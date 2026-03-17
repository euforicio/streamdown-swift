@preconcurrency import MarkdownUI
import Foundation
import Observation
import Streamdown
import SwiftUI

struct ParsedMarkdownContent: @unchecked Sendable {
    let value: MarkdownContent

    var plainText: String {
        value.renderPlainText()
    }
}

struct StreamdownInlineContent: Sendable {
    let attributed: AttributedString

    var characters: AttributedString.CharacterView {
        attributed.characters
    }
}

struct StreamdownMarkdownRenderBlock: Identifiable, Sendable {
    let id: String
    let source: String
    let content: ParsedMarkdownContent
}

struct StreamdownCodeRenderBlock: Identifiable, Sendable {
    let id: String
    let language: String?
    let code: String
    let startLine: Int?
    let isIncomplete: Bool
}

struct StreamdownTableRenderBlock: Identifiable, Sendable {
    let id: String
    let headers: [String]
    let rows: [[String]]
    let isIncomplete: Bool
    let headerInline: [StreamdownInlineContent?]
    let rowInline: [[StreamdownInlineContent?]]
    let columnWeights: [CGFloat]
}

enum StreamdownRenderedBlock: Identifiable, Sendable {
    case markdown(StreamdownMarkdownRenderBlock)
    case code(StreamdownCodeRenderBlock)
    case table(StreamdownTableRenderBlock)

    var id: String {
        switch self {
        case let .markdown(block):
            block.id
        case let .code(block):
            block.id
        case let .table(block):
            block.id
        }
    }
}

struct StreamdownRenderSnapshot: Sendable {
    let normalizedContent: String
    let parsedBlocks: [StreamdownParsedBlock]
    let blocks: [StreamdownRenderedBlock]
    let reusedBlockCount: Int
    let reusedRenderedBlockCount: Int

    static let empty = StreamdownRenderSnapshot(
        normalizedContent: "",
        parsedBlocks: [],
        blocks: [],
        reusedBlockCount: 0,
        reusedRenderedBlockCount: 0
    )
}

@MainActor
@Observable
public final class StreamdownRenderModel {
    private(set) var snapshot: StreamdownRenderSnapshot = .empty

    @ObservationIgnored private let parser: StreamdownRenderActor
    @ObservationIgnored private var renderTask: Task<Void, Never>?
    @ObservationIgnored private var requestID = 0

    public init(parser: StreamdownRenderActor = StreamdownRenderActor()) {
        self.parser = parser
    }

    func render(
        content: String,
        mode: StreamdownMode,
        parseIncompleteMarkdown: Bool,
        normalizeHtmlIndentation: Bool
    ) async {
        requestID += 1
        let currentRequestID = requestID
        let previousSnapshot = snapshot

        renderTask?.cancel()
        renderTask = Task.detached(priority: .userInitiated) { [parser] in
            let nextSnapshot = await parser.renderSnapshot(
                content: content,
                mode: mode,
                parseIncompleteMarkdown: parseIncompleteMarkdown,
                normalizeHtmlIndentation: normalizeHtmlIndentation,
                previous: previousSnapshot
            )

            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard self.requestID == currentRequestID else { return }
                self.snapshot = nextSnapshot
            }
        }
    }

    func cancel() {
        renderTask?.cancel()
        renderTask = nil
    }
}

public actor StreamdownRenderActor {
    private let artificialDelayNanoseconds: UInt64

    public init(artificialDelayNanoseconds: UInt64 = 0) {
        self.artificialDelayNanoseconds = artificialDelayNanoseconds
    }

    func renderSnapshot(
        content: String,
        mode: StreamdownMode,
        parseIncompleteMarkdown: Bool,
        normalizeHtmlIndentation: Bool,
        previous: StreamdownRenderSnapshot?
    ) async -> StreamdownRenderSnapshot {
        if artificialDelayNanoseconds > 0 {
            do {
                try await Task.sleep(nanoseconds: artificialDelayNanoseconds)
            } catch {
                return previous ?? .empty
            }
        }

        guard !Task.isCancelled else {
            return previous ?? .empty
        }

        let normalized = StreamdownParser.normalizeContent(
            content,
            normalizeHtmlIndentation: normalizeHtmlIndentation
        )

        let parsedBlocks: [StreamdownParsedBlock]
        let reusedBlockCount: Int

        if let previous,
           normalized.hasPrefix(previous.normalizedContent),
           !previous.parsedBlocks.isEmpty {
            let stableBlocks = Array(previous.parsedBlocks.dropLast())
            let offset = stableBlocks.last?.range.upperBound ?? 0
            let tailContent = normalized.characterSlice(from: offset)
            let tailBlocks = StreamdownParser.parse(
                tailContent,
                mode: mode,
                parseIncompleteMarkdown: parseIncompleteMarkdown
            ).map { $0.offsetting(by: offset) }

            parsedBlocks = stableBlocks + tailBlocks
            reusedBlockCount = stableBlocks.count
        } else {
            parsedBlocks = StreamdownParser.parse(
                normalized,
                mode: mode,
                parseIncompleteMarkdown: parseIncompleteMarkdown
            )
            reusedBlockCount = 0
        }

        let preparedBlocks = prepareBlocks(from: parsedBlocks, previous: previous)

        return StreamdownRenderSnapshot(
            normalizedContent: normalized,
            parsedBlocks: parsedBlocks,
            blocks: preparedBlocks.blocks,
            reusedBlockCount: reusedBlockCount,
            reusedRenderedBlockCount: preparedBlocks.reusedCount
        )
    }

    private func prepareBlocks(
        from parsedBlocks: [StreamdownParsedBlock],
        previous: StreamdownRenderSnapshot?
    ) -> (blocks: [StreamdownRenderedBlock], reusedCount: Int) {
        let previousBlocks = Dictionary(
            uniqueKeysWithValues: (previous?.blocks ?? []).map { ($0.id, $0) }
        )
        var reusedCount = 0

        let blocks = parsedBlocks.map { parsedBlock in
            let blockID: String

            switch parsedBlock.block {
            case .markdown:
                blockID = "markdown-\(parsedBlock.range.lowerBound)"
            case .code:
                blockID = "code-\(parsedBlock.range.lowerBound)"
            case .table:
                blockID = "table-\(parsedBlock.range.lowerBound)"
            }

            if let previousBlock = previousBlocks[blockID],
               Self.canReuse(previousBlock, for: parsedBlock.block) {
                reusedCount += 1
                return previousBlock
            }

            switch parsedBlock.block {
            case let .markdown(source):
                return .markdown(
                    StreamdownMarkdownRenderBlock(
                        id: blockID,
                        source: source,
                        content: ParsedMarkdownContent(value: MarkdownContent(source))
                    )
                )
            case let .code(language, code, startLine, isIncomplete):
                return .code(
                    StreamdownCodeRenderBlock(
                        id: blockID,
                        language: language,
                        code: code,
                        startLine: startLine,
                        isIncomplete: isIncomplete
                    )
                )
            case let .table(headers, rows, isIncomplete):
                return .table(
                    StreamdownTableRenderBlock(
                        id: blockID,
                        headers: headers,
                        rows: rows,
                        isIncomplete: isIncomplete,
                        headerInline: headers.map(Self.prepareInlineContent),
                        rowInline: rows.map { $0.map(Self.prepareInlineContent) },
                        columnWeights: Self.columnWeights(headers: headers, rows: rows)
                    )
                )
            }
        }

        return (blocks, reusedCount)
    }

    private static func canReuse(
        _ renderedBlock: StreamdownRenderedBlock,
        for parsedBlock: StreamdownBlock
    ) -> Bool {
        switch (renderedBlock, parsedBlock) {
        case let (.markdown(rendered), .markdown(source)):
            return rendered.source == source
        case let (.code(rendered), .code(language, code, startLine, isIncomplete)):
            return rendered.language == language
                && rendered.code == code
                && rendered.startLine == startLine
                && rendered.isIncomplete == isIncomplete
        case let (.table(rendered), .table(headers, rows, isIncomplete)):
            return rendered.headers == headers
                && rendered.rows == rows
                && rendered.isIncomplete == isIncomplete
        default:
            return false
        }
    }

    private static func prepareInlineContent(_ text: String) -> StreamdownInlineContent? {
        guard containsInlineMarkdownSyntax(text) else {
            return nil
        }

        if let parsed = parseInlineMarkdown(text) {
            return StreamdownInlineContent(attributed: parsed)
        }

        let unescaped = unescapedInlineMarkdown(text)
        guard unescaped != text, let parsed = parseInlineMarkdown(unescaped) else {
            return nil
        }
        return StreamdownInlineContent(attributed: parsed)
    }

    private static func containsInlineMarkdownSyntax(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }

        if text.contains(#/`[^`\n]+`/#) { return true }
        if text.contains(#/\[[^\]\n]+\]\([^)]+\)/#) { return true }
        if text.contains(#/\*\*[^*\n]+\*\*/#) { return true }
        if text.contains(#/\*[^*\n]+\*/#) { return true }
        if text.contains(#/~~[^~\n]+~~/#) { return true }
        if text.contains(#/\\[*_`\[\]()~]/#) { return true }
        if text.contains(#/(^|[^\w])__[^_\n]+__(?=[^\w]|$)/#) { return true }
        if text.contains(#/(^|[^\w])_[^_\n]+_(?=[^\w]|$)/#) { return true }

        return false
    }

    private static func parseInlineMarkdown(_ text: String) -> AttributedString? {
        do {
            return try AttributedString(
                markdown: text,
                options: .init(
                    interpretedSyntax: .inlineOnly,
                    failurePolicy: .returnPartiallyParsedIfPossible
                )
            )
        } catch {
            return nil
        }
    }

    private static func unescapedInlineMarkdown(_ text: String) -> String {
        let scalarPairs: [String: String] = [
            "\\*": "*",
            "\\_": "_",
            "\\`": "`",
            "\\[": "[",
            "\\]": "]",
            "\\(": "(",
            "\\)": ")",
            "\\~": "~",
        ]

        return scalarPairs.reduce(text) { partial, pair in
            partial.replacingOccurrences(of: pair.key, with: pair.value)
        }
    }

    private static func columnWeights(headers: [String], rows: [[String]]) -> [CGFloat] {
        let columnCount = max(headers.count, rows.reduce(0) { max($0, $1.count) })
        guard columnCount > 0 else { return [] }

        return (0..<columnCount).map { index in
            let headerWeight = estimatedContentWeight(headers[safe: index] ?? "")
            let rowWeight = rows.map { row in
                estimatedContentWeight(row[safe: index] ?? "")
            }.max() ?? 1
            return max(headerWeight, rowWeight, 1)
        }
    }

    private static func estimatedContentWeight(_ text: String) -> CGFloat {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 1 }

        let cappedLength = min(trimmed.count, 120)
        let emphasisBonus = trimmed.contains("**") || trimmed.contains("_") || trimmed.contains("`") ? 2 : 0
        let linkBonus = trimmed.contains("](") ? 4 : 0
        return CGFloat(cappedLength + emphasisBonus + linkBonus)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
