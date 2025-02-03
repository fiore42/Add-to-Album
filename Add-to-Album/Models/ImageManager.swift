import Photos
import UIKit

class ImageManager {

    func requestPhotoPermissions(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            completion(status == .authorized || status == .limited)
        }
    }

    func fetchNextBatch(batchSize: Int, after asset: PHAsset?) -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        if let lastAsset = asset, let lastDate = lastAsset.creationDate {
            fetchOptions.predicate = NSPredicate(format: "creationDate < %@", lastDate as CVarArg)
        }

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        // Convert fetchResult to an array manually
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { (asset, index, stop) in
            if assets.count < batchSize {
                assets.append(asset)
            } else {
                stop.pointee = true
            }
        }

        return assets
    }


    func requestImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact

        PHImageManager.default().requestImage(
            for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options
        ) { image, _ in completion(image) }
    }
}
