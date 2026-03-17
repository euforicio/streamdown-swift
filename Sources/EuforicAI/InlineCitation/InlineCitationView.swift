import SwiftUI

public struct InlineCitationView: View {
    let citation: EAIInlineCitation
    var onOpen: ((EAIInlineCitation) -> Void)?
    @Environment(\.openURL) private var openURL

    public init(citation: EAIInlineCitation, onOpen: ((EAIInlineCitation) -> Void)? = nil) {
        self.citation = citation
        self.onOpen = onOpen
    }

    public var body: some View {
        HStack(spacing: EAISpacing.xs) {
            Button {
                if let onOpen { onOpen(citation) }
                EAIHaptics.light()
            } label: {
                HStack(spacing: EAISpacing.xs) {
                    Text("[\(citation.index)]")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(EAIColors.tertiaryBackground, in: Capsule())

                    Text(citation.label)
                        .font(EAITypography.caption2)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if let url = citation.url {
                Button("Open") {
                    if let onOpen {
                        onOpen(citation)
                    } else {
                        openURL(url)
                    }
                    EAIHaptics.light()
                }
                .buttonStyle(.plain)
                .font(EAITypography.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(EAISpacing.sm)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 8))
    }
}
