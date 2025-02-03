import SwiftUI
import Photos

struct FunctionBox: View {
    let title: String
    let album: String?
    let isPaired: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("\(title): \(truncateAlbumName(album ?? "Not Set", maxLength: 16))")
                .font(.system(size: 14))
                .lineLimit(1)
            Image(systemName: isPaired ? "circle.fill" : "circle")
                .foregroundColor(isPaired ? .green : .red)
                .imageScale(.small)
        }
        .padding(8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
    }
}
