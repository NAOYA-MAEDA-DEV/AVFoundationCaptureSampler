import SwiftUI

struct LivePhotosCaptureView: View {
    @StateObject private var livePhotosCapture = LivePhotosCapture()
    
    var body: some View {
        GeometryReader { geometry in
            if let previewLayer = livePhotosCapture.previewLayer {
                VideoPreviewLayerView(previewCALayer: previewLayer)
                    .frame(width: geometry.size.width,
                           height: geometry.size.width * 4 / 3)
                    .opacity(livePhotosCapture.shouldFlashScreen ? 0 : 1)
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        livePhotosCapture.captureLivePhotos()
                    }) {
                        Circle()
                            .foregroundColor(.gray)
                            .frame(width: 80, height: 80)
                    }
                    Spacer()
                }
            }
            .onChange(of: livePhotosCapture.previewLayer) {
                livePhotosCapture.setupPreview(size: CGSize(width: geometry.size.width,
                                                            height: geometry.size.width * 4 / 3))
            }
            .onDisappear {
                livePhotosCapture.onDissapear()
            }
            if livePhotosCapture.isProcessing {
                HStack {
                    Spacer()
                    VStack {
                        Text("LIVE")
                            .padding(5)
                            .background(.yellow)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
}

#if DEBUG

#Preview {
    LivePhotosCaptureView()
}

#endif

