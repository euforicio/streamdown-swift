import Foundation

struct EAIConversationRenderedMessage: Identifiable {
    let id: String
    let message: EAIMessage
    let inlineReasoning: EAIMessage?
}

struct EAIConversationRenderState {
    let renderedMessages: [EAIConversationRenderedMessage]
    let latestCompletedAssistantMessageID: String?
}

typealias EAIConversationPresentation = EAIConversationRenderState

struct EAIConversationMessageSnapshot: Sendable {
    let id: String
    let role: EAIRole
    let text: String
    let streamingState: EAIStreamingState
    let createdAt: Date
    let reasoningEndedAt: Date?
}

struct EAIConversationReasoningSnapshot: Sendable {
    let text: String
    let isStreaming: Bool
    let createdAt: Date
    let reasoningEndedAt: Date?
}

struct EAIConversationRenderedMessagePlan: Identifiable, Sendable {
    let id: String
    let messageID: String
    let inlineReasoning: EAIConversationReasoningSnapshot?
}

struct EAIConversationRenderPlan: Sendable {
    let renderedMessages: [EAIConversationRenderedMessagePlan]
    let latestCompletedAssistantMessageID: String?
}

extension EAIConversationRenderState {
    @MainActor
    init(messages: [EAIMessage]) {
        self = EAIConversationRenderPlanner.renderState(from: messages)
    }
}

enum EAIConversationRenderPlanner {
    @MainActor
    static func renderState(from messages: [EAIMessage]) -> EAIConversationRenderState {
        let snapshots = snapshots(from: messages)
        let plan = renderPlan(from: snapshots)
        let messageLookup = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
        return renderState(from: messageLookup, plan: plan)
    }

    @MainActor
    static func presentation(from messages: [EAIMessage]) -> EAIConversationRenderState {
        renderState(from: messages)
    }

    @MainActor
    static func renderedMessages(from messages: [EAIMessage]) -> [EAIConversationRenderedMessage] {
        renderState(from: messages).renderedMessages
    }

    @MainActor
    static func snapshots(from messages: [EAIMessage]) -> [EAIConversationMessageSnapshot] {
        messages.map {
            EAIConversationMessageSnapshot(
                id: $0.id,
                role: $0.role,
                text: $0.text,
                streamingState: $0.streamingState,
                createdAt: $0.createdAt,
                reasoningEndedAt: $0.reasoningEndedAt
            )
        }
    }

    @MainActor
    static func renderState(
        from messageLookup: [String: EAIMessage],
        plan: EAIConversationRenderPlan
    ) -> EAIConversationRenderState {
        EAIConversationRenderState(
            renderedMessages: plan.renderedMessages.compactMap { renderedMessage(from: $0, messageLookup: messageLookup) },
            latestCompletedAssistantMessageID: plan.latestCompletedAssistantMessageID
        )
    }

    static func renderPlan(from messages: [EAIConversationMessageSnapshot]) -> EAIConversationRenderPlan {
        EAIConversationRenderPlan(
            renderedMessages: renderedMessages(from: messages),
            latestCompletedAssistantMessageID: latestCompletedAssistantMessageID(from: messages)
        )
    }

    static func renderedMessages(from messages: [EAIConversationMessageSnapshot]) -> [EAIConversationRenderedMessagePlan] {
        var output: [EAIConversationRenderedMessagePlan] = []
        var pendingReasoning: [EAIConversationMessageSnapshot] = []

        for message in messages {
            if message.role == .reasoning {
                pendingReasoning.append(message)
                continue
            }

            if message.role == .assistant {
                output.append(
                    EAIConversationRenderedMessagePlan(
                        id: message.id,
                        messageID: message.id,
                        inlineReasoning: inlineReasoningSnapshot(from: &pendingReasoning)
                    )
                )
                continue
            }

            flushStandaloneReasoning(into: &output, pendingReasoning: &pendingReasoning)
            output.append(EAIConversationRenderedMessagePlan(id: message.id, messageID: message.id, inlineReasoning: nil))
        }

        flushStandaloneReasoning(into: &output, pendingReasoning: &pendingReasoning, appendStandaloneSuffix: true)
        return output
    }

    private static func latestCompletedAssistantMessageID(from messages: [EAIConversationMessageSnapshot]) -> String? {
        guard !messages.contains(where: { $0.streamingState == .streaming }) else { return nil }
        return messages.last {
            $0.role == .assistant && !$0.text.isEmpty && $0.streamingState != .streaming
        }?.id
    }

    private static func inlineReasoningSnapshot(
        from pendingReasoning: inout [EAIConversationMessageSnapshot]
    ) -> EAIConversationReasoningSnapshot? {
        defer { pendingReasoning.removeAll() }

        guard !pendingReasoning.isEmpty else { return nil }

        let reasoningText = pendingReasoning
            .map(\.text)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        let isStreaming = pendingReasoning.contains(where: { $0.streamingState == .streaming })
        guard isStreaming || !reasoningText.isEmpty else { return nil }

        return EAIConversationReasoningSnapshot(
            text: reasoningText,
            isStreaming: isStreaming,
            createdAt: pendingReasoning.map(\.createdAt).min() ?? Date(),
            reasoningEndedAt: pendingReasoning.compactMap(\.reasoningEndedAt).max()
        )
    }

    private static func flushStandaloneReasoning(
        into output: inout [EAIConversationRenderedMessagePlan],
        pendingReasoning: inout [EAIConversationMessageSnapshot],
        appendStandaloneSuffix: Bool = false
    ) {
        guard !pendingReasoning.isEmpty else { return }

        for reasoning in pendingReasoning {
            output.append(
                EAIConversationRenderedMessagePlan(
                    id: appendStandaloneSuffix ? "\(reasoning.id)-standalone" : reasoning.id,
                    messageID: reasoning.id,
                    inlineReasoning: nil
                )
            )
        }
        pendingReasoning.removeAll()
    }

    @MainActor
    private static func renderedMessage(
        from plan: EAIConversationRenderedMessagePlan,
        messageLookup: [String: EAIMessage]
    ) -> EAIConversationRenderedMessage? {
        guard let message = messageLookup[plan.messageID] else { return nil }
        return EAIConversationRenderedMessage(
            id: plan.id,
            message: message,
            inlineReasoning: inlineReasoningMessage(from: plan.inlineReasoning)
        )
    }

    @MainActor
    private static func inlineReasoningMessage(from snapshot: EAIConversationReasoningSnapshot?) -> EAIMessage? {
        guard let snapshot else { return nil }

        let inlineReasoning = EAIMessage(
            role: .reasoning,
            text: snapshot.text,
            streamingState: snapshot.isStreaming ? .streaming : .complete,
            createdAt: snapshot.createdAt
        )
        inlineReasoning.reasoningEndedAt = snapshot.reasoningEndedAt
        return inlineReasoning
    }
}
