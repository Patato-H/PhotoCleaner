import Photos
import SwiftUI

struct PhotoCardView: View {
    let image: PlatformImage?
    let asset: PHAsset?
    let isLoading: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.16), radius: 24, x: 0, y: 16)

            if let image {
                GeometryReader { proxy in
                    let size = proxy.size
                    Group {
                        #if os(macOS)
                        Image(nsImage: image)
                            .resizable()
                        #else
                        Image(uiImage: image)
                            .resizable()
                        #endif
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                }
                .padding(16)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                        Text("Loading photo…")
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                        Text("Unable to display this photo.")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(6)
        .overlay(alignment: .bottomLeading) {
            if let asset {
                MetadataOverlayView(asset: asset)
            }
        }
    }
}

private struct MetadataOverlayView: View {
    let asset: PHAsset

    var body: some View {
        HStack(spacing: 8) {
            if let date = asset.creationDate {
                Text(date.formatted(date: .abbreviated, time: .shortened))
            }
            if asset.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
            }
            if asset.mediaSubtypes.contains(.photoScreenshot) {
                Image(systemName: "crop")
                Text("Screenshot")
            }
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.regularMaterial)
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
        .clipShape(Capsule())
        .padding(16)
    }
}
