import SwiftUI
import Photos

struct FullscreenImageView: View {
    @Binding var isPresented: Bool
    @Binding var selectedImageIndex: Int
    let imageAssets: [PHAsset]
    private let imageManager = PHImageManager.default()

    @State private var currentImage: UIImage?
    @State private var nextImage: UIImage?
    @State private var previousImage: UIImage? // For the left image
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
            GeometryReader { geometry in // Get geometry here
                ZStack {
                    Color.black.ignoresSafeArea()

                    HStack(spacing: 0) { // Use HStack for transitions
                        if let previousImage = previousImage {
                            Image(uiImage: previousImage)
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
                        if let nextImage = nextImage {
                            Image(uiImage: nextImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        }
                    }
                    .offset(x: dragState.translation.width)
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: dragState.isDragging) // Use interactiveSpring

                    // Separator during swipe
                    if dragState.isDragging {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 20, height: geometry.size.height) // Use geometry.size.height
                            .offset(x: (dragState.translation.width > 0) ? dragState.translation.width - 20 : dragState.translation.width + 20)
                            .animation(.interactiveSpring(), value: dragState.isDragging)
                    }

                    VStack {
                        HStack {
                            Button(action: { dismiss() }) {
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
                    .allowsHitTesting(false)
                }
            } // End of GeometryReader
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
            withAnimation { selectedImageIndex -= 1 }
            loadImages()
        } else if value.translation.width < -threshold && selectedImageIndex < imageAssets.count - 1 {
            withAnimation { selectedImageIndex += 1 }
            loadImages()
        } else {
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
                dragOffset = 0
            }
        }
    }

    private func loadImages() {
        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        imageManager.requestImage(for: imageAssets[selectedImageIndex], targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
            DispatchQueue.main.async {
                withAnimation { currentImage = image }
            }
        }

        let leftIndex = max(0, selectedImageIndex - 1)
        if leftIndex != selectedImageIndex {
            imageManager.requestImage(for: imageAssets[leftIndex], targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
                DispatchQueue.main.async {
                    previousImage = image
                }
            }
        } else {
            previousImage = nil // Clear previous image
        }

        let rightIndex = min(imageAssets.count - 1, selectedImageIndex + 1)
        if rightIndex != selectedImageIndex {
            imageManager.requestImage(for: imageAssets[rightIndex], targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
                DispatchQueue.main.async {
                    nextImage = image
                }
            }
        } else {
            nextImage = nil // Clear next image
        }
    }


    private func showPreviousImage() {
        if selectedImageIndex > 0 {
            withAnimation { selectedImageIndex -= 1 }
            loadImages()
        } else {
            bounceBack()
        }
    }

    private func showNextImage() {
        if selectedImageIndex < imageAssets.count - 1 {
            withAnimation { selectedImageIndex += 1 }
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
