import SwiftUI

struct ZoomView: View {
    @StateObject private var zoom = Zoom()
    
    @State private var isShowParamater: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            if let previewLayer = zoom.previewLayer {
                VideoPreviewLayerView(previewCALayer: previewLayer)
                    .frame(width: geometry.size.width,
                           height: geometry.size.width * 16 / 9)
            }
            VStack {
                ScrollView {
                    HStack {
                        Text("Zoom Fcator Value")
                        Spacer()
                        Text((round(zoom.zoomFactor * 100) / 100).description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Zoom Factor Multiplier")
                        Spacer()
                        Text((round(zoom.zoomFactorMultiplier * 100) / 100).description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Min Zoom Factor Value")
                        Spacer()
                        Text((round(zoom.minZoomFactor * 100) / 100).description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Max Zoom Factor Value")
                        Spacer()
                        Text(zoom.maxZoomFactor.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Zooming")
                        Spacer()
                        Text(zoom.isZooming.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("virtualDeviceSwitchOverVideoZoomFactors")
                        Spacer()
                        Text(zoom.switchZoomFactors.map{ String(describing: $0) }.joined(separator: ", "))
                            .frame(width: 90)
                    }
                }
                .foregroundColor(.yellow)
                .background(Color.black.opacity(0.5))
                .frame(height: 200)
                .opacity(isShowParamater ? 1 : 0)
                Spacer()
                VStack {
                    Picker("Zoom Factor", selection: $zoom.rampZoomFactorValue) {
                        Text("x\(String(format: "%.1f", 1 * zoom.zoomFactorMultiplier))").tag(1)
                        Text("x\(String(format: "%.1f", 2 * zoom.zoomFactorMultiplier))").tag(2)
                        Text("x\(String(format: "%.1f", 4 * zoom.zoomFactorMultiplier))").tag(4)
                        Text("x\(String(format: "%.1f", 6 * zoom.zoomFactorMultiplier))").tag(6)
                        Text("x\(String(format: "%.1f", 10 * zoom.zoomFactorMultiplier))").tag(10)
                        Text("Cancel").tag(0)
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text("Zoom")
                        Slider(value: $zoom.zoomFactorValue,
                               in: zoom.minZoomFactor ... zoom.maxZoomFactor)
                    }
                    HStack {
                        Text("Ramp")
                        Slider(value: $zoom.rampValue,
                               in: 0.1 ... 10)
                    }
                    Picker("Camera Devices", selection: $zoom.selectedCameraIndex) {
                        ForEach(Array(zoom.cameraDevices.enumerated()),
                                id: \.offset) { index, device in
                            Text(device.localizedName).tag(index)
                        }
                    }
                    .pickerStyle(.automatic)
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
            .onChange(of: zoom.selectedCameraIndex) {
                zoom.changeCameraDevice()
            }
            .onChange(of: zoom.rampZoomFactorValue) {
                if zoom.rampZoomFactorValue != 0 {
                    zoom.rampZoom()
                } else {
                    zoom.cancelRampZoom()
                }
            }
            .onChange(of: zoom.zoomFactorValue) {
                if !zoom.isZooming {
                    zoom.changeZoom(value: zoom.zoomFactorValue)
                }
            }
            .onChange(of: zoom.previewLayer) {
                zoom.setPreview(size: CGSize(
                    width: geometry.size.width,
                    height: geometry.size.width * 16 / 9))
            }
            .onDisappear {
                zoom.onDissapear()
            }
        }
    }
}

#if DEBUG

#Preview {
    ZoomView()
}

#endif

