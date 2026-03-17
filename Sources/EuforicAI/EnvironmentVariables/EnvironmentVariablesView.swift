import SwiftUI

private enum EAIEnvironmentVariablesStyle {
    static let cornerRadius: CGFloat = 12
    static let valueLineSpacing = EAISpacing.xxs
}

public struct EnvironmentVariablesView: View {
    let variables: [EAIEnvironmentVariable]
    var onDelete: ((EAIEnvironmentVariable) -> Void)?
    var onToggleSecret: ((EAIEnvironmentVariable) -> Void)?

    @State private var revealed: Set<String> = []

    public init(
        variables: [EAIEnvironmentVariable],
        onDelete: ((EAIEnvironmentVariable) -> Void)? = nil,
        onToggleSecret: ((EAIEnvironmentVariable) -> Void)? = nil
    ) {
        self.variables = variables
        self.onDelete = onDelete
        self.onToggleSecret = onToggleSecret
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            ForEach(Array(variables.enumerated()), id: \.element.id) { index, variable in
                HStack(alignment: .top, spacing: EAISpacing.sm) {
                    VStack(alignment: .leading, spacing: EAIEnvironmentVariablesStyle.valueLineSpacing) {
                        Text(variable.key)
                            .font(EAITypography.callout)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Text(displayValue(for: variable))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .lineLimit(nil)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    HStack(spacing: EAISpacing.xs) {
                        if variable.isSecret {
                            Button {
                                toggle(variable)
                            } label: {
                                Image(systemName: revealed.contains(variable.id) ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.plain)
                        }

                        if onDelete != nil {
                            Button {
                                onDelete?(variable)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, EAISpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)

                if index < variables.count - 1 {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EAISpacing.md)
        .background(
            EAIColors.secondaryBackground,
            in: RoundedRectangle(cornerRadius: EAIEnvironmentVariablesStyle.cornerRadius)
        )
    }

    private func displayValue(for variable: EAIEnvironmentVariable) -> String {
        if variable.isSecret && !revealed.contains(variable.id) {
            return variable.maskedValue()
        }
        return variable.value
    }

    private func toggle(_ variable: EAIEnvironmentVariable) {
        if revealed.contains(variable.id) {
            revealed.remove(variable.id)
        } else {
            revealed.insert(variable.id)
        }
        onToggleSecret?(variable)
    }
}
