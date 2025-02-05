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
                    Logger.log("📂 [HamburgerMenuView] Opening Album Picker for index \(index)")
                    selectedMenuIndex = index
                    isAlbumPickerPresented = true
                }) {
                    Label {
                        Text(selectedAlbums[index].isEmpty ? "⛔️ No Album Selected" : AlbumUtilities.formatAlbumName(selectedAlbums[index]))
                            .foregroundColor(selectedAlbums[index].isEmpty ? .red : .primary)
                    } icon: {
                        Image(systemName: "photo") // Optional album icon
                    }
                }
                .buttonStyle(PlainButtonStyle()) // Ensures the default button style doesn’t override text color
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .resizable()
                .frame(width: 24, height: 20)
                .foregroundColor(.white)
        }
        .onAppear {
            Logger.log("📸 HamburgerMenuView onAppear triggered")
            Logger.log("📂 Initial Selected Albums: \(selectedAlbums)")
            
//            Logger.log("📸 HamburgerMenuView onAppear calling updateSelectedAlbums")
//            AlbumUtilities.updateSelectedAlbums(photoObserverAlbums: photoObserver.albums)
            NotificationCenter.default.addObserver(
                forName: .albumListUpdated,
                object: nil,
                queue: .main
            ) { _ in
                Logger.log("🔄 UI Refresh: Reloading albums in Hamburger Menu")
                self.selectedAlbums = UserDefaultsManager.getSavedAlbums()
                Logger.log("📂 Updated Selected Albums: \(self.selectedAlbums)")
            }
        }
        .onChange(of: photoObserver.albums) { oldValue, newValue in
            Logger.log("🔄 Album List Changed - Checking Selections")
            Logger.log("📸 HamburgerMenuView onChange calling updateSelectedAlbums")
            Logger.log("📂 Old Albums Count: \(oldValue.count), New Albums Count: \(newValue.count)")
            AlbumUtilities.updateSelectedAlbums(photoObserverAlbums: photoObserver.albums)

        }


        .sheet(isPresented: $isAlbumPickerPresented) {
            if let index = selectedMenuIndex {
                AlbumPickerView(selectedAlbum: $selectedAlbums[index], albums: photoObserver.albums, index: index)
                    .onDisappear {
                        Logger.log("📂 Album Picker Closed. Selected Album: \(selectedAlbums[index]) at index \(index)")
                        if let index = selectedMenuIndex {
                            let albumID = UserDefaultsManager.getAlbumID(at: index) // Use the existing function!
                            UserDefaultsManager.saveAlbum(selectedAlbums[index], at: index, albumID: albumID ?? "")
                            Logger.log("💾 Saved Album: \(selectedAlbums[index]) at index \(index), ID: \(albumID ?? "nil")")
                        }
                    }
                    .id(UUID())
            }
        }

    }

    
}
