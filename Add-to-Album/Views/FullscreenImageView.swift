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
                        HStack(spacing: 0) { // Use HStack for smooth transition
                            Image(uiImage: currentImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height) // Fill screen
                                .clipped()
                            if let nextImage = nextImage {
                                Image(uiImage: nextImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height) // Fill screen
                                    .clipped()
                            }
                        }
                        .offset(x: dragState.translation.width) // Apply drag offset
                        .animation(.interactiveSpring(), value: dragState.isDragging) // Smooth animation
                    }
                } else {
                    ProgressView()
                        .foregroundColor(.white)
                }

                VStack {
                    HStack {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "chevron.left") // Back button
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 20) // Adjust top padding as needed
                .padding(.leading, 20)

            }
            .gesture(
                DragGesture()
                    .updating($dragState, body: { (value, state, transaction) in
                        state = .dragging(translation: value.translation)
                    })
                    .onEnded(onDragEnded)
            )
            .onAppear { loadImages() }
            .onChange(of: selectedImageIndex) { _ in loadImages() } // Load on index change
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    private func onDragEnded(value: DragGesture.Value) {
        let threshold: CGFloat = UIScreen.main.bounds.width / 3 // Adjust threshold

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

        // Preload next image (if available)
        if selectedImageIndex < imageAssets.count - 1 {
            loadImage(for: imageAssets[selectedImageIndex + 1]) { image in
                nextImage = image
            }
        } else {
            nextImage = nil
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
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
                dragOffset = 50 // Bounce effect
            }
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.2)) {
                dragOffset = 0
            }

        }
    }

    private func showNextImage() {
        if selectedImageIndex < imageAssets.count - 1 {
            selectedImageIndex += 1
            loadImages()
        } else {
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
                dragOffset = -50 // Bounce effect
            }
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.2)) {
                dragOffset = 0
            }
        }
    }
}
