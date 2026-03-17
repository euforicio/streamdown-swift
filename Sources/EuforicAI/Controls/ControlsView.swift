import SwiftUI

public struct ControlsView: View {
    let controls: [EAIControlAction]
    var onAction: ((EAIControlAction) -> Void)?

    public init(controls: [EAIControlAction], onAction: ((EAIControlAction) -> Void)? = nil) {
        self.controls = controls
        self.onAction = onAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            ForEach(controls) { control in
                Button {
                    onAction?(control)
                    EAIHaptics.light()
                } label: {
                    HStack(spacing: EAISpacing.sm) {
                        Image(systemName: control.icon)
                            .font(.callout)
                        Text(control.title)
                            .font(EAITypography.callout)
                        Spacer()
                        if control.isActive {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(textColor(for: control))
                    .padding(.vertical, EAISpacing.sm)
                    .padding(.horizontal, EAISpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(backgroundColor(for: control), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!control.isEnabled)
            }
        }
        .padding(EAISpacing.md)
    }

    private func textColor(for control: EAIControlAction) -> Color {
        switch control.style {
        case .destructive:
            return .red
        case .primary:
            return control.isActive ? .white : .blue
        case .secondary, .plain:
            return .primary
        }
    }

    private func backgroundColor(for control: EAIControlAction) -> Color {
        switch control.style {
        case .destructive:
            return Color.red.opacity(0.15)
        case .primary:
            return control.isActive ? .blue : .secondary.opacity(0.15)
        case .secondary, .plain:
            return EAIColors.secondaryBackground
        }
    }
}
