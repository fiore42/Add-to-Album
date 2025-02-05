import Photos

class AlbumManager: ObservableObject {

    func isPhotoInAlbum(photoID: String, albumID: String) -> Bool {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", albumID)

        let albumFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        guard let album = albumFetchResult.firstObject else {
            Logger.log("⚠️ Album not found for ID: \(albumID)")
            return false
        }

        let assetsFetchOptions = PHFetchOptions()
        let assets = PHAsset.fetchAssets(in: album, options: assetsFetchOptions)

        var isPhotoInAlbum = false

        assets.enumerateObjects { asset, _, stop in
            if asset.localIdentifier == photoID {
                isPhotoInAlbum = true
                stop.pointee = true // Stop the iteration early once found
            }
        }

        return isPhotoInAlbum
    }


    func togglePhotoInAlbum(photoID: String, albumID: String) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", albumID)

        let albumFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        guard let album = albumFetchResult.firstObject else {
            Logger.log("⚠️ Cannot toggle photo: Album not found")
            return
        }

        let assetsFetchOptions = PHFetchOptions()
        let assetFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photoID], options: assetsFetchOptions)

        guard let photo = assetFetchResult.firstObject else {
            Logger.log("⚠️ Cannot toggle photo: Photo not found")
            return
        }

        PHPhotoLibrary.shared().performChanges({
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            
            if self.isPhotoInAlbum(photoID: photoID, albumID: albumID) {
                Logger.log("📂 Removing \(photoID) from album \(albumID)")
                albumChangeRequest?.removeAssets([photo] as NSArray)
            } else {
                Logger.log("📂 Adding \(photoID) to album \(albumID)")
                albumChangeRequest?.addAssets([photo] as NSArray)
            }
        }) { success, error in
            if let error = error {
                Logger.log("❌ Failed to update album: \(error)")
            } else {
                Logger.log("✅ Album successfully updated")
            }
        }
    }

}
