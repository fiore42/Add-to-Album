import SwiftUI

@main
struct Add_to_AlbumApp: App {
    var body: some Scene {
        WindowGroup {
            ImageGridViewControllerWrapper() // SwiftUI wrapper for UIKit VC
        }
    }
}

// SwiftUI Wrapper for ImageGridViewController
struct ImageGridViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ImageGridViewController {
        return ImageGridViewController()
    }

    func updateUIViewController(_ uiViewController: ImageGridViewController, context: Context) {
        // No updates needed here for this example
    }
}
