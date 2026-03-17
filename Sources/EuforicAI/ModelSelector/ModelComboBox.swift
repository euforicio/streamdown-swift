import SwiftUI

public struct EAIModelComboBox: View {
    let models: [EAIModel]
    let selectedModelID: String
    let isLoading: Bool
    let onSelect: (String) -> Void

    @State private var searchText: String = ""

    public init(
        models: [EAIModel] = [],
        selectedModelID: String = "",
        isLoading: Bool = false,
        onSelect: @escaping (String) -> Void
    ) {
        self.models = models
        self.selectedModelID = selectedModelID
        self.isLoading = isLoading
        self.onSelect = onSelect
    }

    public var body: some View {
        Menu {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, EAISpacing.md)
            } else {
                modelSearchField
                Divider()

                if filteredModels.isEmpty {
                    HStack {
                        Text("No matching models")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, EAISpacing.md)
                    .padding(.vertical, EAISpacing.md)
                } else {
                    ForEach(filteredModels) { model in
                        Button {
                            selectModel(model)
                        } label: {
                            modelRow(model)
                        }
                        .buttonStyle(.plain)
                        if model.id != filteredModels.last?.id {
                            Divider()
                        }
                    }
                }

                if isCustomModel {
                    Divider()
                    Button {
                        commitCustomModel()
                    } label: {
                        HStack(spacing: EAISpacing.sm) {
                            Image(systemName: "plus")
                                .font(.footnote)
                            Text("Use \"\(trimmedSearch)\"")
                                .font(.footnote)
                        }
                        .padding(.horizontal, EAISpacing.md)
                        .padding(.vertical, EAISpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
        } label: {
            HStack(spacing: EAISpacing.xs) {
                Image(systemName: "cpu")
                    .font(.footnote)

                Text(triggerLabel)
                    .font(.footnote)
                    .lineLimit(1)

                if isLoading {
                    ProgressView()
                        .tint(EAIColors.secondaryForeground)
                        .scaleEffect(0.72)
                } else {
                    Image(systemName: "chevron.down")
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(EAIColors.mutedForeground)
            .padding(.horizontal, EAISpacing.md)
            .padding(.vertical, EAISpacing.sm)
            .background(EAIColors.muted, in: Capsule())
            .frame(minHeight: EAISpacing.minTouchTarget)
        }
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var triggerLabel: String {
        let normalized = selectedModelID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.isEmpty {
            return normalized
        }
        return models.first?.id.isEmpty == false ? models.first!.id : "Select model"
    }

    private var isCustomModel: Bool {
        let query = trimmedSearch.lowercased()
        guard !query.isEmpty else { return false }
        return !models.contains { model in
            model.id.lowercased() == query ||
            model.name.lowercased() == query
        }
    }

    private var filteredModels: [EAIModel] {
        if searchText.isEmpty {
            return models
        }
        return models.filter {
            let haystack = "\($0.name) \($0.provider) \($0.id)".lowercased()
            return haystack.contains(trimmedSearch.lowercased())
        }
    }

    private var modelSearchField: some View {
        HStack(spacing: EAISpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Search or type model...", text: $searchText)
                .font(EAITypography.caption)
                .foregroundStyle(EAIColors.foreground)
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
        .padding(.horizontal, EAISpacing.md)
        .padding(.vertical, EAISpacing.sm)
        .background(EAIColors.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(EAIColors.border.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, EAISpacing.sm)
        .padding(.vertical, EAISpacing.sm)
    }

    private func modelRow(_ model: EAIModel) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: EAISpacing.xxs) {
                Text(model.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if !model.provider.isEmpty {
                    Text(model.provider)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !model.description.isEmpty {
                    Text(model.description)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if selectedModelID == model.id {
                Spacer(minLength: EAISpacing.md)
                Image(systemName: "checkmark")
                    .font(EAITypography.caption)
                    .foregroundStyle(EAIColors.accent)
            }
        }
        .padding(.horizontal, EAISpacing.md)
        .padding(.vertical, EAISpacing.sm)
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
        selectModel(EAIModel(id: query, name: query, provider: "custom"))
    }

    private func selectModel(_ model: EAIModel) {
        EAIHaptics.light()
        onSelect(model.id)
    }
}
