import Foundation

public struct StreamdownParser: Sendable {
    private struct LineInfo {
        let text: String
        let start: Int
        let end: Int
    }

    private struct CodeFenceInfo {
        let fence: String
        let language: String?
        let startLine: Int?
    }

    // MARK: - Regex Pattern Cache

    private static let patternCacheLock = NSLock()
    nonisolated(unsafe) private static var openTagPatternCache: [String: NSRegularExpression] = [:]
    nonisolated(unsafe) private static var closeTagPatternCache: [String: NSRegularExpression] = [:]

    private static func cachedOpenTagPattern(for tag: String) -> NSRegularExpression? {
        let key = tag.lowercased()
        patternCacheLock.lock()
        defer { patternCacheLock.unlock() }
        if let cached = openTagPatternCache[key] {
            return cached
        }
        let escapedTag = NSRegularExpression.escapedPattern(for: key)
        guard let regex = try? NSRegularExpression(
            pattern: "<\\s*\(escapedTag)\\b[^>]*>",
            options: [.caseInsensitive]
        ) else { return nil }
        openTagPatternCache[key] = regex
        return regex
    }

    private static func cachedCloseTagPattern(for tag: String) -> NSRegularExpression? {
        let key = tag.lowercased()
        patternCacheLock.lock()
        defer { patternCacheLock.unlock() }
        if let cached = closeTagPatternCache[key] {
            return cached
        }
        let escapedTag = NSRegularExpression.escapedPattern(for: key)
        guard let regex = try? NSRegularExpression(
            pattern: "</\\s*\(escapedTag)\\b[^>]*>",
            options: [.caseInsensitive]
        ) else { return nil }
        closeTagPatternCache[key] = regex
        return regex
    }

    // MARK: - Public API

    public static func normalizeContent(
        _ content: String,
        normalizeHtmlIndentation: Bool
    ) -> String {
        let normalizedInput = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        guard normalizeHtmlIndentation else {
            return normalizedInput
        }

        guard let startPattern = try? NSRegularExpression(pattern: "^[ \\t]*<[\\w!/?-]") else {
            return normalizedInput
        }
        let full = normalizedInput as NSString
        guard startPattern.numberOfMatches(
            in: normalizedInput,
            options: [],
            range: NSRange(location: 0, length: full.length)
        ) > 0 else {
            return normalizedInput
        }

        guard let regex = try? NSRegularExpression(
            pattern: "(^|\\n)[ \\t]{4,}(?=<[\\w!/?-])",
            options: []
        ) else {
            return normalizedInput
        }

        let range = NSRange(location: 0, length: full.length)
        return regex.stringByReplacingMatches(
            in: normalizedInput,
            options: [],
            range: range,
            withTemplate: "$1"
        )
    }

    public static func parse(
        _ normalized: String,
        mode: StreamdownMode,
        parseIncompleteMarkdown: Bool
    ) -> [StreamdownParsedBlock] {
        if normalized.isEmpty {
            return []
        }

        let footnoteReferencePattern = #/\[\^[\w-]{1,200}\](?!:)/#
        let footnoteDefinitionPattern = #/\[\^[\w-]{1,200}\]:/#
        if normalized.contains(footnoteReferencePattern)
            || normalized.contains(footnoteDefinitionPattern) {
            return [
                StreamdownParsedBlock(
                    block: .markdown(normalized),
                    range: 0..<normalized.count
                )
            ]
        }

        let isStreaming = mode == .streaming
        let effectiveParseIncomplete = isStreaming ? parseIncompleteMarkdown : false
        let lines = lineInfos(in: normalized)

        var index = 0
        var blocks: [StreamdownParsedBlock] = []
        var currentMarkdown: [String] = []
        var currentMarkdownStartLine: Int?
        var currentMarkdownHasUnclosedMathBlock = false
        var previousBlockWasCode = false

        func flushMarkdown(upTo lastLineIndex: Int) {
            guard let startLine = currentMarkdownStartLine, !currentMarkdown.isEmpty else { return }
            blocks.append(
                StreamdownParsedBlock(
                    block: .markdown(currentMarkdown.joined(separator: "\n")),
                    range: lines[startLine].start..<lines[lastLineIndex].end
                )
            )
            currentMarkdown.removeAll(keepingCapacity: true)
            currentMarkdownStartLine = nil
            currentMarkdownHasUnclosedMathBlock = false
        }

        while index < lines.count {
            let line = lines[index].text

            if !currentMarkdown.isEmpty {
                if isStreaming
                    && !previousBlockWasCode
                    && currentMarkdownHasUnclosedMathBlock {
                    currentMarkdown.append(line)
                    updateMathBlockState(
                        with: line,
                        hasUnclosedMathBlock: &currentMarkdownHasUnclosedMathBlock
                    )
                    index += 1
                    continue
                }
            }

            if let htmlBlock = parseHTMLBlock(lines: lines, startIndex: &index) {
                if currentMarkdownStartLine != nil {
                    flushMarkdown(upTo: index - htmlBlock.lineCount - 1)
                }
                blocks.append(
                    StreamdownParsedBlock(
                        block: .markdown(htmlBlock.text),
                        range: htmlBlock.start..<htmlBlock.end
                    )
                )
                previousBlockWasCode = false
                continue
            }

            if let codeInfo = parseCodeFenceStart(line: line) {
                if currentMarkdownStartLine != nil {
                    flushMarkdown(upTo: index - 1)
                }

                let blockStart = lines[index].start
                index += 1
                var codeLines: [String] = []
                var foundEnd = false

                while index < lines.count {
                    if isCodeFenceEnd(lines[index].text, fence: codeInfo.fence) {
                        foundEnd = true
                        index += 1
                        break
                    }

                    codeLines.append(lines[index].text)
                    index += 1
                }

                let code = codeLines.joined(separator: "\n")
                let isIncomplete = isStreaming && !foundEnd
                let blockEndLine = max(0, min(index - 1, lines.count - 1))
                let blockRange = blockStart..<lines[blockEndLine].end

                if !foundEnd && !effectiveParseIncomplete {
                    blocks.append(
                        StreamdownParsedBlock(
                            block: .markdown(codeInfo.fence + "\n" + code),
                            range: blockRange
                        )
                    )
                    previousBlockWasCode = false
                    continue
                }

                blocks.append(
                    StreamdownParsedBlock(
                        block: .code(
                            language: codeInfo.language,
                            code: code,
                            startLine: codeInfo.startLine,
                            isIncomplete: isIncomplete
                        ),
                        range: blockRange
                    )
                )
                previousBlockWasCode = true
                continue
            }

            if let table = parseTable(lines: lines, startIndex: index, isStreaming: isStreaming) {
                if currentMarkdownStartLine != nil {
                    flushMarkdown(upTo: index - 1)
                }
                blocks.append(
                    StreamdownParsedBlock(
                        block: table.block,
                        range: lines[index].start..<lines[table.nextIndex - 1].end
                    )
                )
                index = table.nextIndex
                previousBlockWasCode = false
                continue
            }

            if currentMarkdownStartLine == nil {
                currentMarkdownStartLine = index
            }
            currentMarkdown.append(line)
            updateMathBlockState(
                with: line,
                hasUnclosedMathBlock: &currentMarkdownHasUnclosedMathBlock
            )
            index += 1
            previousBlockWasCode = false
        }

        if let startLine = currentMarkdownStartLine, !currentMarkdown.isEmpty {
            blocks.append(
                StreamdownParsedBlock(
                    block: .markdown(currentMarkdown.joined(separator: "\n")),
                    range: lines[startLine].start..<lines[lines.count - 1].end
                )
            )
        }

        return blocks
    }

    public static func parseBlocks(
        content: String,
        mode: StreamdownMode = .streaming,
        parseIncompleteMarkdown: Bool = true,
        normalizeHtmlIndentation: Bool = false
    ) -> [StreamdownBlock] {
        let normalized = normalizeContent(content, normalizeHtmlIndentation: normalizeHtmlIndentation)
        return parse(normalized, mode: mode, parseIncompleteMarkdown: parseIncompleteMarkdown).map(\.block)
    }

    // MARK: - Private helpers

    private static func lineInfos(in content: String) -> [LineInfo] {
        var lines: [LineInfo] = []
        var lineStartIndex = content.startIndex
        var lineStartOffset = 0
        var currentOffset = 0
        var index = content.startIndex

        while index < content.endIndex {
            let character = content[index]
            if character == "\n" {
                lines.append(
                    LineInfo(
                        text: String(content[lineStartIndex..<index]),
                        start: lineStartOffset,
                        end: currentOffset + 1
                    )
                )
                index = content.index(after: index)
                currentOffset += 1
                lineStartIndex = index
                lineStartOffset = currentOffset
                continue
            }

            currentOffset += 1
            index = content.index(after: index)
        }

        lines.append(
            LineInfo(
                text: String(content[lineStartIndex..<content.endIndex]),
                start: lineStartOffset,
                end: currentOffset
            )
        )

        return lines
    }

    private static func parseCodeFenceStart(line: String) -> CodeFenceInfo? {
        let characters = Array(line)
        var start = 0

        while start < characters.count && start < 3 && (characters[start] == " " || characters[start] == "\t") {
            start += 1
        }

        guard start < characters.count else {
            return nil
        }

        let fenceCharacter = characters[start]
        guard fenceCharacter == "`" || fenceCharacter == "~" else {
            return nil
        }

        var fenceEnd = start + 1
        while fenceEnd < characters.count && characters[fenceEnd] == fenceCharacter {
            fenceEnd += 1
        }

        let fenceLength = fenceEnd - start
        guard fenceLength >= 3 else {
            return nil
        }

        let fence = String(repeating: String(fenceCharacter), count: fenceLength)
        let remainder = String(characters[fenceEnd...]).trimmingCharacters(in: .whitespaces)

        if remainder.isEmpty {
            return CodeFenceInfo(fence: fence, language: nil, startLine: nil)
        }

        let parts = remainder.split(whereSeparator: { $0 == " " || $0 == "\t" })
        var language: String?
        var startLine: Int?

        for part in parts {
            let token = part.trimmingCharacters(in: .whitespaces)
            if token.isEmpty {
                continue
            }

            if token.lowercased().hasPrefix("startline=") {
                startLine = Int(token.lowercased().dropFirst("startline=".count))
            } else if language == nil {
                language = token
            }
        }

        return CodeFenceInfo(fence: fence, language: language, startLine: startLine)
    }

    private static func isCodeFenceEnd(_ line: String, fence: String) -> Bool {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        guard let first = fence.first else { return false }
        return !trimmedLine.isEmpty
            && trimmedLine.allSatisfy { $0 == first }
            && trimmedLine.count >= fence.count
    }

    private static func parseHTMLBlock(
        lines: [LineInfo],
        startIndex: inout Int
    ) -> (text: String, start: Int, end: Int, lineCount: Int)? {
        guard startIndex < lines.count else { return nil }

        let firstLine = lines[startIndex].text
        guard let openingTag = htmlBlockStartTag(in: firstLine) else {
            return nil
        }

        if htmlVoidTags.contains(openingTag.lowercased()) {
            let start = lines[startIndex].start
            let end = lines[startIndex].end
            startIndex += 1
            return (firstLine, start, end, 1)
        }

        var htmlLines: [String] = [firstLine]
        let blockStart = lines[startIndex].start
        let initialIndex = startIndex
        startIndex += 1
        var openTags: [String] = [openingTag.lowercased()]

        while startIndex < lines.count && !openTags.isEmpty {
            let line = lines[startIndex].text
            htmlLines.append(line)

            // Check for new nested block-level tags opening on this line
            if let nestedTag = htmlBlockStartTag(in: line) {
                let nestedLower = nestedTag.lowercased()
                if !htmlVoidTags.contains(nestedLower) {
                    let nestedOpenCount = countNonSelfClosingOpenTags(line: line, tag: nestedLower)
                    let nestedCloseCount = countClosingTags(line: line, tag: nestedLower)
                    let netNested = nestedOpenCount - nestedCloseCount
                    if netNested > 0 {
                        openTags.append(contentsOf: Array(repeating: nestedLower, count: netNested))
                        startIndex += 1
                        continue
                    }
                }
            }

            guard let currentTag = openTags.last else {
                break
            }

            let openCount = countNonSelfClosingOpenTags(line: line, tag: currentTag)
            if openCount > 0 {
                openTags.append(contentsOf: Array(repeating: currentTag, count: openCount))
            }

            let closeCount = countClosingTags(line: line, tag: currentTag)
            if closeCount > 0 {
                for _ in 0..<closeCount where openTags.last == currentTag {
                    openTags.removeLast()
                }
            }

            startIndex += 1
        }

        let blockEndIndex = min(max(startIndex - 1, initialIndex), lines.count - 1)
        return (
            htmlLines.joined(separator: "\n"),
            blockStart,
            lines[blockEndIndex].end,
            blockEndIndex - initialIndex + 1
        )
    }

    private static func htmlBlockStartTag(in line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.hasPrefix("<"),
              !trimmed.hasPrefix("</"),
              !trimmed.hasPrefix("<!"),
              !trimmed.hasPrefix("<?") else {
            return nil
        }

        var tag = ""
        var index = trimmed.startIndex

        guard trimmed[index] == "<" else {
            return nil
        }

        index = trimmed.index(after: index)
        if index == trimmed.endIndex {
            return nil
        }

        while index < trimmed.endIndex {
            let character = trimmed[index]
            if character.isWhitespace || character == ">" || character == "/" {
                break
            }
            if character.isASCII && (character.isLetter || character.isNumber || character == "-" || character == "_") {
                tag.append(character.lowercased())
            } else {
                break
            }
            index = trimmed.index(after: index)
        }

        guard !tag.isEmpty else {
            return nil
        }

        let selfClosing = trimmed.hasSuffix("/>") || trimmed.range(of: #"/>$"#, options: .regularExpression) != nil
        if selfClosing {
            return nil
        }

        return tag
    }

    private static let htmlVoidTags: Set<String> = [
        "area", "base", "br", "col", "embed", "hr", "img",
        "input", "link", "meta", "param", "source", "track", "wbr",
    ]

    private static func countNonSelfClosingOpenTags(line: String, tag: String) -> Int {
        guard !htmlVoidTags.contains(tag.lowercased()) else { return 0 }

        guard let regex = cachedOpenTagPattern(for: tag) else { return 0 }

        let nsLine = line as NSString
        let matches = regex.matches(
            in: line,
            range: NSRange(location: 0, length: nsLine.length)
        )

        var count = 0
        for match in matches {
            let matched = nsLine.substring(with: match.range)
            if matched.hasSuffix("/>") || matched.hasSuffix(" />") {
                continue
            }
            count += 1
        }
        return count
    }

    private static func countClosingTags(line: String, tag: String) -> Int {
        guard let regex = cachedCloseTagPattern(for: tag) else { return 0 }

        let nsLine = line as NSString
        return regex.numberOfMatches(
            in: line,
            range: NSRange(location: 0, length: nsLine.length)
        )
    }

    private static func isMathBlockUnclosed(_ markdown: String) -> Bool {
        var hasUnclosedMathBlock = false
        updateMathBlockState(
            with: markdown,
            hasUnclosedMathBlock: &hasUnclosedMathBlock
        )
        return hasUnclosedMathBlock
    }

    private static func updateMathBlockState(
        with text: String,
        hasUnclosedMathBlock: inout Bool
    ) {
        var count = 0
        var index = text.startIndex
        var isEscaped = false

        while index < text.endIndex {
            let character = text[index]
            if character == "\\" && !isEscaped {
                isEscaped = true
                index = text.index(after: index)
                continue
            }

            if !isEscaped && character == "$", text.distance(from: index, to: text.endIndex) > 1 {
                let next = text.index(after: index)
                if text[next] == "$" {
                    count += 1
                    index = text.index(after: next)
                    continue
                }
            }

            isEscaped = false
            index = text.index(after: index)
        }

        if count.isMultiple(of: 2) {
            return
        }

        hasUnclosedMathBlock.toggle()
    }

    private static func parseTable(
        lines: [LineInfo],
        startIndex: Int,
        isStreaming: Bool
    ) -> (block: StreamdownBlock, nextIndex: Int)? {
        guard startIndex + 1 < lines.count else { return nil }

        let headerLine = lines[startIndex].text
        let separatorLine = lines[startIndex + 1].text

        guard headerLine.contains("|"), isSeparatorRow(separatorLine) else {
            return nil
        }

        let headers = parseTableRow(headerLine)
        guard headers.count >= 2 else {
            return nil
        }

        var index = startIndex + 2
        var rows: [[String]] = []

        while index < lines.count {
            let line = lines[index].text
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !line.contains("|") {
                break
            }

            let row = parseTableRow(line)
            if row.isEmpty {
                break
            }

            rows.append(row)
            index += 1
        }

        let onlyTrailingWhitespaceLines = index < lines.count && lines[index...].allSatisfy {
            $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let preservesStreamingTableTail = isStreaming && rows.isEmpty && onlyTrailingWhitespaceLines
        let nextIndex = preservesStreamingTableTail ? lines.count : index
        let isIncomplete = isStreaming && (nextIndex >= lines.count)
        return (
            .table(headers: headers, rows: rows, isIncomplete: isIncomplete),
            nextIndex
        )
    }

    private static func isSeparatorRow(_ line: String) -> Bool {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        if trimmedLine.isEmpty { return false }

        let parts = parseTableRow(trimmedLine)
        if parts.count < 2 { return false }

        return parts.allSatisfy { value in
            let token = value.trimmingCharacters(in: .whitespaces)
            guard !token.isEmpty, token.contains("-") else { return false }
            return token.allSatisfy { character in
                character == "-" || character == ":"
            }
        }
    }

    private static func parseTableRow(_ line: String) -> [String] {
        var normalized = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let hadTrailingPipe = normalized.hasSuffix("|")

        if normalized.hasPrefix("|") {
            normalized.removeFirst()
        }
        if normalized.hasSuffix("|") {
            normalized.removeLast()
        }

        if normalized.isEmpty {
            return []
        }

        var cells: [String] = []
        var current = ""
        var isEscaped = false

        for char in normalized {
            if isEscaped {
                current.append(char)
                isEscaped = false
                continue
            }

            if char == "\\" {
                isEscaped = true
                continue
            }

            if char == "|" {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
                continue
            }

            current.append(char)
        }

        if isEscaped {
            current.append("\\")
        }

        if !current.isEmpty || hadTrailingPipe {
            cells.append(current.trimmingCharacters(in: .whitespaces))
        }

        return cells
    }
}

public extension String {
    func characterSlice(from offset: Int) -> String {
        guard offset > 0 else { return self }
        guard offset < count else { return "" }
        let start = index(startIndex, offsetBy: offset)
        return String(self[start...])
    }
}
