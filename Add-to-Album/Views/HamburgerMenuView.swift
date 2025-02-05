import SwiftUI
import Photos

struct HamburgerMenuView: View {
    @State private var selectedAlbums: [String] = UserDefaultsManager.getSavedAlbums()
    @State private var isAlbumPickerPresented = false
    @State private var selectedMenuIndex: Int? = nil // Track which menu item is selected
    @State private var albums: [PHAssetCollection] = [] // ✅ Preloaded albums

    var body: some View {
        HStack {
            Spacer() // Pushes the menu to the right

            Menu {
                ForEach(0..<4, id: \.self) { index in
                    Button(action: {
                        selectedMenuIndex = index
                        isAlbumPickerPresented = true
                    }) {
                        Text(selectedAlbums[index])
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .frame(width: 30, height: 25)
                    .foregroundColor(.white) // Make the icon white
                    .padding()
            }
            .task {
                fetchAlbums() // ✅ Preload albums when menu appears
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing) // Ensure it's aligned right
        .sheet(isPresented: $isAlbumPickerPresented) {
            if let index = selectedMenuIndex {
                AlbumPickerView(selectedAlbum: $selectedAlbums[index])
            }
        }
    }
    
    private func fetchAlbums() {
        let fetchOptions = PHFetchOptions()
        let userAlbums: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        var fetchedAlbums: [PHAssetCollection] = []
        userAlbums.enumerateObjects { collection, _, _ in
            fetchedAlbums.append(collection)
        }

        DispatchQueue.main.async {
            self.albums = fetchedAlbums
            Logger.log("📸 Albums Preloaded: \(self.albums.count)")
        }
    }
}

