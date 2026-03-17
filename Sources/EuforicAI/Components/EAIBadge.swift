import SwiftUI

public enum EAIBadgeVariant: Sendable {
    case `default`
    case secondary
    case outline
    case destructive
}

public struct EAIBadge: View {
    let text: String
    let variant: EAIBadgeVariant

    public init(_ text: String, variant: EAIBadgeVariant = .default) {
        self.text = text
        self.variant = variant
    }

    public var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, EAISpacing.sm)
            .padding(.vertical, EAISpacing.xxs)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor, in: Capsule())
            .overlay {
                if variant == .outline {
                    Capsule()
                        .strokeBorder(EAIColors.border, lineWidth: 1)
                }
            }
    }

    private var foregroundColor: Color {
        switch variant {
        case .default:
            return EAIColors.primaryForeground
        case .secondary:
            return EAIColors.secondaryForeground
        case .outline:
            return EAIColors.foreground
        case .destructive:
            return .white
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .default:
            return EAIColors.primary
        case .secondary:
            return EAIColors.secondary
        case .outline:
            return .clear
        case .destructive:
            return EAIColors.destructive
        }
    }
}
