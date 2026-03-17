import SwiftUI

public struct BranchView: View {
    let branches: [EAIBranch]
    var onSelect: ((EAIBranch) -> Void)?

    public init(
        branches: [EAIBranch],
        onSelect: ((EAIBranch) -> Void)? = nil
    ) {
        self.branches = branches
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            ForEach(branches) { branch in
                Button {
                    onSelect?(branch)
                    EAIHaptics.light()
                } label: {
                    HStack(spacing: EAISpacing.sm) {
                        Image(systemName: branch.isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(branch.isSelected ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(branch.title)
                                .font(EAITypography.callout)
                                .foregroundStyle(.primary)
                            if !branch.detail.isEmpty {
                                Text(branch.detail)
                                    .font(EAITypography.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, EAISpacing.sm)
                }
                .buttonStyle(.plain)

                Divider()
            }
        }
        .padding(EAISpacing.md)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}
