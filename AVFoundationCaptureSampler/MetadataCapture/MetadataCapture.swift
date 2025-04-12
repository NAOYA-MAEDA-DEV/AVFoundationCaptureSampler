import Photos

final class MetadataCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    @Published var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published private(set) var isRecording = false
    
    @Published var selectedMetadataType: MetadataType = .face
    @Published private(set) var metadataDescription: String = ""
    
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
            
            guard captureSession.canAddOutput(metadataOutput) else { return }
            captureSession.addOutput(metadataOutput)
            metadataOutput.metadataObjectTypes = [.qr]
            metadataOutput.setMetadataObjectsDelegate(
                self,
                queue: DispatchQueue(label: "meta_data_dispatchqueue"))
            
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
    
    func changeDetectingMetadataType() {
        metadataOutput.metadataObjectTypes.removeAll()
        
        switch selectedMetadataType {
        case .qrcode:
            metadataOutput.metadataObjectTypes = [.qr]
            
        case .humanBody:
            metadataOutput.metadataObjectTypes = [.humanBody]
            
        case .humanFullBody:
            metadataOutput.metadataObjectTypes = [.humanFullBody]
            
        case .dogBody:
            metadataOutput.metadataObjectTypes = [.dogBody]
            
        case .catBody:
            metadataOutput.metadataObjectTypes = [.catBody]
            
        case .face:
            metadataOutput.metadataObjectTypes = [.face]
        }
    }
}

extension MetadataCapture: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        for metadataObject in metadataObjects {
            if let machineReadableCode = metadataObject as? AVMetadataMachineReadableCodeObject,
               machineReadableCode.type == .qr {
                metadataDescription = "The content of QR code: \(machineReadableCode.description)"
            }
            
            if let humanBody = metadataObject as? AVMetadataHumanBodyObject {
                metadataDescription = "Detect human body: \(humanBody.description)"
            }
            
            if let humanFullBody = metadataObject as? AVMetadataHumanFullBodyObject {
                metadataDescription = "Detect human full body: \(humanFullBody.description)"
            }
            
            if let catBody = metadataObject as? AVMetadataCatBodyObject {
                metadataDescription = "Detect cat body: \(catBody.description)"
            }
            
            if let dogBody = metadataObject as? AVMetadataDogBodyObject {
                metadataDescription = "Detect dog body: \(dogBody.description)"
            }
        }
    }
}
