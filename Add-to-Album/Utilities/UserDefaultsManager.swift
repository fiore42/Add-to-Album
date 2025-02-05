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
            let id = albumIDs[index]
            Logger.log("💾 Retrieved Album ID at index \(index): '\(id)'") // ✅ Confirm retrieval format
            return id.isEmpty ? nil : id
        }

        Logger.log("⚠️ Invalid index \(index) for album ID retrieval")
        return nil
    }


    
    static func saveAlbum(_ album: String, at index: Int, albumID: String = "") {
        var albums = getSavedAlbums()
        var albumIDs = getSavedAlbumIDs()

        if index >= 0 && index < 4 {
            albums[index] = album
            albumIDs[index] = albumID

            UserDefaults.standard.set(albums, forKey: key)
            UserDefaults.standard.set(albumIDs, forKey: idKey)

            Logger.log("💾 Saving Album at index \(index): Name='\(album)', ID='\(albumID)'") // ✅ Confirm what's stored
        } else {
            Logger.log("⚠️ Attempted to save album at invalid index \(index)")
        }
    }

}
