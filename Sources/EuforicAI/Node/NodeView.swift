import SwiftUI

public struct NodeView: View {
    let node: EAINode
    let isHighlighted: Bool
    let onTap: ((EAINode) -> Void)?

    public init(node: EAINode, isHighlighted: Bool = false, onTap: ((EAINode) -> Void)? = nil) {
        self.node = node
        self.isHighlighted = isHighlighted
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            onTap?(node)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(node.title)
                        .font(EAITypography.callout)
                        .fontWeight(.medium)
                    Spacer()
                    if isHighlighted {
                        Image(systemName: "pin.fill")
                            .foregroundStyle(.yellow)
                    }
                }

                if !node.description.isEmpty {
                    Text(node.description)
                        .font(EAITypography.caption2)
                        .foregroundStyle(.secondary)
                }

                if !node.metadata.isEmpty {
                    Text(node.metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
                        .font(EAITypography.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }
            .padding(EAISpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isHighlighted ? Color.accentColor.opacity(0.12) : EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
