import SwiftUI

struct ThumbnailCaptureView: View {
    @StateObject private var thumbnailCapture = ThumbnailCapture()
    
    var body: some View {
        GeometryReader { geometry in
            if let previewLayer = thumbnailCapture.previewLayer {
                VideoPreviewLayerView(previewCALayer: previewLayer)
                    .frame(width: geometry.size.width,
                           height: geometry.size.width * 4 / 3)
            }
            VStack {
                Spacer()
                ZStack(alignment: .leading) {
                    HStack {
                        Spacer()
                        Button(action: {
                            Task {
                                await thumbnailCapture.capturePhoto()
                            }
                        }) {
                            Circle()
                                .foregroundColor(.gray)
                                .frame(width: 80, height: 80)
                        }
                        Spacer()
                    }
                    if let img = thumbnailCapture.previewImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                    }
                }
            }
            .onChange(of: thumbnailCapture.previewLayer) {
                thumbnailCapture.setupPreview(size: CGSize(width: geometry.size.width,
                                                           height: geometry.size.width * 4 / 3))
            }
            .onDisappear {
                thumbnailCapture.onDissapear()
            }
        }
    }
}

#if DEBUG

#Preview {
    ThumbnailCaptureView()
}

#endif

