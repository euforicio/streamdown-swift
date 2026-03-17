import SwiftUI

public struct AudioPlayerView: View {
    let track: EAIAudioTrack
    let onPlayPause: ((EAIAudioTrack, Bool) -> Void)?
    let onSeek: ((EAIAudioTrack, TimeInterval) -> Void)?

    @State private var position: Double
    @State private var isPlaying: Bool
    @State private var volume: Double
    @State private var isMuted: Bool

    public init(
        track: EAIAudioTrack,
        isPlaying: Bool = false,
        onPlayPause: ((EAIAudioTrack, Bool) -> Void)? = nil,
        onSeek: ((EAIAudioTrack, TimeInterval) -> Void)? = nil
    ) {
        self.track = track
        self.onPlayPause = onPlayPause
        self.onSeek = onSeek
        self._isPlaying = State(initialValue: isPlaying)
        self._position = State(initialValue: 0)
        self._volume = State(initialValue: 0.85)
        self._isMuted = State(initialValue: false)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            HStack {
                Text(track.title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)

                Spacer()

                Text("\(formatDuration(position)) / \(formatDuration(track.durationSeconds))")
                    .font(EAITypography.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button {
                    seek(by: -10)
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    isPlaying.toggle()
                    onPlayPause?(track, isPlaying)
                    EAIHaptics.light()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    seek(by: 10)
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text(formatDuration(position))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)

                Slider(
                    value: $position,
                    in: 0...safeDuration,
                    onEditingChanged: { editing in
                        if !editing {
                            onSeek?(track, position)
                        }
                    }
                )
                .tint(.blue)

                Text(formatDuration(safeDuration))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .leading)
            }

            HStack(spacing: EAISpacing.sm) {
                Button {
                    isMuted.toggle()
                } label: {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Slider(value: $volume, in: 0...1)
                    .tint(.blue)
                    .disabled(isMuted)
                    .frame(width: 78)

                Spacer()
            }
        }
        .padding(EAISpacing.md)
        .background(
            EAIColors.tertiaryBackground,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(EAIColors.separator.opacity(0.45), lineWidth: 1)
        )
        .onAppear {
            if track.durationSeconds > 0 {
                position = min(position, track.durationSeconds)
            }
        }
    }

    private var safeDuration: Double {
        max(track.durationSeconds, 1)
    }

    private func seek(by delta: TimeInterval) {
        let target = max(0, min(position + delta, safeDuration))
        position = target
        onSeek?(track, target)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(Int(seconds), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

#Preview {
    AudioPlayerView(
        track: EAIAudioTrack(
            title: "Demo narration",
            durationSeconds: 124,
            source: "sample.mp3"
        ),
        isPlaying: false,
        onPlayPause: { _, _ in },
        onSeek: { _, _ in }
    )
}
