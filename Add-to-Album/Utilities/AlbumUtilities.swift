import Photos

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
    


    static func fetchAlbums(completion: @escaping ([PHAssetCollection]) -> Void) {
        let fetchOptions = PHFetchOptions()
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        Logger.log("📸 fetchAlbums called")


        var fetchedAlbums: [PHAssetCollection] = []
        userAlbums.enumerateObjects { collection, _, _ in
            fetchedAlbums.append(collection)
        }

        DispatchQueue.main.async {
            Logger.log("📸 Albums Fetched: \(fetchedAlbums.count)")
            completion(fetchedAlbums)
            NotificationCenter.default.post(name: albumsUpdated, object: fetchedAlbums)
            
            // ✅ Call updateSelectedAlbums AFTER the fetch is complete
            PHPhotoLibrary.shared().performChanges { // Ensures the library is consistent
                Logger.log("📸 fetchAlbums calling updateSelectedAlbums")
                 self.updateSelectedAlbums(photoObserverAlbums: fetchedAlbums)
            } completionHandler: { success, error in
                if let error = error {
                    Logger.log("Error performing photo library changes: \(error)")
                } else {
                     Logger.log("Photo library changes completed.")
                }
            }
        }
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

        for (index, savedAlbumID) in savedAlbumIDs.enumerated() {
            if savedAlbumID.isEmpty { continue }
            Logger.log("🔄 Analysing: \(savedAlbumID) - \(currentAlbumMap[savedAlbumID])")

            if let updatedName = currentAlbumMap[savedAlbumID] {
                let currentSavedName = UserDefaultsManager.getSavedAlbumName(at: index)
                if currentSavedName != updatedName {
                    Logger.log("🔄 Album Renamed - Updating Entry \(index) to \(updatedName)")
                    UserDefaultsManager.saveAlbum(updatedName, at: index, albumID: savedAlbumID)
                } else {
                    Logger.log("🔄 Album name not changed: \(currentSavedName)")
                }
            } else {
                Logger.log("⚠️ Album ID '\(savedAlbumID)' at index \(index) no longer exists in the photo library.")
            }
        }
    }

    }
