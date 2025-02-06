import Foundation
import SwiftUI
import Photos
import Combine

class AlbumSelectionViewModel: ObservableObject {
    @ObservedObject var albumManager = AlbumManager()

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
    
    func updateSelectedAlbums(photoObserverAlbums: [PHAssetCollection]) {
        Logger.log("📂 Checking album state: \(photoObserverAlbums.count) albums found")
        
        if photoObserverAlbums.isEmpty {
            let hasSavedAlbums = UserDefaultsManager.getSavedAlbumIDs().contains { !$0.isEmpty }
            if hasSavedAlbums {
                Logger.log("⏳ Photo library may still be loading - Deferring updateSelectedAlbums")
                return
            } else {
                Logger.log("⚠️ No albums exist in the photo library - Proceeding with updateSelectedAlbums")
            }
        }
        
        let savedAlbumIDs = UserDefaultsManager.getSavedAlbumIDs().map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Create album map including Favorites
        var allAlbums: [PHAssetCollection] = photoObserverAlbums // Start with regular albums

        if let favoritesAlbum = self.albumManager.fetchFavoritesAlbum() {  // Use self.albumManager!
            allAlbums.append(favoritesAlbum)
        }

        let currentAlbumMap: [String: String] = Dictionary(uniqueKeysWithValues:
                                                            allAlbums.map { ($0.localIdentifier.trimmingCharacters(in: .whitespacesAndNewlines), $0.localizedTitle ?? "Unknown Album") }
        )
        

        var hasChanges = false // ✅ Track changes to trigger UI update
        
        
        for (index, savedAlbumID) in savedAlbumIDs.enumerated() {
            if savedAlbumID.isEmpty { continue }
//            Logger.log("🔄 Analysing: \(savedAlbumID) - \(currentAlbumMap[savedAlbumID])")
            
            if let updatedName = currentAlbumMap[savedAlbumID] {
                let currentSavedName = UserDefaultsManager.getSavedAlbumName(at: index)
                Logger.log("🔄 Analysing index: \(index) updatedName: \(updatedName) currentSavedName: \(currentSavedName)")
                if currentSavedName != updatedName {
                    Logger.log("🔄 Album Renamed - Updating Entry \(index) to \(updatedName) id \(savedAlbumID)")
                    UserDefaultsManager.saveAlbum(updatedName, at: index, albumID: savedAlbumID)
                    hasChanges = true // ✅ Track changes to trigger UI update
                    
                } else {
                    Logger.log("🔄 Album name not changed: \(currentSavedName)")
                }
            } else {
                Logger.log("⚠️ Album ID '\(savedAlbumID)' at index \(index) no longer exists in the photo library.")
                UserDefaultsManager.saveAlbum("", at: index, albumID: "")
                hasChanges = true // ✅ Track changes to trigger UI update
                
                
            }
        }
        
        // ✅ Notify UI to refresh only if there were changes
        if hasChanges {
            Logger.log("🔄 Notifying UI: Album List Updated")
            NotificationCenter.default.post(name: .albumListUpdated, object: nil)
        }
        
        
    }
}
