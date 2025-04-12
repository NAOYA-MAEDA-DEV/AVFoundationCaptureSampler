import Photos
import UIKit

final class PhotoCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published private(set) var shouldFlashScreen = false
    
    private var compressedData: Data?
    
    override init() {
        super.init()
        Task { [weak self] in
            await self?.setupCamera()
            self?.captureSession.startRunning()
        }
    }
    
    func onDissapear() {
        captureSession.stopRunning()
    }
    
    private func setupCamera() async {
        guard await isAuthorizedCamera else { return }
        
        captureSession.beginConfiguration()
        
        defer {
            captureSession.commitConfiguration()
        }
        
        do {
            guard let cameraDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back) else {
                return
            }
            let cameraDeviceInput = try AVCaptureDeviceInput(device: cameraDevice)
            guard captureSession.canAddInput(cameraDeviceInput) else { return }
            captureSession.addInput(cameraDeviceInput)
            
            guard captureSession.canAddOutput(photoOutput) else { return }
            captureSession.addOutput(photoOutput)
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer.videoGravity = .resizeAspectFill
            }
            
            if captureSession.canSetSessionPreset(.photo) {
                captureSession.sessionPreset = .photo
            }
        } catch {
            print(error)
        }
    }
    
    func setupPreview(size: CGSize) {
        previewLayer.frame = CGRect(x: 0,
                                    y: 0,
                                    width: size.width,
                                    height: size.height)
    }
    
    func capturePhoto() async {
        guard await isAuthorizedCamera else { return }
        let captureSettings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: captureSettings,
                                 delegate: self)
    }
}

extension PhotoCapture: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        print("\(#function)")
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        print("\(#function)")
        
        shouldFlashScreen = true
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        print("\(#function)")
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        print("\(#function)")
        
        shouldFlashScreen = false
        
        guard error == nil else {
            print("Error broken photo data: \(error!)")
            return
        }
        
        guard let photoData = photo.fileDataRepresentation() else {
            print("No photo data to write.")
            return
        }
        
        compressedData = photoData
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: (any Error)?
    ) {
        print("\(#function)")
        
        guard error == nil else {
            print("Error capture photo: \(error!)")
            return
        }
        
        guard let compressedData = compressedData else {
            print("The expected photo data isn't available.")
            return
        }
        
        Task {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo,
                                                data: compressedData,
                                                options: nil)
                }
            } catch {
                print(error)
            }
        }
    }
}
