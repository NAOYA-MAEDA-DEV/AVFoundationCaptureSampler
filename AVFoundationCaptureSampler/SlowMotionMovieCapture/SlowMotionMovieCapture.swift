import AVFoundation
import Photos

final class SlowMotionMovieCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDevice: AVCaptureDevice?
    private let movieFileOutput = AVCaptureMovieFileOutput()
    @Published var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published var selectedFps: Fps = .fps30
    @Published private(set) var isRecording = false
    
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
                captureSession.commitConfiguration()
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
        setupFps()
    }
    
    func setupFps(){
        guard let cameraDevice else { return }
//        let formats = cameraDevice.formats
//        for format in cameraDevice.formats {
//            print(format.description)
//        }
        
        let desiredFpsValue: Float64
        
        switch selectedFps {
        case .fps30:
            desiredFpsValue = 30
            
        case .fps60:
            desiredFpsValue = 60
            
        case .fps120:
            desiredFpsValue = 120
            
        case .fps240:
            desiredFpsValue = 240
        }
        
        var selectedFormat: AVCaptureDevice.Format! = nil
        let currentDimensions = getCurrentResolution(device: cameraDevice)
        
        for format in (cameraDevice.formats) {
            for range in format.videoSupportedFrameRateRanges{
                let desc = format.formatDescription
                let dimentions = CMVideoFormatDescriptionGetDimensions(desc)
                
                if (240 <= range.maxFrameRate &&
                    currentDimensions.width == dimentions.width &&
                    currentDimensions.height == dimentions.height) {
                    selectedFormat = format
                    
                    do {
                        try cameraDevice.lockForConfiguration()
                        
                        cameraDevice.activeFormat = selectedFormat
                        cameraDevice.activeVideoMinFrameDuration = CMTimeMake(
                            value: 1,
                            timescale: Int32(desiredFpsValue))
                        cameraDevice.activeVideoMaxFrameDuration = CMTimeMake(
                            value: 1,
                            timescale: Int32(desiredFpsValue))
                        
                        cameraDevice.unlockForConfiguration()
                        
                        return
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
    
    private func getCurrentResolution(device: AVCaptureDevice) -> CMVideoDimensions {
        let formatDescription = device.activeFormat.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        return dimensions
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
}

extension SlowMotionMovieCapture: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: (any Error)?
    ) {
        Task {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            guard status == .authorized else { return }
            
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
