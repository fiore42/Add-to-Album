import SwiftUI
import Photos

struct HamburgerMenuView: View {
    @State private var selectedAlbums: [String] = UserDefaultsManager.getSavedAlbums()
    @State private var isAlbumPickerPresented = false
    @State private var selectedMenuIndex: Int? = nil // Track which menu item is selected
    @State private var albums: [PHAssetCollection] = [] // ✅ Preloaded albums

    var body: some View {
        Menu {
            ForEach(0..<4, id: \.self) { index in
                Button(action: {
                    selectedMenuIndex = index
                    isAlbumPickerPresented = true
                    Logger.log("📂 Menu Item \(index) Tapped. Albums Count: \(albums.count)")
                }) {
                    Text(selectedAlbums[index])
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .resizable()
                .frame(width: 24, height: 20)
                .foregroundColor(.white)
        }
        .onChange(of: isAlbumPickerPresented) { oldValue, newValue in
            Logger.log("🔄 isAlbumPickerPresented changed: \(newValue)")
        }
        .onAppear {
            fetchAlbums() // ✅ Preload albums when menu appears
        }
        .sheet(isPresented: $isAlbumPickerPresented) {
            if let index = selectedMenuIndex, !albums.isEmpty {
//                Logger.log("📂 Opening AlbumPickerView for index \(index). Passing Albums Count: \(albums.count)")
                AlbumPickerView(selectedAlbum: $selectedAlbums[index], albums: albums)
                    .id(UUID()) // ✅ Force SwiftUI to create a new instance every time
//            } else {
//                Logger.log("⚠️ Prevented Opening AlbumPickerView - Albums Not Loaded!")
            }
        }

    }

    private func fetchAlbums() {
        let fetchOptions = PHFetchOptions()
        let userAlbums: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(
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
            Logger.log("📸 Albums Preloaded in HamburgerMenuView: \(self.albums.count)")
        }
    }
}
