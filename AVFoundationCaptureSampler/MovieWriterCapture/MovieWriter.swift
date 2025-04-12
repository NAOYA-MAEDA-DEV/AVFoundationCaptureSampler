import AVFoundation

final class MovieWriter {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    
    private var videoSettings: [String: Any]
    private var audioSettings: [String: Any]
    private var videoTransform: CGAffineTransform
    
    var isRecording = false
    
    private var offsetTime = CMTime.zero
    
    init(audioSettings: [String: Any],
         videoSettings: [String: Any],
         videoTransform: CGAffineTransform) {
        self.audioSettings = audioSettings
        self.videoSettings = videoSettings
        self.videoTransform = videoTransform
    }
    
    func startRecording() {
        let outputFileURL = makeUniqueTempFileURL(extension: "mov")
        
        guard let assetWriter = try? AVAssetWriter(
            url: outputFileURL,
            fileType: .mov) else {
            return
        }
        
        let assetWriterVideoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriterVideoInput.transform = videoTransform
        assetWriter.add(assetWriterVideoInput)
        
        let assetWriterAudioInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: audioSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterAudioInput)
        
        self.assetWriter = assetWriter
        self.videoInput = assetWriterVideoInput
        self.audioInput = assetWriterAudioInput
        
        isRecording = true
    }
    
    func recordVideo(sampleBuffer: CMSampleBuffer, isVideo: Bool) {
        guard isRecording,
              let assetWriter else {
            return
        }
        
        if isVideo && assetWriter.status == .unknown {
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            if isVideo {
                recordVideo(sampleBuffer: sampleBuffer)
            } else {
                recordAudio(sampleBuffer: sampleBuffer)
            }
        } else if assetWriter.status == .writing {
            if isVideo {
                recordVideo(sampleBuffer: sampleBuffer)
            } else {
                recordAudio(sampleBuffer: sampleBuffer)
            }
        }
    }
    
    private func recordVideo(sampleBuffer: CMSampleBuffer) {
        guard let videoInput,
              videoInput.isReadyForMoreMediaData else {
            return
        }
        
        videoInput.append(sampleBuffer)
    }
    
    private func recordAudio(sampleBuffer: CMSampleBuffer) {
        guard let audioInput,
              audioInput.isReadyForMoreMediaData else {
            return
        }
        
        audioInput.append(sampleBuffer)
    }
    
    func stopRecording() async -> URL? {
        guard let assetWriter else {
            return nil
        }
        
        self.isRecording = false
        
        self.assetWriter = nil
        
        await assetWriter.finishWriting()
        
        return assetWriter.outputURL
    }
}
