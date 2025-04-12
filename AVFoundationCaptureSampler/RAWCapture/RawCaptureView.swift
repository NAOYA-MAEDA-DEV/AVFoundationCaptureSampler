import SwiftUI

struct RawCaptureView: View {
    @StateObject private var rawCapture = RawCapture()
    
    var body: some View {
        GeometryReader { geometry in
            if let previewLayer = rawCapture.previewLayer {
                VideoPreviewLayerView(previewCALayer: previewLayer)
                    .frame(width: geometry.size.width,
                           height: geometry.size.width * 4 / 3)
            }
            VStack {
                Spacer()
                Picker("Camera Devices", selection: $rawCapture.selectedCameraDeviceIndex) {
                    ForEach(Array(rawCapture.cameraDevices.enumerated()),
                            id: \.offset) { index, device in
                        Text(device.localizedName).tag(index)
                    }
                }
                .pickerStyle(.automatic)
                Toggle(isOn: $rawCapture.isAppleProRAWEnabled) {
                    Text("Apple ProRAW Enabled")
                }
                .toggleStyle(.switch)
                .disabled(!rawCapture.isAppleProRAWSupported)
                Picker("Save RAW Data Type", selection: $rawCapture.selectedSaveRAWDataType) {
                    ForEach(SaveRawDataType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                HStack {
                    Spacer()
                    Button(action: {
                        Task {
                            await rawCapture.capturePhoto()
                        }
                    }) {
                        Circle()
                            .foregroundColor(.gray)
                            .frame(width: 80, height: 80)
                    }
                    Spacer()
                }
            }
            .padding(15)
            .onChange(of: rawCapture.selectedCameraDeviceIndex) {
                rawCapture.changeCameraDevice()
            }
            .onChange(of: rawCapture.previewLayer) {
                rawCapture.setupPreview(size: CGSize(width: geometry.size.width,
                                                     height: geometry.size.width * 4 / 3))
            }
        }
        .onDisappear {
            rawCapture.onDissapear()
        }
    }
}

#if DEBUG

#Preview {
    RawCaptureView()
}

#endif

