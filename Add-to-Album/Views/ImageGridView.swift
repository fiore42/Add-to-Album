import SwiftUI

struct ImageGridView: View {
    @StateObject private var viewModel = ImageGridViewModel() // Make sure this is implemented
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
                                ForEach(viewModel.images.indices, id: \.self) { index in
                                    ImageCellView(image: viewModel.images[index])
                                        .aspectRatio(1, contentMode: .fit) // Or .fill
                                        .frame(width: cellSize(geometry: geometry), height: cellSize(geometry: geometry))
                                        .clipped()
                                        .onTapGesture {
                                            Logger.log("🖼 Thumbnail tapped for index: \(index)")
                                            selectedImageIndex = index // Explicitly set the selected index
                                            isPresented = true
                                        }
                                        .onAppear {
                                            if index == viewModel.images.count - 1 {
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
                selectedImageIndex: $selectedImageIndex, // ✅ Fix: Add `$` to make it a Binding<Int>
                imageAssets: viewModel.imageAssets
            )
        }
    }

    private func cellSize(geometry: GeometryProxy) -> CGFloat {
        let columns: CGFloat = 3
        let totalSpacing: CGFloat = spacing * (columns - 1) + (spacing * 2)
        return (geometry.size.width - totalSpacing) / columns
    }
}
