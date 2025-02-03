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
    @State private var imageAspectRatio: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let currentImage = currentImage {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        if selectedImageIndex > 0, let leftImage = leftImage {
                            Image(uiImage: leftImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                        
                        Image(uiImage: currentImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)

                        if selectedImageIndex < imageAssets.count - 1, let rightImage = rightImage {
                            Image(uiImage: rightImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded(onDragEnded)
                    )
                }
            } else {
                ProgressView()
                    .foregroundColor(.white)
            }

            // **Black Separator During Swipe**
            if dragOffset != 0 {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 20, height: UIScreen.main.bounds.height)
                    .offset(x: dragOffset > 0 ? dragOffset - 20 : dragOffset + 20)
            }

            // **Back Button**
            VStack {
                HStack {
                    Button(action: { isPresented = false }) {
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

    /// **Handles swipe gesture end logic**
    private func onDragEnded(value: DragGesture.Value) {
        let screenWidth = UIScreen.main.bounds.width
        let threshold = screenWidth / 3

        if value.translation.width > threshold {
            showPreviousImage()
        } else if value.translation.width < -threshold {
            showNextImage()
        } else {
            withAnimation(.spring()) {
                dragOffset = 0
            }
        }
    }

    /// **Loads the main and adjacent high-res images**
    private func loadImages() {
        loadImage(for: imageAssets[selectedImageIndex]) { image, aspectRatio in
            withAnimation {
                currentImage = image
                imageAspectRatio = aspectRatio
            }
        }

        // Preload left image if available
        if selectedImageIndex > 0 {
            loadImage(for: imageAssets[selectedImageIndex - 1]) { image, _ in
                leftImage = image
            }
        } else {
            leftImage = nil
        }

        // Preload right image if available
        if selectedImageIndex < imageAssets.count - 1 {
            loadImage(for: imageAssets[selectedImageIndex + 1]) { image, _ in
                rightImage = image
            }
        } else {
            rightImage = nil
        }
    }

    /// **Loads an image and returns its aspect ratio**
    private func loadImage(for asset: PHAsset, completion: @escaping (UIImage?, CGFloat) -> Void) {
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
                guard let image = image else {
                    completion(nil, 1.0)
                    return
                }
                let aspectRatio = image.size.width / image.size.height
                completion(image, aspectRatio)
            }
        }
    }

    /// **Handles swipe to the previous image with bounce effect**
    private func showPreviousImage() {
        if selectedImageIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedImageIndex -= 1
            }
            loadImages()
        } else {
            bounceBack()
        }
    }

    /// **Handles swipe to the next image with bounce effect**
    private func showNextImage() {
        if selectedImageIndex < imageAssets.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedImageIndex += 1
            }
            loadImages()
        } else {
            bounceBack()
        }
    }

    /// **Creates a bounce effect when swiping beyond limits**
    private func bounceBack() {
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
            dragOffset = (dragOffset > 0) ? 50 : -50
        }
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
            dragOffset = 0
        }
    }
}
