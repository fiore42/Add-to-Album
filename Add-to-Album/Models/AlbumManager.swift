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
        // ✅ Check if it's the Favorites album
        if let favoritesAlbum = fetchFavoritesAlbum(), albumID == favoritesAlbum.localIdentifier {
            return isPhotoInFavorites(photoID: photoID) // ✅ Check favorite status
        }
        
        // ✅ Otherwise, check normal albums
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

    private func isPhotoInFavorites(photoID: String) -> Bool {
        guard let photo = fetchAssetByID(photoID) else { return false }
        return photo.isFavorite
    }
    
    func togglePhotoInAlbum(photoID: String, albumID: String) {
        if let favoritesAlbum = fetchFavoritesAlbum(), albumID == favoritesAlbum.localIdentifier {
            togglePhotoInFavorites(photoID: photoID)
        } else {
            guard let album = fetchAlbumByID(albumID) else { return }
            togglePhotoInRegularAlbum(photoID: photoID, album: album)
        }
    }
    
    private func togglePhotoInFavorites(photoID: String) {
        guard let photo = fetchAssetByID(photoID) else { return }
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: photo)
            request.isFavorite = !photo.isFavorite
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                self.albumChanges = UUID()
                if let error = error {
                    Logger.log("Error toggling favorite: \(error)")
                }
            }
        }
    }

    private func togglePhotoInRegularAlbum(photoID: String, album: PHAssetCollection) {
        guard let photo = fetchAssetByID(photoID) else { return }

        PHPhotoLibrary.shared().performChanges {
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            if self.isPhotoInAlbum(photoID: photoID, albumID: album.localIdentifier) {
                albumChangeRequest?.removeAssets([photo] as NSFastEnumeration)
                Logger.log("Removed \(photoID) from \(album.localIdentifier)")
            } else {
                albumChangeRequest?.addAssets([photo] as NSFastEnumeration)
                Logger.log("Added \(photoID) to \(album.localIdentifier)")
            }
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                self.albumChanges = UUID()
                if let error = error {
                    Logger.log("Error toggling photo in album: \(error)")
                }
            }
        }
    }
    
    private func fetchAssetByID(_ photoID: String) -> PHAsset? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoID], options: nil)
        return fetchResult.firstObject
    }

    func fetchFavoritesAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        let albums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: fetchOptions)
        return albums.firstObject
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
