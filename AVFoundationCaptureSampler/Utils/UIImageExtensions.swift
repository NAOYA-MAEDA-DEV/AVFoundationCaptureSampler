import UIKit

extension UIImage {
    func imageOrientationStr() -> String {
        switch self.imageOrientation {
        case .up:
            return "up"
            
        case .down:
            return "down"
            
        case .left:
            return "left"
            
        case .right:
            return "right"
            
        case .upMirrored:
            return "upMirrored"
            
        case .downMirrored:
            return "downMirrored"
            
        case .leftMirrored:
            return "leftMirrored"
            
        case .rightMirrored:
            return "rightMirrored"
            
        @unknown default:
            fatalError()
        }
    }
}
