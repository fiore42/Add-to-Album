import SwiftUI
import PhotosUI
import Foundation // ✅ Ensure Foundation is imported

    
struct FullScreenImageView: View {

    
    @ObservedObject var viewModel: ViewModel
    let assets: [PHAsset] // Updated: Store all assets for swiping
    let imageManager: PHImageManager
    @State private var selectedIndex: Int // Track which image is being viewed
    @State private var highResImages: [Int: UIImage] = [:] // Store loaded images
    @State private var dragOffset: CGFloat = 0
    @GestureState private var dragState = DragState.inactive // Use @GestureState
    @State private var rubberBandOffset: CGFloat = 0 // New state for resistance
    @Binding var pairedAlbums: [String: PHAssetCollection?] // Binding to optional PHAssetCollections
    let loadMoreAssets: () -> Void // Trigger batch load if needed
    let onDismiss: () -> Void
    let imageCache = NSCache<PHAsset, UIImage>() // Image cache
    @State private var imageLoadRequests: [Int: PHImageRequestID] = [:] // Track requests

    @AppStorage("functionAlbumAssociations") private var functionAlbumAssociations: Data = Data()
    
        
    // ✅ Custom public initializer to fix the "private initializer" issue
    init(
        viewModel: ViewModel, // Initialize viewModel
        assets: [PHAsset],
        imageManager: PHImageManager,
        selectedIndex: Int,
//        pairedAlbums: [String: PHAssetCollection],
//        pairedAlbums: Binding<[String: PHAssetCollection]>, // Note the Binding<> wrapper
        pairedAlbums: Binding<[String: PHAssetCollection?]>, // Binding to optional dictionary
        loadMoreAssets: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel  // Initialize viewModel
        self.assets = assets
        self.imageManager = imageManager
        self._selectedIndex = State(initialValue: selectedIndex)
//        self.pairedAlbums = pairedAlbums
        self._pairedAlbums = pairedAlbums // Initialize the _pairedAlbums with the binding
        self.loadMoreAssets = loadMoreAssets
        self.onDismiss = onDismiss
        // highResImages and dragOffset are initialized by default, no need to initialize them here.
        // functionAlbumAssociations is initialized by @AppStorage
    }

    enum DragState {
            case inactive
            case dragging(translation: CGSize)

            var translation: CGSize {
                switch self {
                case .inactive:
                    return .zero
                case .dragging(let translation):
                    return translation
                }
            }

            var isDragging: Bool {
                switch self {
                case .inactive:
                    return false
                case .dragging:
                    return true
                }
            }
        }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
//            InteractiveImageGallery(
//                selectedIndex: $selectedIndex,
//                assets: assets,
//                imageManager: imageManager,
//                highResImages: highResImages,  // ✅ Pass high-res images
//                loadMoreAssets: { /* Handle loading more assets if needed */ }
//            )
////            InteractiveImageGallery(selectedIndex: $selectedIndex, assets: assets, imageManager: imageManager, loadMoreAssets: loadMoreAssets)
//                .edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(assets.indices, id: \.self) { index in
                        ZStack {
                            if let image = highResImages[index] {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width)
                            } else {
                                ProgressView("Loading...")
                                    .frame(width: geometry.size.width)
                                    .onAppear {
                                        loadImageIfNecessary(index: index, size: geometry.size.width)
//                                        loadHighResImage(index: index, size: geometry.size.width) // Pass size
//                                        loadHighResImage(index: index)
                                    }
                            }
                        }
                        .frame(width: geometry.size.width)
                    }
                }
                .onAppear {
                    loadImageIfNecessary(index: selectedIndex, size: UIScreen.main.bounds.width) // Initial load
                    // No need to call loadFunctionAlbumAssociations or checkAlbumExistence here
                    // It's already handled in ContentView
                }
                //                .offset(x: -CGFloat(selectedIndex) * geometry.size.width)
//                .offset(x: -CGFloat(selectedIndex) * geometry.size.width + dragOffset)
                .offset(x: -CGFloat(selectedIndex) * geometry.size.width + dragState.translation.width + rubberBandOffset) // Include rubberBandOffset
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.15), value: selectedIndex) // Smooth snapping *always*
//                .animation(.easeInOut(duration: 0.3), value: selectedIndex) // ✅ Smooth animation when changing index
                .gesture(
                    DragGesture()
                        .updating($dragState, body: { (value, state, transaction) in
                            let translation = value.translation
                            state = .dragging(translation: translation)
                            if selectedIndex == 0 && translation.width > 0 || selectedIndex == assets.count - 1 && translation.width < 0 { // Rubber band effect
                                rubberBandOffset = translation.width * 0.3 // Adjust resistance factor (0.3)
                            } else {
                                rubberBandOffset = 0
                            }
                        })
                        .onEnded(onDragEnded)
                )

//                .gesture(
//                    DragGesture()
//                        .onChanged { value in
//                            // Disable implicit animations when tracking live drag
//                            withTransaction(Transaction(animation: nil)) {
//                                dragOffset = value.translation.width
//                            }
//                        }
//                        .onEnded { value in
//                            let threshold: CGFloat = 50
//                            
//                            //                            if value.translation.width > threshold, selectedIndex > 0 {
//                            //                                selectedIndex -= 1
//                            if value.translation.width > threshold {
//                                if selectedIndex > 0 {
//                                    withAnimation {
//                                        selectedIndex -= 1
//                                    }
//                                } else {
//                                    // Bounce effect when swiping right on first image
//                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
//                                        dragOffset = 20
//                                    }
//                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
//                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)) {
//                                            dragOffset = 0
//                                        }
//                                    }
//                                }
//                                
//                            } else if value.translation.width < -threshold, selectedIndex < assets.count - 1 {
//                                selectedIndex += 1
//                            }
//                            // Reset offset after swipe
//                            withAnimation {
//                                dragOffset = 0
//                            }
//                            // If swiping reaches the last image, load more
//                            if selectedIndex == assets.count - 1 {
//                                loadMoreAssets()
//                            }
//                        }
//                )
            }
            
            // ✅ Function Boxes (Only if a function is paired)
            if let fu1Album = pairedAlbums["Function 1"] { // Access through viewModel
                FunctionBox(
                    title: "Fu 1",
                    album: fu1Album?.localizedTitle,
                    position: .topLeading,
                    topOffsetPercentage: 10,
                    isPaired: isImagePaired(asset: assets[selectedIndex], with: fu1Album), // Pass isPaired
                    onTap: { togglePairing(asset: assets[selectedIndex], with: fu1Album, for: "Function 1") } // Pass onTap
                )
            }
            if let fu2Album = pairedAlbums["Function 2"] {
                FunctionBox(
                    title: "Fu 2",
                    album: fu2Album?.localizedTitle,
                    position: .topTrailing,
                    topOffsetPercentage: 10,
                    isPaired: isImagePaired(asset: assets[selectedIndex], with: fu2Album), // Pass isPaired
                    onTap: { togglePairing(asset: assets[selectedIndex], with: fu2Album, for: "Function 2") } // Pass onTap
                )
            }
            if let fu3Album = pairedAlbums["Function 3"] {
                FunctionBox(
                    title: "Fu 3",
                    album: fu3Album?.localizedTitle,
                    position: .bottomLeading,
                    bottomOffsetPercentage: 27,
                    isPaired: isImagePaired(asset: assets[selectedIndex], with: fu3Album), // Pass isPaired
                    onTap: { togglePairing(asset: assets[selectedIndex], with: fu3Album, for: "Function 3") } // Pass onTap
                )
            }
            if let fu4Album = pairedAlbums["Function 4"] {
                FunctionBox(
                    title: "Fu 4",
                    album: fu4Album?.localizedTitle,
                    position: .bottomTrailing,
                    bottomOffsetPercentage: 27,
                    isPaired: isImagePaired(asset: assets[selectedIndex], with: fu4Album), // Pass isPaired
                    onTap: { togglePairing(asset: assets[selectedIndex], with: fu4Album, for: "Function 4") } // Pass onTap
                )
            }
            
            Button(action: {
                onDismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
            }
            .position(x: 40, y: 60) // Adjust position as needed
        }
        .edgesIgnoringSafeArea(.all)

        .onAppear {
            loadHighResImage(index: selectedIndex, size: UIScreen.main.bounds.width) // Initial load
//            loadHighResImage(index: selectedIndex)
        }
    }

    private func onDragEnded(value: DragGesture.Value) {
        let threshold: CGFloat = 50
        let translation = value.translation

        if translation.width > threshold && selectedIndex > 0 {
            selectedIndex -= 1
        } else if translation.width < -threshold && selectedIndex < assets.count - 1 {
            selectedIndex += 1
        } else if selectedIndex == 0 && translation.width > 0 || selectedIndex == assets.count - 1 && translation.width < 0 { // Rubber band snap back
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2)) { // Correct: .spring directly
                rubberBandOffset = 0
            }
        } else { // Standard snap back
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.1)) { // Correct: .spring directly
                rubberBandOffset = 0 // Reset in all cases
            }
        }
    }
    
    func isImagePaired(asset: PHAsset, with album: PHAssetCollection?) -> Bool {
        guard let album = album else { return false }

        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier) // Fetch only the given asset

        let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions) // Fetch assets *in the album*

        return fetchResult.count > 0 // Check if the asset is in the album
    }

    func togglePairing(asset: PHAsset, with album: PHAssetCollection?, for function: String) {
        guard let album = album else { return }

        PHPhotoLibrary.shared().performChanges {
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier)
            let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)

            if fetchResult.count > 0 { // Asset is in the album (remove)
                let change = PHAssetCollectionChangeRequest(for: album)
                change?.removeAssets([asset] as NSArray) // Correct: [asset] is already an NSArray
                print("❌ Removed image from \(function) album.")
            } else { // Asset is NOT in the album (add)
                let change = PHAssetCollectionChangeRequest(for: album)
                let array = NSArray(array: [asset]) // Create NSArray *explicitly*
                change?.addAssets(array) // Use the explicitly created NSArray
                print("✅ Added image to \(function) album.")
            }
        } completionHandler: { success, error in
            if success {
                DispatchQueue.main.async {
                    self.viewModel.pairedAlbums[function] = album // Update on main thread
                }
            } else if let error = error {
                print("Error toggling pairing: \(error)")
                DispatchQueue.main.async {
                    // Handle error on main thread
                }
            }
        }
    }
    
    func loadImageIfNecessary(index: Int, size: CGFloat) {
         let asset = assets[index]

         // 1. Check if image is already loaded or loading
         if highResImages[index] != nil || imageLoadRequests[index] != nil {
             return // Already loaded or loading, do nothing
         }

         let targetSize = CGSize(width: size * UIScreen.main.scale, height: size * UIScreen.main.scale)
         let requestOptions = PHImageRequestOptions()
         requestOptions.isSynchronous = false
         requestOptions.deliveryMode = .highQualityFormat
         requestOptions.isNetworkAccessAllowed = true

         // 2. Store the request ID to cancel later if needed
         let requestID = imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { image, info in
             DispatchQueue.main.async {
                 if let image = image {
                     self.highResImages[index] = image
                     self.imageCache.setObject(image, forKey: asset)
                 } else if let error = info?[PHImageErrorKey] as? NSError, error.domain == "PHPhotosErrorDomain" && error.code == 3300 {
                     // Request was cancelled, do nothing
                 } else {
                     print("Error loading image: \(info ?? [:])")
                 }
                 self.imageLoadRequests.removeValue(forKey: index) // Remove request ID
             }
         }

         imageLoadRequests[index] = requestID // Store the request ID
     }

    func loadHighResImage(index: Int, size: CGFloat) { // Added size parameter
        let asset = assets[index]

        if let cachedImage = imageCache.object(forKey: asset) {
            highResImages[index] = cachedImage
            return
        }

        let targetSize = CGSize(width: size * UIScreen.main.scale, height: size * UIScreen.main.scale) // Use passed size
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true

        let requestID = imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.highResImages[index] = image
                    self.imageCache.setObject(image, forKey: asset) // Cache the image
                }
            }
        }

        // Store requestID in the view's tag for cancellation
        // Find the correct image view (if it exists) and set the tag
        // This part is tricky and might require adjustments depending on your view hierarchy
        // For now, I'm assuming the images are direct children of the HStack
    }
}
    
//    func loadHighResImage(index: Int) {
//        let asset = assets[index]
//        let targetSize = PHImageManagerMaximumSize
//        let requestOptions = PHImageRequestOptions()
//        requestOptions.isSynchronous = false
//        requestOptions.deliveryMode = .highQualityFormat
//        requestOptions.isNetworkAccessAllowed = true
//
//        // ✅ Allow image request to proceed, but only update the state if the image is missing.
//        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
//            if let image = image {
//                DispatchQueue.main.async {
//                    if self.highResImages[index] == nil { // ✅ Only update if missing
//                        self.highResImages[index] = image
//                    }
//                }
//            }
//        }
//    }



struct FunctionBox: View {
    let title: String
    let album: String?
    let position: Alignment
    let topOffsetPercentage: CGFloat // Percentage from the top (0-100)
    let bottomOffsetPercentage: CGFloat // Percentage from the bottom (0-100)
    let isPaired: Bool // Add isPaired property
    let onTap: () -> Void // Add onTap closure

    init(
        title: String,
        album: String?,
        position: Alignment,
        topOffsetPercentage: CGFloat = 10,
        bottomOffsetPercentage: CGFloat = 10,
        isPaired: Bool, // isPaired *after* other properties
        onTap: @escaping () -> Void // onTap after isPaired in init
    ) {
        self.title = title
        self.album = album
        self.position = position
        self.topOffsetPercentage = topOffsetPercentage
        self.bottomOffsetPercentage = bottomOffsetPercentage
        self.isPaired = isPaired
        self.onTap = onTap
    }
    
    
    var body: some View {
        GeometryReader { geometry in  // GeometryReader *outside* the Text
            let truncatedAlbum = truncateAlbumName(album ?? "Not Set", maxLength: 16)

            HStack { // Embed in HStack for emoji
                Text("\(title): \(truncatedAlbum)")
                    .font(.system(size: 16))
                Image(systemName: isPaired ? "circle.fill" : "circle") // Green or red circle
                    .foregroundColor(isPaired ? .green : .red)
                    .imageScale(.small)
            }
                .padding(12)
                .background(Color.black.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: position)
                .offset(y: {
                    switch position {
                    case .topLeading, .topTrailing:
                        return geometry.size.height * (topOffsetPercentage / 100)
                    case .bottomLeading, .bottomTrailing:
                        return geometry.size.height * (1 - (bottomOffsetPercentage / 100)) // Corrected: Use negative offset to move up from bottom
                    default:
                        return 0
                    }
                }())
        } // End of GeometryReader
        .frame(maxWidth: .infinity) // Ensure the GeometryReader takes full width
        .onTapGesture { // Add tap gesture
            onTap()
        }
    }
    
}
