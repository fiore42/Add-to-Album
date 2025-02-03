import SwiftUI
import PhotosUI
import Foundation

struct FullScreenImageView: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: ViewModel
    /// The array of assets to page through.
    let assets: [PHAsset]
    let imageManager: PHImageManager
    
    /// The currently visible index.
    @State private var selectedIndex: Int
    /// The current drag offset.
    @State private var dragOffset: CGFloat = 0
    /// Cache for loaded high‑resolution images.
    @State private var highResImages: [Int: UIImage] = [:]
    /// In‑flight image request IDs.
    @State private var imageLoadRequests: [Int: PHImageRequestID] = [:]
    /// A dummy state variable to force a UI refresh after pairing changes.
    @State private var refreshToggle: Bool = false
    
    /// Binding for the paired albums dictionary.
    @Binding var pairedAlbums: [String: PHAssetCollection?]
    /// Closure called when a new batch of assets should be loaded.
    let loadMoreAssets: () -> Void
    /// Closure called to dismiss this view.
    let onDismiss: () -> Void
    
    /// A simple image cache.
    let imageCache = NSCache<PHAsset, UIImage>()
    
    // MARK: - Initializer
    
    init(
        viewModel: ViewModel,
        assets: [PHAsset],
        imageManager: PHImageManager,
        selectedIndex: Int,
        pairedAlbums: Binding<[String: PHAssetCollection?]>,
        loadMoreAssets: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.assets = assets
        self.imageManager = imageManager
        self._selectedIndex = State(initialValue: selectedIndex)
        self._pairedAlbums = pairedAlbums
        self.loadMoreAssets = loadMoreAssets
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Paging Content
                HStack(spacing: 0) {
                    ForEach(assets.indices, id: \.self) { index in
                        ZStack {
                            if let image = highResImages[index] {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width,
                                           height: geometry.size.height)
                                    .background(Color.black)
                            } else {
                                ProgressView("Loading...")
                                    .frame(width: geometry.size.width,
                                           height: geometry.size.height)
                                    .background(Color.black)
                                    .onAppear {
                                        loadImageIfNeeded(for: index,
                                                          containerWidth: geometry.size.width)
                                    }
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .onDisappear {
                            cancelLoad(for: index)
                        }
                    }
                }
                .offset(x: -CGFloat(selectedIndex) * geometry.size.width + dragOffset)
                .animation(.interactiveSpring(), value: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.width
                            // Damp the drag when at the boundaries.
                            if (selectedIndex == 0 && translation > 0) ||
                                (selectedIndex == assets.count - 1 && translation < 0) {
                                dragOffset = translation * 0.3
                            } else {
                                dragOffset = translation
                            }
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            let translation = value.translation.width
                            var newIndex = selectedIndex
                            if translation < -threshold, selectedIndex < assets.count - 1 {
                                newIndex += 1
                            } else if translation > threshold, selectedIndex > 0 {
                                newIndex -= 1
                            }
                            withAnimation(.interactiveSpring()) {
                                selectedIndex = newIndex
                                dragOffset = 0
                            }
                            if newIndex > assets.count - 5 {
                                loadMoreAssets()
                            }
                        }
                )

                // ✅ Function Boxes (Only if a function is paired)
                if let fu1Album = pairedAlbums["Function 1"] { // Access through viewModel
                          FunctionBox(
                                    title: "Fu 1",
                                    album: fu1Album?.localizedTitle,
                                    position: .topLeading,
                                    topOffsetPercentage: 10,
                                    isPaired: FunctionBox.isImagePaired(asset: assets[selectedIndex], with: fu1Album), // Pass isPaired
                                    onTap: {
                                        togglePairing(for: "Function 1", asset: assets[selectedIndex], album: fu1Album)
                                    } // Pass onTap
                          )
                }
                if let fu2Album = pairedAlbums["Function 2"] {
                          FunctionBox(
                                    title: "Fu 2",
                                    album: fu2Album?.localizedTitle,
                                    position: .topTrailing,
                                    topOffsetPercentage: 10,
                                    isPaired: FunctionBox.isImagePaired(asset: assets[selectedIndex], with: fu2Album), // Pass isPaired
                                    onTap: {
                                        togglePairing(for: "Function 2", asset: assets[selectedIndex], album: fu2Album)
                                    } // Pass onTap
                          )
                }
                if let fu3Album = pairedAlbums["Function 3"] {
                          FunctionBox(
                                    title: "Fu 3",
                                    album: fu3Album?.localizedTitle,
                                    position: .bottomLeading,
                                    bottomOffsetPercentage: 27,
                                    isPaired: FunctionBox.isImagePaired(asset: assets[selectedIndex], with: fu3Album), // Pass isPaired
                                    onTap: {
                                        togglePairing(for: "Function 3", asset: assets[selectedIndex], album: fu3Album)
                                    } // Pass onTap
                          )
                }
                if let fu4Album = pairedAlbums["Function 4"] {
                          FunctionBox(
                                    title: "Fu 4",
                                    album: fu4Album?.localizedTitle,
                                    position: .bottomTrailing,
                                    bottomOffsetPercentage: 27,
                                    isPaired: FunctionBox.isImagePaired(asset: assets[selectedIndex], with: fu4Album), // Pass isPaired
                                    onTap: {
                                        togglePairing(for: "Function 4", asset: assets[selectedIndex], album: fu4Album)
                                    } // Pass onTap

                          )
                }
                
                // Dismiss Button
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                }
                .position(x: 40, y: 60)
            }




            .id(refreshToggle) // Toggling this forces the overlay to refresh.
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                loadImageIfNeeded(for: selectedIndex, containerWidth: geometry.size.width)
            }
        }
    }
    
    // MARK: - Toggle Pairing
    
    /// Performs the pairing toggle and then forces a UI refresh.
    private func togglePairing(for function: String,
                                 asset: PHAsset,
                                 album: PHAssetCollection?) {
        guard let album = album else { return }
        PHPhotoLibrary.shared().performChanges({
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier)
            let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
            if fetchResult.count > 0 {
                let changeRequest = PHAssetCollectionChangeRequest(for: album)
                changeRequest?.removeAssets([asset] as NSArray)
                print("Removed asset from \(function)")
            } else {
                let changeRequest = PHAssetCollectionChangeRequest(for: album)
                changeRequest?.addAssets([asset] as NSArray)
                print("Added asset to \(function)")
            }
        }, completionHandler: { success, error in
            if success {
                DispatchQueue.main.async {
                    refreshToggle.toggle()
                }
            } else if let error = error {
                print("Error toggling pairing for \(function): \(error)")
            }
        })
    }
    
    // MARK: - Image Loading Helpers
    
    private func loadImageIfNeeded(for index: Int, containerWidth: CGFloat) {
        guard index < assets.count else { return }
        let asset = assets[index]
        if highResImages[index] != nil || imageLoadRequests[index] != nil { return }
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: containerWidth * scale, height: containerWidth * scale)
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        let requestID = imageManager.requestImage(for: asset,
                                                  targetSize: targetSize,
                                                  contentMode: .aspectFit,
                                                  options: options) { image, info in
            DispatchQueue.main.async {
                if let image = image {
                    self.highResImages[index] = image
                    self.imageCache.setObject(image, forKey: asset)
                } else if let error = info?[PHImageErrorKey] as? NSError,
                          error.domain == "PHPhotosErrorDomain", error.code == 3072 {
                    // Request cancelled (expected when scrolling quickly)
                } else {
                    print("Error loading image at index \(index): \(info ?? [:])")
                }
                self.imageLoadRequests.removeValue(forKey: index)
            }
        }
        imageLoadRequests[index] = requestID
    }
    
    private func cancelLoad(for index: Int) {
        if let requestID = imageLoadRequests[index] {
            imageManager.cancelImageRequest(requestID)
            imageLoadRequests.removeValue(forKey: index)
        }
    }
}
