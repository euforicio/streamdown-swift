import SwiftUI

public struct TaskItemView: View {
    let title: String
    let status: EAIToolStatus
    let detail: String

    @State private var isExpanded = false

    public init(title: String, status: EAIToolStatus = .pending, detail: String = "") {
        self.title = title
        self.status = status
        self.detail = detail
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                guard !detail.isEmpty else { return }
                EAIHaptics.light()
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: EAISpacing.sm) {
                    statusIcon

                    Text(title)
                        .font(EAITypography.callout)
                        .foregroundStyle(status == .completed ? .secondary : .primary)
                        .strikethrough(status == .completed)

                    Spacer()

                    if !detail.isEmpty {
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
                .padding(.vertical, EAISpacing.xs)
            }
            .buttonStyle(.plain)

            if !detail.isEmpty {
                Text(detail)
                    .font(EAITypography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, EAISpacing.lg)
                    .padding(.bottom, EAISpacing.sm)
                    .frame(maxHeight: isExpanded ? .none : 0)
                    .clipped()
                    .opacity(isExpanded ? 1 : 0)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .pending:
            Image(systemName: "circle")
                .font(EAITypography.caption)
                .foregroundStyle(.tertiary)
        case .running:
            ProgressView()
                .controlSize(.mini)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(EAITypography.caption)
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(EAITypography.caption)
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        TaskItemView(title: "Install dependencies", status: .completed)
        TaskItemView(title: "Run tests", status: .running, detail: "Running 42 test cases...")
        TaskItemView(title: "Deploy to staging", status: .pending)
        TaskItemView(title: "Integration test", status: .failed, detail: "Connection timeout")
    }
    .padding()
}
