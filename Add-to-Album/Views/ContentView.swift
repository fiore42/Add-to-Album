import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var viewModel = PhotoGridViewModel()
    
    // A three-column grid with 2-pt spacing
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.status {
                case .granted, .limited:
                    // Permission granted or limited
                    if viewModel.displayedImages.isEmpty && !viewModel.isFetching {
                        ProgressView("Loading Photos...")
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(viewModel.displayedImages.indices, id: \.self) { i in
                                    // Square thumbnail
                                    Image(uiImage: viewModel.displayedImages[i])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: thumbnailSize(), height: thumbnailSize())
                                        .clipped()
                                        .onAppear {
                                            // When the user scrolls to the last item, load the next batch
                                            if i == viewModel.displayedImages.count - 1 {
                                                viewModel.loadNextBatch()
                                            }
                                        }
                                }
                            }
                            .padding(2)
                        }
                    }
                    
                case .notDetermined:
                    VStack(spacing: 20) {
                        Text("We need access to your photo library.")
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Request Permission") {
                            viewModel.requestPermission()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                case .denied, .restricted:
                    Text("Photo library access is denied or restricted.\nPlease update your Settings.")
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .navigationTitle("Photo Grid")
        }
        .onAppear {
            viewModel.checkCurrentStatus()
        }
    }
    
    /// Calculate a square cell size for a 3-column layout with 2-pt spacing.
    private func thumbnailSize() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let totalSpacing: CGFloat = 2 * (3 - 1) // 3 columns => 2 gaps
        return (screenWidth - totalSpacing) / 3
    }
}

// MARK: - ViewModel

class PhotoGridViewModel: ObservableObject {
    @Published var status: PhotoPermissionStatus = .notDetermined
    
    /// All PHAssets (fetched once) in descending creationDate order
    private var allAssets: PHFetchResult<PHAsset>?
    
    /// The thumbnails currently displayed
    @Published var displayedImages: [UIImage] = []
    
    /// Indicates if we're currently fetching or loading a batch
    @Published var isFetching = false
    
    /// How many photos to load per batch (smaller to help diagnose issues)
    private let batchSize = 10
    
    /// Index of the next asset to load
    private var currentIndex = 0
    
    private let imageManager = PHCachingImageManager()
    
    // Debug logger with timestamp
    private func log(_ message: String) {
        print("[\(Date())] [PhotoGridViewModel] \(message)")
    }
    
    // ---------------------------------------------------------------------
    // MARK: - Permission Flow
    // ---------------------------------------------------------------------
    
    func checkCurrentStatus() {
        let current = PhotoPermissionManager.currentStatus()
        status = current
        log("checkCurrentStatus() -> \(current)")
        
        if current == .granted || current == .limited {
            fetchAssetsIfNeeded()
        }
    }
    
    func requestPermission() {
        log("requestPermission() called.")
        PhotoPermissionManager.requestPermission { [weak self] newStatus in
            guard let self = self else { return }
            self.log("requestPermission() -> user responded with \(newStatus)")
            self.status = newStatus
            
            if newStatus == .granted || newStatus == .limited {
                self.fetchAssetsIfNeeded()
            }
        }
    }
    
    // ---------------------------------------------------------------------
    // MARK: - Asset Fetching / Batching
    // ---------------------------------------------------------------------
    
    /// Fetches all photo assets (if we haven't already),
    /// then triggers the initial batch load.
    private func fetchAssetsIfNeeded() {
        guard allAssets == nil else {
            log("fetchAssetsIfNeeded() -> allAssets already fetched. Will load next batch.")
            loadNextBatch()
            return
        }
        
        isFetching = true
        log("fetchAssetsIfNeeded() -> Fetching assets from Photo Library...")
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = PHAsset.fetchAssets(with: .image, options: options)
        self.allAssets = result
        self.currentIndex = 0
        
        log("fetchAssetsIfNeeded() -> Fetched total assets: \(result.count)")
        
        isFetching = false
        loadNextBatch()
    }
    
    /// Loads the next batch of photos if available.
    func loadNextBatch() {
        guard !isFetching else {
            log("loadNextBatch() -> Already fetching, skipping.")
            return
        }
        guard let allAssets = allAssets else {
            log("loadNextBatch() -> No assets fetched yet.")
            return
        }
        
        // Check if we've loaded all
        if currentIndex >= allAssets.count {
            log("loadNextBatch() -> All assets already loaded. currentIndex=\(currentIndex).")
            return
        }
        
        isFetching = true
        
        let endIndex = min(currentIndex + batchSize, allAssets.count)
        let assetsToLoad = (currentIndex..<endIndex).map { allAssets.object(at: $0) }
        
        log("loadNextBatch() -> Will load assets [\(currentIndex) ..< \(endIndex)] (count: \(assetsToLoad.count)).")
        
        currentIndex = endIndex
        
        fetchThumbnails(for: assetsToLoad) {
            self.isFetching = false
            self.log("loadNextBatch() -> Finished batch. displayedImages.count = \(self.displayedImages.count)")
        }
    }
    
    /// Fetch thumbnails for the given PHAssets on a background thread,
    /// then append them to displayedImages on the main thread.
    private func fetchThumbnails(for assets: [PHAsset], completion: @escaping () -> Void) {
        let targetSize = CGSize(width: 150, height: 150)
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.log("fetchThumbnails() -> Starting background fetch for \(assets.count) assets.")
            
            var tempImages = [UIImage]()
            tempImages.reserveCapacity(assets.count)
            
            let group = DispatchGroup()
            
            for (i, asset) in assets.enumerated() {
                group.enter()
                self.log("fetchThumbnails() -> Requesting image for item \(i+1)/\(assets.count) (assetIndex=\(i)).")
                
                self.imageManager.requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFill,
                    options: requestOptions
                ) { image, info in
                    if let image = image {
                        self.log("fetchThumbnails() -> Received image for item \(i+1)/\(assets.count).")
                        tempImages.append(image)
                    } else {
                        self.log("fetchThumbnails() -> Nil image for item \(i+1)/\(assets.count). Possibly iCloud or error.")
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.log("fetchThumbnails() -> Completed batch of \(assets.count) assets. Appending to displayedImages.")
                self.displayedImages.append(contentsOf: tempImages)
                completion()
            }
        }
    }
}
