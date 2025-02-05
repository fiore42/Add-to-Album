import Photos

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
    


        static func fetchAlbums(completion: @escaping ([PHAssetCollection]) -> Void) {
            let fetchOptions = PHFetchOptions()
            let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

            var fetchedAlbums: [PHAssetCollection] = []
            userAlbums.enumerateObjects { collection, _, _ in
                fetchedAlbums.append(collection)
            }

            DispatchQueue.main.async {
                Logger.log("📸 Albums Fetched: \(fetchedAlbums.count)")
                completion(fetchedAlbums) // Call completion with fetched albums
            }
        }
                

}
