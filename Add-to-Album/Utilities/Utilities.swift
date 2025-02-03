import Foundation

func truncateAlbumName(_ name: String, maxLength: Int) -> String {
    if name.count <= maxLength {
        return name
    }
    let words = name.split(separator: " ")
    var truncated = ""
    for w in words {
        if truncated.count + w.count + 1 > maxLength {
            break
        }
        truncated += (truncated.isEmpty ? "" : " ") + w
    }
    return truncated
}
