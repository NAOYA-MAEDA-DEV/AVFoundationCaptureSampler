import SwiftUI
import PhotosUI

struct CheckExifView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var image: UIImage? = nil
    @State private var orientation: Int?
    let onDissapear: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            if let image = image {
                VStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
                    Text("imageOrientation Property: \(image.imageOrientationStr())")
                }
            }
            VStack(alignment: .center) {
                Spacer()
                if let orientation {
                    Text("Orientation \(orientation)")
                }
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()) {
                        Text("Select Photo")
                    }
                    .buttonStyle(.borderedProminent)
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        }
        .onDisappear {
            onDissapear()
        }
        .onChange(of: selectedItem) {
            if let selectedItem {
                selectedItem.loadTransferable(type: Data.self) { result in
                    switch result {
                    case .success(let data):
                        if let data = data, let uiImage = UIImage(data: data) {
                            image = uiImage
                            orientation = extractExifOrientation(from: data)
                        }
                        
                    case .failure(let error):
                        print(error)
                    }
                    self.selectedItem = nil
                }
            }
        }
    }
    
    private func extractExifOrientation(from imageData: Data) -> Int? {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let orientation = properties[kCGImagePropertyOrientation] as? Int else {
            return nil
        }
        return orientation
    }
}

#if DEBUG

#Preview {
    CheckExifView{}
}

#endif
