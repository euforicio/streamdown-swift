import SwiftUI

public struct ActionsView: View {
    let messageText: String
    var onRegenerate: () -> Void
    var onShare: ((String) -> Void)?
    var onCopied: (() -> Void)?

    @State private var thumbsUp = false
    @State private var thumbsDown = false
    @State private var copied = false

    public init(
        messageText: String,
        onRegenerate: @escaping () -> Void = {},
        onShare: ((String) -> Void)? = nil,
        onCopied: (() -> Void)? = nil
    ) {
        self.messageText = messageText
        self.onRegenerate = onRegenerate
        self.onShare = onShare
        self.onCopied = onCopied
    }

    public var body: some View {
        HStack(spacing: EAISpacing.xs) {
            actionButton(
                icon: copied ? "checkmark" : "doc.on.doc",
                isActive: copied
            ) {
                CopyAction.perform(messageText, copied: $copied)
                onCopied?()
            }

            actionButton(icon: "arrow.clockwise", isActive: false) {
                EAIHaptics.send()
                onRegenerate()
            }

            actionButton(icon: "hand.thumbsup", isActive: thumbsUp) {
                EAIHaptics.light()
                thumbsUp.toggle()
                if thumbsUp { thumbsDown = false }
            }

            actionButton(icon: "hand.thumbsdown", isActive: thumbsDown) {
                EAIHaptics.light()
                thumbsDown.toggle()
                if thumbsDown { thumbsUp = false }
            }

            if onShare != nil {
                actionButton(icon: "square.and.arrow.up", isActive: false) {
                    EAIHaptics.light()
                    onShare?(messageText)
                }
            }
        }
        .padding(.top, EAISpacing.xs)
    }

    private func actionButton(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: isActive ? "\(icon).fill" : icon)
                .font(EAITypography.caption)
                .foregroundStyle(isActive ? Color.accentColor : .secondary)
                .frame(width: EAISpacing.minTouchTarget, height: EAISpacing.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ActionsView(messageText: "Hello, world!")
        .padding()
}
