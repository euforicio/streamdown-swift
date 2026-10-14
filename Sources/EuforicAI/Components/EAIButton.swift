import SwiftUI

public enum EAIButtonVariant: Sendable {
    case primary
    case secondary
    case outline
    case ghost
    case destructive
    case link
    case glass
    case glassProminent
}

public struct EAIButton<Label: View>: View {
    let variant: EAIButtonVariant
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    @ViewBuilder private let label: () -> Label

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.isEnabled) private var isEnabled

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

    @ViewBuilder
    public var body: some View {
        switch variant {
        case .glass:
            button.buttonStyle(.glass)
        case .glassProminent:
            button
                .buttonStyle(.glassProminent)
                .tint(colorScheme == .dark ? .white : .black)
        default:
            button
                .buttonStyle(.plain)
                .foregroundStyle(foregroundColor)
                .background(backgroundColor, in: .rect(cornerRadius: 10))
                .overlay {
                    if variant == .outline {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                Color.primary.opacity(colorSchemeContrast == .increased ? 0.65 : 0.2),
                                lineWidth: 1
                            )
                    }
                }
                .opacity(isEnabled && !isDisabled && !isLoading ? 1 : 0.5)
        }
    }

    @ViewBuilder
    private var button: some View {
        if isLoading {
            nativeButton.accessibilityValue(Text("Loading"))
        } else {
            nativeButton
        }
    }

    private var nativeButton: some View {
        Button(role: variant == .destructive ? .destructive : nil, action: action) {
            label()
                .foregroundStyle(foregroundColor)
                .opacity(isLoading ? 0 : 1)
                .overlay {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(foregroundColor)
                            .accessibilityHidden(true)
                    }
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, variant == .link ? EAISpacing.xs : EAISpacing.sm)
                .padding(.vertical, EAISpacing.sm)
                .frame(minWidth: EAISpacing.minTouchTarget, minHeight: EAISpacing.minTouchTarget)
                .contentShape(.rect(cornerRadius: 10))
        }
        .disabled(isLoading || isDisabled)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .glassProminent:
            return colorScheme == .dark ? .black : .white
        case .destructive:
            return EAIComponentColors.destructiveForeground(for: colorScheme)
        case .secondary, .outline, .ghost, .glass:
            return .primary
        case .link:
            return .accentColor
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return .primary
        case .secondary:
            return .primary.opacity(0.08)
        case .destructive:
            return EAIComponentColors.destructiveBackground(for: colorScheme)
        case .outline, .ghost, .link, .glass, .glassProminent:
            return .clear
        }
    }
}

// Convenience icon preset. Supply a localized action name for VoiceOver.
public struct EAIActionIconButton: View {
    let systemName: String
    let variant: EAIButtonVariant
    @ScaledMetric(relativeTo: .caption) private var scaledSize: CGFloat = 14
    let accessibilityLabel: LocalizedStringKey?
    let action: () -> Void

    public init(
        systemName: String,
        variant: EAIButtonVariant = .ghost,
        size: CGFloat = 14,
        accessibilityLabel: LocalizedStringKey? = nil,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.variant = variant
        self._scaledSize = ScaledMetric(wrappedValue: size, relativeTo: .caption)
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    @ViewBuilder
    public var body: some View {
        if let accessibilityLabel {
            button.accessibilityLabel(Text(accessibilityLabel))
        } else {
            button
        }
    }

    private var button: some View {
        EAIButton(variant, action: action) {
            Image(systemName: systemName)
                .font(.system(size: scaledSize, weight: .medium))
        }
    }
}

// Explicit opaque sRGB pairs keep small destructive text readable in both appearances.
enum EAIComponentColors {
    static func destructiveForeground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(.sRGB, red: 255.0 / 255, green: 180.0 / 255, blue: 171.0 / 255)
            : Color(.sRGB, red: 180.0 / 255, green: 35.0 / 255, blue: 24.0 / 255)
    }

    static func destructiveBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(.sRGB, red: 42.0 / 255, green: 18.0 / 255, blue: 17.0 / 255)
            : Color(.sRGB, red: 253.0 / 255, green: 233.0 / 255, blue: 231.0 / 255)
    }
}

