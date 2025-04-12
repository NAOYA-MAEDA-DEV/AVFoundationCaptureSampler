import UIKit
import Photos
import CoreMotion
import Combine

final class RotationCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDevice: AVCaptureDevice?
    private var cameraDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    @Published var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published private(set) var isRecording = false
    @Published private(set) var previewImage: UIImage?
    @Published var previewLayerAngle: VideoAngle = .angle_0
    @Published var photoOutputAngle: VideoAngle = .angle_0
    @Published var movieFileOutputAngle: VideoAngle = .angle_0
    @Published var videoDataOutputAngle: VideoAngle = .angle_0
    @Published var isAutoRotation: Bool = false
    
    private var compressedData: Data?
    
    @Published private(set) var cameraDevices: [AVCaptureDevice] = []
    @Published var selectedCameraIndex = 0
    
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator!
    private var rotationObservers = [AnyObject]()
    
    private let motionManager = CMMotionManager()
    
    @available(iOS, deprecated: 17.0)
    private var angleForCapture: AVCaptureVideoOrientation = .portrait
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        cameraDevices = getAvailableCameraDevices()
        Task { [weak self] in
            await self?.setupCamera()
            self?.captureSession.startRunning()
        }
    }
    
    func onDissapear() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        rotationObservers.removeAll()
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
            print("Default videoRotationAngle of AVCapturePhotoOutput")
            print(photoOutput.connection(with: .video)?.videoRotationAngle ?? "Nothing")
            
            guard captureSession.canAddOutput(movieFileOutput) else { return }
            captureSession.addOutput(movieFileOutput)
            print("Default videoRotationAngle of AVCaptureMovieFileOutput")
            print(movieFileOutput.connection(with: .video)?.videoRotationAngle ?? "Nothing")
            
            guard captureSession.canAddOutput(videoDataOutput) else { return }
            videoDataOutput.setSampleBufferDelegate(
                self,
                queue: DispatchQueue(label: "video_data_dispatchqueue"))
            captureSession.addOutput(videoDataOutput)
            print("Default videoRotationAngle of AVCaptureVideoDataOutput")
            print(videoDataOutput.connection(with: .video)?.videoRotationAngle ?? "Nothing")
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer.videoGravity = .resizeAspectFill
                print("Default videoRotationAngle of AVCaptureVideoPreviewLayer")
                print(self.previewLayer.connection?.videoRotationAngle ?? "Nothing")
                
                if #available(iOS 17, *) {
                    self.createRotationCoordinator(for: cameraDevice,
                                                   previewLayer: previewLayer)
                } else {
                    self.startDeviceMotionUpdates()
                }
                
                self.setupObserver()
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
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        let previewLayerConnection = previewLayer?.connection
        if let previewLayerConnection {
            previewLayerConnection.publisher(for: \.videoRotationAngle)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newAngle in
                    switch newAngle {
                    case 0:
                        self?.previewLayerAngle = .angle_0
                        
                    case 90:
                        self?.previewLayerAngle = .angle_90
                        
                    case 180:
                        self?.previewLayerAngle = .angle_180
                        
                    case 270:
                        self?.previewLayerAngle = .angle_270
                        
                    default:
                        fatalError()
                    }
                }
                .store(in: &cancellables)
        }
        
        let photoOutputConnection = photoOutput.connection(with: .video)
        if let photoOutputConnection {
            photoOutputConnection.publisher(for: \.videoRotationAngle)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newAngle in
                    switch newAngle {
                    case 0:
                        self?.photoOutputAngle = .angle_0
                        
                    case 90:
                        self?.photoOutputAngle = .angle_90
                        
                    case 180:
                        self?.photoOutputAngle = .angle_180
                        
                    case 270:
                        self?.photoOutputAngle = .angle_270
                        
                    default:
                        fatalError()
                    }
                }
                .store(in: &cancellables)
        }
        
        let movieFileOutputConnection = movieFileOutput.connection(with: .video)
        if let movieFileOutputConnection {
            movieFileOutputConnection.publisher(for: \.videoRotationAngle)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newAngle in
                    switch newAngle {
                    case 0:
                        self?.movieFileOutputAngle = .angle_0
                        
                    case 90:
                        self?.movieFileOutputAngle = .angle_90
                        
                    case 180:
                        self?.movieFileOutputAngle = .angle_180
                        
                    case 270:
                        self?.movieFileOutputAngle = .angle_270
                        
                    default:
                        fatalError()
                    }
                }
                .store(in: &cancellables)
        }
        
        let videoDataOutputConnection = videoDataOutput.connection(with: .video)
        if let videoDataOutputConnection {
            videoDataOutputConnection.publisher(for: \.videoRotationAngle)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newAngle in
                    switch newAngle {
                    case 0:
                        self?.videoDataOutputAngle = .angle_0
                        
                    case 90:
                        self?.videoDataOutputAngle = .angle_90
                        
                    case 180:
                        self?.videoDataOutputAngle = .angle_180
                        
                    case 270:
                        self?.videoDataOutputAngle = .angle_270
                        
                    default:
                        fatalError()
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    private func createRotationCoordinator(for device: AVCaptureDevice, previewLayer: AVCaptureVideoPreviewLayer) {
        rotationObservers.removeAll()
        
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        
        rotationObservers.append(
            rotationCoordinator.observe(\.videoRotationAngleForHorizonLevelCapture, options: .new) { [weak self] _, change in
                guard let self,
                      self.isAutoRotation,
                      let angle = change.newValue else { return }
                Task {
                    self.updateCaptureRotation(angle: angle)
                }
            }
        )
        
        rotationObservers.append(
            rotationCoordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { [weak self] _, change in
                guard let self,
                      self.isAutoRotation,
                      let angle = change.newValue else { return }
                Task {
                    self.updatePreviewLayerRotation(angle: angle)
                }
            }
        )
    }
    
    private func updateCaptureRotation(angle: CGFloat) {
        if let photoOutputConnection = photoOutput.connection(with: .video) {
            photoOutputConnection.videoRotationAngle = angle
        }
        
        if let movieFileOutputConnection = movieFileOutput.connection(with: .video) {
            
            movieFileOutputConnection.videoRotationAngle = angle
        }
        
        if let videoDataOutputConnection = videoDataOutput.connection(with: .video) {
            videoDataOutputConnection.videoRotationAngle = angle
        }
    }
    
    
    private func updatePreviewLayerRotation(angle: CGFloat) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.previewLayer.connection?.videoRotationAngle = angle
        }
    }
    
    @available(iOS, deprecated: 17.0)
    private func startDeviceMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(
                to: OperationQueue.main) { [weak self] (motion, error) in
                    guard let self, let motion else { return }
                    
                    let gravity = motion.gravity
                    let x = gravity.x
                    let y = gravity.y
                    
                    angleForCapture = determineDeviceOrientation(
                        gravityX: x,
                        gravityY: y)
                }
        }
    }
    
    @available(iOS, deprecated: 17.0)
    private func determineDeviceOrientation(
        gravityX x: Double,
        gravityY y: Double
    ) -> AVCaptureVideoOrientation {
        let threshold = 0.5
        
        if fabs(y) > fabs(x) {
            if y < -threshold {
                return .portrait
            } else if y > threshold {
                return .portraitUpsideDown
            }
        } else {
            if x < -threshold {
                return .landscapeRight
            } else if x > threshold {
                return .landscapeLeft
            }
        }
        
        return .portrait
    }
    
    func capturePhoto() async {
        guard await isAuthorizedCamera else { return }
        
        let captureSettings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: captureSettings,
                                 delegate: self)
    }
    
    func controlRecording() {
        if isRecording {
            movieFileOutput.stopRecording()
            isRecording = false
            AudioServicesPlaySystemSound(1118)
        } else {
            let fileURL: URL = makeUniqueTempFileURL(extension: "mov")
            movieFileOutput.startRecording(to: fileURL,
                                           recordingDelegate: self)
            isRecording = true
            AudioServicesPlaySystemSound(1117)
        }
    }
    
    func updatePreviewLayerRotation() {
        let previewLayerConnection = previewLayer.connection
        
        let angle: CGFloat
        
        switch previewLayerAngle {
        case .angle_0:
            angle = 0
            
        case .angle_90:
            angle = 90
            
        case .angle_180:
            angle = 180
            
        case .angle_270:
            angle = 270
        }
        
        if let previewLayerConnection {
            if previewLayerConnection.isVideoRotationAngleSupported(angle) {
                previewLayerConnection.videoRotationAngle = angle
            }
        }
    }
    
    func updatePhotoOutputRotation() {
        let photoOutputVideoConnection = photoOutput.connection(with: .video)
        
        let angle: CGFloat
        
        switch photoOutputAngle {
        case .angle_0:
            angle = 0
            
        case .angle_90:
            angle = 90
            
        case .angle_180:
            angle = 180
            
        case .angle_270:
            angle = 270
        }
        
        if let photoOutputVideoConnection {
            if photoOutputVideoConnection.isVideoRotationAngleSupported(angle) {
                photoOutputVideoConnection.videoRotationAngle = angle
            }
        }
    }
    
    func updateMovieFileOutputRotation() {
        let movieFileOutputVideoConnection = movieFileOutput.connection(with: .video)
        
        let angle: CGFloat
        
        switch movieFileOutputAngle {
        case .angle_0:
            angle = 0
            
        case .angle_90:
            angle = 90
            
        case .angle_180:
            angle = 180
            
        case .angle_270:
            angle = 270
        }
        
        if let movieFileOutputVideoConnection {
            if movieFileOutputVideoConnection.isVideoRotationAngleSupported(angle) {
                movieFileOutputVideoConnection.videoRotationAngle = angle
            }
        }
    }
    
    func updateVideoDataOutputRotation() {
        let videoDataOutputVideoConnection = videoDataOutput.connection(with: .video)
        
        let angle: CGFloat
        
        switch videoDataOutputAngle {
        case .angle_0:
            angle = 0
            
        case .angle_90:
            angle = 90
            
        case .angle_180:
            angle = 180
            
        case .angle_270:
            angle = 270
        }
        
        if let videoDataOutputVideoConnection {
            if videoDataOutputVideoConnection.isVideoRotationAngleSupported(angle) {
                videoDataOutputVideoConnection.videoRotationAngle = angle
            }
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
            self.cameraDeviceInput = cameraDeviceInput
        } catch {
            print(error)
        }
        
        if #available(iOS 17, *) {
            createRotationCoordinator(for: cameraDevice,
                                      previewLayer: previewLayer)
        } else {
            startDeviceMotionUpdates()
        }
        
        self.setupObserver()
    }
}

extension RotationCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let inputCIImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        if let cgImg = inputCIImage.toCGImage() {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.previewImage = UIImage(cgImage: cgImg)
            }
        }
    }
}

extension RotationCapture: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        guard error == nil else {
            print("Error broken photo data: \(error!)")
            return
        }
        
        guard let photoData = photo.fileDataRepresentation() else {
            print("No photo data to write.")
            return
        }
        
        self.compressedData = photoData
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: (any Error)?
    ) {
        guard error == nil else {
            print("Error capture photo: \(error!)")
            return
        }
        
        guard let compressedData = self.compressedData else {
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

extension RotationCapture: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: (any Error)?
    ) {
        Task {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    creationRequest.addResource(with: .video,
                                                fileURL: outputFileURL,
                                                options: options)
                }
            } catch {
                print(error)
            }
        }
    }
}
