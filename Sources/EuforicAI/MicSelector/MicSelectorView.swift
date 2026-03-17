import SwiftUI

public struct MicSelectorView: View {
    let microphones: [SAMicrophone]
    let selectedMicrophoneID: String?
    var onSelect: ((SAMicrophone) -> Void)?

    public init(
        microphones: [SAMicrophone],
        selectedMicrophoneID: String? = nil,
        onSelect: ((SAMicrophone) -> Void)? = nil
    ) {
        self.microphones = microphones
        self.selectedMicrophoneID = selectedMicrophoneID
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            ForEach(microphones) { mic in
                Button {
                    onSelect?(mic)
                } label: {
                    HStack(spacing: EAISpacing.sm) {
                        Image(systemName: selectedMicrophoneID == mic.id ? "dot.radiowaves.left.and.right" : "mic")
                            .foregroundStyle(selectedMicrophoneID == mic.id ? .blue : .secondary)
                        VStack(alignment: .leading) {
                            Text(mic.name)
                                .font(EAITypography.callout)
                            Text(mic.locale)
                                .font(EAITypography.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, EAISpacing.sm)
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
        .padding(EAISpacing.sm)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 10))
    }
}
