import Foundation

class UserDefaultsManager {
    private static let key = "selectedAlbums"

    static func getSavedAlbums() -> [String] {
        if let saved = UserDefaults.standard.array(forKey: key) as? [String], saved.count == 4 {
            return saved
        }
        return Array(repeating: "No Album Selected", count: 4) // Default menu state
    }

    static func saveAlbum(_ album: String, at index: Int) {
        var albums = getSavedAlbums()
        albums[index] = album
        UserDefaults.standard.set(albums, forKey: key)
        Logger.log("💾 UserDefaults Updated: \(albums)")
    }
}
