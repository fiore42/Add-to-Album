import UIKit

@main
class Add_to_AlbumApp: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        let layout = UICollectionViewFlowLayout()
        let imageGridVC = ImageGridViewController(collectionViewLayout: layout)
        let navigationController = UINavigationController(rootViewController: imageGridVC)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }
}
