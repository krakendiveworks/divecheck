import SwiftUI

/// Generic "coming soon" screen for menu entries that exist in the
/// navigation structure ahead of the feature being built out.
struct PlaceholderToolView: View {
    let title: String
    let symbolName: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 44))
                .foregroundStyle(.blue)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text("Coming soon")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.blue, in: Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PlaceholderToolView(
            title: "Statistics",
            symbolName: "chart.bar.fill",
            message: "Dive statistics and trends across your logged dives will live here."
        )
    }
}
