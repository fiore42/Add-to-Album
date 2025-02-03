import SwiftUI

struct ImageCellView: View {
    let image: UIImage?

    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill the frame
                .clipped()
        } else {
            ProgressView()
        }
    }
}
