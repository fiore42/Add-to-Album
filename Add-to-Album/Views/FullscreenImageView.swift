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

    enum ImageLoadState {
        case loading, loaded
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                HStack(spacing: 0) {
                    if let leftImage = leftImage {
                        Image(uiImage: leftImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    
                    if let currentImage = currentImage {
                        Image(uiImage: currentImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    
                    if let rightImage = rightImage {
                        Image(uiImage: rightImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                }
                .offset(x: dragTranslation.width) // Use dragTranslation directly
                .animation(.interactiveSpring(), value: dragTranslation) // Animate with dragTranslation
                
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
                        handleSwipe(value: value, screenWidth: geometry.size.width)
                    }
            )
            .onAppear {
                // No loadImages() call here
            }
            .onChange(of: selectedImageIndex) { oldValue, newValue in
                loadImages()
            }
        } // End of GeometryReader
    }


    private func handleSwipe(value: DragGesture.Value, screenWidth: CGFloat) {
        let threshold = screenWidth / 3

        if value.translation.width > threshold && selectedImageIndex > 0 {
            selectedImageIndex -= 1 // Update the index *before* loading images
            loadImages()
        } else if value.translation.width < -threshold && selectedImageIndex < imageAssets.count - 1 {
            selectedImageIndex += 1 // Update the index *before* loading images
            loadImages()
        } else {
            // Do *not* set dragTranslation here. Let the gesture end.
            withAnimation(.interactiveSpring()) {
                // If you have other view properties you need to reset as part of the "cancel" animation,
                // do it here.  For example, if you had a scale effect:
                // scale = 1.0  // Example
            }
        }
    }

    private func loadImages() {
        imageLoadState = .loading // Set loading state

        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        let currentIndex = selectedImageIndex // Ensure we capture the correct index before async execution
        loadImage(for: imageAssets[currentIndex], targetSize: targetSize, options: options) { image in
            DispatchQueue.main.async {
                if selectedImageIndex == currentIndex { // ✅ Ensure we set the correct image
                    currentImage = image
                    imageLoadState = .loaded // Set loaded state
                }
            }
        }


        let leftIndex = selectedImageIndex > 0 ? selectedImageIndex - 1 : nil
        leftImage = nil // Clear previous left image
        if let leftIndex = leftIndex {
            loadImage(for: imageAssets[leftIndex], targetSize: targetSize, options: options) { image in
                DispatchQueue.main.async {
                    leftImage = image
                }
            }
        }

        let rightIndex = selectedImageIndex < imageAssets.count - 1 ? selectedImageIndex + 1 : nil
        rightImage = nil // Clear previous right image
        if let rightIndex = rightIndex {
            loadImage(for: imageAssets[rightIndex], targetSize: targetSize, options: options) { image in
                DispatchQueue.main.async {
                    rightImage = image
                }
            }
        }
    }

    private func loadImage(for asset: PHAsset, targetSize: CGSize, options: PHImageRequestOptions, completion: @escaping (UIImage?) -> Void) {
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
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
