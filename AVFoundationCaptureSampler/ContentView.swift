import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                Section(
                    footer: VStack {
                        Spacer()
                        Text("App Version: \(appVersion)")
                        Text("Build Number: \(appBuildNumber)")
                    }.frame(maxWidth: .infinity)
                ) {
                    NavigationLink(destination: AccessView()) {
                        Text("Access")
                    }
                    NavigationLink(destination: DisplayPreviewView()) {
                        Text("Display Preview")
                    }
                    NavigationLink(destination: PhotoCaptureView()) {
                        Text("Photo Capture")
                    }
                    NavigationLink(destination: MovieCaptureView()) {
                        Text("Movie Capture")
                    }
                    NavigationLink(destination: LivePhotosCaptureView()) {
                        Text("Live Photos Capture")
                    }
                    NavigationLink(destination: CameraDeviceView()) {
                        Text("Camera Device")
                    }
                    NavigationLink(destination: ManualFocusView()) {
                        Text("Manual Focus")
                    }
                    NavigationLink(destination: ManualExposureView()) {
                        Text("Manual Exposure")
                    }
                    NavigationLink(destination: ManualWhiteBalanceView()) {
                        Text("Manual WhiteBalance")
                    }
                    NavigationLink(destination: LightCaptureView()) {
                        Text("Light Capture")
                    }
                    NavigationLink(destination: ZoomView()) {
                        Text("Zoom")
                    }
                    NavigationLink(destination: PhotoSettingsCaptureView()) {
                        Text("Photo Settings Capture")
                    }
                    NavigationLink(destination: ConnectionCaptureView()) {
                        Text("Connection Capture")
                    }
                    NavigationLink(destination: RotationCaptureView()) {
                        Text("Rotation Capture")
                    }
                    NavigationLink(destination: MetadataCaptureView()) {
                        Text("Metadata Capture")
                    }
                    NavigationLink(destination: SlowMotionMovieCaptureView()) {
                        Text("Slow Motion Movie Capture")
                    }
                    NavigationLink(destination: MovieWriterCaptureView()) {
                        Text("Movie AssetWriter Capture")
                    }
                    NavigationLink(destination: MultiCamCaptureView()) {
                        Text("Multi Cam Capture")
                    }
                    NavigationLink(destination: RawCaptureView()) {
                        Text("RAW / Apple ProRAW Capture")
                    }
                    NavigationLink(destination: AppleLogCaptureView()) {
                        Text("Apple Log Capture")
                    }
                    NavigationLink(destination: ThumbnailCaptureView()) {
                        Text("Thumbnail Capture")
                    }
                    NavigationLink(destination: ImageOrientationView()) {
                        Text("Image Orientation")
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("AVFoundation Capture Sampler")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#if DEBUG

#Preview {
    ContentView()
}

#endif
