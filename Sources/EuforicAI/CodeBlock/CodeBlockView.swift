import Observation
import SwiftUI

public struct CodeBlockView: View {
    public enum Density {
        case regular
        case compact
    }

    let language: String?
    let code: String
    let title: String?
    let filename: String?
    var showLineNumbers: Bool
    let showHeader: Bool
    let density: Density
    @State private var renderState: CodeBlockRenderState

    private var lineNumberWidth: CGFloat {
        let lineCount = max(1, renderState.displayedLineUpperBound)
        let digitCount = CGFloat(max(2, String(lineCount).count))
        return digitCount * (density == .compact ? 7 : 7.5) + (density == .compact ? 8 : 10)
    }

    @State private var copied = false

    public init(
        language: String? = nil,
        code: String,
        title: String? = nil,
        filename: String? = nil,
        showLineNumbers: Bool = false,
        showHeader: Bool = true,
        density: Density = .regular
    ) {
        self.language = language
        self.code = code
        self.showLineNumbers = showLineNumbers
        self.title = title
        self.filename = filename
        self.showHeader = showHeader
        self.density = density
        _renderState = State(initialValue: CodeBlockRenderState(code: code, language: language))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showHeader {
                header
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, headerVerticalPadding)
                    .overlay(alignment: .bottom) {
                        Divider()
                    }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if showLineNumbers {
                        numberedCode
                    } else {
                        nonNumberedCode
                    }
                }
            }
        }
        .background(EAIColors.tertiaryBackground, in: RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(EAIColors.separator.opacity(0.45), lineWidth: 1)
        )
        .onChange(of: code) { _, newValue in
            renderState.update(code: newValue, language: language)
        }
        .onChange(of: language) { _, newValue in
            renderState.update(code: code, language: newValue)
        }
    }

    private var header: some View {
        HStack(spacing: EAISpacing.sm) {
            HStack(spacing: EAISpacing.sm) {
                if let language, !language.isEmpty {
                    Text(language.lowercased())
                        .font(.system(size: density == .compact ? 11 : 12, weight: .medium, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundStyle(EAIColors.secondaryLabel)
                        .textCase(.lowercase)
                        .lineLimit(1)
                }

                if let filename, !filename.isEmpty {
                    Text(filename)
                        .font(.system(size: density == .compact ? 10.5 : 11.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(EAIColors.tertiaryLabel)
                        .lineLimit(1)
                }
            }

            Spacer()
            Button {
                CopyAction.perform(renderState.normalizedCode, copied: $copied)
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: density == .compact ? 11 : 12, weight: .medium))
                    .foregroundStyle(copied ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, density == .compact ? 2 : 4)
    }

    private var contentFont: Font {
        .system(size: density == .compact ? 10.5 : 11, weight: .regular, design: .monospaced)
    }

    private var lineNumberFont: Font {
        .system(size: density == .compact ? 10.5 : 11, weight: .medium, design: .monospaced)
    }

    private var cornerRadius: CGFloat {
        density == .compact ? 10 : 8
    }

    private var horizontalPadding: CGFloat {
        density == .compact ? EAISpacing.sm : EAISpacing.md
    }

    private var headerVerticalPadding: CGFloat {
        density == .compact ? EAISpacing.xxs : EAISpacing.xs
    }

    private var contentTopPadding: CGFloat {
        density == .compact ? 2 : 4
    }

    private var contentVerticalPadding: CGFloat {
        density == .compact ? EAISpacing.xxs : EAISpacing.xs
    }

    private var nonNumberedCode: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(renderState.highlightedLines.indices, id: \.self) { index in
                Text(renderState.highlightedLines[index])
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 1)
                    .font(contentFont)
            }
        }
        .padding(.top, contentTopPadding)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, contentVerticalPadding)
    }

    private var numberedCode: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(renderState.lineTexts.enumerated()), id: \.offset) { index, _ in
                HStack(alignment: .firstTextBaseline, spacing: EAISpacing.sm) {
                    Text("\(renderState.displayedLineStart + index + 1)")
                        .font(lineNumberFont.monospacedDigit())
                        .foregroundStyle(EAIColors.tertiaryLabel)
                        .lineLimit(1)
                        .frame(width: lineNumberWidth, alignment: .trailing)
                        .padding(.leading, 2)

                    Text(renderState.highlightedLines[index])
                        .font(contentFont)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 1)
                }
                .padding(.leading, 1)
                .padding(.trailing, 1)
            }
        }
        .padding(.top, contentTopPadding)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, contentVerticalPadding)
    }
}

@Observable
@MainActor
final class CodeBlockRenderState {
    private static let defaultMaxDisplayedLines = 400

    private struct DisplayWindow: Sendable {
        let displayedLineStart: Int
        let lineTexts: [String]
        let highlightedLines: [AttributedString]
    }

    private struct RenderResult: Sendable {
        let normalizedCode: String
        let normalizedLanguage: String
        let displayWindow: DisplayWindow
    }

    private(set) var normalizedCode: String
    private(set) var displayedLineStart: Int
    private(set) var lineTexts: [String]
    private(set) var highlightedLines: [AttributedString]
    private(set) var renderVersion = 1

    var displayedLineUpperBound: Int {
        displayedLineStart + lineTexts.count
    }

    private var normalizedLanguage: String
    private var renderTask: Task<Void, Never>?
    private var pendingGeneration = 0
    private let maxDisplayedLines: Int

    convenience init() {
        self.init(code: "", language: nil)
    }

    init(code: String, language: String?, maxDisplayedLines: Int = defaultMaxDisplayedLines) {
        self.maxDisplayedLines = max(1, maxDisplayedLines)
        let renderResult = Self.renderResult(
            code: code,
            language: language,
            maxDisplayedLines: self.maxDisplayedLines
        )
        self.normalizedCode = renderResult.normalizedCode
        self.normalizedLanguage = renderResult.normalizedLanguage
        self.displayedLineStart = renderResult.displayWindow.displayedLineStart
        self.lineTexts = renderResult.displayWindow.lineTexts
        self.highlightedLines = renderResult.displayWindow.highlightedLines
    }

    func update(code: String, language: String?) {
        let normalizedCode = Self.normalize(code)
        let normalizedLanguage = Self.normalize(language)

        guard normalizedCode != self.normalizedCode || normalizedLanguage != self.normalizedLanguage else {
            return
        }

        self.normalizedCode = normalizedCode
        self.normalizedLanguage = normalizedLanguage
        pendingGeneration &+= 1
        let generation = pendingGeneration
        let maxDisplayedLines = self.maxDisplayedLines
        renderTask?.cancel()
        renderTask = Task { [normalizedCode, normalizedLanguage] in
            let renderResult = await Task.detached(priority: .userInitiated) {
                Self.renderResult(
                    normalizedCode: normalizedCode,
                    normalizedLanguage: normalizedLanguage,
                    maxDisplayedLines: maxDisplayedLines
                )
            }.value
            guard !Task.isCancelled else { return }
            self.apply(renderResult, generation: generation)
        }
    }

    nonisolated private static func normalize(_ code: String) -> String {
        code
            .replacingOccurrences(of: "\\r\\n", with: "\n")
            .replacingOccurrences(of: "\\n", with: "\n")
    }

    nonisolated private static func normalize(_ language: String?) -> String {
        language?.lowercased() ?? ""
    }

    nonisolated private static func lineTexts(from code: String) -> [String] {
        code.components(separatedBy: "\n")
    }

    nonisolated private static func highlightedLines(from lineTexts: [String], language: String) -> [AttributedString] {
        lineTexts.map { line in
            let tokens = CodeBlockSyntaxHighlighter.tokens(for: line, language: language)
            var attributed = AttributedString()
            for token in tokens {
                var fragment = AttributedString(token.text)
                fragment.foregroundColor = token.color
                fragment.inlinePresentationIntent = token.isKeyword ? .stronglyEmphasized : nil
                attributed += fragment
            }
            return attributed
        }
    }

    nonisolated private static func renderResult(
        code: String,
        language: String?,
        maxDisplayedLines: Int
    ) -> RenderResult {
        renderResult(
            normalizedCode: normalize(code),
            normalizedLanguage: normalize(language),
            maxDisplayedLines: maxDisplayedLines
        )
    }

    nonisolated private static func renderResult(
        normalizedCode: String,
        normalizedLanguage: String,
        maxDisplayedLines: Int
    ) -> RenderResult {
        let allLineTexts = lineTexts(from: normalizedCode)
        let displayWindow = trimmedDisplayWindow(
            lineTexts: allLineTexts,
            language: normalizedLanguage,
            maxDisplayedLines: maxDisplayedLines
        )
        return RenderResult(
            normalizedCode: normalizedCode,
            normalizedLanguage: normalizedLanguage,
            displayWindow: displayWindow
        )
    }

    nonisolated private static func trimmedDisplayWindow(
        lineTexts: [String],
        language: String,
        maxDisplayedLines: Int
    ) -> DisplayWindow {
        guard lineTexts.count > maxDisplayedLines else {
            return DisplayWindow(
                displayedLineStart: 0,
                lineTexts: lineTexts,
                highlightedLines: highlightedLines(from: lineTexts, language: language)
            )
        }

        let displayedLineStart = lineTexts.count - maxDisplayedLines
        let displayedLineTexts = Array(lineTexts.suffix(maxDisplayedLines))
        return DisplayWindow(
            displayedLineStart: displayedLineStart,
            lineTexts: displayedLineTexts,
            highlightedLines: highlightedLines(from: displayedLineTexts, language: language)
        )
    }

    private func apply(_ renderResult: RenderResult, generation: Int) {
        guard generation == pendingGeneration else { return }
        displayedLineStart = renderResult.displayWindow.displayedLineStart
        lineTexts = renderResult.displayWindow.lineTexts
        highlightedLines = renderResult.displayWindow.highlightedLines
        renderVersion &+= 1
    }
}

private struct CodeBlockSyntaxHighlighter {
    struct Token {
        let text: String
        let color: Color
        let isKeyword: Bool
    }

    private static func keywordSet(for language: String) -> Set<String> {
        if language.contains("swift") || language.contains("swiftui") {
            return [
                "actor", "as", "associatedtype", "await", "break", "case", "catch", "class", "continue",
                "default", "defer", "deinit", "didSet", "do", "dynamic", "enum", "else", "extension",
                "false", "fallthrough", "fileprivate", "for", "func", "guard", "if", "import", "in",
                "init", "inout", "is", "lazy", "let", "mutating", "nonisolated", "nil", "override",
                "private", "protocol", "public", "return", "rethrows", "self", "static", "struct",
                "super", "switch", "throw", "throws", "true", "try", "typealias", "var", "while", "where",
                "weak", "willSet", "internal", "final", "required", "static"
            ]
        }
        if language.contains("python") {
            return [
                "and", "as", "assert", "async", "await", "break", "class", "continue", "def", "del",
                "elif", "else", "except", "False", "finally", "for", "from", "global", "if", "import",
                "in", "is", "lambda", "None", "nonlocal", "not", "pass", "raise", "return", "try",
                "True", "while", "with", "yield"
            ]
        }
        if language.contains("javascript") || language.contains("typescript") || language.contains("js") || language.contains("tsx") {
            return [
                "await", "break", "case", "catch", "class", "const", "continue", "default", "delete",
                "do", "else", "export", "false", "finally", "for", "function", "if", "import", "in",
                "new", "return", "super", "switch", "this", "throw", "true", "try", "typeof", "while",
                "with", "yield", "var", "let", "const"
            ]
        }
        return [
            "return", "if", "else", "for", "while", "true", "false", "null", "none", "const",
            "let", "var", "class", "import", "from", "function", "async"
        ]
    }

    private static func commentPrefix(for language: String) -> String? {
        if language.contains("python") || language.contains("bash") || language.contains("shell") {
            return "#"
        }
        return "//"
    }

    static func tokens(for line: String, language: String?) -> [Token] {
        let normalizedLanguage = (language ?? "").lowercased()
        let keywords = keywordSet(for: normalizedLanguage)
        let normalizedCommentPrefix = commentPrefix(for: normalizedLanguage)

        let chars = Array(line)
        var index = 0
        var results: [Token] = []

        while index < chars.count {
            let char = chars[index]

            if char == "\"" || char == "'" || char == "`" {
                let quote = char
                var value = String(quote)
                index += 1
                while index < chars.count {
                    let current = chars[index]
                    value.append(current)
                    if current == "\\" && index + 1 < chars.count {
                        index += 1
                        value.append(chars[index])
                    } else if current == quote {
                        index += 1
                        break
                    }
                    index += 1
                }
                results.append(Token(text: value, color: .orange, isKeyword: false))
                continue
            }

            if let commentPrefix = normalizedCommentPrefix, isCommentStart(
                at: index,
                in: chars,
                prefix: commentPrefix
            ) {
                let commentText = String(chars[index...])
                if !commentText.isEmpty {
                    results.append(Token(text: commentText, color: .secondary, isKeyword: false))
                }
                break
            }

            if char.isNumber {
                var value = ""
                while index < chars.count {
                    let current = chars[index]
                    if current.isNumber || current == "." || current == "x" || current == "X" || current == "a" || current == "b" || current == "f" || current == "A" || current == "B" || current == "F" {
                        value.append(current)
                        index += 1
                    } else {
                        break
                    }
                }
                results.append(Token(text: value, color: .purple, isKeyword: false))
                continue
            }

            if isIdentifierStart(char) {
                var value = ""
                while index < chars.count {
                    let current = chars[index]
                    if isIdentifier(current) {
                        value.append(current)
                        index += 1
                    } else {
                        break
                    }
                }

                if keywords.contains(value) {
                    results.append(Token(text: value, color: .blue, isKeyword: true))
                } else {
                    results.append(Token(text: value, color: EAIColors.primaryLabel, isKeyword: false))
                }
                continue
            }

            if "{}()[]<>.,:;+-/*=%&|!^?~".contains(char) {
                results.append(Token(text: String(char), color: EAIColors.secondaryLabel, isKeyword: false))
                index += 1
                continue
            }

            results.append(Token(text: String(char), color: EAIColors.primaryLabel, isKeyword: false))
            index += 1
        }

        if results.isEmpty {
            results.append(Token(text: " ", color: EAIColors.primaryLabel, isKeyword: false))
        }
        return results
    }

    private static func isCommentStart(at index: Int, in chars: [Character], prefix: String) -> Bool {
        guard index < chars.count else { return false }
        if prefix == "//" {
            return index + 1 < chars.count && chars[index] == "/" && chars[index + 1] == "/"
        }
        if prefix == "#" {
            return chars[index] == "#"
        }
        return false
    }

    private static func isIdentifierStart(_ character: Character) -> Bool {
        character.isLetter || character == "_"
    }

    private static func isIdentifier(_ character: Character) -> Bool {
        isIdentifierStart(character) || character.isNumber
    }
}

#Preview {
    VStack(spacing: 16) {
        CodeBlockView(language: "swift", code: "let x = 42\nprint(x)")
        CodeBlockView(language: "python", code: "x = 42\nprint(x)", showLineNumbers: true)
        CodeBlockView(language: "javascript", code: "const value = 42\nconsole.log(value // comment)")
    }
    .padding()
}
