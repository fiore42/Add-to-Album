import SwiftUI
import PhotosUI
import Foundation

struct FullScreenImageView: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: ViewModel
    
    let assets: [PHAsset]
    let imageManager: PHImageManager
    
    @State private var selectedIndex: Int
    @State private var dragOffset: CGFloat = 0
    @State private var highResImages: [Int: UIImage] = [:]
    @State private var imageLoadRequests: [Int: PHImageRequestID] = [:]
    @State private var refreshToggle: Bool = false
    
    @Binding var pairedAlbums: [String: PHAssetCollection?]
    let loadMoreAssets: () -> Void
    let onDismiss: () -> Void
    
    let imageCache = NSCache<PHAsset, UIImage>()
    
    // MARK: - Init
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
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // The swiping/paging stack
                HStack(spacing: 0) {
                    ForEach(assets.indices, id: \.self) { index in
                        ZStack {
                            if let image = highResImages[index] {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .background(Color.black)
                            } else {
                                ProgressView("Loading...")
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .background(Color.black)
                                    .onAppear {
                                        loadImageIfNeeded(for: index, containerWidth: geometry.size.width)
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
                            
                            // If near the end, load next batch
                            if newIndex > assets.count - 5 {
                                loadMoreAssets()
                            }
                        }
                )
                
                // Function boxes
                VStack {
                    
                    // Add a spacer to push the top row to about 10% from top
                    Spacer()
                        .frame(height: geometry.size.height * 0.1)
                    
                    // Top row: Fu1 / Fu2
                    HStack {
                        // Fu1 (left side)
                        boxForFunction(
                            function: "Function 1",
                            shortName: "Fu 1",
                            asset: assets[selectedIndex]
                        )
                        
                        Spacer()
                        
                        // Fu2 (right side)
                        boxForFunction(
                            function: "Function 2",
                            shortName: "Fu 2",
                            asset: assets[selectedIndex]
                        )
                    }
                    
                    Spacer()
                    
                    // Bottom row: Fu3 / Fu4
                    HStack {
                        // Fu3 (left side)
                        boxForFunction(
                            function: "Function 3",
                            shortName: "Fu 3",
                            asset: assets[selectedIndex]
                        )
                        
                        Spacer()
                        
                        // Fu4 (right side)
                        boxForFunction(
                            function: "Function 4",
                            shortName: "Fu 4",
                            asset: assets[selectedIndex]
                        )
                    }
                    
                    // Add a spacer to push bottom row ~10% from bottom
                    Spacer()
                        .frame(height: geometry.size.height * 0.1)
                }
                .id(refreshToggle)
                .padding(.horizontal, 20) // adjust as needed
                
                // Dismiss button - top left
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
                .position(x: 40, y: 60)
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                loadImageIfNeeded(for: selectedIndex, containerWidth: geometry.size.width)
            }
        }
    }
    
    // MARK: - Helper for Fu Boxes
    /// Returns either a `FunctionBox` if the album is set, or a fallback "Not Paired" box.
    private func boxForFunction(function: String, shortName: String, asset: PHAsset) -> some View {
        if let album = pairedAlbums[function] ?? nil {
            return AnyView(
                FunctionBox(
                    title: shortName,
                    album: album.localizedTitle,
                    isPaired: FunctionBox.isImagePaired(asset: asset, with: album),
                    onTap: {
                        togglePairing(for: function, asset: asset, album: album)
                    }
                )
            )
        } else {
            // Fallback if we have no album set
            return AnyView(
                Text("\(shortName): Not Paired")
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
            )
        }
    }
    
    // MARK: - Toggle Pairing
    private func togglePairing(for function: String, asset: PHAsset, album: PHAssetCollection?) {
        guard let album = album else { return }
        
        PHPhotoLibrary.shared().performChanges({
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier)
            let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
            
            let changeRequest = PHAssetCollectionChangeRequest(for: album)
            
            if fetchResult.count > 0 {
                changeRequest?.removeAssets([asset] as NSArray)
                print("Removed asset from \(function)")
            } else {
                changeRequest?.addAssets([asset] as NSArray)
                print("Added asset to \(function)")
            }
        }, completionHandler: { success, error in
            if success {
                DispatchQueue.main.async {
                    refreshToggle.toggle() // Forces the function boxes to refresh
                }
            } else if let error = error {
                print("Error toggling pairing for \(function): \(error)")
            }
        })
    }
    
    // MARK: - Image Loading
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
        
        let requestID = imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            DispatchQueue.main.async {
                if let image = image {
                    self.highResImages[index] = image
                    self.imageCache.setObject(image, forKey: asset)
                } else if let error = info?[PHImageErrorKey] as? NSError,
                          error.domain == "PHPhotosErrorDomain", error.code == 3072 {
                    // Request was cancelled (quick swipes)
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
