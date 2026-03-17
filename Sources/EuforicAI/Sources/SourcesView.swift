import SwiftUI

public struct SourcesView: View {
    let sources: [EAISource]

    @State private var isExpanded = false

    public init(sources: [EAISource]) {
        self.sources = sources
    }

    public var body: some View {
        guard !sources.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            Collapsible(isExpanded: $isExpanded) {
                HStack(spacing: EAISpacing.sm) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(EAITypography.caption)
                        .foregroundStyle(.secondary)
                    Text("\(sources.count) source\(sources.count == 1 ? "" : "s")")
                        .font(EAITypography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, EAISpacing.xs)
            } content: {
                VStack(alignment: .leading, spacing: EAISpacing.xs) {
                    ForEach(sources) { source in
                        sourceRow(source)
                    }
                }
                .padding(.leading, EAISpacing.lg)
                .padding(.bottom, EAISpacing.sm)
            }
        )
    }

    private func sourceRow(_ source: EAISource) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let url = source.url {
                Link(destination: url) {
                    Text(source.title)
                        .font(EAITypography.caption)
                        .foregroundStyle(.blue)
                }
            } else {
                Text(source.title)
                    .font(EAITypography.caption)
                    .foregroundStyle(.primary)
            }

            if !source.snippet.isEmpty {
                Text(source.snippet)
                    .font(EAITypography.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

#Preview {
    SourcesView(sources: [
        EAISource(title: "Swift Documentation", url: URL(string: "https://swift.org"), snippet: "The Swift Programming Language"),
        EAISource(title: "Apple Developer", snippet: "iOS development resources"),
    ])
    .padding()
}
