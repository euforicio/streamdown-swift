import SwiftUI

public struct MessageView: View {
    let message: EAIMessage
    let showAssistantActions: Bool
    var inlineReasoning: EAIMessage?
    var onRegenerate: () -> Void
    var onRetry: (() -> Void)?
    var onCopied: (() -> Void)?

    public init(
        message: EAIMessage,
        showAssistantActions: Bool = true,
        onRegenerate: @escaping () -> Void = {},
        onRetry: (() -> Void)? = nil,
        onCopied: (() -> Void)? = nil,
        inlineReasoning: EAIMessage? = nil
    ) {
        self.message = message
        self.showAssistantActions = showAssistantActions
        self.onRegenerate = onRegenerate
        self.onRetry = onRetry
        self.onCopied = onCopied
        self.inlineReasoning = inlineReasoning
    }

    public var body: some View {
        switch message.role {
        case .user:
            UserBubble(message: message)
        case .assistant:
            AssistantBubble(
                message: message,
                showActions: showAssistantActions,
                onRegenerate: onRegenerate,
                onCopied: onCopied,
                inlineReasoning: inlineReasoning
            )
        case .reasoning:
            ReasoningView(message: message)
        case .tool:
            HStack {
                ToolView(message: message)
                Spacer(minLength: 60)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .error:
            errorView
        case .system:
            systemView
        case .progress:
            systemView
                .shimmer(active: true)
        }
    }

    private var errorView: some View {
        HStack(spacing: EAISpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message.text)
                .font(EAITypography.callout)
                .foregroundStyle(.red)
                .accessibilityIdentifier("error-message-text")
            Spacer()
            if let onRetry {
                Button {
                    EAIHaptics.send()
                    onRetry()
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.callout.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(EAISpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("error-message")
        .accessibilityLabel(message.text)
        .accessibilityValue(message.text)
        .onAppear { EAIHaptics.error() }
    }

    private var systemView: some View {
        VStack(alignment: .leading, spacing: EAISpacing.xs) {
            if !message.toolName.isEmpty {
                Text(message.toolName)
                    .font(EAITypography.caption.weight(.semibold))
                    .foregroundStyle(EAIColors.foreground)
            }

            if !message.text.isEmpty {
                Text(message.text)
                    .font(EAITypography.caption)
                    .foregroundStyle(.secondary)
            }

            if !message.sources.isEmpty {
                SourcesView(sources: message.sources)
            }

            if !message.attachments.isEmpty {
                AttachmentsView(attachments: message.attachments, layout: .inline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageView(message: .preview(role: .user, text: "Hello"))
        MessageView(message: .preview(role: .assistant, text: "Hi there!"))
        MessageView(message: .preview(role: .error, text: "Something went wrong"))
        MessageView(message: .preview(role: .system, text: "System message"))
    }
    .padding()
}
