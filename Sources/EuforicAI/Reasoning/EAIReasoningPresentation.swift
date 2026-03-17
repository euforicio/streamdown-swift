import Foundation

@MainActor
enum EAIReasoningPresentation {
    static func defaultExpanded(for message: EAIMessage) -> Bool {
        message.isStreaming
    }

    static func triggerLabel(for message: EAIMessage, now: Date = Date()) -> String {
        if message.isStreaming {
            return "Thinking..."
        }

        guard let endDate = message.reasoningEndedAt else {
            return "Thought for a moment"
        }

        let clampedEndDate = max(endDate, message.createdAt)
        let seconds = Int(message.createdAt.distance(to: clampedEndDate))
        if seconds < 2 {
            return "Thought for a moment"
        }

        return "Thought for \(seconds)s"
    }
}
