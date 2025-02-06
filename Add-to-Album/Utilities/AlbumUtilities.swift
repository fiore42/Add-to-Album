import Photos
import Foundation

extension Notification.Name {
    //Notify the hamburger menu of changes in the album titles
    static let albumListUpdated = Notification.Name("AlbumListUpdated") // ✅ Notify UI
}

struct AlbumUtilities {
    
    static func formatAlbumName(_ name: String) -> String {
        let words = name.split(separator: " ")
        var shortName = ""
        var characterCount = 0
        
        if let firstWord = words.first, firstWord.count > 14 {
            return String(firstWord.prefix(12)) + "..."
        }
        
        for word in words {
            if characterCount + word.count + (shortName.isEmpty ? 0 : 1) > 14 {
                break
            }
            shortName += (shortName.isEmpty ? "" : " ") + word
            characterCount += word.count + 1
        }
        
        return shortName
    }
    
    
    
    static let albumsUpdated = Notification.Name("AlbumsUpdated")
    
    
}
