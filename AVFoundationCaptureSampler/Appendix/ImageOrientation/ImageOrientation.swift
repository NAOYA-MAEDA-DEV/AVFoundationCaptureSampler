import UIKit
import Photos

final class ImageOrientation: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    @Published var selectedOrientation: ImageOrientationType = .up
    @Published private(set) var isCaptured: Bool = false
    
    @Published private(set) var previewImage: UIImage?
    
    override init() {
        super.init()
        Task { [weak self] in
            await self?.setupCapture()
            self?.captureSession.startRunning()
        }
    }
    
    func onDissapear() {
        captureSession.stopRunning()
    }
    
    func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    private func setupCapture() async {
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
            
            guard captureSession.canAddOutput(videoDataOutput) else { return }
            videoDataOutput.setSampleBufferDelegate(
                self,
                queue: DispatchQueue(label: "display_preview_dispatchqueue"))
            
            captureSession.addOutput(videoDataOutput)
        } catch {
            print(error)
        }
    }
    
    func capturePreview() {
        isCaptured = true
        AudioServicesPlaySystemSound(1108)
    }
}

extension ImageOrientation: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let cameraDeviceInputCIImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        if let cgImg = cameraDeviceInputCIImage.toCGImage() {
            let orientation: UIImage.Orientation
            
            switch selectedOrientation {
            case .up:
                orientation = .up
                
            case .down:
                orientation = .down
                
            case .left:
                orientation = .left
                
            case .right:
                orientation = .right
                
            case .upMirrored:
                orientation = .upMirrored
                
            case .downMirrored:
                orientation = .downMirrored
                
            case .leftMirrored:
                orientation = .leftMirrored
                
            case .rightMirrored:
                orientation = .rightMirrored
            }
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.previewImage = UIImage(
                    cgImage: cgImg,
                    scale: 1.0,
                    orientation: orientation)
                
                if self.isCaptured {
                    self.isCaptured = false
                    
                    guard let previewImage = self.previewImage else { return }
                    
                    do {
                        try await PHPhotoLibrary.shared().performChanges {
                            let creationRequest = PHAssetCreationRequest.forAsset()
                            creationRequest.addResource(with: .photo,
                                                        data:(previewImage.jpegData(compressionQuality: 1.0))!,
                                                        options: nil)
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}
