import SwiftUI

public struct JSXPreviewContext: @unchecked Sendable {
    public let jsx: String
    public let processedJsx: String
    public let error: Error?
    public let components: [String: Any]?
    public let bindings: [String: Any]?

    public init(
        jsx: String,
        processedJsx: String,
        error: Error?,
        components: [String: Any]?,
        bindings: [String: Any]?
    ) {
        self.jsx = jsx
        self.processedJsx = processedJsx
        self.error = error
        self.components = components
        self.bindings = bindings
    }
}

private struct JSXPreviewContextKey: EnvironmentKey {
    nonisolated static let defaultValue = JSXPreviewContext(
        jsx: "",
        processedJsx: "",
        error: nil,
        components: nil,
        bindings: nil
    )
}

public extension EnvironmentValues {
    var jsxPreviewContext: JSXPreviewContext {
        get { self[JSXPreviewContextKey.self] }
        set { self[JSXPreviewContextKey.self] = newValue }
    }
}

private struct ParsedJSX {
    let processed: String
    let error: Error?
}

private struct JSXPreviewParseError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

private let jsxTagRegexPattern = #"<\/?([a-zA-Z][a-zA-Z0-9]*)\s*([^>]*?)(\/)?>"#
private let jsxPreviewMaxLength = 12_000

public struct JSXPreview<Content: View>: View {

    let jsx: String
    let isStreaming: Bool
    let components: [String: Any]?
    let bindings: [String: Any]?
    let onError: ((Error) -> Void)?
    let content: () -> Content

    @State private var processedJsx: String
    @State private var parserError: Error?

    public init(
        jsx: String,
        isStreaming: Bool = false,
        components: [String: Any]? = nil,
        bindings: [String: Any]? = nil,
        onError: ((Error) -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.jsx = jsx
        self.isStreaming = isStreaming
        self.components = components
        self.bindings = bindings
        self.onError = onError
        self.content = content

        let initial = Self.parseJSX(jsx, streaming: isStreaming)
        _processedJsx = State(initialValue: initial.processed)
        _parserError = State(initialValue: initial.error)
    }

    public var body: some View {
        let context = JSXPreviewContext(
            jsx: jsx,
            processedJsx: processedJsx,
            error: parserError,
            components: components,
            bindings: bindings
        )

        content()
            .environment(\.jsxPreviewContext, context)
            .onAppear(perform: syncParsedOutput)
            .onChange(of: jsx) { _, _ in
                syncParsedOutput()
            }
            .onChange(of: isStreaming) { _, _ in
                syncParsedOutput()
            }
    }

    private func syncParsedOutput() {
        let next = Self.parseJSX(jsx, streaming: isStreaming)
        let previousMessage = parserError?.localizedDescription

        processedJsx = next.processed
        parserError = next.error

        if previousMessage != next.error?.localizedDescription, let error = next.error {
            onError?(error)
        }
    }

    private static func parseJSX(_ value: String, streaming: Bool) -> ParsedJSX {
        guard let regex = try? NSRegularExpression(pattern: jsxTagRegexPattern) else {
            return ParsedJSX(processed: String(value.prefix(jsxPreviewMaxLength)), error: nil)
        }

        let value = String(value.prefix(jsxPreviewMaxLength))
        var output = ""
        var stack: [String] = []
        var cursor = value.startIndex

        while let match = regex.firstMatch(
            in: value,
            options: [],
            range: NSRange(cursor..<value.endIndex, in: value)
        ) {
            let matchRange = match.range
            guard let tagRange = Range(matchRange, in: value) else {
                break
            }

            output += String(value[cursor..<tagRange.lowerBound])
            output += String(value[tagRange])

            cursor = tagRange.upperBound

            guard
                let tagNameRange = Range(match.range(at: 1), in: value),
                let closeMarkerRange = Range(match.range(at: 3), in: value)
            else {
                continue
            }

            let tagName = String(value[tagNameRange])
            let rawTag = String(value[tagRange])
            let isClosingTag = rawTag.hasPrefix("</")
            let isSelfClosing = closeMarkerRange.lowerBound < closeMarkerRange.upperBound

            if isSelfClosing {
                continue
            }

            if isClosingTag {
                guard let lastTag = stack.last else {
                    return ParsedJSX(
                        processed: output + String(value[cursor...]),
                        error: JSXPreviewParseError(message: "Unexpected closing tag </\(tagName)>")
                    )
                }

                if lastTag != tagName {
                    return ParsedJSX(
                        processed: output + String(value[cursor...]),
                        error: JSXPreviewParseError(
                            message: "Mismatched closing tag </\(tagName)>. Expected </\(lastTag)>."
                        )
                    )
                }

                _ = stack.popLast()
                continue
            }

            stack.append(tagName)
        }

        output += String(value[cursor...])

        guard streaming, !stack.isEmpty else {
            return ParsedJSX(processed: output, error: nil)
        }

        var completed = output
        for tag in stack.reversed() {
            completed += "</\(tag)>"
        }

        return ParsedJSX(processed: completed, error: nil)
    }
}

public struct JSXPreviewContent: View {
    @Environment(\.jsxPreviewContext) private var context

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !context.processedJsx.isEmpty {
                CodeBlockView(
                    language: "jsx",
                    code: context.processedJsx,
                    showLineNumbers: false
                )
                .padding(.horizontal, EAISpacing.md)
                .padding(.vertical, EAISpacing.sm)
            }
        }
    }
}

public struct JSXPreviewError: View {
    private let children: ((Error) -> AnyView)?

    @Environment(\.jsxPreviewContext) private var context

    public init() {
        self.children = nil
    }

    public init<C: View>(@ViewBuilder children: @escaping (Error) -> C) {
        self.children = { AnyView(children($0)) }
    }

    public var body: some View {
        guard let error = context.error else {
            return AnyView(EmptyView())
        }

        return AnyView(
            HStack(spacing: EAISpacing.sm) {
                if let children {
                    children(error)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)

                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.all, EAISpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.red.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 8)
            )
        )
    }
}
