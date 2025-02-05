import SwiftUI
import Photos

struct HamburgerMenuView: View {
    @State private var selectedAlbums: [String] = UserDefaultsManager.getSavedAlbums()
    @State private var isAlbumPickerPresented = false
    @State private var selectedMenuIndex: Int? = nil // Track which menu item is selected
    @State private var albums: [PHAssetCollection] = [] // ✅ Preloaded albums
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
            NotificationCenter.default.addObserver(forName: AlbumUtilities.albumsUpdated, object: nil, queue: .main) { notification in // ADD THIS
                if let updatedAlbums = notification.object as? [PHAssetCollection] {
                    self.albums = updatedAlbums // Refresh albums
                    self.updateSelectedAlbums(updatedAlbums: updatedAlbums) // Update selectedAlbums
                }
            }
            Logger.log("📁 Loaded Saved Albums: \(selectedAlbums)")
        }
        .onDisappear { // Important: remove observer to prevent memory leak
            NotificationCenter.default.removeObserver(self, name: AlbumUtilities.albumsUpdated, object: nil) // Add object: nil

        }
        .sheet(isPresented: $isAlbumPickerPresented) {
            if let index = selectedMenuIndex, !albums.isEmpty {
                AlbumPickerView(selectedAlbum: $selectedAlbums[index])
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

    // Function to update selectedAlbums
    private func updateSelectedAlbums(updatedAlbums: [PHAssetCollection]) {
        for i in 0..<selectedAlbums.count {
            let savedAlbumName = selectedAlbums[i]
            let albumExists = updatedAlbums.contains(where: { $0.localizedTitle == savedAlbumName })
            if !albumExists {
                selectedAlbums[i] = "No Album Selected"
                UserDefaultsManager.saveAlbum("No Album Selected", at: i)
            }
        }
    }
    
}
