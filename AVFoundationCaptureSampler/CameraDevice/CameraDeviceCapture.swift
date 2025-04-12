import Photos
import Combine

final class CameraDeviceCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDeviceInput: AVCaptureDeviceInput?
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    private let cameraDeviceTypes: [AVCaptureDevice.DeviceType] = [
        .builtInWideAngleCamera,
        .builtInUltraWideCamera,
        .builtInTelephotoCamera,
        .builtInDualCamera,
        .builtInDualWideCamera,
        .builtInTripleCamera
    ]
    
    @Published private(set) var cameraDevices: [AVCaptureDevice] = []
    
    @Published var selectedCameraDeviceIndex = 0
    
    override init() {
        super.init()
        Task { [weak self] in
            await self?.setupCamera()
            self?.captureSession.startRunning()
            self?.getAvailableCameraDevices()
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
            self.cameraDeviceInput = cameraDeviceInput
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer.videoGravity = .resizeAspectFill
            }
            
            if captureSession.canSetSessionPreset(.high) {
                captureSession.sessionPreset = .high
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
    
    private func getAvailableCameraDevices() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.cameraDevices = AVCaptureDevice.DiscoverySession(
                deviceTypes: self.cameraDeviceTypes,
                mediaType: .video,
                position: .unspecified).devices
        }
    }
    
    func changeCameraDevice() {
        captureSession.beginConfiguration()
        
        defer {
            captureSession.commitConfiguration()
        }
        
        if let cameraDeviceInput, captureSession.inputs.contains(cameraDeviceInput) {
            captureSession.removeInput(cameraDeviceInput)
        }
        
        let cameraDevice = cameraDevices[selectedCameraDeviceIndex]
        
        do {
            let cameraDeviceInput = try AVCaptureDeviceInput(device: cameraDevice)
            guard captureSession.canAddInput(cameraDeviceInput) else { fatalError() }
            captureSession.addInput(cameraDeviceInput)
            self.cameraDeviceInput = cameraDeviceInput
        } catch {
            print(error)
        }
    }
}
