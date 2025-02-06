import Photos
import SwiftUI

class PhotoLibraryObserver: NSObject, PHPhotoLibraryChangeObserver, ObservableObject {
    @Published var albums: [PHAssetCollection] = [] // ✅ Store real-time albums
//    let albumSelectionViewModel: AlbumSelectionViewModel
    
    
    var albumSelectionViewModel: AlbumSelectionViewModel? // ✅ Make it mutable (not `let`)
    
    //    init(albumSelectionViewModel: AlbumSelectionViewModel) {
    //        self.albumSelectionViewModel = albumSelectionViewModel
    //        super.init()
    //        PHPhotoLibrary.shared().register(self)
    //        fetchAlbums()
    //    }
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self) // ✅ Register for album changes
        fetchAlbums() // ✅ Fetch initial albums
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self) // ✅ Clean up when not needed
    }
    
    // ✅ Set `albumSelectionViewModel` when it becomes available
    func setAlbumSelectionViewModel(_ viewModel: AlbumSelectionViewModel) {
        self.albumSelectionViewModel = viewModel
        Logger.log("🔄 [PhotoLibraryObserver] AlbumSelectionViewModel Injected")
        
        // ✅ Update selected albums after setting ViewModel
        self.albumSelectionViewModel?.updateSelectedAlbums(photoObserverAlbums: self.albums)
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
             self.albumSelectionViewModel?.updateSelectedAlbums(photoObserverAlbums: self.albums)
                          
         }
     }
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            Logger.log("🔄 Detected Changes in Photo Library - Refreshing Albums")
            self.fetchAlbums() // ✅ Refresh album list when a change is detected
        }
    }
    

}



