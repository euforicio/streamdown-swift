import SwiftUI

public struct AssistantBubble: View {
    let message: EAIMessage
    let showActions: Bool
    let inlineReasoning: EAIMessage?
    var onRegenerate: () -> Void
    var onCopied: (() -> Void)?

    public init(
        message: EAIMessage,
        showActions: Bool = true,
        onRegenerate: @escaping () -> Void = {},
        onCopied: (() -> Void)? = nil,
        inlineReasoning: EAIMessage? = nil
    ) {
        self.message = message
        self.showActions = showActions
        self.onRegenerate = onRegenerate
        self.onCopied = onCopied
        self.inlineReasoning = inlineReasoning
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.xs) {
            if let inlineReasoning {
                ReasoningView(message: inlineReasoning)
                    .padding(.bottom, EAISpacing.xs)
            }

            if message.isStreaming && message.text.isEmpty {
                ShimmerView()
            } else {
                EAIStreamdown(
                    content: message.text,
                    mode: message.isStreaming ? .streaming : .static
                )
            }

            if message.isStreaming && !message.text.isEmpty {
                StreamingCursor()
            }

            if !message.sources.isEmpty {
                SourcesView(sources: message.sources)
            }

            if !message.attachments.isEmpty {
                AttachmentsView(attachments: message.attachments, layout: .inline)
            }

            if showActions && !message.isStreaming && !message.text.isEmpty {
                ActionsView(
                    messageText: message.text,
                    onRegenerate: onRegenerate,
                    onCopied: onCopied
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("assistant-bubble")
        .accessibilityLabel(message.text)
        .accessibilityValue(message.text)
        .accessibilityChildren {
            if !message.text.isEmpty {
                Text(message.text)
                    .accessibilityIdentifier("assistant-bubble-text")
            }
        }
    }
}

#Preview("Complete") {
    AssistantBubble(message: .preview(text: "Here is **markdown** with `code`."))
        .padding()
}

#Preview("Streaming") {
    AssistantBubble(message: .preview(text: "Typing...", streamingState: .streaming))
        .padding()
}

#Preview("With Sources") {
    AssistantBubble(message: .preview(
        text: "Based on the documentation...",
        sources: [
            EAISource(title: "Swift Docs", url: URL(string: "https://swift.org"), snippet: "The Swift language guide"),
        ]
    ))
    .padding()
}
