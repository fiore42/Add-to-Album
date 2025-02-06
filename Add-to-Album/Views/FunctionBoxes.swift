import SwiftUI

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct FunctionBoxes: View {
    @State private var positionTop: CGFloat = 0.25 // 20% from top and bottom
    @State private var positionBottom: CGFloat = 0.2 // 20% from top and bottom
    @State private var positionLeftRight: CGFloat = 0.05 // 10% from left and right

    let geometry: GeometryProxy
    let currentPhotoID: String

    @Binding var selectedAlbums: [String] // ✅ Connected to the menu
    @Binding var selectedAlbumIDs: [String] // ✅ Store Album IDs for further logic
    
    @ObservedObject private var albumManager = AlbumManager() // ✅ Manage album logic

    @State private var rotationAngle: Double = 0 // ✅ Rotation state
    
    var body: some View {
        VStack {
            // ✅ Rotation buttons at the top
            HStack {
                Button(action: {
                    rotationAngle -= 90 // Rotate left
                    Logger.log("↩️ Rotated image left to \(rotationAngle) degrees")
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                }
                .padding()

                Spacer()

                Button(action: {
                    rotationAngle += 90 // Rotate right
                    Logger.log("↪️ Rotated image right to \(rotationAngle) degrees")
                }) {
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                }
                .padding()
            }
            .padding(.horizontal)
            Spacer()
            
            HStack {
                functionBox(text: selectedAlbums[safe: 0] ?? "No Album", albumID: selectedAlbumIDs[safe: 0] ?? "", alignment: .topLeading)
                Spacer()
                functionBox(text: selectedAlbums[safe: 1] ?? "No Album", albumID: selectedAlbumIDs[safe: 1] ?? "", alignment: .topTrailing)
            }

            Spacer()

            HStack {
                functionBox(text: selectedAlbums[safe: 2] ?? "No Album", albumID: selectedAlbumIDs[safe: 2] ?? "", alignment: .bottomLeading)
                Spacer()
                functionBox(text: selectedAlbums[safe: 3] ?? "No Album", albumID: selectedAlbumIDs[safe: 3] ?? "", alignment: .bottomTrailing)
            }

            Spacer()
        }
        .ignoresSafeArea()
        .onAppear {
            Logger.log("📂 [FunctionBoxes] appeared. selectedAlbums: \(selectedAlbums) selectedAlbumIDs: \(selectedAlbumIDs)")
        }
        .onChange(of: selectedAlbums) { oldValue, newValue in
            Logger.log("🔄 [FunctionBoxes] selectedAlbums Updated! Old: \(oldValue) -> New: \(newValue)")
        }
        .onChange(of: selectedAlbumIDs) { oldValue, newValue in
            Logger.log("🔄 [FunctionBoxes] selectedAlbumIDs Updated! Old: \(oldValue) -> New: \(newValue)")
        }

    }

    private func functionBox(text: String, albumID: String, alignment: Alignment) -> some View {
        if text.isEmpty {
            return AnyView(EmptyView()) // ✅ Makes it disappear when the album name is empty
        } else {
            return AnyView(
                FunctionBoxView(text: text, albumID: albumID, photoID: currentPhotoID, albumManager: albumManager)
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

struct FunctionBoxView: View {
    let text: String
    let albumID: String
    let photoID: String
    @ObservedObject var albumManager: AlbumManager // ✅ Inject AlbumManager
    
    @State private var isInAlbum: Bool = false

    var body: some View {
        HStack {
            Text(text)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // ✅ Shows green if photo is in album, red if not
            Circle()
                .fill(isInAlbum ? Color.green : Color.red)

//                .fill(albumManager.isPhotoInAlbum(photoID: photoID, albumID: albumID) ? Color.green : Color.red)
                .frame(width: 12, height: 12)

        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
        .onTapGesture {
            Logger.log("📂 [FunctionBox] Toggling photo \(photoID) in album \(albumID)")
            albumManager.togglePhotoInAlbum(photoID: photoID, albumID: albumID)
        }
        .onAppear {
            isInAlbum = albumManager.isPhotoInAlbum(photoID: photoID, albumID: albumID)
        }
        // tried to remove this because it gets triggered a lot, but it breaks the updates
        .onReceive(albumManager.$albumChanges) { _ in
            isInAlbum = albumManager.isPhotoInAlbum(photoID: photoID, albumID: albumID)
            Logger.log("🔄 [FunctionBox] UI updated after album change")
        }
    }

}

