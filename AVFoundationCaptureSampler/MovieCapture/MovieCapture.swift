import Photos

final class MovieCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private let movieFileOutput = AVCaptureMovieFileOutput()
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published private(set) var recordingState: RecordingState = .notRecording
    
    let presets: [AVCaptureSession.Preset] = [
        .high,
        .medium,
        .low,
        .photo,
        .inputPriority,
        .hd1280x720,
        .hd1920x1080,
        .hd4K3840x2160,
        .vga640x480,
        .iFrame1280x720,
        .iFrame960x540,
        .cif352x288
    ]
    @Published var selectedPreset: AVCaptureSession.Preset = .high
    
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
            
            guard captureSession.canAddOutput(movieFileOutput) else { return }
            captureSession.addOutput(movieFileOutput)
            
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
    
    func changeCapturePreset() {
        guard !movieFileOutput.isRecording else { return }
        
        captureSession.beginConfiguration()
        
        if captureSession.canSetSessionPreset(selectedPreset) {
            captureSession.sessionPreset = selectedPreset
        } else {
            selectedPreset = captureSession.sessionPreset
        }
        
        captureSession.commitConfiguration()
    }
    
    func controlRecording() {
        if !movieFileOutput.isRecording {
            let fileURL: URL = makeUniqueTempFileURL(extension: "mov")
            movieFileOutput.startRecording(to: fileURL,
                                           recordingDelegate: self)
            recordingState = .recording
        } else if movieFileOutput.isRecording {
            movieFileOutput.stopRecording()
        }
    }
    
    @available(iOS 18.0, *)
    func pauseRecording() {
        if movieFileOutput.isRecording {
            movieFileOutput.pauseRecording()
            recordingState = .pause
        }
    }
    
    @available(iOS 18.0, *)
    func resumeRecording() {
        if movieFileOutput.isRecordingPaused {
            movieFileOutput.resumeRecording()
            recordingState = .recording
        }
    }
}

extension MovieCapture: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        print("\(#function)")
        
        AudioServicesPlaySystemSound(1117)
    }
    
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didPauseRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        print("\(#function)")
    }
    
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didResumeRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        print("\(#function)")
    }
    
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        print("\(#function)")
        
        AudioServicesPlaySystemSound(1118)
        
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
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.recordingState = .notRecording
            }
            
            //            if FileManager.default.fileExists(atPath: outputFileURL.path()) {
            //                print("The movie file exists.")
            //
            //            } else {
            //                print("The movie file has been deleted.")
            //            }
        }
    }
}

