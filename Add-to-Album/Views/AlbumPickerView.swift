import SwiftUI
import Photos

struct AlbumPickerView: View {
    @Binding var selectedAlbum: String
    @Environment(\.dismiss) var dismiss
    @State private var albums: [PHAssetCollection] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Group { // Use a Group to handle loading state
                if isLoading {
                    ProgressView() // Show progress while loading
                } else {
                    List(albums, id: \.localIdentifier) { album in
                        Button(action: {
                            selectedAlbum = formatAlbumName(album.localizedTitle ?? "Unknown")
                            UserDefaultsManager.saveAlbums([selectedAlbum])
                            dismiss()
                        }) {
                            Text(album.localizedTitle ?? "Unknown")
                        }
                    }
                    .navigationTitle("Select Album")
                }
            }
            .onAppear(perform: fetchAlbums)
        }
    }

    private func fetchAlbums() {
        isLoading = true // Set loading to true *before* fetching

        let fetchOptions = PHFetchOptions()
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        var fetchedAlbums: [PHAssetCollection] = []
        userAlbums.enumerateObjects { collection, _, _ in
            fetchedAlbums.append(collection)
        }

        DispatchQueue.main.async {
            self.albums = fetchedAlbums // ✅ Updating in the main thread ensures UI refresh
            self.isLoading = false // Set loading to false *after* fetching and updating albums

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
