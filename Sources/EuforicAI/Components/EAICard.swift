import SwiftUI

public struct EAICard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .background(EAIColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(EAIColors.border, lineWidth: 1)
            }
    }
}

public struct EAICardHeader<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(.horizontal, EAISpacing.base)
            .padding(.top, EAISpacing.base)
            .padding(.bottom, EAISpacing.sm)
    }
}

public struct EAICardContent<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(.horizontal, EAISpacing.base)
            .padding(.bottom, EAISpacing.base)
    }
}

public struct EAICardTitle: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(EAIColors.cardForeground)
    }
}
