
import SwiftUI
import Photos

class ImageGridViewModel: ObservableObject {
    @Published var status: PhotoPermissionStatus = .notDetermined
    @Published var images: [UIImage] = []

    private let imageManager = ImageManager()
    private var allAssets: PHFetchResult<PHAsset>?
    private var currentIndex = 0
    private let batchSize = 30
    private var isLoadingBatch = false

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
    
    /// **Step 2:** Fetch Assets Once
    private func fetchAssetsIfNeeded() {
        guard allAssets == nil else { return }

        Logger.log("📸 Fetching assets...")
        allAssets = imageManager.fetchAllAssets()
        currentIndex = 0

        DispatchQueue.main.async {
            self.loadNextBatch()
        }
    }

    /// **Step 3:** Load Next Batch (Efficiently)
    func loadNextBatch() {
        guard !isLoadingBatch, let allAssets = allAssets, currentIndex < allAssets.count else {
            Logger.log("⚠️ No more images or already loading")
            return
        }

        isLoadingBatch = true

        let endIndex = min(currentIndex + batchSize, allAssets.count)
        let assetsToLoad = (currentIndex..<endIndex).map { allAssets.object(at: $0) }
        currentIndex = endIndex

        Logger.log("📥 Requesting thumbnails [\(currentIndex) to \(endIndex)]")

        // **Efficient Parallel Processing (Limits Threads to 4)**
        imageManager.fetchThumbnails(for: assetsToLoad, maxConcurrentRequests: 4) { [weak self] images in
            DispatchQueue.main.async {
                self?.images.append(contentsOf: images)
                self?.isLoadingBatch = false
            }
        }
    }
}
