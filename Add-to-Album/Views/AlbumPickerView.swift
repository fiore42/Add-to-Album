import SwiftUI
import Photos

struct AlbumPickerView: View {
    @Binding var selectedAlbum: String
    @Environment(\.dismiss) var dismiss
    let albums: [PHAssetCollection] // ✅ Receive preloaded albums
    let index: Int
    
//    @State private var albums: [PHAssetCollection] = []
//    private var photoLibraryChangeObserver: PHPhotoLibraryChangeObserver?

    var body: some View {
        NavigationView {
            VStack {
                
                List(albums, id: \.localIdentifier) { album in
                    Button(action: {
                        let albumID = album.localIdentifier // ✅ Ensure this is a String
                        selectedAlbum = AlbumUtilities.formatAlbumName(album.localizedTitle ?? "Unknown")
                        UserDefaultsManager.saveAlbum(selectedAlbum, at: index, albumID: albumID) // ✅ Now `index` is correctly passed
                        dismiss()
                    }) {
                        Text(album.localizedTitle ?? "Unknown")
                    }
                }
                .navigationTitle("Select Album")

            }
            
//            .onDisappear { // ADD THIS: Remove observer
//                if let observer = photoLibraryChangeObserver {
//                    PHPhotoLibrary.shared().unregister(observer)
//                }
//            }
//            .onChange(of: selectedAlbum) {oldvalue, newValue in // ADD THIS: Reset selectedAlbum
//                let savedAlbums = UserDefaultsManager.getSavedAlbums()
//                if !savedAlbums.contains(newValue) {
//                    selectedAlbum = "No Album Selected"
//                }
//            }
        }
    }

}
