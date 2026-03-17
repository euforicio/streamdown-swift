import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct UserBubble: View {
    let message: EAIMessage

    public init(message: EAIMessage) {
        self.message = message
    }

    public var body: some View {
        HStack {
            Spacer(minLength: 60)
            VStack(alignment: .trailing, spacing: EAISpacing.xs) {
                Text(message.text)
                    .font(EAITypography.body)
                    .textSelection(.enabled)
            }
            .padding(EAISpacing.md)
            .background(.tint, in: bubbleShape)
            .foregroundStyle(.white)
        }
        .contextMenu {
            Button {
                EAIHaptics.light()
                #if canImport(UIKit)
                UIPasteboard.general.string = message.text
                #elseif canImport(AppKit)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.text, forType: .string)
                #endif
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("user-bubble")
        .accessibilityLabel(message.text)
        .accessibilityValue(message.text)
        .accessibilityChildren {
            Text(message.text)
                .accessibilityLabel(message.text)
                .accessibilityIdentifier("user-bubble-text")
        }
    }

    private var bubbleShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 16,
            bottomLeadingRadius: 16,
            bottomTrailingRadius: 4,
            topTrailingRadius: 16
        )
    }
}

#Preview {
    UserBubble(message: .preview(role: .user, text: "Hello, world!"))
        .padding()
}
