import SwiftUI
import Photos

struct AlbumPickerView: View {
    @Binding var selectedAlbum: String
    @Environment(\.dismiss) var dismiss
    let albums: [PHAssetCollection] // ✅ Receive preloaded albums
    let index: Int
    let albumManager: AlbumManager
//    @State private var refreshTrigger = UUID() // Force refresh

    var body: some View {
        NavigationView {
            VStack {
                
                List {
                       // ✅ Add "No Album Selected" at the top
                       Button(action: {
                           selectedAlbum = ""
                           UserDefaultsManager.saveAlbum(selectedAlbum, at: index, albumID: "") // Save empty ID
                           Logger.log("📂 [AlbumPickerView] Selected name: \(selectedAlbum) (No ID) for index: \(index)")

                           dismiss() // Close the picker
                       }) {
                           Text(Constants.noAlbumSelected)
                               .foregroundColor(.red)
                       }

//                    if let favoritesAlbum = fetchFavoritesAlbum() {
                    if let favoritesAlbum = albumManager.fetchFavoritesAlbum() {
                        Button(action: {
                            let albumID = favoritesAlbum.localIdentifier
                            selectedAlbum = AlbumUtilities.formatAlbumName(favoritesAlbum.localizedTitle ?? "Favorites")
                            UserDefaultsManager.saveAlbum(selectedAlbum, at: index, albumID: albumID)
                            Logger.log("📂 [AlbumPickerView] Selected name: \(selectedAlbum) id: \(albumID) (System Favorites) for index: \(index)")
                            dismiss()
                        }) {
                            Text(favoritesAlbum.localizedTitle ?? "Favorites")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Text("Favorites album not found.") // In the list, no section header
                            .foregroundColor(.white)
                    }
                    
                       // ✅ Show real albums below
                       ForEach(albums, id: \.localIdentifier) { album in
                           Button(action: {
                               let albumID = album.localIdentifier
                               selectedAlbum = AlbumUtilities.formatAlbumName(album.localizedTitle ?? "Unknown")
                               UserDefaultsManager.saveAlbum(selectedAlbum, at: index, albumID: albumID) // Save ID!
                               Logger.log("📂 [AlbumPickerView] Selected name: \(selectedAlbum) id: \(albumID) for index: \(index)")

                               dismiss() // Close the picker
                           }) {
                               Text(album.localizedTitle ?? "Unknown")
                                   .foregroundColor(.white) // ✅ Make album names white

                           }
                           .buttonStyle(PlainButtonStyle()) // ✅ Ensures color override works
                       }
                   }
                .navigationTitle("Select Album")
            }
            .onAppear {
                Logger.log("📸 [AlbumPickerView] albums count onAppear: \(albums.count)")
            }
            
        }
        
//        .onChange(of: albums) { oldValue, newValue in // When albums change
//            refreshTrigger = UUID() // Trigger a refresh
//        }
//        .id(refreshTrigger) // Apply the ID to the root view

    }
    
//    // there are two fetchFavoritesAlbum
//    
//    private func fetchFavoritesAlbum() -> PHAssetCollection? {
//        let fetchOptions = PHFetchOptions()
//        let albums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: fetchOptions)
//        return albums.firstObject
//    }

}

