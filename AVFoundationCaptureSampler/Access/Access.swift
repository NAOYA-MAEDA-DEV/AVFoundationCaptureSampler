import UIKit
import Photos

final class Access: NSObject, ObservableObject {
    public override init() {
        super.init()
    }
    
    func requestCameraAuthorization() async -> Bool {
        await isAuthorizedCamera
    }
    
    func requestMicAuthorization() async -> Bool {
        await isAuthorizedMic
    }
    
    func requestAddOnlyPhotosAuthorization() async -> Bool {
        await isAuthorizedAddOnlyPhotos
    }
    
    func requestReadWritePhotosAuthorization() async -> Bool {
        await isAuthorizedReadWritePhotos
    }
    
    func requestWhenInUseAuthorization() {
        requestWhenInUseAuthorizedLocationAcccess()
    }
    
    func openSettingsScreen() {
        UIApplication.shared.open(URL(
            string: UIApplication.openSettingsURLString)!,
                                  options: [:],
                                  completionHandler: nil)
    }
}
