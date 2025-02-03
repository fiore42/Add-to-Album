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
                            if (selectedIndex == 0 && translation > 0) || (selectedIndex == assets.count - 1 && translation < 0) {
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
                
                // Function Boxes - Absolute Positioning

                // Top Left
                if let album1 = pairedAlbums["Function 1"] {
                    FunctionBox(
                        title: "Fu 1",
                        album: album1?.localizedTitle ?? "Unknown",
                        isPaired: FunctionBox.isImagePaired(asset: assets[selectedIndex], with: album1),
                        onTap: { togglePairing(for: "Function 1", asset: assets[selectedIndex], album: album1) }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading) // Align to the left
//                    .position(x: 20 + geometry.safeAreaInsets.leading, y: 20 + geometry.safeAreaInsets.top)
                    .position(
                        x: 20 + geometry.safeAreaInsets.leading,
                        y: geometry.size.height * (10 / 100) // Adjust this percentage
                    )
                }
                
                // Top Right
                if let album2 = pairedAlbums["Function 2"] {
                    FunctionBox(
                        title: "Fu 2",
                        album: album2?.localizedTitle ?? "Unknown",
                        isPaired: FunctionBox.isImagePaired(asset: assets[selectedIndex], with: album2),
                        onTap: { togglePairing(for: "Function 2", asset: assets[selectedIndex], album: album2) }
                    )
                    .position(x: geometry.size.width - 20 - geometry.safeAreaInsets.trailing, y: 20 + geometry.safeAreaInsets.top)
                }
                
                // Bottom Left
                if let album3 = pairedAlbums["Function 3"] {
                    FunctionBox(
                        title: "Fu 3",
                        album: album3?.localizedTitle ?? "Unknown",
                        isPaired: FunctionBox.isImagePaired(asset: assets[selectedIndex], with: album3),
                        onTap: { togglePairing(for: "Function 3", asset: assets[selectedIndex], album: album3) }
                    )
                    .position(x: 20 + geometry.safeAreaInsets.leading, y: geometry.size.height - 20 - geometry.safeAreaInsets.bottom)
                }
                
                // Bottom Right
                if let album4 = pairedAlbums["Function 4"] {
                    FunctionBox(
                        title: "Fu 4",
                        album: album4?.localizedTitle ?? "Unknown",
                        isPaired: FunctionBox.isImagePaired(asset: assets[selectedIndex], with: album4),
                        onTap: { togglePairing(for: "Function 4", asset: assets[selectedIndex], album: album4) }
                    )
                    .position(x: geometry.size.width - 20 - geometry.safeAreaInsets.trailing, y: geometry.size.height - 20 - geometry.safeAreaInsets.bottom)
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
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                loadImageIfNeeded(for: selectedIndex, containerWidth: geometry.size.width)
            }
        }
    }
    
    // MARK: - Toggle Pairing
    
    private func togglePairing(for function: String, asset: PHAsset, album: PHAssetCollection?) {
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
