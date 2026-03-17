import SwiftUI

public struct SpeechInputView: View {
    @Binding var text: String
    let isListening: Bool
    var onSend: (() -> Void)?
    var onToggleListening: (() -> Void)?

    @FocusState private var isFocused: Bool

    public init(
        text: Binding<String>,
        isListening: Bool = false,
        onSend: (() -> Void)? = nil,
        onToggleListening: (() -> Void)? = nil
    ) {
        self._text = text
        self.isListening = isListening
        self.onSend = onSend
        self.onToggleListening = onToggleListening
    }

    public var body: some View {
        HStack(spacing: EAISpacing.sm) {
            TextField("Speak or type", text: $text, axis: .vertical)
                .focused($isFocused)
                .lineLimit(1...4)

            Button {
                onToggleListening?()
                EAIHaptics.light()
            } label: {
                Image(systemName: isListening ? "waveform.circle.fill" : "mic.fill")
                    .foregroundStyle(isListening ? Color.red : Color.blue)
            }
            .buttonStyle(.plain)

            Button(action: { onSend?() }) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(text.isEmpty ? Color.secondary : Color.blue)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(.plain)
        }
        .padding(EAISpacing.md)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 18))
    }
}
