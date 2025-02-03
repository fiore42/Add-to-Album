import SwiftUI

struct ImageCellView: View {
    let image: UIImage?

    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill() // Or .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            ProgressView() // Or a placeholder
        }
    }
}
