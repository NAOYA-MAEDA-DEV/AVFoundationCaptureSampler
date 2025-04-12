import SwiftUI

struct MetadataCaptureView: View {
    @StateObject private var metadataCapture = MetadataCapture()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                if let previewLayer = metadataCapture.previewLayer {
                    VideoPreviewLayerView(previewCALayer: previewLayer)
                        .frame(width: geometry.size.width,
                               height: geometry.size.width * 16 / 9)
                }
                VStack {
                    HStack {
                        Text("Detect Metadata")
                        Spacer()
                        Text(metadataCapture.metadataDescription)
                            .frame(width: 90)
                    }
                    Spacer()
                    Picker("Metadata Type", selection: $metadataCapture.selectedMetadataType) {
                        ForEach(MetadataType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.automatic)
                }
            }
            .padding(.bottom, 30)
            .onChange(of: metadataCapture.selectedMetadataType) {
                metadataCapture.changeDetectingMetadataType()
            }
            .onChange(of: metadataCapture.previewLayer) {
                metadataCapture.setupPreview(size: CGSize(width: geometry.size.width,
                                                     height: geometry.size.width * 16 / 9))
            }
            .onDisappear {
                metadataCapture.onDissapear()
            }
        }
    }
}

#if DEBUG

#Preview {
    MetadataCaptureView()
}

#endif
