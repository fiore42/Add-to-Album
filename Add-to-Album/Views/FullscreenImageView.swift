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
    @GestureState private var dragState: CGSize = .zero
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let currentImage = currentImage {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Image(uiImage: currentImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()

                        if let nextImage = getNextImage() {
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 20) // 20px vertical black separator
                            
                            Image(uiImage: nextImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        }
                    }
                    .offset(x: dragOffset + dragState.width)
                    .gesture(
                        DragGesture()
                            .updating($dragState) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                handleSwipe(value: value)
                            }
                    )
                }
            } else {
                ProgressView()
                    .foregroundColor(.white)
            }

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
        .onAppear { loadImages() }
        .onChange(of: selectedImageIndex) { _ in loadImages() }
    }

    /// **Determines the next image for transition**
    private func getNextImage() -> UIImage? {
        if dragOffset < 0 {
            return rightImage // Swiping left, so show right image
        } else if dragOffset > 0 {
            return leftImage // Swiping right, so show left image
        }
        return nil
    }

    /// **Handles swipe gesture ending**
    private func handleSwipe(value: DragGesture.Value) {
        let screenWidth = UIScreen.main.bounds.width
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
            withAnimation {
                currentImage = image
            }
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

    /// **Handles swipe left (next image) with bounce effect**
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

    /// **Handles swipe right (previous image) with bounce effect**
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
