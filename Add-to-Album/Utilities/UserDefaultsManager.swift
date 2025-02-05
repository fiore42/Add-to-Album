import Foundation

class UserDefaultsManager {
    private static let idKey = "savedAlbumIDs" // ✅ Store album IDs
    private static let key = "savedAlbumNames"

    static func getSavedAlbums() -> [String] {
        let albums = UserDefaults.standard.array(forKey: key) as? [String] ?? Array(repeating: "No Album Selected", count: 4)
        Logger.log("💾 Retrieved Albums from UserDefaults: \(albums)") // Added Log
        return albums
    }


    static func getSavedAlbumIDs() -> [String] {
        let savedAlbumIDs = UserDefaults.standard.array(forKey: idKey) as? [String] ?? []
        Logger.log("💾 DEBUG: Retrieved Album IDs from UserDefaults: \(savedAlbumIDs)")
        return savedAlbumIDs
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

        let albums = UserDefaults.standard.array(forKey: key) as? [String] ?? Array(repeating: "No Album Selected", count: 4)

        let savedAlbumNames = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        Logger.log("❤️‍🔥 albums: \(albums) savedAlbumNames: \(savedAlbumNames)")

        return (index < savedAlbumNames.count) ? savedAlbumNames[index] : "No Album Selected"
    }


    static func saveAlbum(_ name: String, at index: Int, albumID: String) {
        var savedAlbumIDs = UserDefaults.standard.array(forKey: idKey) as? [String] ?? []
        var savedAlbumNames = UserDefaults.standard.array(forKey: key) as? [String] ?? []

        // Ensure the arrays have enough space
        while savedAlbumIDs.count <= index { savedAlbumIDs.append("") }
        while savedAlbumNames.count <= index { savedAlbumNames.append("No Album Selected") }

        // Log before saving
        Logger.log("💾 Before Saving: Name='\(name)', ID='\(albumID)', Index=\(index)")

        if albumID.isEmpty {
            Logger.log("⚠️ Attempted to save album with empty ID at index \(index). AKA deleting!")
        }
        savedAlbumIDs[index] = albumID
        savedAlbumNames[index] = name
        

        // Save back to UserDefaults
        UserDefaults.standard.set(savedAlbumIDs, forKey: idKey)
        UserDefaults.standard.set(savedAlbumNames, forKey: key)

        Logger.log("💾 Saved Album: \(name) at index \(index) with ID: \(albumID)")
    }




}
