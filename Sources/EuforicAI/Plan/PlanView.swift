import SwiftUI

public struct PlanStep: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let status: EAIToolStatus

    public init(
        id: String = UUID().uuidString,
        title: String,
        detail: String = "",
        status: EAIToolStatus = .pending
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.status = status
    }
}

public struct PlanView: View {
    let title: String
    let steps: [PlanStep]
    let isStreaming: Bool

    public init(title: String = "Plan", steps: [PlanStep], isStreaming: Bool = false) {
        self.title = title
        self.steps = steps
        self.isStreaming = isStreaming
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            HStack(spacing: EAISpacing.sm) {
                Image(systemName: "list.clipboard")
                    .font(EAITypography.callout)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(EAITypography.callout)
                    .fontWeight(.medium)
                if isStreaming {
                    ProgressView()
                        .controlSize(.mini)
                }
            }

            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: EAISpacing.sm) {
                    stepIcon(step.status, index: index)
                        .frame(width: 20, alignment: .center)

                    VStack(alignment: .leading, spacing: EAISpacing.xxs) {
                        Text(step.title)
                            .font(EAITypography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(step.status == .completed ? .secondary : .primary)

                        if !step.detail.isEmpty {
                            Text(step.detail)
                                .font(EAITypography.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if isStreaming {
                ShimmerView(lineCount: 2, widths: [140, 100])
                    .padding(.leading, 28)
            }
        }
        .padding(EAISpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func stepIcon(_ status: EAIToolStatus, index: Int) -> some View {
        switch status {
        case .pending:
            Text("\(index + 1)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
        case .running:
            ProgressView()
                .controlSize(.mini)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    PlanView(steps: [
        PlanStep(title: "Read the file", status: .completed),
        PlanStep(title: "Analyze the code", detail: "Looking at the function signature", status: .running),
        PlanStep(title: "Write the fix", status: .pending),
        PlanStep(title: "Run tests", status: .pending),
    ], isStreaming: true)
    .padding()
}
