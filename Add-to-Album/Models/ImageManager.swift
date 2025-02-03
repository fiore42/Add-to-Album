import Photos
import UIKit

class ImageManager {
    private let imageRequestQueue = DispatchQueue(label: "imageRequestQueue", attributes: .concurrent)

    func getPhotoPermissionStatus() -> PhotoPermissionStatus {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized: return .granted
        case .limited: return .limited
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    func requestPhotoPermissions(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
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

    /// ✅ **Optimized Image Fetching with Controlled Parallelism**
    func fetchThumbnails(for assets: [PHAsset], maxConcurrentRequests: Int, completion: @escaping ([UIImage]) -> Void) {
        let targetSize = CGSize(width: 150, height: 150)
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat // 🔥 Load faster, lower quality if needed
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast

        DispatchQueue.global(qos: .userInitiated).async {
            let imageManager = PHCachingImageManager()
            var tempImages = [UIImage](repeating: UIImage(), count: assets.count)
            let group = DispatchGroup()
            let semaphore = DispatchSemaphore(value: maxConcurrentRequests) // Limits concurrent requests

            for (index, asset) in assets.enumerated() {
                group.enter()
                semaphore.wait() // Ensures we don't open too many threads

                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                    if let image = image {
                        tempImages[index] = image
                    }
                    semaphore.signal() // Allow another request
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(tempImages)
            }
        }
    }
}
