import SwiftUI

struct ContentBottomPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ViewportBottomPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollToBottomTracker: ViewModifier {
    @Binding var isNearBottom: Bool
    @State private var contentMaxY: CGFloat = 0
    @State private var viewportMaxY: CGFloat = 0
    let threshold: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ViewportBottomPreferenceKey.self, value: geo.frame(in: .global).maxY)
                }
            )
            .onPreferenceChange(ContentBottomPreferenceKey.self) { contentBottom in
                contentMaxY = contentBottom
                isNearBottom = contentMaxY - viewportMaxY < threshold
            }
            .onPreferenceChange(ViewportBottomPreferenceKey.self) { viewportBottom in
                viewportMaxY = viewportBottom
                isNearBottom = contentMaxY - viewportMaxY < threshold
            }
    }
}

extension View {
    public func trackScrollPosition(isNearBottom: Binding<Bool>, threshold: CGFloat = 100) -> some View {
        modifier(ScrollToBottomTracker(isNearBottom: isNearBottom, threshold: threshold))
    }
}

extension View {
    func contentBottomTracking() -> some View {
        background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ContentBottomPreferenceKey.self, value: geo.frame(in: .global).maxY)
            }
        )
    }
}
