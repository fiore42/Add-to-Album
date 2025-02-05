import SwiftUI
import Photos

struct AlbumPickerView: View {
    @Binding var selectedAlbum: String
    @Environment(\.dismiss) var dismiss
    let albums: [PHAssetCollection] // ✅ Receive preloaded albums
    let index: Int
    @State private var currentAlbums: [PHAssetCollection] = []

    var body: some View {
        NavigationView {
            VStack {
                if currentAlbums.isEmpty {
                    Text("📂 Loading albums...") // 🟢 Show a loading message
                        .foregroundColor(.gray)
                        .padding()
                } else {
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
            }
            .onAppear {
                Logger.log("📸 [AlbumPickerView] albums count onAppear: \(albums.count)")
                self.currentAlbums = albums
                
                // ✅ Listen for updates from PhotoLibraryObserver
                NotificationCenter.default.addObserver(forName: .albumsUpdated, object: nil, queue: .main) { _ in
                    Logger.log("📸 [AlbumPickerView] Albums updated via Notification")
                    self.currentAlbums = albums
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: .albumsUpdated, object: nil)
            }
            
        }
    }

}
