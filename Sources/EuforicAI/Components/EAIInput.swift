import SwiftUI

/// A flat, appearance-adaptive field that preserves native editing and focus.
public struct EAIInput: View {
    private let title: LocalizedStringKey
    @Binding private var text: String
    private let axis: Axis

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public init(
        _ title: LocalizedStringKey,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) {
        self.title = title
        self._text = text
        self.axis = axis
    }

    public var body: some View {
        TextField(title, text: $text, axis: axis)
            .textFieldStyle(.plain)
            .font(.body)
            .foregroundStyle(.primary)
            .padding(.horizontal, EAISpacing.md)
            .padding(.vertical, EAISpacing.sm)
            .frame(minHeight: EAISpacing.minTouchTarget)
            .background(Color.primary.opacity(0.05), in: .rect(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        Color.primary.opacity(colorSchemeContrast == .increased ? 0.65 : 0.15),
                        lineWidth: 1
                    )
            }
            .opacity(isEnabled ? 1 : 0.5)
            .accessibilityLabel(Text(title))
    }
}
