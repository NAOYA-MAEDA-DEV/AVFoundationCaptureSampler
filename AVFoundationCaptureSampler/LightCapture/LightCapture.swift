import Photos
import Combine

final class LightCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDevice: AVCaptureDevice?
    private var cameraDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published private(set) var isFlash = false
    
    @Published var selectedFlashLightMode: FlashMode = .off
    @Published var selectedTorchLightMode: TorchMode = .off
    @Published var torchLevel: Float = 0.5
    
    @Published private(set) var cameraDevices: [AVCaptureDevice] = []
    @Published var selectedCameraIndex = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        cameraDevices = getAvailableCameraDevices()
        Task { [weak self] in
            await self?.setupCamera()
            self?.captureSession.startRunning()
            self?.setupObserver()
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
            self.cameraDevice = cameraDevice
            self.cameraDeviceInput = cameraDeviceInput
            
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
    
    private func setupObserver() {
        guard let cameraDevice else { return }
        
        cameraDevice.publisher(for: \.torchMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMode in
                switch newMode {
                case .off:
                    self?.selectedTorchLightMode = .off
                    
                case .on:
                    self?.selectedTorchLightMode = .on
                    
                case .auto:
                    self?.selectedTorchLightMode = .auto
                    
                @unknown default:
                    fatalError()
                }
            }
            .store(in: &cancellables)
    }
    
    func capturePhoto() async {
        guard await isAuthorizedCamera else { return }
        
        let captureSettings = AVCapturePhotoSettings()
        
        let flashMode: AVCaptureDevice.FlashMode
        
        if let cameraDevice, cameraDevice.hasFlash, cameraDevice.isFlashAvailable {
            switch selectedFlashLightMode {
            case .off:
                flashMode = .off
                
            case .on:
                flashMode = .on
                
            case .auto:
                flashMode = .auto
            }
            
            if photoOutput.supportedFlashModes.contains(flashMode) {
                captureSettings.flashMode = flashMode
            }
        }
        
        photoOutput.capturePhoto(with: captureSettings,
                                 delegate: self)
    }
    
    func changeTorchMode() {
        if let cameraDevice, cameraDevice.hasTorch, cameraDevice.isTorchAvailable {
            
            let oldTorchMode = selectedTorchLightMode
            let newTorchMode: AVCaptureDevice.TorchMode
            switch selectedTorchLightMode {
            case .off:
                newTorchMode = .off
                
            case .on:
                newTorchMode = .on
                
            case .auto:
                newTorchMode = .auto
                
            @unknown default:
                fatalError()
            }
            
            if cameraDevice.isTorchModeSupported(newTorchMode) {
                do {
                    try cameraDevice.lockForConfiguration()
                    
                    cameraDevice.torchMode = newTorchMode
                    
                    cameraDevice.unlockForConfiguration()
                } catch let error {
                    print(error)
                }
            } else {
                selectedTorchLightMode = oldTorchMode
            }
        }
    }
    
    func changeTorchLevel() {
        guard let cameraDevice else { return }
        do {
            try cameraDevice.lockForConfiguration()
            if torchLevel <= AVCaptureDevice.maxAvailableTorchLevel {
                try cameraDevice.setTorchModeOn(level: torchLevel)
            }
            cameraDevice.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func changeCameraDevice() {
        captureSession.beginConfiguration()
        
        defer {
            captureSession.commitConfiguration()
        }
        
        if let cameraDeviceInput {
            captureSession.removeInput(cameraDeviceInput)
        }
        
        let cameraDevice = cameraDevices[selectedCameraIndex]
        
        do {
            let cameraDeviceInput = try AVCaptureDeviceInput(device: cameraDevice)
            guard captureSession.canAddInput(cameraDeviceInput) else { fatalError() }
            captureSession.addInput(cameraDeviceInput)
            self.cameraDevice = cameraDeviceInput.device
            self.cameraDeviceInput = cameraDeviceInput
        } catch {
            print(error)
        }
    }
}

extension LightCapture: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        print("\(#function)")
        
        isFlash = resolvedSettings.isFlashEnabled
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        print("\(#function)")
        
        isFlash = false
    }
}
