import SwiftUI

struct MultiCamCaptureView: View {
    @StateObject var multiCamCapture = MultiCamCapture()
    let columns = [
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    HStack {
                        VideoPreviewLayerView(previewCALayer: multiCamCapture.ultraWideAngleCameraPreviewLayer)
                            .frame(width: geometry.size.width / 2, height: geometry.size.width * 8 / 9)
                            .onTapGesture {
                                multiCamCapture.toggleUltraWideAngleCameraSetting()
                            }
                        VideoPreviewLayerView(previewCALayer: multiCamCapture.backWideAngleCameraPreviewLayer)
                            .frame(width: geometry.size.width / 2, height: geometry.size.width * 8 / 9)
                            .onTapGesture {
                                multiCamCapture.toggleBackWideAngleCameraSetting()
                            }
                    }
                    HStack {
                        VideoPreviewLayerView(previewCALayer: multiCamCapture.telephotoCameraPreviewLayer)
                            .frame(width: geometry.size.width / 2, height: geometry.size.width * 8 / 9)
                            .onTapGesture {
                                multiCamCapture.toggleTelephotoCameraSetting()
                            }
                        VideoPreviewLayerView(previewCALayer: multiCamCapture.frontWideAngleCameraPreviewLayer)
                            .frame(width: geometry.size.width / 2, height: geometry.size.width * 8 / 9)
                            .onTapGesture {
                                multiCamCapture.toggleFrontWideAngleCameraSetting()
                            }
                    }
                }
                VStack {
                    Group {
                        HStack {
                            Text("Hardware Cost")
                            Spacer()
                            Text(String(format: "%.2f", multiCamCapture.hardwareCost))
                                .frame(width: 90)
                        }
                        HStack {
                            Text("System Pressure Cost")
                            Spacer()
                            Text(String(format: "%.2f", multiCamCapture.systemPressureCost))
                                .frame(width: 90)
                        }
                    }
                    .foregroundColor(.yellow)
                    Spacer()
                    HStack(alignment: .center) {
                        Spacer()
                        Button(action: {
                            multiCamCapture.controlRecording()
                        }) {
                            Circle()
                                .foregroundColor(multiCamCapture.isRecording ? .red : .gray)
                                .frame(width: 80, height: 80)
                        }
                        Spacer()
                    }
                }
                .padding(.bottom, 30)
            }
            .onAppear {
                multiCamCapture.setupPreview(size: CGSize(width: geometry.size.width / 2,
                                                          height: geometry.size.width * 8 / 9
                                                         ))
            }
        }
        .onDisappear {
            multiCamCapture.onDissapear()
        }
    }
}

#if DEBUG

#Preview {
    MultiCamCaptureView()
}

#endif

