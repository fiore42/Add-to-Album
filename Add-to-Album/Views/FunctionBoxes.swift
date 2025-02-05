import SwiftUI

struct FunctionBoxes: View {
    @State private var positionTopBottom: CGFloat = 0.2 // 20% from top and bottom
    @State private var positionLeftRight: CGFloat = 0.1 // 10% from left and right

    let geometry: GeometryProxy

    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                functionBox(text: "test test 1", alignment: .topLeading)
                Spacer()
                functionBox(text: "test test 2", alignment: .topTrailing)
            }

            Spacer()

            HStack {
                functionBox(text: "test test 3", alignment: .bottomLeading)
                Spacer()
                functionBox(text: "test test 4", alignment: .bottomTrailing)
            }

            Spacer()
        }
        .ignoresSafeArea()
    }

    private func functionBox(text: String, alignment: Alignment) -> some View {
        FunctionBox(text: text)
            .frame(width: geometry.size.width * 0.3, height: geometry.size.height * 0.05)
            .background(Color.black.opacity(0.5))
            .cornerRadius(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .padding(
                EdgeInsets(
                    top: alignment == .topLeading || alignment == .topTrailing ? geometry.size.height * positionTopBottom : 0,
                    leading: alignment == .topLeading || alignment == .bottomLeading ? geometry.size.width * positionLeftRight : 0,
                    bottom: alignment == .bottomLeading || alignment == .bottomTrailing ? geometry.size.height * positionTopBottom : 0,
                    trailing: alignment == .topTrailing || alignment == .bottomTrailing ? geometry.size.width * positionLeftRight : 0
                )
            )
    }
}

struct FunctionBox: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.5))
            .cornerRadius(10)
    }
}
