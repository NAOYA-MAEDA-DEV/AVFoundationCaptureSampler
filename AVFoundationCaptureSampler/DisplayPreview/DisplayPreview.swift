import UIKit
import AVFoundation

final class DisplayPreview: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
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
}

extension DisplayPreview: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        print("\(#function)")
        // If you remove the comment in the following code, captureOutput(_:didDrop:from:) will be called.
        // Thread.sleep(forTimeInterval: 1.0)
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let cameraDeviceInputCIImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        if let cgImg = cameraDeviceInputCIImage.toCGImage() {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.previewImage = UIImage(
                    cgImage: cgImg,
                    scale: 1,
                    orientation: .right)
            }
        }
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        print("\(#function)")
    }
}

