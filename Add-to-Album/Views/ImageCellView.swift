import SwiftUI
import Photos

// ImageCellView (handles thumbnail loading)
struct ImageCellView: View {
    let asset: PHAsset
    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView() // Placeholder
            }
        }
        .onAppear {
            let targetSize = CGSize(width: 200, height: 200) // Adjust as needed
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                DispatchQueue.main.async {
                    self.thumbnail = image
                }
            }
        }
    }
}
