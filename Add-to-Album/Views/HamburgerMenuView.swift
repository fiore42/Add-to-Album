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
                AlbumPickerView(selectedAlbum: $selectedAlbums[index], albums: photoObserver.albums, index: index)
                    .onDisappear {
                        if let index = selectedMenuIndex {
                            let albumID = UserDefaultsManager.getAlbumID(at: index) // Use the existing function!
                            UserDefaultsManager.saveAlbum(selectedAlbums[index], at: index, albumID: albumID ?? "")
                            Logger.log("💾 Saved Album: \(selectedAlbums[index]) at index \(index)")
                        }
                    }
                    .id(UUID())
            }
        }

    }

    // **Automatically Reset Deleted Albums to "No Album Selected"**
    private func updateSelectedAlbums() {
        Logger.log("📂 Checking album state: \(photoObserver.albums.count) albums found")

        // ✅ If albums haven't loaded, defer the check
        if photoObserver.albums.isEmpty {
            let hasSavedAlbums = UserDefaultsManager.getSavedAlbumIDs().contains { !$0.isEmpty }
            if hasSavedAlbums {
                Logger.log("⏳ Photo library may still be loading - Deferring updateSelectedAlbums")
                return
            } else {
                Logger.log("⚠️ No albums exist in the photo library - Proceeding with updateSelectedAlbums")
            }
        }

        // ✅ Retrieve ALL saved album IDs once
        let savedAlbumIDs = UserDefaultsManager.getSavedAlbumIDs().map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let currentAlbumIDs = Set(photoObserver.albums.map { $0.localIdentifier.trimmingCharacters(in: .whitespacesAndNewlines) })

        Logger.log("📂 All Current Album IDs: \(currentAlbumIDs)")
        Logger.log("💾 All Saved Album IDs: \(savedAlbumIDs)")

        // ✅ Loop through selected albums efficiently
        for (index, savedAlbumID) in savedAlbumIDs.enumerated() {
            if savedAlbumID.isEmpty { continue }  // Skip empty entries

            Logger.log("🔎 Checking ID at index \(index): '\(savedAlbumID)' VS Current Album IDs: \(currentAlbumIDs)")

            let albumStillExists = currentAlbumIDs.contains(savedAlbumID)

            Logger.log("✅ Album at index \(index) exists in photo library: \(albumStillExists)")

            if !albumStillExists {
                selectedAlbums[index] = "No Album Selected"
                UserDefaultsManager.saveAlbum(selectedAlbums[index], at: index, albumID: "")
                Logger.log("⚠️ Album Deleted - Resetting Entry \(index) to No Album Selected")
            }
        }
    }










    
}
