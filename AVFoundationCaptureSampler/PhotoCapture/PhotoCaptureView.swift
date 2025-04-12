import SwiftUI

struct PhotoCaptureView: View {
    @StateObject private var photoCapture = PhotoCapture()
    
    var body: some View {
        GeometryReader { geometry in
            if let previewLayer = photoCapture.previewLayer {
                VideoPreviewLayerView(previewCALayer: previewLayer)
                    .frame(width: geometry.size.width,
                           height: geometry.size.width * 4 / 3)
                    .opacity(photoCapture.shouldFlashScreen ? 0 : 1)
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        Task {
                            await photoCapture.capturePhoto()
                        }
                    }) {
                        Circle()
                            .foregroundColor(.gray)
                            .frame(width: 80, height: 80)
                    }
                    Spacer()
                }
            }
            .onChange(of: photoCapture.previewLayer) {
                photoCapture.setupPreview(size: CGSize(width: geometry.size.width,
                                                       height: geometry.size.width * 4 / 3))
            }
            .onDisappear {
                photoCapture.onDissapear()
            }
        }
    }
}

#if DEBUG

#Preview {
    PhotoCaptureView()
}

#endif

