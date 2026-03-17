import SwiftUI

public struct ScrollToBottomButton: View {
    let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.down")
                .font(.callout.weight(.semibold))
                .frame(width: EAISpacing.minTouchTarget, height: EAISpacing.minTouchTarget)
                .background(.ultraThinMaterial, in: Circle())
                .glassEffect(.regular.interactive(), in: .circle)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .accessibilityLabel("Scroll to bottom")
    }
}

#Preview {
    ScrollToBottomButton {}
        .padding()
}
