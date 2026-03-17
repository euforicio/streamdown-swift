import SwiftUI

public struct VoiceSelectorView: View {
    let voices: [SASpeechVoice]
    let selectedVoiceID: String?
    var onSelect: ((SASpeechVoice) -> Void)?

    public init(
        voices: [SASpeechVoice],
        selectedVoiceID: String? = nil,
        onSelect: ((SASpeechVoice) -> Void)? = nil
    ) {
        self.voices = voices
        self.selectedVoiceID = selectedVoiceID
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: EAISpacing.sm) {
            ForEach(voices) { voice in
                HStack(spacing: EAISpacing.sm) {
                    Image(systemName: selectedVoiceID == voice.id ? "checkmark.seal.fill" : "speaker.wave.2")
                        .foregroundStyle(selectedVoiceID == voice.id ? .green : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(voice.name)
                            .font(EAITypography.callout)
                        Text("\(voice.locale) · \(voice.style)")
                            .font(EAITypography.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Use") {
                        onSelect?(voice)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(EAISpacing.sm)
                .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
