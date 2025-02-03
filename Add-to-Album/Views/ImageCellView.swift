import SwiftUI

struct ImageCellView: View {
    let image: UIImage? // Or your image type

    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable() // Important: Make the image resizable
                .scaledToFill() // Or .scaledToFit() depending on your needs
                .clipped() // Very important: Clip to the frame bounds
        } else {
            // Placeholder or loading indicator
            ProgressView() // Example placeholder
        }
    }
}
