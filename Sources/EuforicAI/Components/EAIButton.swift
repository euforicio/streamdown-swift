import SwiftUI

public enum EAIButtonVariant: Sendable {
    case primary
    case secondary
    case outline
    case ghost
    case destructive
    case link
}

public struct EAIButton<Label: View>: View {
    let variant: EAIButtonVariant
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    @ViewBuilder private let label: () -> Label

    public init(
        _ variant: EAIButtonVariant = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.variant = variant
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
        self.label = label
    }

    public var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(foregroundColor)
                } else {
                    label()
                }
            }
            .font(.caption)
            .fontWeight(.medium)
        }
        .buttonStyle(.plain)
        .foregroundStyle(foregroundColor)
        .frame(height: EAISpacing.minTouchTarget)
        .frame(minWidth: EAISpacing.minTouchTarget)
        .padding(.horizontal, variant == .link ? EAISpacing.xs : EAISpacing.sm)
        .background(backgroundColor)
        .overlay {
            if variant == .outline {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(EAIColors.border, lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(isDisabled ? 0.5 : 1)
        .disabled(isLoading || isDisabled)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return EAIColors.secondaryForeground
        case .secondary:
            return EAIColors.foreground
        case .outline:
            return EAIColors.foreground
        case .ghost, .link:
            return EAIColors.primary
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return EAIColors.primary
        case .secondary, .outline:
            return EAIColors.secondary
        case .ghost, .link:
            return .clear
        case .destructive:
            return EAIColors.destructive
        }
    }
}

// Convenience icon preset
public struct EAIActionIconButton: View {
    let systemName: String
    let variant: EAIButtonVariant
    let size: CGFloat
    let action: () -> Void

    public init(
        systemName: String,
        variant: EAIButtonVariant = .ghost,
        size: CGFloat = 14,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.variant = variant
        self.size = size
        self.action = action
    }

    public var body: some View {
        EAIButton(
            variant,
            isDisabled: false,
            action: action
        ) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .medium))
                .frame(width: EAISpacing.minTouchTarget, height: EAISpacing.minTouchTarget)
        }
    }
}

