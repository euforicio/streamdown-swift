import SwiftUI

public struct TranscriptionView: View {
    let segments: [EAITranscriptionSegment]
    let onCopy: ((String) -> Void)?

    @State private var copied = false

    public init(segments: [EAITranscriptionSegment], onCopy: ((String) -> Void)? = nil) {
        self.segments = segments
        self.onCopy = onCopy
    }

    public var body: some View {
        VStack(spacing: EAISpacing.sm) {
            ForEach(segments) { segment in
                HStack(alignment: .top, spacing: EAISpacing.sm) {
                    Text(formatTime(segment.startSeconds))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(segment.speaker)
                            .font(EAITypography.caption)
                            .foregroundStyle(.tertiary)
                        Text(segment.text)
                            .font(EAITypography.caption)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }
                .padding(.vertical, 2)
                .padding(.horizontal, EAISpacing.md)
                .background(EAIColors.tertiaryBackground, in: RoundedRectangle(cornerRadius: 8))
            }

            Button(copied ? "Copied transcript" : "Copy transcript") {
                let transcript = segments.map(\.text).joined(separator: " ")
                if let onCopy {
                    onCopy(transcript)
                } else {
                    CopyAction.perform(transcript, copied: $copied)
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let value = max(Int(seconds), 0)
        return String(format: "%02d:%02d", (value / 60), (value % 60))
    }
}
