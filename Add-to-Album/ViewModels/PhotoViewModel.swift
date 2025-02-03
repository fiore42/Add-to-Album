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
        
        // Optionally limit the results if you have huge libraries (e.g., 30k+ photos)
        // Comment out this line if you truly want *all* photos at once.
        fetchOptions.fetchLimit = 5000
        
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        print("📊 Photos framework returned \(result.count) assets (respecting fetchLimit if set).")

        var temp: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            temp.append(asset)
        }
        self.allAssets = temp
        
        print("📊 After enumeration, we have allAssets.count = \(self.allAssets.count).")

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
            
            let addedCount = newSlice.count
            let totalDisplayed = self.displayedAssets.count
            print("✅ Fetched \(addedCount) items in this batch. Now displaying \(totalDisplayed) total.")
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
