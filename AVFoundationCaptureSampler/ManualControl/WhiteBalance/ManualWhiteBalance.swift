import Photos
import Combine

final class ManualWhiteBalance: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDeviceInput: AVCaptureDeviceInput?
    private var cameraDevice: AVCaptureDevice?
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published private(set) var whiteBalanceModeStr: String = ""
    @Published private(set) var redGain: Float = 1.0
    @Published private(set) var greenGain: Float = 1.0
    @Published private(set) var blueGain: Float = 1.0
    @Published private(set) var maxWhiteBalanceGain: Float = 4.0
    @Published private(set) var temperature: Float = 0.0
    @Published private(set) var tint: Float = 0.0
    @Published private(set) var grayWorldRedGain: Float = 1.0
    @Published private(set) var grayWorldGreenGain: Float = 1.0
    @Published private(set) var grayWorldBlueGain: Float = 1.0
    @Published private(set) var whiteBalanceChromaticityValueX: Float = 0.0
    @Published private(set) var whiteBalanceChromaticityValueY: Float = 0.0
    @Published private(set) var isAdjustingWhiteBalance: Bool = false
    
    @Published var selectedWhiteBalanceMode = WhiteBalamceMode.continuous
    @Published var redGainValue: Float = 1.0
    @Published var greenGainValue: Float = 1.0
    @Published var blueGainValue: Float = 1.0
    
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
        selectedWhiteBalanceMode = .continuous
        changeWhiteBalanceMode()
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
        
        cameraDevice.publisher(for: \.whiteBalanceMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMode in
                switch newMode {
                case .locked:
                    self?.whiteBalanceModeStr = "Locked"
                    self?.selectedWhiteBalanceMode = .locked
                    
                case .autoWhiteBalance:
                    self?.whiteBalanceModeStr = "Auto"
                    self?.selectedWhiteBalanceMode = .auto
                    
                case .continuousAutoWhiteBalance:
                    self?.whiteBalanceModeStr = "Continuous"
                    self?.selectedWhiteBalanceMode = .continuous
                    
                @unknown default:
                    fatalError()
                }
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.deviceWhiteBalanceGains)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self,
                      newValue.redGain > 0.0,
                      newValue.greenGain > 0.0,
                      newValue.blueGain > 0.0
                else { return }
                
                self.redGain = newValue.redGain
                self.greenGain = newValue.greenGain
                self.blueGain = newValue.blueGain
                let whiteBalanceGains: AVCaptureDevice.WhiteBalanceGains = .init(redGain: newValue.redGain,
                                                                                 greenGain: newValue.greenGain,
                                                                                 blueGain: newValue.blueGain)
                let whiteBalanceTemperatureAndTintValues = cameraDevice.temperatureAndTintValues(for: whiteBalanceGains)
                self.temperature = whiteBalanceTemperatureAndTintValues.temperature
                self.tint = whiteBalanceTemperatureAndTintValues.tint
                
                let whiteBalanceChromaticityValues = cameraDevice.chromaticityValues(for: whiteBalanceGains)
                self.whiteBalanceChromaticityValueX = whiteBalanceChromaticityValues.x
                self.whiteBalanceChromaticityValueY = whiteBalanceChromaticityValues.y
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.maxWhiteBalanceGain)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.maxWhiteBalanceGain = newValue
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.grayWorldDeviceWhiteBalanceGains)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.grayWorldRedGain = newValue.redGain
                self?.grayWorldGreenGain = newValue.greenGain
                self?.grayWorldBlueGain = newValue.blueGain
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.isAdjustingWhiteBalance)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAdjusting in
                self?.isAdjustingWhiteBalance = isAdjusting
            }
            .store(in: &cancellables)
    }
    
    func changeWhiteBalanceMode() {
        guard let cameraDevice else { return }
        
        let oldWhiteBalanceMode = cameraDevice.whiteBalanceMode
        let newWhiteBalanceMode: AVCaptureDevice.WhiteBalanceMode
        switch selectedWhiteBalanceMode {
        case .locked:
            newWhiteBalanceMode = .locked
            
        case .auto:
            newWhiteBalanceMode = .autoWhiteBalance
            
        case .continuous:
            newWhiteBalanceMode = .continuousAutoWhiteBalance
        }
        if cameraDevice.isWhiteBalanceModeSupported(newWhiteBalanceMode) {
            do {
                try cameraDevice.lockForConfiguration()
                
                cameraDevice.whiteBalanceMode = newWhiteBalanceMode
                
                cameraDevice.unlockForConfiguration()
            } catch let error {
                print(error)
            }
        } else {
            switch oldWhiteBalanceMode {
            case .locked:
                selectedWhiteBalanceMode = .locked
                
            case .autoWhiteBalance:
                selectedWhiteBalanceMode = .auto
                
            case .continuousAutoWhiteBalance:
                selectedWhiteBalanceMode = .continuous
                
            @unknown default:
                fatalError()
            }
        }
    }
    
    func changeWhiteBalance() async {
        guard let cameraDevice else { return }
        
        if cameraDevice.isLockingWhiteBalanceWithCustomDeviceGainsSupported {
            let whiteBalanceGainsValue: AVCaptureDevice.WhiteBalanceGains = .init(
                redGain: redGainValue,
                greenGain: greenGainValue,
                blueGain: blueGainValue)
            
            do {
                try cameraDevice.lockForConfiguration()
                
                await cameraDevice.setWhiteBalanceModeLocked(with: whiteBalanceGainsValue)
                //                cameraDevice.setWhiteBalanceModeLocked(with: whiteBalanceGainsValue) { newValue in
                //                    print("\(newValue)")
                //                }
                
                cameraDevice.unlockForConfiguration()
            } catch let error {
                print(error)
            }
        }
    }
    
    func changeTemperatureAndTintValues() async {
        guard let cameraDevice else { return }
        
        let whiteBalanceGains = cameraDevice.grayWorldDeviceWhiteBalanceGains
        redGainValue = min(whiteBalanceGains.redGain, maxWhiteBalanceGain)
        greenGainValue = min(whiteBalanceGains.greenGain, maxWhiteBalanceGain)
        blueGainValue = min(whiteBalanceGains.blueGain, maxWhiteBalanceGain)
        
        await changeWhiteBalance()
    }
    
    func setGrayWorldGains() {
        guard let cameraDevice else { return }
        
        let whiteBalanceGains = cameraDevice.grayWorldDeviceWhiteBalanceGains
        redGainValue = min(whiteBalanceGains.redGain, maxWhiteBalanceGain)
        greenGainValue = min(whiteBalanceGains.greenGain, maxWhiteBalanceGain)
        blueGainValue = min(whiteBalanceGains.blueGain, maxWhiteBalanceGain)
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
