import SwiftUI

public struct SandboxView: View {
    let sessions: [EAISandboxSession]
    let onRun: ((String) -> Void)?

    @State private var command: String = ""

    public init(sessions: [EAISandboxSession], onRun: ((String) -> Void)? = nil) {
        self.sessions = sessions
        self.onRun = onRun
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            HStack(spacing: EAISpacing.sm) {
                TextField("Run command", text: $command, axis: .horizontal)
                    .textFieldStyle(.roundedBorder)

                Button("Run") {
                    onRun?(command)
                    command = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            ForEach(sessions) { session in
                VStack(alignment: .leading, spacing: EAISpacing.xs) {
                    HStack(spacing: EAISpacing.sm) {
                        Text(session.command)
                            .font(EAITypography.caption)
                            .lineLimit(1)
                        Spacer()
                        if session.isRunning {
                            ProgressView()
                                .controlSize(.mini)
                        }
                    }

                    if !session.output.isEmpty {
                        Text(session.output)
                            .font(EAITypography.monoSmall2)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    Text(String(format: "Elapsed: %.1fs", session.elapsed))
                        .font(EAITypography.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(EAISpacing.sm)
                .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(EAISpacing.sm)
        .background(EAIColors.tertiaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}
