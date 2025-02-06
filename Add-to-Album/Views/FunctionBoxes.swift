import SwiftUI

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct FunctionBoxes: View {
    let geometry: GeometryProxy
    let currentPhotoID: String

    @Binding var selectedAlbums: [String]
    @Binding var selectedAlbumIDs: [String]
    
    @ObservedObject private var albumManager = AlbumManager()

    let albumPositions: [[Int]] = [
        [0, 1],
        [4, 5],
        [6, 7],
        [2, 3]
    ]

    var body: some View {
        VStack {
            ForEach(albumPositions, id: \.self) { row in
                HStack {
                    functionBox(
                        text: selectedAlbums[safe: row[0]] ?? Constants.noAlbumSelected,
                        albumID: selectedAlbumIDs[safe: row[0]] ?? "",
                        alignment: .leading
                    )
                    Spacer()
                    functionBox(
                        text: selectedAlbums[safe: row[1]] ?? Constants.noAlbumSelected,
                        albumID: selectedAlbumIDs[safe: row[1]] ?? "",
                        alignment: .trailing
                    )
                }
            }
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

    private func functionBox(text: String, albumID: String, alignment: HorizontalAlignment) -> some View {
        if text.isEmpty {
            return AnyView(EmptyView())
        } else {
            return AnyView(
                FunctionBoxView(
                    text: text,
                    albumID: albumID,
                    photoID: currentPhotoID,
                    albumManager: albumManager
                )
                .frame(width: geometry.size.width * 0.35, height: geometry.size.height * 0.05)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
            )
        }
    }
    
    struct FunctionBoxView: View {
        let text: String
        let albumID: String
        let photoID: String
        @ObservedObject var albumManager: AlbumManager // ✅ Inject AlbumManager
        
        //    let rotateLeft: () -> Void // ✅ Function for rotating left
        //    let rotateRight: () -> Void // ✅ Function for rotating right
        
        @State private var isInAlbum: Bool = false
        
        var body: some View {
            VStack {
                HStack {
                    Text(text)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // ✅ Show green if photo is in album, red if not
                    Circle()
                        .fill(isInAlbum ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                }
                
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
            .onReceive(albumManager.$albumChanges) { _ in
                isInAlbum = albumManager.isPhotoInAlbum(photoID: photoID, albumID: albumID)
                Logger.log("🔄 [FunctionBox] UI updated after album change")
            }
        }
    }

}
