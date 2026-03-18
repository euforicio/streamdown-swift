import Testing
@testable import Streamdown

// MARK: - Basic parsing

@Test func emptyInput() {
    let blocks = StreamdownParser.parseBlocks(content: "")
    #expect(blocks.isEmpty)
}

@Test func plainMarkdown() {
    let blocks = StreamdownParser.parseBlocks(content: "Hello world")
    #expect(blocks == [.markdown("Hello world")])
}

@Test func multilineMarkdown() {
    let input = "Line one\nLine two\nLine three"
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks == [.markdown(input)])
}

@Test func whitespaceOnlyContent() {
    let blocks = StreamdownParser.parseBlocks(content: "   \n\n  \n")
    #expect(blocks.count == 1)
    if case .markdown = blocks.first {} else {
        #expect(Bool(false), "Expected markdown block for whitespace-only content")
    }
}

// MARK: - Line ending normalization

@Test func crlfNormalization() {
    let result = StreamdownParser.normalizeContent("a\r\nb", normalizeHtmlIndentation: false)
    #expect(result == "a\nb")
}

@Test func bareCRNormalization() {
    let result = StreamdownParser.normalizeContent("a\rb", normalizeHtmlIndentation: false)
    #expect(result == "a\nb")
}

@Test func mixedLineEndings() {
    let result = StreamdownParser.normalizeContent("a\r\nb\rc\nd", normalizeHtmlIndentation: false)
    #expect(result == "a\nb\nc\nd")
}

// MARK: - HTML indentation normalization

@Test func htmlIndentationNormalization() {
    let input = "    <div>\n        <p>Hello</p>\n    </div>"
    let result = StreamdownParser.normalizeContent(input, normalizeHtmlIndentation: true)
    #expect(!result.hasPrefix("    "))
}

@Test func htmlIndentationSkippedWhenDisabled() {
    let input = "    <div>\n        <p>Hello</p>\n    </div>"
    let result = StreamdownParser.normalizeContent(input, normalizeHtmlIndentation: false)
    #expect(result == input)
}

@Test func htmlIndentationNoOpForNonHTML() {
    let input = "    just some indented text"
    let result = StreamdownParser.normalizeContent(input, normalizeHtmlIndentation: true)
    #expect(result == input)
}

// MARK: - Code blocks: backticks

@Test func fencedCodeBlockWithLanguage() {
    let input = """
    ```swift
    let x = 1
    ```
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks == [.code(language: "swift", code: "let x = 1", startLine: nil, isIncomplete: false)])
}

@Test func fencedCodeBlockNoLanguage() {
    let input = """
    ```
    some code
    ```
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks == [.code(language: nil, code: "some code", startLine: nil, isIncomplete: false)])
}

@Test func fencedCodeBlockWithTilde() {
    let input = """
    ~~~python
    print("hi")
    ~~~
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks == [.code(language: "python", code: "print(\"hi\")", startLine: nil, isIncomplete: false)])
}

@Test func codeBlockWithStartLine() {
    let input = """
    ```swift startLine=5
    let x = 1
    ```
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks == [.code(language: "swift", code: "let x = 1", startLine: 5, isIncomplete: false)])
}

@Test func fourBacktickCodeBlock() {
    let input = """
    ````typescript
    const x = 1
    ````
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks == [.code(language: "typescript", code: "const x = 1", startLine: nil, isIncomplete: false)])
}

@Test func fiveBacktickCodeBlock() {
    let input = """
    `````go
    fmt.Println("hello")
    `````
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks == [.code(language: "go", code: "fmt.Println(\"hello\")", startLine: nil, isIncomplete: false)])
}

@Test func emptyCodeBlock() {
    let input = """
    ```python
    ```
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks == [.code(language: "python", code: "", startLine: nil, isIncomplete: false)])
}

@Test func codeBlockWithLeadingSpaces() {
    // Up to 3 spaces of indentation before fence is allowed
    let input = "   ```swift\n   let x = 1\n   ```"
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 1)
    if case .code = blocks.first {} else {
        #expect(Bool(false), "Expected code block with leading spaces")
    }
}

@Test func fourBacktickNotClosedByThree() {
    // A 4-backtick fence should NOT be closed by a 3-backtick line
    let input = """
    ````python
    some code
    ```
    still code
    ````
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    #expect(blocks.count == 1)
    if case let .code(_, code, _, _) = blocks.first {
        #expect(code.contains("```"))
        #expect(code.contains("still code"))
    } else {
        #expect(Bool(false), "Expected code block")
    }
}

@Test func tildeInsideBacktickFence() {
    let input = """
    ```bash
    ~~~
    echo hi
    ~~~
    ```
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 1)
    if case let .code(_, code, _, _) = blocks.first {
        #expect(code.contains("~~~"))
    } else {
        #expect(Bool(false), "Expected code block containing tildes")
    }
}

@Test func multipleCodeBlocks() {
    let input = """
    ```swift
    let a = 1
    ```

    ```python
    b = 2
    ```
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 3)
    #expect(blocks[0] == .code(language: "swift", code: "let a = 1", startLine: nil, isIncomplete: false))
    if case .markdown = blocks[1] {} else {
        #expect(Bool(false), "Expected markdown between code blocks")
    }
    #expect(blocks[2] == .code(language: "python", code: "b = 2", startLine: nil, isIncomplete: false))
}

@Test func codeBlockMultiline() {
    let input = """
    ```rust
    fn main() {
        println!("Hello");
        let x = 42;
    }
    ```
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 1)
    if case let .code(lang, code, _, _) = blocks.first {
        #expect(lang == "rust")
        let lines = code.components(separatedBy: "\n")
        #expect(lines.count == 4)
    } else {
        #expect(Bool(false), "Expected code block")
    }
}

// MARK: - Code blocks: streaming/static incomplete

@Test func incompleteCodeBlockInStreamingMode() {
    let input = """
    ```swift
    let x = 1
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .streaming, parseIncompleteMarkdown: true)
    #expect(blocks == [.code(language: "swift", code: "let x = 1", startLine: nil, isIncomplete: true)])
}

@Test func incompleteCodeBlockInStaticMode() {
    let input = """
    ```swift
    let x = 1
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text.contains("```"))
        #expect(text.contains("let x = 1"))
    } else {
        #expect(Bool(false), "Expected markdown block")
    }
}

@Test func incompleteCodeBlockStreamingNoParseIncomplete() {
    let input = """
    ```swift
    let x = 1
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .streaming, parseIncompleteMarkdown: false)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text.contains("```"))
    } else {
        #expect(Bool(false), "Expected markdown block when parseIncompleteMarkdown is false")
    }
}

// MARK: - Tables

@Test func gfmTable() {
    let input = """
    | Name | Age |
    | --- | --- |
    | Alice | 30 |
    | Bob | 25 |
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    let tableBlocks = blocks.filter {
        if case .table = $0 { return true }
        return false
    }
    #expect(tableBlocks.count == 1)
    if case let .table(headers, rows, isIncomplete) = tableBlocks.first {
        #expect(headers == ["Name", "Age"])
        #expect(rows == [["Alice", "30"], ["Bob", "25"]])
        #expect(isIncomplete == false)
    } else {
        #expect(Bool(false), "Expected table block")
    }
}

@Test func incompleteTableInStreaming() {
    let input = """
    | Name | Age |
    | --- | --- |
    | Alice | 30 |
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .streaming)
    #expect(blocks.count == 1)
    if case let .table(headers, rows, isIncomplete) = blocks.first {
        #expect(headers == ["Name", "Age"])
        #expect(rows == [["Alice", "30"]])
        #expect(isIncomplete == true)
    } else {
        #expect(Bool(false), "Expected table block")
    }
}

@Test func singleColumnNotTable() {
    let input = """
    | Value |
    | --- |
    | one |
    | two |
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    let tableBlocks = blocks.filter {
        if case .table = $0 { return true }
        return false
    }
    #expect(tableBlocks.isEmpty)
}

@Test func tableWithAlignmentMarkers() {
    let input = """
    | Left | Center | Right |
    | :--- | :---: | ---: |
    | a | b | c |
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    let tableBlocks = blocks.filter {
        if case .table = $0 { return true }
        return false
    }
    #expect(tableBlocks.count == 1)
    if case let .table(headers, rows, _) = tableBlocks.first {
        #expect(headers == ["Left", "Center", "Right"])
        #expect(rows == [["a", "b", "c"]])
    }
}

@Test func tableWithEscapedPipes() {
    let input = """
    | Code | Output |
    | --- | --- |
    | a \\| b | result |
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    let tableBlocks = blocks.filter {
        if case .table = $0 { return true }
        return false
    }
    #expect(tableBlocks.count == 1)
    if case let .table(_, rows, _) = tableBlocks.first {
        #expect(rows.count == 1)
        #expect(rows[0][0] == "a | b")
    }
}

@Test func tableFollowedByMarkdown() {
    let input = """
    | A | B |
    | --- | --- |
    | 1 | 2 |

    Some trailing text
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    #expect(blocks.count == 2)
    if case .table = blocks[0] {} else {
        #expect(Bool(false), "Expected table as first block")
    }
    if case .markdown(let text) = blocks[1] {
        #expect(text.contains("Some trailing text"))
    } else {
        #expect(Bool(false), "Expected markdown after table")
    }
}

@Test func tableHeadersOnly() {
    // Table with header + separator but no data rows
    let input = """
    | A | B |
    | --- | --- |

    Next paragraph
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    let tableBlocks = blocks.filter {
        if case .table = $0 { return true }
        return false
    }
    #expect(tableBlocks.count == 1)
    if case let .table(headers, rows, _) = tableBlocks.first {
        #expect(headers == ["A", "B"])
        #expect(rows.isEmpty)
    }
}

@Test func tableRaggedRows() {
    // Rows with fewer columns than headers
    let input = """
    | A | B | C |
    | --- | --- | --- |
    | 1 | 2 |
    | x | y | z |
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    let tableBlocks = blocks.filter {
        if case .table = $0 { return true }
        return false
    }
    #expect(tableBlocks.count == 1)
    if case let .table(_, rows, _) = tableBlocks.first {
        #expect(rows.count == 2)
        #expect(rows[0].count == 2)  // fewer than headers
        #expect(rows[1].count == 3)
    }
}

@Test func tableWithInlineMarkdown() {
    let input = """
    | Feature | Status |
    | --- | --- |
    | **Bold** | `done` |
    | _Italic_ | [link](url) |
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    let tableBlocks = blocks.filter {
        if case .table = $0 { return true }
        return false
    }
    #expect(tableBlocks.count == 1)
    if case let .table(_, rows, _) = tableBlocks.first {
        #expect(rows[0][0] == "**Bold**")
        #expect(rows[0][1] == "`done`")
        #expect(rows[1][0] == "_Italic_")
    }
}

@Test func tableWithoutLeadingPipe() {
    // GFM tables don't require leading pipes
    let input = """
    Name | Age
    --- | ---
    Alice | 30
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    let tableBlocks = blocks.filter {
        if case .table = $0 { return true }
        return false
    }
    #expect(tableBlocks.count == 1)
    if case let .table(headers, rows, _) = tableBlocks.first {
        #expect(headers == ["Name", "Age"])
        #expect(rows == [["Alice", "30"]])
    }
}

// MARK: - Mixed content

@Test func mixedContent() {
    let input = """
    Some text

    ```swift
    let x = 1
    ```

    More text
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 3)
    #expect(blocks[0] == .markdown("Some text\n"))
    #expect(blocks[1] == .code(language: "swift", code: "let x = 1", startLine: nil, isIncomplete: false))
    #expect(blocks[2] == .markdown("\nMore text"))
}

@Test func markdownThenTableThenCode() {
    let input = """
    # Header

    | A | B |
    | --- | --- |
    | 1 | 2 |

    ```js
    console.log("hi")
    ```
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    #expect(blocks.count >= 3)
    if case .markdown(let text) = blocks[0] {
        #expect(text.contains("# Header"))
    }
    let hasTable = blocks.contains {
        if case .table = $0 { return true }
        return false
    }
    #expect(hasTable)
    let hasCode = blocks.contains {
        if case .code = $0 { return true }
        return false
    }
    #expect(hasCode)
}

// MARK: - HTML blocks

@Test func htmlBlock() {
    let input = """
    <div>
    Hello
    </div>
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text.contains("<div>"))
        #expect(text.contains("</div>"))
    } else {
        #expect(Bool(false), "Expected markdown block for HTML")
    }
}

@Test func htmlVoidTag() {
    let input = "<br>"
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text == "<br>")
    }
}

@Test func htmlSelfClosingTag() {
    let input = "<img src=\"test.png\" />"
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 1)
    // Self-closing tags should not start an HTML block
    if case .markdown = blocks.first {} else {
        #expect(Bool(false), "Expected markdown for self-closing tag")
    }
}

@Test func htmlWithAttributes() {
    let input = """
    <div class="container" id="main">
    Content
    </div>
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text.contains("class=\"container\""))
        #expect(text.contains("</div>"))
    }
}

@Test func nestedDetailsBlock() {
    let input = """
    <details>
    <summary>Outer</summary>
    <details>
    <summary>Inner</summary>
    Inner content
    </details>
    Outer content
    </details>
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text.contains("<details>"))
        #expect(text.contains("</details>"))
        #expect(text.contains("Inner content"))
        #expect(text.contains("Outer content"))
    } else {
        #expect(Bool(false), "Expected single markdown block for nested details")
    }
}

@Test func divInsideDetails() {
    let input = """
    <details>
    <summary>Click me</summary>
    <div class="content">
    Some content
    </div>
    </details>
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text.contains("<details>"))
        #expect(text.contains("</details>"))
        #expect(text.contains("<div"))
        #expect(text.contains("</div>"))
    } else {
        #expect(Bool(false), "Expected single markdown block for div inside details")
    }
}

@Test func tripleNestedHTML() {
    let input = """
    <details>
    <div>
    <section>
    Deep content
    </section>
    </div>
    </details>
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text.contains("Deep content"))
        #expect(text.contains("</details>"))
    } else {
        #expect(Bool(false), "Expected single block for triple-nested HTML")
    }
}

@Test func multipleSiblingDivs() {
    let input = """
    <div>
    <div>First</div>
    <div>Second</div>
    </div>
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text.contains("First"))
        #expect(text.contains("Second"))
        // Should end at the outer </div>
        #expect(text.hasSuffix("</div>"))
    } else {
        #expect(Bool(false), "Expected single block for sibling divs")
    }
}

@Test func htmlBlockFollowedByMarkdown() {
    let input = """
    <div>
    Hello
    </div>

    Regular paragraph
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    #expect(blocks.count == 2)
    if case .markdown(let text) = blocks[0] {
        #expect(text.contains("<div>"))
    }
    if case .markdown(let text) = blocks[1] {
        #expect(text.contains("Regular paragraph"))
    }
}

@Test func htmlOpenAndCloseOnSameLine() {
    let input = "<div>Hello</div>"
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text == "<div>Hello</div>")
    }
}

// MARK: - Math blocks

@Test func mathBlockUnclosedInStreaming() {
    let input = """
    Here is math:
    $$
    x^2 + y^2
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .streaming)
    #expect(blocks.count == 1)
    if case .markdown = blocks.first {
        // expected: unclosed math block stays as single markdown
    } else {
        #expect(Bool(false), "Expected markdown block for unclosed math")
    }
}

@Test func mathBlockClosed() {
    let input = """
    $$
    x^2 + y^2
    $$
    More text
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .streaming)
    // Closed math block should allow subsequent content to be separate blocks
    let totalContent = blocks.compactMap { block -> String? in
        if case .markdown(let text) = block { return text }
        return nil
    }.joined()
    #expect(totalContent.contains("$$"))
    #expect(totalContent.contains("More text"))
}

@Test func escapedDollarSignNotMath() {
    let input = "Price is \\$\\$ per unit"
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .streaming)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text.contains("\\$"))
    }
}

@Test func shellDoubleDolorAfterCodeBlock() {
    let input = """
    ```bash
    echo "hello"
    ```

    The process ID is $$ in bash.
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .streaming)
    #expect(blocks.count == 2)
    #expect(blocks[0] == .code(language: "bash", code: "echo \"hello\"", startLine: nil, isIncomplete: false))
    if case .markdown(let text) = blocks[1] {
        #expect(text.contains("$$"))
    } else {
        #expect(Bool(false), "Expected markdown block after code block")
    }
}

@Test func doubleDollarInsideCodeBlockNotMath() {
    let input = """
    ```bash
    echo $$
    ```
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .streaming)
    #expect(blocks.count == 1)
    if case let .code(_, code, _, _) = blocks.first {
        #expect(code.contains("$$"))
    } else {
        #expect(Bool(false), "Expected code block containing $$")
    }
}

// MARK: - Footnotes

@Test func footnotes() {
    let input = """
    Some text[^1] with a footnote.

    [^1]: This is the footnote.
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text.contains("[^1]"))
    } else {
        #expect(Bool(false), "Expected markdown block for footnotes")
    }
}

@Test func footnoteDefinitionOnly() {
    let input = "[^note]: Definition without reference."
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text.contains("[^note]:"))
    }
}

// MARK: - Incremental parse stability

@Test func incrementalParseStableBlocks() {
    let base = """
    Hello world

    ```swift
    let x = 1
    ```
    """
    let blocks1 = StreamdownParser.parseBlocks(content: base, mode: .streaming)
    #expect(blocks1.count == 2)

    let extended = base + "\nMore text"
    let blocks2 = StreamdownParser.parseBlocks(content: extended, mode: .streaming)
    #expect(blocks2.count == 3)
    #expect(blocks2[0] == blocks1[0])
    #expect(blocks2[1] == blocks1[1])
}

@Test func incrementalParseAppendToCodeBlock() {
    let partial = """
    ```swift
    let x = 1
    """
    let blocks1 = StreamdownParser.parseBlocks(content: partial, mode: .streaming, parseIncompleteMarkdown: true)
    #expect(blocks1.count == 1)
    if case let .code(_, _, _, isIncomplete) = blocks1.first {
        #expect(isIncomplete == true)
    }

    let complete = partial + "\nlet y = 2\n```"
    let blocks2 = StreamdownParser.parseBlocks(content: complete, mode: .streaming)
    #expect(blocks2.count == 1)
    if case let .code(_, code, _, isIncomplete) = blocks2.first {
        #expect(isIncomplete == false)
        #expect(code.contains("let y = 2"))
    }
}

// MARK: - Regex cache consistency

@Test func regexCacheConsistency() {
    // Parse content with <div> multiple times — cache should return consistent results
    let input = """
    <div>
    content
    </div>
    """
    let blocks1 = StreamdownParser.parseBlocks(content: input)
    let blocks2 = StreamdownParser.parseBlocks(content: input)
    let blocks3 = StreamdownParser.parseBlocks(content: input)
    #expect(blocks1 == blocks2)
    #expect(blocks2 == blocks3)
}

@Test func regexCacheDifferentTags() {
    let divInput = "<div>\ncontent\n</div>"
    let detailsInput = "<details>\ncontent\n</details>"
    let sectionInput = "<section>\ncontent\n</section>"

    let divBlocks = StreamdownParser.parseBlocks(content: divInput)
    let detailsBlocks = StreamdownParser.parseBlocks(content: detailsInput)
    let sectionBlocks = StreamdownParser.parseBlocks(content: sectionInput)

    // Each should parse as a single HTML block
    #expect(divBlocks.count == 1)
    #expect(detailsBlocks.count == 1)
    #expect(sectionBlocks.count == 1)
}

// MARK: - StreamdownParsedBlock

@Test func parsedBlockOffsetting() {
    let block = StreamdownParsedBlock(
        block: .markdown("hello"),
        range: 0..<5
    )
    let offset = block.offsetting(by: 10)
    #expect(offset.range == 10..<15)
    #expect(offset.block == block.block)
}

@Test func parsedBlockOffsettingByZero() {
    let block = StreamdownParsedBlock(
        block: .code(language: "swift", code: "x", startLine: nil, isIncomplete: false),
        range: 5..<10
    )
    let offset = block.offsetting(by: 0)
    #expect(offset.range == 5..<10)
}

// MARK: - StreamdownBlock identity

@Test func parseBlocksReturnsStreamdownBlockArray() {
    let blocks = StreamdownParser.parseBlocks(content: "hello")
    let _: [StreamdownBlock] = blocks
    #expect(blocks.count == 1)
}

@Test func blockIds() {
    let md = StreamdownBlock.markdown("hello")
    let code = StreamdownBlock.code(language: "swift", code: "x", startLine: nil, isIncomplete: false)
    let table = StreamdownBlock.table(headers: ["A", "B"], rows: [["1", "2"]], isIncomplete: false)

    #expect(md.id.hasPrefix("markdown-"))
    #expect(code.id.hasPrefix("code-"))
    #expect(table.id.hasPrefix("table-"))

    // Different content = different ids
    let md2 = StreamdownBlock.markdown("world")
    #expect(md.id != md2.id)
}

// MARK: - String.characterSlice

@Test func characterSliceFromZero() {
    #expect("hello".characterSlice(from: 0) == "hello")
}

@Test func characterSliceFromMiddle() {
    #expect("hello".characterSlice(from: 2) == "llo")
}

@Test func characterSliceBeyondLength() {
    #expect("hello".characterSlice(from: 10) == "")
}

@Test func characterSliceExactLength() {
    #expect("hello".characterSlice(from: 5) == "")
}

// MARK: - parse() with ranges

@Test func parseReturnsCorrectRanges() {
    let input = "hello\n```\ncode\n```\nworld"
    let normalized = StreamdownParser.normalizeContent(input, normalizeHtmlIndentation: false)
    let parsed = StreamdownParser.parse(normalized, mode: .static, parseIncompleteMarkdown: false)

    #expect(parsed.count == 3)
    // Ranges should cover the entire input without gaps
    #expect(parsed[0].range.lowerBound == 0)
    for i in 0..<parsed.count {
        #expect(parsed[i].range.lowerBound < parsed[i].range.upperBound)
    }
}

// MARK: - Edge cases

@Test func onlyCodeFenceMarker() {
    let input = "```"
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    #expect(blocks.count == 1)
    // A lone fence marker in static mode should become markdown
    if case .markdown = blocks.first {} else {
        #expect(Bool(false), "Expected markdown for lone fence marker")
    }
}

@Test func twoBackticksNotAFence() {
    let input = "`` not a fence ``"
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 1)
    if case .markdown(let text) = blocks.first {
        #expect(text == "`` not a fence ``")
    }
}

@Test func codeBlockContainingTableLikeSyntax() {
    let input = """
    ```
    | Not | A | Table |
    | --- | --- | --- |
    | 1 | 2 | 3 |
    ```
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 1)
    if case let .code(_, code, _, _) = blocks.first {
        #expect(code.contains("| Not | A | Table |"))
    } else {
        #expect(Bool(false), "Expected code block, not table")
    }
}

@Test func unicodeContent() {
    let input = "Hello 🌍 世界\n\n```swift\nlet emoji = \"🎉\"\n```"
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks.count == 2)
    if case .markdown(let text) = blocks[0] {
        #expect(text.contains("🌍"))
        #expect(text.contains("世界"))
    }
    if case let .code(_, code, _, _) = blocks[1] {
        #expect(code.contains("🎉"))
    }
}

@Test func tableWithUnicodeContent() {
    let input = """
    | Emoji | Name |
    | --- | --- |
    | 🍎 | Apple |
    | 🍌 | Banana |
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    let tableBlocks = blocks.filter {
        if case .table = $0 { return true }
        return false
    }
    #expect(tableBlocks.count == 1)
    if case let .table(_, rows, _) = tableBlocks.first {
        #expect(rows[0][0] == "🍎")
    }
}
