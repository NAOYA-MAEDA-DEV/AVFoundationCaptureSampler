import Photos

final class RawCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published var isAppleProRAWEnabled: Bool = false
    @Published private(set) var isAppleProRAWSupported: Bool = false
    @Published var selectedSaveRAWDataType: SaveRawDataType = .rawWithL
    
    private var rawImageFileURL: URL?
    private var compressedData: Data?
    
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
            self.cameraDeviceInput = cameraDeviceInput
            
            guard captureSession.canAddOutput(photoOutput) else { return }
            captureSession.addOutput(photoOutput)
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer.videoGravity = .resizeAspectFill
            }
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isAppleProRAWSupported = self.photoOutput.isAppleProRAWSupported
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
    
    func capturePhoto() async {
        guard await isAuthorizedCamera else { return }
        
        if isAppleProRAWEnabled {
            photoOutput.isAppleProRAWEnabled = photoOutput.isAppleProRAWSupported
        } else {
            photoOutput.isAppleProRAWEnabled = false
        }
        
        let query = photoOutput.isAppleProRAWEnabled
        ? { AVCapturePhotoOutput.isAppleProRAWPixelFormat($0) }
        : { AVCapturePhotoOutput.isBayerRAWPixelFormat($0) }

        guard let rawFormat =
                photoOutput.availableRawPhotoPixelFormatTypes.first(where: query) else {
            print("No RAW format found.")
            return
        }
        
        let processedFormat = [AVVideoCodecKey: AVVideoCodecType.hevc]

        let captureSettings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat,
                                                     processedFormat: processedFormat)
        
        photoOutput.capturePhoto(with: captureSettings,
                                 delegate: self)
    }
    
    func changeCameraDevice() {
        captureSession.beginConfiguration()
        
        defer {
            captureSession.commitConfiguration()
        }
        
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
    }
}

extension RawCapture: AVCapturePhotoCaptureDelegate {
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
        
        if photo.isRawPhoto {
            rawImageFileURL = makeUniqueTempFileURL(extension: "dng")
            do {
                try photo.fileDataRepresentation()!.write(to: rawImageFileURL!)
            } catch {
                fatalError("couldn't write DNG file to URL")
            }
        } else {
            compressedData = photoData
        }
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
        
        Task { [weak self] in
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            guard status == .authorized else { return }
            guard let self else { return }
            
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    if self.selectedSaveRAWDataType == .rawWithL {
                        creationRequest.addResource(with: .photo,
                                                    data: compressedData,
                                                    options: options)
                        if let rawImageFileURL = self.rawImageFileURL {
                            creationRequest.addResource(with: .alternatePhoto,
                                                        fileURL: rawImageFileURL,
                                                        options: options)
                        }
                    } else {
                        if let rawImageFileURL = self.rawImageFileURL {
                            creationRequest.addResource(with: .photo,
                                                        fileURL: rawImageFileURL,
                                                        options: options)
                        }
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}
