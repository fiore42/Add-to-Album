import SwiftUI
import Photos


struct ImageGridView: View {

    @ObservedObject var albumSelectionViewModel: AlbumSelectionViewModel // ✅ Injected

    @StateObject private var viewModel = ImageGridViewModel()
    @State private var isPresented = false
    @State private var selectedImageIndex = 0
    
    private let spacing: CGFloat = 5
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: 3)
    }
    
    var body: some View {
        NavigationStack {
            contentView
            .navigationTitle("Photo Grid")
            .navigationBarTitleDisplayMode(.inline) // Ensures proper layout
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { // Moves menu to top right
                    HamburgerMenuView()
                }
            }
            .task {
                Logger.log("🔍 Before Checking Permissions: \(viewModel.status)")
                viewModel.checkPermissions()
                Logger.log("🔍 After Checking Permissions: \(viewModel.status)")
            }
        }
        .fullScreenCover(isPresented: $isPresented) {
            FullscreenImageView(
                isPresented: $isPresented,
                selectedImageIndex: $selectedImageIndex,
                imageAssets: viewModel.imageAssets,
                imageGridViewModel: viewModel,
                albumSelectionViewModel: albumSelectionViewModel // ✅ Pass it down
            )
        }
    }

    
    private var contentView: some View {
        AnyView(
            Group {
                if viewModel.isCheckingPermissions {
                    splashScreenView // Show splash screen
                } else {
                    switch viewModel.status {
                    case .granted, .limited:
                        imageGridView
                    case .notDetermined:
                        permissionRequestView
                    case .denied, .restricted:
                        accessDeniedView
                    }
                }
            }
        )
    }

    private var splashScreenView: some View {
        VStack {
            Spacer()
            ProgressView("Checking Permissions...")
                .progressViewStyle(CircularProgressViewStyle())
                .font(.title2)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8)) // Dark splash screen
        .ignoresSafeArea()
    }

    private var imageGridView: some View {

        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(viewModel.imageAssets.indices, id: \.self) { index in
                        ImageGridItem(
                            asset: viewModel.imageAssets[index],
                            index: index,
                            geometry: geometry,
                            viewModel: viewModel,
                            isPresented: $isPresented,
                            selectedImageIndex: $selectedImageIndex,
                            spacing: spacing
                        )
                    }
                }
                .padding(.horizontal, spacing)
                .padding(.top, spacing)
            }
        }
    }

    private var permissionRequestView: some View {
        VStack(spacing: 20) {
            Text("We need access to your photos.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                viewModel.requestPermission()
            }) {
                Text("Request Permission")
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }

    private var accessDeniedView: some View {
        VStack(spacing: 20) {
            Text("Photo access denied. Please update settings.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                openAppSettings()
            }) {
                Text("Open Settings")
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }

    /// Opens App Settings if access is denied
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func cellSize(geometry: GeometryProxy) -> CGFloat {
        let columns: CGFloat = 3
        let totalSpacing: CGFloat = spacing * (columns - 1) + (spacing * 2)
        return (geometry.size.width - totalSpacing) / columns
    }
}


struct ImageGridItem: View {

    let asset: PHAsset
    let index: Int
    let geometry: GeometryProxy
    @ObservedObject var viewModel: ImageGridViewModel // Make sure you observe the view model here
    @Binding var isPresented: Bool
    @Binding var selectedImageIndex: Int
    let spacing: CGFloat 

    var body: some View {
        ImageCellView(asset: asset)
            .aspectRatio(1, contentMode: .fit)
            .frame(width: cellSize(), height: cellSize())
            .clipped()
            .onTapGesture {
                selectedImageIndex = index
                isPresented = true
            }
            .onAppear {
                if index == viewModel.imageAssets.count - 5 && !viewModel.isLoadingBatch {
                    viewModel.loadNextBatch()
                }
            }
    }

    private func cellSize() -> CGFloat {
        let columns: CGFloat = 3
        let totalSpacing: CGFloat = spacing * (columns - 1) + (spacing * 2)
        return (geometry.size.width - totalSpacing) / columns
    }
}
