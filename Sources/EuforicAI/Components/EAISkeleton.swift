import SwiftUI

public struct EAISkeleton: View {
    let width: CGFloat?
    let height: CGFloat

    public init(width: CGFloat? = nil, height: CGFloat = 20) {
        self.width = width
        self.height = height
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(EAIColors.muted)
            .frame(width: width, height: height)
            .shimmer(active: true)
    }
}
