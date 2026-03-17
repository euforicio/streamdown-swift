import SwiftUI

public struct ChatbotView: View {
    let title: String
    let messages: [EAIMessage]
    let isStreaming: Bool
    var onSend: (String) -> Void
    var onCancel: () -> Void
    var onRegenerate: () -> Void
    var onRetry: (() -> Void)?
    var onAttach: (() -> Void)?
    var onClear: (() -> Void)?

    @State private var promptText = ""
    @State private var scrollTrigger: UInt = 0

    public init(
        title: String = "Chatbot",
        messages: [EAIMessage],
        isStreaming: Bool = false,
        onSend: @escaping (String) -> Void,
        onCancel: @escaping () -> Void = {},
        onRegenerate: @escaping () -> Void = {},
        onRetry: (() -> Void)? = nil,
        onAttach: (() -> Void)? = nil,
        onClear: (() -> Void)? = nil
    ) {
        self.title = title
        self.messages = messages
        self.isStreaming = isStreaming
        self.onSend = onSend
        self.onCancel = onCancel
        self.onRegenerate = onRegenerate
        self.onRetry = onRetry
        self.onAttach = onAttach
        self.onClear = onClear
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            ConversationView(
                messages: messages,
                onRegenerate: onRegenerate,
                onRetry: onRetry,
                scrollTrigger: scrollTrigger
            )
            PromptInputView(
                text: $promptText,
                isStreaming: isStreaming,
                onSend: sendMessage,
                onCancel: onCancel,
                onAttach: onAttach
            )
        }
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 14))
        .clipped()
    }

    private var header: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(EAIColors.primaryLabel)
            Spacer()
            if let onClear {
                Button(role: .destructive) {
                    onClear()
                } label: {
                    Text("Clear")
                        .font(EAITypography.caption2)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, EAISpacing.md)
        .padding(.top, EAISpacing.md)
        .padding(.bottom, EAISpacing.sm)
    }

    private func sendMessage() {
        let trimmed = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        promptText = ""
        onSend(trimmed)
        scrollTrigger &+= 1
    }
}

#if canImport(UIKit)
#Preview {
    @Previewable @State var messages = [
        EAIMessage.preview(role: .assistant, text: "Hi, how can I help?"),
    ]
    @Previewable @State var isStreaming = false
    ChatbotView(
        messages: messages,
        isStreaming: isStreaming,
        onSend: { text in
            messages.append(EAIMessage.preview(role: .user, text: text))
            let response = EAIMessage(
                role: .assistant,
                text: "I can help with: \(text)",
                streamingState: .complete
            )
            messages.append(response)
        },
        onClear: { messages = [] }
    )
}
#endif
