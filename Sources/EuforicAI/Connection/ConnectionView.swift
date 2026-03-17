import SwiftUI

public struct ConnectionView: View {
    let connection: EAIConnection
    var onConnect: ((EAIConnection) -> Void)?

    public init(connection: EAIConnection, onConnect: ((EAIConnection) -> Void)? = nil) {
        self.connection = connection
        self.onConnect = onConnect
    }

    public var body: some View {
        HStack(spacing: EAISpacing.sm) {
            RoundedRectangle(cornerRadius: 4)
                .fill(statusColor)
                .frame(width: 8, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(connection.title)
                    .font(EAITypography.callout)
                Text(connection.detail.isEmpty ? connection.state.rawValue.capitalized : connection.detail)
                    .font(EAITypography.caption)
                    .foregroundStyle(.secondary)
                Text("Signal: \(connection.strength.rawValue.capitalized)")
                    .font(EAITypography.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button(connection.state == .connected ? "Disconnect" : "Connect") {
                onConnect?(connection)
                EAIHaptics.send()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(EAISpacing.md)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 10))
    }

    private var statusColor: Color {
        switch connection.state {
        case .connected: return .green
        case .connecting: return .blue
        case .failed: return .red
        case .disconnected: return .secondary
        }
    }
}
