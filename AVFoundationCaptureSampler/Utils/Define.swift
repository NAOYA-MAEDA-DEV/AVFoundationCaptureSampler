import AVFoundation

enum RecordingState: String, CaseIterable, Identifiable {
    case notRecording
    case recording
    case pause
    
    var id: String { rawValue }
}

enum FocusMode: String, CaseIterable, Identifiable {
    case locked = "Locked"
    case auto = "Auto"
    case continuous = "Continuous"

    var id: String { rawValue }
}

enum FocusRange: String, CaseIterable, Identifiable {
    case none = "None"
    case near = "Near"
    case far = "Far"

    var id: String { rawValue }
}

enum ExposureMode: String, CaseIterable, Identifiable {
    case locked = "Locked"
    case auto = "Auto"
    case continuous = "Continuous"
    case custom = "Custom"

    var id: String { rawValue }
}

enum WhiteBalamceMode: String, CaseIterable, Identifiable {
    case locked = "Locked"
    case auto = "Auto"
    case continuous = "Continuous"

    var id: String { rawValue }
}

enum FlashMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case on = "On"
    case auto = "Auto"
    
    var id: String { rawValue }
}

enum TorchMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case on = "On"
    case auto = "Auto"
    
    var id: String { rawValue }
}

enum SaveImageFormatType: String, CaseIterable, Identifiable {
    case jpeg = "JPEG"
    case heic = "HEIC"
    
    var id: String { rawValue }
}

enum PhotoQualityPrioritization: String, CaseIterable, Identifiable {
    case speed = "Speed"
    case quality = "Quality"
    case balanced = "Balanced"

    var id: String { rawValue }
}

enum VideoStabilizationMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case standard = "Standard"
    case cinematic = "Cinematic"
    case cinematicExtended = "CinematicExtended"
    case previewOptimized = "PreviewOptimized"
    case cinematicExtendedEnhanced = "CinematicExtendedEnhanced"
    case auto = "Auto"
    
    var id: String { rawValue }
}

enum VideoAngle: String, CaseIterable, Identifiable {
    case angle_0 = "0°"
    case angle_90 = "90°"
    case angle_180 = "180°"
    case angle_270 = "270°"
    
    var id: String { rawValue }
}

enum MetadataType: String, CaseIterable, Identifiable {
    case qrcode = "QRCode"
    case humanBody = "Human body"
    case humanFullBody = "Human full body"
    case dogBody = "Dog body"
    case catBody = "Cat body"
    case face = "Face"
    
    var id: String { rawValue }
}

enum Fps: String, CaseIterable, Identifiable {
    case fps30 = "30 FPS"
    case fps60 = "60 FPS"
    case fps120 = "120 FPS"
    case fps240 = "240 FPS"

    var id: String { rawValue }
}

enum RawDataType: String, CaseIterable, Identifiable {
    case raw = "RAW"
    case proRaw = "Apple ProRAW"
    
    var id: String { rawValue }
}

enum SaveRawDataType: String, CaseIterable, Identifiable {
    case raw = "RAW"
    case rawWithL = "RAW + JPEG"
    
    var id: String { rawValue }
}

enum ImageOrientationType: String, CaseIterable, Identifiable {
    case up = "up"
    case down = "down"
    case left = "left"
    case right = "right"
    case upMirrored = "upMirrored"
    case downMirrored = "downMirrored"
    case leftMirrored = "leftMirrored"
    case rightMirrored = "rightMirrored"

    var id: String { rawValue }
}
