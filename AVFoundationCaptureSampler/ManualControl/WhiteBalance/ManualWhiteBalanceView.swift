import SwiftUI

struct ManualWhiteBalanceView: View {
    @StateObject private var manualWhiteBalance = ManualWhiteBalance()
    
    @State private var isShowParamater: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            if let previewLayer = manualWhiteBalance.previewLayer {
                ZStack {
                    VideoPreviewLayerView(previewCALayer: previewLayer)
                        .frame(width: geometry.size.width,
                               height: geometry.size.width * 16 / 9)
                }
            }
            VStack {
                ScrollView {
                    HStack {
                        Text("WhiteBalance Mode")
                        Spacer()
                        Text(manualWhiteBalance.whiteBalanceModeStr)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Red Gain")
                        Spacer()
                        Text(String(format: "%.2f", manualWhiteBalance.redGain))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Green Gain")
                        Spacer()
                        Text(String(format: "%.2f", manualWhiteBalance.greenGain))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Blue Gain")
                        Spacer()
                        Text(String(format: "%.2f", manualWhiteBalance.blueGain))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Max WhiteBalance Gain")
                        Spacer()
                        Text(String(format: "%.2f", manualWhiteBalance.maxWhiteBalanceGain))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(String(format: "%.2f", manualWhiteBalance.temperature))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Tint")
                        Spacer()
                        Text(String(format: "%.2f", manualWhiteBalance.tint))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Gray World Red Gain")
                        Spacer()
                        Text(String(format: "%.2f", manualWhiteBalance.grayWorldRedGain))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Gray World Green Gain")
                        Spacer()
                        Text(String(format: "%.2f", manualWhiteBalance.grayWorldGreenGain))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Gray World Blue Gain")
                        Spacer()
                        Text(String(format: "%.2f", manualWhiteBalance.grayWorldBlueGain))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("ChromaticityValue X")
                        Spacer()
                        Text(String(format: "%.2f", manualWhiteBalance.whiteBalanceChromaticityValueX))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("ChromaticityValue Y")
                        Spacer()
                        Text(String(format: "%.2f", manualWhiteBalance.whiteBalanceChromaticityValueY))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("IsAdjustingWhiteBalance")
                        Spacer()
                        Text(manualWhiteBalance.isAdjustingWhiteBalance.description)
                            .frame(width: 90)
                    }
                }
                .foregroundColor(.yellow)
                .background(Color.black.opacity(0.5))
                .frame(height: 200)
                .opacity(isShowParamater ? 1 : 0)
                Spacer()
                ScrollView {
                    Picker("Camera Devices", selection: $manualWhiteBalance.selectedCameraIndex) {
                        ForEach(Array(manualWhiteBalance.cameraDevices.enumerated()),
                                id: \.offset) { index, device in
                            Text(device.localizedName).tag(index)
                        }
                    }
                    .pickerStyle(.automatic)
                    Picker("WhiteBalance Mode", selection: $manualWhiteBalance.selectedWhiteBalanceMode) {
                        ForEach(WhiteBalamceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text("Red Gain")
                        Slider(value: $manualWhiteBalance.redGainValue,
                               in: 1.0 ... manualWhiteBalance.maxWhiteBalanceGain)
                    }
                    HStack {
                        Text("Green Gain")
                        Slider(value: $manualWhiteBalance.greenGainValue,
                               in: 1.0 ... manualWhiteBalance.maxWhiteBalanceGain)
                    }
                    HStack {
                        Text("Blue Gain")
                        Slider(value: $manualWhiteBalance.blueGainValue,
                               in: 1.0 ... manualWhiteBalance.maxWhiteBalanceGain)
                    }
                    Button(action: {
                        manualWhiteBalance.setGrayWorldGains()
                    }) {
                        Text("Set GrayWorld Gains")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(height: 200)
                .padding(.horizontal, 15)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowParamater.toggle()
                    }) {
                        Image(systemName: "list.bullet.rectangle")
                    }
                }
            }
            .onChange(of: manualWhiteBalance.selectedCameraIndex) {
                manualWhiteBalance.changeCameraDevice()
            }
            .onChange(of: manualWhiteBalance.selectedWhiteBalanceMode) {
                manualWhiteBalance.changeWhiteBalanceMode()
            }
            .onChange(of: manualWhiteBalance.redGainValue) {
                Task {
                    await manualWhiteBalance.changeWhiteBalance()
                }
            }
            .onChange(of: manualWhiteBalance.greenGainValue) {
                Task {
                    await manualWhiteBalance.changeWhiteBalance()
                }
            }
            .onChange(of: manualWhiteBalance.blueGainValue) {
                Task {
                    await manualWhiteBalance.changeWhiteBalance()
                }
            }
            .onChange(of: manualWhiteBalance.previewLayer) {
                manualWhiteBalance.setPreview(size: CGSize(width: geometry.size.width,
                                                           height: geometry.size.width * 16 / 9))
            }
            .onDisappear {
                manualWhiteBalance.onDissapear()
            }
        }
    }
}

#if DEBUG

#Preview {
    ManualWhiteBalanceView()
}

#endif

