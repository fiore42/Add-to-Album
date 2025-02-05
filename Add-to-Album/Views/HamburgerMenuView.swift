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
        .onChange(of: photoObserver.albums) { oldValue, newValue in
            Logger.log("🔄 Album List Changed - Checking Selections")
            updateSelectedAlbums() // ✅ Update menu when albums change
        }

        .sheet(isPresented: $isAlbumPickerPresented) {
            if let index = selectedMenuIndex {
                AlbumPickerView(selectedAlbum: $selectedAlbums[index], albums: photoObserver.albums, index: index) // ✅ Pass index
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

    // **Automatically Reset Deleted Albums to "No Album Selected"**
    private func updateSelectedAlbums() {
        let currentAlbumIDs = Set(photoObserver.albums.map { $0.localIdentifier }) // ✅ Store existing album IDs

        for i in 0..<selectedAlbums.count {
            // Retrieve the stored album's unique ID
            if let savedAlbumID = UserDefaultsManager.getAlbumID(at: i) {
                let albumStillExists = currentAlbumIDs.contains(savedAlbumID) // ✅ Check by unique ID
                if !albumStillExists {
                    selectedAlbums[i] = "No Album Selected" // ✅ Reset deleted albums
                    UserDefaultsManager.saveAlbum(selectedAlbums[i], at: i)
                    Logger.log("⚠️ Album Deleted - Resetting Entry \(i) to No Album Selected")
                }
            }
        }
    }


    
}
