import SwiftUI

struct ImageGridView: View {
    @StateObject private var viewModel = ImageGridViewModel()
    @State private var isPresented = false
    @State private var selectedImageIndex = 0
    private let spacing: CGFloat = 2
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            Group {
                switch viewModel.status {
                case .granted, .limited:
                    GeometryReader { geometry in
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: spacing) {
                                ForEach(viewModel.imageAssets.indices, id: \.self) { index in // Use imageAssets
                                    ImageCellView(asset: viewModel.imageAssets[index]) // Pass the PHAsset
                                        .aspectRatio(1, contentMode: .fit)
                                        .frame(width: cellSize(geometry: geometry), height: cellSize(geometry: geometry))
                                        .clipped()
                                        .onTapGesture {
                                            Logger.log("🖼 Thumbnail tapped for index: \(index)")
                                            selectedImageIndex = index
                                            isPresented = true
                                        }
                                        .onAppear {
                                            if index == viewModel.imageAssets.count - 1 { // Use imageAssets
                                                viewModel.loadNextBatch()
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, spacing)
                            .padding(.top, spacing)
                        }
                    }

                case .notDetermined:
                    VStack {
                        Text("We need access to your photos.")
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Request Permission") {
                            viewModel.requestPermission()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                case .denied, .restricted:
                    Text("Photo access denied. Please update settings.")
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .navigationTitle("Photo Grid")
            .onAppear {
                viewModel.checkPermissions()
            }
        }
        .fullScreenCover(isPresented: $isPresented) {
            FullscreenImageView(
                isPresented: $isPresented,
                selectedImageIndex: $selectedImageIndex,
                imageAssets: viewModel.imageAssets // Pass imageAssets
            )
        }
    }

    private func cellSize(geometry: GeometryProxy) -> CGFloat {
        let columns: CGFloat = 3
        let totalSpacing: CGFloat = spacing * (columns - 1) + (spacing * 2)
        return (geometry.size.width - totalSpacing) / columns
    }
}
