
import SwiftUI
import Foundation

struct FunctionBox: View {
    let title: String
    let album: String?
    let position: Alignment
    let topOffsetPercentage: CGFloat // Percentage from the top (0-100)
    let bottomOffsetPercentage: CGFloat // Percentage from the bottom (0-100)
    let isPaired: Bool
    let onTap: () -> Void

    init(
        title: String,
        album: String?,
        position: Alignment,
        topOffsetPercentage: CGFloat = 10,
        bottomOffsetPercentage: CGFloat = 10,
        isPaired: Bool,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.album = album
        self.position = position
        self.topOffsetPercentage = topOffsetPercentage
        self.bottomOffsetPercentage = bottomOffsetPercentage
        self.isPaired = isPaired
        self.onTap = onTap
    }
    
    var body: some View {
        GeometryReader { geometry in
            let truncatedAlbum = truncateAlbumName(album ?? "Not Set", maxLength: 16)
            HStack {
                Text("\(title): \(truncatedAlbum)")
                    .font(.system(size: 16))
                Image(systemName: isPaired ? "circle.fill" : "circle")
                    .foregroundColor(isPaired ? .green : .red)
                    .imageScale(.small)
            }
            .padding(12)
            .background(Color.black.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: position)
            .offset(y: {
                switch position {
                case .topLeading, .topTrailing:
                    return geometry.size.height * (topOffsetPercentage / 100)
                case .bottomLeading, .bottomTrailing:
                    return geometry.size.height * (1 - (bottomOffsetPercentage / 100))
                default:
                    return 0
                }
            }())
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            onTap()
        }
    }
}


// ✅ Truncates an album name to a maximum length, ensuring words are not cut off randomly.
func truncateAlbumName(_ name: String, maxLength: Int) -> String {
    if name.count <= maxLength {
        return name
    }
    
    let words = name.split(separator: " ")
    var truncatedName = ""

    for word in words {
        if (truncatedName.count + word.count + 1) > maxLength {
            break
        }
        truncatedName += (truncatedName.isEmpty ? "" : " ") + word
    }
    
    return truncatedName
}
