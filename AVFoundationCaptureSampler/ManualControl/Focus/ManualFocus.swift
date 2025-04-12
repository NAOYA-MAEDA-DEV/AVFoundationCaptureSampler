import Photos
import Combine

final class ManualFocus: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDeviceInput: AVCaptureDeviceInput?
    private var cameraDevice: AVCaptureDevice?
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published private(set) var focusModeStr: String = ""
    @Published private(set) var focusRangeStr: String = ""
    @Published private(set) var smoothAutoFocus = false
    @Published private(set) var faceDrivenAutoFocus = false
    @Published private(set) var automaticallyAdjustsFaceDrivenAutoFocus = false
    @Published private(set) var lensPosition: Float = 0.0
    @Published private(set) var minimumFocusDistance: Int = 0
    @Published private(set) var isAdjustingFocus: Bool = false
    
    @Published var selectedFocusMode = FocusMode.continuous
    @Published var selectedFocusRange = FocusRange.none
    @Published var isSmoothAutoFocus = true
    @Published var isFaceDrivenAutoFocus = true
    @Published var isAutomaticallyAdjustsFaceDrivenAutoFocus = true
    @Published var lensPositionValue: Float = 0.0
    
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
        selectedFocusMode = .continuous
        selectedFocusRange = .none
        changeFocusMode()
        changeFocusRange()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
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
        
        cameraDevice.publisher(for: \.focusMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMode in
                switch newMode {
                case .locked:
                    self?.focusModeStr = "Locked"
                    
                case .autoFocus:
                    self?.focusModeStr = "Auto"
                    
                case .continuousAutoFocus:
                    self?.focusModeStr = "Continuous"
                    
                @unknown default:
                    fatalError()
                }
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.autoFocusRangeRestriction)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRange in
                switch newRange {
                case .none:
                    self?.focusRangeStr = "None"
                    self?.selectedFocusRange = .none
                    
                case .near:
                    self?.focusRangeStr = "Near"
                    self?.selectedFocusRange = .near
                    
                case .far:
                    self?.focusRangeStr = "Far"
                    self?.selectedFocusRange = .far
                    
                @unknown default:
                    fatalError()
                }
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.isSmoothAutoFocusEnabled)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.smoothAutoFocus = enabled
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.isFaceDrivenAutoFocusEnabled)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                print(enabled)
                self?.faceDrivenAutoFocus = enabled
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.automaticallyAdjustsFaceDrivenAutoFocusEnabled)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.automaticallyAdjustsFaceDrivenAutoFocus = enabled
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.lensPosition)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.lensPosition = newValue
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.minimumFocusDistance)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.minimumFocusDistance = newValue
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.isAdjustingFocus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAdjusting in
                self?.isAdjustingFocus = isAdjusting
            }
            .store(in: &cancellables)
    }
    
    func focusAt(point: CGPoint) {
        guard let cameraDevice else { return }
        
        if cameraDevice.isFocusPointOfInterestSupported && cameraDevice.isFocusModeSupported(.autoFocus) {
            do {
                try cameraDevice.lockForConfiguration()
                
                cameraDevice.focusPointOfInterest = point
                cameraDevice.focusMode = .autoFocus
                
                cameraDevice.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    func changeFocusMode() {
        guard let cameraDevice else { return }
        
        let oldFocusMode = cameraDevice.focusMode
        let newFocusMode: AVCaptureDevice.FocusMode
        switch selectedFocusMode {
        case .locked:
            newFocusMode = .locked
            
        case .auto:
            newFocusMode = .autoFocus
            
        case .continuous:
            newFocusMode = .continuousAutoFocus
        }
        
        if cameraDevice.isFocusModeSupported(newFocusMode) {
            do {
                try cameraDevice.lockForConfiguration()
                
                cameraDevice.focusMode = newFocusMode
                
                cameraDevice.unlockForConfiguration()
            } catch let error {
                print(error)
            }
        } else {
            switch oldFocusMode {
            case .locked:
                selectedFocusMode = .locked
                
            case .autoFocus:
                selectedFocusMode = .auto
                
            case .continuousAutoFocus:
                selectedFocusMode = .continuous
                
            @unknown default:
                fatalError()
            }
        }
    }
    
    func changeFocusRange() {
        guard let cameraDevice else { return }
        
        let oldFocusRange = cameraDevice.autoFocusRangeRestriction
        let newFocusRange: AVCaptureDevice.AutoFocusRangeRestriction
        switch selectedFocusRange {
        case .none:
            newFocusRange = .none
            
        case .near:
            newFocusRange = .near
            
        case .far:
            newFocusRange = .far
        }
        
        if cameraDevice.isAutoFocusRangeRestrictionSupported {
            do {
                try cameraDevice.lockForConfiguration()
                
                cameraDevice.autoFocusRangeRestriction = newFocusRange
                
                cameraDevice.unlockForConfiguration()
            } catch let error {
                print(error)
            }
        } else {
            switch oldFocusRange {
            case .none:
                selectedFocusRange = .none
                
            case .near:
                selectedFocusRange = .near
                
            case .far:
                selectedFocusRange = .far
                
            @unknown default:
                fatalError()
            }
        }
    }
    
    func changeLensPosition() async {
        guard let cameraDevice else { return }
        
        do {
            try cameraDevice.lockForConfiguration()
            
            if cameraDevice.isLockingFocusWithCustomLensPositionSupported {
                await cameraDevice.setFocusModeLocked(lensPosition: lensPositionValue)
                //                cameraDevice.setFocusModeLocked(lensPosition: lensPositionValue) { newValue in
                //                    print("\(newValue)")
                //                }
            }
            
            cameraDevice.unlockForConfiguration()
        } catch let error {
            print(error)
        }
    }
    
    func toggleSmoothAutoFocus() {
        guard let cameraDevice else { return }
        
        do {
            try cameraDevice.lockForConfiguration()
            
            if isSmoothAutoFocus {
                cameraDevice.isSmoothAutoFocusEnabled = cameraDevice.isSmoothAutoFocusSupported
                smoothAutoFocus = cameraDevice.isSmoothAutoFocusSupported
            } else {
                cameraDevice.isSmoothAutoFocusEnabled = false
            }
            
            cameraDevice.unlockForConfiguration()
        } catch let error {
            print(error)
        }
    }
    
    func toggleFaceDrivenAutoFocus() {
        guard let cameraDevice else { return }
        
        do {
            try cameraDevice.lockForConfiguration()
            
            cameraDevice.isFaceDrivenAutoFocusEnabled = isFaceDrivenAutoFocus
            
            cameraDevice.unlockForConfiguration()
        } catch let error {
            print(error)
        }
        
        selectedFocusMode = .auto
        changeFocusMode()
    }
    
    func toggleAutomaticallyAdjustsFaceDrivenAutoFocus() {
        guard let cameraDevice else { return }
        
        do {
            try cameraDevice.lockForConfiguration()
            
            cameraDevice.automaticallyAdjustsFaceDrivenAutoFocusEnabled = isAutomaticallyAdjustsFaceDrivenAutoFocus
            
            cameraDevice.unlockForConfiguration()
        } catch let error {
            print(error)
        }
        
        selectedFocusMode = .auto
        changeFocusMode()
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
