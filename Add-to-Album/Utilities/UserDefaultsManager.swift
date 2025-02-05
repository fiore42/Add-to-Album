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
    
    static func getSavedAlbumName(at index: Int) -> String {
        let savedAlbumNames = UserDefaults.standard.array(forKey: "savedAlbumNames") as? [String] ?? []
        return (index < savedAlbumNames.count) ? savedAlbumNames[index] : "No Album Selected"
    }


    static func saveAlbum(_ name: String, at index: Int, albumID: String) {
        var savedAlbumIDs = UserDefaults.standard.array(forKey: "savedAlbumIDs") as? [String] ?? []
        var savedAlbumNames = UserDefaults.standard.array(forKey: "savedAlbumNames") as? [String] ?? []

        // Ensure the arrays have enough space
        while savedAlbumIDs.count <= index { savedAlbumIDs.append("") }
        while savedAlbumNames.count <= index { savedAlbumNames.append("No Album Selected") }

        // Update values
        savedAlbumIDs[index] = albumID
        savedAlbumNames[index] = name

        // Save back to UserDefaults
        UserDefaults.standard.set(savedAlbumIDs, forKey: "savedAlbumIDs")
        UserDefaults.standard.set(savedAlbumNames, forKey: "savedAlbumNames")

        Logger.log("💾 Saved Album: \(name) at index \(index)")
    }



}
