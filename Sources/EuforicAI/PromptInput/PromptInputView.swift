import SwiftUI

public enum PromptInputStatus: String, Sendable {
    case ready
    case submitting
    case streaming
    case error
}

public struct PromptInputView: View {
    @Binding var text: String
    let isStreaming: Bool
    let status: PromptInputStatus
    let onSend: () -> Void
    let onCancel: () -> Void
    var onAttach: (() -> Void)?
    var onStopStreaming: (() -> Void)?
    var modelName: String = ""
    var modelOptions: [EAIModel] = []
    var isModelLoading: Bool = false
    var onModelSelect: ((String) -> Void)?
    var discoveryWarning: String = ""
    var sendOnReturn: Bool = true
    var allowsSwipeToDismissKeyboard: Bool = false
    var dismissFocusTrigger: UInt = 0

    @FocusState private var isFocused: Bool

    public init(
        text: Binding<String>,
        isStreaming: Bool = false,
        status: PromptInputStatus = .ready,
        onSend: @escaping () -> Void,
        onCancel: @escaping () -> Void = {},
        onStopStreaming: (() -> Void)? = nil,
        onAttach: (() -> Void)? = nil,
        modelName: String = "",
        modelOptions: [EAIModel] = [],
        isModelLoading: Bool = false,
        onModelSelect: ((String) -> Void)? = nil,
        discoveryWarning: String = "",
        sendOnReturn: Bool = true,
        allowsSwipeToDismissKeyboard: Bool = false,
        dismissFocusTrigger: UInt = 0
    ) {
        self._text = text
        self.isStreaming = isStreaming
        self.status = status
        self.onSend = onSend
        self.onCancel = onCancel
        self.onStopStreaming = onStopStreaming
        self.onAttach = onAttach
        self.modelName = modelName
        self.modelOptions = modelOptions
        self.isModelLoading = isModelLoading
        self.onModelSelect = onModelSelect
        self.discoveryWarning = discoveryWarning
        self.sendOnReturn = sendOnReturn
        self.allowsSwipeToDismissKeyboard = allowsSwipeToDismissKeyboard
        self.dismissFocusTrigger = dismissFocusTrigger
    }

    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSend: Bool {
        !isEmpty
    }

    private var isBusy: Bool {
        isStreaming || status == .submitting || status == .streaming
    }

    private var shouldShowStopAction: Bool {
        if isStreaming {
            return isEmpty
        }
        return status == .submitting || status == .streaming
    }

    private var placeholder: String {
        "Ask anything, @ to add files, / for commands"
    }

    public var body: some View {
        VStack(spacing: EAISpacing.xs) {
            TextField(placeholder, text: $text, axis: .vertical)
                .font(.body)
                .textFieldStyle(.plain)
                .accessibilityIdentifier("prompt-input-textfield")
                .focused($isFocused)
                .lineLimit(1...5)
                .padding(.horizontal, EAISpacing.base)
                .padding(.vertical, EAISpacing.md)
                .onKeyPress(keys: [.return], phases: .down) { keyPress in
                    guard canSend else { return .ignored }

                    let hasShift = keyPress.modifiers.contains(.shift)
                    let hasShortcutModifier = keyPress.modifiers.contains(.command) || keyPress.modifiers.contains(.control)

                    if sendOnReturn {
                        guard !hasShift else { return .ignored }
                        submitMessage()
                        return .handled
                    }

                    guard hasShortcutModifier, !hasShift else { return .ignored }
                    submitMessage()
                    return .handled
                }
                .onAppear {
                    DispatchQueue.main.async {
                        isFocused = true
                    }
                }
                .onChange(of: dismissFocusTrigger) { _, _ in
                    isFocused = false
                }

            HStack(spacing: EAISpacing.md) {
                if let onAttach {
                    Button(action: onAttach) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: EAISpacing.minTouchTarget, height: EAISpacing.minTouchTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Attach file")
                }

                controlsCluster

                Spacer()

                actionButton
            }
            .padding(.horizontal, EAISpacing.base)
            .padding(.bottom, EAISpacing.sm)

            if !discoveryWarning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(discoveryWarning)
                    .font(.caption2)
                    .foregroundStyle(EAIColors.warning)
                    .padding(.horizontal, EAISpacing.base)
                    .padding(.horizontal, EAISpacing.xs)
                    .lineLimit(2)
                    .padding(.bottom, EAISpacing.xs)
            }
        }
        .background(
            EAIColors.secondaryBackground,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .simultaneousGesture(
            swipeDownDismissGesture,
            including: allowsSwipeToDismissKeyboard ? .subviews : .none
        )
    }

    private var sendForeground: Color {
        switch status {
        case .ready:
            return isEmpty ? EAIColors.tertiaryLabel : EAIColors.info
        case .error:
            return .red
        case .submitting, .streaming:
            return Color.secondary
        }
    }

    private func cancelAction() {
        if let onStopStreaming {
            onStopStreaming()
        } else {
            onCancel()
        }
    }

    @ViewBuilder
    private var controlsCluster: some View {
        if let onModelSelect {
            HStack(spacing: EAISpacing.sm) {
                EAIModelComboBox(
                    models: modelOptions,
                    selectedModelID: modelName,
                    isLoading: isModelLoading,
                    onSelect: onModelSelect
                )
                .accessibilityLabel("Select model")
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if shouldShowStopAction {
            Button(action: cancelAction) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.red)
                    .frame(width: EAISpacing.minTouchTarget, height: EAISpacing.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Stop")
            .accessibilityIdentifier("prompt-input-stop-button")
        } else {
            Button {
                submitMessage()
            } label: {
                Image(systemName: status == .error ? "arrow.clockwise.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(sendForeground)
                    .frame(width: EAISpacing.minTouchTarget, height: EAISpacing.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("Send message")
            .accessibilityIdentifier("prompt-input-send-button")
        }
    }

    private func submitMessage() {
        onSend()
        DispatchQueue.main.async {
            isFocused = true
        }
    }

    private var swipeDownDismissGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onEnded { value in
                guard allowsSwipeToDismissKeyboard, isFocused else { return }
                let vertical = value.translation.height
                let horizontal = abs(value.translation.width)
                guard vertical > 24, vertical > horizontal else { return }
                isFocused = false
            }
    }
}

#Preview {
    @Previewable @State var text = ""
    PromptInputView(
        text: $text,
        onSend: {},
        onAttach: {}
    )
}
