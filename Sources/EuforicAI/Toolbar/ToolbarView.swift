import SwiftUI

public struct ToolbarView: View {
    let actions: [EAIControlAction]
    let alignment: Alignment
    var onAction: ((EAIControlAction) -> Void)?

    public init(
        actions: [EAIControlAction],
        alignment: Alignment = .leading,
        onAction: ((EAIControlAction) -> Void)? = nil
    ) {
        self.actions = actions
        self.alignment = alignment
        self.onAction = onAction
    }

    public var body: some View {
        HStack(spacing: EAISpacing.sm) {
            ForEach(actions) { action in
                Button {
                    onAction?(action)
                } label: {
                    Image(systemName: action.icon)
                        .font(.callout)
                        .frame(width: 32, height: 32)
                        .foregroundStyle(action.style == .destructive ? .red : .primary)
                        .background(EAIColors.secondaryBackground, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!action.isEnabled)
                .accessibilityLabel(action.title)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: alignment)
        .padding(EAISpacing.sm)
    }
}
