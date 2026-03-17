import SwiftUI

public struct ShimmerView: View {
    let lineCount: Int
    let widths: [CGFloat]
    let lineHeight: CGFloat
    let cornerRadius: CGFloat

    @State private var phase: CGFloat = 0

    public init(
        lineCount: Int = 3,
        widths: [CGFloat] = [200, 160, 120],
        lineHeight: CGFloat = 12,
        cornerRadius: CGFloat = 4
    ) {
        self.lineCount = lineCount
        self.widths = widths
        self.lineHeight = lineHeight
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            ForEach(0..<lineCount, id: \.self) { index in
                shimmerBar(width: widths.indices.contains(index) ? widths[index] : widths.last ?? 120)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }

    private func shimmerBar(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(EAIColors.gray5)
            .frame(width: max(width, 72), height: lineHeight)
            .overlay(
                GeometryReader { proxy in
                    let shimmerWidth = max(proxy.size.width * 1.7, 96)
                    LinearGradient(
                        colors: [EAIColors.gray5.opacity(0), EAIColors.gray4, EAIColors.gray5.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: shimmerWidth, height: proxy.size.height)
                    .offset(x: phase * (proxy.size.width + shimmerWidth) - shimmerWidth)
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    ShimmerView()
        .padding()
}
