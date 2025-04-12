import SwiftUI

struct ManualFocusView: View {
    @StateObject private var manualFocus = ManualFocus()
    
    @State private var isShowParamater: Bool = true
    @State private var tapLocation: CGPoint? = nil
    
    var body: some View {
        GeometryReader { geometry in
            if let previewLayer = manualFocus.previewLayer {
                VideoPreviewLayerView(previewCALayer: previewLayer)
                    .frame(width: geometry.size.width,
                           height: geometry.size.width * 16 / 9)
                    .onTapGesture(coordinateSpace: .local) { location in
                        tapLocation = location
                        let focusPoint = manualFocus.previewLayer.captureDevicePointConverted(fromLayerPoint: location)
                        manualFocus.focusAt(point: focusPoint)
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
                        Text("Focus Mode")
                        Spacer()
                        Text(manualFocus.focusModeStr)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Focus Range")
                        Spacer()
                        Text(manualFocus.focusRangeStr)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Smooth Auto Focus")
                        Spacer()
                        Text(manualFocus.smoothAutoFocus.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Face Driven Auto Focus")
                        Spacer()
                        Text(manualFocus.faceDrivenAutoFocus.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Automatically Adjusts\nFace Driven Auto Focus")
                        Spacer()
                        Text(manualFocus.automaticallyAdjustsFaceDrivenAutoFocus.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Lens Position")
                        Spacer()
                        Text(String(format: "%.2f", manualFocus.lensPosition))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Minimum Focus Distance")
                        Spacer()
                        Text(String(format: "%d", manualFocus.minimumFocusDistance))
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Adjusting Focus")
                        Spacer()
                        Text(manualFocus.isAdjustingFocus.description)
                            .frame(width: 90)
                    }
                }
                .foregroundColor(.yellow)
                .background(Color.black.opacity(0.5))
                .frame(height: 200)
                .opacity(isShowParamater ? 1 : 0)
                Spacer()
                ScrollView {
                    Picker("Camera Devices", selection: $manualFocus.selectedCameraIndex) {
                        ForEach(Array(manualFocus.cameraDevices.enumerated()),
                                id: \.offset) { index, device in
                            Text(device.localizedName).tag(index)
                        }
                    }
                    .pickerStyle(.automatic)
                    HStack {
                        Button("Locked", action: {
                            manualFocus.selectedFocusMode = .locked
                        })
                        Button("Auto", action: {
                            manualFocus.selectedFocusMode = .auto
                        })
                        Button("Continious", action: {
                            manualFocus.selectedFocusMode = .continuous
                        })
                    }
                    .buttonStyle(.borderedProminent)
                    Picker("Focus Range", selection: $manualFocus.selectedFocusRange) {
                        ForEach(FocusRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    Toggle(isOn: $manualFocus.isSmoothAutoFocus) {
                        Text("isSmoothAutoFocusEnabled")
                    }
                    .toggleStyle(.switch)
                    Toggle(isOn: $manualFocus.isFaceDrivenAutoFocus) {
                        Text("isFaceDrivenAutoFocusEnabled")
                    }
                    .disabled(manualFocus.isAutomaticallyAdjustsFaceDrivenAutoFocus)
                    .toggleStyle(.switch)
                    Toggle(isOn: $manualFocus.isAutomaticallyAdjustsFaceDrivenAutoFocus) {
                        Text("automaticallyAdjustsFaceDrivenAutoFocusEnabled")
                    }
                    .toggleStyle(.switch)
                    HStack {
                        Text("Lens Position")
                        Slider(value: $manualFocus.lensPositionValue, in: 0 ... 1.0)
                            .padding(.horizontal)
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
            .onChange(of: manualFocus.selectedCameraIndex) {
                manualFocus.changeCameraDevice()
            }
            .onChange(of: manualFocus.selectedFocusMode) {
                manualFocus.changeFocusMode()
            }
            .onChange(of: manualFocus.selectedFocusRange) {
                manualFocus.changeFocusRange()
            }
            .onChange(of: manualFocus.isSmoothAutoFocus) {
                manualFocus.toggleSmoothAutoFocus()
            }
            .onChange(of: manualFocus.isFaceDrivenAutoFocus) {
                manualFocus.toggleFaceDrivenAutoFocus()
            }
            .onChange(of: manualFocus.isAutomaticallyAdjustsFaceDrivenAutoFocus) {
                manualFocus.toggleAutomaticallyAdjustsFaceDrivenAutoFocus()
            }
            .onChange(of: manualFocus.lensPositionValue) {
                Task {
                    await manualFocus.changeLensPosition()
                }
            }
            .onChange(of: manualFocus.previewLayer) {
                manualFocus.setPreview(size: CGSize(width: geometry.size.width,
                                                    height: geometry.size.width * 16 / 9))
            }
            .onDisappear {
                manualFocus.onDissapear()
            }
        }
    }
}

#if DEBUG

#Preview {
    ManualFocusView()
}

#endif

