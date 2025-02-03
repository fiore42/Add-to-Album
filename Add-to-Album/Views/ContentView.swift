import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var viewModel = PhotoGridViewModel()
    
    // Number of columns in the grid
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
                    // Authorized: Show the grid of images
                    if viewModel.images.isEmpty {
                        ProgressView("Loading Photos...")
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(viewModel.images, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(minWidth: 0, maxWidth: .infinity,
                                               minHeight: 100, maxHeight: .infinity)
                                        .clipped()
                                }
                            }
                            .padding(2)
                        }
                    }
                    
                case .notDetermined:
                    // Permission not determined yet: show button to request
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
                    // Denied or restricted: show message
                    Text("Photo library access is denied or restricted.\nPlease update your settings to continue.")
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .navigationTitle("Photo Grid")
        }
        .onAppear {
            // If the user had previously granted permission, fetch photos right away.
            // (This also triggers when the view is first loaded.)
            viewModel.checkCurrentStatus()
        }
    }
}

// MARK: - View Model

class PhotoGridViewModel: ObservableObject {
    @Published var status: PhotoPermissionStatus = .notDetermined
    @Published var images: [UIImage] = []
    
    // For demonstration, we’ll fetch a small set of photos
    private let batchSize = 30
    
    func checkCurrentStatus() {
        let current = PhotoPermissionManager.currentStatus()
        status = current
        
        if current == .granted || current == .limited {
            fetchPhotos()
        }
    }
    
    func requestPermission() {
        PhotoPermissionManager.requestPermission { [weak self] newStatus in
            guard let self = self else { return }
            self.status = newStatus
            if newStatus == .granted || newStatus == .limited {
                self.fetchPhotos()
            }
        }
    }
    
    private func fetchPhotos() {
        // 1. Fetch PHAssets
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = PHAsset.fetchAssets(with: .image, options: options)
        let count = min(batchSize, result.count)
        
        // 2. Request images (synchronously or asynchronously)
        //    We'll do a simple approach: get them in a for-loop.
        
        // Typically, you'd use a PHImageManager (caching or not).
        let imageManager = PHCachingImageManager()
        
        var tempImages: [UIImage] = []
        let targetSize = CGSize(width: 150, height: 150) // low-res
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        
        for i in 0..<count {
            let asset = result.object(at: i)
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, _ in
                if let image = image {
                    tempImages.append(image)
                }
                
                // When we've reached the last requested asset, publish
                if i == count - 1 {
                    DispatchQueue.main.async {
                        self.images = tempImages
                    }
                }
            }
        }
    }
}
