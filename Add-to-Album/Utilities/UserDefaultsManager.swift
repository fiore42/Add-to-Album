import Foundation

class UserDefaultsManager {
    private static let idKey = "savedAlbumIDs" // ✅ Store album IDs
    private static let key = "savedAlbumNames"

    static func getSavedAlbums() -> [String] {
        let albums = UserDefaults.standard.array(forKey: key) as? [String] ?? Array(repeating: "", count: 4)
        Logger.log("💾 [UserDefaults] Retrieved Albums: \(albums)") // Added Log
        return albums
    }


    static func getSavedAlbumIDs() -> [String] {
        let savedAlbumIDs = UserDefaults.standard.array(forKey: idKey) as? [String] ?? []
        Logger.log("💾 [UserDefaults] Retrieved Album IDs: \(savedAlbumIDs)")
        return savedAlbumIDs
    }


    static func getAlbumID(at index: Int) -> String? {
        let albumIDs = getSavedAlbumIDs()

        if index >= 0 && index < albumIDs.count {
            let id = albumIDs[index].trimmingCharacters(in: .whitespacesAndNewlines)
            Logger.log("💾 [UserDefaults] Retrieved Album ID at index \(index): '\(id)'")
            return id.isEmpty ? nil : id // ✅ Return nil instead of empty string
        }

        Logger.log("⚠️ [UserDefaults] Invalid index \(index) for album ID retrieval")
        return nil
    }
    
    static func getSavedAlbumName(at index: Int) -> String {

        let albums = UserDefaults.standard.array(forKey: key) as? [String] ?? Array(repeating: "", count: 4)

        let savedAlbumNames = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        Logger.log("❤️‍🔥 [UserDefaults] found name: \(savedAlbumNames[index]) for index: \(index)")

        return (index < savedAlbumNames.count) ? savedAlbumNames[index] : ""
    }


    static func saveAlbum(_ name: String, at index: Int, albumID: String) {
        var savedAlbumIDs = UserDefaults.standard.array(forKey: idKey) as? [String] ?? []
        var savedAlbumNames = UserDefaults.standard.array(forKey: key) as? [String] ?? []

        // Ensure the arrays have enough space
        while savedAlbumIDs.count <= index { savedAlbumIDs.append("") }
        while savedAlbumNames.count <= index { savedAlbumNames.append("") }

        // Log before saving
        Logger.log("💾 [UserDefaults] Before Saving: Name='\(name)', ID='\(albumID)', Index=\(index)")

        if albumID.isEmpty {
            Logger.log("⚠️ [UserDefaults] Attempted to save album with empty ID at index \(index). AKA deleting!")
        }
        savedAlbumIDs[index] = albumID
        savedAlbumNames[index] = name
        

        // Save back to UserDefaults
        UserDefaults.standard.set(savedAlbumIDs, forKey: idKey)
        UserDefaults.standard.set(savedAlbumNames, forKey: key)

        Logger.log("💾 [UserDefaults] Saved Album: \(name) at index \(index) with ID: \(albumID)")
    }




}
