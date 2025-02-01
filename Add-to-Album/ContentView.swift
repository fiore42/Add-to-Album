import SwiftUI
import PhotosUI
//import os.log

//func logMemoryUsage() {
//    var info = task_vm_info()
//    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
//
//    let kerr = withUnsafeMutablePointer(to: &info) {
//        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
//            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
//        }
//    }
//
//    if kerr == KERN_SUCCESS {
//        let memoryUsedMB = info.phys_footprint / (1024 * 1024)
//        os_log("🧠 Memory usage: %u MB", memoryUsedMB)
//    } else {
//        os_log("❌ Memory usage query failed.")
//    }
//}

struct SelectedImage: Identifiable {
    let id = UUID() // Unique identifier required for Identifiable
    let index: Int
}

struct ContentView: View {
    @State private var images: [UIImage] = [] {
        didSet {
            print("UI should update with \(images.count) images") // Debugging UI updates
        }
    }
    @State private var photoAccessStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var photoAssets: [PHAsset] = [] // Store PHAssets instead of UIImages
    @State private var selectedImage: SelectedImage? = nil

    var body: some View {
        NavigationView {
            VStack {
                switch photoAccessStatus {
                case .authorized:
                    if images.isEmpty {
                        Text("Loading your gallery...")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .onAppear {
                                print("🔄 onAppear triggered at:", Date())
                                print("🔍 photoAssets count: \(photoAssets.count)")
                                requestPhotoLibraryAccess()
                            }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                if images.isEmpty {
                                    Text("No images available.")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                } else {

                                    ForEach(Array(photoAssets.enumerated()), id: \.offset) { index, asset in
                                        ImageThumbnailView(asset: asset)
                                            .onTapGesture {
                                                selectedImage = SelectedImage(index: index) // ✅ Track which image was clicked
                                            }
                                    }

                                }
                            }

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
            .onChange(of: images) {
                print("🔄 Images updated, UI should refresh")
            }
            .padding()
            .navigationTitle("Photo Gallery")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(item: $selectedImage) { selected in
                FullScreenImageView(assets: photoAssets, selectedIndex: selected.index) {
                    selectedImage = nil
                }
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
            fetchOptions.fetchLimit = 500 // ✅ Only fetch the 500 most recent photos

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

//struct FullScreenImageView: View {
//    let assets: [PHAsset] // Store assets instead of UIImages
//    @State var selectedIndex: Int
//    @State private var highResImage: UIImage?
//    let onDismiss: () -> Void
//
//    var body: some View {
//
//        TabView(selection: $selectedIndex) {
//            ForEach(visibleAssets(), id: \.index) { item in
//                ZStack {
//                    if let image = item.image {
//                        Image(uiImage: image)
//                            .resizable()
//                            .scaledToFit()
//                    } else {
//                        ProgressView("Loading...")
//                            .onAppear {
//                                loadHighResImage(asset: item.asset)
//                            }
//                    }
//                }
//                .tag(item.index)
//            }
//        }
//
//        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
//        .background(Color.black.edgesIgnoringSafeArea(.all))
//        .onTapGesture {
//            self.highResImage = nil // Release memory
//            onDismiss()
//        }
//    }
//
//    func visibleAssets() -> [(index: Int, asset: PHAsset, image: UIImage?)] {
//        let start = max(0, selectedIndex - 2)
//        let end = min(assets.count - 1, selectedIndex + 2)
//        
//        return Array(assets[start...end].enumerated()).map { offset, asset in
//            let actualIndex = start + offset
//            return (index: actualIndex, asset: asset, image: actualIndex == selectedIndex ? highResImage : nil)
//        }
//    }
//
//    
//    func loadHighResImage(asset: PHAsset) {
//        DispatchQueue.main.async {
//            self.highResImage = nil // ✅ Clear previous image to free memory
//        }
//
//        let imageManager = PHImageManager.default()
//        let requestOptions = PHImageRequestOptions()
//        requestOptions.isSynchronous = false
//        requestOptions.deliveryMode = .highQualityFormat
//        requestOptions.isNetworkAccessAllowed = true
//
////        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
//        let targetSize = CGSize(width: 1200, height: 1200) // Reduce size to lower memory usage
//
//        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
//            DispatchQueue.main.async {
//                self.highResImage = image
//            }
//        }
//    }
//
//    
//}
//

struct FullScreenImageView: View {
    let assets: [PHAsset]
    @State var selectedIndex: Int
    @State private var highResImages: [Int: UIImage] = [:] // Store images per index
    @State private var dragOffset: CGFloat = 0 // Track drag gesture
    let onDismiss: () -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            TabView(selection: $selectedIndex) {
                ForEach(visibleAssets(), id: \.index) { item in
                    ZStack {
                        if let image = highResImages[item.index] {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .transition(.opacity)
                                // Add gesture handling
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            dragOffset = value.translation.width
                                        }
                                        .onEnded { value in
                                            let threshold: CGFloat = 50
                                            let velocity = value.predictedEndTranslation.width - value.translation.width
                                            
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                if value.translation.width > threshold || velocity > 500 {
                                                    if selectedIndex > 0 {
                                                        selectedIndex -= 1
                                                    }
                                                } else if value.translation.width < -threshold || velocity < -500 {
                                                    if selectedIndex < assets.count - 1 {
                                                        selectedIndex += 1
                                                    }
                                                }
                                                dragOffset = 0
                                            }
                                        }
                                )
                        } else {
                            ProgressView("Loading...")
                                .onAppear {
                                    if highResImages[item.index] == nil {
                                        loadHighResImage(asset: item.asset, index: item.index)
                                    }
                                }
                        }
                    }
                    .tag(item.index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .background(Color.black.edgesIgnoringSafeArea(.all))
            // Disable default TabView paging
            .gesture(DragGesture())
            .onAppear {
                loadHighResImage(asset: assets[selectedIndex], index: selectedIndex)
            }
            .onChange(of: selectedIndex) { oldIndex, newIndex in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
                if highResImages[newIndex] == nil {
                    loadHighResImage(asset: assets[newIndex], index: newIndex)
                }
            }
        }
    }
    
    func visibleAssets() -> [(index: Int, asset: PHAsset)] {
        let start = max(0, selectedIndex - 2)
        let end = min(assets.count - 1, selectedIndex + 2)
        return assets[start...end].enumerated().map { offset, asset in
            let actualIndex = start + offset
            return (index: actualIndex, asset: asset)
        }
    }
    
    func loadHighResImage(asset: PHAsset, index: Int) {
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
