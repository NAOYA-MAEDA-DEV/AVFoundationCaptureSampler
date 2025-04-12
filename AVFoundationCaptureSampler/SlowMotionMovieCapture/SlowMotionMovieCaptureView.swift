import SwiftUI

struct SlowMotionMovieCaptureView: View {
    @StateObject private var slowMotionMovieCapture = SlowMotionMovieCapture()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let previewLayer = slowMotionMovieCapture.previewLayer {
                    VideoPreviewLayerView(previewCALayer: previewLayer)
                        .frame(width: geometry.size.width,
                               height: geometry.size.width * 16 / 9)
                }
                VStack {
                    Spacer()
                    Picker("FPS", selection: $slowMotionMovieCapture.selectedFps) {
                        ForEach(Fps.allCases) { fps in
                            Text(fps.rawValue).tag(fps)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .onChange(of: slowMotionMovieCapture.selectedFps) {
                        slowMotionMovieCapture.setupFps()
                    }
                    HStack(alignment: .center) {
                        Spacer()
                        Button(action: {
                            slowMotionMovieCapture.controlRecording()
                        }) {
                            Circle()
                                .foregroundColor(slowMotionMovieCapture.isRecording ? .red : .gray)
                                .frame(width: 80, height: 80)
                        }
                        Spacer()
                    }
                }
                .padding(.bottom, 30)
            }
            .onChange(of: slowMotionMovieCapture.previewLayer) {
                slowMotionMovieCapture.setupPreview(size: CGSize(
                    width: geometry.size.width,
                    height: geometry.size.width * 16 / 9)
                )
            }
        }
        .onDisappear {
            slowMotionMovieCapture.onDissapear()
        }
    }
}

#if DEBUG

#Preview {
    SlowMotionMovieCaptureView()
}

#endif

