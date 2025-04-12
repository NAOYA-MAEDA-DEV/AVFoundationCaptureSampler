import AVFoundation

func getAvailableCameraDevices() -> [AVCaptureDevice] {
    let cameraDeviceTypes: [AVCaptureDevice.DeviceType] = [
        .builtInWideAngleCamera,
        .builtInUltraWideCamera,
        .builtInTelephotoCamera,
        .builtInDualCamera,
        .builtInDualWideCamera,
        .builtInTripleCamera
    ]
    
    return AVCaptureDevice.DiscoverySession(
        deviceTypes: cameraDeviceTypes,
        mediaType: .video,
        position: .unspecified).devices
}
