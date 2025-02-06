import Foundation
import Combine

class AlbumSelectionViewModel: ObservableObject {
    @Published var selectedAlbums: [String] = UserDefaultsManager.getSavedAlbums()
    @Published var selectedAlbumIDs: [String] = UserDefaultsManager.getSavedAlbumIDs()

    private var cancellables: Set<AnyCancellable> = []

    init() {
        NotificationCenter.default.publisher(for: .albumSelectionUpdated)
            .sink { [weak self] _ in
                Logger.log("🔄 [AlbumSelectionViewModel] Detected update, refreshing albums")
                self?.selectedAlbums = UserDefaultsManager.getSavedAlbums()
                self?.selectedAlbumIDs = UserDefaultsManager.getSavedAlbumIDs()
            }
            .store(in: &cancellables)
    }
}
