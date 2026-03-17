import Observation
import SwiftUI

public struct TerminalView: View {
    let output: String
    let isStreaming: Bool
    var exitCode: Int32?
    var showWindowChrome: Bool
    var showWindowControls: Bool
    var title: String
    var autoScroll: Bool
    var onClear: (() -> Void)?

    @State private var renderState: TerminalRenderState
    @State private var copied = false

    public init(
        output: String,
        isStreaming: Bool = false,
        exitCode: Int32? = nil,
        title: String = "Terminal",
        autoScroll: Bool = true,
        showWindowChrome: Bool = true,
        showWindowControls: Bool = false,
        onClear: (() -> Void)? = nil
    ) {
        self.output = output
        self.isStreaming = isStreaming
        self.exitCode = exitCode
        self.title = title
        self.autoScroll = autoScroll
        self.showWindowChrome = showWindowChrome
        self.showWindowControls = showWindowControls
        self.onClear = onClear
        _renderState = State(initialValue: TerminalRenderState(output: output))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showWindowChrome {
                header
            }

            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ansiOutput
                            .textSelection(.enabled)
                            .padding(.horizontal, EAISpacing.md)
                            .padding(.vertical, EAISpacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)

                        if isStreaming {
                            StreamingCursor()
                                .padding(.horizontal, EAISpacing.md)
                                .padding(.bottom, EAISpacing.sm)
                                .padding(.top, 1)
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("terminal-tail")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 300)
                .onAppear { scrollToTail(using: proxy) }
                .onChange(of: renderState.renderVersion) { _, _ in
                    scrollToTail(using: proxy)
                }
                .onChange(of: isStreaming) { _, _ in
                    scrollToTail(using: proxy)
                }
            }
        }
        .padding(.bottom, EAISpacing.xs)
        .background(
            Color(.sRGB, red: 0.06, green: 0.06, blue: 0.07, opacity: 1),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.sRGB, white: 1, opacity: 0.08), lineWidth: 1)
        )
        .onChange(of: output) { _, newValue in
            renderState.update(output: newValue)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("terminal-view-root")
    }

    private var header: some View {
        HStack(spacing: EAISpacing.sm) {
            if showWindowControls {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red.opacity(0.9))
                        .frame(width: 10, height: 10)
                    Circle()
                        .fill(Color.yellow.opacity(0.9))
                        .frame(width: 10, height: 10)
                    Circle()
                        .fill(Color.green.opacity(0.9))
                        .frame(width: 10, height: 10)
                }
                .padding(.trailing, 2)
            }

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(.sRGB, white: 0.78, opacity: 1))

            Spacer()

            if isStreaming {
                ShimmerView(
                    lineCount: 1,
                    widths: [46],
                    lineHeight: 7,
                    cornerRadius: 3
                )
                .frame(width: 46, height: 7)
            }

            Button {
                CopyAction.perform(renderState.rawOutput, copied: $copied)
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(copied ? .green : .secondary)
            }
            .buttonStyle(.plain)

            if onClear != nil {
                Button {
                    onClear?()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if let exitCode {
                Text("exit \(exitCode)")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(exitCode == 0 ? Color.secondary : Color.red)
            }
        }
        .padding(.horizontal, EAISpacing.md)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider().background(Color.white.opacity(0.1))
        }
    }

    @ViewBuilder
    private var ansiOutput: some View {
        if renderState.normalizedOutput.isEmpty {
            Text(" ")
                .foregroundStyle(.green)
                .accessibilityIdentifier("terminal-view-output")
        } else {
            Text(renderState.attributedOutput)
                .foregroundStyle(.green)
                .font(.system(size: 12, design: .monospaced))
                .accessibilityIdentifier("terminal-view-output")
        }
    }

    private func scrollToTail(using proxy: ScrollViewProxy) {
        guard autoScroll else { return }

        withAnimation(nil) {
            proxy.scrollTo("terminal-tail", anchor: .bottom)
        }
    }
}

private extension Array where Element == ParsedAnsiSegment {
    var attributed: AttributedString {
        var attributed = AttributedString()
        for segment in self {
            var fragment = AttributedString(segment.text)
            fragment.foregroundColor = segment.style.foreground
            if segment.style.bold {
                fragment.inlinePresentationIntent = .stronglyEmphasized
            }
            if segment.style.underline {
                fragment.underlineStyle = .single
            }
            attributed += fragment
        }
        return attributed
    }
}

@Observable
@MainActor
final class TerminalRenderState {
    private static let defaultMaxDisplayedCharacters = 120_000

    private struct ReplaceRenderResult: Sendable {
        let normalizedOutput: String
        let parsedSegments: [ParsedAnsiSegment]
        let trailingStyle: TerminalAnsiParser.StyleState
        let attributedOutput: AttributedString
    }

    private struct AppendRenderResult: Sendable {
        let normalizedOutput: String
        let parsedSegments: [ParsedAnsiSegment]
        let trailingStyle: TerminalAnsiParser.StyleState
        let attributedOutput: AttributedString
    }

    private(set) var rawOutput: String
    private(set) var normalizedOutput: String
    private(set) var attributedOutput: AttributedString
    private(set) var renderVersion = 1
    private var rawNormalizedOutput: String
    private var parsedSegments: [ParsedAnsiSegment]
    private var trailingStyle: TerminalAnsiParser.StyleState
    private var renderTask: Task<Void, Never>?
    private var pendingGeneration = 0
    private let maxDisplayedCharacters: Int

    convenience init() {
        self.init(output: "")
    }

    init(output: String, maxDisplayedCharacters: Int = defaultMaxDisplayedCharacters) {
        self.maxDisplayedCharacters = max(1, maxDisplayedCharacters)
        let normalized = Self.normalize(output)
        let parseResult = TerminalAnsiParser.parse(normalized)
        let trimmedState = Self.trimmedDisplayState(
            parsedSegments: parseResult.segments,
            maxDisplayedCharacters: self.maxDisplayedCharacters
        )
        self.rawOutput = output
        self.rawNormalizedOutput = normalized
        self.normalizedOutput = trimmedState.normalizedOutput
        self.parsedSegments = trimmedState.parsedSegments
        self.trailingStyle = parseResult.trailingStyle
        self.attributedOutput = trimmedState.parsedSegments.attributed
    }

    func update(output: String) {
        let normalized = Self.normalize(output)
        rawOutput = output
        guard normalized != rawNormalizedOutput else { return }

        pendingGeneration &+= 1
        let generation = pendingGeneration
        renderTask?.cancel()

        if normalized.hasPrefix(rawNormalizedOutput) {
            let appendedText = String(normalized.dropFirst(rawNormalizedOutput.count))
            let trailingStyle = self.trailingStyle
            renderTask = Task { [appendedText, normalized] in
                let appendResult = await Task.detached(priority: .userInitiated) {
                    Self.appendRenderResult(
                        appendedText: appendedText,
                        rawNormalizedOutput: normalized,
                        trailingStyle: trailingStyle
                    )
                }.value
                guard !Task.isCancelled else { return }
                self.applyAppend(appendResult, generation: generation)
            }
            return
        }

        renderTask = Task { [normalized] in
            let replaceResult = await Task.detached(priority: .userInitiated) {
                Self.replaceRenderResult(normalizedOutput: normalized)
            }.value
            guard !Task.isCancelled else { return }
            self.applyReplace(replaceResult, generation: generation)
        }
    }

    var segmentTexts: [String] {
        parsedSegments.map(\.text)
    }

    nonisolated private static func normalize(_ output: String) -> String {
        if output.contains("\\n") && !output.contains("\n") {
            return output.replacingOccurrences(of: "\\n", with: "\n")
        }
        return output
    }

    nonisolated private static func replaceRenderResult(normalizedOutput: String) -> ReplaceRenderResult {
        let parseResult = TerminalAnsiParser.parse(normalizedOutput)
        return ReplaceRenderResult(
            normalizedOutput: normalizedOutput,
            parsedSegments: parseResult.segments,
            trailingStyle: parseResult.trailingStyle,
            attributedOutput: parseResult.segments.attributed
        )
    }

    nonisolated private static func appendRenderResult(
        appendedText: String,
        rawNormalizedOutput: String,
        trailingStyle: TerminalAnsiParser.StyleState
    ) -> AppendRenderResult {
        guard !appendedText.isEmpty else {
            return AppendRenderResult(
                normalizedOutput: rawNormalizedOutput,
                parsedSegments: [],
                trailingStyle: trailingStyle,
                attributedOutput: AttributedString()
            )
        }

        let parseResult = TerminalAnsiParser.parse(appendedText, initialStyle: trailingStyle)
        return AppendRenderResult(
            normalizedOutput: rawNormalizedOutput,
            parsedSegments: parseResult.segments,
            trailingStyle: parseResult.trailingStyle,
            attributedOutput: parseResult.segments.attributed
        )
    }

    private func applyReplace(_ replaceResult: ReplaceRenderResult, generation: Int) {
        guard generation == pendingGeneration else { return }
        rawNormalizedOutput = replaceResult.normalizedOutput
        let trimmedState = Self.trimmedDisplayState(
            parsedSegments: replaceResult.parsedSegments,
            maxDisplayedCharacters: maxDisplayedCharacters
        )
        normalizedOutput = trimmedState.normalizedOutput
        parsedSegments = trimmedState.parsedSegments
        trailingStyle = replaceResult.trailingStyle
        attributedOutput = trimmedState.parsedSegments.attributed
        renderVersion &+= 1
    }

    private func applyAppend(_ appendResult: AppendRenderResult, generation: Int) {
        guard generation == pendingGeneration else { return }
        rawNormalizedOutput = appendResult.normalizedOutput
        parsedSegments.append(contentsOf: appendResult.parsedSegments)
        let trimmedState = Self.trimmedDisplayState(
            parsedSegments: parsedSegments,
            maxDisplayedCharacters: maxDisplayedCharacters
        )
        normalizedOutput = trimmedState.normalizedOutput
        parsedSegments = trimmedState.parsedSegments
        trailingStyle = appendResult.trailingStyle
        attributedOutput = trimmedState.parsedSegments.attributed
        renderVersion &+= 1
    }

    nonisolated private static func trimmedDisplayState(
        parsedSegments: [ParsedAnsiSegment],
        maxDisplayedCharacters: Int
    ) -> (normalizedOutput: String, parsedSegments: [ParsedAnsiSegment]) {
        let visibleOutput = parsedSegments.map(\.text).joined()
        guard visibleOutput.count > maxDisplayedCharacters else {
            return (visibleOutput, parsedSegments)
        }

        let charactersToTrim = visibleOutput.count - maxDisplayedCharacters
        let trimmedSegments = trimLeadingCharacters(
            from: parsedSegments,
            charactersToTrim: charactersToTrim
        )
        let trimmedOutput = String(visibleOutput.suffix(maxDisplayedCharacters))
        return (trimmedOutput, trimmedSegments)
    }

    nonisolated private static func trimLeadingCharacters(
        from segments: [ParsedAnsiSegment],
        charactersToTrim: Int
    ) -> [ParsedAnsiSegment] {
        guard charactersToTrim > 0 else { return segments }

        var remainingToTrim = charactersToTrim
        var trimmedSegments: [ParsedAnsiSegment] = []
        trimmedSegments.reserveCapacity(segments.count)

        for segment in segments {
            guard remainingToTrim > 0 else {
                trimmedSegments.append(segment)
                continue
            }

            let segmentCount = segment.text.count
            if segmentCount <= remainingToTrim {
                remainingToTrim -= segmentCount
                continue
            }

            let startIndex = segment.text.index(segment.text.startIndex, offsetBy: remainingToTrim)
            let retainedText = String(segment.text[startIndex...])
            trimmedSegments.append(ParsedAnsiSegment(text: retainedText, style: segment.style))
            remainingToTrim = 0
        }

        return trimmedSegments
    }
}

private struct TerminalAnsiParser {
    struct StyleState: Sendable {
        var foreground: Color? = .green
        var background: Color?
        var bold: Bool = false
        var dim: Bool = false
        var underline: Bool = false

        mutating func applyReset() {
            foreground = .green
            background = nil
            bold = false
            dim = false
            underline = false
        }
    }

    struct ParseResult: Sendable {
        let segments: [ParsedAnsiSegment]
        let trailingStyle: StyleState
    }

    static func parse(_ value: String, initialStyle: StyleState = StyleState()) -> ParseResult {
        var segments: [ParsedAnsiSegment] = []
        var state = initialStyle
        var buffer = ""
        var didApplyANSIParameters = false

        func flush() {
            guard !buffer.isEmpty else { return }
            segments.append(ParsedAnsiSegment(text: buffer, style: state))
            buffer = ""
        }

        var index = value.startIndex
        while index < value.endIndex {
            let character = value[index]
            if character == "\u{1B}" && value.index(after: index) < value.endIndex && value[value.index(after: index)] == "[" {
                let parameterStart = value.index(index, offsetBy: 2)
                if parameterStart >= value.endIndex {
                    buffer.append(character)
                    index = value.index(after: index)
                    continue
                }
                var parameterEnd = parameterStart
                while parameterEnd < value.endIndex, value[parameterEnd] != "m" {
                    parameterEnd = value.index(after: parameterEnd)
                }
                if parameterEnd >= value.endIndex {
                    buffer.append(character)
                    index = value.index(after: index)
                    continue
                }

                let rawParams = String(value[parameterStart..<parameterEnd])
                flush()
                applyANSIParameters(rawParams, to: &state)
                didApplyANSIParameters = true
                index = value.index(after: parameterEnd)
                continue
            }

            buffer.append(character)
            index = value.index(after: index)
        }

        flush()
        if segments.isEmpty, !value.isEmpty, !didApplyANSIParameters {
            segments = [ParsedAnsiSegment(text: value, style: state)]
        }
        return ParseResult(segments: segments, trailingStyle: state)
    }

    private static func applyANSIParameters(_ raw: String, to state: inout StyleState) {
        let values = raw
            .split(separator: ";")
            .compactMap { Int($0) }

        if values.isEmpty {
            state.applyReset()
            return
        }

        for value in values {
            switch value {
            case 0:
                state.applyReset()
            case 1:
                state.bold = true
            case 2:
                state.dim = true
            case 4:
                state.underline = true
            case 22:
                state.bold = false
                state.dim = false
            case 24:
                state.underline = false
            case 39:
                state.foreground = .green
            case 49:
                state.background = nil
            case 90...97:
                state.foreground = brightAnsiColor(value)
            case 30...37:
                state.foreground = ansiColor(value)
            case 40...47:
                state.background = ansiColor(value - 10)
            case 100...107:
                state.background = brightAnsiColor(value - 10)
            default:
                continue
            }
        }
    }

    private static func ansiColor(_ value: Int) -> Color {
        switch value {
        case 30, 40: return .black
        case 31, 41: return .red
        case 32, 42: return .green
        case 33, 43: return .yellow
        case 34, 44: return .blue
        case 35, 45: return .purple
        case 36, 46: return .cyan
        default: return .white
        }
    }

    private static func brightAnsiColor(_ value: Int) -> Color {
        switch value {
        case 90, 100: return .gray
        case 91, 101: return .red
        case 92, 102: return .green
        case 93, 103: return .yellow
        case 94, 104: return .blue
        case 95, 105: return .purple
        case 96, 106: return .cyan
        case 97, 107: return .white
        default: return .white
        }
    }
}

struct ParsedAnsiSegment: Sendable {
    let text: String
    fileprivate let style: TerminalAnsiParser.StyleState
}

#Preview {
    TerminalView(
        output: """
$ swift run
Compile complete
""",
        isStreaming: true,
        title: "Build Output",
        onClear: {}
    )
}
