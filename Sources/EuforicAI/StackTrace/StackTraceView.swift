import SwiftUI

public struct StackFrame: Identifiable, Sendable {
    public let id: String
    public let function: String
    public let file: String
    public let line: Int?
    public let isHighlighted: Bool

    public init(
        id: String = UUID().uuidString,
        function: String,
        file: String = "",
        line: Int? = nil,
        isHighlighted: Bool = false
    ) {
        self.id = id
        self.function = function
        self.file = file
        self.line = line
        self.isHighlighted = isHighlighted
    }
}

public struct StackTraceView: View {
    let errorMessage: String
    let frames: [StackFrame]

    @State private var isExpanded = false

    public init(errorMessage: String, frames: [StackFrame]) {
        self.errorMessage = errorMessage
        self.frames = frames
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            HStack(spacing: EAISpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(errorMessage)
                    .font(EAITypography.monoSmall)
                    .foregroundStyle(.red)
                    .lineLimit(isExpanded ? nil : 2)
            }

            if !frames.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: EAISpacing.xs) {
                        Text("\(frames.count) frame\(frames.count == 1 ? "" : "s")")
                            .font(EAITypography.caption2)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: EAISpacing.xxs) {
                ForEach(Array(frames.enumerated()), id: \.element.id) { index, frame in
                    frameRow(frame, index: index)
                }
            }
            .frame(maxHeight: isExpanded ? .none : 0)
            .clipped()
            .opacity(isExpanded ? 1 : 0)
            .animation(.easeInOut(duration: 0.25), value: isExpanded)
        }
        .padding(EAISpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private func frameRow(_ frame: StackFrame, index: Int) -> some View {
        HStack(alignment: .top, spacing: EAISpacing.sm) {
            Text("\(index)")
                .font(EAITypography.monoSmall2)
                .foregroundStyle(.tertiary)
                .frame(width: 20, alignment: .trailing)

            VStack(alignment: .leading, spacing: 0) {
                Text(frame.function)
                    .font(EAITypography.monoSmall2)
                    .foregroundStyle(frame.isHighlighted ? .red : .primary)
                    .fontWeight(frame.isHighlighted ? .semibold : .regular)

                if !frame.file.isEmpty {
                    HStack(spacing: EAISpacing.xxs) {
                        Text(frame.file)
                        if let line = frame.line {
                            Text(":\(line)")
                        }
                    }
                    .font(EAITypography.monoSmall2)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    StackTraceView(
        errorMessage: "Fatal error: Index out of range",
        frames: [
            StackFrame(function: "Array.subscript(_:)", file: "Array.swift", line: 420, isHighlighted: true),
            StackFrame(function: "ContentView.body.getter", file: "ContentView.swift", line: 15),
            StackFrame(function: "SwiftUI.ViewGraph.updateOutputs()"),
        ]
    )
    .padding()
}
