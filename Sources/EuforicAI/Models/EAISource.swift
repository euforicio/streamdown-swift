import Foundation

public struct EAISource: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let title: String
    public let url: URL?
    public let snippet: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        url: URL? = nil,
        snippet: String = ""
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.snippet = snippet
    }
}
