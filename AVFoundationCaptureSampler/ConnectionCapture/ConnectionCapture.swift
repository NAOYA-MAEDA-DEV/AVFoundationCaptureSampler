import UIKit
import Photos
import Combine

final class ConnectionCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDevice: AVCaptureDevice?
    private var cameraDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published private(set) var videoStabilizationModeStr: String = ""
    
    @Published private(set) var previewImage: UIImage?
    @Published private(set) var isRecording = false
    @Published var videoStabilizationMode: VideoStabilizationMode = .off
    @Published var isAutomaticallyAdjustsPreviewLayerVideoMirroring = false
    @Published var isAutomaticallyAdjustsPhotoOutputVideoMirroring = false
    @Published var isAutomaticallyAdjustsMovieOutputVideoMirroring = false
    @Published var isAutomaticallyAdjustsVideoDataOutputVideoMirroring = false
    @Published var isPreviewLayerVideoMirrored = false
    @Published var isPhotoOutputVideoMirrored = false
    @Published var isMovieFileOutputVideoMirrored = false
    @Published var isVideoDataOutputVideoMirroring = false
    
    private var compressedData: Data?
    
    @Published private(set) var cameraDevices: [AVCaptureDevice] = []
    @Published var selectedCameraIndex = 0
    
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
            
            print("Input: BackWideAngleLensCamera / Output: Nothing")
            var connections = movieFileOutput.connections
            for connection in connections {
                print(connection.description)
            }
            checkConnection(connections: connections)
            
            guard captureSession.canAddOutput(movieFileOutput) else { return }
            captureSession.addOutput(movieFileOutput)
            
            print("Input: BackWideAngleLensCamera / Output: AVCaptureMovieFileOutput")
            
            connections = movieFileOutput.connections
            for connection in connections {
                print(connection.description)
            }
            
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                captureSession.commitConfiguration()
                return
            }
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            guard captureSession.canAddInput(audioDeviceInput) else { return }
            captureSession.addInput(audioDeviceInput)
            
            print("Input: BackWideAngleLensCamera, Microphone / Output: AVCaptureMovieFileOutput")
            
            connections = movieFileOutput.connections
            for connection in connections {
                print(connection.description)
            }
            
            guard captureSession.canAddOutput(videoDataOutput) else { return }
            videoDataOutput.setSampleBufferDelegate(
                self,
                queue: DispatchQueue(label: "video_data_dispatchqueue"))
            captureSession.addOutput(videoDataOutput)
            
            guard captureSession.canAddOutput(photoOutput) else { return }
            captureSession.addOutput(photoOutput)
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer.videoGravity = .resizeAspectFill
                self.setupObserver()
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
    
    private func setupObserver() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        if let movieFileOutputConnection = movieFileOutput.connection(with: .video) {
            movieFileOutputConnection.publisher(for: \.preferredVideoStabilizationMode)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newMode in
                    print(newMode.rawValue.description)
                    switch newMode {
                    case .off:
                        self?.videoStabilizationModeStr = "Off"
                        
                    case .standard:
                        self?.videoStabilizationModeStr = "Standard"
                        
                    case .cinematic:
                        self?.videoStabilizationModeStr = "Cinematic"
                        
                    case .cinematicExtended:
                        self?.videoStabilizationModeStr = "CinematicExtended"
                        
                    case .previewOptimized:
                        self?.videoStabilizationModeStr = "PreviewOptimized"
                        
                    case .cinematicExtendedEnhanced:
                        self?.videoStabilizationModeStr = "CinematicExtendedEnhanced"
                        
                    case .auto:
                        self?.videoStabilizationModeStr = "Auto"
                        
                    @unknown default:
                        fatalError()
                    }
                }
                .store(in: &cancellables)
            
            movieFileOutputConnection.publisher(for: \.automaticallyAdjustsVideoMirroring)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newMode in
                    self?.isAutomaticallyAdjustsMovieOutputVideoMirroring = newMode
                }
                .store(in: &cancellables)
            
            movieFileOutputConnection.publisher(for: \.isVideoMirrored)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newMode in
                    guard !movieFileOutputConnection.automaticallyAdjustsVideoMirroring else { return }
                    self?.isMovieFileOutputVideoMirrored = newMode
                }
                .store(in: &cancellables)
        }
        
        if let previewLayerConnection = previewLayer.connection {
            previewLayerConnection.publisher(for: \.automaticallyAdjustsVideoMirroring)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newMode in
                    self?.isAutomaticallyAdjustsPreviewLayerVideoMirroring = newMode
                }
                .store(in: &cancellables)
            
            previewLayerConnection.publisher(for: \.isVideoMirrored)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newMode in
                    guard !previewLayerConnection.automaticallyAdjustsVideoMirroring else { return }
                    self?.isPreviewLayerVideoMirrored = newMode
                }
                .store(in: &cancellables)
        }
        
        if let photoOutputConnection = photoOutput.connection(with: .video) {
            photoOutputConnection.publisher(for: \.automaticallyAdjustsVideoMirroring)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newMode in
                    self?.isAutomaticallyAdjustsPhotoOutputVideoMirroring = newMode
                }
                .store(in: &cancellables)
            
            photoOutputConnection.publisher(for: \.isVideoMirrored)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newMode in
                    guard !photoOutputConnection.automaticallyAdjustsVideoMirroring else { return }
                    self?.isPhotoOutputVideoMirrored = newMode
                }
                .store(in: &cancellables)
        }
        
        if let videoDataOutputConnection = videoDataOutput.connection(with: .video) {
            videoDataOutputConnection.publisher(for: \.automaticallyAdjustsVideoMirroring)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newMode in
                    self?.isAutomaticallyAdjustsVideoDataOutputVideoMirroring = newMode
                }
                .store(in: &cancellables)
            
            videoDataOutputConnection.publisher(for: \.isVideoMirrored)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newMode in
                    guard !videoDataOutputConnection.automaticallyAdjustsVideoMirroring else { return }
                    self?.isVideoDataOutputVideoMirroring = newMode
                }
                .store(in: &cancellables)
        }
    }
    
    private func checkConnection(connections: [AVCaptureConnection]) {
        for connection in connections {
            let ports = connection.inputPorts
            
            print("Input Ports")
            
            for port in ports {
                print(port.description)
            }
            
            print("Output")
            
            print(connection.output?.description ?? "Nothing")
        }
    }
    
    func changeVideoStabilization() {
        guard let cameraDevice else { return }
        
        let videoStabilizationMode: AVCaptureVideoStabilizationMode
        switch self.videoStabilizationMode {
        case .off:
            videoStabilizationMode = .off
            
        case .standard:
            videoStabilizationMode = .standard
            
        case .cinematic:
            videoStabilizationMode = .cinematic
            
        case .cinematicExtended:
            videoStabilizationMode = .cinematicExtended
            
        case .previewOptimized:
            videoStabilizationMode = .previewOptimized
            
        case .cinematicExtendedEnhanced:
            if #available(iOS 18, *) {
                videoStabilizationMode = .cinematicExtendedEnhanced
            } else {
                videoStabilizationMode = .cinematicExtended
            }
            
        case .auto:
            videoStabilizationMode = .auto
        }
        
        if let videoConnection = movieFileOutput.connection(with: .video) {
            if videoConnection.isVideoStabilizationSupported,
               cameraDevice.activeFormat.isVideoStabilizationModeSupported(videoStabilizationMode) {
                videoConnection.preferredVideoStabilizationMode = videoStabilizationMode
            } else {
                switch videoConnection.preferredVideoStabilizationMode {
                case .off:
                    self.videoStabilizationMode = .off
                    
                case .standard:
                    self.videoStabilizationMode = .standard
                    
                case .cinematic:
                    self.videoStabilizationMode = .cinematic
                    
                case .cinematicExtended:
                    self.videoStabilizationMode = .cinematicExtended
                    
                case .previewOptimized:
                    self.videoStabilizationMode = .previewOptimized
                    
                case .cinematicExtendedEnhanced:
                    self.videoStabilizationMode = .cinematicExtendedEnhanced
                    
                case .auto:
                    self.videoStabilizationMode = .auto
                    
                @unknown default:
                    fatalError()
                }
            }
        }
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
            movieFileOutput.startRecording(to: fileURL, recordingDelegate: self)
            isRecording = true
            AudioServicesPlaySystemSound(1117)
        }
    }
    
    func toggleAutomaticallyAdjustsPreviewLayerVideoMirroring() {
        let previewLayerConnection = previewLayer.connection
        previewLayerConnection?.automaticallyAdjustsVideoMirroring = isAutomaticallyAdjustsPreviewLayerVideoMirroring
    }
    
    func toggleAutomaticallyAdjustsPhotoOutputVideoMirroring() {
        let photoOutputConnection = photoOutput.connection(with: .video)
        photoOutputConnection?.automaticallyAdjustsVideoMirroring = isAutomaticallyAdjustsPhotoOutputVideoMirroring
    }
    
    func toggleAutomaticallyAdjustsMovieOutputVideoMirroring() {
        let movieFileOutputVideoConnection = movieFileOutput.connection(with: .video)
        movieFileOutputVideoConnection?.automaticallyAdjustsVideoMirroring = isAutomaticallyAdjustsMovieOutputVideoMirroring
    }
    
    func toggleAutomaticallyAdjustsVideoDataOutputVideoMirroring() {
        let videoDataOutputConnection = videoDataOutput.connection(with: .video)
        videoDataOutputConnection?.automaticallyAdjustsVideoMirroring = isAutomaticallyAdjustsVideoDataOutputVideoMirroring
    }
    
    func togglePreviewLayerVideoMirrored() {
        let previewConnection = previewLayer.connection
        previewConnection?.isVideoMirrored = isPreviewLayerVideoMirrored
    }
    
    func togglePhotoOutputVideoMirrored() {
        let photoOutputConnection = photoOutput.connection(with: .video)
        photoOutputConnection?.isVideoMirrored = isPhotoOutputVideoMirrored
    }
    
    func toggleMovieOutputVideoMirrored() {
        let movieFileOutputConnection = movieFileOutput.connection(with: .video)
        movieFileOutputConnection?.isVideoMirrored = isMovieFileOutputVideoMirrored
    }
    
    func toggleVideoDataOutputVideoMirrored() {
        let videoDataOutputConnection = videoDataOutput.connection(with: .video)
        videoDataOutputConnection?.isVideoMirrored = isVideoDataOutputVideoMirroring
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
        self.cameraDevice = cameraDevice
        
        do {
            let cameraDeviceInput = try AVCaptureDeviceInput(device: cameraDevice)
            guard captureSession.canAddInput(cameraDeviceInput) else { fatalError() }
            captureSession.addInput(cameraDeviceInput)
            self.cameraDeviceInput = cameraDeviceInput
        } catch {
            print(error)
        }
        
        self.setupObserver()
    }
}

extension ConnectionCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
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

extension ConnectionCapture: AVCaptureFileOutputRecordingDelegate {
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

extension ConnectionCapture: AVCapturePhotoCaptureDelegate {
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
        
        compressedData = photoData
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
