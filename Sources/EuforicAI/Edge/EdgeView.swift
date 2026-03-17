import SwiftUI

public struct EdgeView: View {
    let edge: EAIConnectionEdge

    public init(edge: EAIConnectionEdge) {
        self.edge = edge
    }

    public var body: some View {
        HStack(spacing: EAISpacing.xs) {
            Text(edge.fromNodeID.prefix(8))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(edge.toNodeID.prefix(8))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if !edge.label.isEmpty {
                Text("— \(edge.label)")
                    .font(EAITypography.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
