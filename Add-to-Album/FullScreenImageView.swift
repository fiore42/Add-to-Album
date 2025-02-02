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
    /// Cache for already loaded images.
    @State private var highResImages: [Int: UIImage] = [:]
    /// In-flight image request IDs.
    @State private var imageLoadRequests: [Int: PHImageRequestID] = [:]
    
    /// Binding for the paired album dictionary.
    @Binding var pairedAlbums: [String: PHAssetCollection?]
    /// Called when a new batch of assets should be loaded.
    let loadMoreAssets: () -> Void
    /// Called to dismiss this view.
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
                
                // MARK: - Paging Content
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
                                        loadImageIfNeeded(for: index, containerWidth: geometry.size.width)
                                    }
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        // Cancel any in‑flight requests when a page goes offscreen.
                        .onDisappear {
                            cancelLoad(for: index)
                        }
                    }
                }
                // Compute the horizontal offset for paging.
                .offset(x: -CGFloat(selectedIndex) * geometry.size.width + dragOffset)
                .animation(.interactiveSpring(), value: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.width
                            // If at the first image dragging right or at the last dragging left, dampen the movement.
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
                            
                            // If we are within 5 images of the end, load more.
                            if newIndex > assets.count - 5 {
                                loadMoreAssets()
                            }
                        }
                )
                
                // MARK: - Function Boxes
                // The function boxes are now simply overlaid using absolute alignment.
                if let fu1Album = pairedAlbums["Function 1"] {
                    FunctionBox(
                        title: "Fu 1",
                        album: fu1Album?.localizedTitle,
                        isPaired: FunctionBox.isImagePaired(asset: assets[selectedIndex], with: fu1Album),
                        onTap: {
                            FunctionBox.togglePairing(asset: assets[selectedIndex], with: fu1Album, for: "Function 1")
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.top, 40)
                    .padding(.leading, 20)
                }
                if let fu2Album = pairedAlbums["Function 2"] {
                    FunctionBox(
                        title: "Fu 2",
                        album: fu2Album?.localizedTitle,
                        isPaired: FunctionBox.isImagePaired(asset: assets[selectedIndex], with: fu2Album),
                        onTap: {
                            FunctionBox.togglePairing(asset: assets[selectedIndex], with: fu2Album, for: "Function 2")
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 40)
                    .padding(.trailing, 20)
                }
                if let fu3Album = pairedAlbums["Function 3"] {
                    FunctionBox(
                        title: "Fu 3",
                        album: fu3Album?.localizedTitle,
                        isPaired: FunctionBox.isImagePaired(asset: assets[selectedIndex], with: fu3Album),
                        onTap: {
                            FunctionBox.togglePairing(asset: assets[selectedIndex], with: fu3Album, for: "Function 3")
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.bottom, 40)
                    .padding(.leading, 20)
                }
                if let fu4Album = pairedAlbums["Function 4"] {
                    FunctionBox(
                        title: "Fu 4",
                        album: fu4Album?.localizedTitle,
                        isPaired: FunctionBox.isImagePaired(asset: assets[selectedIndex], with: fu4Album),
                        onTap: {
                            FunctionBox.togglePairing(asset: assets[selectedIndex], with: fu4Album, for: "Function 4")
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.bottom, 40)
                    .padding(.trailing, 20)
                }
                
                // Dismiss/back button.
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                }
                .position(x: 40, y: 60)
            }
            .edgesIgnoringSafeArea(.all)
            // Ensure the current image is loaded on appear.
            .onAppear {
                loadImageIfNeeded(for: selectedIndex, containerWidth: geometry.size.width)
            }
        }
    }
    
    // MARK: - Image Loading Helpers
    
    /// Request the image for the given index if it isn’t already loaded.
    private func loadImageIfNeeded(for index: Int, containerWidth: CGFloat) {
        guard index < assets.count else { return }
        let asset = assets[index]
        
        if highResImages[index] != nil || imageLoadRequests[index] != nil {
            return
        }
        
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
                    // Cancellation errors are expected when the request is no longer needed.
                } else {
                    print("Error loading image at index \(index): \(info ?? [:])")
                }
                self.imageLoadRequests.removeValue(forKey: index)
            }
        }
        imageLoadRequests[index] = requestID
    }
    
    /// Cancel any in-flight request for the image at the given index.
    private func cancelLoad(for index: Int) {
        if let requestID = imageLoadRequests[index] {
            imageManager.cancelImageRequest(requestID)
            imageLoadRequests.removeValue(forKey: index)
        }
    }
}
