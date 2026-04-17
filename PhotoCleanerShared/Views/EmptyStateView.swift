import SwiftUI

struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.slash")
                .font(.system(size: 46))
                .foregroundColor(.secondary)
            Text(message)
                .font(.title3.weight(.semibold))
            Text("Try changing the filter or adding more photos to your library.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: 460)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
