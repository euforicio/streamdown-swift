import SwiftUI

public struct CheckpointView: View {
    let checkpoints: [EAICheckpoint]
    var onActivate: ((EAICheckpoint) -> Void)?

    public init(checkpoints: [EAICheckpoint], onActivate: ((EAICheckpoint) -> Void)? = nil) {
        self.checkpoints = checkpoints
        self.onActivate = onActivate
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.md) {
            ForEach(Array(checkpoints.enumerated()), id: \.element.id) { index, checkpoint in
                Button {
                    onActivate?(checkpoint)
                } label: {
                    HStack(alignment: .top, spacing: EAISpacing.sm) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .frame(width: 22, height: 22)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: EAISpacing.xxs) {
                            Text(checkpoint.title)
                                .font(EAITypography.callout)
                            Text(checkpoint.state.capitalized)
                                .font(EAITypography.caption2)
                                .foregroundStyle(.secondary)

                            if !checkpoint.note.isEmpty {
                                Text(checkpoint.note)
                                    .font(EAITypography.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(checkpoint.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, EAISpacing.xs)
                }
                .buttonStyle(.plain)

                Divider()
            }
        }
    }
}
