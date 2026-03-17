import SwiftUI

public struct CommitView: View {
    let commit: EAICommit
    var onTap: ((EAICommit) -> Void)?

    public init(commit: EAICommit, onTap: ((EAICommit) -> Void)? = nil) {
        self.commit = commit
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            onTap?(commit)
        } label: {
            HStack(alignment: .top, spacing: EAISpacing.sm) {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(commit.message)
                        .font(EAITypography.callout)
                        .foregroundStyle(.primary)

                    HStack {
                        Text(commit.hash)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .textSelection(.enabled)

                        Spacer()

                        Text(commit.author)
                            .font(EAITypography.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(commit.date.formatted(.relative(presentation: .named)))
                        .font(EAITypography.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(EAISpacing.sm)
        }
        .buttonStyle(.plain)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 10))
    }
}
