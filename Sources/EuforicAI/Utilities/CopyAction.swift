import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
public struct CopyAction {
    public static func perform(_ text: String, copied: Binding<Bool>) {
        setClipboard(text)
        EAIHaptics.light()
        copied.wrappedValue = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copied.wrappedValue = false
        }
    }

    private static func setClipboard(_ text: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = text
#elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
    }
}
