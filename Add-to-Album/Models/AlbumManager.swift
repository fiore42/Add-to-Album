import SwiftUI
import Photos
import Combine

class AlbumManager: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    @Published var albumChanges = UUID()

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            self.albumChanges = UUID()
        }
    }

    func isPhotoInAlbum(photoID: String, albumID: String) -> Bool {
        guard let album = fetchAlbumByID(albumID) else { return false }
        let fetchResult = PHAsset.fetchAssets(in: album, options: nil)
        for index in 0..<fetchResult.count {
            let asset = fetchResult[index]
            if asset.localIdentifier == photoID {
                return true
            }
        }
        return false
    }

    func togglePhotoInAlbum(photoID: String, albumID: String) {
        guard let album = fetchAlbumByID(albumID) else { return }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoID], options: nil)
        guard let photo = fetchResult.firstObject else { return }

        PHPhotoLibrary.shared().performChanges {
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            if self.isPhotoInAlbum(photoID: photoID, albumID: albumID) {
                albumChangeRequest?.removeAssets([photo] as NSFastEnumeration)
                print("Removed \(photoID) from \(albumID)")
            } else {
                albumChangeRequest?.addAssets([photo] as NSFastEnumeration)
                print("Added \(photoID) to \(albumID)")
            }
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                self.albumChanges = UUID()
                if let error = error {
                    print("Error toggling photo in album: \(error)")
                }
            }
        }
    }

    private func fetchAlbumByID(_ albumID: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        let albumsFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        for index in 0..<albumsFetchResult.count {
            let album = albumsFetchResult[index]
            if album.localIdentifier == albumID {
                return album
            }
        }
        return nil
    }
}
