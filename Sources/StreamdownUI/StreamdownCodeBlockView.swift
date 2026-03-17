import Observation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Syntax Highlighter

struct CodeBlockSyntaxHighlighter: Sendable {
    struct Token: Sendable {
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
                "weak", "willSet", "internal", "final", "required",
            ]
        }
        if language.contains("python") {
            return [
                "and", "as", "assert", "async", "await", "break", "class", "continue", "def", "del",
                "elif", "else", "except", "False", "finally", "for", "from", "global", "if", "import",
                "in", "is", "lambda", "None", "nonlocal", "not", "pass", "raise", "return", "try",
                "True", "while", "with", "yield",
            ]
        }
        if language.contains("javascript") || language.contains("typescript") || language.contains("js") || language.contains("tsx") {
            return [
                "await", "break", "case", "catch", "class", "const", "continue", "default", "delete",
                "do", "else", "export", "false", "finally", "for", "function", "if", "import", "in",
                "new", "return", "super", "switch", "this", "throw", "true", "try", "typeof", "while",
                "with", "yield", "var", "let",
            ]
        }
        return [
            "return", "if", "else", "for", "while", "true", "false", "null", "none", "const",
            "let", "var", "class", "import", "from", "function", "async",
        ]
    }

    private static func commentPrefix(for language: String) -> String? {
        if language.contains("python") || language.contains("bash") || language.contains("shell") {
            return "#"
        }
        return "//"
    }

    nonisolated static func tokens(for line: String, language: String?, foreground: Color, secondaryLabel: Color) -> [Token] {
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
                    if current.isNumber || current == "." || current == "x" || current == "X"
                        || current == "a" || current == "b" || current == "f"
                        || current == "A" || current == "B" || current == "F"
                    {
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
                    results.append(Token(text: value, color: foreground, isKeyword: false))
                }
                continue
            }

            if "{}()[]<>.,:;+-/*=%&|!^?~".contains(char) {
                results.append(Token(text: String(char), color: secondaryLabel, isKeyword: false))
                index += 1
                continue
            }

            results.append(Token(text: String(char), color: foreground, isKeyword: false))
            index += 1
        }

        if results.isEmpty {
            results.append(Token(text: " ", color: foreground, isKeyword: false))
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

// MARK: - Render State

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
    private let foreground: Color
    private let secondaryLabel: Color

    convenience init(foreground: Color = Color(white: 0.93), secondaryLabel: Color = Color(white: 0.55)) {
        self.init(code: "", language: nil, foreground: foreground, secondaryLabel: secondaryLabel)
    }

    init(
        code: String,
        language: String?,
        maxDisplayedLines: Int = defaultMaxDisplayedLines,
        foreground: Color = Color(white: 0.93),
        secondaryLabel: Color = Color(white: 0.55)
    ) {
        self.maxDisplayedLines = max(1, maxDisplayedLines)
        self.foreground = foreground
        self.secondaryLabel = secondaryLabel
        let renderResult = Self.renderResult(
            code: code,
            language: language,
            maxDisplayedLines: self.maxDisplayedLines,
            foreground: foreground,
            secondaryLabel: secondaryLabel
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
        let foreground = self.foreground
        let secondaryLabel = self.secondaryLabel
        renderTask?.cancel()
        renderTask = Task { [normalizedCode, normalizedLanguage] in
            let renderResult = await Task.detached(priority: .userInitiated) {
                Self.renderResult(
                    normalizedCode: normalizedCode,
                    normalizedLanguage: normalizedLanguage,
                    maxDisplayedLines: maxDisplayedLines,
                    foreground: foreground,
                    secondaryLabel: secondaryLabel
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

    nonisolated private static func highlightedLines(
        from lineTexts: [String],
        language: String,
        foreground: Color,
        secondaryLabel: Color
    ) -> [AttributedString] {
        lineTexts.map { line in
            let tokens = CodeBlockSyntaxHighlighter.tokens(
                for: line,
                language: language,
                foreground: foreground,
                secondaryLabel: secondaryLabel
            )
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
        maxDisplayedLines: Int,
        foreground: Color,
        secondaryLabel: Color
    ) -> RenderResult {
        renderResult(
            normalizedCode: normalize(code),
            normalizedLanguage: normalize(language),
            maxDisplayedLines: maxDisplayedLines,
            foreground: foreground,
            secondaryLabel: secondaryLabel
        )
    }

    nonisolated private static func renderResult(
        normalizedCode: String,
        normalizedLanguage: String,
        maxDisplayedLines: Int,
        foreground: Color,
        secondaryLabel: Color
    ) -> RenderResult {
        let allLineTexts = lineTexts(from: normalizedCode)
        let displayWindow = trimmedDisplayWindow(
            lineTexts: allLineTexts,
            language: normalizedLanguage,
            maxDisplayedLines: maxDisplayedLines,
            foreground: foreground,
            secondaryLabel: secondaryLabel
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
        maxDisplayedLines: Int,
        foreground: Color,
        secondaryLabel: Color
    ) -> DisplayWindow {
        guard lineTexts.count > maxDisplayedLines else {
            return DisplayWindow(
                displayedLineStart: 0,
                lineTexts: lineTexts,
                highlightedLines: highlightedLines(
                    from: lineTexts,
                    language: language,
                    foreground: foreground,
                    secondaryLabel: secondaryLabel
                )
            )
        }

        let displayedLineStart = lineTexts.count - maxDisplayedLines
        let displayedLineTexts = Array(lineTexts.suffix(maxDisplayedLines))
        return DisplayWindow(
            displayedLineStart: displayedLineStart,
            lineTexts: displayedLineTexts,
            highlightedLines: highlightedLines(
                from: displayedLineTexts,
                language: language,
                foreground: foreground,
                secondaryLabel: secondaryLabel
            )
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

// MARK: - Code Block Content View (inline rendering, replaces CodeBlockView)

public struct StreamdownCodeBlockContent: View {
    let language: String?
    let code: String
    var showLineNumbers: Bool
    var showHeader: Bool

    @Environment(\.streamdownTheme) private var theme
    @State private var renderState: CodeBlockRenderState?
    @State private var copied = false

    public init(
        language: String? = nil,
        code: String,
        showLineNumbers: Bool = false,
        showHeader: Bool = true
    ) {
        self.language = language
        self.code = code
        self.showLineNumbers = showLineNumbers
        self.showHeader = showHeader
    }

    private var lineNumberWidth: CGFloat {
        let lineCount = max(1, (renderState?.displayedLineUpperBound ?? 1))
        let digitCount = CGFloat(max(2, String(lineCount).count))
        return digitCount * 7.5 + 10
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showHeader {
                header
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.vertical, theme.spacing.xs)
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
        .background(theme.colors.tertiaryBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.colors.separator.opacity(0.45), lineWidth: 1)
        )
        .onAppear {
            if renderState == nil {
                renderState = CodeBlockRenderState(
                    code: code,
                    language: language,
                    foreground: theme.colors.foreground,
                    secondaryLabel: theme.colors.secondaryLabel
                )
            }
        }
        .onChange(of: code) { _, newValue in
            renderState?.update(code: newValue, language: language)
        }
        .onChange(of: language) { _, newValue in
            renderState?.update(code: code, language: newValue)
        }
    }

    private var header: some View {
        HStack(spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.sm) {
                if let language, !language.isEmpty {
                    Text(language.lowercased())
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundStyle(theme.colors.secondaryLabel)
                        .textCase(.lowercase)
                        .lineLimit(1)
                }
            }

            Spacer()
            Button {
                copyToClipboard(renderState?.normalizedCode ?? code)
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(copied ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var contentFont: Font {
        .system(size: 11, weight: .regular, design: .monospaced)
    }

    private var lineNumberFont: Font {
        .system(size: 11, weight: .medium, design: .monospaced)
    }

    private var nonNumberedCode: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let renderState {
                ForEach(renderState.highlightedLines.indices, id: \.self) { index in
                    Text(renderState.highlightedLines[index])
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 1)
                        .font(contentFont)
                }
            }
        }
        .padding(.top, 4)
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.xs)
    }

    private var numberedCode: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let renderState {
                ForEach(Array(renderState.lineTexts.enumerated()), id: \.offset) { index, _ in
                    HStack(alignment: .firstTextBaseline, spacing: theme.spacing.sm) {
                        Text("\(renderState.displayedLineStart + index + 1)")
                            .font(lineNumberFont.monospacedDigit())
                            .foregroundStyle(theme.colors.tertiaryLabel)
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
        }
        .padding(.top, 4)
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.xs)
    }

    private func copyToClipboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }
}

// MARK: - Code Block View (outer wrapper with header controls)

struct StreamdownCodeBlockView: View {
    let language: String?
    let code: String
    let startLine: Int?
    let isIncomplete: Bool
    let controlsCopy: Bool
    let controlsDownload: Bool
    let isStreaming: Bool
    let showFullscreen: Bool
    let isMermaid: Bool
    let mermaidPanZoom: Bool

    @Environment(\.streamdownTheme) private var theme
    @State private var copied = false
    @State private var isFullscreen = false

    private let mermaidLanguages = Set(["mermaid", "flowchart", "graphviz"])

    private var normalizedLanguage: String? {
        language?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var cornerRadius: CGFloat { 8 }
    private var headerIconSize: CGFloat { 12 }
    private var controlTapPadding: CGFloat { 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: theme.spacing.sm) {
                if let language {
                    Text(language)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(theme.colors.secondaryLabel)
                        .textCase(.lowercase)
                        .lineLimit(1)
                }
                if let startLine {
                    Text("startLine \(startLine)")
                        .font(.system(size: 11.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(theme.colors.tertiaryLabel)
                        .lineLimit(1)
                }

                Spacer()

                if controlsCopy {
                    Button(action: copy) {
                        headerIcon(
                            systemName: copied ? "checkmark" : "doc.on.doc",
                            foregroundStyle: copied ? Color.green : theme.colors.secondaryLabel
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isStreaming)
                }

                if controlsDownload {
                    Menu {
                        Button("Download as \(defaultFilename)") { download() }
                    } label: {
                        headerIcon(systemName: "arrow.down.to.line")
                    }
                    .disabled(isStreaming)
                }

                if showFullscreen {
                    Button(action: { isFullscreen = true }) {
                        headerIcon(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                    .buttonStyle(.plain)
                    .disabled(isStreaming)
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, 0)
            .overlay(alignment: .bottom) {
                Divider()
            }

            if isIncomplete && code.isEmpty {
                VStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Streaming block...")
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.mutedForeground)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.colors.secondaryBackground)
            } else {
                if shouldRenderMermaid {
                    StreamdownMermaidView(
                        source: code,
                        panZoom: mermaidPanZoom
                    )
                    .frame(minHeight: 120)
                } else {
                    StreamdownCodeBlockContent(
                        language: normalizedLanguage,
                        code: code,
                        showLineNumbers: false,
                        showHeader: false
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(theme.colors.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(theme.colors.separator.opacity(0.45), lineWidth: 1)
                )
        )
        .overlay(alignment: .bottomTrailing) {
            if shouldShowMermaidNote {
                Text("Mermaid rendering not available yet")
                    .font(.caption2)
                    .foregroundStyle(theme.colors.mutedForeground)
                    .padding(theme.spacing.xs)
            }
        }
        #if os(macOS)
        .sheet(isPresented: $isFullscreen) {
            StreamdownCodeFullscreen(language: normalizedLanguage, code: code)
        }
        #else
        .fullScreenCover(isPresented: $isFullscreen) {
            StreamdownCodeFullscreen(language: normalizedLanguage, code: code)
        }
        #endif
    }

    private var defaultFilename: String {
        "\(normalizedLanguage ?? "code").txt"
    }

    private var shouldShowMermaidNote: Bool {
        guard isMermaid else { return false }
        return !shouldRenderMermaid
    }

    private var shouldRenderMermaid: Bool {
        guard isMermaid else { return false }
        return mermaidLanguages.contains(normalizedLanguage ?? "") || normalizedLanguage == "mermaid"
    }

    private func headerIcon(
        systemName: String,
        foregroundStyle: some ShapeStyle = Color(white: 0.55)
    ) -> some View {
        Image(systemName: systemName)
            .font(.system(size: headerIconSize, weight: .medium))
            .foregroundStyle(foregroundStyle)
            .padding(controlTapPadding)
            .contentShape(Rectangle())
    }

    private func copy() {
        #if canImport(UIKit)
        UIPasteboard.general.string = code
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        #endif
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }

    private func download() {
        let filename = "\(normalizedLanguage ?? "code").txt"
        shareFile(code, filename: filename)
    }

    private func shareFile(_ text: String, filename: String) {
        #if canImport(UIKit)
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let file = tempDir.appendingPathComponent(filename)
        try? text.write(to: file, atomically: true, encoding: .utf8)
        let activity = UIActivityViewController(activityItems: [file], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let presenter = root.presentedViewController ?? root
        activity.popoverPresentationController?.sourceView = presenter.view
        presenter.present(activity, animated: true)
        #endif
    }
}

private struct StreamdownCodeFullscreen: View {
    let language: String?
    let code: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.streamdownTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding(theme.spacing.sm)

            StreamdownCodeBlockContent(
                language: language,
                code: code,
                showLineNumbers: false
            )
            .padding()
            Spacer()
        }
        .background(theme.colors.background)
    }
}
