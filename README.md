# Streamdown

A streaming markdown parser and renderer for Swift. Incrementally parses markdown as it arrives — code blocks, tables, and Mermaid diagrams rendered in real-time.

## Features

- **Streaming + static parsing** — incremental re-parse as content arrives, or one-shot for complete documents
- **Code blocks** — fenced code with syntax highlighting, optional line numbers, copy/download controls
- **GFM tables** — pipe-delimited tables with CSV, TSV, and Markdown export (Excel BOM support)
- **Mermaid diagrams** — live rendering via embedded WebView with optional pan/zoom
- **Nested HTML blocks** — full HTML block detection and passthrough
- **Math block detection** — `$$` delimited math blocks preserved as markdown
- **Theming** — dark (default) and light presets, automatic system appearance switching, full customization via environment
- **Streaming animations** — configurable staggered block reveal with per-block delay
- **Link safety** — modal confirmation before opening external URLs, with async verification callback
- **Incremental re-parse** — block reuse optimization avoids re-rendering unchanged content
- **Regex caching** — compiled patterns cached for parse performance
- **Swift 6 concurrency** — `Sendable` throughout, `@Observable` render model, actor-isolated background parsing

## Requirements

- Swift 6.2+
- iOS 17+ / macOS 14+ / visionOS 1+

## Installation

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/euforicio/streamdown-swift", branch: "main")
```

Two targets are available:

- **Streamdown** — parsing only, no UI dependencies
- **StreamdownUI** — SwiftUI views, depends on [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui)

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "Streamdown", package: "streamdown-swift"),
        .product(name: "StreamdownUI", package: "streamdown-swift"),
    ]
)
```

## Quick Start — Parsing

```swift
import Streamdown

let blocks = StreamdownParser.parseBlocks(content: markdown, mode: .streaming)

for block in blocks {
    switch block {
    case .markdown(let text):
        print("Markdown: \(text)")
    case .code(let language, let code, _, let isIncomplete):
        print("Code (\(language ?? "plain")): \(code)")
    case .table(let headers, let rows, _):
        print("Table: \(headers.joined(separator: " | "))")
    }
}
```

`StreamdownMode` controls parsing behavior:

| Mode | Behavior |
|------|----------|
| `.streaming` | Treats unterminated fences/tables as incomplete blocks — safe for partial content |
| `.static` | Assumes content is complete — unterminated fences become markdown |

## Quick Start — SwiftUI

```swift
import StreamdownUI

struct MessageView: View {
    let text: String
    let isStreaming: Bool

    var body: some View {
        StreamdownView(content: text, isStreaming: isStreaming)
    }
}
```

`StreamdownView` accepts the full range of configuration options:

```swift
StreamdownView(
    content: text,
    isStreaming: true,
    controls: .default,
    parseIncompleteMarkdown: true,
    normalizeHtmlIndentation: false,
    linkSafety: .enabled,
    animation: .default
)
```

## Block Types

| Block | Description |
|-------|-------------|
| `.markdown(String)` | Prose, headings, lists, inline code, math blocks, HTML blocks |
| `.code(language:code:startLine:isIncomplete:)` | Fenced code blocks with optional language tag and line offset |
| `.table(headers:rows:isIncomplete:)` | Pipe-delimited tables parsed into typed headers and row arrays |

All blocks conform to `Equatable`, `Identifiable`, and `Sendable`.

## Theming

Built-in presets:

```swift
// Dark theme (default)
StreamdownView(content: text, isStreaming: true)

// Light theme
StreamdownView(content: text, isStreaming: true)
    .environment(\.streamdownTheme, .light)
```

Automatic system appearance switching:

```swift
StreamdownView(content: text, isStreaming: true)
    .streamdownAutomaticTheme()
```

Custom theme via environment:

```swift
let theme = StreamdownTheme(
    spacing: .default,
    colors: StreamdownTheme.Colors(
        background: .black,
        foreground: .white,
        secondaryBackground: .gray,
        tertiaryBackground: .gray.opacity(0.5),
        secondaryLabel: .gray,
        tertiaryLabel: .gray.opacity(0.7),
        mutedForeground: .gray,
        border: .gray.opacity(0.3),
        separator: .gray.opacity(0.2),
        card: .black
    ),
    fonts: .default
)

StreamdownView(content: text, isStreaming: true)
    .environment(\.streamdownTheme, theme)
```

## Controls

`StreamdownControls` configures per-block-type toolbar actions:

```swift
let controls = StreamdownControls(
    code: .init(copy: true, download: true, lineNumbers: true),
    table: .init(copy: true, download: true, fullscreen: true),
    mermaid: .init(copy: true, download: true, fullscreen: true, panZoom: true)
)

StreamdownView(content: text, isStreaming: true, controls: controls)
```

### Sub-structs

| Struct | Options |
|--------|---------|
| `StreamdownControls.Code` | `copy`, `download`, `lineNumbers` |
| `StreamdownControls.Table` | `copy`, `download`, `fullscreen` |
| `StreamdownControls.Mermaid` | `copy`, `download`, `fullscreen`, `panZoom` |

All options default to sensible values — copy enabled, everything else off. Pass `.default` or omit for defaults.

## Streaming Animation

Configure the staggered block reveal animation:

```swift
// Custom stagger delay
StreamdownView(
    content: text,
    isStreaming: true,
    animation: StreamdownAnimationConfig(staggerDelay: 0.08)
)

// Disable animations
StreamdownView(
    content: text,
    isStreaming: true,
    animation: .none
)
```

| Property | Default | Description |
|----------|---------|-------------|
| `enabled` | `true` | Whether blocks animate in |
| `staggerDelay` | `0.04` | Seconds between each block's entrance |

## Link Safety

When enabled, external links show a confirmation modal before opening:

```swift
// Enabled (default)
StreamdownView(content: text, linkSafety: .enabled)

// Disabled
StreamdownView(content: text, linkSafety: .disabled)

// Custom async verification
StreamdownView(
    content: text,
    linkSafety: StreamdownLinkSafetyConfig(
        enabled: true,
        onLinkCheck: { url in
            // Return true if the link is safe to open
            await checkUrlReputation(url)
        }
    )
)
```

The `onLinkCheck` callback receives the URL and returns a `Bool`. The modal displays the full URL and offers Copy and Open actions.

## Table Export

`StreamdownTableData` provides export methods for parsed tables:

```swift
let tableData = StreamdownTableData(
    headers: ["Name", "Role"],
    rows: [["Alice", "Engineer"], ["Bob", "Designer"]]
)

// CSV (RFC 4180)
let csv = tableData.toCSV()

// CSV with Excel BOM for proper Unicode handling
let excelCSV = tableData.toCSV(excelCompatible: true)

// TSV
let tsv = tableData.toTSV()

// Markdown table
let md = tableData.toMarkdownTable()
```

## Architecture

The package is split into two targets with a clean dependency boundary:

```
Sources/
├── Streamdown/                  # Parser — zero UI dependencies
│   ├── StreamdownParser.swift          # Core incremental parser
│   ├── StreamdownParser+CodeFence.swift
│   ├── StreamdownParser+HTML.swift
│   ├── StreamdownParser+Math.swift
│   ├── StreamdownParser+Table.swift
│   ├── StreamdownBlock.swift           # Block enum
│   ├── StreamdownMode.swift            # static / streaming
│   ├── StreamdownParsedBlock.swift     # Block + character range
│   └── StreamdownTableData.swift       # Export (CSV/TSV/Markdown)
│
└── StreamdownUI/                # SwiftUI views — depends on Streamdown + MarkdownUI
    ├── StreamdownView.swift            # Main entry point
    ├── StreamdownControls.swift        # Toolbar config
    ├── StreamdownTheme.swift           # Theme + environment key
    ├── StreamdownAnimationConfig.swift # Animation settings
    ├── StreamdownLinkSafetyModal.swift # Link safety config + modal
    ├── StreamdownMermaidView.swift     # Mermaid diagram WebView
    ├── StreamdownCodeBlockView.swift   # Code block rendering
    ├── StreamdownTableView.swift       # Table rendering
    ├── StreamdownRenderModel.swift     # @Observable render state
    └── StreamdownRenderActor.swift     # Background parse actor
```

**Streamdown** can be used standalone for parsing in non-UI contexts (servers, CLI tools, etc.).

## Testing

```bash
swift test
```

The test suite covers parsing (code fences, HTML blocks, tables, math blocks, mixed content, normalization) and table export (CSV escaping, TSV, Markdown formatting, Excel BOM).

## Acknowledgments

- Inspired by [vercel/streamdown](https://github.com/nicepkg/streamdown)
- Markdown rendering powered by [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui)

## License

MIT — see [LICENSE](LICENSE).
