import SwiftUI
import Photos

struct AlbumPickerView: View {
    @Binding var selectedAlbum: String
    @Environment(\.dismiss) var dismiss
    let albums: [PHAssetCollection] // ✅ Receive preloaded albums
    let index: Int
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
                               .fontWeight(.bold)
                               .foregroundColor(.red)
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
                           }
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

}

