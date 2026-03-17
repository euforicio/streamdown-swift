import SwiftUI

public struct AgentView: View {
    let agent: EAIChatAgent
    var onTap: ((String) -> Void)?
    var onSend: ((EAIChatAgent, String) -> Void)?
    @State private var draft: String = ""

    public init(
        agent: EAIChatAgent,
        onTap: ((String) -> Void)? = nil,
        onSend: ((EAIChatAgent, String) -> Void)? = nil
    ) {
        self.agent = agent
        self.onTap = onTap
        self.onSend = onSend
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            HStack(spacing: EAISpacing.sm) {
                Circle()
                    .fill(statusTint)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(agent.name)
                        .font(EAITypography.callout)
                        .fontWeight(.semibold)

                    Text(agent.role)
                        .font(EAITypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(agent.status.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(.white)
                    .background(statusTint, in: Capsule())
            }

            Text(agent.description)
                .font(EAITypography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if !agent.capabilities.isEmpty {
                HStack(spacing: EAISpacing.xs) {
                    ForEach(agent.capabilities, id: \.self) { capability in
                        Text(capability)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(EAIColors.secondaryBackground, in: Capsule())
                    }
                }
            }

            HStack {
                TextField("Send to this agent", text: $draft, axis: .horizontal)
                    .textFieldStyle(.roundedBorder)

                Button("Send") {
                    let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    onSend?(agent, trimmed)
                    draft = ""
                    EAIHaptics.send()
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(EAISpacing.md)
        .background(EAIColors.tertiaryBackground, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture { onTap?(agent.id) }
    }

    private var statusTint: Color {
        switch agent.status {
        case .idle:
            return .orange
        case .active:
            return .blue
        case .reasoning:
            return .purple
        case .done:
            return .green
        case .failed:
            return .red
        }
    }
}
