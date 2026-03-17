import SwiftUI
@preconcurrency import MarkdownUI
import Streamdown

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - MarkdownUI Theme Extension

extension Theme {
    @MainActor static func streamdownHighlighted(theme: StreamdownTheme) -> Theme {
        .gitHub.text {
            ForegroundColor(.primary)
        }
        .codeBlock { configuration in
            StreamdownCodeBlockContent(
                language: configuration.language,
                code: configuration.content
            )
        }
    }
}

// MARK: - StreamdownView

public struct StreamdownView: View {
    let content: String
    let mode: StreamdownMode
    let isStreaming: Bool
    let controls: StreamdownControls
    let linkSafety: StreamdownLinkSafetyConfig
    let parseIncompleteMarkdown: Bool
    let normalizeHtmlIndentation: Bool

    @Environment(\.streamdownTheme) private var theme
    @State private var modalURL: URL?
    @State private var modalIsPresented: Bool = false
    @State private var renderModel = StreamdownRenderModel()

    public init(
        content: String,
        isStreaming: Bool = false,
        controls: StreamdownControls = .default,
        parseIncompleteMarkdown: Bool = true,
        normalizeHtmlIndentation: Bool = false,
        linkSafety: StreamdownLinkSafetyConfig = .enabled
    ) {
        self.init(
            content: content,
            mode: isStreaming ? .streaming : .static,
            controls: controls,
            parseIncompleteMarkdown: parseIncompleteMarkdown,
            normalizeHtmlIndentation: normalizeHtmlIndentation,
            linkSafety: linkSafety
        )
    }

    public init(
        content: String,
        mode: StreamdownMode,
        controls: StreamdownControls = .default,
        parseIncompleteMarkdown: Bool = true,
        normalizeHtmlIndentation: Bool = false,
        linkSafety: StreamdownLinkSafetyConfig = .enabled
    ) {
        self.content = content
        self.mode = mode
        self.isStreaming = mode == .streaming
        self.controls = controls
        self.parseIncompleteMarkdown = mode == .streaming ? parseIncompleteMarkdown : false
        self.normalizeHtmlIndentation = normalizeHtmlIndentation
        self.linkSafety = linkSafety
    }

    public static func parseBlocks(
        content: String,
        mode: StreamdownMode = .streaming,
        parseIncompleteMarkdown: Bool = true,
        normalizeHtmlIndentation: Bool = false
    ) -> [StreamdownBlock] {
        StreamdownParser.parseBlocks(
            content: content,
            mode: mode,
            parseIncompleteMarkdown: parseIncompleteMarkdown,
            normalizeHtmlIndentation: normalizeHtmlIndentation
        )
    }

    public var body: some View {
        let parseTaskID = StreamdownRenderRequestKey(
            content: content,
            mode: mode,
            parseIncompleteMarkdown: parseIncompleteMarkdown,
            normalizeHtmlIndentation: normalizeHtmlIndentation
        )

        VStack(alignment: .leading, spacing: theme.spacing.md) {
            ForEach(renderModel.snapshot.blocks, id: \.id) { block in
                switch block {
                case let .markdown(markdown):
                    markdownBlock(markdown)
                case let .code(code):
                    codeBlock(
                        language: code.language,
                        code: code.code,
                        startLine: code.startLine,
                        isIncomplete: code.isIncomplete
                    )
                case let .table(table):
                    tableBlock(table)
                }
            }
        }
        .task(id: parseTaskID) {
            await renderModel.render(
                content: content,
                mode: mode,
                parseIncompleteMarkdown: parseIncompleteMarkdown,
                normalizeHtmlIndentation: normalizeHtmlIndentation
            )
        }
        .onDisappear { renderModel.cancel() }
        .overlay {
            if modalIsPresented, let pending = modalURL {
                StreamdownLinkSafetyModal(
                    url: pending.absoluteString,
                    isPresented: $modalIsPresented
                ) {
                    openExternalURL(pending)
                }
            }
        }
        .animation(mode == .streaming ? nil : .easeInOut(duration: 0.2), value: renderModel.snapshot.blocks.map(\.id))
    }

    private func markdownBlock(_ block: StreamdownMarkdownRenderBlock) -> some View {
        Markdown(block.content.value)
            .markdownTheme(.streamdownHighlighted(theme: theme))
            .textSelection(.enabled)
            .environment(\.openURL, OpenURLAction { url in
                systemOpenHandler(url)
            })
    }

    private func codeBlock(
        language: String?,
        code: String,
        startLine: Int?,
        isIncomplete: Bool
    ) -> some View {
        let isMermaidFlowchart = language?.lowercased().contains("mermaid") == true
        let controlsCopy = isMermaidFlowchart ? controls.mermaid.copy : controls.code.copy
        let controlsDownload = isMermaidFlowchart ? controls.mermaid.download : controls.code.download

        if controlsCopy || controlsDownload {
            return AnyView(
                StreamdownCodeBlockView(
                    language: language,
                    code: code,
                    startLine: startLine,
                    isIncomplete: isIncomplete,
                    controlsCopy: controlsCopy,
                    controlsDownload: controlsDownload,
                    isStreaming: isStreaming,
                    showFullscreen: isMermaidFlowchart ? controls.mermaid.fullscreen : false,
                    isMermaid: isMermaidFlowchart,
                    mermaidPanZoom: controls.mermaid.panZoom
                )
            )
        }

        return AnyView(
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                if let language {
                    Text(language)
                        .font(.caption2)
                        .foregroundStyle(theme.colors.tertiaryLabel)
                        .textCase(.lowercase)
                        .textSelection(.enabled)
                }

                StreamdownCodeBlockContent(
                    language: language,
                    code: code,
                    showHeader: true
                )
                .textSelection(.enabled)
            }
        )
    }

    private func tableBlock(_ block: StreamdownTableRenderBlock) -> some View {
        StreamdownTableView(
            headers: block.headers,
            rows: block.rows,
            headerInline: block.headerInline,
            rowInline: block.rowInline,
            columnWeights: block.columnWeights,
            controls: controls.table,
            isStreaming: isStreaming,
            isIncomplete: block.isIncomplete
        )
    }

    private func systemOpenHandler(_ url: URL) -> OpenURLAction.Result {
        guard linkSafety.enabled else {
            return .systemAction
        }

        if let onLinkCheck = linkSafety.onLinkCheck {
            Task {
                let shouldAllow = await onLinkCheck(url)
                await MainActor.run {
                    if shouldAllow {
                        openExternalURL(url)
                    } else {
                        modalURL = url
                        modalIsPresented = true
                    }
                }
            }
            return .handled
        }

        Task {
            await MainActor.run {
                modalURL = url
                modalIsPresented = true
            }
        }
        return .handled
    }

    private func openExternalURL(_ url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
}

private struct StreamdownRenderRequestKey: Hashable {
    let mode: StreamdownMode
    let parseIncompleteMarkdown: Bool
    let normalizeHtmlIndentation: Bool
    let contentHash: Int
    let contentCount: Int

    init(
        content: String,
        mode: StreamdownMode,
        parseIncompleteMarkdown: Bool,
        normalizeHtmlIndentation: Bool
    ) {
        self.mode = mode
        self.parseIncompleteMarkdown = parseIncompleteMarkdown
        self.normalizeHtmlIndentation = normalizeHtmlIndentation
        self.contentCount = content.count

        var hasher = Hasher()
        hasher.combine(content)
        self.contentHash = hasher.finalize()
    }
}
