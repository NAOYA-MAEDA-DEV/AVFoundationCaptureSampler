import Photos
import Combine

final class ManualExposure: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDeviceInput: AVCaptureDeviceInput?
    private var cameraDevice: AVCaptureDevice?
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published private(set) var exposureModeStr: String = ""
    @Published private(set) var faceDrivenAutoExposure = true
    @Published private(set) var automaticallyAdjustsFaceDrivenAutoExposure = true
    @Published private(set) var exposureTargetOffset: Float = 0.0
    @Published private(set) var exposureTargetBias: Float = 0.0
    @Published private(set) var minExposureTargetBias: Float = 0
    @Published private(set) var maxExposureTargetBias: Float = 0
    @Published private(set) var exposureDuration: Float64 = 0.0
    @Published private(set) var minExposureDuration: Float = 0.0
    @Published private(set) var maxExposureDuration: Float = 0.0
    @Published private(set) var iso: Float = 0.0
    @Published private(set) var minISO: Float = 0.0
    @Published private(set) var maxISO: Float = 0.0
    @Published private(set) var lensAperture: Float = 0.0
    @Published private(set) var isAdjustingExposure: Bool = false
    
    @Published var selectedExposureMode = ExposureMode.continuous
    @Published var isFaceDrivenAutoExposure = true
    @Published var isAutomaticallyAdjustsFaceDrivenAutoExposure = true
    @Published var exposureTargetBiasValue: Float = 0.0
    @Published var isoValue: Float = 0.0
    @Published var exposureDurationValue: Float = 0.0
    
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
    
    func onDissapear() async {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.exposureTargetBiasValue = 0.0
            self.selectedExposureMode = .continuous
            await self.changeExposureTargetBias()
            self.changeExposureMode()
            self.cancellables.forEach { $0.cancel() }
            self.cancellables.removeAll()
            self.captureSession.stopRunning()
        }
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
    
    func setPreview(size: CGSize) {
        previewLayer.frame = CGRect(x: 0,
                                    y: 0,
                                    width: size.width,
                                    height: size.height)
    }
    
    private func setupObserver() {
        guard let cameraDevice else { return }
        
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        cameraDevice.publisher(for: \.exposureMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMode in
                switch newMode {
                case .locked:
                    self?.exposureModeStr = "Locked"
                    self?.selectedExposureMode = .locked
                    
                case .autoExpose:
                    self?.exposureModeStr = "Auto"
                    self?.selectedExposureMode = .auto
                    
                case .continuousAutoExposure:
                    self?.exposureModeStr = "Continuous"
                    self?.selectedExposureMode = .continuous
                    
                case .custom:
                    self?.exposureModeStr = "Custom"
                    self?.selectedExposureMode = .custom
                    
                @unknown default:
                    fatalError()
                }
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.isFaceDrivenAutoExposureEnabled)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.faceDrivenAutoExposure = enabled
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.automaticallyAdjustsFaceDrivenAutoExposureEnabled)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.automaticallyAdjustsFaceDrivenAutoExposure = enabled
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.exposureTargetOffset)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.exposureTargetOffset = newValue
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.exposureTargetBias)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.exposureTargetBias = newValue
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.minExposureTargetBias)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.minExposureTargetBias = newValue
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.maxExposureTargetBias)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.maxExposureTargetBias = newValue
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.exposureDuration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.exposureDuration = newValue.seconds
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.iso)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.iso = newValue
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.activeFormat)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.minISO = newValue.minISO
                self?.maxISO = newValue.maxISO
                self?.minExposureDuration = Float(newValue.minExposureDuration.seconds)
                self?.maxExposureDuration = Float(newValue.maxExposureDuration.seconds)
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.lensAperture)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.lensAperture = newValue
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.isAdjustingExposure)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAdjusting in
                self?.isAdjustingExposure = isAdjusting
            }
            .store(in: &cancellables)
    }
    
    func exposureAt(point: CGPoint) {
        guard let cameraDevice else { return }
        
        if cameraDevice.isExposurePointOfInterestSupported {
            do {
                try cameraDevice.lockForConfiguration()
                
                cameraDevice.exposurePointOfInterest = point
                cameraDevice.exposureMode = .autoExpose
                
                cameraDevice.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    func changeExposureMode() {
        guard let cameraDevice else { return }
        
        let oldExposureMode = cameraDevice.exposureMode
        let newExposureMode: AVCaptureDevice.ExposureMode
        switch selectedExposureMode {
        case .locked:
            newExposureMode = .locked
            
        case .auto:
            newExposureMode = .autoExpose
            
        case .continuous:
            newExposureMode = .continuousAutoExposure
            
        case .custom:
            newExposureMode = .custom
        }
        if cameraDevice.isExposureModeSupported(newExposureMode) {
            do {
                try cameraDevice.lockForConfiguration()
                
                cameraDevice.exposureMode = newExposureMode
                
                cameraDevice.unlockForConfiguration()
            } catch let error {
                print(error)
            }
        } else {
            switch oldExposureMode {
            case .locked:
                selectedExposureMode = .locked
                
            case .autoExpose:
                selectedExposureMode = .auto
                
            case .continuousAutoExposure:
                selectedExposureMode = .continuous
                
            case .custom:
                selectedExposureMode = .custom
                
            @unknown default:
                fatalError()
            }
        }
    }
    
    func changeExposureTargetBias() async {
        guard let cameraDevice else { return }
        
        do {
            try cameraDevice.lockForConfiguration()
            
            await cameraDevice.setExposureTargetBias(exposureTargetBiasValue)
            //            cameraDevice.setExposureTargetBias(exposureTargetBiasValue) { newValue in
            //                print("\(newValue)")
            //            }
            
            cameraDevice.unlockForConfiguration()
        } catch let error {
            print(error)
        }
    }
    
    func changeISO() async {
        guard let cameraDevice else { return }
        
        do {
            try cameraDevice.lockForConfiguration()
            
            await cameraDevice.setExposureModeCustom(
                duration: AVCaptureDevice.currentExposureDuration,
                iso: isoValue)
            //            cameraDevice.setExposureModeCustom(
            //                duration: AVCaptureDevice.currentExposureDuration,
            //                iso: isoValue) { newValue in
            //                    print("\(newValue)")
            //                }
            
            cameraDevice.unlockForConfiguration()
        } catch let error {
            print(error)
        }
    }
    
    func changeExposureDuration() async {
        guard let cameraDevice else { return }
        
        do {
            try cameraDevice.lockForConfiguration()
            
            let newDuration = CMTimeMakeWithSeconds(Float64(exposureDurationValue),
                                                    preferredTimescale: 1000000)
            
            await cameraDevice.setExposureModeCustom(
                duration: newDuration,
                iso: AVCaptureDevice.currentISO)
            //            cameraDevice.setExposureModeCustom(
            //                duration: newDuration,
            //                iso: AVCaptureDevice.currentISO) { newValue in
            //                    print("\(newValue)")
            //                }
            
            cameraDevice.unlockForConfiguration()
        } catch let error {
            print(error)
        }
    }
    
    func toggleFaceDrivenAutoExpose() {
        guard let cameraDevice else { return }
        
        do {
            try cameraDevice.lockForConfiguration()
            
            cameraDevice.isFaceDrivenAutoExposureEnabled = isFaceDrivenAutoExposure
            
            cameraDevice.unlockForConfiguration()
        } catch let error {
            print(error)
        }
    }
    
    func toggleAutomaticallyAdjustsFaceDrivenAutoExposure() {
        guard let cameraDevice else { return }
        
        do {
            try cameraDevice.lockForConfiguration()
            
            cameraDevice.automaticallyAdjustsFaceDrivenAutoExposureEnabled = isAutomaticallyAdjustsFaceDrivenAutoExposure
            
            cameraDevice.unlockForConfiguration()
        } catch let error {
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
        
        self.setupObserver()
    }
}
