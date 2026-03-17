import Foundation

public enum EAIConnectionState: String, Sendable, Codable {
    case disconnected
    case connecting
    case connected
    case failed
}

public enum EAIConnectionStrength: String, Sendable, Codable {
    case unknown
    case poor
    case fair
    case good
    case excellent
}

public struct EAIConnection: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let title: String
    public let detail: String
    public var state: EAIConnectionState
    public var strength: EAIConnectionStrength

    public init(
        id: String = UUID().uuidString,
        title: String,
        detail: String = "",
        state: EAIConnectionState = .disconnected,
        strength: EAIConnectionStrength = .unknown
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.state = state
        self.strength = strength
    }
}

public enum EAIAgentStatus: String, Sendable, Codable {
    case idle
    case active
    case reasoning
    case done
    case failed
}

public struct EAIChatAgent: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let name: String
    public let role: String
    public let description: String
    public var status: EAIAgentStatus
    public var capabilities: [String]

    public init(
        id: String = UUID().uuidString,
        name: String,
        role: String,
        description: String,
        status: EAIAgentStatus = .idle,
        capabilities: [String] = []
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.description = description
        self.status = status
        self.capabilities = capabilities
    }
}

public struct EAIPersona: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let name: String
    public let tone: String
    public let systemPrompt: String
    public let constraints: [String]
    public var isActive: Bool

    public init(
        id: String = UUID().uuidString,
        name: String,
        tone: String,
        systemPrompt: String,
        constraints: [String] = [],
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.tone = tone
        self.systemPrompt = systemPrompt
        self.constraints = constraints
        self.isActive = isActive
    }
}

public struct EAIEnvironmentVariable: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let key: String
    public let value: String
    public let isSecret: Bool

    public init(
        id: String = UUID().uuidString,
        key: String,
        value: String,
        isSecret: Bool = false
    ) {
        self.id = id
        self.key = key
        self.value = value
        self.isSecret = isSecret
    }

    public func maskedValue(characterCount: Int = 8) -> String {
        guard isSecret else { return value }
        return String(repeating: "*", count: min(characterCount, max(value.count, 1)))
    }
}

public struct EAIBranch: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let title: String
    public let detail: String
    public var isSelected: Bool

    public init(id: String = UUID().uuidString, title: String, detail: String = "", isSelected: Bool = false) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isSelected = isSelected
    }
}

public struct EAICheckpoint: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let title: String
    public let state: String
    public let updatedAt: Date
    public let note: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        state: String,
        updatedAt: Date = Date(),
        note: String = ""
    ) {
        self.id = id
        self.title = title
        self.state = state
        self.updatedAt = updatedAt
        self.note = note
    }
}

public struct EAICommit: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let hash: String
    public let message: String
    public let author: String
    public let date: Date

    public init(
        id: String = UUID().uuidString,
        hash: String,
        message: String,
        author: String,
        date: Date = Date()
    ) {
        self.id = id
        self.hash = hash
        self.message = message
        self.author = author
        self.date = date
    }
}

public enum EAIQueueState: String, Sendable, Codable {
    case queued
    case running
    case done
    case failed
}

public struct EAIQueueItem: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public var state: EAIQueueState
    public let progress: Double

    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String = "",
        state: EAIQueueState = .queued,
        progress: Double = 0
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.state = state
        self.progress = progress
    }
}

public enum EAITaskStatus: String, Sendable, Codable {
    case pending
    case running
    case completed
    case failed
}

public enum EAITestResultState: String, Sendable, Codable {
    case pass
    case fail
    case skipped
    case running
}

public struct EAITestResult: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let name: String
    public let state: EAITestResultState
    public let durationMS: Double
    public let details: String
    public let errorMessage: String?
    public let errorStack: String?

    public init(
        id: String = UUID().uuidString,
        name: String,
        state: EAITestResultState = .running,
        durationMS: Double = 0,
        details: String = "",
        errorMessage: String? = nil,
        errorStack: String? = nil
    ) {
        self.id = id
        self.name = name
        self.state = state
        self.durationMS = durationMS
        self.details = details
        self.errorMessage = errorMessage
        self.errorStack = errorStack
    }
}

public enum EAIControlStyle: String, Sendable, Codable {
    case primary
    case secondary
    case destructive
    case plain
}

public struct EAIControlAction: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let title: String
    public let icon: String
    public let style: EAIControlStyle
    public var isEnabled: Bool
    public var isActive: Bool

    public init(
        id: String = UUID().uuidString,
        title: String,
        icon: String,
        style: EAIControlStyle = .plain,
        isEnabled: Bool = true,
        isActive: Bool = false
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.style = style
        self.isEnabled = isEnabled
        self.isActive = isActive
    }
}

public struct EAIImageAsset: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let source: String
    public let url: String?

    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String = "",
        source: String = "",
        url: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.source = source
        self.url = url
    }

    public var imageURL: URL? {
        guard let url else { return nil }
        return URL(string: url)
    }
}

public struct EAIInlineCitation: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let index: Int
    public let label: String
    public let sourceTitle: String
    public let sourceURL: String

    public init(
        id: String = UUID().uuidString,
        index: Int,
        label: String,
        sourceTitle: String,
        sourceURL: String
    ) {
        self.id = id
        self.index = index
        self.label = label
        self.sourceTitle = sourceTitle
        self.sourceURL = sourceURL
    }

    public var url: URL? {
        URL(string: sourceURL)
    }
}

public struct EAINode: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let metadata: [String: String]

    public init(id: String = UUID().uuidString, title: String, description: String = "", metadata: [String: String] = [:]) {
        self.id = id
        self.title = title
        self.description = description
        self.metadata = metadata
    }
}

public struct EAIConnectionEdge: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let fromNodeID: String
    public let toNodeID: String
    public let label: String

    public init(
        id: String = UUID().uuidString,
        fromNodeID: String,
        toNodeID: String,
        label: String = ""
    ) {
        self.id = id
        self.fromNodeID = fromNodeID
        self.toNodeID = toNodeID
        self.label = label
    }
}

public struct EAIAudioTrack: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let title: String
    public let durationSeconds: TimeInterval
    public let source: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        durationSeconds: TimeInterval,
        source: String
    ) {
        self.id = id
        self.title = title
        self.durationSeconds = durationSeconds
        self.source = source
    }
}

public struct SAMicrophone: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let name: String
    public let locale: String

    public init(id: String = UUID().uuidString, name: String, locale: String) {
        self.id = id
        self.name = name
        self.locale = locale
    }
}

public struct SASpeechVoice: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let name: String
    public let locale: String
    public let style: String

    public init(id: String = UUID().uuidString, name: String, locale: String, style: String = "default") {
        self.id = id
        self.name = name
        self.locale = locale
        self.style = style
    }
}

public struct EAISchemaField: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let key: String
    public let type: String
    public let required: Bool
    public let description: String
    public let location: String?
    public let properties: [EAISchemaField]

    public init(
        id: String = UUID().uuidString,
        key: String,
        type: String = "string",
        required: Bool = false,
        description: String = "",
        location: String? = nil,
        properties: [EAISchemaField] = []
    ) {
        self.id = id
        self.key = key
        self.type = type
        self.required = required
        self.description = description
        self.location = location
        self.properties = properties
    }
}

public struct EAISchemaObject: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let title: String
    public let fields: [EAISchemaField]
    public let method: String?
    public let path: String?
    public let requestBody: [EAISchemaField]
    public let responseBody: [EAISchemaField]
    public let parameters: [EAISchemaField]

    public init(
        id: String = UUID().uuidString,
        title: String,
        fields: [EAISchemaField] = [],
        method: String? = nil,
        path: String? = nil,
        requestBody: [EAISchemaField] = [],
        responseBody: [EAISchemaField] = [],
        parameters: [EAISchemaField] = []
    ) {
        self.id = id
        self.title = title
        self.fields = fields
        self.method = method
        self.path = path
        self.requestBody = requestBody
        self.responseBody = responseBody
        self.parameters = parameters
    }
}

public struct EAITestResultSummary: Sendable, Codable, Hashable {
    public let id: String
    public let total: Int
    public let passed: Int
    public let failed: Int
    public let skipped: Int
    public let durationMS: Double

    public init(
        id: String = UUID().uuidString,
        total: Int,
        passed: Int,
        failed: Int,
        skipped: Int,
        durationMS: Double
    ) {
        self.id = id
        self.total = total
        self.passed = passed
        self.failed = failed
        self.skipped = skipped
        self.durationMS = durationMS
    }
}

public struct EAITestSuite: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let name: String
    public let status: EAITestResultState
    public let tests: [EAITestResult]
    public let durationMS: Double
    public let defaultOpen: Bool

    public init(
        id: String = UUID().uuidString,
        name: String,
        status: EAITestResultState,
        tests: [EAITestResult],
        durationMS: Double = 0,
        defaultOpen: Bool = true
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.tests = tests
        self.durationMS = durationMS
        self.defaultOpen = defaultOpen
    }
}

public struct EAISandboxSession: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let command: String
    public let output: String
    public let isRunning: Bool
    public let elapsed: TimeInterval

    public init(
        id: String = UUID().uuidString,
        command: String,
        output: String = "",
        isRunning: Bool = false,
        elapsed: TimeInterval = 0
    ) {
        self.id = id
        self.command = command
        self.output = output
        self.isRunning = isRunning
        self.elapsed = elapsed
    }
}

public struct EAITranscriptionSegment: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let speaker: String
    public let text: String
    public let startSeconds: TimeInterval
    public let endSeconds: TimeInterval

    public init(
        id: String = UUID().uuidString,
        speaker: String,
        text: String,
        startSeconds: TimeInterval,
        endSeconds: TimeInterval
    ) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
    }
}
