import SwiftUI
import Photos

class ImageGridViewModel: ObservableObject {
    @Published var status: PhotoPermissionStatus = .notDetermined
    @Published var imageAssets: [PHAsset] = [] // Only PHAssets are stored
    @Published internal var isLoadingBatch = false // Make it internal
    @Published var isCheckingPermissions: Bool = true


    private let imageManager = ImageManager() // Assuming this handles permission requests and asset fetching
    private var allAssets: PHFetchResult<PHAsset>?
    private var currentIndex = 0
    private let batchSize = 30
//    private var isLoadingBatch = false

    func checkPermissions() {
        Logger.log("🔍 Checking Permissions...")
        let current = imageManager.getPhotoPermissionStatus()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return } // Prevents memory leaks

            self.status = current
            self.isCheckingPermissions = false // Hide splash screen once check is done

            Logger.log("📊 Current Photo Library Status: \(self.status)")

            if current == .granted || current == .limited {
                self.fetchAssetsIfNeeded()
            }
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
        guard allAssets == nil else { return }

        allAssets = imageManager.fetchAllAssets()
        currentIndex = 0

        DispatchQueue.main.async {
            self.loadNextBatch()
        }
    }

    func loadNextBatch() {
        guard !isLoadingBatch, let allAssets = allAssets, currentIndex < allAssets.count else {
            return
        }

        isLoadingBatch = true

        let endIndex = min(currentIndex + batchSize, allAssets.count)
        let assetsToLoad = (currentIndex..<endIndex).map { allAssets.object(at: $0) }
        currentIndex = endIndex

        // Append PHAssets directly (no need to convert to UIImage for the grid)
        DispatchQueue.main.async {
            self.imageAssets.append(contentsOf: assetsToLoad)
            self.isLoadingBatch = false // Release the lock *after* appending the assets.
        }
    }
}



