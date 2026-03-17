import Testing
@testable import Streamdown

@Test func emptyInput() {
    let blocks = StreamdownParser.parseBlocks(content: "")
    #expect(blocks.isEmpty)
}

@Test func plainMarkdown() {
    let blocks = StreamdownParser.parseBlocks(content: "Hello world")
    #expect(blocks == [.markdown("Hello world")])
}

@Test func fencedCodeBlockWithLanguage() {
    let input = """
    ```swift
    let x = 1
    ```
    """
    let blocks = StreamdownParser.parseBlocks(content: input)
    #expect(blocks == [.code(language: "swift", code: "let x = 1", startLine: nil, isIncomplete: false)])
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

@Test func gfmTable() {
    let input = """
    | Name | Age |
    | --- | --- |
    | Alice | 30 |
    | Bob | 25 |
    """
    let blocks = StreamdownParser.parseBlocks(content: input, mode: .static)
    // In static mode, table at end of content with no trailing content
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

@Test func crlfNormalization() {
    let result = StreamdownParser.normalizeContent("a\r\nb", normalizeHtmlIndentation: false)
    #expect(result == "a\nb")
}

@Test func parseBlocksReturnsStreamdownBlockArray() {
    let blocks = StreamdownParser.parseBlocks(content: "hello")
    // Verify the return type is [StreamdownBlock] by using it as such
    let _: [StreamdownBlock] = blocks
    #expect(blocks.count == 1)
}
