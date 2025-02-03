import SwiftUI
import Photos

class ImageGridViewModel: ObservableObject {
    @Published var status: PhotoPermissionStatus = .notDetermined
    @Published var images: [UIImage] = []
    
    private let imageManager = ImageManager()
    private var allAssets: PHFetchResult<PHAsset>?
    private var currentIndex = 0
    private let batchSize = 30
    private var isLoadingBatch = false // Prevents duplicate batch loads

    /// **Step 1:** Check Permissions & Load Photos
    func checkPermissions() {
        let current = imageManager.getPhotoPermissionStatus()
        status = current
        Logger.log("🔍 Current permission status: \(current)")
        
        if current == .granted || current == .limited {
            fetchAssetsIfNeeded()
        }
    }

    func requestPermission() {
        imageManager.requestPhotoPermissions { [weak self] granted in
            DispatchQueue.main.async {
                self?.status = granted ? .granted : .denied
                if granted {
                    self?.fetchAssetsIfNeeded()
                }
            }
        }
    }
    
    private func fetchAssetsIfNeeded() {
        if allAssets != nil { return }
        
        Logger.log("📸 Fetching assets...")
        allAssets = imageManager.fetchAllAssets()
        currentIndex = 0

        // **Delays batch loading slightly to avoid UI freeze**
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.loadNextBatch()
        }
    }
    func loadNextBatch() {
         guard !isLoadingBatch, let allAssets = allAssets, currentIndex < allAssets.count else {
             Logger.log("⚠️ Skipping batch load (already loading or no more assets)")
             return
         }

         isLoadingBatch = true // Prevents duplicate loads

         let endIndex = min(currentIndex + batchSize, allAssets.count)
         let assetsToLoad = (currentIndex..<endIndex).map { allAssets.object(at: $0) }
         currentIndex = endIndex
         
         Logger.log("📥 Loading images [\(currentIndex) to \(endIndex)]")

         // **Fetch thumbnails concurrently**
         imageManager.fetchThumbnails(for: assetsToLoad) { [weak self] images in
             DispatchQueue.main.async {
                 self?.images.append(contentsOf: images)
                 self?.isLoadingBatch = false // Mark batch as complete
             }
         }
     }
}
