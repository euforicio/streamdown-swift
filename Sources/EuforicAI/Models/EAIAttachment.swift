import Foundation

public enum EAIAttachmentKind: String, Sendable, Codable, Hashable {
    case file
    case image
    case code
    case document
}

public struct EAIAttachment: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let name: String
    public let kind: EAIAttachmentKind
    public let size: Int64?
    public let mimeType: String?

    public init(
        id: String = UUID().uuidString,
        name: String,
        kind: EAIAttachmentKind = .file,
        size: Int64? = nil,
        mimeType: String? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.size = size
        self.mimeType = mimeType
    }

    public var formattedSize: String? {
        guard let size else { return nil }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    public var iconName: String {
        switch kind {
        case .file: "doc.fill"
        case .image: "photo.fill"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .document: "doc.text.fill"
        }
    }
}
