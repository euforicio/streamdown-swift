@preconcurrency import MarkdownUI
import SwiftUI

extension Theme {
    @MainActor public static let saiCodeHighlighted: Theme = .gitHub.text {
        ForegroundColor(.primary)
    }
    .codeBlock { configuration in
        CodeBlockView(
            language: configuration.language,
            code: configuration.content
        )
        .padding(.bottom, EAISpacing.sm)
    }
}
