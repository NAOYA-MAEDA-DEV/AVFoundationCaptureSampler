import Photos
import Combine

final class Zoom: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDevice: AVCaptureDevice?
    private var cameraDeviceInput: AVCaptureDeviceInput?
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published private(set) var zoomFactor: CGFloat = 0
    @Published private(set) var zoomFactorMultiplier: CGFloat = 0
    @Published private(set) var minZoomFactor: CGFloat = 0
    @Published private(set) var maxZoomFactor: CGFloat = 0
    @Published private(set) var isZooming: Bool = false
    @Published private(set) var switchZoomFactors: [NSNumber] = []
    
    @Published var zoomFactorValue: CGFloat = 0
    @Published var rampZoomFactorValue: Int = 0
    @Published var rampValue: CGFloat = 0
    
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
        
        cameraDevice.publisher(for: \.videoZoomFactor)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                self.zoomFactor = newValue
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.minAvailableVideoZoomFactor)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.minZoomFactor = newValue
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.maxAvailableVideoZoomFactor)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                self.maxZoomFactor = newValue
                
                if self.maxZoomFactor > 10 {
                    self.maxZoomFactor = 10
                }
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.isRampingVideoZoom)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isZooming in
                self?.isZooming = isZooming
            }
            .store(in: &cancellables)
        
        cameraDevice.publisher(for: \.virtualDeviceSwitchOverVideoZoomFactors)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] factors in
                self?.switchZoomFactors = factors
            }
            .store(in: &cancellables)
        
        if #available(iOS 18, *) {
            cameraDevice.publisher(for: \.displayVideoZoomFactorMultiplier)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] factor in
                    self?.zoomFactorMultiplier = factor
                }
                .store(in: &cancellables)
        }
    }
    
    func changeZoom(value: CGFloat) {
        guard let cameraDevice else { return }
        do {
            try cameraDevice.lockForConfiguration()
            
            cameraDevice.videoZoomFactor = value
            
            cameraDevice.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func rampZoom() {
        guard let cameraDevice else { return }
        do {
            try cameraDevice.lockForConfiguration()
            
            cameraDevice.ramp(
                toVideoZoomFactor: CGFloat(rampZoomFactorValue),
                withRate: Float(rampValue))
            
            cameraDevice.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func cancelRampZoom() {
        guard let cameraDevice else { return }
        do {
            try cameraDevice.lockForConfiguration()
            
            cameraDevice.cancelVideoZoomRamp()
            
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
        
        self.setupObserver()
    }
}
