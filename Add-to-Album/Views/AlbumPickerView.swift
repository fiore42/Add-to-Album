import SwiftUI
import Photos

struct AlbumPickerView: View {
    @Binding var selectedAlbum: String
    @Environment(\.dismiss) var dismiss
    @State private var albums: [PHAssetCollection] = []

    var body: some View {
        NavigationView {
            List(albums, id: \.localIdentifier) { album in
                Button(action: {
                    selectedAlbum = formatAlbumName(album.localizedTitle ?? "Unknown")
                    UserDefaultsManager.saveAlbums([selectedAlbum]) // Persist selection
                    dismiss()
                }) {
                    Text(album.localizedTitle ?? "Unknown")
                }
            }
            .navigationTitle("Select Album")
            .onAppear(perform: fetchAlbums)
        }
    }

    private func fetchAlbums() {
        let fetchOptions = PHFetchOptions()
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        albums = []
        userAlbums.enumerateObjects { collection, _, _ in
            albums.append(collection)
        }
    }

    private func formatAlbumName(_ name: String) -> String {
        let words = name.split(separator: " ")
        var shortName = ""
        var characterCount = 0

        if let firstWord = words.first, firstWord.count > 14 {
            return String(firstWord.prefix(12)) + "..."
        }

        for word in words {
            if characterCount + word.count + (shortName.isEmpty ? 0 : 1) > 14 {
                break
            }
            shortName += (shortName.isEmpty ? "" : " ") + word
            characterCount += word.count + 1
        }

        return shortName
    }
}
