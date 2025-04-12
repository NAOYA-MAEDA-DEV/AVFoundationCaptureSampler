import Photos
import Combine

final class MovieWriterCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDevice: AVCaptureDevice?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let audioDataOutput = AVCaptureAudioDataOutput()
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published private(set) var isRecording = false
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator!
    private var observations = [NSKeyValueObservation]()
    private var videoTransform: CGAffineTransform = .identity
    
    private var movieWriter: MovieWriter?
    
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
            self.cameraDevice = cameraDevice
            let cameraDeviceInput = try AVCaptureDeviceInput(device: cameraDevice)
            guard captureSession.canAddInput(cameraDeviceInput) else { return }
            captureSession.addInput(cameraDeviceInput)
            
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                return
            }
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            guard captureSession.canAddInput(audioDeviceInput) else { return }
            captureSession.addInput(audioDeviceInput)
            
            guard captureSession.canAddOutput(videoDataOutput) else { return }
            videoDataOutput.setSampleBufferDelegate(
                self,
                queue: DispatchQueue(label: "video_data_dispatchqueue"))
            captureSession.addOutput(videoDataOutput)
            
            guard captureSession.canAddOutput(audioDataOutput) else { return }
            audioDataOutput.setSampleBufferDelegate(
                self,
                queue: DispatchQueue(label: "audio_data_dispatchqueue"))
            captureSession.addOutput(audioDataOutput)
            
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
        
        guard let cameraDevice else { return }
        createRotationCoordinator(for: cameraDevice)
    }
    
    private func createRotationCoordinator(for device: AVCaptureDevice) {
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(
            device: device,
            previewLayer: nil)
        
        updatePreview(angle: rotationCoordinator.videoRotationAngleForHorizonLevelCapture)
        
        observations.append(
            rotationCoordinator
                .observe(\.videoRotationAngleForHorizonLevelCapture, options: .new) { [weak self] _ , change in
                guard let angle = change.newValue else { return }
                self?.updatePreview(angle: angle)
            }
        )
    }
    
    private func updatePreview(angle: CGFloat) {
        videoTransform = CGAffineTransform(rotationAngle: angle / 180 * Double.pi)
    }
    
    func controlRecording() async {
        if isRecording {
            isRecording = false
            
            guard let movieWriter else { return }
            
            if let url = await movieWriter.stopRecording() {
                await saveAssetWith(url: url)
            }
            
            AudioServicesPlaySystemSound(1118)
        } else {
            guard let audioSettings = audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov) else {
                return
            }
            
            guard let videoSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov) else {
                return
            }
            movieWriter = MovieWriter(audioSettings: audioSettings,
                                      videoSettings: videoSettings,
                                      videoTransform: videoTransform)
            
            guard let movieWriter else { return }
            
            movieWriter.startRecording()
            
            isRecording = true
            
            AudioServicesPlaySystemSound(1117)
        }
    }
    
    private func saveAssetWith(url: URL) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                creationRequest.addResource(with: .video,
                                            fileURL: url,
                                            options: options)
            }
        } catch {
            print(error)
        }
    }
}

extension MovieWriterCapture: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let movieWriter else { return }
        
        if isRecording {
            if let _ = output as? AVCaptureVideoDataOutput {
                movieWriter.recordVideo(
                    sampleBuffer: sampleBuffer,
                    isVideo: true)
            } else if let _ = output as? AVCaptureAudioDataOutput {
                movieWriter.recordVideo(
                    sampleBuffer: sampleBuffer,
                    isVideo: false)
            }
        }
    }
}
