import UIKit
import Photos
import Combine

class MultiCamCapture: NSObject, ObservableObject {
    private var multiCamCaptureSession: AVCaptureMultiCamSession?
    
    private var audioDevicePort: AVCaptureDeviceInput.Port?
    
    private var backWideAngleCameraInput: AVCaptureDeviceInput?
    private var backWideAngleCameraMovieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    private var backWideAngleCameraMovieFileOutputConnection: AVCaptureConnection?
    private var backWideAngleAudioConnection: AVCaptureConnection?
    private var backWideAngleLayerConnection: AVCaptureConnection?
    private var backWideAngleCameraBackgroundTaskID : UIBackgroundTaskIdentifier?
    var backWideAngleCameraPreviewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    private var ultraWideAngleCameraInput: AVCaptureDeviceInput?
    private var ultraWideAngleCameraMovieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    private var ultraWideAngleCameraMovieFileOutputConnection: AVCaptureConnection?
    private var ultraWideAngleAudioConnection: AVCaptureConnection?
    private var ultraWideAngleLayerConnection: AVCaptureConnection?
    private var ultraWideAngleCameraBackgroundTaskID : UIBackgroundTaskIdentifier?
    var ultraWideAngleCameraPreviewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    private var telephotoCameraInput: AVCaptureDeviceInput?
    private var telephotoCameraMovieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    private var telephotoCameraMovieFileOutputConnection: AVCaptureConnection?
    private var telephotoAudioConnection: AVCaptureConnection?
    private var telephotoLayerConnection: AVCaptureConnection?
    private var telephotoCameraBackgroundTaskID : UIBackgroundTaskIdentifier?
    var telephotoCameraPreviewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    private var frontWideAngleCameraInput: AVCaptureDeviceInput?
    private var frontWideAngleCameraMovieFileOutput: AVCaptureMovieFileOutput  = AVCaptureMovieFileOutput()
    private var frontWideAngleCameraMovieFileOutputConnection: AVCaptureConnection?
    private var frontWideAngleAudioConnection: AVCaptureConnection?
    private var frontWideAngleLayerConnection: AVCaptureConnection?
    private var frontWideAngleCameraBackgroundTaskID : UIBackgroundTaskIdentifier?
    var frontWideAngleCameraPreviewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    @Published private(set) var isRecording = false
    @Published private(set) var hardwareCost: Float = 0.0
    @Published private(set) var systemPressureCost: Float = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        Task { [weak self] in
            await self?.setupCamera()
            self?.setupObserver()
        }
    }
    
    func onDissapear() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        multiCamCaptureSession?.stopRunning()
    }
    
    private func setupCamera() async {
        guard await isAuthorizedCamera else { return }
        guard AVCaptureMultiCamSession.isMultiCamSupported else { return }
        multiCamCaptureSession = AVCaptureMultiCamSession()
        setupAudioDevice()
        setupBackWideAngleCamera()
        setupUltraWideAngleCamera()
        setupTelephotoCamera()
        multiCamCaptureSession?.startRunning()
    }
    
    func setupPreview(size: CGSize) {
        backWideAngleCameraPreviewLayer.frame = CGRect(x: 0,
                                                       y: 0,
                                                       width: size.width,
                                                       height: size.height)
        ultraWideAngleCameraPreviewLayer.frame = CGRect(x: 0,
                                                        y: 0,
                                                        width: size.width,
                                                        height: size.height)
        telephotoCameraPreviewLayer.frame = CGRect(x: 0,
                                                   y: 0,
                                                   width: size.width,
                                                   height: size.height)
        frontWideAngleCameraPreviewLayer.frame = CGRect(x: 0,
                                                        y: 0,
                                                        width: size.width,
                                                        height: size.height)
    }
    
    private func setupObserver() {
        guard let multiCamCaptureSession else { return }
        
        multiCamCaptureSession.publisher(for: \.hardwareCost)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.hardwareCost = value
            }
            .store(in: &cancellables)
        
        multiCamCaptureSession.publisher(for: \.systemPressureCost)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.systemPressureCost = value
            }
            .store(in: &cancellables)
    }
    
    private func setupAudioDevice() {
        guard let multiCamCaptureSession else { return }
        
        multiCamCaptureSession.beginConfiguration()
        
        defer {
            multiCamCaptureSession.commitConfiguration()
        }
        
        guard let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio) else {
            return
        }
        let audioDeviceInput: AVCaptureDeviceInput?
        do {
            audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            guard let audioDeviceInput, multiCamCaptureSession.canAddInput(audioDeviceInput) else {
                return
            }
            multiCamCaptureSession.addInputWithNoConnections(audioDeviceInput)
        } catch {
            print(error)
            return
        }
        
        guard let audioDevicePort = audioDeviceInput?.ports(
            for: AVMediaType.audio,
            sourceDeviceType: audioDevice.deviceType,
            sourceDevicePosition: AVCaptureDevice.Position.back).first else {
            return
        }
        self.audioDevicePort = audioDevicePort
    }
    
    private func setupBackWideAngleCamera() {
        guard let multiCamCaptureSession else { return }
        
        multiCamCaptureSession.beginConfiguration()
        
        defer {
            multiCamCaptureSession.commitConfiguration()
        }
        
        guard let backWideAngleCameraDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back) else {
            return
        }
        do {
            backWideAngleCameraInput = try AVCaptureDeviceInput(device: backWideAngleCameraDevice)
            guard let backWideAngleCameraInput, multiCamCaptureSession.canAddInput(backWideAngleCameraInput) else {
                return
            }
            multiCamCaptureSession.addInputWithNoConnections(backWideAngleCameraInput)
            self.backWideAngleCameraInput = backWideAngleCameraInput
        } catch {
            print(error)
            return
        }
        
        guard let backWideAngleCameraPort = backWideAngleCameraInput?.ports(
            for: .video,
            sourceDeviceType: backWideAngleCameraDevice.deviceType,
            sourceDevicePosition: backWideAngleCameraDevice.position).first else {
            return
        }
        
        guard multiCamCaptureSession.canAddOutput(backWideAngleCameraMovieFileOutput) else {
            return
        }
        multiCamCaptureSession.addOutputWithNoConnections(backWideAngleCameraMovieFileOutput)
        backWideAngleCameraMovieFileOutputConnection = AVCaptureConnection(
            inputPorts: [backWideAngleCameraPort],
            output: backWideAngleCameraMovieFileOutput)
        guard let backWideAngleCameraMovieFileOutputConnection,
              multiCamCaptureSession.canAddConnection(backWideAngleCameraMovieFileOutputConnection) else {
            return
        }
        multiCamCaptureSession.addConnection(backWideAngleCameraMovieFileOutputConnection)
        
        if let audioDevicePort {
            backWideAngleAudioConnection = AVCaptureConnection(
                inputPorts: [audioDevicePort],
                output: backWideAngleCameraMovieFileOutput)
        }
        if let backWideAngleAudioConnection,
           multiCamCaptureSession.canAddConnection(backWideAngleAudioConnection) {
            multiCamCaptureSession.addConnection(backWideAngleAudioConnection)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            backWideAngleCameraPreviewLayer.setSessionWithNoConnection(multiCamCaptureSession)
            backWideAngleCameraPreviewLayer.videoGravity = .resizeAspectFill
            backWideAngleLayerConnection = AVCaptureConnection(
                inputPort: backWideAngleCameraPort,
                videoPreviewLayer: backWideAngleCameraPreviewLayer)
            guard let backWideAngleLayerConnection,
                  multiCamCaptureSession.canAddConnection(backWideAngleLayerConnection) else {
                return
            }
            multiCamCaptureSession.addConnection(backWideAngleLayerConnection)
        }
    }
    
    func toggleBackWideAngleCameraSetting() {
        guard let multiCamCaptureSession else { return }
        guard let backWideAngleCameraInput else {
            setupBackWideAngleCamera()
            return
        }
        
        if multiCamCaptureSession.inputs.contains(backWideAngleCameraInput) {
            removeBackWideAngleCamera()
        } else {
            setupBackWideAngleCamera()
        }
    }
    
    private func removeBackWideAngleCamera() {
        guard let multiCamCaptureSession else { return }
        
        if let backWideAngleCameraInput,
           multiCamCaptureSession.inputs.contains(backWideAngleCameraInput) {
            multiCamCaptureSession.removeInput(backWideAngleCameraInput)
        }
        if multiCamCaptureSession.outputs.contains(backWideAngleCameraMovieFileOutput) {
            multiCamCaptureSession.removeOutput(backWideAngleCameraMovieFileOutput)
        }
        if let backWideAngleCameraMovieFileOutputConnection,
           multiCamCaptureSession.connections.contains(backWideAngleCameraMovieFileOutputConnection) {
            multiCamCaptureSession.removeConnection(backWideAngleCameraMovieFileOutputConnection)
        }
        if let backWideAngleAudioConnection,
           multiCamCaptureSession.connections.contains(backWideAngleAudioConnection) {
            multiCamCaptureSession.removeConnection(backWideAngleAudioConnection)
        }
        if let backWideAngleLayerConnection,
           multiCamCaptureSession.connections.contains(backWideAngleLayerConnection) {
            multiCamCaptureSession.removeConnection(backWideAngleLayerConnection)
        }
    }
    
    private func setupFrontWideAngleCamera() {
        guard let multiCamCaptureSession else { return }
        
        multiCamCaptureSession.beginConfiguration()
        
        defer {
            multiCamCaptureSession.commitConfiguration()
        }
        
        guard let frontWideAngleCameraDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front) else {
            return
        }
        do {
            frontWideAngleCameraInput = try AVCaptureDeviceInput(device: frontWideAngleCameraDevice)
            guard let frontWideAngleCameraInput, multiCamCaptureSession.canAddInput(frontWideAngleCameraInput) else {
                return
            }
            multiCamCaptureSession.addInputWithNoConnections(frontWideAngleCameraInput)
            self.frontWideAngleCameraInput = frontWideAngleCameraInput
        }
        catch {
            print(error)
            return
        }
        
        guard let frontWideAngleCameraPort = frontWideAngleCameraInput?.ports(
            for: .video,
            sourceDeviceType: frontWideAngleCameraDevice.deviceType,
            sourceDevicePosition: frontWideAngleCameraDevice.position).first else {
            return
        }
        
        guard multiCamCaptureSession.canAddOutput(frontWideAngleCameraMovieFileOutput) else {
            return
        }
        multiCamCaptureSession.addOutputWithNoConnections(frontWideAngleCameraMovieFileOutput)
        frontWideAngleCameraMovieFileOutputConnection = AVCaptureConnection(
            inputPorts: [frontWideAngleCameraPort],
            output: frontWideAngleCameraMovieFileOutput)
        guard let frontWideAngleCameraMovieFileOutputConnection,
              multiCamCaptureSession.canAddConnection(frontWideAngleCameraMovieFileOutputConnection) else {
            return
        }
        multiCamCaptureSession.addConnection(frontWideAngleCameraMovieFileOutputConnection)
        
        if let audioDevicePort {
            frontWideAngleAudioConnection = AVCaptureConnection(
                inputPorts: [audioDevicePort],
                output: frontWideAngleCameraMovieFileOutput)
        }
        if let frontWideAngleAudioConnection,
           multiCamCaptureSession.canAddConnection(frontWideAngleAudioConnection) {
            multiCamCaptureSession.addConnection(frontWideAngleAudioConnection)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            frontWideAngleCameraPreviewLayer.setSessionWithNoConnection(multiCamCaptureSession)
            frontWideAngleCameraPreviewLayer.videoGravity = .resizeAspectFill
            frontWideAngleLayerConnection = AVCaptureConnection(
                inputPort: frontWideAngleCameraPort,
                videoPreviewLayer: frontWideAngleCameraPreviewLayer)
            guard let frontWideAngleLayerConnection,
                  multiCamCaptureSession.canAddConnection(frontWideAngleLayerConnection) else {
                return
            }
            multiCamCaptureSession.addConnection(frontWideAngleLayerConnection)
        }
    }
    
    func toggleFrontWideAngleCameraSetting() {
        guard let multiCamCaptureSession else { return }
        guard let frontWideAngleCameraInput else {
            setupFrontWideAngleCamera()
            return
        }
        
        if multiCamCaptureSession.inputs.contains(frontWideAngleCameraInput) {
            removeFrontWideAngleCamera()
        } else {
            setupFrontWideAngleCamera()
        }
    }
    
    private func removeFrontWideAngleCamera() {
        guard let multiCamCaptureSession else { return }
        
        if let frontWideAngleCameraInput,
           multiCamCaptureSession.inputs.contains(frontWideAngleCameraInput) {
            multiCamCaptureSession.removeInput(frontWideAngleCameraInput)
        }
        if multiCamCaptureSession.outputs.contains(frontWideAngleCameraMovieFileOutput) {
            multiCamCaptureSession.removeOutput(frontWideAngleCameraMovieFileOutput)
        }
        if let frontWideAngleCameraMovieFileOutputConnection,
           multiCamCaptureSession.connections.contains(frontWideAngleCameraMovieFileOutputConnection) {
            multiCamCaptureSession.removeConnection(frontWideAngleCameraMovieFileOutputConnection)
        }
        if let frontWideAngleAudioConnection,
           multiCamCaptureSession.connections.contains(frontWideAngleAudioConnection) {
            multiCamCaptureSession.removeConnection(frontWideAngleAudioConnection)
        }
        if let frontWideAngleLayerConnection,
           multiCamCaptureSession.connections.contains(frontWideAngleLayerConnection) {
            multiCamCaptureSession.removeConnection(frontWideAngleLayerConnection)
        }
    }
    
    private func setupUltraWideAngleCamera() {
        guard let multiCamCaptureSession else { return }
        
        multiCamCaptureSession.beginConfiguration()
        
        defer {
            multiCamCaptureSession.commitConfiguration()
        }
        
        guard let ultraWideAngleCameraDevice = AVCaptureDevice.default(
            .builtInUltraWideCamera,
            for: .video,
            position: .back) else {
            return
        }
        do {
            ultraWideAngleCameraInput = try AVCaptureDeviceInput(device: ultraWideAngleCameraDevice)
            guard let ultraWideAngleCameraInput, multiCamCaptureSession.canAddInput(ultraWideAngleCameraInput) else {
                return
            }
            multiCamCaptureSession.addInputWithNoConnections(ultraWideAngleCameraInput)
            self.ultraWideAngleCameraInput = ultraWideAngleCameraInput
        } catch {
            print(error)
            return
        }
        
        guard let ultraWideAngleCameraPort = ultraWideAngleCameraInput?.ports(
            for: .video,
            sourceDeviceType: ultraWideAngleCameraDevice.deviceType,
            sourceDevicePosition: ultraWideAngleCameraDevice.position).first else {
            return
        }
        
        ultraWideAngleCameraMovieFileOutput = AVCaptureMovieFileOutput()
        guard multiCamCaptureSession.canAddOutput(ultraWideAngleCameraMovieFileOutput) else {
            return
        }
        multiCamCaptureSession.addOutputWithNoConnections(ultraWideAngleCameraMovieFileOutput)
        ultraWideAngleCameraMovieFileOutputConnection = AVCaptureConnection(
            inputPorts: [ultraWideAngleCameraPort],
            output: ultraWideAngleCameraMovieFileOutput)
        guard let ultraWideAngleCameraMovieFileOutputConnection,
              multiCamCaptureSession.canAddConnection(ultraWideAngleCameraMovieFileOutputConnection) else {
            return
        }
        multiCamCaptureSession.addConnection(ultraWideAngleCameraMovieFileOutputConnection)
        
        if let audioDevicePort {
            ultraWideAngleAudioConnection = AVCaptureConnection(
                inputPorts: [audioDevicePort],
                output: ultraWideAngleCameraMovieFileOutput)
        }
        if let ultraWideAngleAudioConnection,
           multiCamCaptureSession.canAddConnection(ultraWideAngleAudioConnection) {
            multiCamCaptureSession.addConnection(ultraWideAngleAudioConnection)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            ultraWideAngleCameraPreviewLayer.setSessionWithNoConnection(multiCamCaptureSession)
            ultraWideAngleCameraPreviewLayer.videoGravity = .resizeAspectFill
            ultraWideAngleLayerConnection = AVCaptureConnection(
                inputPort: ultraWideAngleCameraPort,
                videoPreviewLayer: ultraWideAngleCameraPreviewLayer)
            guard let ultraWideAngleLayerConnection,
                  multiCamCaptureSession.canAddConnection(ultraWideAngleLayerConnection) else {
                return
            }
            multiCamCaptureSession.addConnection(ultraWideAngleLayerConnection)
        }
    }
    
    func toggleUltraWideAngleCameraSetting() {
        guard let multiCamCaptureSession else { return }
        guard let ultraWideAngleCameraInput else {
            setupFrontWideAngleCamera()
            return
        }
        
        if multiCamCaptureSession.inputs.contains(ultraWideAngleCameraInput) {
            removeUltraWideAngleCamera()
        } else {
            setupUltraWideAngleCamera()
        }
    }
    
    func removeUltraWideAngleCamera() {
        guard let multiCamCaptureSession else { return }
        
        if let ultraWideAngleCameraInput,
           multiCamCaptureSession.inputs.contains(ultraWideAngleCameraInput) {
            multiCamCaptureSession.removeInput(ultraWideAngleCameraInput)
        }
        if multiCamCaptureSession.outputs.contains(ultraWideAngleCameraMovieFileOutput) {
            multiCamCaptureSession.removeOutput(ultraWideAngleCameraMovieFileOutput)
        }
        if let ultraWideAngleCameraMovieFileOutputConnection,
           multiCamCaptureSession.connections.contains(ultraWideAngleCameraMovieFileOutputConnection) {
            multiCamCaptureSession.removeConnection(ultraWideAngleCameraMovieFileOutputConnection)
        }
        if let ultraWideAngleAudioConnection,
           multiCamCaptureSession.connections.contains(ultraWideAngleAudioConnection) {
            multiCamCaptureSession.removeConnection(ultraWideAngleAudioConnection)
        }
        if let ultraWideAngleLayerConnection,
           multiCamCaptureSession.connections.contains(ultraWideAngleLayerConnection) {
            multiCamCaptureSession.removeConnection(ultraWideAngleLayerConnection)
        }
    }
    
    private func setupTelephotoCamera() {
        guard let multiCamCaptureSession else { return }
        
        multiCamCaptureSession.beginConfiguration()
        
        defer {
            multiCamCaptureSession.commitConfiguration()
        }
        
        guard let telephotoCameraDevice = AVCaptureDevice.default(
            .builtInTelephotoCamera,
            for: .video,
            position: .back) else {
            return
        }
        do {
            telephotoCameraInput = try AVCaptureDeviceInput(device: telephotoCameraDevice)
            guard let telephotoCameraInput, multiCamCaptureSession.canAddInput(telephotoCameraInput) else {
                return
            }
            multiCamCaptureSession.addInputWithNoConnections(telephotoCameraInput)
            self.telephotoCameraInput = telephotoCameraInput
        } catch {
            print(error)
            return
        }
        
        guard let telephotoCameraPort = telephotoCameraInput?.ports(
            for: .video,
            sourceDeviceType: telephotoCameraDevice.deviceType,
            sourceDevicePosition: telephotoCameraDevice.position).first else {
            return
        }
        
        self.telephotoCameraMovieFileOutput = AVCaptureMovieFileOutput()
        guard multiCamCaptureSession.canAddOutput(telephotoCameraMovieFileOutput) else {
            return
        }
        multiCamCaptureSession.addOutputWithNoConnections(telephotoCameraMovieFileOutput)
        telephotoCameraMovieFileOutputConnection = AVCaptureConnection(
            inputPorts: [telephotoCameraPort],
            output: telephotoCameraMovieFileOutput)
        
        guard let telephotoCameraMovieFileOutputConnection,
              multiCamCaptureSession.canAddConnection(telephotoCameraMovieFileOutputConnection) else {
            return
        }
        multiCamCaptureSession.addConnection(telephotoCameraMovieFileOutputConnection)
        
        if let audioDevicePort {
            telephotoAudioConnection = AVCaptureConnection(
                inputPorts: [audioDevicePort],
                output: telephotoCameraMovieFileOutput)
        }
        if let telephotoAudioConnection,
           multiCamCaptureSession.canAddConnection(telephotoAudioConnection) {
            multiCamCaptureSession.addConnection(telephotoAudioConnection)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            telephotoCameraPreviewLayer.setSessionWithNoConnection(multiCamCaptureSession)
            telephotoCameraPreviewLayer.videoGravity = .resizeAspectFill
            telephotoLayerConnection = AVCaptureConnection(
                inputPort: telephotoCameraPort,
                videoPreviewLayer: telephotoCameraPreviewLayer)
            guard let telephotoLayerConnection,
                  multiCamCaptureSession.canAddConnection(telephotoLayerConnection) else {
                return
            }
            multiCamCaptureSession.addConnection(telephotoLayerConnection)
        }
    }
    
    func toggleTelephotoCameraSetting() {
        guard let multiCamCaptureSession else { return }
        guard let telephotoCameraInput else {
            setupFrontWideAngleCamera()
            return
        }
        
        if multiCamCaptureSession.inputs.contains(telephotoCameraInput) {
            removeTelephotoCamera()
        } else {
            setupTelephotoCamera()
        }
    }
    
    func removeTelephotoCamera() {
        guard let multiCamCaptureSession else { return }
        
        if let telephotoCameraInput,
           multiCamCaptureSession.inputs.contains(telephotoCameraInput) {
            multiCamCaptureSession.removeInput(telephotoCameraInput)
        }
        if multiCamCaptureSession.outputs.contains(telephotoCameraMovieFileOutput) {
            multiCamCaptureSession.removeOutput(telephotoCameraMovieFileOutput)
        }
        if let telephotoCameraMovieFileOutputConnection,
           multiCamCaptureSession.connections.contains(telephotoCameraMovieFileOutputConnection) {
            multiCamCaptureSession.removeConnection(telephotoCameraMovieFileOutputConnection)
        }
        if let telephotoAudioConnection,
           multiCamCaptureSession.connections.contains(telephotoAudioConnection) {
            multiCamCaptureSession.removeConnection(telephotoAudioConnection)
        }
        if let telephotoLayerConnection,
           multiCamCaptureSession.connections.contains(telephotoLayerConnection) {
            multiCamCaptureSession.removeConnection(telephotoLayerConnection)
        }
    }
    
    func controlRecording() {
        guard let multiCamCaptureSession else { return }
        
        if isRecording {
            if backWideAngleCameraMovieFileOutput.isRecording {
                backWideAngleCameraMovieFileOutput.stopRecording()
            }
            if frontWideAngleCameraMovieFileOutput.isRecording {
                frontWideAngleCameraMovieFileOutput.stopRecording()
            }
            if ultraWideAngleCameraMovieFileOutput.isRecording {
                ultraWideAngleCameraMovieFileOutput.stopRecording()
            }
            if telephotoCameraMovieFileOutput.isRecording {
                telephotoCameraMovieFileOutput.stopRecording()
            }
            isRecording = false
            AudioServicesPlaySystemSound(1118)
        } else {
            if let backWideAngleCameraInput,
               multiCamCaptureSession.inputs.contains(backWideAngleCameraInput) {
                let backWideAngleCameraMovieFileURL: URL = makeUniqueTempFileURL(extension: "mov")
                backWideAngleCameraMovieFileOutput.startRecording(to: backWideAngleCameraMovieFileURL, recordingDelegate: self)
                backWideAngleCameraBackgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            }
            if let frontWideAngleCameraInput,
               multiCamCaptureSession.inputs.contains(frontWideAngleCameraInput) {
                let frontWideAngleCameraMovieFileURL: URL = makeUniqueTempFileURL(extension: "mov")
                frontWideAngleCameraMovieFileOutput.startRecording(to: frontWideAngleCameraMovieFileURL, recordingDelegate: self)
                frontWideAngleCameraBackgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            }
            if let ultraWideAngleCameraInput,
               multiCamCaptureSession.inputs.contains(ultraWideAngleCameraInput) {
                let ultraWideAngleCameraMovieFileURL: URL = makeUniqueTempFileURL(extension: "mov")
                ultraWideAngleCameraMovieFileOutput.startRecording(to: ultraWideAngleCameraMovieFileURL, recordingDelegate: self)
                ultraWideAngleCameraBackgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            }
            if let telephotoCameraInput,
               multiCamCaptureSession.inputs.contains(telephotoCameraInput) {
                let telephotoCameraMovieFileURL: URL = makeUniqueTempFileURL(extension: "mov")
                telephotoCameraMovieFileOutput.startRecording(to: telephotoCameraMovieFileURL, recordingDelegate: self)
                telephotoCameraBackgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            }
            isRecording = true
            AudioServicesPlaySystemSound(1117)
        }
    }
}

extension MultiCamCapture: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: (any Error)?
    ) {
        Task { [weak self] in
            guard let self else { return }
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
            if output == self.backWideAngleCameraMovieFileOutput {
                if let currentBackgroundRecordingID = self.backWideAngleCameraBackgroundTaskID {
                    self.backWideAngleCameraBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
                    
                    if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                        await UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                    }
                }
            } else if output == self.frontWideAngleCameraMovieFileOutput {
                if let currentBackgroundRecordingID = self.frontWideAngleCameraBackgroundTaskID {
                    self.frontWideAngleCameraBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
                    
                    if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                        await UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                    }
                }
            } else if output == self.ultraWideAngleCameraMovieFileOutput {
                if let currentBackgroundRecordingID = self.ultraWideAngleCameraBackgroundTaskID {
                    self.ultraWideAngleCameraBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
                    
                    if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                        await UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                    }
                }
            } else if output == self.telephotoCameraMovieFileOutput {
                if let currentBackgroundRecordingID = self.telephotoCameraBackgroundTaskID {
                    self.telephotoCameraBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
                    
                    if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                        await UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                    }
                }
            }
        }
    }
}
