import SwiftUI

struct MovieCaptureView: View {
    @StateObject private var movieCapture = MovieCapture()
    
    var body: some View {
        GeometryReader { geometry in
            if let previewLayer = movieCapture.previewLayer {
                VideoPreviewLayerView(previewCALayer: previewLayer)
                    .frame(width: geometry.size.width,
                           height: geometry.size.width * 16 / 9)
            }
            VStack {
                Spacer()
                if movieCapture.recordingState == .notRecording {
                    Picker("Capture Preset", selection: $movieCapture.selectedPreset) {
                        ForEach(movieCapture.presets,
                                id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.automatic)
                }
                VStack {
                    if #available(iOS 18, *) {
                        if movieCapture.recordingState != .notRecording {
                            Button(movieCapture.recordingState == .recording
                                   ? "Pause"
                                   : "Resume",
                                   action: {
                                if movieCapture.recordingState == .recording {
                                    movieCapture.pauseRecording()
                                } else if movieCapture.recordingState == .pause {
                                    movieCapture.resumeRecording()
                                }
                            })
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    HStack {
                        Spacer()
                        Button(action: {
                            movieCapture.controlRecording()
                        }) {
                            Circle()
                                .foregroundColor(movieCapture.recordingState == .recording
                                                 ? .red
                                                 : movieCapture.recordingState == .pause
                                                 ? .yellow
                                                 : .gray)
                                .frame(width: 80, height: 80)
                        }
                        Spacer()
                    }
                }
            }
            .onChange(of: movieCapture.selectedPreset) {
                movieCapture.changeCapturePreset()
            }
            .onChange(of: movieCapture.previewLayer) {
                movieCapture.setupPreview(size: CGSize(width: geometry.size.width,
                                                       height: geometry.size.width * 16 / 9))
            }
            .onDisappear {
                movieCapture.onDissapear()
            }
        }
    }
}

#if DEBUG

#Preview {
    MovieCaptureView()
}

#endif

