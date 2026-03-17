import SwiftUI

struct ShimmerModifier: ViewModifier {
    let active: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if active {
            content
                .opacity(0.4 + 0.6 * abs(sin(Double(phase))))
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        phase = .pi
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    public func shimmer(active: Bool) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}
