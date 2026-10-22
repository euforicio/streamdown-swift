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

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public init(_ text: String, variant: EAIBadgeVariant = .default) {
        self.text = text
        self.variant = variant
    }

    public var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, EAISpacing.sm)
            .padding(.vertical, EAISpacing.xxs)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor, in: Capsule())
            .overlay {
                if variant == .outline {
                    Capsule()
                        .strokeBorder(
                            Color.primary.opacity(colorSchemeContrast == .increased ? 0.65 : 0.2),
                            lineWidth: 1
                        )
                }
            }
    }

    private var foregroundColor: Color {
        switch variant {
        case .default:
            return colorScheme == .dark ? .black : .white
        case .secondary, .outline:
            return .primary
        case .destructive:
            return EAIComponentColors.destructiveForeground(for: colorScheme)
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .default:
            return .primary
        case .secondary:
            return .primary.opacity(0.08)
        case .outline:
            return .clear
        case .destructive:
            return EAIComponentColors.destructiveBackground(for: colorScheme)
        }
    }
}
