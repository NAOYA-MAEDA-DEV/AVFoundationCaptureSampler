import SwiftUI

struct CameraDeviceView: View {
    @StateObject private var cameraDeviceCapture = CameraDeviceCapture()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                if let previewLayer = cameraDeviceCapture.previewLayer {
                    VideoPreviewLayerView(previewCALayer: previewLayer)
                        .frame(width: geometry.size.width,
                               height: geometry.size.width * 16 / 9)
                }
                VStack {
                    Spacer()
                    Picker("Camera Devices", selection: $cameraDeviceCapture.selectedCameraDeviceIndex) {
                        ForEach(Array(cameraDeviceCapture.cameraDevices.enumerated()),
                                id: \.offset) { index, device in
                            Text(device.localizedName).tag(index)
                        }
                    }
                    .pickerStyle(.automatic)
                }
                .padding(.bottom, 30)
                .onChange(of: cameraDeviceCapture.selectedCameraDeviceIndex) {
                    cameraDeviceCapture.changeCameraDevice()
                }
                .onChange(of: cameraDeviceCapture.previewLayer) {
                    cameraDeviceCapture.setupPreview(size: CGSize( width: geometry.size.width,
                                                                   height: geometry.size.width * 16 / 9))
                }
                .onDisappear{
                    cameraDeviceCapture.onDissapear()
                }
            }
        }
    }
}

#if DEBUG

#Preview {
    CameraDeviceView()
}

#endif

