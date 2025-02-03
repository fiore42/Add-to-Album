import SwiftUI
import PhotosUI

class AlbumAssociationManager: ObservableObject { // Make it ObservableObject
    @AppStorage("functionAlbumAssociations") private var functionAlbumAssociationsData: Data = Data()
    @Published var pairedAlbums: [String: PHAssetCollection?] = [:] {
        didSet { // Key change: didSet observer
            saveFunctionAlbumAssociations()
        }
    }

    init() {
        loadFunctionAlbumAssociations() // Load in init
    }

    private var functionAlbumAssociations: [String: String] { // Computed property
        get {
            guard let loadedAssociations = try? JSONDecoder().decode([String: String].self, from: functionAlbumAssociationsData) else { return [:] }
            return loadedAssociations
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                functionAlbumAssociationsData = encoded
            }
        }
    }

    func updatePairedAlbum(for function: String, with collection: PHAssetCollection?) {
        // Create a *new* dictionary with the change
        var newPairedAlbums = pairedAlbums
        newPairedAlbums[function] = collection
        pairedAlbums = newPairedAlbums // Assign the *new* dictionary (this will trigger the @Published update)
    }
    
    func loadFunctionAlbumAssociations() {
        let loadedAssociations = functionAlbumAssociations // Access computed property
        let fetchOptions = PHFetchOptions()
        for (function, localIdentifier) in loadedAssociations {
            let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: fetchOptions)
            if let collection = fetchResult.firstObject {
                pairedAlbums[function] = collection
            }
        }
    }

    func checkAlbumExistence() {
        var albumsToRemove: [String] = []

        for (function, collection) in pairedAlbums {
            guard let collection = collection else {
                albumsToRemove.append(function)
                continue
            }

            let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [collection.localIdentifier], options: nil)
            if fetchResult.firstObject == nil { // Check for *nil* to remove
                albumsToRemove.append(function)
            }
        }

        for function in albumsToRemove {
            pairedAlbums.removeValue(forKey: function)
        }
        // pairedAlbums' didSet will handle saving
    }

    func saveFunctionAlbumAssociations() {
        functionAlbumAssociations = pairedAlbums.compactMapValues { $0?.localIdentifier }
    }
}
