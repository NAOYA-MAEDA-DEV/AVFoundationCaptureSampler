import SwiftUI

struct PhotoSettingsCaptureView: View {
    @StateObject private var photoSettingsCapture = PhotoSettingsCapture()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let previewLayer = photoSettingsCapture.previewLayer {
                    VideoPreviewLayerView(previewCALayer: previewLayer)
                        .frame(width: geometry.size.width,
                               height: geometry.size.width * 4 / 3)
                    Spacer()
                }
            }
            VStack {
                Spacer()
                Picker("Camera Devices", selection: $photoSettingsCapture.selectedCameraDeviceIndex) {
                    ForEach(Array(photoSettingsCapture.cameraDevices.enumerated()),
                            id: \.offset) { index, device in
                        Text(device.localizedName).tag(index)
                    }
                }
                .pickerStyle(.automatic)
                Picker("Format", selection: $photoSettingsCapture.saveImageFormatType) {
                    ForEach(SaveImageFormatType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                Picker("PhotoQualityPrioritization", selection: $photoSettingsCapture.photoQualityPrioritization) {
                    ForEach(PhotoQualityPrioritization.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                Toggle(isOn: $photoSettingsCapture.exifLocationisOn) {
                    Text("Exif Location")
                }
                Toggle(isOn: $photoSettingsCapture.isAutoRedEyeReductionEnabled) {
                    Text("AutoRedEyeReductionEnabled")
                }
                Toggle(isOn: $photoSettingsCapture.isBracketSettingsEnabled) {
                    Text("Bracketed Photo")
                }
                HStack(alignment: .center) {
                    Spacer()
                    Button(action: {
                        Task {
                            await photoSettingsCapture.capturePhoto()
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
            .onChange(of: photoSettingsCapture.selectedCameraDeviceIndex) {
                photoSettingsCapture.changeCameraDevice()
            }
            .onChange(of: photoSettingsCapture.previewLayer) {
                photoSettingsCapture.setupPreview(size: CGSize(width: geometry.size.width,
                                                               height: geometry.size.width * 4 / 3))
            }
            .onDisappear {
                photoSettingsCapture.onDissapear()
            }
        }
    }
}

#if DEBUG

#Preview {
    PhotoSettingsCaptureView()
}

#endif

