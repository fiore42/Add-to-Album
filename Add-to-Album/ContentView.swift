import SwiftUI
import PhotosUI

struct SelectedImage: Identifiable {
    let id = UUID() // Unique identifier required for Identifiable
    let index: Int
}

struct ContentView: View {
    @State private var photoAssets: [PHAsset] = []
    @State private var photoAccessStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedImage: SelectedImage? = nil
    @State private var currentPage = 0
    @State private var isLoadingMore = false
    private let batchSize = 30  // Reduced batch size for smoother loading
    
    
    var body: some View {
        NavigationView {
            VStack {
                switch photoAccessStatus {
                case .authorized:
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 2)], spacing: 2) {
                            ForEach(photoAssets.indices, id: \.self) { index in
                                ImageThumbnailView(asset: photoAssets[index])
                                    .onTapGesture {
                                        selectedImage = SelectedImage(index: index) // Directly pass the index
                                    }
                                    .onAppear {
                                        if index == photoAssets.count - 15 && !isLoadingMore {
                                            loadNextBatch()
                                        }
                                    }
                            }
                        }

                        if isLoadingMore {
                            ProgressView().padding()
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
                    loadMoreAssets: loadNextBatch,
                    onDismiss: { selectedImage = nil }
                )
//                {
//                    selectedImage = nil
//                }
            }
        }
    }
    
    func loadNextBatch() {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        let startTime = Date()
        let currentCount = photoAssets.count
        
        print("🔄 Loading next batch of images at \(startTime) (current count: \(currentCount))")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            // Use fetchLimit to get only what we need
            fetchOptions.fetchLimit = currentCount + batchSize
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            let fetchEndTime = Date()
            print("✅ Fetch batch completed. Time taken: \(fetchEndTime.timeIntervalSince(startTime)) seconds")
            
            
            // Calculate the range for new assets
            let startIndex = currentCount
            let endIndex = min(startIndex + batchSize, fetchResult.count)
            
            // Check if we have new assets to load
            guard startIndex < fetchResult.count else {
                DispatchQueue.main.async {
                    isLoadingMore = false
                }
                print("⚠️ No new assets found to load")
                return
            }
            
            // Use sparse array to fetch only the new assets
            let indexSet = IndexSet(startIndex..<endIndex)
            let newAssets = fetchResult.objects(at: indexSet)
            
            DispatchQueue.main.async {
                let mainThreadStart = Date()
                
                // Append new assets in chunks to prevent UI freezes
                let chunkSize = 10
                for chunk in stride(from: 0, to: newAssets.count, by: chunkSize) {
                    let endChunk = min(chunk + chunkSize, newAssets.count)
                    let assetsChunk = Array(newAssets[chunk..<endChunk])
                    
                    // Add small delay between chunks
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(chunk/chunkSize)) {
                        photoAssets.append(contentsOf: assetsChunk)
                    }
                }
                
                currentPage += 1
                isLoadingMore = false
                let mainThreadEnd = Date()
                print("✅ Updated photoAssets. UI update time: \(mainThreadEnd.timeIntervalSince(mainThreadStart)) seconds")
                print("🔄 Batch load complete. Total duration: \(mainThreadEnd.timeIntervalSince(startTime)) seconds")
                
            }
        }
    }
    
    struct ImageThumbnailView: View {
        let asset: PHAsset
        @State private var thumbnail: UIImage?
        
        var body: some View {
            Group {
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
        }
        
        func loadThumbnail() {
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .opportunistic  // Changed to opportunistic for better performance
            requestOptions.resizeMode = .exact  // Changed to exact for better quality/performance ratio
            
            let targetSize = CGSize(width: 200, height: 200)  // Increased size for better quality
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, _ in
                if let image = image {
                    DispatchQueue.main.async {
                        self.thumbnail = image
                    }
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
        let startTime = Date()
        print("⏳ fetchAllPhotos() started at \(startTime)")
        
        //        logMemoryUsage() // ✅ Log memory before loading images
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("📸 Fetching photos on background thread at \(Date())")
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 100 // ✅ Only fetch the 500 most recent photos
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            print("✅ Fetch completed. Found \(fetchResult.count) assets at \(Date())")
            
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
                let mainThreadStartTime = Date()
                self.photoAssets.append(contentsOf: fetchResult.objects(at: IndexSet(0..<fetchResult.count)))
                let mainThreadEndTime = Date()
                print("✅ Updated photoAssets. Time taken: \(mainThreadEndTime.timeIntervalSince(mainThreadStartTime)) seconds")
                
                let endTime = Date()
                print("⏳ fetchAllPhotos() completed in \(endTime.timeIntervalSince(startTime)) seconds")
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
    @State private var highResImages: [Int: UIImage] = [:] // Store images by original index
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
                    ForEach(visibleImageIndexes(), id: \.self) { index in
                        let asset = assets[index]  // Ensure correct mapping
                        ZStack {
                            if let image = highResImages[index] {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width)
                            } else {
                                ProgressView("Loading...")
                                    .onAppear {
                                        loadHighResImage(asset: asset, index: index)
                                        //                                                   loadHighResImage(asset: assets[index], index: index)
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
            print("🟢 FullScreenImageView appeared with selectedIndex: \(selectedIndex) at \(Date())")
            loadVisibleImages()
        }
        .onChange(of: selectedIndex) { oldIndex, newIndex in
            print("🔄 selectedIndex changed from \(oldIndex) to \(newIndex) at \(Date())")
            loadVisibleImages()
        }
    }
    
    //    private func loadVisibleImages() {
    //        // Load current image
    //        loadHighResImage(asset: assets[selectedIndex], index: selectedIndex)
    //
    //        // Load previous image if exists
    //        if selectedIndex > 0 {
    //            loadHighResImage(asset: assets[selectedIndex - 1], index: selectedIndex - 1)
    //        }
    //
    //        // Load next image if exists
    //        if selectedIndex < assets.count - 1 {
    //            loadHighResImage(asset: assets[selectedIndex + 1], index: selectedIndex + 1)
    //        }
    //    }
    
    private func loadVisibleImages() {
        let indexes = visibleImageIndexes()
        print("🖼 Loading visible images for indexes: \(indexes) at \(Date())")
        
        for index in indexes {
            loadHighResImage(asset: assets[index], index: index)
        }
    }
    
    
    func loadHighResImage(asset: PHAsset, index: Int) {
        // Skip if already loaded
        if highResImages[index] != nil {
            print("✅ Image at index \(index) already loaded. Skipping.")
            return
        }
        
        let startTime = Date()
        print("🔍 Starting high-res image load for index \(index) at \(startTime)")
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        
        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
            let endTime = Date()
            
            if let image = image {
                DispatchQueue.main.async {
                    highResImages[index] = image
//                    self.highResImages[index] = image
                    print("✅ High-res image for index \(index) loaded in \(endTime.timeIntervalSince(startTime)) seconds")
                    
                }
            }
            else {
                print("❌ Failed to load high-res image for index \(index)")
                
            }
        }
    }
    
    func visibleImageIndexes() -> [Int] {
        let start = max(0, selectedIndex - 1)  // Load previous image
        let end = min(assets.count - 1, selectedIndex + 1)  // Load next image
        
        let indexes = Array(start...end)
        
        print("📌 Corrected Visible image indexes: \(indexes) (called at \(Date()))")
        
        return indexes
    }
    
}
