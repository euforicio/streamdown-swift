import SwiftUI

public struct StreamingCursor: View {
    @State private var visible = true

    public init() {}

    public var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Color.accentColor)
            .frame(width: 3, height: 16)
            .opacity(visible ? 1 : 0)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: visible)
            .onAppear { visible = false }
    }
}

#Preview {
    StreamingCursor()
        .padding()
}
