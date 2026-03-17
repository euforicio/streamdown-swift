import Foundation

public enum EAIRole: String, Sendable, Codable {
    case user
    case assistant
    case system
    case tool
    case reasoning
    case error
    case progress
}

public enum EAIStreamingState: String, Sendable, Codable {
    case idle
    case streaming
    case complete
}

public enum EAIToolStatus: String, Sendable, Codable {
    case pending
    case running
    case completed
    case failed
}

@Observable
@MainActor
public final class EAIMessage: Identifiable, Sendable {
    nonisolated public let id: String
    nonisolated public let role: EAIRole
    nonisolated public let createdAt: Date

    public var text: String
    public var toolName: String
    public var toolCommand: String
    public var toolOutput: String
    public var toolExitCode: Int32
    public var toolCallID: String
    public var toolStatus: EAIToolStatus
    public var streamingState: EAIStreamingState
    public var toolStartedAt: Date?
    public var toolElapsed: TimeInterval = 0
    public var attachments: [EAIAttachment]
    public var sources: [EAISource]
    public var reasoningEndedAt: Date?

    public var isStreaming: Bool {
        get { streamingState == .streaming }
        set { streamingState = newValue ? .streaming : .complete }
    }

    public init(
        id: String = UUID().uuidString,
        role: EAIRole,
        text: String = "",
        toolName: String = "",
        toolCommand: String = "",
        toolOutput: String = "",
        toolExitCode: Int32 = 0,
        toolCallID: String = "",
        toolStatus: EAIToolStatus = .running,
        streamingState: EAIStreamingState = .idle,
        toolStartedAt: Date? = nil,
        toolElapsed: TimeInterval = 0,
        attachments: [EAIAttachment] = [],
        sources: [EAISource] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.createdAt = createdAt
        self.text = text
        self.toolName = toolName
        self.toolCommand = toolCommand
        self.toolOutput = toolOutput
        self.toolExitCode = toolExitCode
        self.toolCallID = toolCallID
        self.toolStatus = toolStatus
        self.streamingState = streamingState
        self.toolStartedAt = toolStartedAt
        self.toolElapsed = toolElapsed
        self.attachments = attachments
        self.sources = sources
    }

    public static func preview(
        role: EAIRole = .assistant,
        text: String = "Hello, how can I help you?",
        streamingState: EAIStreamingState = .complete,
        toolName: String = "",
        toolCommand: String = "",
        toolOutput: String = "",
        toolStatus: EAIToolStatus = .completed,
        attachments: [EAIAttachment] = [],
        sources: [EAISource] = []
    ) -> EAIMessage {
        EAIMessage(
            role: role,
            text: text,
            toolName: toolName,
            toolCommand: toolCommand,
            toolOutput: toolOutput,
            toolStatus: toolStatus,
            streamingState: streamingState,
            attachments: attachments,
            sources: sources
        )
    }
}
