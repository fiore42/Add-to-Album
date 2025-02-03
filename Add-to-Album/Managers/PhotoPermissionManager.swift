import Foundation
import Photos

enum PhotoPermissionStatus {
    case granted
    case limited
    case denied
    case notDetermined
    case restricted
}

/// A simple manager for checking and requesting photo permissions.
class PhotoPermissionManager {
    
    static func currentStatus() -> PhotoPermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            return .granted
        case .limited:
            return .limited
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }
    
    static func requestPermission(completion: @escaping (PhotoPermissionStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(.granted)
                case .limited:
                    completion(.limited)
                case .denied:
                    completion(.denied)
                case .notDetermined:
                    completion(.notDetermined)
                case .restricted:
                    completion(.restricted)
                @unknown default:
                    completion(.denied)
                }
            }
        }
    }
}
