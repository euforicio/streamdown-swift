import SwiftUI

public struct PanelView<PanelContent: View>: View {
    let title: String
    let isInitiallyExpanded: Bool
    @ViewBuilder let content: () -> PanelContent

    @State private var isExpanded: Bool

    public init(title: String, isInitiallyExpanded: Bool = true, @ViewBuilder content: @escaping () -> PanelContent) {
        self.title = title
        self.isInitiallyExpanded = isInitiallyExpanded
        self.content = content
        self._isExpanded = State(initialValue: isInitiallyExpanded)
    }

    public var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(title)
                        .font(EAITypography.callout)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(EAISpacing.md)
            }
            .buttonStyle(.plain)

            content()
                .padding([.horizontal, .bottom], EAISpacing.md)
                .frame(maxHeight: isExpanded ? .none : 0)
                .clipped()
                .opacity(isExpanded ? 1 : 0)
        }
        .animation(.snappy(duration: 0.25), value: isExpanded)
        .background(RoundedRectangle(cornerRadius: 12).fill(EAIColors.tertiaryBackground))
    }
}
