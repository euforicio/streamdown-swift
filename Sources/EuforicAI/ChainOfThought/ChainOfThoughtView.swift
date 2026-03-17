import SwiftUI

public struct ChainOfThoughtStep: Identifiable, Sendable {
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

public struct ChainOfThoughtView: View {
    let steps: [ChainOfThoughtStep]

    @State private var isExpanded = true

    public init(steps: [ChainOfThoughtStep]) {
        self.steps = steps
    }

    public var body: some View {
        Collapsible(isExpanded: $isExpanded) {
            HStack(spacing: EAISpacing.sm) {
                Image(systemName: "list.number")
                    .font(EAITypography.caption)
                    .foregroundStyle(.secondary)
                Text("Reasoning (\(steps.count) steps)")
                    .font(EAITypography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, EAISpacing.xs)
        } content: {
            VStack(alignment: .leading, spacing: EAISpacing.sm) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    stepRow(step, number: index + 1)
                }
            }
            .padding(.leading, EAISpacing.lg)
            .padding(.bottom, EAISpacing.sm)
        }
    }

    private func stepRow(_ step: ChainOfThoughtStep, number: Int) -> some View {
        HStack(alignment: .top, spacing: EAISpacing.sm) {
            stepStatusIcon(step.status)

            VStack(alignment: .leading, spacing: EAISpacing.xxs) {
                Text(step.title)
                    .font(EAITypography.caption)
                    .fontWeight(.medium)

                if !step.detail.isEmpty {
                    Text(step.detail)
                        .font(EAITypography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func stepStatusIcon(_ status: EAIToolStatus) -> some View {
        switch status {
        case .pending:
            Image(systemName: "circle")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        case .running:
            ProgressView()
                .controlSize(.mini)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    ChainOfThoughtView(steps: [
        ChainOfThoughtStep(title: "Parse the query", status: .completed),
        ChainOfThoughtStep(title: "Search for relevant files", detail: "Found 3 matches", status: .completed),
        ChainOfThoughtStep(title: "Generate response", status: .running),
        ChainOfThoughtStep(title: "Format output", status: .pending),
    ])
    .padding()
}
