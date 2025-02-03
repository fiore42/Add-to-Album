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
                    if viewModel.displayedImages.isEmpty && !viewModel.isFetching {
                        ProgressView("Loading Photos...")
                    } else {
                        // (Debug Log) Print when we actually render the grid
                        Text("[DEBUG] Rendering grid with \(viewModel.displayedImages.count) images.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(viewModel.displayedImages.indices, id: \.self) { i in
                                    ZStack {
                                        // Background color to ensure we see the cell area
                                        Color.gray.opacity(0.2)
                                            .frame(width: thumbnailSize(), height: thumbnailSize())
                                        
                                        // The photo thumbnail
                                        if let image = viewModel.displayedImages[safe: i] {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: thumbnailSize(), height: thumbnailSize())
                                                .clipped()
                                        } else {
                                            // If for some reason there's no image at that index,
                                            // show a placeholder color.
                                            Color.red
                                                .frame(width: thumbnailSize(), height: thumbnailSize())
                                        }
                                        
                                        // A small overlay label to see the cell # for debugging
                                        Text("Cell #\(i + 1)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(Color.black.opacity(0.3))
                                            .cornerRadius(4)
                                    }
                                    // When this cell appears, check if it's the last -> load next batch
                                    .onAppear {
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
            // Debug log when the view first appears
            print("[\(Date())] [ContentView] onAppear -> checking status.")
            viewModel.checkCurrentStatus()
        }
    }
    
    /// Calculate a square cell size for a 3-column layout with 2-pt spacing.
    private func thumbnailSize() -> CGFloat {
        // If this runs too early on certain devices/orientations, you can
        // fallback to a known default if zero:
        let width = UIScreen.main.bounds.width
        if width == 0 {
            print("[\(Date())] [ContentView] WARNING: Screen width is 0. Using default 100.")
            return 100
        }
        
        let totalSpacing: CGFloat = 2 * (3 - 1) // 3 columns => 2 gaps
        let size = (width - totalSpacing) / 3
        return size
    }
}

// MARK: - PhotoGridViewModel

class PhotoGridViewModel: ObservableObject {
    @Published var status: PhotoPermissionStatus = .notDetermined
    
    /// All PHAssets (fetched once) in descending creationDate order
    private var allAssets: PHFetchResult<PHAsset>?
    
    /// The thumbnails currently displayed
    @Published var displayedImages: [UIImage] = []
    
    /// Indicates if we're currently fetching or loading a batch
    @Published var isFetching = false
    
    /// How many photos to load per batch
    private let batchSize = 10
    
    /// Index of the next asset to load
    private var currentIndex = 0
    
    private let imageManager = PHCachingImageManager()
    
    // Debug logger with timestamp
    private func log(_ message: String) {
        print("[\(Date())] [PhotoGridViewModel] \(message)")
    }
    
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
    
    /// Fetches all photo assets once, then triggers loadNextBatch.
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

// An optional safe subscript to avoid out-of-range errors
fileprivate extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
