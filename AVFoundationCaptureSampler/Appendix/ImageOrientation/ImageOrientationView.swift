import SwiftUI

struct ImageOrientationView: View {
    @StateObject private var imageOrientation = ImageOrientation()
    
    var body: some View {
        GeometryReader { geometry in
            if let img = imageOrientation.previewImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            }
            VStack {
                Spacer()
                NavigationLink {
                    CheckExifView {
                        imageOrientation.startCaptureSession()
                    }
                } label: {
                    Text("Check Image Orientation")
                }
                .buttonStyle(.borderedProminent)
                Picker("Orientation", selection: $imageOrientation.selectedOrientation) {
                    ForEach(ImageOrientationType.allCases) { orientationType in
                        Text(orientationType.rawValue).tag(orientationType)
                    }
                }
                .pickerStyle(.automatic)
                HStack {
                    Spacer()
                    Button(action: {
                        imageOrientation.capturePreview()
                    }) {
                        Circle()
                            .foregroundColor(.gray)
                            .frame(width: 80, height: 80)
                    }
                    Spacer()
                }
            }
        }
        .onDisappear {
            imageOrientation.onDissapear()
        }
    }
}

#if DEBUG

#Preview {
    ImageOrientationView()
}

#endif
