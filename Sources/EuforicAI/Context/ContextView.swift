import SwiftUI

public struct ContextView: View {
    let used: Int
    let total: Int
    let label: String

    public init(used: Int, total: Int, label: String = "tokens") {
        self.used = used
        self.total = total
        self.label = label
    }

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(Double(used) / Double(total), 1.0)
    }

    private var color: Color {
        switch fraction {
        case 0..<0.6: return .green
        case 0.6..<0.85: return .orange
        default: return .red
        }
    }

    public var body: some View {
        HStack(spacing: EAISpacing.sm) {
            ZStack {
                Circle()
                    .stroke(EAIColors.gray5, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(formatted(used)) / \(formatted(total))")
                    .font(EAITypography.caption)
                    .fontWeight(.medium)
                Text(label)
                    .font(EAITypography.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatted(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }
}

#Preview {
    VStack(spacing: 16) {
        ContextView(used: 2048, total: 8192)
        ContextView(used: 6000, total: 8192)
        ContextView(used: 7800, total: 8192)
    }
    .padding()
}
