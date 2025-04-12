import AVFoundation

func makeUniqueTempFileURL(extension type: String) -> URL {
    let temporaryDirectoryURL = FileManager.default.temporaryDirectory
    let uniqueFilename = ProcessInfo.processInfo.globallyUniqueString
    let urlNoExt = temporaryDirectoryURL.appendingPathComponent(uniqueFilename)
    let url = urlNoExt.appendingPathExtension(type)
    return url
}

func getResolution(from sampleBuffer: CMSampleBuffer) -> CGSize? {
    guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
        return nil
    }
    
    let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
    return CGSize(width: Int(dimensions.width), height: Int(dimensions.height))
}
