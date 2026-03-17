import SwiftUI

public struct ArtifactView: View {
    let title: String
    let kind: String
    let content: String
    var onOpen: (() -> Void)?

    @State private var isExpanded = true
    @State private var copied = false

    public init(title: String, kind: String = "text", content: String, onOpen: (() -> Void)? = nil) {
        self.title = title
        self.kind = kind
        self.content = content
        self.onOpen = onOpen
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            VStack(spacing: 0) {
                Divider()
                Text(content)
                    .font(EAITypography.monoSmall)
                    .textSelection(.enabled)
                    .padding(EAISpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(maxHeight: 300)
            }
            .frame(maxHeight: isExpanded ? .none : 0)
            .clipped()
            .opacity(isExpanded ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(EAIColors.separator, lineWidth: 0.5)
        )
    }

    private var header: some View {
        HStack(spacing: EAISpacing.sm) {
            Image(systemName: artifactIcon)
                .font(EAITypography.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(EAITypography.caption)
                    .fontWeight(.medium)
                Text(kind)
                    .font(EAITypography.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                CopyAction.perform(content, copied: $copied)
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(EAITypography.caption2)
                    .foregroundStyle(copied ? .green : .secondary)
            }
            .buttonStyle(.plain)

            if let onOpen {
                Button(action: onOpen) {
                    Image(systemName: "arrow.up.right.square")
                        .font(EAITypography.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .buttonStyle(.plain)
        }
        .padding(EAISpacing.md)
    }

    private var artifactIcon: String {
        switch kind.lowercased() {
        case "code", "swift", "python", "javascript": return "chevron.left.forwardslash.chevron.right"
        case "html": return "globe"
        case "markdown", "text": return "doc.text"
        case "image": return "photo"
        default: return "doc"
        }
    }
}

#Preview {
    ArtifactView(
        title: "fibonacci.swift",
        kind: "code",
        content: "func fibonacci(_ n: Int) -> Int {\n    guard n > 1 else { return n }\n    return fibonacci(n - 1) + fibonacci(n - 2)\n}"
    )
    .padding()
}
