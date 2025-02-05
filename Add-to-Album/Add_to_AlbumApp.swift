import SwiftUI

@main
struct Add_to_AlbumApp: App {
    
    @StateObject private var albumSelectionViewModel = AlbumSelectionViewModel() // ✅ Global State
    
    init() {
        Logger.log("Project History:")
        Logger.log("1. 03 Feb 2025 - 19:30 the thumbnail view works")
        Logger.log("2. 03 Feb 2025 - 21:59 the full screen view almost works")
        Logger.log("3. 04 Feb 2025 - 11:58 high screen photos work fast")
        Logger.log("4. 05 Feb 2025 - 01:33 grid and full screen works - PhotoKit")
        Logger.log("5. 05 Feb 2025 - 01:42 introduced PHCachingImageManager")
        Logger.log("6. 05 Feb 2025 - 02:03 perfect grid and full screen view")
        Logger.log("7. 05 Feb 2025 - 02:47 added overlays / swipe up and swipe down in full screen")
        Logger.log("8. 05 Feb 2025 - 19:15 correctly handles album changes and deletion")
        Logger.log("9. 05 Feb 2025 - 22:36 now shows the album list from the first tap")

        Logger.log("🚀 App launched") // ✅ First debug print
    }
    var body: some Scene {
        WindowGroup {
            ImageGridView()
                .environmentObject(albumSelectionViewModel) // ✅ Inject ViewModel
        }
    }
}
