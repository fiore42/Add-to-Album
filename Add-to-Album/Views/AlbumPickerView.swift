import SwiftUI
import Photos

struct AlbumPickerView: View {
    @Binding var selectedAlbum: String
    @Environment(\.dismiss) var dismiss
//    let albums: [PHAssetCollection] // ✅ Receive preloaded albums
    
    @State private var albums: [PHAssetCollection] = []
//    private var photoLibraryChangeObserver: PHPhotoLibraryChangeObserver?

    var body: some View {
        NavigationView {
            VStack {
                
                List(albums, id: \.localIdentifier) { album in
                    Button(action: {
                        selectedAlbum = AlbumUtilities.formatAlbumName(album.localizedTitle ?? "Unknown")
                        dismiss()
                    }) {
                        Text(album.localizedTitle ?? "Unknown")
                    }
                }
                .navigationTitle("Select Album")
                .onAppear { // REPLACE the existing .onAppear with this:
                    AlbumUtilities.fetchAlbums { fetchedAlbums in
                        withAnimation {
                            self.albums = fetchedAlbums
                        }
                    }
                    Logger.log("✅ AlbumPickerView Opened with Albums Count: \(albums.count)") // Keep the logging
                }
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
