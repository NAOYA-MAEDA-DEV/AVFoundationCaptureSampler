import SwiftUI

struct ManualExposureView: View {
    @StateObject private var manualExposure = ManualExposure()
    
    @State private var isShowParamater: Bool = true
    @State private var tapLocation: CGPoint? = nil
    
    var body: some View {
        GeometryReader { geometry in
            if let previewLayer = manualExposure.previewLayer {
                VideoPreviewLayerView(previewCALayer: previewLayer)
                    .frame(width: geometry.size.width,
                           height: geometry.size.width * 16 / 9)
                    .onTapGesture(coordinateSpace: .local) { location in
                        tapLocation = location
                        let exposurePoint = manualExposure.previewLayer.captureDevicePointConverted(fromLayerPoint: location)
                        manualExposure.exposureAt(point: exposurePoint)
                    }
                if let tapLocation = tapLocation {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 1)
                        .frame(width: 50, height: 50)
                        .position(tapLocation)
                        .animation(.easeInOut, value: tapLocation)
                }
            }
            VStack {
                ScrollView {
                    HStack {
                        Text("Exposure Mode")
                        Spacer()
                        Text(manualExposure.exposureModeStr)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Face Driven Auto Exposure")
                        Spacer()
                        Text(manualExposure.isFaceDrivenAutoExposure.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Automatically Adjusts\nFace Driven Auto Exposure")
                        Spacer()
                        Text(manualExposure.isAutomaticallyAdjustsFaceDrivenAutoExposure.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Exposure Target Offset")
                        Spacer()
                        Text(String(format: "%.2f", manualExposure.exposureTargetOffset))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Exposure Target Bias")
                        Spacer()
                        Text(String(format: "%.2f", manualExposure.exposureTargetBias))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Min Exposure Target Bias")
                        Spacer()
                        Text(String(format: "%.2f", manualExposure.minExposureTargetBias))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Max Exposure Target Bias")
                        Spacer()
                        Text(String(format: "%.2f", manualExposure.maxExposureTargetBias))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Exposure Duration")
                        Spacer()
                        Text(String(format: "%.2f", manualExposure.exposureDuration))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Min Exposure Duration")
                        Spacer()
                        Text(String(format: "%.2f", manualExposure.minExposureDuration))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Max Exposure Duration")
                        Spacer()
                        Text(String(format: "%.2f", manualExposure.maxExposureDuration))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("ISO")
                        Spacer()
                        Text(String(format: "%.2f", manualExposure.iso))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Min ISO")
                        Spacer()
                        Text(String(format: "%.2f", manualExposure.minISO))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Max ISO")
                        Spacer()
                        Text(String(format: "%.2f", manualExposure.maxISO))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Lens Aperture")
                        Spacer()
                        Text(String(format: "%.2f", manualExposure.lensAperture))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Adjusting Exposure")
                        Spacer()
                        Text(manualExposure.isAdjustingExposure.description)
                            .frame(width: 90)
                    }
                }
                .foregroundColor(.yellow)
                .background(Color.black.opacity(0.5))
                .frame(height: 200)
                .opacity(isShowParamater ? 1 : 0)
                Spacer()
                ScrollView {
                    Picker("Camera Devices", selection: $manualExposure.selectedCameraIndex) {
                        ForEach(Array(manualExposure.cameraDevices.enumerated()),
                                id: \.offset) { index, device in
                            Text(device.localizedName).tag(index)
                        }
                    }
                    .pickerStyle(.automatic)
                    HStack {
                        Button("Locked", action: {
                            manualExposure.selectedExposureMode = .locked
                        })
                        Button("Auto", action: {
                            manualExposure.selectedExposureMode = .auto
                        })
                        Button("Continious", action: {
                            manualExposure.selectedExposureMode = .continuous
                        })
                        Button("Custom", action: {
                            manualExposure.selectedExposureMode = .custom
                        })
                    }
                    .buttonStyle(.borderedProminent)
                    Toggle(isOn: $manualExposure.isFaceDrivenAutoExposure) {
                        Text("FaceDrivenAutoExposureIs")
                    }
                    .toggleStyle(.switch)
                    .disabled(manualExposure.isAutomaticallyAdjustsFaceDrivenAutoExposure)
                    Toggle(isOn: $manualExposure.isAutomaticallyAdjustsFaceDrivenAutoExposure) {
                        Text("AutomaticallyAdjustsFaceDrivenAutoExposureIs")
                    }
                    .toggleStyle(.switch)
                    HStack {
                        Text("Exposure Target Bias")
                        Slider(value: $manualExposure.exposureTargetBiasValue,
                               in: manualExposure.minExposureTargetBias ... manualExposure.maxExposureTargetBias)
                    }
                    HStack {
                        Text("ISO")
                        Slider(value: $manualExposure.isoValue,
                               in: manualExposure.minISO ... manualExposure.maxISO)
                    }
                    HStack {
                        Text("Exposure Duration")
                        Slider(value: $manualExposure.exposureDurationValue,
                               in: manualExposure.minExposureDuration ... manualExposure.maxExposureDuration)
                    }
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
            .onChange(of: manualExposure.selectedCameraIndex) {
                manualExposure.changeCameraDevice()
            }
            .onChange(of: manualExposure.selectedExposureMode) {
                manualExposure.changeExposureMode()
            }
            .onChange(of: manualExposure.isFaceDrivenAutoExposure) {
                manualExposure.toggleFaceDrivenAutoExpose()
            }
            .onChange(of: manualExposure.isAutomaticallyAdjustsFaceDrivenAutoExposure) {
                manualExposure.toggleAutomaticallyAdjustsFaceDrivenAutoExposure()
            }
            .onChange(of: manualExposure.exposureTargetBiasValue) {
                Task {
                    await manualExposure.changeExposureTargetBias()
                }
            }
            .onChange(of: manualExposure.isoValue) {
                Task {
                    await manualExposure.changeISO()
                }
            }
            .onChange(of: manualExposure.exposureDurationValue) {
                Task {
                    await manualExposure.changeExposureDuration()
                }
            }
            .onChange(of: manualExposure.previewLayer) {
                manualExposure.setPreview(size: CGSize(width: geometry.size.width,
                                                       height: geometry.size.width * 16 / 9))
            }
            .onDisappear {
                Task {
                    await manualExposure.onDissapear()
                }
            }
        }
    }
}

#if DEBUG

#Preview {
    ManualExposureView()
}

#endif

