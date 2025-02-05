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
        }
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            Logger.log("🔄 Detected Changes in Photo Library - Refreshing Albums")
            self.fetchAlbums() // ✅ Refresh album list when a change is detected
        }
    }
}
