import SwiftUI

struct AccessView: View {
    @Environment(\.openURL) var openURL
    
    @StateObject private var access = Access()
    
    var body: some View {
        VStack(spacing: 30) {
            Button("Camera", action: {
                Task {
                    _ = await access.requestCameraAuthorization()
                }
            })
            Button("Microphone", action: {
                Task {
                    _ = await access.requestMicAuthorization()
                }
            })
            Button("Photo Library - AddOnly", action: {
                Task {
                    _ = await access.requestAddOnlyPhotosAuthorization()
                }
            })
            Button("Photo Library - ReadWrite", action: {
                Task {
                    _ = await access.requestReadWritePhotosAuthorization()
                }
            })
            Button("Location - RequestWhenInUseAuthorization", action: {
                access.requestWhenInUseAuthorization()
                
            })
            Button("Open settings screen", action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            })
        }
        .buttonStyle(.borderedProminent)
    }
}

#if DEBUG

#Preview {
    AccessView()
}

#endif
