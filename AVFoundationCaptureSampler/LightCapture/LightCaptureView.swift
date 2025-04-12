import SwiftUI

struct LightCaptureView: View {
    @StateObject private var lightCapture = LightCapture()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let previewLayer = lightCapture.previewLayer {
                    VideoPreviewLayerView(previewCALayer: previewLayer)
                        .frame(width: geometry.size.width,
                               height: geometry.size.width * 4 / 3)
                }
            }
            VStack {
                Spacer()
                Picker("Camera Devices", selection: $lightCapture.selectedCameraIndex) {
                    ForEach(Array(lightCapture.cameraDevices.enumerated()),
                            id: \.offset) { index, device in
                        Text(device.localizedName).tag(index)
                    }
                }
                .pickerStyle(.automatic)
                HStack {
                    Text("Flash Light")
                    Spacer()
                    Picker("Flash Light", selection: $lightCapture.selectedFlashLightMode) {
                        ForEach(FlashMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                HStack {
                    Text("Torch Light")
                    Spacer()
                    Picker("Torch Light", selection: $lightCapture.selectedTorchLightMode) {
                        ForEach(TorchMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                HStack {
                    Text("Torch Level")
                    Slider(value: $lightCapture.torchLevel,
                           in: 0.001 ... 1.0)
                }
                HStack(alignment: .center) {
                    Spacer()
                    Button(action: {
                        Task {
                            await lightCapture.capturePhoto()
                        }
                    }) {
                        Circle()
                            .foregroundColor(.gray)
                            .frame(width: 80, height: 80)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 15)
            .onChange(of: lightCapture.selectedTorchLightMode) {
                lightCapture.changeTorchMode()
            }
            .onChange(of: lightCapture.torchLevel) {
                lightCapture.changeTorchLevel()
            }
            .onChange(of: lightCapture.previewLayer) {
                lightCapture.setupPreview(size: CGSize(width: geometry.size.width,
                                                       height: geometry.size.width * 4 / 3))
            }
            .onDisappear {
                lightCapture.onDissapear()
            }
            if lightCapture.isFlash {
                HStack {
                    Spacer()
                    VStack {
                        Text("Flash")
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
    LightCaptureView()
}

#endif

