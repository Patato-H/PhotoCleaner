import SwiftUI
import Photos
import AppKit

struct PhotoCardView: View {
    let image: NSImage?
    let asset: PHAsset?
    let isLoading: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.9))
                .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 16)

            if let image {
                GeometryReader { proxy in
                    let size = proxy.size
                    Image(nsImage: image)
                        .resizable()
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
        .padding(8)
        .background(.thinMaterial)
        .clipShape(Capsule())
        .padding(16)
    }
}

