import SwiftUI

/// A full-screen, pinch-to-zoom/pan image viewer with a black background and
/// a Close button -- for tapping a thumbnail (a cert card photo, a dive log
/// photo, etc.) and actually being able to read it. Meant to be presented
/// via `.fullScreenCover`, not `.sheet`, so it covers the whole screen edge
/// to edge rather than leaving a card-style inset.
struct FullScreenImageViewer: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    @State private var currentZoom: CGFloat = 0
    @State private var totalZoom: CGFloat = 1
    @State private var currentOffset: CGSize = .zero
    @State private var totalOffset: CGSize = .zero

    private var zoomScale: CGFloat {
        max(1, totalZoom + currentZoom)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(zoomScale)
                .offset(x: totalOffset.width + currentOffset.width, y: totalOffset.height + currentOffset.height)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            currentZoom = value - 1
                        }
                        .onEnded { _ in
                            totalZoom = max(1, totalZoom + currentZoom)
                            currentZoom = 0
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            currentOffset = value.translation
                        }
                        .onEnded { value in
                            totalOffset.width += value.translation.width
                            totalOffset.height += value.translation.height
                            currentOffset = .zero
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut) {
                        if totalZoom > 1 {
                            totalZoom = 1
                            totalOffset = .zero
                        } else {
                            totalZoom = 3
                        }
                    }
                }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .statusBarHidden()
    }
}

#Preview {
    FullScreenImageViewer(image: UIImage(systemName: "photo") ?? UIImage())
}
