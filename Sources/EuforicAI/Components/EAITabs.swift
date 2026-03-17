import SwiftUI

public struct EAITab: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let icon: String?

    public init(id: String, label: String, icon: String? = nil) {
        self.id = id
        self.label = label
        self.icon = icon
    }
}

public struct EAITabs: View {
    let tabs: [EAITab]
    @Binding var selectedID: String
    let compact: Bool

    public init(tabs: [EAITab], selectedID: Binding<String>, compact: Bool = false) {
        self.tabs = tabs
        self._selectedID = selectedID
        self.compact = compact
    }

    public var body: some View {
        HStack(spacing: EAISpacing.xxs) {
            ForEach(tabs) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedID = tab.id
                    }
                } label: {
                    HStack(spacing: EAISpacing.xs) {
                        if let icon = tab.icon {
                            Image(systemName: icon)
                                .font(compact ? .subheadline : .footnote)
                        }
                        if !compact {
                            Text(tab.label)
                                .font(.footnote.weight(.medium))
                                .lineLimit(1)
                                .fixedSize()
                        }
                    }
                    .frame(minWidth: EAISpacing.minTouchTarget, minHeight: EAISpacing.minTouchTarget)
                    .padding(.horizontal, compact ? EAISpacing.xs : EAISpacing.md)
                    .foregroundStyle(selectedID == tab.id ? EAIColors.foreground : EAIColors.mutedForeground)
                    .background(
                        selectedID == tab.id ? EAIColors.secondary : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(EAISpacing.xxs)
        .background(EAIColors.muted, in: RoundedRectangle(cornerRadius: 10))
    }
}
