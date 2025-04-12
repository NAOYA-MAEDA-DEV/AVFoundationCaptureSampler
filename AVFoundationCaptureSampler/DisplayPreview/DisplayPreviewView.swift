import SwiftUI

struct DisplayPreviewView: View {
    @StateObject private var displayPreview = DisplayPreview()
    
    var body: some View {
        if let img = displayPreview.previewImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .onDisappear {
                    displayPreview.onDissapear()
                }
        }
    }
}

#if DEBUG

#Preview {
    DisplayPreviewView()
}

#endif
