import SwiftUI
import Photos

class ImageViewModel: ObservableObject {
    @Published var currentImage: UIImage?
}

struct FullscreenImageView: View {
    @Binding var isPresented: Bool
    @Binding var selectedImageIndex: Int
    let imageAssets: [PHAsset]
    @Environment(\.dismiss) var dismiss
    @StateObject private var imageViewModel = ImageViewModel()
    @State private var imageLoadStates: [PHAsset: LoadingState] = [:]

    enum LoadingState {
        case idle
        case loading
        case success
        case failure
    }

    init(isPresented: Binding<Bool>, selectedImageIndex: Binding<Int>, imageAssets: [PHAsset]) {
        self._isPresented = isPresented
        self._selectedImageIndex = selectedImageIndex
        self.imageAssets = imageAssets
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                TabView(selection: $selectedImageIndex) {
                    ForEach(imageAssets.indices, id: \.self) { index in
                        ZStack {
                            Color.black.ignoresSafeArea()

                            if imageLoadStates[imageAssets[index]] == .loading || imageLoadStates[imageAssets[index]] == .idle {
                                ProgressView()
                                    .scaleEffect(1.5)
                            } else if let image = imageViewModel.currentImage, imageLoadStates[imageAssets[index]] == .success {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .transition(.opacity)
                            } else {
                                Image(systemName: "xmark.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.red)
                            }
                        }
                        .tag(index)
                        .onAppear {
                            loadImage(for: imageAssets[index], targetSize: geometry.size)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))

                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                                .padding()
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private func loadImage(for asset: PHAsset, targetSize: CGSize) {
        guard imageLoadStates[asset] != .loading else { return }

        imageLoadStates[asset] = .loading

        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false // Key for performance

        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, info in
            DispatchQueue.main.async {
                if let image = image {
                    self.imageViewModel.currentImage = image // Update the ViewModel
                    self.imageLoadStates[asset] = .success
                } else {
                    self.imageLoadStates[asset] = .failure
                }
            }
        }
    }
}
