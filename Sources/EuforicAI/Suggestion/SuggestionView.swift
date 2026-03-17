import SwiftUI

public struct SuggestionView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    public init(
        suggestions: [String] = [
            "Write a Python script",
            "Explain this code",
            "Help me debug",
            "Summarize this",
        ],
        onSelect: @escaping (String) -> Void
    ) {
        self.suggestions = suggestions
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: EAISpacing.sm) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        EAIHaptics.light()
                        onSelect(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(EAITypography.subheadline)
                            .padding(.horizontal, EAISpacing.md)
                            .padding(.vertical, EAISpacing.sm)
                            .frame(minHeight: EAISpacing.minTouchTarget)
                            .background(
                                EAIColors.secondaryBackground,
                                in: Capsule()
                            )
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
            }
            .padding(.horizontal, EAISpacing.base)
        }
    }
}

#Preview {
    SuggestionView { suggestion in
        print(suggestion)
    }
}
