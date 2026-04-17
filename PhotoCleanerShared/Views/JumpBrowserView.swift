import Photos
import SwiftUI

struct JumpBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ReviewViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 140), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                        JumpAssetCell(asset: asset)
                            .environmentObject(viewModel)
                            .onTapGesture {
                                viewModel.jumpToAsset(localIdentifier: asset.localIdentifier)
                                dismiss()
                            }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Jump to Photo")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 760, minHeight: 560)
        #endif
    }
}

private struct JumpAssetCell: View {
    @EnvironmentObject private var viewModel: ReviewViewModel
    let asset: PHAsset
    @State private var thumbnail: PlatformImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
                .frame(height: 120)

            if let thumbnail {
                Group {
                    #if os(macOS)
                    Image(nsImage: thumbnail)
                        .resizable()
                    #else
                    Image(uiImage: thumbnail)
                        .resizable()
                    #endif
                }
                .aspectRatio(contentMode: .fill)
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(height: 120)
            }

            if let date = asset.creationDate {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear {
            guard thumbnail == nil else { return }
            Task {
                thumbnail = await viewModel.requestThumbnail(for: asset, targetSize: CGSize(width: 320, height: 320))
            }
        }
    }
}
