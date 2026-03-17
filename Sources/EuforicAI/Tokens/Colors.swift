import SwiftUI

public enum EAIColors {
    // Core tokens matching web CSS variables (dark theme)
    public static let background = Color(white: 0.08)         // hsl(0, 0%, 8%)
    public static let foreground = Color(white: 0.93)         // hsl(0, 0%, 93%)
    public static let card = Color(white: 0.10)               // hsl(0, 0%, 10%)
    public static let cardForeground = Color(white: 0.93)     // hsl(0, 0%, 93%)
    public static let primary = Color(white: 0.98)            // hsl(0, 0%, 98%)
    public static let primaryForeground = Color(white: 0.08)  // hsl(0, 0%, 8%)
    public static let secondary = Color(white: 0.14)          // hsl(0, 0%, 14%)
    public static let secondaryForeground = Color(white: 0.93) // hsl(0, 0%, 93%)
    public static let muted = Color(white: 0.14)              // hsl(0, 0%, 14%)
    public static let mutedForeground = Color(white: 0.55)    // hsl(0, 0%, 55%)
    public static let destructive = Color(red: 0.96, green: 0.25, blue: 0.37)  // hsl(0, 84.2%, 60.2%)
    public static let border = Color(white: 0.16)             // hsl(0, 0%, 16%)
    public static let accent = Color(white: 0.14)             // hsl(0, 0%, 14%)
    public static let accentForeground = Color(white: 0.93)   // hsl(0, 0%, 93%)
    public static let sidebar = Color(white: 0.10)            // hsl(0, 0%, 10%)

    // Backward-compatible aliases
    public static let primaryLabel = foreground
    public static let secondaryLabel = mutedForeground
    public static let tertiaryLabel = Color(white: 0.40)
    public static let secondaryBackground = card
    public static let tertiaryBackground = secondary
    public static let separator = border
    public static let gray4 = border
    public static let gray5 = Color(white: 0.12)
    public static let gray6 = Color(white: 0.10)

    // Semantic colors
    public static let success = Color.green
    public static let error = Color.red
    public static let warning = Color.orange
    public static let info = Color.blue
}
