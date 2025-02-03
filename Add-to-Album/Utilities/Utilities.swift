// ✅ Truncates an album name to a maximum length, ensuring words are not cut off randomly.
func truncateAlbumName(_ name: String, maxLength: Int) -> String {
    if name.count <= maxLength {
        return name
    }
    
    let words = name.split(separator: " ")
    var truncatedName = ""

    for word in words {
        if (truncatedName.count + word.count + 1) > maxLength {
            break
        }
        truncatedName += (truncatedName.isEmpty ? "" : " ") + word
    }
    
    return truncatedName
}
