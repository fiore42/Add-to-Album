import SwiftUI
import PhotosUI
import Foundation

// MARK: - FullScreenImageView

struct FullScreenImageView: View {
    // We still observe the view model for things like pairedAlbums,
    // but we use the passed-in assets array for the swipe content.
    @ObservedObject var viewModel: ViewModel

    /// The array of assets used for swiping.
    let assets: [PHAsset]
    let imageManager: PHImageManager

    /// Index of the currently visible image.
    @State private var selectedIndex: Int

    /// Dictionary mapping an index to its high-resolution UIImage.
    @State private var highResImages: [Int: UIImage] = [:]

    /// A temporary offset added during the drag (for rubber-banding).
    @State private var rubberBandOffset: CGFloat = 0

    /// A binding to the paired albums (you might later move the function logic out).
    @Binding var pairedAlbums: [String: PHAssetCollection?]

    /// Closure to load more assets.
    let loadMoreAssets: () -> Void

    /// Closure called on dismiss.
    let onDismiss: () -> Void

    /// A simple image cache.
    let imageCache = NSCache<PHAsset, UIImage>()

    /// Dictionary tracking in-flight image requests.
    @State private var imageLoadRequests: [Int: PHImageRequestID] = [:]

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

    // MARK: - Drag State

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
    }
    @GestureState private var dragState = DragState.inactive

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(assets.indices, id: \.self) { index in
                        // Wrap each image in its own container.
                        HStack(spacing: 0) {
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
                                        }
                                }
                            }
                            // A vertical barrier between images.
                            if index < assets.count - 1 {
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: 2, height: geometry.size.height)
                            }
                        }
                        .frame(width: geometry.size.width)
                        .onAppear {
                            loadImageIfNecessary(index: index, size: geometry.size.width)
                        }
                        .onDisappear {
                            cancelLoad(for: index)
                        }
                    }
                }
                // The offset calculation uses the selected index, current drag translation, and any rubber band offset.
                .offset(
                    x: -CGFloat(selectedIndex) * geometry.size.width
                        + dragState.translation.width
                        + rubberBandOffset
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.15), value: selectedIndex)
                .gesture(
                    DragGesture()
                        .updating($dragState) { value, state, _ in
                            let translation = value.translation
                            state = .dragging(translation: translation)
                            
                            // If at either end, apply a rubber band effect.
                            if (selectedIndex == 0 && translation.width > 0) ||
                                (selectedIndex == assets.count - 1 && translation.width < 0) {
                                rubberBandOffset = translation.width * 0.3
                            } else {
                                rubberBandOffset = 0
                            }
                        }
                        .onEnded(onDragEnded)
                )
                .onChange(of: selectedIndex) { newValue in
                    // If we are near the end of the current batch, trigger a load of more assets.
                    if newValue > assets.count - 5 {
                        loadMoreAssets()
                    }
                }
            }

            // MARK: - Function Boxes
            // These boxes remain over the image.
            if let fu1Album = pairedAlbums["Function 1"] {
                FunctionBox(
                    title: "Fu 1",
                    album: fu1Album?.localizedTitle,
                    position: .topLeading,
                    topOffsetPercentage: 10,
                    isPaired: isImagePaired(asset: assets[selectedIndex], with: fu1Album),
                    onTap: {
                        togglePairing(asset: assets[selectedIndex], with: fu1Album, for: "Function 1")
                    }
                )
            }
            if let fu2Album = pairedAlbums["Function 2"] {
                FunctionBox(
                    title: "Fu 2",
                    album: fu2Album?.localizedTitle,
                    position: .topTrailing,
                    topOffsetPercentage: 10,
                    isPaired: isImagePaired(asset: assets[selectedIndex], with: fu2Album),
                    onTap: {
                        togglePairing(asset: assets[selectedIndex], with: fu2Album, for: "Function 2")
                    }
                )
            }
            if let fu3Album = pairedAlbums["Function 3"] {
                FunctionBox(
                    title: "Fu 3",
                    album: fu3Album?.localizedTitle,
                    position: .bottomLeading,
                    bottomOffsetPercentage: 27,
                    isPaired: isImagePaired(asset: assets[selectedIndex], with: fu3Album),
                    onTap: {
                        togglePairing(asset: assets[selectedIndex], with: fu3Album, for: "Function 3")
                    }
                )
            }
            if let fu4Album = pairedAlbums["Function 4"] {
                FunctionBox(
                    title: "Fu 4",
                    album: fu4Album?.localizedTitle,
                    position: .bottomTrailing,
                    bottomOffsetPercentage: 27,
                    isPaired: isImagePaired(asset: assets[selectedIndex], with: fu4Album),
                    onTap: {
                        togglePairing(asset: assets[selectedIndex], with: fu4Album, for: "Function 4")
                    }
                )
            }

            // A dismiss/back button.
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
            }
            .position(x: 40, y: 60)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            loadImageIfNecessary(index: selectedIndex, size: UIScreen.main.bounds.width)
        }
    }

    // MARK: - Drag Handling

    private func onDragEnded(value: DragGesture.Value) {
        let threshold: CGFloat = 50
        let translation = value.translation

        if translation.width > threshold && selectedIndex > 0 {
            selectedIndex -= 1
        } else if translation.width < -threshold && selectedIndex < assets.count - 1 {
            selectedIndex += 1
        }
        // Snap back the rubber band effect.
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.1)) {
            rubberBandOffset = 0
        }
    }

    // MARK: - Function-Button Helpers

    /// Check if an asset is contained in the given album.
    func isImagePaired(asset: PHAsset, with album: PHAssetCollection?) -> Bool {
        guard let album = album else { return false }
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier)
        let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
        return fetchResult.count > 0
    }

    /// Toggle whether the asset is paired with the given album.
    func togglePairing(asset: PHAsset, with album: PHAssetCollection?, for function: String) {
        guard let album = album else { return }
        PHPhotoLibrary.shared().performChanges({
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier)
            let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
            if fetchResult.count > 0 {
                // Remove asset.
                let change = PHAssetCollectionChangeRequest(for: album)
                change?.removeAssets([asset] as NSArray)
                print("❌ Removed image from \(function) album.")
            } else {
                // Add asset.
                let change = PHAssetCollectionChangeRequest(for: album)
                change?.addAssets(NSArray(array: [asset]))
                print("✅ Added image to \(function) album.")
            }
        }) { success, error in
            if success {
                // Update the binding directly.
                DispatchQueue.main.async {
                    self.pairedAlbums[function] = album
                }
            } else if let error = error {
                print("Error toggling pairing: \(error)")
            }
        }
    }

    // MARK: - Image Loading

    func loadImageIfNecessary(index: Int, size: CGFloat) {
        let asset = assets[index]
        // If the image is already loaded or is being loaded, do nothing.
        if highResImages[index] != nil || imageLoadRequests[index] != nil {
            return
        }
        let targetSize = CGSize(width: size * UIScreen.main.scale, height: size * UIScreen.main.scale)
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true

        let requestID = imageManager.requestImage(for: asset,
                                                  targetSize: targetSize,
                                                  contentMode: .aspectFit,
                                                  options: requestOptions) { image, info in
            DispatchQueue.main.async {
                if let image = image {
                    self.highResImages[index] = image
                    self.imageCache.setObject(image, forKey: asset)
                } else if let error = info?[PHImageErrorKey] as? NSError,
                          error.domain == "PHPhotosErrorDomain", error.code == 3300 {
                    // Request was cancelled.
                } else {
                    print("Error loading image: \(info ?? [:])")
                }
                self.imageLoadRequests.removeValue(forKey: index)
            }
        }
        imageLoadRequests[index] = requestID
    }

    func cancelLoad(for index: Int) {
        if let requestID = imageLoadRequests[index] {
            imageManager.cancelImageRequest(requestID)
            imageLoadRequests.removeValue(forKey: index)
        }
    }
}
