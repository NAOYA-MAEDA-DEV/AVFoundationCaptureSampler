import SwiftUI

struct ConnectionCaptureView: View {
    @StateObject private var connectionCapture = ConnectionCapture()
    
    @State private var isShowParamater: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                if let previewLayer = connectionCapture.previewLayer {
                    VideoPreviewLayerView(previewCALayer: previewLayer)
                        .frame(width: geometry.size.width,
                               height: geometry.size.width * 16 / 9)
                }
                if let img = connectionCapture.previewImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width / 2,
                               height: geometry.size.width * 8 / 9)
                }
            }
            VStack {
                ScrollView {
                    HStack {
                        Text("Video Stabilization Mode")
                        Spacer()
                        Text(connectionCapture.videoStabilizationModeStr)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("AutomaticallyAdjustsVideoMirroring - AVCaptureVideoPreviewLayer")
                        Spacer()
                        Text(connectionCapture.isAutomaticallyAdjustsPreviewLayerVideoMirroring.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("AutomaticallyAdjustsVideoMirroring - AVCapturePhotoOutput")
                        Spacer()
                        Text(connectionCapture.isAutomaticallyAdjustsPhotoOutputVideoMirroring.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("AutomaticallyAdjustsVideoMirroring - AVCaptureMovieFileOutput")
                        Spacer()
                        Text(connectionCapture.isAutomaticallyAdjustsMovieOutputVideoMirroring.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("AutomaticallyAdjustsVideoMirroring - AVCaptureVideoDataOutput")
                        Spacer()
                        Text(connectionCapture.isAutomaticallyAdjustsVideoDataOutputVideoMirroring.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("VideoMirrored - AVCaptureVideoPreviewLayer")
                        Spacer()
                        Text(connectionCapture.isPreviewLayerVideoMirrored.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("VideoMirrored - AVCapturePhotoOutput")
                        Spacer()
                        Text(connectionCapture.isPhotoOutputVideoMirrored.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("VideoMirrored - AVCaptureMovieFileOutput")
                        Spacer()
                        Text(connectionCapture.isMovieFileOutputVideoMirrored.description)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("VideoMirrored - AVCaptureVideoDataOutput")
                        Spacer()
                        Text(connectionCapture.isVideoDataOutputVideoMirroring.description)
                            .frame(width: 90)
                    }
                }
                .foregroundColor(.yellow)
                .background(Color.black.opacity(0.5))
                .frame(height: 200)
                .opacity(isShowParamater ? 1 : 0)
                Spacer()
                ScrollView {
                    Picker("Camera Devices", selection: $connectionCapture.selectedCameraIndex) {
                        ForEach(Array(connectionCapture.cameraDevices.enumerated()),
                                id: \.offset) { index, device in
                            Text(device.localizedName).tag(index)
                        }
                    }
                    .pickerStyle(.automatic)
                    HStack {
                        Text("Stabilization Mode")
                        Spacer()
                        Picker("Stabilization Mode", selection: $connectionCapture.videoStabilizationMode) {
                            ForEach(VideoStabilizationMode.allCases) { newMode in
                                Text(newMode.rawValue).tag(newMode)
                            }
                        }
                        .pickerStyle(.automatic)
                    }
                    Toggle("AutomaticallyAdjustsVideoMirroring - AVCaptureVideoPreviewLayer", isOn: $connectionCapture.isAutomaticallyAdjustsPreviewLayerVideoMirroring)
                        .disabled(connectionCapture.isPreviewLayerVideoMirrored)
                    Toggle("AutomaticallyAdjustsVideoMirroring - AVCapturePhotoOutput", isOn: $connectionCapture.isAutomaticallyAdjustsPhotoOutputVideoMirroring)
                    Toggle("AutomaticallyAdjustsVideoMirroring - AVCaptureMovieFileOutput", isOn: $connectionCapture.isAutomaticallyAdjustsMovieOutputVideoMirroring)
                    Toggle("AutomaticallyAdjustsVideoMirroring - AVCaptureVideoDataOutput", isOn: $connectionCapture.isAutomaticallyAdjustsVideoDataOutputVideoMirroring)
                    Toggle("VideoMirrored - AVCaptureVideoPreviewLayer", isOn: $connectionCapture.isPreviewLayerVideoMirrored)
                        .disabled(connectionCapture.isAutomaticallyAdjustsPreviewLayerVideoMirroring)
                    Toggle("VideoMirrored - AVCapturePhotoOutput", isOn: $connectionCapture.isPhotoOutputVideoMirrored)
                        .disabled(connectionCapture.isAutomaticallyAdjustsPhotoOutputVideoMirroring)
                    Toggle("VideoMirrored - AVCaptureMovieFileOutput", isOn: $connectionCapture.isMovieFileOutputVideoMirrored)
                        .disabled(connectionCapture.isAutomaticallyAdjustsMovieOutputVideoMirroring)
                    Toggle("VideoMirrored - AVCaptureVideoDataOutput", isOn: $connectionCapture.isVideoDataOutputVideoMirroring)
                        .disabled(connectionCapture.isAutomaticallyAdjustsVideoDataOutputVideoMirroring)
                    HStack(alignment: .center) {
                        Spacer()
                        Button(action: {
                            connectionCapture.controlRecording()
                        }) {
                            ZStack {
                                Circle()
                                    .foregroundColor(connectionCapture.isRecording ? .red : .gray)
                                    .frame(width: 80, height: 80)
                                Image(systemName: "video")
                                    .tint(.white)
                            }
                        }
                        Button(action: {
                            Task {
                                await connectionCapture.capturePhoto()
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
            .onChange(of: connectionCapture.previewLayer) {
                connectionCapture.setupPreview(size: CGSize(width: geometry.size.width,
                                                            height: geometry.size.width * 16 / 9))
            }
        }
        .onChange(of: connectionCapture.selectedCameraIndex) {
            connectionCapture.changeCameraDevice()
        }
        .onChange(of: connectionCapture.videoStabilizationMode) {
            print(connectionCapture.videoStabilizationMode)
            connectionCapture.changeVideoStabilization()
        }
        .onChange(of: connectionCapture.isAutomaticallyAdjustsPreviewLayerVideoMirroring) {
            connectionCapture.toggleAutomaticallyAdjustsPreviewLayerVideoMirroring()
        }
        .onChange(of: connectionCapture.isAutomaticallyAdjustsPhotoOutputVideoMirroring) {
            connectionCapture.toggleAutomaticallyAdjustsPhotoOutputVideoMirroring()
        }
        .onChange(of: connectionCapture.isAutomaticallyAdjustsMovieOutputVideoMirroring) {
            connectionCapture.toggleAutomaticallyAdjustsMovieOutputVideoMirroring()
        }
        .onChange(of: connectionCapture.isAutomaticallyAdjustsVideoDataOutputVideoMirroring) {
            connectionCapture.toggleAutomaticallyAdjustsVideoDataOutputVideoMirroring()
        }
        .onChange(of: connectionCapture.isPreviewLayerVideoMirrored) {
            connectionCapture.togglePreviewLayerVideoMirrored()
        }
        .onChange(of: connectionCapture.isPhotoOutputVideoMirrored) {
            connectionCapture.togglePhotoOutputVideoMirrored()
        }
        .onChange(of: connectionCapture.isMovieFileOutputVideoMirrored) {
            connectionCapture.toggleMovieOutputVideoMirrored()
        }
        .onChange(of: connectionCapture.isVideoDataOutputVideoMirroring) {
            connectionCapture.toggleVideoDataOutputVideoMirrored()
        }
        .onDisappear {
            connectionCapture.onDissapear()
        }
    }
}

#if DEBUG

#Preview {
    ConnectionCaptureView()
}

#endif

