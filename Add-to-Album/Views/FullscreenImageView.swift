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
    @State private var dragOffset: CGFloat = 0
    @GestureState private var dragTranslation: CGSize = .zero
    @Environment(\.dismiss) var dismiss

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                // Display images side by side for natural swipe transition
                HStack(spacing: 0) {
                    if let leftImage = leftImage {
                        Image(uiImage: leftImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .offset(x: -geometry.size.width + dragOffset + dragTranslation.width)
                    }
                    
                    if let currentImage = currentImage {
                        Image(uiImage: currentImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .offset(x: dragOffset + dragTranslation.width)
                    }

                    if let rightImage = rightImage {
                        Image(uiImage: rightImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .offset(x: geometry.size.width + dragOffset + dragTranslation.width)
                    }
                }

                // Black separator between images during swipe
                if dragTranslation.width != 0 {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 20, height: geometry.size.height)
                        .offset(x: dragTranslation.width > 0 ? dragTranslation.width - 20 : dragTranslation.width + 20)
                }

                // Back button in the top left
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .gesture(
                DragGesture()
                    .updating($dragTranslation) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        handleSwipe(value: value, screenWidth: geometry.size.width)
                    }
            )
            .onAppear { loadImages() }
            .onChange(of: selectedImageIndex) { _ in loadImages() }
        }
    }

    /// **Handles swipe gesture ending**
    private func handleSwipe(value: DragGesture.Value, screenWidth: CGFloat) {
        let threshold = screenWidth / 3

        if value.translation.width > threshold {
            showPreviousImage()
        } else if value.translation.width < -threshold {
            showNextImage()
        } else {
            withAnimation(.interactiveSpring()) {
                dragOffset = 0
            }
        }
    }

    /// **Loads the main and adjacent images**
    private func loadImages() {
        loadImage(for: imageAssets[selectedImageIndex]) { image in
            currentImage = image
        }

        let leftIndex = max(0, selectedImageIndex - 1)
        if leftIndex != selectedImageIndex {
            loadImage(for: imageAssets[leftIndex]) { image in
                leftImage = image
            }
        } else {
            leftImage = nil
        }

        let rightIndex = min(imageAssets.count - 1, selectedImageIndex + 1)
        if rightIndex != selectedImageIndex {
            loadImage(for: imageAssets[rightIndex]) { image in
                rightImage = image
            }
        } else {
            rightImage = nil
        }
    }

    /// **Loads an image and ensures correct aspect ratio**
    private func loadImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    /// **Handles swipe left (next image) with smooth transition**
    private func showNextImage() {
        if selectedImageIndex < imageAssets.count - 1 {
            withAnimation(.easeInOut(duration: 0.4)) {
                dragOffset = -UIScreen.main.bounds.width
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                selectedImageIndex += 1
                dragOffset = 0
            }
        } else {
            bounceBack()
        }
    }

    /// **Handles swipe right (previous image) with smooth transition**
    private func showPreviousImage() {
        if selectedImageIndex > 0 {
            withAnimation(.easeInOut(duration: 0.4)) {
                dragOffset = UIScreen.main.bounds.width
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                selectedImageIndex -= 1
                dragOffset = 0
            }
        } else {
            bounceBack()
        }
    }

    /// **Creates a bounce effect when swiping beyond the first/last image**
    private func bounceBack() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            dragOffset = (dragOffset > 0) ? 50 : -50
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
            dragOffset = 0
        }
    }
}
