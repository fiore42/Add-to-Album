import SwiftUI
import Photos

struct SelectedAlbumEntry: Identifiable {
    let id = UUID() // Ensures each selection is unique
    let index: Int  // The menu index (0-3)
}

struct HamburgerMenuView: View {
    @EnvironmentObject var albumSelectionViewModel: AlbumSelectionViewModel // ✅ Get shared ViewModel

//    @StateObject private var photoObserver = PhotoLibraryObserver() // ✅ Use album observer
    
    @StateObject var photoObserver: PhotoLibraryObserver // Initialize PhotoLibraryObserver


//    @State private var selectedAlbums: [String] = UserDefaultsManager.getSavedAlbums()
    @State private var selectedAlbumEntry: SelectedAlbumEntry? // ✅ Track selected album
//    @State private var albums: [PHAssetCollection] = [] // ✅ Preloaded albums
    
    // Use a dedicated init() to initialize photoObserver
    init() {
        _photoObserver = StateObject(wrappedValue: PhotoLibraryObserver()) // Initialize PhotoLibraryObserver WITHOUT albumSelectionViewModel
    }

    var body: some View {

        Menu {
            ForEach(0..<4, id: \.self) { index in
                Button(action: {
                    selectedAlbumEntry = SelectedAlbumEntry(index: index)
                    Logger.log("📂 [HamburgerMenuView] Opening Album Picker overlay for index \(index) id \(selectedAlbumEntry)")
                }) {
                    Label {
                        Text(albumSelectionViewModel.selectedAlbums[index].isEmpty ? Constants.noAlbumSelected : AlbumUtilities.formatAlbumName(albumSelectionViewModel.selectedAlbums[index]))
//                            .foregroundColor(albumSelectionViewModel.selectedAlbums[index].isEmpty ? .red : .primary)
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
            // ✅ Initialize `photoObserver` once `albumSelectionViewModel` is available
            if photoObserver.albumSelectionViewModel == nil {
                photoObserver.setAlbumSelectionViewModel(albumSelectionViewModel)
            }
            Logger.log("📂 Initial Selected Albums: \(albumSelectionViewModel.selectedAlbums)")
            // Remove existing observers before adding a new one to avoid duplicate triggers.
            NotificationCenter.default.removeObserver(self, name: .albumListUpdated, object: nil)
            

//            NotificationCenter.default.addObserver(
//                forName: .albumListUpdated,
//                object: nil,
//                queue: .main
//            ) { _ in
//                Logger.log("🔄 UI Refresh: Reloading albums in Hamburger Menu")
//                albumSelectionViewModel.selectedAlbums = UserDefaultsManager.getSavedAlbums()
//                Logger.log("📂 Updated Selected Albums: \(albumSelectionViewModel.selectedAlbums)")
//            }
        }
        .onChange(of: photoObserver.albums) { oldValue, newValue in
            // do not run if the value jumps from 0 to x, when x > 1
            guard oldValue != newValue, !(oldValue.count == 0 && newValue.count > 1) else { return }
            Logger.log("🔄 Album List Changed - Checking Selections")
            Logger.log("📸 HamburgerMenuView onChange calling updateSelectedAlbums")
            Logger.log("📂 Old Albums Count: \(oldValue.count), New Albums Count: \(newValue.count)")
            self.albumSelectionViewModel.updateSelectedAlbums(photoObserverAlbums: photoObserver.albums)

        }


        // ✅ Use .sheet(item:) to handle album picker
        .sheet(item: $selectedAlbumEntry, content: albumPickerSheet)


    }

    private func albumPickerSheet(for selectedEntry: SelectedAlbumEntry) -> some View {
        let index = selectedEntry.index
        let albumManager = AlbumManager()
        
        return AlbumPickerView(
            selectedAlbum: $albumSelectionViewModel.selectedAlbums[index],
            albums: photoObserver.albums,
            index: index,
            albumManager: albumManager
        )
        .onDisappear {
            Logger.log("📂 Album Picker Closed. Selected Album: \(albumSelectionViewModel.selectedAlbums[index]) at index \(index) ID: \(albumSelectionViewModel.selectedAlbumIDs[index])")
            let albumID = UserDefaultsManager.getAlbumID(at: index) ?? ""
            UserDefaultsManager.saveAlbum(albumSelectionViewModel.selectedAlbums[index], at: index, albumID: albumID)
            Logger.log("💾 [onDisappear] Saved Album: \"\(albumSelectionViewModel.selectedAlbums[index])\" at index \(index) with ID: \(albumSelectionViewModel.selectedAlbumIDs[index])")
            
        }
    }
    
}
