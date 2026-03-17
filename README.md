# Streamdown

A streaming markdown parser for Swift. Incrementally parses markdown as it arrives — code blocks, tables, and Mermaid diagrams rendered in real-time.

## Installation

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/euforicio/streamdown-swift", from: "0.1.0")
```

Two targets are available:

- **Streamdown** — parsing only, no UI dependencies
- **StreamdownUI** — SwiftUI views built on [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui)

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

## Block Types

| Block | Description |
|-------|-------------|
| `.markdown` | Prose, headings, lists, inline code, math blocks |
| `.code` | Fenced code blocks with optional language and line offset |
| `.table` | Pipe-delimited tables parsed into headers and rows |

## Theming

Inject a custom `StreamdownTheme` via the SwiftUI environment:

```swift
let theme = StreamdownTheme(
    spacing: .default,
    colors: StreamdownTheme.Colors(
        background: .black,
        foreground: .white
    ),
    fonts: .default
)

StreamdownView(content: text, isStreaming: true)
    .environment(\.streamdownTheme, theme)
```

## Platforms

- iOS 17+
- macOS 14+
- visionOS 1+

## License

MIT — see [LICENSE](LICENSE).
