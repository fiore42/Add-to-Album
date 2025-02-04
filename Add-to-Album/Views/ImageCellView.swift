import SwiftUI
import Photos

struct ImageCellView: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView() // Show progress while loading
            }
        }
        .onAppear {
            loadImage(for: asset)
        }
    }

    private func loadImage(for asset: PHAsset) {
        let manager = PHImageManager.default()
        let targetSize = CGSize(width: 200, height: 200) // Adjust as needed
        let options = PHImageRequestOptions()
        options.isSynchronous = false

        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, info in
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
}
