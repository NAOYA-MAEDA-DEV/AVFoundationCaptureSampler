import Photos

final class LivePhotosCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published var isLivePhotos = false
    
    @Published private(set) var shouldFlashScreen = false
    
    private var compressedData: Data?
    private var livePhotosMovieURL: URL?
    
    @Published private(set) var isProcessing = false
    
    override init() {
        super.init()
        Task { [weak self] in
            await self?.setupCamera()
            self?.captureSession.startRunning()
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
            
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                return
            }
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            guard captureSession.canAddInput(audioDeviceInput) else { return }
            captureSession.addInput(audioDeviceInput)
            
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
            
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
        } catch {
            print(error)
        }
    }
    
    func setupPreview(size: CGSize) {
        photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
        
        previewLayer.frame = CGRect(x: 0,
                                    y: 0,
                                    width: size.width,
                                    height: size.height)
    }
    
    func captureLivePhotos() {
        let captureSettings = AVCapturePhotoSettings()
        let livePhotoMovieFileName = NSUUID().uuidString
        let livePhotoMovieFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((livePhotoMovieFileName as NSString).appendingPathExtension("mov")!)
        captureSettings.livePhotoMovieFileURL = URL(fileURLWithPath: livePhotoMovieFilePath)
        photoOutput.capturePhoto(with: captureSettings,
                                 delegate: self)
    }
}

extension LivePhotosCapture: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        print("\(#function)")
        
        isProcessing = true
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        print("\(#function)")
        
        shouldFlashScreen = true
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        print("\(#function)")
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        print("\(#function)")
        
        shouldFlashScreen = false
        
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
        didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL,
        resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        print("\(#function)")
        
        isProcessing = false
        
        AudioServicesPlaySystemSound(1118)
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL,
        duration: CMTime,
        photoDisplayTime: CMTime,
        resolvedSettings: AVCaptureResolvedPhotoSettings,
        error:(any Error)?
    ) {
        print("\(#function)")
        
        if error != nil {
            print("Error processing Live Photo companion movie: \(error!)")
            return
        }
        
        self.livePhotosMovieURL = outputFileURL
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: (any Error)?
    ) {
        print("\(#function)")
        
        guard error == nil else {
            print("Error capture photo: \(error!)")
            return
        }
        
        guard let compressedData = self.compressedData else {
            print("The expected photo data isn't available.")
            return
        }
        
        guard let livePhotosMovieURL = self.livePhotosMovieURL else {
            print("The expected movie data isn't available.")
            return
        }
        
        Task {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo,
                                                data: compressedData,
                                                options: nil)
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    creationRequest.addResource(with: .pairedVideo,
                                                fileURL: livePhotosMovieURL,
                                                options: options)
                }
            } catch {
                print(error)
            }
        }
    }
}
