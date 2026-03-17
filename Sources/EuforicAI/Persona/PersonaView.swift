import SwiftUI

public struct PersonaView: View {
    let persona: EAIPersona
    var onToggle: ((EAIPersona) -> Void)?
    var onEditPrompt: ((EAIPersona) -> Void)?
    @State private var isActive: Bool

    public init(
        persona: EAIPersona,
        onToggle: ((EAIPersona) -> Void)? = nil,
        onEditPrompt: ((EAIPersona) -> Void)? = nil
    ) {
        self.persona = persona
        self.onToggle = onToggle
        self.onEditPrompt = onEditPrompt
        self._isActive = State(initialValue: persona.isActive)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(persona.name)
                        .font(EAITypography.callout)
                        .fontWeight(.semibold)

                    Text(persona.tone)
                        .font(EAITypography.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $isActive)
                    .labelsHidden()
                    .onChange(of: isActive) { _, value in
                        var updatedPersona = persona
                        updatedPersona.isActive = value
                        onToggle?(updatedPersona)
                    }
            }

            Text(persona.systemPrompt)
                .font(EAITypography.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            if !persona.constraints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Constraints")
                        .font(EAITypography.caption2)
                        .foregroundStyle(.tertiary)
                    ForEach(persona.constraints, id: \.self) { item in
                        Text("• \(item)")
                            .font(EAITypography.caption2)
                    }
                }
            }

            if onEditPrompt != nil {
                Button("Edit prompt") { onEditPrompt?(persona) }
                    .buttonStyle(.bordered)
                    .font(EAITypography.caption)
            }
        }
        .padding(EAISpacing.md)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}
