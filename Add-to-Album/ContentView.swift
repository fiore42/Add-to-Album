import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var images: [UIImage] = []
    @State private var photoAccessStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedImage: SelectedImage? = nil // Updated to use a struct

    var body: some View {
        NavigationView {
            VStack {
                switch photoAccessStatus {
                case .authorized:
                    if images.isEmpty {
                        Text("Loading your gallery...")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .onAppear {
                                fetchAllPhotos()
                            }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .onTapGesture {
                                            selectedImage = SelectedImage(index: index) // Wrap index in SelectedImage
                                        }
                                }
                            }
                        }
                    }
                case .limited:
                    VStack {
                        Text("The app has limited access to your photos.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Open Settings to Allow Full Access") {
                            openSettings()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                case .denied, .restricted:
                    VStack {
                        Text("Photos access is required. Please enable it in Settings.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Open Settings") {
                            openSettings()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                case .notDetermined:
                    Text("Requesting access to Photos...")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .onAppear {
                            requestPhotoLibraryAccess()
                        }

                @unknown default:
                    Text("Unexpected authorization status. Please restart the app.")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Photo Gallery")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(item: $selectedImage) { selectedImage in
                FullScreenImageView(images: images, selectedIndex: selectedImage.index) {
                    self.selectedImage = nil
                }
            }
        }
    }

    // MARK: - Request Photo Library Access
    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
            DispatchQueue.main.async {
                photoAccessStatus = newStatus
                if newStatus == .authorized {
                    fetchAllPhotos()
                } else if newStatus == .limited {
                    alertMessage = "The app currently has limited access. You can grant full access in Settings."
                    showAlert = true
                } else {
                    alertMessage = "Photos access is required. Please enable it in Settings."
                    showAlert = true
                }
            }
        }
    }

    // MARK: - Fetch All Photos
    func fetchAllPhotos() {
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

            var fetchedImages: [UIImage] = []
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat

            fetchResult.enumerateObjects { asset, _, _ in
                let targetSize = CGSize(width: 200, height: 200)
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { image, _ in
                    if let image = image {
                        fetchedImages.append(image)
                    }
                }
            }

            DispatchQueue.main.async {
                images = fetchedImages
            }
        }
    }

    // MARK: - Open App Settings
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
}

struct FullScreenImageView: View {
    let images: [UIImage]
    @State var selectedIndex: Int
    let onDismiss: () -> Void

    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic)) // Swiping left or right
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onTapGesture {
            onDismiss() // Dismiss full-screen view when tapped
        }
    }
}

// MARK: - Identifiable Wrapper for Index
struct SelectedImage: Identifiable {
    let id = UUID()
    let index: Int
}
