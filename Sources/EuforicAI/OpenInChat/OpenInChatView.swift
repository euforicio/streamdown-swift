import SwiftUI

public struct OpenInChatView: View {
    let messageText: String
    let title: String
    var onOpen: (() -> Void)?

    public init(messageText: String, title: String = "Open in chat", onOpen: (() -> Void)? = nil) {
        self.messageText = messageText
        self.title = title
        self.onOpen = onOpen
    }

    public var body: some View {
        HStack(spacing: EAISpacing.sm) {
            Image(systemName: "bubble.left.and.bubble.right")
                .foregroundStyle(.blue)
            Text(messageText)
                .font(EAITypography.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.tail)

            Spacer()

            Button(title) {
                onOpen?()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(EAISpacing.md)
        .background(EAIColors.tertiaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}
