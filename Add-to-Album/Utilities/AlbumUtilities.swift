import Photos
import Foundation

extension Notification.Name {
    //Notify the hamburger menu of changes in the album titles
    static let albumListUpdated = Notification.Name("AlbumListUpdated") // ✅ Notify UI
}

struct AlbumUtilities {
    
    static func formatAlbumName(_ name: String) -> String {
        let words = name.split(separator: " ")
        var shortName = ""
        var characterCount = 0
        
        if let firstWord = words.first, firstWord.count > 14 {
            return String(firstWord.prefix(12)) + "..."
        }
        
        for word in words {
            if characterCount + word.count + (shortName.isEmpty ? 0 : 1) > 14 {
                break
            }
            shortName += (shortName.isEmpty ? "" : " ") + word
            characterCount += word.count + 1
        }
        
        return shortName
    }
    
    
    
    static let albumsUpdated = Notification.Name("AlbumsUpdated")
    
    static func updateSelectedAlbums(photoObserverAlbums: [PHAssetCollection]) {
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
        
        // Create a mapping of album ID to current album name
        let currentAlbumMap: [String: String] = Dictionary(uniqueKeysWithValues:
                                                            photoObserverAlbums.map { ($0.localIdentifier.trimmingCharacters(in: .whitespacesAndNewlines), $0.localizedTitle ?? "Unknown Album") }
        )
        
        var hasChanges = false // ✅ Track changes to trigger UI update
        
        
        for (index, savedAlbumID) in savedAlbumIDs.enumerated() {
            if savedAlbumID.isEmpty { continue }
            Logger.log("🔄 Analysing: \(savedAlbumID) - \(currentAlbumMap[savedAlbumID])")
            
            if let updatedName = currentAlbumMap[savedAlbumID] {
                let currentSavedName = UserDefaultsManager.getSavedAlbumName(at: index)
                Logger.log("🔄 Analysing index: \(index) updatedName: \(updatedName) currentSavedName: \(currentSavedName)")
                if currentSavedName != updatedName {
                    Logger.log("🔄 Album Renamed - Updating Entry \(index) to \(updatedName)")
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
