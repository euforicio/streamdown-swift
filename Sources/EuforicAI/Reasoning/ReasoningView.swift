import SwiftUI

public struct ReasoningView: View {
    let message: EAIMessage

    @State private var isExpanded: Bool

    public init(message: EAIMessage) {
        self.message = message
        self._isExpanded = State(initialValue: EAIReasoningPresentation.defaultExpanded(for: message))
    }

    public var body: some View {
        Collapsible(isExpanded: $isExpanded) {
            HStack(spacing: EAISpacing.sm) {
                Image(systemName: "brain")
                    .font(EAITypography.callout)
                    .foregroundStyle(.secondary)
                Text(triggerLabel)
                    .font(EAITypography.callout)
                    .foregroundStyle(.secondary)
                    .shimmer(active: message.isStreaming)
            }
            .padding(.vertical, EAISpacing.sm)
        } content: {
            Group {
            if message.isStreaming {
                    EAIStreamdown(
                        content: message.text,
                        isStreaming: true
                    )
                    .font(EAITypography.callout)
                    .foregroundStyle(.secondary)
                } else {
                    EAIStreamdown(content: message.text)
                        .font(EAITypography.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, EAISpacing.lg)
            .padding(.bottom, EAISpacing.sm)
        }
        .onChange(of: message.streamingState) {
            isExpanded = EAIReasoningPresentation.defaultExpanded(for: message)
        }
    }

    private var triggerLabel: String {
        EAIReasoningPresentation.triggerLabel(for: message)
    }
}

#Preview {
    ReasoningView(message: .preview(
        role: .reasoning,
        text: "Let me think about this step by step...",
        streamingState: .streaming
    ))
    .padding()
}
