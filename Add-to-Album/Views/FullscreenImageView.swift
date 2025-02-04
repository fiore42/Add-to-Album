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
    @State private var imageLoadState: ImageLoadState = .loading // Track image loading state
    @GestureState private var dragTranslation: CGSize = .zero
    @Environment(\.dismiss) var dismiss
    @State private var loadingIndices: Set<Int> = [] // ✅ Track in-progress image loads
    @State private var imageCache: [Int: UIImage] = [:] // ✅ Stores loaded images

    enum ImageLoadState {
        case loading, loaded
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                HStack(spacing: 0) {
                    ForEach(imageAssets.indices, id: \.self) { index in
                        if let image = getImage(for: index, geometry: geometry) { // Pass geometry here!
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        } else {
                            Color.black // Placeholder to prevent gaps
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
                .offset(x: -CGFloat(selectedImageIndex) * geometry.size.width + dragTranslation.width)
                .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: selectedImageIndex)

                // Black separator
                if dragTranslation != .zero { // Only show when dragging
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 20, height: geometry.size.height)
                        .offset(x: dragTranslation.width > 0 ? dragTranslation.width - 20 : dragTranslation.width + 20)
                        .animation(.interactiveSpring(), value: dragTranslation)
                }
                
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
                imageCache.removeAll() // ✅ Clear the cache when reopening fullscreen

                // ✅ Force a re-selection update to trigger `onChange`
                let tempIndex = selectedImageIndex
                selectedImageIndex = -1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    selectedImageIndex = tempIndex
                    loadImages(geometry: geometry) // ✅ Only call loadImages after restoring index
                }
            }
            
            .onChange(of: selectedImageIndex) { oldValue, newValue in
                Logger.log("[🔄 onChange] Old Index: \(oldValue), New Index: \(newValue)")
                loadImages(geometry: geometry)
            }

        } // End of GeometryReader
    }

    func getImage(for index: Int, geometry: GeometryProxy) -> UIImage? { // Add geometry parameter
// check cache first, if not in cache, load image
        if let cachedImage = imageCache[index] {
            return cachedImage // ✅ Load from cache if available
        }
        loadImageIfNeeded(for: index, geometry: geometry) // Pass geometry here!
        return nil // ✅ Prevents crash, returns black placeholder
    }

    private func loadImageIfNeeded(for index: Int, geometry: GeometryProxy) { // Add geometry parameter
        guard imageCache[index] == nil else { return } // ✅ Prevent reloading

        let asset = imageAssets[index]
        let targetSize = CGSize(width: geometry.size.width * 1.2, height: geometry.size.height * 1.2)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat // Load a fast preview first
        options.resizeMode = .fast // Prioritize speed over quality

        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    imageCache[index] = image
                }
            }
        }
    }

    private func loadImages(geometry: GeometryProxy) {
        guard imageCache[selectedImageIndex] == nil else {
            Logger.log("[⚠️ loadImages] Image already cached for index: \(selectedImageIndex)")
            return
        }
        
        // ✅ Prevent out-of-bounds access
        guard selectedImageIndex >= 0, selectedImageIndex < imageAssets.count else {
            Logger.log("[⚠️ loadImages] Skipped due to invalid index: \(selectedImageIndex)")
            return
        }

        Logger.log("[📸 loadImages] selectedImageIndex: \(selectedImageIndex), total assets: \(imageAssets.count)")
        loadingIndices.insert(selectedImageIndex)

        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat // Load a fast preview first
        options.resizeMode = .fast // Prioritize speed over quality
        
        let currentIndex = selectedImageIndex // Capture the *current* selectedImageIndex

        Logger.log("[🔵 Current Image] Loading image at index \(currentIndex)") // Use captured index
        loadImage(for: imageAssets[currentIndex], geometry: geometry, targetSize: targetSize, options: options) { image in // Pass geometry here
            DispatchQueue.main.async {
                self.loadingIndices.remove(currentIndex) // Remove using the captured index

                guard let image = image else {
                    Logger.log("[❌ Failed to load image for index: \(currentIndex)]") // Use captured index
                    return
                }

                if self.selectedImageIndex == currentIndex { // Compare with *current* selectedImageIndex
                    self.currentImage = image
                    self.imageLoadState = .loaded
                    self.imageCache[currentIndex] = image // Cache using captured index
                    Logger.log("[✅ Loaded Image] Index: \(currentIndex)") // Use captured index
                } else {
                    Logger.log("[⚠️ Skipped outdated image load for index: \(currentIndex)]") // Use captured index
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
