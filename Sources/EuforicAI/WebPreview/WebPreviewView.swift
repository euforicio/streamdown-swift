import SwiftUI

public struct WebPreviewView: View {
    let url: URL?
    let title: String
    let onOpen: ((URL) -> Void)?
    @Environment(\.openURL) private var openURL

    public init(url: URL?, title: String = "Web Preview", onOpen: ((URL) -> Void)? = nil) {
        self.url = url
        self.title = title
        self.onOpen = onOpen
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            if let url {
                Text(title)
                    .font(EAITypography.callout)

                Text(url.absoluteString)
                    .font(EAITypography.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)

                Button("Open") {
                    openURL(url)
                    EAIHaptics.light()
                }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("Open in app") {
                    if let onOpen {
                        onOpen(url)
                    } else {
                        openURL(url)
                    }
                    EAIHaptics.light()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Text("No URL to preview")
                    .font(EAITypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(EAISpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 10))
    }
}
