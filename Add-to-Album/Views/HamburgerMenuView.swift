import SwiftUI

struct HamburgerMenuView: View {
    @State private var selectedAlbums: [String] = UserDefaultsManager.getSavedAlbums()
    @State private var isAlbumPickerPresented = false
    @State private var selectedMenuIndex: Int? = nil // Track which menu item is selected

    var body: some View {
        HStack {
            Spacer() // Pushes the menu to the right

            Menu {
                ForEach(0..<4, id: \.self) { index in
                    Button(action: {
                        selectedMenuIndex = index
                        isAlbumPickerPresented = true
                    }) {
                        Text(selectedAlbums[index])
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .frame(width: 30, height: 25)
                    .foregroundColor(.white) // Make the icon white
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing) // Ensure it's aligned right
        .sheet(isPresented: $isAlbumPickerPresented) {
            if let index = selectedMenuIndex {
                AlbumPickerView(selectedAlbum: $selectedAlbums[index])
            }
        }
    }
}
