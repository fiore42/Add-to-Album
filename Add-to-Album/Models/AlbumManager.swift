import Photos
import Combine

class AlbumManager: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    @Published var albumChanges = UUID() // ✅ Triggers SwiftUI updates when album contents change
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self) // ✅ Register for system album changes
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self) // ✅ Prevent memory leaks
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            self.albumChanges = UUID() // ✅ Triggers SwiftUI updates
        }
    }

    func isPhotoInAlbum(photoID: String, albumID: String) -> Bool {
        let fetchOptions = PHFetchOptions()
        let albumFetchResult = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .any, options: fetchOptions
        )

        guard let album = albumFetchResult.firstObject else { return false }
        let assets = PHAsset.fetchAssets(in: album, options: nil)

        for index in 0..<assets.count {
            if assets.object(at: index).localIdentifier == photoID {
                return true
            }
        }
        return false
    }

    func togglePhotoInAlbum(photoID: String, albumID: String) {
        let key = "\(albumID)_\(photoID)"
        let currentState = UserDefaults.standard.bool(forKey: key)
        UserDefaults.standard.set(!currentState, forKey: key)

        Logger.log("📂 \(photoID) now \(currentState ? "removed from" : "added to") \(albumID)")

        DispatchQueue.main.async {
            self.albumChanges = UUID() // ✅ Updates UI when a change occurs
        }
    }
}
