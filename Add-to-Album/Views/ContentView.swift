import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var viewModel = PhotoGridViewModel()
    
    // Define a three-column grid with 2-pt spacing
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
                        // No images yet, and we're not currently fetching -> show a loading indicator
                        ProgressView("Loading Photos...")
                    } else {
                        // Show the grid of loaded thumbnails
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(viewModel.displayedImages.indices, id: \.self) { i in
                                    // Square thumbnail
                                    Image(uiImage: viewModel.displayedImages[i])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: thumbnailSize(), height: thumbnailSize())
                                        .clipped()
                                        // When we reach the last item, attempt to load the next batch
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
                    // Permission not determined; prompt user
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
                    // Permission denied or restricted
                    Text("Photo library access is denied or restricted.\nPlease update your settings.")
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
    
    /// Returns the width for a three-column layout with 2-pt spacing, ensuring a square shape.
    private func thumbnailSize() -> CGFloat {
        // We'll do a rough calculation based on screen width minus total spacing
        let screenWidth = UIScreen.main.bounds.width
        let columns: CGFloat = 3
        let spacing: CGFloat = 2
        let totalSpacing = (columns - 1) * spacing
        return (screenWidth - totalSpacing) / columns
    }
}

// MARK: - ViewModel

class PhotoGridViewModel: ObservableObject {
    @Published var status: PhotoPermissionStatus = .notDetermined
    
    /// All PHAssets in descending creationDate order
    private var allAssets: PHFetchResult<PHAsset>?
    
    /// Converted thumbnails that are currently displayed
    @Published var displayedImages: [UIImage] = []
    
    /// Indicates if a fetch or load operation is ongoing
    @Published var isFetching = false
    
    /// How many photos to load per batch
    private let batchSize = 30
    
    /// Keep track of how many assets we've converted so far
    private var currentIndex = 0
    
    private let imageManager = PHCachingImageManager()
    
    // -------------------------------------------------------------------------
    // MARK: - Permission Flow
    // -------------------------------------------------------------------------
    
    func checkCurrentStatus() {
        let current = PhotoPermissionManager.currentStatus()
        status = current
        if current == .granted || current == .limited {
            fetchAssetsIfNeeded()
        }
    }
    
    func requestPermission() {
        PhotoPermissionManager.requestPermission { [weak self] newStatus in
            guard let self = self else { return }
            self.status = newStatus
            if newStatus == .granted || newStatus == .limited {
                self.fetchAssetsIfNeeded()
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Asset Fetching and Batching
    // -------------------------------------------------------------------------
    
    /// Fetches all assets (if not yet fetched), then loads the first batch.
    private func fetchAssetsIfNeeded() {
        // If we’ve already fetched, no need to do it again
        guard allAssets == nil else {
            loadNextBatch()
            return
        }
        
        isFetching = true
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        allAssets = PHAsset.fetchAssets(with: .image, options: options)
        currentIndex = 0
        
        isFetching = false
        loadNextBatch()
    }
    
    /// Loads the next batch of images from our `allAssets`, if available.
    func loadNextBatch() {
        guard !isFetching else { return } // If we're already fetching, skip
        guard let allAssets = allAssets else { return }
        
        // If we already loaded everything, do nothing
        if currentIndex >= allAssets.count {
            return
        }
        
        isFetching = true
        
        let endIndex = min(currentIndex + batchSize, allAssets.count)
        let assetsToLoad = (currentIndex..<endIndex).map { allAssets.object(at: $0) }
        
        fetchThumbnails(for: assetsToLoad) {
            self.isFetching = false
        }
        
        currentIndex = endIndex
    }
    
    private func fetchThumbnails(for assets: [PHAsset], completion: @escaping () -> Void) {
        let targetSize = CGSize(width: 150, height: 150)
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        
        // We’ll track how many we’ve loaded
        var loadedCount = 0
        
        for asset in assets {
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { [weak self] (image, _) in
                guard let self = self, let image = image else {
                    loadedCount += 1
                    if loadedCount == assets.count {
                        completion()
                    }
                    return
                }
                
                // Append the image on the main thread
                DispatchQueue.main.async {
                    self.displayedImages.append(image)
                    loadedCount += 1
                    if loadedCount == assets.count {
                        completion()
                    }
                }
            }
        }
    }
}
