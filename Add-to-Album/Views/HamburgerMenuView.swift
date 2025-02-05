import SwiftUI
import Photos

struct HamburgerMenuView: View {
    @StateObject private var photoObserver = PhotoLibraryObserver() // ✅ Use album observer
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
        .onAppear {
            updateSelectedAlbums() // ✅ Check if selected albums still exist
        }
        .onChange(of: photoObserver.albums) { _ in
            Logger.log("🔄 Album List Changed - Checking Selections")
            updateSelectedAlbums() // ✅ Update menu when albums change
        }

        .sheet(isPresented: $isAlbumPickerPresented) {
            if let index = selectedMenuIndex {
                AlbumPickerView(selectedAlbum: $selectedAlbums[index], albums: photoObserver.albums)
                    .onDisappear {
                        if let index = selectedMenuIndex {
                            UserDefaultsManager.saveAlbum(selectedAlbums[index], at: index)
                            Logger.log("💾 Saved Album: \(selectedAlbums[index]) at index \(index)")
                        }
                    }
                    .id(UUID()) // ✅ Force SwiftUI to recreate the modal
            }
        }

    }

    /// **Automatically Reset Deleted Albums to "No Album Selected"**
    private func updateSelectedAlbums() {
        for i in 0..<selectedAlbums.count {
            let savedAlbum = selectedAlbums[i]
            let albumExists = photoObserver.albums.contains { $0.localizedTitle == savedAlbum }
            if !albumExists {
                selectedAlbums[i] = "No Album Selected" // ✅ Reset deleted albums
                UserDefaultsManager.saveAlbum(selectedAlbums[i], at: i) // ✅ Persist change
                Logger.log("⚠️ Album Deleted - Resetting Entry \(i) to No Album Selected")
            }
        }
    }
    
}
