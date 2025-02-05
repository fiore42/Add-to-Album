import Photos

class AlbumManager: ObservableObject {
    func isPhotoInAlbum(photoID: String, albumID: String) -> Bool {
        // Dummy check: Replace with actual PhotoKit logic
        return UserDefaults.standard.bool(forKey: "\(albumID)_\(photoID)")
    }

    func togglePhotoInAlbum(photoID: String, albumID: String) {
        let key = "\(albumID)_\(photoID)"
        let currentState = UserDefaults.standard.bool(forKey: key)
        UserDefaults.standard.set(!currentState, forKey: key)

        Logger.log("📂 \(photoID) now \(currentState ? "removed from" : "added to") \(albumID)")
    }
}
