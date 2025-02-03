import SwiftUI

struct ImageGridView: View {
    @StateObject private var viewModel = ImageGridViewModel()

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
                case.granted,.limited:
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: spacing) {
                            ForEach(viewModel.images.indices, id: \.self) { index in
                                ImageCellView(image: viewModel.images[index])
                                  .frame(width: cellSize(), height: cellSize())
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

                case.notDetermined:
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

                case.denied,.restricted:
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

    private func cellSize() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let columns: CGFloat = 3
        let totalSpacing: CGFloat = spacing * (columns - 1) + (spacing * 2)
        return (screenWidth - totalSpacing) / columns
    }
}
