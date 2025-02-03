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
    @GestureState private var dragState = DragState.inactive
    @Environment(\.dismiss) var dismiss

    enum DragState {
        case inactive
        case dragging(translation: CGSize)

        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }

        var isDragging: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
    }

    var body: some View {
        NavigationView {
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

                            if let nextImage = nextImage {
                                Image(uiImage: nextImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                            }
                        }
                        .offset(x: dragState.translation.width)
                        .animation(.interactiveSpring(), value: dragState.isDragging)
                    }
                } else {
                    ProgressView()
                        .foregroundColor(.white)
                }

                // Separator during swipe
                if dragState.isDragging {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 20, height: UIScreen.main.bounds.height) // Adjust height as needed
                        .offset(x: (dragState.translation.width > 0) ? dragState.translation.width - 20 : dragState.translation.width + 20)
                        .animation(.interactiveSpring(), value: dragState.isDragging)
                }

                VStack {
                    HStack {
                        Button(action: { dismiss() }) { // Use dismiss
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.leading, 20)
                .allowsHitTesting(false) // Prevent interaction with the button while dragging
            }
            .gesture(
                DragGesture()
                    .updating($dragState, body: { (value, state, transaction) in
                        state = .dragging(translation: value.translation)
                    })
                    .onEnded(onDragEnded)
            )
            .onAppear { loadImages() }
            .onChange(of: selectedImageIndex) { _ in loadImages() }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    private func onDragEnded(value: DragGesture.Value) {
        let screenWidth = UIScreen.main.bounds.width
        let threshold = screenWidth / 3

        if value.translation.width > threshold && selectedImageIndex > 0 {
            showPreviousImage()
        } else if value.translation.width < -threshold && selectedImageIndex < imageAssets.count - 1 {
            showNextImage()
        } else {
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
                dragOffset = 0
            }
        }
    }

    private func loadImages() {
        loadImage(for: imageAssets[selectedImageIndex]) { image in
            withAnimation { currentImage = image }
        }

        // Preload left and right images (up to 3 in memory)
        let leftIndex = max(0, selectedImageIndex - 1)
        if leftIndex != selectedImageIndex {
            loadImage(for: imageAssets[leftIndex]) { image in
                // Store left image (you'll need a way to manage this)
            }
        }

        let rightIndex = min(imageAssets.count - 1, selectedImageIndex + 1)
        if rightIndex != selectedImageIndex {
            loadImage(for: imageAssets[rightIndex]) { image in
                nextImage = image // Right image is the next image
            }
        }
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

    private func showPreviousImage() {
        if selectedImageIndex > 0 {
            selectedImageIndex -= 1
            loadImages()
        } else {
            bounceBack()
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

    private func bounceBack() {
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
            dragOffset = (dragOffset > 0) ? 50 : -50
        }
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.2)) {
            dragOffset = 0
        }
    }
}
