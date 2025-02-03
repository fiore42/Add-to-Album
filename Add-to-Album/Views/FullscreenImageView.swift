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
    @State private var isSwiping = false // To control animations

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = currentImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity) // Smooth transition effect
            } else {
                ProgressView()
                    .foregroundColor(.white)
            }

            HStack {
                if leftImage != nil {
                    Image(uiImage: leftImage!)
                        .resizable()
                        .scaledToFit()
                        .opacity(0.5) // Show next/prev images as faded previews
                        .frame(width: 50, height: 50)
                        .onTapGesture { showPreviousImage() }
                }
                Spacer()
                if rightImage != nil {
                    Image(uiImage: rightImage!)
                        .resizable()
                        .scaledToFit()
                        .opacity(0.5)
                        .frame(width: 50, height: 50)
                        .onTapGesture { showNextImage() }
                }
            }
            .padding()

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
        .gesture(
            DragGesture()
                .onEnded { value in
                    let translation = value.translation.width
                    let threshold: CGFloat = 100 // More natural swipe threshold

                    if translation > threshold {
                        showPreviousImage()
                    } else if translation < -threshold {
                        showNextImage()
                    }
                }
        )
        .onChange(of: selectedImageIndex) { _ in loadImages() }
        .onAppear { loadImages() }
    }

    // Loads the main image and adjacent images
    private func loadImages() {
        loadImage(for: imageAssets[selectedImageIndex]) { image in
            withAnimation {
                currentImage = image
            }
        }
        loadAdjacentImages()
    }

    // Loads a high-res image for current index
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

    // Loads left & right images to speed up swiping
    private func loadAdjacentImages() {
        let targetSize = CGSize(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.height / 2)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic

        if selectedImageIndex > 0 {
            imageManager.requestImage(for: imageAssets[selectedImageIndex - 1], targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
                DispatchQueue.main.async { leftImage = image }
            }
        } else { leftImage = nil }

        if selectedImageIndex < imageAssets.count - 1 {
            imageManager.requestImage(for: imageAssets[selectedImageIndex + 1], targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
                DispatchQueue.main.async { rightImage = image }
            }
        } else { rightImage = nil }
    }

    // Moves to the previous image
    private func showPreviousImage() {
        guard selectedImageIndex > 0 else { return }
        isSwiping = true
        selectedImageIndex -= 1
    }

    // Moves to the next image
    private func showNextImage() {
        guard selectedImageIndex < imageAssets.count - 1 else { return }
        isSwiping = true
        selectedImageIndex += 1
    }
}
