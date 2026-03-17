import Testing
@testable import Streamdown

@Test func csvExport() {
    let table = StreamdownTableData(
        headers: ["Name", "Age"],
        rows: [["Alice", "30"], ["Bob", "25"]]
    )
    let csv = table.toCSV()
    #expect(csv == "Name,Age\nAlice,30\nBob,25")
}

@Test func tsvExport() {
    let table = StreamdownTableData(
        headers: ["Name", "Age"],
        rows: [["Alice", "30"], ["Bob", "25"]]
    )
    let tsv = table.toTSV()
    #expect(tsv == "Name\tAge\nAlice\t30\nBob\t25")
}

@Test func markdownTableExport() {
    let table = StreamdownTableData(
        headers: ["Name", "Age"],
        rows: [["Alice", "30"], ["Bob", "25"]]
    )
    let md = table.toMarkdownTable()
    let expected = """
    | Name | Age |
    | --- | --- |
    | Alice | 30 |
    | Bob | 25 |
    """
    #expect(md == expected)
}

@Test func csvEscaping() {
    let table = StreamdownTableData(
        headers: ["Value"],
        rows: [
            ["has \"quotes\""],
            ["has,comma"],
            ["has\nnewline"],
        ]
    )
    let csv = table.toCSV()
    let lines = csv.split(separator: "\n", omittingEmptySubsequences: false)
    #expect(lines[0] == "Value")
    #expect(lines[1] == "\"has \"\"quotes\"\"\"")
    #expect(String(lines[2]) == "\"has,comma\"")
    // The newline value will be inside quotes spanning two lines
    let remaining = lines[3...].joined(separator: "\n")
    #expect(remaining.contains("has"))
    #expect(remaining.contains("newline"))
}

@Test func emptyRows() {
    let table = StreamdownTableData(
        headers: ["A", "B"],
        rows: []
    )
    let csv = table.toCSV()
    #expect(csv == "A,B")

    let tsv = table.toTSV()
    #expect(tsv == "A\tB")

    let md = table.toMarkdownTable()
    #expect(md.contains("| A | B |"))
    #expect(md.contains("| --- | --- |"))
}

@Test func tsvEscaping() {
    let table = StreamdownTableData(
        headers: ["Col"],
        rows: [
            ["has\ttab"],
            ["has\nnewline"],
        ]
    )
    let tsv = table.toTSV()
    let lines = tsv.split(separator: "\n")
    #expect(lines[0] == "Col")
    #expect(lines[1] == "has\\ttab")
    #expect(lines[2] == "has\\nnewline")
}
