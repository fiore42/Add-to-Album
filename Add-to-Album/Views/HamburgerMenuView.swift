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
            AlbumUtilities.fetchAlbums { fetchedAlbums in // Provide the closure here
                withAnimation { // If you want animation
                    self.albums = fetchedAlbums // Update your local albums array
                }
            }
            Logger.log("📁 Loaded Saved Albums: \(selectedAlbums)")
        }
        .sheet(isPresented: $isAlbumPickerPresented) {
            if let index = selectedMenuIndex, !albums.isEmpty {
                AlbumPickerView(selectedAlbum: $selectedAlbums[index])
//                AlbumPickerView(selectedAlbum: $selectedAlbums[index], albums: albums)
                    .onDisappear {
                        if let index = selectedMenuIndex {
                            UserDefaultsManager.saveAlbum(selectedAlbums[index], at: index)
                            Logger.log("💾 Saved Album: \(selectedAlbums[index]) at index \(index)")
                        }
                    }
                    .id(UUID()) // ✅ Force SwiftUI to create a new instance every time
            }
        }

    }

}
