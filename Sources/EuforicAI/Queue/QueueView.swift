import SwiftUI

public struct QueueView: View {
    let items: [EAIQueueItem]
    let isStreaming: Bool
    var onTap: ((EAIQueueItem) -> Void)?

    public init(items: [EAIQueueItem], isStreaming: Bool = false, onTap: ((EAIQueueItem) -> Void)? = nil) {
        self.items = items
        self.isStreaming = isStreaming
        self.onTap = onTap
    }

    public var body: some View {
        VStack(spacing: EAISpacing.sm) {
            if isStreaming {
                ShimmerView(lineCount: 1, widths: [160])
                    .padding(.horizontal, EAISpacing.md)
            }

            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        statusIcon(for: item.state)
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(EAITypography.callout)
                            if !item.subtitle.isEmpty {
                                Text(item.subtitle)
                                    .font(EAITypography.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }

                    ProgressView(value: item.progress, total: 1)
                }
                .padding(EAISpacing.sm)
                .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 10))
                .onTapGesture { onTap?(item) }
            }
        }
    }

    @ViewBuilder
    private func statusIcon(for state: EAIQueueState) -> some View {
        switch state {
        case .queued:
            Image(systemName: "clock")
                .foregroundStyle(.yellow)
        case .running:
            ProgressView()
                .controlSize(.mini)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}
