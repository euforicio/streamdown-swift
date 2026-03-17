import SwiftUI

public struct EAIModel: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let provider: String
    public let description: String

    public init(id: String, name: String, provider: String = "", description: String = "") {
        self.id = id
        self.name = name
        self.provider = provider
        self.description = description
    }
}

public struct ModelSelectorView: View {
    let models: [EAIModel]
    @Binding var selected: EAIModel?
    var onDismiss: () -> Void

    @State private var searchText = ""

    public init(
        models: [EAIModel],
        selected: Binding<EAIModel?>,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.models = models
        self._selected = selected
        self.onDismiss = onDismiss
    }

    private var filteredModels: [EAIModel] {
        if searchText.isEmpty { return models }
        let query = searchText.lowercased()
        return models.filter {
            $0.name.lowercased().contains(query) ||
            $0.provider.lowercased().contains(query) ||
            $0.id.lowercased().contains(query)
        }
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isCustomModel: Bool {
        let query = trimmedSearch.lowercased()
        guard !query.isEmpty else { return false }
        return !models.contains { $0.id.lowercased() == query || $0.name.lowercased() == query }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modelSearchField
                Divider()
                modelRows
            }
                .navigationTitle("Select Model")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done", action: onDismiss)
                    }
                }
        }
    }

    private var modelRows: some View {
        ScrollView {
            VStack(spacing: 0) {
                if filteredModels.isEmpty {
                    HStack {
                        Text("No matching models")
                            .foregroundStyle(.secondary)
                            .font(EAITypography.caption2)
                        Spacer()
                    }
                    .padding(.horizontal, EAISpacing.md)
                    .padding(.vertical, EAISpacing.md)
                } else {
                    ForEach(filteredModels) { model in
                        modelRow(model)
                        Divider()
                    }
                }

                if isCustomModel {
                    Button("Use \"\(trimmedSearch)\"") {
                        commitCustomModel()
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, EAISpacing.md)
                    .padding(.vertical, EAISpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var modelSearchField: some View {
        TextField("Search or type model...", text: $searchText)
            .font(EAITypography.caption)
            .padding(.horizontal, EAISpacing.md)
            .padding(.vertical, EAISpacing.sm)
            #if canImport(UIKit)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            #endif
            .onSubmit {
                commitCurrentSelection()
            }
            #if canImport(UIKit)
            .submitLabel(.search)
            #endif
    }

    private func commitCurrentSelection() {
        guard !trimmedSearch.isEmpty else { return }
        if isCustomModel {
            commitCustomModel()
            return
        }
        if filteredModels.count == 1 {
            selectModel(filteredModels[0])
        }
    }

    private func commitCustomModel() {
        let query = trimmedSearch
        guard !query.isEmpty else { return }
        selectModel(EAIModel(id: query, name: query, provider: "runtime"))
    }

    private func selectModel(_ model: EAIModel) {
        EAIHaptics.light()
        selected = model
        searchText = ""
        onDismiss()
    }

    private func modelRow(_ model: EAIModel) -> some View {
        Button {
            selectModel(model)
        } label: {
            HStack(alignment: .top) {
                modelInfo(model)
                Spacer()
                if selected?.id == model.id {
                    Image(systemName: "checkmark")
                        .font(EAITypography.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func modelInfo(_ model: EAIModel) -> some View {
        VStack(alignment: .leading, spacing: EAISpacing.xxs) {
            Text(model.name)
                .font(EAITypography.callout)
                .fontWeight(.medium)
            if !model.provider.isEmpty {
                Text(model.provider)
                    .font(EAITypography.caption2)
                    .foregroundStyle(.secondary)
            }
            if !model.description.isEmpty {
                Text(model.description)
                    .font(EAITypography.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
    }
}

#Preview {
    @Previewable @State var selected: EAIModel? = nil
    ModelSelectorView(
        models: [
            EAIModel(id: "claude-opus-4-6", name: "Claude Opus 4.6", provider: "Anthropic", description: "Most capable model"),
            EAIModel(id: "claude-sonnet-4-6", name: "Claude Sonnet 4.6", provider: "Anthropic", description: "Fast and balanced"),
            EAIModel(id: "gpt-4o", name: "GPT-4o", provider: "OpenAI", description: "Multimodal model"),
        ],
        selected: $selected
    )
}
