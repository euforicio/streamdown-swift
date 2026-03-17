import SwiftUI

public struct SnippetView: View {
    let command: String
    let showPromptSymbol: Bool

    @State private var copied = false

    public init(command: String, showPromptSymbol: Bool = true) {
        self.command = command
        self.showPromptSymbol = showPromptSymbol
    }

    public var body: some View {
        HStack(spacing: EAISpacing.sm) {
            if showPromptSymbol {
                Text("$")
                    .font(EAITypography.monoSmall)
                    .foregroundStyle(.tertiary)
            }

            Text(command)
                .font(EAITypography.monoSmall)
                .textSelection(.enabled)
                .lineLimit(1)

            Spacer()

            Button {
                CopyAction.perform(command, copied: $copied)
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(EAITypography.caption2)
                    .foregroundStyle(copied ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, EAISpacing.md)
        .padding(.vertical, EAISpacing.sm)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    VStack(spacing: 8) {
        SnippetView(command: "npm install shadcn-ai")
        SnippetView(command: "swift build")
    }
    .padding()
}
