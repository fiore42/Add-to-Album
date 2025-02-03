import SwiftUI
import Photos

struct FullscreenImageView: View {
    @Binding var isPresented: Bool
    @Binding var selectedImageIndex: Int
    let imageAssets: [PHAsset]
    private let imageManager = PHImageManager.default()

    @State private var currentImage: UIImage?
    @State private var nextImage: UIImage?
    @State private var dragOffset: CGFloat = 0
    @State private var isSwiping = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let currentImage = currentImage {
                GeometryReader { geometry in
                    ZStack {
                        Image(uiImage: currentImage)
                            .resizable()
                            .scaledToFit()
                            .offset(x: dragOffset)
                        
                        if let nextImage = nextImage {
                            Image(uiImage: nextImage)
                                .resizable()
                                .scaledToFit()
                                .offset(x: dragOffset > 0 ? -geometry.size.width + dragOffset : geometry.size.width + dragOffset)
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 100
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
                    )
                }
            } else {
                ProgressView()
                    .foregroundColor(.white)
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear { loadImages() }
    }

    private func loadImages() {
        loadImage(for: imageAssets[selectedImageIndex]) { image in
            withAnimation {
                currentImage = image
            }
        }
        preloadNextImage()
    }

    private func loadImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    private func preloadNextImage() {
        guard selectedImageIndex < imageAssets.count - 1 else {
            nextImage = nil
            return
        }
        loadImage(for: imageAssets[selectedImageIndex + 1]) { image in
            nextImage = image
        }
    }

    private func showPreviousImage() {
        if selectedImageIndex > 0 {
            withAnimation(.easeInOut(duration: 0.4)) {
                selectedImageIndex -= 1
                swap(&currentImage, &nextImage)
                dragOffset = UIScreen.main.bounds.width
            }
            preloadNextImage()
            withAnimation(.spring()) {
                dragOffset = 0
            }
        } else {
            // Bounce effect when swiping beyond the first image
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2)) {
                dragOffset = 50
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.2)) {
                dragOffset = 0
            }
        }
    }

    private func showNextImage() {
        if selectedImageIndex < imageAssets.count - 1 {
            withAnimation(.easeInOut(duration: 0.4)) {
                selectedImageIndex += 1
                swap(&currentImage, &nextImage)
                dragOffset = -UIScreen.main.bounds.width
            }
            preloadNextImage()
            withAnimation(.spring()) {
                dragOffset = 0
            }
        } else {
            // Bounce effect when swiping beyond the last image
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2)) {
                dragOffset = -50
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.2)) {
                dragOffset = 0
            }
        }
    }
}
