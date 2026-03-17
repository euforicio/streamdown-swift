import SwiftUI

public struct EAIDropdownMenu<Label: View, Content: View>: View {
    let role: ButtonRole?
    let label: () -> Label
    let content: () -> Content

    public init(
        role: ButtonRole? = nil,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.role = role
        self.label = label
        self.content = content
    }

    public var body: some View {
        let _ = role

        Menu {
            content()
        } label: {
            HStack(spacing: 0) {
                label()
            }
            .frame(minWidth: EAISpacing.minTouchTarget, minHeight: EAISpacing.minTouchTarget)
        }
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
    }
}
