import Foundation

class UserDefaultsManager {
    private static let key = "selectedAlbums"
    private static let idKey = "selectedAlbumIDs" // ✅ Store album IDs

    static func getSavedAlbums() -> [String] {
        let albums = UserDefaults.standard.array(forKey: key) as? [String] ?? Array(repeating: "No Album Selected", count: 4)
        Logger.log("💾 Retrieved Albums from UserDefaults: \(albums)") // Added Log
        return albums
    }

    static func getSavedAlbumIDs() -> [String] {
        let ids = UserDefaults.standard.array(forKey: idKey) as? [String] ?? Array(repeating: "", count: 4)
        Logger.log("💾 Retrieved Album IDs from UserDefaults: \(ids)") // Added Log
        return ids
    }

    static func getAlbumID(at index: Int) -> String? {
        let albumIDs = getSavedAlbumIDs()

        if index >= 0 && index < albumIDs.count {
            let id = albumIDs[index].trimmingCharacters(in: .whitespacesAndNewlines)
            Logger.log("💾 Retrieved Album ID at index \(index): '\(id)'")
            return id.isEmpty ? nil : id // ✅ Return nil instead of empty string
        }

        Logger.log("⚠️ Invalid index \(index) for album ID retrieval")
        return nil
    }


    
    static func saveAlbum(_ album: String, at index: Int, albumID: String?) {
        var albums = getSavedAlbums()
        var albumIDs = getSavedAlbumIDs()

        if index >= 0 && index < 4 {
            let cleanAlbumID = albumID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" // ✅ Trim and handle nil safely

            albums[index] = album
            albumIDs[index] = cleanAlbumID

            UserDefaults.standard.set(albums, forKey: key)
            UserDefaults.standard.set(albumIDs, forKey: idKey)

            Logger.log("💾 Saving Album at index \(index): Name='\(album)', ID='\(cleanAlbumID)'")
        } else {
            Logger.log("⚠️ Attempted to save album at invalid index \(index)")
        }
    }


}
