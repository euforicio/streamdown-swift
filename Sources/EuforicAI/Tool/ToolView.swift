import SwiftUI

enum EAIToolTextSanitizer {
    private static let boilerplatePatterns = [
        #"(?i)tool\s*call\s*request(?:ed)?:?"#,
        #"(?i)tool\s*call\s*response(?:d)?:?"#,
        #"(?i)toolcall\s*request(?:ed)?:?"#,
        #"(?i)toolcall\s*response(?:d)?:?"#,
        #"(?i)\b[a-z0-9_.-]+\s+call\s+started\b\s*:[^\n\r]*"#,
        #"(?i)\b[a-z0-9_.-]+\s+call\s+complete(?:d)?\b\s*:[^\n\r]*"#,
        #"(?i)\b[a-z0-9_.-]+\s+call\s+started\b"#,
        #"(?i)\b[a-z0-9_.-]+\s+call\s+complete(?:d)?\b"#,
        #"(?im)^\s*\b[a-z0-9_.-]+\s+call\b\s*:?$"#
    ]

    static func sanitize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        var cleaned = trimmed
        for pattern in boilerplatePatterns {
            cleaned = cleaned.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression
            )
        }

        return cleaned
            .replacingOccurrences(of: #"[ \t]{2,}"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[ \t]+\n"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"\n[ \t]+"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum EAIToolViewStyle {
    static let cornerRadius: CGFloat = 14
    static let borderOpacity: Double = 0.75
    static let cardPadding = EAISpacing.md
    static let expandedSpacing = EAISpacing.md
    static let headerIconSize: CGFloat = 16
    static let disclosureIconSize: CGFloat = 14
    static let headerSpacing = EAISpacing.sm
    static let codeCornerRadius: CGFloat = 10
    static let statusIconSize: CGFloat = 11
    static let statusHorizontalPadding = EAISpacing.sm
    static let statusVerticalPadding = EAISpacing.xxs
}

struct EAIToolPayloadSection: Identifiable {
    let id: String
    let title: String
    let text: String
    let language: String?
}

struct EAIToolPayloadPresentation {
    let sections: [EAIToolPayloadSection]

    init(command: String, output: String) {
        let commandText = EAIToolTextSanitizer.sanitize(command)
        let outputText = EAIToolTextSanitizer.sanitize(output)

        var sections: [EAIToolPayloadSection] = []

        if !commandText.isEmpty {
            sections.append(
                EAIToolPayloadSection(
                    id: "parameters",
                    title: "PARAMETERS",
                    text: commandText,
                    language: Self.payloadLanguage(for: commandText)
                )
            )
        }

        if !outputText.isEmpty {
            sections.append(
                EAIToolPayloadSection(
                    id: "result",
                    title: "RESULT",
                    text: outputText,
                    language: Self.payloadLanguage(for: outputText)
                )
            )
        }

        self.sections = sections
    }

    private static func payloadLanguage(for text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            return "json"
        }

        if trimmed.contains("\n") || trimmed.contains("$ ") {
            return "bash"
        }

        return nil
    }
}

struct EAIToolStatusStyle {
    let title: String
    let icon: String
    let foreground: Color
    let background: Color

    static func make(for status: EAIToolStatus) -> EAIToolStatusStyle {
        switch status {
        case .pending:
            EAIToolStatusStyle(
                title: "Pending",
                icon: "clock",
                foreground: EAIColors.warning,
                background: EAIColors.warning.opacity(0.14)
            )
        case .running:
            EAIToolStatusStyle(
                title: "Running",
                icon: "arrow.trianglehead.2.clockwise.rotate.90",
                foreground: EAIColors.info,
                background: EAIColors.info.opacity(0.14)
            )
        case .completed:
            EAIToolStatusStyle(
                title: "Completed",
                icon: "checkmark.circle",
                foreground: EAIColors.success,
                background: EAIColors.success.opacity(0.14)
            )
        case .failed:
            EAIToolStatusStyle(
                title: "Failed",
                icon: "xmark.circle",
                foreground: EAIColors.destructive,
                background: EAIColors.destructive.opacity(0.14)
            )
        }
    }
}

public struct ToolView: View {
    let message: EAIMessage

    @State private var isExpanded = false
    @State private var payloadPresentation: EAIToolPayloadPresentation

    public init(message: EAIMessage) {
        self.message = message
        _payloadPresentation = State(
            initialValue: EAIToolPayloadPresentation(
                command: message.toolCommand,
                output: message.toolOutput
            )
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? EAIToolViewStyle.expandedSpacing : 0) {
            headerButton

            if isExpanded {
                VStack(alignment: .leading, spacing: EAIToolViewStyle.expandedSpacing) {
                    ForEach(payloadPresentation.sections) { section in
                        payloadSection(section)
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    )
                )
            }
        }
        .padding(EAIToolViewStyle.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: EAIToolViewStyle.cornerRadius)
                .fill(EAIColors.card.opacity(0.96))
        )
        .overlay {
            RoundedRectangle(cornerRadius: EAIToolViewStyle.cornerRadius)
                .stroke(EAIColors.separator.opacity(EAIToolViewStyle.borderOpacity), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tool-view-root")
        .animation(.snappy(duration: 0.22), value: isExpanded)
        .onChange(of: message.toolCommand) { _, newCommand in
            refreshPayloadPresentation(command: newCommand, output: message.toolOutput)
        }
        .onChange(of: message.toolOutput) { _, newOutput in
            refreshPayloadPresentation(command: message.toolCommand, output: newOutput)
        }
    }

    private var headerButton: some View {
        Button(action: toggleExpanded) {
            HStack(alignment: .center, spacing: EAIToolViewStyle.headerSpacing) {
                Image(systemName: "wrench.adjustable")
                    .font(.system(size: EAIToolViewStyle.headerIconSize, weight: .medium))
                    .foregroundStyle(EAIColors.mutedForeground)
                    .frame(width: EAIToolViewStyle.headerIconSize + EAISpacing.xs)

                Text(message.toolName.isEmpty ? "Tool" : message.toolName)
                    .font(EAITypography.callout.weight(.medium))
                    .foregroundStyle(EAIColors.foreground)
                    .lineLimit(1)

                statusPill

                Spacer(minLength: EAISpacing.sm)

                Image(systemName: "chevron.down")
                    .font(.system(size: EAIToolViewStyle.disclosureIconSize, weight: .medium))
                    .foregroundStyle(EAIColors.mutedForeground)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.snappy(duration: 0.22), value: isExpanded)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tool-view-toggle")
    }

    private var statusPill: some View {
        let style = EAIToolStatusStyle.make(for: message.toolStatus)

        return HStack(spacing: EAISpacing.xxs) {
            Image(systemName: style.icon)
                .font(.system(size: EAIToolViewStyle.statusIconSize, weight: .medium))

            Text(style.title)
                .font(EAITypography.caption.weight(.medium))
                .lineLimit(1)
        }
        .foregroundStyle(style.foreground)
        .padding(.horizontal, EAIToolViewStyle.statusHorizontalPadding)
        .padding(.vertical, EAIToolViewStyle.statusVerticalPadding)
        .background(style.background, in: Capsule())
        .accessibilityIdentifier("tool-view-status-pill")
    }

    @ViewBuilder
    private func payloadSection(_ section: EAIToolPayloadSection) -> some View {
        VStack(alignment: .leading, spacing: EAISpacing.xs) {
            Text(section.title)
                .font(EAITypography.caption2.weight(.semibold))
                .tracking(0.9)
                .foregroundStyle(EAIColors.mutedForeground)

            CodeBlockView(
                language: section.language,
                code: section.text,
                showLineNumbers: false,
                showHeader: false,
                density: .compact
            )
            .clipShape(.rect(cornerRadius: EAIToolViewStyle.codeCornerRadius))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(section.title + "\n" + section.text)
        .accessibilityIdentifier("tool-view-section-\(section.id)")
    }

    private func refreshPayloadPresentation(command: String, output: String) {
        payloadPresentation = EAIToolPayloadPresentation(command: command, output: output)
    }

    private func toggleExpanded() {
        EAIHaptics.light()
        withAnimation(.snappy(duration: 0.22)) {
            isExpanded.toggle()
        }
    }
}

#Preview {
    ToolView(message: .preview(
        role: .tool,
        toolName: "Weather Lookup",
        toolCommand: """
        {
          "location": "San Francisco, CA",
          "units": "fahrenheit"
        }
        """,
        toolOutput: """
        {
          "temperature": 68,
          "condition": "Partly cloudy",
          "humidity": 65,
          "wind": "12 mph NW"
        }
        """,
        toolStatus: .completed
    ))
    .padding()
    .background(EAIColors.background)
}
