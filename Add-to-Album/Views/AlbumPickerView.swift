import SwiftUI
import Photos

struct AlbumPickerView: View {
    @Binding var selectedAlbum: String
    @Environment(\.dismiss) var dismiss
    @State private var albums: [PHAssetCollection] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView() // Show progress while loading
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1)) // Optional UI improvement
                    
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
        }
        .onAppear {
//moved to task
        }
        .task { // Use task instead of onAppear + if condition
            if albums.isEmpty {
                fetchAlbums()
            }
        }
        
    }


    private func fetchAlbums() {
        DispatchQueue.main.async {
            self.isLoading = true // ✅ Ensures UI shows progress before fetching starts
        }

        let fetchOptions = PHFetchOptions()
        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: fetchOptions
        )

        var fetchedAlbums: [PHAssetCollection] = []
        userAlbums.enumerateObjects { collection, _, _ in
            fetchedAlbums.append(collection)
        }

        DispatchQueue.main.async {
                self.albums = fetchedAlbums
                self.isLoading = false
                print("📸 Albums Loaded: \(self.albums.count)") // Debugging

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
