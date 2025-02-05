import SwiftUI

struct FunctionBoxes: View {
    @State private var positionTop: CGFloat = 0.25 // 20% from top and bottom
    @State private var positionBottom: CGFloat = 0.2 // 20% from top and bottom
    @State private var positionLeftRight: CGFloat = 0.05 // 10% from left and right

    let geometry: GeometryProxy

    @Binding var selectedAlbums: [String] // ✅ Connected to the menu
    @Binding var selectedAlbumIDs: [String] // ✅ Store Album IDs for further logic
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                functionBox(text: selectedAlbums.indices.contains(0) ? selectedAlbums[0] : "No Album", alignment: .topLeading)
                Spacer()
                functionBox(text: selectedAlbums.indices.contains(1) ? selectedAlbums[1] : "No Album", alignment: .topTrailing)
            }

            Spacer()

            HStack {
                functionBox(text: selectedAlbums.indices.contains(2) ? selectedAlbums[2] : "No Album", alignment: .bottomLeading)
                Spacer()
                functionBox(text: selectedAlbums.indices.contains(3) ? selectedAlbums[3] : "No Album", alignment: .bottomTrailing)
            }

            Spacer()
        }
        .ignoresSafeArea()
        .onAppear {
            Logger.log("📂 FunctionBoxes appeared. Initial Albums: \(selectedAlbums)")
        }
        .onChange(of: selectedAlbums) { _, newValue in
            Logger.log("🔄 FunctionBoxes updated with new Albums: \(newValue)")
        }
    }

    private func functionBox(text: String, alignment: Alignment) -> some View {
        if text.isEmpty {
            return AnyView(EmptyView()) // ✅ Makes it disappear when the album name is empty
        } else {
            return AnyView(
                FunctionBox(text: text)
                    .frame(width: geometry.size.width * 0.35, height: geometry.size.height * 0.05)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                    .padding(
                        EdgeInsets(
                            top: alignment == .topLeading || alignment == .topTrailing ? geometry.size.height * positionTop : 0,
                            leading: alignment == .topLeading || alignment == .bottomLeading ? geometry.size.width * positionLeftRight : 0,
                            bottom: alignment == .bottomLeading || alignment == .bottomTrailing ? geometry.size.height * positionBottom : 0,
                            trailing: alignment == .topTrailing || alignment == .bottomTrailing ? geometry.size.width * positionLeftRight : 0
                        )
                    )
            )
        }
    }
}

struct FunctionBox: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.5))
            .cornerRadius(10)
    }
}
