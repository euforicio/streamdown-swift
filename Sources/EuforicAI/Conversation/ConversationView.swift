import SwiftUI

public struct ConversationView<ExtraContent: View>: View {
    private struct RenderInputKey: Hashable {
        let id: String
        let role: EAIRole
        let textCount: Int
        let streamingState: EAIStreamingState
        let reasoningEndedAt: Date?
    }

    let messages: [EAIMessage]
    var onRegenerate: () -> Void
    var onRetry: (() -> Void)?
    var onCopied: (() -> Void)?
    var scrollTrigger: UInt
    var maxMessageWidth: CGFloat?
    var allowsInteractiveKeyboardDismissal: Bool
    let extraContent: ExtraContent

    @State private var isNearBottom = true
    @State private var renderState = EAIConversationRenderState(renderedMessages: [], latestCompletedAssistantMessageID: nil)
    private let nearBottomThreshold: CGFloat = 24

    public init(
        messages: [EAIMessage],
        onRegenerate: @escaping () -> Void = {},
        onRetry: (() -> Void)? = nil,
        onCopied: (() -> Void)? = nil,
        scrollTrigger: UInt = 0,
        maxMessageWidth: CGFloat? = nil,
        allowsInteractiveKeyboardDismissal: Bool = false,
        @ViewBuilder extraContent: () -> ExtraContent = { EmptyView() }
    ) {
        self.messages = messages
        self.onRegenerate = onRegenerate
        self.onRetry = onRetry
        self.onCopied = onCopied
        self.scrollTrigger = scrollTrigger
        self.maxMessageWidth = maxMessageWidth
        self.allowsInteractiveKeyboardDismissal = allowsInteractiveKeyboardDismissal
        self.extraContent = extraContent()
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: EAISpacing.md) {
                    ForEach(renderState.renderedMessages) { renderedMessage in
                        MessageView(
                            message: renderedMessage.message,
                            showAssistantActions: renderedMessage.message.id == renderState.latestCompletedAssistantMessageID,
                            onRegenerate: onRegenerate,
                            onRetry: onRetry,
                            onCopied: onCopied,
                            inlineReasoning: renderedMessage.inlineReasoning
                        )
                    }
                    extraContent
                }
                .padding(.horizontal, EAISpacing.base)
                .padding(.top, EAISpacing.sm)
                .frame(maxWidth: maxMessageWidth ?? .infinity)
                .frame(maxWidth: .infinity)
                .contentBottomTracking()
            }
            .scrollDismissesKeyboard(allowsInteractiveKeyboardDismissal ? .interactively : .never)
            .trackScrollPosition(isNearBottom: $isNearBottom, threshold: nearBottomThreshold)
            .overlay(alignment: .bottomTrailing) {
                if !isNearBottom {
                    ScrollToBottomButton {
                        if let lastID = renderState.renderedMessages.last?.id {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                        isNearBottom = true
                    }
                    .padding(EAISpacing.base)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.snappy(duration: 0.2), value: isNearBottom)
            .task(id: renderInputKeys) {
                await refreshRenderState()
            }
            .onChange(of: renderState.renderedMessages.last?.id) {
                guard isNearBottom, !messages.isEmpty else { return }
                guard let lastID = renderState.renderedMessages.last?.id else { return }
                withAnimation(nil) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }

    private var renderInputKeys: [RenderInputKey] {
        messages.map {
            RenderInputKey(
                id: $0.id,
                role: $0.role,
                textCount: $0.text.count,
                streamingState: $0.streamingState,
                reasoningEndedAt: $0.reasoningEndedAt
            )
        }
    }

    @MainActor
    private func refreshRenderState() async {
        let snapshots = EAIConversationRenderPlanner.snapshots(from: messages)
        let messageLookup = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
        let plan = await Task.detached(priority: .userInitiated) {
            EAIConversationRenderPlanner.renderPlan(from: snapshots)
        }.value
        guard !Task.isCancelled else { return }
        renderState = EAIConversationRenderPlanner.renderState(from: messageLookup, plan: plan)
    }
}

#Preview {
    ConversationView(messages: [
        .preview(role: .user, text: "Hello"),
        .preview(role: .assistant, text: "Hi! How can I help?"),
    ])
}
