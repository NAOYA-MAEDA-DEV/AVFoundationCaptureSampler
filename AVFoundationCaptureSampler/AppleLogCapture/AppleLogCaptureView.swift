import SwiftUI

struct AppleLogCaptureView: View {
    @StateObject private var appleLogCapture = AppleLogCapture()
    
    var body: some View {
        GeometryReader { geometry in
            if let previewLayer = appleLogCapture.previewLayer {
                VideoPreviewLayerView(previewCALayer: previewLayer)
                    .frame(width: geometry.size.width,
                           height: geometry.size.width * 16 / 9)
            }
            VStack {
                Spacer()
                Picker("Camera Devices", selection: $appleLogCapture.selectedCameraDeviceIndex) {
                    ForEach(Array(appleLogCapture.cameraDevices.enumerated()),
                            id: \.offset) { index, device in
                        Text(device.localizedName).tag(index)
                    }
                }
                HStack(alignment: .center) {
                    Spacer()
                    Button(action: {
                        appleLogCapture.controlRecording()
                    }) {
                        Circle()
                            .foregroundColor(appleLogCapture.isRecording ? .red : .gray)
                            .frame(width: 80, height: 80)
                    }
                    Spacer()
                }
            }
            .padding(15)
            .onChange(of: appleLogCapture.selectedCameraDeviceIndex) {
                Task {
                    await appleLogCapture.changeCameraDevice()
                }
            }
            .onChange(of: appleLogCapture.previewLayer) {
                appleLogCapture.setupPreview(size: CGSize(width: geometry.size.width,
                                                          height: geometry.size.width * 16 / 9))
            }
        }
        .onDisappear {
            appleLogCapture.onDissapear()
        }
    }
}

#if DEBUG

#Preview {
    AppleLogCaptureView()
}

#endif

