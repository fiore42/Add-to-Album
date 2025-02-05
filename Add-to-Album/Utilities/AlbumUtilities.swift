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

        var fetchedAlbums: [PHAssetCollection] = []
        userAlbums.enumerateObjects { collection, _, _ in
            fetchedAlbums.append(collection)
        }

        DispatchQueue.main.async {
            Logger.log("📸 Albums Fetched: \(fetchedAlbums.count)")
            completion(fetchedAlbums)
            NotificationCenter.default.post(name: albumsUpdated, object: fetchedAlbums)
            
            // ✅ Automatically update selected albums when fetching completes
            updateSelectedAlbums(photoObserverAlbums: fetchedAlbums)
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
            let currentAlbumIDs = Set(photoObserverAlbums.map { $0.localIdentifier.trimmingCharacters(in: .whitespacesAndNewlines) })

//            Logger.log("📂 All Current Album IDs: \(currentAlbumIDs)")
//            Logger.log("💾 All Saved Album IDs: \(savedAlbumIDs)")

            for (index, savedAlbumID) in savedAlbumIDs.enumerated() {
                if savedAlbumID.isEmpty { continue }

//                Logger.log("🔎 Checking ID at index \(index): '\(savedAlbumID)' VS Current Album IDs: \(currentAlbumIDs)")

                let albumStillExists = currentAlbumIDs.contains(savedAlbumID)

                Logger.log("✅ Album at index \(index) exists in photo library: \(albumStillExists)")

                if !albumStillExists {
                    let resetName = "No Album Selected"
                    UserDefaultsManager.saveAlbum(resetName, at: index, albumID: "")
                    Logger.log("⚠️ Album Deleted - Resetting Entry \(index) to \(resetName)")
                }
            }
        }
    }
