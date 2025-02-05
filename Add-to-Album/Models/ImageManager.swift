import Photos
import UIKit

class ImageManager {
    func getPhotoPermissionStatus() -> PhotoPermissionStatus {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) { // Request readWrite access
        case .authorized: return .granted
        case .limited: return .limited
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    func requestPhotoPermissions(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in // Request readWrite access
            DispatchQueue.main.async {
                completion(status == .authorized || status == .limited)
            }
        }
    }

    func fetchAllAssets() -> PHFetchResult<PHAsset> {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }

    func fetchThumbnails(for assets: [PHAsset], targetSize: CGSize, completion: @escaping ([UIImage]) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic // Or .highQualityFormat if needed
        options.isNetworkAccessAllowed = true // If you need to fetch from iCloud
        options.resizeMode = .exact // Or .none if you want the original size

        let imageManager = PHCachingImageManager() // Use PHCachingImageManager for efficiency

        var thumbnails: [UIImage] = Array(repeating: UIImage(), count: assets.count) // Initialize with placeholders

        for (index, asset) in assets.enumerated() {
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, info in
                DispatchQueue.main.async {
                    if let image = image {
                        thumbnails[index] = image
                    } else {
                        // Handle cases where image loading fails (e.g., iCloud not available)
                        print("Failed to load thumbnail for asset: \(asset)")
                    }
                    if index == assets.count - 1 { // All requests are done
                        completion(thumbnails)
                    }
                }
            }
        }
    }
}
