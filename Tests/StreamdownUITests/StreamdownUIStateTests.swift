import Streamdown
import Testing
@testable import StreamdownUI

@MainActor
@Test func renderModelPublishesParsedMarkdown() async {
    let model = StreamdownRenderModel()

    await model.render(
        content: "Hello **world**",
        mode: .static,
        parseIncompleteMarkdown: false,
        normalizeHtmlIndentation: false
    )

    for _ in 0..<100 where model.snapshot.blocks.isEmpty {
        try? await Task.sleep(for: .milliseconds(10))
    }

    #expect(model.snapshot.blocks.count == 1)
}

@Test func renderActorKeepsMarkdownSourceAndReusesStableBlocks() async {
    let actor = StreamdownRenderActor()
    let initialContent = """
    Intro with **emphasis**.

    ```swift
    let value = 1
    ```

    Tail
    """
    let initial = await actor.renderSnapshot(
        content: initialContent,
        mode: .streaming,
        parseIncompleteMarkdown: true,
        normalizeHtmlIndentation: false,
        previous: nil
    )

    guard case let .markdown(intro) = initial.blocks.first else {
        Issue.record("Expected the first rendered block to remain markdown")
        return
    }
    #expect(intro.source == "Intro with **emphasis**.\n")

    let updated = await actor.renderSnapshot(
        content: initialContent + " extended",
        mode: .streaming,
        parseIncompleteMarkdown: true,
        normalizeHtmlIndentation: false,
        previous: initial
    )

    #expect(updated.reusedBlockCount == 2)
    #expect(updated.reusedRenderedBlockCount == 2)
}

@MainActor
@Test func codeBlockStatePublishesUpdatedContent() async {
    let state = CodeBlockRenderState(code: "let value = 1", language: "swift")

    state.update(code: "let value = 2", language: "swift")

    for _ in 0..<100 where state.lineTexts != ["let value = 2"] {
        try? await Task.sleep(for: .milliseconds(10))
    }

    #expect(state.normalizedCode == "let value = 2")
    #expect(state.lineTexts == ["let value = 2"])
    #expect(state.renderVersion > 1)
}

@MainActor
@Test func codeBlockStatePublishesThemeChanges() async {
    let state = CodeBlockRenderState(code: "// note", language: "swift")
    let initialVersion = state.renderVersion

    state.updateAppearance(foreground: .red, secondaryLabel: .blue)

    for _ in 0..<100 where state.renderVersion == initialVersion {
        try? await Task.sleep(for: .milliseconds(10))
    }

    #expect(state.renderVersion > initialVersion)
}
