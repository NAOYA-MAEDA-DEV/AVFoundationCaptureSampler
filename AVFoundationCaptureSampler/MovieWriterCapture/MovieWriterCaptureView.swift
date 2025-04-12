import SwiftUI

struct MovieWriterCaptureView: View {
    @StateObject private var movieWriterCapture = MovieWriterCapture()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let previewLayer = movieWriterCapture.previewLayer {
                    VideoPreviewLayerView(previewCALayer: previewLayer)
                        .frame(width: geometry.size.width,
                               height: geometry.size.width * 16 / 9)
                }
                Spacer()
            }
            VStack {
                Spacer()
                HStack(alignment: .center) {
                    Spacer()
                    Button(action: {
                        Task {
                            await movieWriterCapture.controlRecording()
                        }
                    }) {
                        Circle()
                            .foregroundColor(movieWriterCapture.isRecording
                                             ? .red
                                             : .gray)
                            .frame(width: 80, height: 80)
                    }
                    Spacer()
                }
            }
            .onChange(of: movieWriterCapture.previewLayer) {
                movieWriterCapture.setupPreview(size: CGSize(width: geometry.size.width,
                                                             height: geometry.size.width * 16 / 9))
            }
        }
        .onDisappear {
            movieWriterCapture.onDissapear()
        }
    }
}

#if DEBUG

#Preview {
    MovieWriterCaptureView()
}

#endif

