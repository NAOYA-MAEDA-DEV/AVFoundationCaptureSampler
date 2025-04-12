import SwiftUI

struct VideoPreviewLayerView: UIViewControllerRepresentable {
    var previewCALayer: CALayer
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPreviewLayerView>)
    -> UIViewController {
        let viewController = UIViewController()
        
        viewController.view.layer.addSublayer(previewCALayer)
        previewCALayer.frame = viewController.view.layer.frame
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController,
                                context: UIViewControllerRepresentableContext<VideoPreviewLayerView>) {
        previewCALayer.frame = uiViewController.view.layer.frame
    }
}
