import SwiftUI
import Photos

class PhotoViewModel: ObservableObject {
    let albumManager = AlbumAssociationManager()
    
    private(set) var allAssets: [PHAsset] = []
    @Published var displayedAssets: [PHAsset] = []
    @Published var userAlbums: [PHAssetCollection] = []
    
    private var isFetching = false
    private let batchSize = 30
    
    // MARK: - Load All Assets
    func loadAllAssetsIfNeeded() {
        if !allAssets.isEmpty {
            print("🔄 Already have allAssets loaded. Not re-fetching.")
            return
        }
        
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                if newStatus == .authorized {
                    self.performFetchAll()
                }
            }
        case .authorized:
            performFetchAll()
        default:
            print("🚫 Photo library access denied or restricted.")
        }
    }
    
    private func performFetchAll() {
        print("📥 Fetching ALL assets from the photo library...")
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var temp: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            temp.append(asset)
        }
        self.allAssets = temp
        
        DispatchQueue.main.async {
            self.displayedAssets.removeAll()
            self.fetchNextBatchIfNeeded()
        }
    }
    
    // MARK: - Batch Loading
    func fetchNextBatchIfNeeded() {
        guard !isFetching else { return }
        guard displayedAssets.count < allAssets.count else { return }
        
        isFetching = true
        let startIndex = displayedAssets.count
        let endIndex = min(allAssets.count, startIndex + batchSize)
        let newSlice = allAssets[startIndex..<endIndex]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.displayedAssets.append(contentsOf: newSlice)
            self.isFetching = false
            print("✅ Next batch appended. Count = \(self.displayedAssets.count)")
        }
    }
    
    // MARK: - Fetch User Albums
    func fetchUserAlbums() {
        print("📂 Fetching user albums from Photos.")
        let fetchOptions = PHFetchOptions()
        let collectionResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        var temp: [PHAssetCollection] = []
        collectionResult.enumerateObjects { collection, _, _ in
            temp.append(collection)
        }
        
        DispatchQueue.main.async {
            self.userAlbums = temp
            print("📂 Found \(temp.count) user albums.")
        }
    }
}
