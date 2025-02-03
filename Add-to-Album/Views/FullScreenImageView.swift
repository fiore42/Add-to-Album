import SwiftUI
import Photos

struct FullScreenImageView: View, Identifiable {
    let id = UUID()
    
    let selectedAsset: PHAsset
    let allAssets: [PHAsset]
    let displayedAssets: [PHAsset]
    
    let onLoadMore: () -> Void
    let onDismiss: () -> Void
    
    // We rely on the environment object for album associations
    @EnvironmentObject var albumManager: AlbumAssociationManager
    
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var highResCache: [String: UIImage] = [:]
    @State private var pendingRequests: [Int: PHImageRequestID] = [:]
    @State private var hasRequestedMore = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                HStack(spacing: 0) {
                    ForEach(allAssets.indices, id: \.self) { idx in
                        ZStack {
                            ProgressView("Loading...")
                                .frame(width: geo.size.width, height: geo.size.height)
                                .background(Color.black)
                                .onAppear {
                                    preloadAround(index: idx, containerWidth: geo.size.width)
                                }
                                .onDisappear {
                                    cancelLoad(forIndex: idx)
                                }
                            
                            if let uiImage = highResCache[allAssets[idx].localIdentifier] {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width, height: geo.size.height)
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
                .offset(x: -CGFloat(currentIndex) * geo.size.width + dragOffset)
                .animation(.interactiveSpring(), value: currentIndex)
                .animation(.interactiveSpring(), value: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.width
                            if (currentIndex == 0 && translation > 0) ||
                               (currentIndex == allAssets.count - 1 && translation < 0) {
                                dragOffset = translation * 0.3
                            } else {
                                dragOffset = translation
                            }
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            let translation = value.translation.width
                            if translation < -threshold, currentIndex < allAssets.count - 1 {
                                currentIndex += 1
                            } else if translation > threshold, currentIndex > 0 {
                                currentIndex -= 1
                            }
                            dragOffset = 0
                            handleIndexChanged()
                        }
                )
                
                cornerOverlays(geo: geo)
                
                // Dismiss button
                Button(action: { onDismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
                .position(x: 40, y: 60)
            }
            .onAppear {
                if let startIndex = allAssets.firstIndex(of: selectedAsset) {
                    currentIndex = startIndex
                    preloadAround(index: startIndex, containerWidth: geo.size.width)
                }
            }
        }
    }
    
    private func handleIndexChanged() {
        // If we're near the end of displayedAssets, load more
        if currentIndex > displayedAssets.count - 5, !hasRequestedMore {
            hasRequestedMore = true
            onLoadMore()
        }
        // Preload neighbors
        preloadAround(index: currentIndex, containerWidth: UIScreen.main.bounds.width)
    }
    
    // MARK: - Preload
    private func preloadAround(index: Int, containerWidth: CGFloat) {
        let neighbors = [index - 1, index, index + 1]
        for i in neighbors {
            guard i >= 0 && i < allAssets.count else { continue }
            requestHighResIfNeeded(index: i, containerWidth: containerWidth)
        }
    }
    
    private func requestHighResIfNeeded(index i: Int, containerWidth: CGFloat) {
        let asset = allAssets[i]
        if highResCache[asset.localIdentifier] != nil ||
           pendingRequests[i] != nil {
            return
        }
        
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: containerWidth * scale, height: containerWidth * scale)
        
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        let reqID = PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            DispatchQueue.main.async {
                self.pendingRequests.removeValue(forKey: i)
                
                guard let img = image else { return }
                self.highResCache[asset.localIdentifier] = img
            }
        }
        
        pendingRequests[i] = reqID
    }
    
    private func cancelLoad(forIndex i: Int) {
        if let reqID = pendingRequests[i] {
            PHImageManager.default().cancelImageRequest(reqID)
            pendingRequests.removeValue(forKey: i)
        }
    }
    
    // MARK: - Overlays
    @ViewBuilder
    private func cornerOverlays(geo: GeometryProxy) -> some View {
        // Hard-coded mapping from "Function 1" -> position, "Function 2" -> position, etc.
        // or do something more flexible.
        let corners: [String: (x: CGFloat, y: CGFloat)] = [
            "Function 1": (20 + geo.safeAreaInsets.leading,  20 + geo.safeAreaInsets.top),
            "Function 2": (geo.size.width - 20 - geo.safeAreaInsets.trailing, 20 + geo.safeAreaInsets.top),
            "Function 3": (20 + geo.safeAreaInsets.leading,  geo.size.height - 20 - geo.safeAreaInsets.bottom),
            "Function 4": (geo.size.width - 20 - geo.safeAreaInsets.trailing, geo.size.height - 20 - geo.safeAreaInsets.bottom)
        ]
        
        ForEach(corners.keys.sorted(), id: \.self) { fn in
            if let album = albumManager.pairedAlbums[fn] {
                let pos = corners[fn]!
                let isPaired = isCurrentAssetIn(album: album)
                
                FunctionBox(
                    title: shortName(fn),
                    album: album?.localizedTitle,
                    isPaired: isPaired,
                    onTap: {
                        toggleAssetIn(album: album, function: fn)
                    }
                )
                .position(x: pos.x, y: pos.y)
            }
        }
    }
    
    private func shortName(_ long: String) -> String {
        switch long {
        case "Function 1": return "Fu 1"
        case "Function 2": return "Fu 2"
        case "Function 3": return "Fu 3"
        case "Function 4": return "Fu 4"
        default: return long
        }
    }
    
    private func isCurrentAssetIn(album: PHAssetCollection?) -> Bool {
        guard let album = album else { return false }
        let asset = allAssets[currentIndex]
        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier)
        let res = PHAsset.fetchAssets(in: album, options: opts)
        return (res.count > 0)
    }
    
    private func toggleAssetIn(album: PHAssetCollection?, function: String) {
        guard let album = album else { return }
        let asset = allAssets[currentIndex]
        
        PHPhotoLibrary.shared().performChanges({
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier)
            let existing = PHAsset.fetchAssets(in: album, options: fetchOptions)
            
            let cr = PHAssetCollectionChangeRequest(for: album)
            if existing.count > 0 {
                cr?.removeAssets([asset] as NSArray)
            } else {
                cr?.addAssets([asset] as NSArray)
            }
        }, completionHandler: { success, error in
            if success {
                print("✅ Toggled asset in \(function).")
            } else if let err = error {
                print("🚫 Error toggling: \(err.localizedDescription)")
            }
        })
    }
}
