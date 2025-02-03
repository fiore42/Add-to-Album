import SwiftUI
import Photos

struct ImageGridView: View {
    @StateObject private var viewModel = ImageGridViewModel()

    // Defines a three-column layout
    private let columns = [
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5)
    ]

    var body: some View {
        NavigationView {
            Group {
                switch viewModel.status {
                case .granted, .limited:
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 5) {
                            ForEach(viewModel.images.indices, id: \.self) { index in
                                ImageCellView(image: viewModel.images[index])
                                    .onAppear {
                                        if index == viewModel.images.count - 1 {
                                            viewModel.loadNextBatch()
                                        }
                                    }
                            }
                        }
                        .padding(5)
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
    }
}
