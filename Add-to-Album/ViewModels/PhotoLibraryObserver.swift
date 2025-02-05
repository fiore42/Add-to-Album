import Photos

class PhotoLibraryObserver: NSObject, PHPhotoLibraryChangeObserver, ObservableObject {
    @Published var albums: [PHAssetCollection] = [] // ✅ Store real-time albums

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self) // ✅ Register for album changes
        fetchAlbums() // ✅ Fetch initial albums
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self) // ✅ Clean up when not needed
    }

    func fetchAlbums() {
         let fetchOptions = PHFetchOptions()
         let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

         var fetchedAlbums: [PHAssetCollection] = []
         userAlbums.enumerateObjects { collection, _, _ in
             fetchedAlbums.append(collection)
         }

         DispatchQueue.main.async {
             self.albums = fetchedAlbums
             Logger.log("📸 Albums Updated: \(self.albums.count)")
             
             // ✅ Automatically update selected albums when fetching completes
            AlbumUtilities.updateSelectedAlbums(photoObserverAlbums: self.albums)
         }
     }
//    func photoLibraryDidChange(_ changeInstance: PHChange) {
//        DispatchQueue.main.async {
//            Logger.log("🔄 Detected Changes in Photo Library - Refreshing Albums")
//            self.fetchAlbums() // ✅ Refresh album list when a change is detected
//        }
//    }
    
    
//    https://stackoverflow.com/questions/42657266/phphotolibrary-photolibrarydidchange-called-multiple-times-in-swift
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let _fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil) as? PHFetchResult<PHObject> else {
            return
        }

        if let resultDetailChanges = changeInstance.changeDetails(for: _fetchResult) {
            let insertedObjects = resultDetailChanges.insertedObjects
            let removedObjects = resultDetailChanges.removedObjects
            let changedObjects = resultDetailChanges.changedObjects.filter {
                return changeInstance.changeDetails(for: $0)?.assetContentChanged == true
            }

            if resultDetailChanges.hasIncrementalChanges && (!insertedObjects.isEmpty || !removedObjects.isEmpty || !changedObjects.isEmpty) {
                DispatchQueue.main.async {
                    Logger.log("🔄 Detected Changes in Photo Library - Refreshing Albums")
                    self.fetchAlbums() // ✅ Refresh album list when a change is detected
                }
            }
        }
    }

    
}



