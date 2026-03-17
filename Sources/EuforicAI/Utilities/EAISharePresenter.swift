import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public enum EAISharePresenter {
    @MainActor
    public static func shareText(_ text: String, filename: String, type: String = "text/plain") {
        guard !text.isEmpty else { return }

        #if canImport(UIKit)
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let file = tempDirectory.appendingPathComponent(filename)

        do {
            try text.write(to: file, atomically: true, encoding: .utf8)
        } catch {
            return
        }

        let activity = UIActivityViewController(activityItems: [file], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return
        }
        let presenter = root.presentedViewController ?? root
        activity.popoverPresentationController?.sourceView = presenter.view
        presenter.present(activity, animated: true)
        #else
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        #endif
    }
}
