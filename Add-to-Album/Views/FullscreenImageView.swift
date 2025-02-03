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
                    Image(uiImage: leftImage ?? UIImage()) // ✅ Ensure placeholder instead of blank
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()

                    Image(uiImage: currentImage ?? UIImage()) // ✅ Ensure placeholder instead of blank
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()

                    Image(uiImage: rightImage ?? UIImage()) // ✅ Ensure placeholder instead of blank
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .offset(x: -CGFloat(selectedImageIndex) * geometry.size.width + dragTranslation.width)
                .animation(.interactiveSpring(), value: selectedImageIndex)

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
//                    .onEnded { value in
//                        handleSwipe(value: value, screenWidth: geometry.size.width)
//                    }
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
                loadImages()
            }
            .onChange(of: selectedImageIndex) { oldValue, newValue in
                Logger.log("[🔄 onChange] Old Index: \(oldValue), New Index: \(newValue)")
                loadImages()
            }

        } // End of GeometryReader
    }

    func getImage(for index: Int) -> UIImage? {
        if let cachedImage = imageCache[index] {
            return cachedImage // ✅ Load from cache if available
        }
        loadImageIfNeeded(for: index) // ✅ Request image asynchronously
        return nil // ✅ Prevents crash, returns black placeholder
    }

    private func loadImageIfNeeded(for index: Int) {
        guard imageCache[index] == nil else { return } // ✅ Prevent reloading

        let asset = imageAssets[index]
        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    imageCache[index] = image
                }
            }
        }
    }

    
    private func handleSwipe(value: DragGesture.Value, screenWidth: CGFloat) {
        let threshold = screenWidth / 3

        if value.translation.width > threshold && selectedImageIndex > 0 {
            Logger.log("[⬅️ Swiped Left] Moving to index \(selectedImageIndex - 1)")
            selectedImageIndex -= 1 // Update the index *before* loading images
            loadImages()
        } else if value.translation.width < -threshold && selectedImageIndex < imageAssets.count - 1 {
            Logger.log("[➡️ Swiped Right] Moving to index \(selectedImageIndex + 1)")
            selectedImageIndex += 1 // Update the index *before* loading images
            loadImages()
        } else {
            // Do *not* set dragTranslation here. Let the gesture end.
            Logger.log("[🔄 Cancel Swipe] Returning to index \(selectedImageIndex)")
            withAnimation(.interactiveSpring()) {
                // If you have other view properties you need to reset as part of the "cancel" animation,
                // do it here.  For example, if you had a scale effect:
                // scale = 1.0  // Example
            }
        }
    }

    private func loadImages() {
        guard !loadingIndices.contains(selectedImageIndex) else {
            Logger.log("[⚠️ loadImages] Skipping duplicate load for index: \(selectedImageIndex)")
            return
        }
        
        Logger.log("[📸 loadImages] selectedImageIndex: \(selectedImageIndex), total assets: \(imageAssets.count)")
        loadingIndices.insert(selectedImageIndex) // ✅ Mark as in-progress

        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        // ✅ Load current image
        if currentImage == nil {
            Logger.log("[🔵 Current Image] Loading image at index \(selectedImageIndex)")
            loadImage(for: imageAssets[selectedImageIndex], targetSize: targetSize, options: options) { image in
                DispatchQueue.main.async {
                    self.currentImage = image
                    self.imageLoadState = .loaded
                    self.loadingIndices.remove(selectedImageIndex)
                    Logger.log("[✅ Loaded Current Image] Index: \(selectedImageIndex)")
                }
            }
        }

        // ✅ Preload left image if available
        let leftIndex = selectedImageIndex > 0 ? selectedImageIndex - 1 : nil
        if let leftIndex = leftIndex, leftImage == nil {
            Logger.log("[⬅️ Left Image] Preloading image at index \(leftIndex)")
            loadImage(for: imageAssets[leftIndex], targetSize: targetSize, options: options) { image in
                DispatchQueue.main.async {
                    self.leftImage = image
                    Logger.log("[✅ Loaded Left Image] Index: \(leftIndex)")
                }
            }
        }

        // ✅ Preload right image if available
        let rightIndex = selectedImageIndex < imageAssets.count - 1 ? selectedImageIndex + 1 : nil
        if let rightIndex = rightIndex, rightImage == nil {
            Logger.log("[➡️ Right Image] Preloading image at index \(rightIndex)")
            loadImage(for: imageAssets[rightIndex], targetSize: targetSize, options: options) { image in
                DispatchQueue.main.async {
                    self.rightImage = image
                    Logger.log("[✅ Loaded Right Image] Index: \(rightIndex)")
                }
            }
        }
    }


    private func loadImage(for asset: PHAsset, targetSize: CGSize, options: PHImageRequestOptions, completion: @escaping (UIImage?) -> Void) {
        Logger.log("[🖼 Requesting Image] Asset LocalIdentifier: \(asset.localIdentifier)")
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
            if let image = image {
                Logger.log("[✅ Image Loaded Successfully]")
            } else {
                Logger.log("[❌ Image Load Failed]")
            }
            completion(image)
        }
    }


    private func showNextImage() {
        if selectedImageIndex < imageAssets.count - 1 {
            selectedImageIndex += 1
            loadImages()
        } else {
            bounceBack()
        }
    }

    private func showPreviousImage() {
        if selectedImageIndex > 0 {
            selectedImageIndex -= 1
            loadImages()
        } else {
            bounceBack()
        }
    }

    private func bounceBack() {
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
            // Animate any *other* properties that need to bounce
            // For example, if you had a 'scale' property:
            // scale = scale > 1 ? 1.1 : 0.9 // Example bounce scale
        }
        // Do *not* attempt to set dragTranslation here.
    }
}
