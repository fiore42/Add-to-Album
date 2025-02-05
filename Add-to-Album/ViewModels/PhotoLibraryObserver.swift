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
           let fetchOptions = PHFetchOptions()
           let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

           // Get change details specifically for albums
           if let albumChanges = changeInstance.changeDetails(for: fetchResult) {
               let insertedAlbums = albumChanges.insertedObjects
               let removedAlbums = albumChanges.removedObjects
               let changedAlbums = albumChanges.changedObjects.filter {
                   return changeInstance.changeDetails(for: $0)?.assetContentChanged == true
               }

               if albumChanges.hasIncrementalChanges {
                   Logger.log("🔄 Detected Changes in Photo Library:")
                   
                   if !insertedAlbums.isEmpty {
                       Logger.log("➕ New Albums Added: \(insertedAlbums.map { $0.localizedTitle ?? "Unknown" })")
                   }
                   if !removedAlbums.isEmpty {
                       Logger.log("❌ Albums Removed: \(removedAlbums.map { $0.localizedTitle ?? "Unknown" })")
                   }
                   if !changedAlbums.isEmpty {
                       Logger.log("✏️ Albums Renamed/Updated: \(changedAlbums.map { $0.localizedTitle ?? "Unknown" })")
                   }

                   DispatchQueue.main.async {
                       self.fetchAlbums() // ✅ Refresh only when albums are changed
                   }
               }
           }
       }
    
}



