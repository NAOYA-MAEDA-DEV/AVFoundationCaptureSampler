import SwiftUI

struct RotationCaptureView: View {
    @StateObject private var rotationCapture = RotationCapture()
    
    @State private var isShowParamater: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                if let previewLayer = rotationCapture.previewLayer {
                    VideoPreviewLayerView(previewCALayer: previewLayer)
                        .frame(width: geometry.size.width,
                               height: geometry.size.width * 4 / 3)
                }
                if let img = rotationCapture.previewImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width / 2,
                               height: geometry.size.width * 2 / 3)
                }
            }
            VStack {
                ScrollView {
                    HStack {
                        Text("PreviewLayer Angle")
                        Spacer()
                        Text(rotationCapture.previewLayerAngle.rawValue)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("PhotoOutput Angle")
                        Spacer()
                        Text(rotationCapture.movieFileOutputAngle.rawValue)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("MovieFileOutput Angle")
                        Spacer()
                        Text(rotationCapture.movieFileOutputAngle.rawValue)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("VideoDataOutput Angle")
                        Spacer()
                        Text(rotationCapture.videoDataOutputAngle.rawValue)
                            .frame(width: 90)
                    }
                }
                .foregroundColor(.yellow)
                .background(Color.black.opacity(0.5))
                .frame(height: 200)
                .opacity(isShowParamater ? 1 : 0)
                Spacer()
                ScrollView {
                    Picker("Camera Devices", selection: $rotationCapture.selectedCameraIndex) {
                        ForEach(Array(rotationCapture.cameraDevices.enumerated()),
                                id: \.offset) { index, device in
                            Text(device.localizedName).tag(index)
                        }
                    }
                    .pickerStyle(.automatic)
                    Toggle(isOn: $rotationCapture.isAutoRotation) {
                        Text("AutoRotationIs")
                    }
                    .toggleStyle(.switch)
                    HStack {
                        Text("PreviewLayer Rotation")
                        Spacer()
                        Picker("PreviewLayer Rotation", selection: $rotationCapture.previewLayerAngle) {
                            ForEach(VideoAngle.allCases) { angle in
                                Text(angle.rawValue).tag(angle)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    HStack {
                        Text("PhotoOutput Rotation")
                        Spacer()
                        Picker("PhotoOutput Rotation", selection: $rotationCapture.photoOutputAngle) {
                            ForEach(VideoAngle.allCases) { angle in
                                Text(angle.rawValue).tag(angle)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    HStack {
                        Text("MovieFileOutput Rotation")
                        Spacer()
                        Picker("MovieFileOutput Rotation", selection: $rotationCapture.movieFileOutputAngle) {
                            ForEach(VideoAngle.allCases) { angle in
                                Text(angle.rawValue).tag(angle)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    HStack {
                        Text("VideoDataOutput Rotation")
                        Spacer()
                        Picker("VideoDataOutput Rotation", selection: $rotationCapture.videoDataOutputAngle) {
                            ForEach(VideoAngle.allCases) { angle in
                                Text(angle.rawValue).tag(angle)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    HStack(alignment: .center) {
                        Spacer()
                        Button(action: {
                            rotationCapture.controlRecording()
                        }) {
                            ZStack {
                                Circle()
                                    .foregroundColor(rotationCapture.isRecording ? .red : .gray)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "video")
                                    .tint(.white)
                            }
                        }
                        Button(action: {
                            Task {
                                await rotationCapture.capturePhoto()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .foregroundColor(.gray)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "camera")
                                    .tint(.white)
                            }
                        }
                        Spacer()
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
            .onChange(of: rotationCapture.selectedCameraIndex) {
                rotationCapture.changeCameraDevice()
            }
            .onChange(of: rotationCapture.photoOutputAngle) {
                rotationCapture.updatePhotoOutputRotation()
            }
            .onChange(of: rotationCapture.movieFileOutputAngle) {
                rotationCapture.updateMovieFileOutputRotation()
            }
            .onChange(of: rotationCapture.videoDataOutputAngle) {
                rotationCapture.updateVideoDataOutputRotation()
            }
            .onChange(of: rotationCapture.previewLayerAngle) {
                rotationCapture.updatePreviewLayerRotation()
            }
            .onChange(of: rotationCapture.previewLayer) {
                rotationCapture.setupPreview(size: CGSize(width: geometry.size.width,
                                                          height: geometry.size.width * 4 / 3))
            }
            .onDisappear {
                rotationCapture.onDissapear()
            }
        }
    }
}

#if DEBUG

#Preview {
    RotationCaptureView()
}

#endif

