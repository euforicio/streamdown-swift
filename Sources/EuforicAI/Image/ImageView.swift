import SwiftUI

public struct ImageView: View {
    let asset: EAIImageAsset
    let onOpen: ((EAIImageAsset) -> Void)?

    public init(asset: EAIImageAsset, onOpen: ((EAIImageAsset) -> Void)? = nil) {
        self.asset = asset
        self.onOpen = onOpen
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.xs) {
            if let url = asset.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(height: 180)
                            .frame(maxWidth: .infinity)
                    case .failure:
                        VStack {
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                            Text("Image failed to load")
                                .font(EAITypography.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 180)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(EAIColors.gray5)
                    .frame(height: 180)
                    .overlay(
                        Text("No image source")
                            .foregroundStyle(.secondary)
                    )
            }

            Text(asset.title)
                .font(EAITypography.callout)

            if !asset.subtitle.isEmpty {
                Text(asset.subtitle)
                    .font(EAITypography.caption)
                    .foregroundStyle(.secondary)
            }

            if !asset.source.isEmpty {
                Text(asset.source)
                    .font(EAITypography.caption2)
                    .foregroundStyle(.tertiary)
            }

            if onOpen != nil {
                Button("Open") {
                    onOpen?(asset)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(EAISpacing.sm)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}
