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
        let currentAlbumIDs = Set(photoObserver.albums.map {
            $0.localIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        })

        let savedAlbumIDs = UserDefaultsManager.getSavedAlbumIDs().map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // ✅ Log all album IDs along with type and length
        Logger.log("📂 All Current Album IDs: \(currentAlbumIDs.map { "\($0) (Type: \($0.debugDescription), Length: \($0.count))" })")

        Logger.log("💾 All Saved Album IDs: \(savedAlbumIDs.map { "\($0) (Type: \($0.debugDescription), Length: \($0.count))" })")

        for i in 0..<selectedAlbums.count {
            Logger.log("🔍 Checking Album at index \(i)")

            if let savedAlbumID = UserDefaultsManager.getAlbumID(at: i)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                Logger.log("💾 Retrieved Album ID at index \(i): '\(savedAlbumID)' (Type: \(type(of: savedAlbumID)), Length: \(savedAlbumID.count))")

                let albumStillExists = currentAlbumIDs.contains(where: {
                    $0.localizedStandardCompare(savedAlbumID) == .orderedSame
                })

                Logger.log("✅ Album at index \(i) exists in photo library: \(albumStillExists)")

                if !albumStillExists {
                    selectedAlbums[i] = "No Album Selected"
                    UserDefaultsManager.saveAlbum(selectedAlbums[i], at: i, albumID: "")
                    Logger.log("⚠️ Album Deleted - Resetting Entry \(i) to No Album Selected")
                } else {
                    Logger.log("✅ Album ID Matched: \(savedAlbumID)")
                }
            } else {
                Logger.log("⚠️ No saved Album ID at index \(i)")
            }
        }
    }






    
}
