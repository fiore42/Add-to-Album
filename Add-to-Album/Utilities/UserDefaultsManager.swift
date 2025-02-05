import Foundation

class UserDefaultsManager {
    private static let key = "selectedAlbums"
    private static let idKey = "selectedAlbumIDs" // ✅ Store album IDs

    static func getSavedAlbums() -> [String] {
        if let saved = UserDefaults.standard.array(forKey: key) as? [String], saved.count == 4 {
            return saved
        }
        return Array(repeating: "No Album Selected", count: 4) // Default menu state
    }

    static func getSavedAlbumIDs() -> [String] {
        if let saved = UserDefaults.standard.array(forKey: idKey) as? [String], saved.count == 4 {
            return saved
        }
        return Array(repeating: "", count: 4) // Default empty IDs
    }

    static func getAlbumID(at index: Int) -> String? {
        let albumIDs = getSavedAlbumIDs()
        return albumIDs[index].isEmpty ? nil : albumIDs[index]
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
