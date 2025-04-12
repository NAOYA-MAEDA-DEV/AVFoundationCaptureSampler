import AVFoundation
import Photos

var isAuthorizedCamera: Bool {
    get async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        var isAuthorized = status == .authorized
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        
        return isAuthorized
    }
}

var isAuthorizedMic: Bool {
    get async {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        var isAuthorized = status == .authorized
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .audio)
        }
        
        return isAuthorized
    }
}

var isAuthorizedAddOnlyPhotos: Bool {
    get async {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        var isAuthorized = status == .authorized
        if status == .notDetermined {
            isAuthorized = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
        }
        
        return isAuthorized
    }
}

var isAuthorizedReadWritePhotos: Bool {
    get async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        var isAuthorized = status == .authorized
        if status == .notDetermined {
            isAuthorized = await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
        }
        
        return isAuthorized
    }
}

func requestWhenInUseAuthorizedLocationAcccess() {
    let status = CLLocationManager().authorizationStatus
    if status == .notDetermined {
        CLLocationManager().requestWhenInUseAuthorization()
    }
}
