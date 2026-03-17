import SwiftUI

public struct LoaderView: View {
    let text: String
    let style: LoaderStyle
    let size: CGFloat

    public init(text: String = "Loading...", style: LoaderStyle = .spinner, size: CGFloat = 16) {
        self.text = text
        self.style = style
        self.size = size
    }

    public var body: some View {
        HStack(spacing: EAISpacing.sm) {
            switch style {
            case .spinner:
                SpinnerLoader(size: max(size, 8))
                    .frame(width: max(size, 8), height: max(size, 8))
            case .dots:
                DotsLoader(size: max(size, 8))
                    .frame(width: max(size, 8) * 1.6, height: max(size, 8))
            case .bars:
                BarsLoader(size: max(size, 8))
                    .frame(width: max(size, 8) * 1.2, height: max(size, 8))
            }

            if !text.isEmpty {
                Text(text)
                    .font(EAITypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(EAISpacing.md)
    }

    public enum LoaderStyle: String, Sendable {
        case spinner
        case dots
        case bars
    }
}

private struct SpinnerLoader: View {
    let size: CGFloat
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: max(2, size / 7))
                .foregroundStyle(.tertiary.opacity(0.45))

            Circle()
                .trim(from: 0.15, to: 0.85)
                .stroke(style: StrokeStyle(lineWidth: max(2, size / 7), lineCap: .round))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
        }
        .onAppear {
            isAnimating = true
        }
        .animation(
            .linear(duration: 0.82).repeatForever(autoreverses: false),
            value: isAnimating
        )
    }
}

private struct DotsLoader: View {
    let size: CGFloat
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: max(2, size / 4)) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.secondary)
                    .frame(width: max(3, size / 3.3), height: max(3, size / 3.3))
                    .scaleEffect(isAnimating ? 1 : 0.35)
                    .opacity(isAnimating ? 1 : 0.35)
                    .animation(
                        .easeInOut(duration: 0.42)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.11),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

private struct BarsLoader: View {
    let size: CGFloat
    @State private var isAnimating = false

    private var barWidth: CGFloat {
        max(2, size * 0.24)
    }

    var body: some View {
        HStack(spacing: max(3, size * 0.2)) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(.secondary)
                    .frame(width: barWidth, height: size)
                    .scaleEffect(y: isAnimating ? 1 : 0.28)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.12),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
