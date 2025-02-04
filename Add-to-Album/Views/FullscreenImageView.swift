import SwiftUI
import Photos

struct FullscreenImageView: View {
    @Binding var isPresented: Bool
    @Binding var selectedImageIndex: Int
    let imageAssets: [PHAsset]
    private let imageManager = PHImageManager.default()

    @State private var currentImage: UIImage?
    @State private var leftImage: UIImage?
    @State private var rightImage: UIImage?
//    @State private var imageLoadState: ImageLoadState = .loading // Track image loading state
    @State private var imageLoadState: ImageLoadState = .idle
    @GestureState private var dragTranslation: CGSize = .zero
    @Environment(\.dismiss) var dismiss
//    @State private var loadingIndices: Set<Int> = [] // ✅ Track in-progress image loads
    @State private var loadingIndices = Set<Int>() // Track loading indices

    @State private var imageCache: [Int: UIImage] = [:] // ✅ Stores loaded images
    @State private var showingFullScreenImage = false

    enum ImageLoadState {
        case idle, loading, loaded, failed
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                HStack(spacing: 0) {
                    ForEach(imageAssets.indices, id: \.self) { index in
                        Image(uiImage: getImage(for: index, geometry: geometry) ?? UIImage()) // Use placeholder
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .onTapGesture {
                                showingFullScreenImage = true // Toggle the state
                                loadImages(geometry: geometry) // Reload with correct target size
                            }
                    }
                }
                .offset(x: -CGFloat(selectedImageIndex) * geometry.size.width + dragTranslation.width) // Offset with drag
                .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: selectedImageIndex)

                // Back button
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.leading, 20)

                // Loading indicator (center of the screen)
                if imageLoadState == .loading {
                    ProgressView()
                        .progressViewStyle(.circular) // Or your preferred style
                        .scaleEffect(1.5) // Make it a bit larger
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Center it
                }
                if imageLoadState == .failed && currentImage == nil {
                    Text("Image failed to load").foregroundColor(.white)
                }


            } // End of ZStack
            .gesture(
                DragGesture()
                    .updating($dragTranslation, body: { value, state, _ in
                        state = value.translation
                    })
                    .onEnded { value in
                        let threshold = geometry.size.width / 3
                        let dragAmount = value.translation.width

                        withAnimation(.interactiveSpring()) {
                            if dragAmount > threshold, selectedImageIndex > 0 {
                                selectedImageIndex -= 1
                            } else if dragAmount < -threshold, selectedImageIndex < imageAssets.count - 1 {
                                selectedImageIndex += 1
                            }
                        }
                    }
            )
            .onAppear {
                Logger.log("[🟢 onAppear] selectedImageIndex: \(selectedImageIndex)")
                imageCache.removeAll() // Clear the cache when reopening fullscreen

                // ✅ Force a re-selection update to trigger `onChange`
                let tempIndex = selectedImageIndex
                selectedImageIndex = -1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    selectedImageIndex = tempIndex
                    loadImages(geometry: geometry) // ✅ Only call loadImages after restoring index
                }
            }
            .onChange(of: selectedImageIndex) { oldValue, newValue in
                guard newValue >= 0 && newValue < imageAssets.count else {
                    Logger.log("[⚠️ onChange] Invalid index: \(newValue), skipping")
                    return // Don't do anything if the index is invalid
                }
                let preloadThreshold = 5 // Load 5 images ahead
                let loadMoreIndex = newValue + preloadThreshold

                if loadMoreIndex < imageAssets.count && loadMoreIndex >= 0 {
                    Logger.log("[✅ onChange] calling loadImageIfNeeded: \(loadMoreIndex)")
                    loadImageIfNeeded(for: loadMoreIndex, geometry: geometry)
                }
            }
        } // End of GeometryReader
    }
    
    private func getImage(for index: Int, geometry: GeometryProxy) -> UIImage? {
        if let cachedImage = imageCache[index] {
            return cachedImage
        }
        loadImageIfNeeded(for: index, geometry: geometry)
        return nil
    }

    private func loadImageIfNeeded(for index: Int, geometry: GeometryProxy) {
            guard index >= 0, index < imageAssets.count, imageCache[index] == nil, !loadingIndices.contains(index) else { return }

            loadingIndices.insert(index)

            let asset = imageAssets[index]
            let targetSize = CGSize(width: geometry.size.width * 1.2, height: geometry.size.height * 1.2)
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact

            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
                // ***FIX: Update state on the main thread***
                DispatchQueue.main.async {
                    self.loadingIndices.remove(index)
                    if let image = image {
                        self.imageCache[index] = image
                        if self.selectedImageIndex == index {
                            self.currentImage = image // Correctly updating State
                            self.imageLoadState = .loaded // Correctly updating State
                        }
                    } else {
                        self.imageLoadState = .failed // Correctly updating State if the image fails to load
                    }
                }
            }
        }

    private func loadImages(geometry: GeometryProxy) {
            let currentIndex = selectedImageIndex

            guard !loadingIndices.contains(currentIndex), currentIndex >= 0, currentIndex < imageAssets.count else {
                Logger.log("[⚠️ loadImages] Skipped: Already loading or invalid index: \(currentIndex)")
                return
            }

            let isFullScreen = showingFullScreenImage

            let targetSize: CGSize
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true

            if isFullScreen {
                targetSize = CGSize(width: geometry.size.width * 1.2, height: geometry.size.height * 1.2)
                options.deliveryMode = .highQualityFormat
            } else {
                let thumbnailSize = CGSize(width: 200, height: 200)
                targetSize = thumbnailSize
                options.deliveryMode = .fastFormat
            }

            if let cachedImage = imageCache[currentIndex], isFullScreen == (cachedImage.size != targetSize) {
                Logger.log("[⚠️ loadImages] Image already cached for index: \(currentIndex), using cached image")
                DispatchQueue.main.async {
                    self.currentImage = cachedImage
                    self.imageLoadState = .loaded
                }
                return
            }

            Logger.log("[📸 loadImages] selectedImageIndex: \(currentIndex), total assets: \(imageAssets.count)")
            loadingIndices.insert(currentIndex)
            imageLoadState = .loading

            Logger.log("[🔵 Current Image] Loading image at index \(currentIndex)")
            loadImage(for: imageAssets[currentIndex], geometry: geometry, targetSize: targetSize, options: options) { image in
                DispatchQueue.main.async {
                    self.loadingIndices.remove(currentIndex)

                    guard let image = image else {
                        Logger.log("[❌ Failed to load image for index: \(currentIndex)]")
                        self.imageLoadState = .failed
                        return
                    }

                    if self.selectedImageIndex == currentIndex {
                        self.currentImage = image
                        self.imageCache[currentIndex] = image
                        self.imageLoadState = .loaded
                        Logger.log("[✅ Loaded Image] Index: \(currentIndex)")
                    } else {
                        Logger.log("[⚠️ Skipped outdated image load for index: \(currentIndex)]")
                    }
                }
            }
        }


    private func loadImage(for asset: PHAsset, geometry: GeometryProxy, targetSize: CGSize, options: PHImageRequestOptions, completion: @escaping (UIImage?) -> Void) {

            let initialSize = CGSize(width: geometry.size.width * 0.5, height: geometry.size.height * 0.5) // Fast load
            let fullSize = CGSize(width: geometry.size.width * 1.2, height: geometry.size.height * 1.2) // Full quality

            Logger.log("[🖼 Fast Requesting Image] \(asset.localIdentifier), Target: \(initialSize)")

            
            let options = PHImageRequestOptions()
            options.isSynchronous = false // ✅ Async request
            options.deliveryMode = .fastFormat // ✅ Prioritize speed
            options.resizeMode = .fast // ✅ Load lower quality first
            options.isNetworkAccessAllowed = true
            

            imageManager.requestImage(for: asset, targetSize: initialSize, contentMode: .aspectFit, options: options) { fastImage, _ in
                if let fastImage = fastImage {
                    DispatchQueue.main.async {
                        completion(fastImage) // ✅ Show fast version first
                    }
                }

                // ✅ Now request full-size image in the background
                let fullOptions = PHImageRequestOptions()
                fullOptions.isSynchronous = false
                fullOptions.deliveryMode = .highQualityFormat // High quality
                fullOptions.isNetworkAccessAllowed = false // No iCloud

                Logger.log("[🖼 HQ Requesting Image] \(asset.localIdentifier), Target: \(fullSize)")

                imageManager.requestImage(for: asset, targetSize: fullSize, contentMode: .aspectFit, options: fullOptions) { fullImage, _ in
                    if let fullImage = fullImage {
                        DispatchQueue.main.async {
                            completion(fullImage) // ✅ Replace with high-quality image
                        }
                    }
                }
            }
        }



}
