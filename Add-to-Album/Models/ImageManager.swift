import Photos
import UIKit

class ImageManager {

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

//    /// ✅ **Parallelized Image Fetching (Super Fast)**
//    func fetchThumbnails(for assets: [PHAsset], completion: @escaping ([UIImage]) -> Void) {
//        let targetSize = CGSize(width: 150, height: 150)
//        let options = PHImageRequestOptions()
//        options.deliveryMode = .opportunistic
//        options.isNetworkAccessAllowed = true
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            let imageManager = PHCachingImageManager()
//            var tempImages = [UIImage]()
//            let group = DispatchGroup()
//
//            for asset in assets {
//                group.enter()
//                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
//                    if let image = image {
//                        tempImages.append(image)
//                    }
//                    group.leave()
//                }
//            }
//
//            group.notify(queue: .main) {
//                completion(tempImages)
//            }
//        }
//    }
}
