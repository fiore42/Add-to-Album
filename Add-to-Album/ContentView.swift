import SwiftUI
import PhotosUI

struct SelectedImage: Identifiable {
    let id = UUID() // Unique identifier required for Identifiable
    let index: Int
}

struct ContentView: View {
    @State private var images: [UIImage] = []
    @State private var photoAccessStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var photoAssets: [PHAsset] = []
    @State private var selectedImage: SelectedImage? = nil
    @State private var currentPage = 0
    @State private var isLoadingMore = false
    private let batchSize = 50

    var body: some View {
        NavigationView {
            VStack {
                switch photoAccessStatus {
                case .authorized:
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(Array(photoAssets.enumerated()), id: \.offset) { index, asset in
                                ImageThumbnailView(asset: asset)
                                    .onTapGesture {
                                        selectedImage = SelectedImage(index: index)
                                    }
                                    // Load more when reaching near the end
                                    .onAppear {
                                        if index == photoAssets.count - 10 && !isLoadingMore {
                                            loadNextBatch()
                                        }
                                    }
                            }
                        }
                        
                        if isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                    .onAppear {
                        if photoAssets.isEmpty {
                            requestPhotoLibraryAccess()
                        }
                    }
                case .limited:
                    VStack {
                        Text("The app has limited access to your photos.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Open Settings to Allow Full Access") {
                            openSettings()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                case .denied, .restricted:
                    VStack {
                        Text("Photos access is required. Please enable it in Settings.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Open Settings") {
                            openSettings()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                case .notDetermined:
                    Text("Requesting access to Photos...")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .onAppear {
                            requestPhotoLibraryAccess()
                        }

                @unknown default:
                    Text("Unexpected authorization status. Please restart the app.")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Photo Gallery")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(item: $selectedImage) { selected in
                FullScreenImageView(
                    assets: photoAssets,
                    selectedIndex: selected.index,
                    loadMoreAssets: loadNextBatch
                ) {
                    selectedImage = nil
                }
            }
        }
    }
    
    func loadNextBatch() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = batchSize * (currentPage + 1)
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            let startIndex = currentPage * batchSize
            let endIndex = min(startIndex + batchSize, fetchResult.count)
            
            // If we've fetched all available photos, don't continue
            guard startIndex < fetchResult.count else {
                DispatchQueue.main.async {
                    isLoadingMore = false
                }
                return
            }
            
            let newAssets = fetchResult.objects(at: IndexSet(startIndex..<endIndex))
            
            DispatchQueue.main.async {
                photoAssets.append(contentsOf: newAssets)
                currentPage += 1
                isLoadingMore = false
            }
        }
    }

    struct ImageThumbnailView: View {
        let asset: PHAsset
        @State private var thumbnail: UIImage?

        var body: some View {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
            } else {
                Color.gray
                    .frame(width: 100, height: 100)
                    .onAppear {
                        loadThumbnail()
                    }
            }
        }

        func loadThumbnail() {
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .fastFormat

            let targetSize = CGSize(width: 100, height: 100) // Small size for speed
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { image, _ in
                DispatchQueue.main.async {
                    self.thumbnail = image
                }
            }
        }
    }

    
    // MARK: - Request Photo Library Access
    func requestPhotoLibraryAccess() {

        print("🔍 Entered requestPhotoLibraryAccess() at:", Date())

        DispatchQueue.main.async { // ✅ Ensure immediate UI update
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            photoAccessStatus = status // ✅ Update status immediately

            if status == .notDetermined {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                    DispatchQueue.main.async {
                        self.photoAccessStatus = newStatus
                        if newStatus == .authorized {
                            self.fetchAllPhotos()
                        } else if newStatus == .limited {
                            self.alertMessage = "The app currently has limited access. You can grant full access in Settings."
                            self.showAlert = true
                        } else {
                            self.alertMessage = "Photos access is required. Please enable it in Settings."
                            self.showAlert = true
                        }
                    }
                }
            } else if status == .authorized {
                fetchAllPhotos() // ✅ Fetch photos immediately if already authorized
            }
        }
    }


    
    // MARK: - Fetch All Photos
    func fetchAllPhotos() {
        print("Starting fetchAllPhotos()") // Debugging Step 1
        
//        logMemoryUsage() // ✅ Log memory before loading images

        DispatchQueue.global(qos: .userInitiated).async {
            print("Fetching photos on background thread") // Debugging Step 2

            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 100 // ✅ Only fetch the 500 most recent photos

            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            print("Fetched \(fetchResult.count) photos") // Debugging Step 3

            var fetchedImages: [UIImage] = []
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .fastFormat // ✅ Fast-loading thumbnails
            requestOptions.resizeMode = .fast
            requestOptions.isNetworkAccessAllowed = true

            let batchSize = 20 // ✅ Process in batches of 20
            for batchStart in stride(from: 0, to: fetchResult.count, by: batchSize) {
                let batchEnd = min(batchStart + batchSize, fetchResult.count)
                let batchAssets = fetchResult.objects(at: IndexSet(batchStart..<batchEnd))

                for asset in batchAssets {
                    let targetSize = CGSize(width: 200, height: 200)
                    imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { image, _ in
                        if let image = image {
                            DispatchQueue.main.async {
                                fetchedImages.append(image)
                                // ✅ Only print every 100 images
                                if fetchedImages.count % 100 == 0 {
                                    print("Loaded image \(fetchedImages.count)/\(fetchResult.count)")
                                }
                            }
                        } else {
                            print("Skipping missing or iCloud-only image at index \(fetchedImages.count + 1)")
                        }
                    }
                }

                usleep(200_000) // ✅ Small delay to prevent UI freeze
            }

            DispatchQueue.main.async {
                self.photoAssets = Array(fetchResult.objects(at: IndexSet(0..<fetchResult.count))) // ✅ Update photoAssets
                self.images = fetchedImages
                print("✅ Updated photoAssets with \(self.photoAssets.count) assets") // Debugging Step 5
            }

        }
    }


    // MARK: - Open App Settings
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
}


struct FullScreenImageView: View {
    let assets: [PHAsset]
    @State var selectedIndex: Int
    @State private var highResImages: [Int: UIImage] = [:]
    @State private var offset: CGFloat = 0
    @State private var dragging = false
    let loadMoreAssets: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Main content
                       GeometryReader { geometry in
                           HStack(spacing: 0) {
                               ForEach(0..<assets.count, id: \.self) { index in
                                   ZStack {
                                       if let image = highResImages[index] {
                                           Image(uiImage: image)
                                               .resizable()
                                               .scaledToFit()
                                               .frame(width: geometry.size.width)
                                       } else {
                                           ProgressView("Loading...")
                                               .onAppear {
                                                   loadHighResImage(asset: assets[index], index: index)
                                               }
                                       }
                                   }
                                   .frame(width: geometry.size.width)
                                   // Load more images when approaching the end
                                   .onAppear {
                                       if index == assets.count - 5 {
                                           loadMoreAssets()
                                       }
                                   }
                               }
                           }
                           .offset(x: -CGFloat(selectedIndex) * geometry.size.width + offset)
                           .animation(dragging ? nil : .interactiveSpring(), value: selectedIndex)
                           .gesture(
                               DragGesture()
                                   .onChanged { value in
                                       dragging = true
                                       offset = value.translation.width
                                   }
                                   .onEnded { value in
                                       dragging = false
                                       let predictedEndOffset = value.predictedEndTranslation.width
                                       let threshold: CGFloat = 100
                                       
                                       withAnimation(.interactiveSpring()) {
                                           if predictedEndOffset > threshold && selectedIndex > 0 {
                                               selectedIndex -= 1
                                           } else if predictedEndOffset < -threshold && selectedIndex < assets.count - 1 {
                                               selectedIndex += 1
                                           }
                                           offset = 0
                                       }
                                   }
                           )
                       }
            
            // Back button overlay
                       VStack {
                           HStack {
                               Button(action: {
                                   onDismiss()
                               }) {
                                   Image(systemName: "chevron.left")
                                       .font(.title2)
                                       .foregroundColor(.white)
                                       .padding()
                                       .background(
                                           Circle()
                                               .fill(Color.black.opacity(0.5))
                                       )
                               }
                               .padding(.top, 50)
                               .padding(.leading, 20)
                               Spacer()
                           }
                           Spacer()
                       }
                   }
                   .ignoresSafeArea()
                   .onAppear {
                       loadVisibleImages()
                   }
                   .onChange(of: selectedIndex) { oldIndex, newIndex in
                       loadVisibleImages()
                   }
               }
    
    private func loadVisibleImages() {
        // Load current image
        loadHighResImage(asset: assets[selectedIndex], index: selectedIndex)
        
        // Load previous image if exists
        if selectedIndex > 0 {
            loadHighResImage(asset: assets[selectedIndex - 1], index: selectedIndex - 1)
        }
        
        // Load next image if exists
        if selectedIndex < assets.count - 1 {
            loadHighResImage(asset: assets[selectedIndex + 1], index: selectedIndex + 1)
        }
    }
    
    func loadHighResImage(asset: PHAsset, index: Int) {
        // Skip if already loaded
        if highResImages[index] != nil {
            return
        }
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        
        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    highResImages[index] = image
                }
            }
        }
    }
}
