import Photos

final class PhotoSettingsCapture: NSObject, ObservableObject {
    private let captureSession = AVCaptureSession()
    private var cameraDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published var saveImageFormatType: SaveImageFormatType = .jpeg
    @Published var photoQualityPrioritization: PhotoQualityPrioritization = .balanced
    @Published var exifLocationisOn: Bool = true
    @Published var isAutoRedEyeReductionEnabled: Bool = true
    @Published var isBracketSettingsEnabled: Bool = false
    
    private var compressedData: Data?
    
    @Published private(set) var cameraDevices: [AVCaptureDevice] = []
    
    @Published var selectedCameraDeviceIndex = 0
    
    private var locationManager: LocationManager = LocationManager()
    
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
        locationManager.stopLocationUpdate()
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
        let captureSettings: AVCapturePhotoSettings!
        
        if isBracketSettingsEnabled {
            let exposureValues: [Float] = [-2, 0, +2]
            let makeAutoExposureSettings = AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias:)
            let exposureSettings = exposureValues.map(makeAutoExposureSettings)
            
            switch saveImageFormatType {
            case .jpeg:
                captureSettings = AVCapturePhotoBracketSettings(
                    rawPixelFormatType: 0,
                    processedFormat: [AVVideoCodecKey: AVVideoCodecType.jpeg],
                    bracketedSettings: exposureSettings)
                
            case .heic:
                captureSettings = AVCapturePhotoBracketSettings(
                    rawPixelFormatType: 0,
                    processedFormat: [AVVideoCodecKey: AVVideoCodecType.hevc],
                    bracketedSettings: exposureSettings)
            }
        } else {
            switch saveImageFormatType {
            case .jpeg:
                captureSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                
            case .heic:
                captureSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            
            captureSettings.isAutoRedEyeReductionEnabled = isAutoRedEyeReductionEnabled
        }
        
        var meta: [String: Any] = [:]
        meta[kCGImagePropertyTIFFSoftware as String] = "Your App"
        meta[kCGImagePropertyTIFFArtist as String] = "Your Artist Name"
        meta[kCGImagePropertyTIFFCopyright as String] = "Your Copyright Name"
        captureSettings.metadata["{TIFF}"] = meta
        
        captureSettings.embeddedThumbnailPhotoFormat = [
            AVVideoCodecKey: AVVideoCodecType.jpeg,
            AVVideoWidthKey: 100,
            AVVideoHeightKey: 100
        ]
        
        if exifLocationisOn,
           let location = locationManager.getLocation(),
           let gpsDictionary = createLocationMetadata(location: location) {
            captureSettings.metadata[kCGImagePropertyGPSDictionary as String] = gpsDictionary
        }
        
        photoOutput.maxPhotoQualityPrioritization = .quality
        
        switch photoQualityPrioritization {
        case .speed:
            captureSettings.photoQualityPrioritization = .speed
        case .quality:
            captureSettings.photoQualityPrioritization = .quality
        case .balanced:
            captureSettings.photoQualityPrioritization =  .balanced
        }
        
        photoOutput.capturePhoto(with: captureSettings,
                                 delegate: self)
    }
    
    private func createLocationMetadata(location: CLLocation) -> NSMutableDictionary? {
        let gpsDictionary = NSMutableDictionary()
        var latitude = location.coordinate.latitude
        var longitude = location.coordinate.longitude
        var altitude = location.altitude
        var latitudeRef = "N"
        var longitudeRef = "E"
        var altitudeRef = 0
        
        if latitude < 0.0 {
            latitude = -latitude
            latitudeRef = "S"
        }
        
        if longitude < 0.0 {
            longitude = -longitude
            longitudeRef = "W"
        }
        
        if altitude < 0.0 {
            altitude = -altitude
            altitudeRef = 1
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd"
        gpsDictionary[kCGImagePropertyGPSDateStamp] = formatter.string(from:location.timestamp)
        formatter.dateFormat = "HH:mm:ss"
        gpsDictionary[kCGImagePropertyGPSTimeStamp] = formatter.string(from:location.timestamp)
        gpsDictionary[kCGImagePropertyGPSLatitudeRef] = latitudeRef
        gpsDictionary[kCGImagePropertyGPSLatitude] = latitude
        gpsDictionary[kCGImagePropertyGPSLongitudeRef] = longitudeRef
        gpsDictionary[kCGImagePropertyGPSLongitude] = longitude
        gpsDictionary[kCGImagePropertyGPSDOP] = location.horizontalAccuracy
        gpsDictionary[kCGImagePropertyGPSAltitudeRef] = altitudeRef
        gpsDictionary[kCGImagePropertyGPSAltitude] = altitude
        
        return gpsDictionary
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

extension PhotoSettingsCapture: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        print("\(#function)")
        
        guard error == nil else {
            print("Error broken photo data: \(error!)")
            return
        }
        
        guard let photoData = photo.fileDataRepresentation() else {
            print("No photo data to write.")
            return
        }
        
        if isBracketSettingsEnabled {
            Task {
                do {
                    try await PHPhotoLibrary.shared().performChanges {
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo,
                                                    data: photoData,
                                                    options: nil)
                    }
                } catch {
                    print(error)
                }
            }
        } else {
            self.compressedData = photoData
        }
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
        
        if !isBracketSettingsEnabled {
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
}
