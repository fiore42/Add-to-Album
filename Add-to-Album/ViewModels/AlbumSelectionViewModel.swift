import SwiftUI

class AlbumSelectionViewModel: ObservableObject {
    @Published var selectedAlbums: [String] = UserDefaultsManager.getSavedAlbums()
    @Published var selectedAlbumIDs: [String] = UserDefaultsManager.getSavedAlbumIDs()
}
