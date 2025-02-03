import SwiftUI
import PhotosUI

class AlbumAssociationManager: ObservableObject {
    @AppStorage("functionAlbumAssociations") private var functionAlbumAssociationsData: Data = Data()
    @Published var pairedAlbums: [String: PHAssetCollection?] = [:] {
        didSet {
            saveFunctionAlbumAssociations()
        }
    }
    
    private var functionAlbumIDs: [String: String] {
        get {
            guard let loaded = try? JSONDecoder().decode([String: String].self, from: functionAlbumAssociationsData) else {
                return [:]
            }
            return loaded
        }
        set {
            guard let encoded = try? JSONEncoder().encode(newValue) else { return }
            functionAlbumAssociationsData = encoded
        }
    }
    
    init() {
        loadFunctionAlbumAssociations()
    }
    
    func loadFunctionAlbumAssociations() {
        print("🗄 Loading saved function-album associations from AppStorage...")
        let savedMap = functionAlbumIDs
        let fetchOptions = PHFetchOptions()
        pairedAlbums = [:]
        
        for (function, localIdentifier) in savedMap {
            let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: fetchOptions)
            if let firstAlbum = result.firstObject {
                pairedAlbums[function] = firstAlbum
            } else {
                pairedAlbums[function] = nil
            }
        }
    }
    
    func saveFunctionAlbumAssociations() {
        print("💾 Saving function-album associations to AppStorage...")
        let mapToSave = pairedAlbums.compactMapValues { $0?.localIdentifier }
        functionAlbumIDs = mapToSave
    }
    
    func updatePairedAlbum(for function: String, with collection: PHAssetCollection?) {
        pairedAlbums[function] = collection
    }
    
    func checkAlbumExistence() {
        print("🔍 Checking if any paired album has been removed...")
        var toRemove: [String] = []
        for (function, collection) in pairedAlbums {
            guard let collection = collection else {
                toRemove.append(function)
                continue
            }
            let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [collection.localIdentifier], options: nil)
            if result.count == 0 {
                toRemove.append(function)
            }
        }
        for f in toRemove {
            pairedAlbums.removeValue(forKey: f)
        }
    }
}
