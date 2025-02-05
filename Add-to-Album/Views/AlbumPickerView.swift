import SwiftUI
import Photos

struct AlbumPickerView: View {
    @Binding var selectedAlbum: String
    @Environment(\.dismiss) var dismiss
    let albums: [PHAssetCollection] // ✅ Receive preloaded albums
    let index: Int
    

    var body: some View {
        NavigationView {
            VStack {
                
                List(albums, id: \.localIdentifier) { album in // 'album' is available here
                    Button(action: {
                        Logger.log("📂 [AlbumPickerView] Opening Album PickerView for index \(index), Album: \(album)")

                        let albumID = album.localIdentifier
                        selectedAlbum = AlbumUtilities.formatAlbumName(album.localizedTitle ?? "Unknown")
                        UserDefaultsManager.saveAlbum(selectedAlbum, at: index, albumID: albumID) // Save ID!
                        dismiss() // 'dismiss' is available here
                    }) {
                        Text(album.localizedTitle ?? "Unknown")
                    }
                }
                .navigationTitle("Select Album")

            }
            .onAppear {
                Logger.log("📸 [AlbumPickerView] albums: \(albums)")
            }
            
        }
    }

}
