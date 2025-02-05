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
        let id = albumIDs[index].isEmpty ? nil : albumIDs[index]
        Logger.log("💾 Retrieved Album ID at index \(index): \(id ?? "nil")") // Added Log
        return id
    }

    
    static func saveAlbum(_ album: String, at index: Int, albumID: String = "") {
            var albums = getSavedAlbums()
            albums[index] = album
            UserDefaults.standard.set(albums, forKey: key)

            var albumIDs = getSavedAlbumIDs()
            albumIDs[index] = albumID // ✅ Save album ID as a String
            UserDefaults.standard.set(albumIDs, forKey: idKey)

            Logger.log("💾 UserDefaults Updated: \(albums) with IDs: \(albumIDs)")
        }

}
