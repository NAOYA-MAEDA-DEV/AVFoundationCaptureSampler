import Photos

final class AppleLogCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDeviceInput: AVCaptureDeviceInput?
    private var cameraDevice: AVCaptureDevice?
    private let movieFileOutput = AVCaptureMovieFileOutput()
    @Published var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published private(set) var isRecording = false
    
    private let cameraDeviceTypes: [AVCaptureDevice.DeviceType] = [
        .builtInWideAngleCamera,
        .builtInUltraWideCamera,
        .builtInTelephotoCamera,
        .builtInDualCamera,
        .builtInDualWideCamera,
        .builtInTripleCamera
    ]
    
    @Published private(set) var cameraDevices: [AVCaptureDevice] = []
    
    @Published var selectedCameraDeviceIndex = 0
    
    override init() {
        super.init()
        cameraDevices = getAvailableCameraDevices()
        Task { [weak self] in
            guard let self else { return }
            await self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    
    func onDissapear() {
        captureSession.stopRunning()
    }
    
    private func setupCaptureSession() async {
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
            self.cameraDeviceInput = cameraDeviceInput
            
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
            
            captureSession.automaticallyConfiguresCaptureDeviceForWideColor = false
        } catch {
            print(error)
        }
    }
    
    func setupPreview(size: CGSize) {
        previewLayer.frame = CGRect(x: 0,
                                    y: 0,
                                    width: size.width,
                                    height: size.height)
        Task {
            if let cameraDevice, self.isAppleProResLogAvailable(for: cameraDevice) {
                await self.setupAppleProResLog()
            }
        }
    }
    
    private func setupAppleProResLog() async {
        guard let cameraDevice else { return }
        
        do {
            try cameraDevice.lockForConfiguration()
            
            if let format = cameraDevice.formats.first(where: {
                $0.supportedColorSpaces.contains(.appleLog)
            })
            {
                cameraDevice.activeFormat = format
                cameraDevice.activeColorSpace = .appleLog
            }
            
            let frameRate = CMTimeMake(value: 1,
                                       timescale: 30)
            cameraDevice.activeVideoMinFrameDuration = frameRate
            cameraDevice.activeVideoMaxFrameDuration = frameRate
            
            cameraDevice.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    private func isAppleProResLogAvailable(for device: AVCaptureDevice) -> Bool {
        device.formats.first(where: {
            $0.supportedColorSpaces.contains(.appleLog)
        }) != nil
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
    
    func changeCameraDevice() async {
        captureSession.beginConfiguration()
        
        if let cameraDeviceInput {
            captureSession.removeInput(cameraDeviceInput)
        }
        
        let cameraDevice = cameraDevices[selectedCameraDeviceIndex]
        
        do {
            let cameraDeviceInput = try AVCaptureDeviceInput(device: cameraDevice)
            guard captureSession.canAddInput(cameraDeviceInput) else { fatalError() }
            captureSession.addInput(cameraDeviceInput)
            self.cameraDeviceInput = cameraDeviceInput
        } catch {
            print(error)
        }
        
        if self.isAppleProResLogAvailable(for: cameraDevice) {
            await self.setupAppleProResLog()
        }
        
        captureSession.commitConfiguration()
    }
}

extension AppleLogCapture: AVCaptureFileOutputRecordingDelegate {
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
