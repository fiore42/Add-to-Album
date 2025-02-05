import Foundation

class UserDefaultsManager {
    private static let key = "selectedAlbums"

    static func getSavedAlbums() -> [String] {
        if let saved = UserDefaults.standard.array(forKey: key) as? [String], saved.count == 4 {
            return saved
        }
        return Array(repeating: "No Album Selected", count: 4)
    }

    static func saveAlbums(_ albums: [String]) {
        UserDefaults.standard.set(albums, forKey: key)
    }
}
