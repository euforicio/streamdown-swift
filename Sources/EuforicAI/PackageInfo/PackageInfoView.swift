import SwiftUI

public struct PackageInfoView: View {
    let name: String
    let version: String
    let build: String
    let description: String
    let repoURL: URL?
    let dependencies: [String]

    public init(
        name: String,
        version: String,
        build: String = "",
        description: String = "",
        repoURL: URL? = nil,
        dependencies: [String] = []
    ) {
        self.name = name
        self.version = version
        self.build = build
        self.description = description
        self.repoURL = repoURL
        self.dependencies = dependencies
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(EAITypography.callout)
                    .fontWeight(.semibold)
                Text("v\(version)")
                    .font(EAITypography.caption)
                    .foregroundStyle(.secondary)
                if !build.isEmpty {
                    Text("build \(build)")
                        .font(EAITypography.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if !description.isEmpty {
                Text(description)
                    .font(EAITypography.caption)
                    .foregroundStyle(.secondary)
            }

            if !dependencies.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dependencies")
                        .font(EAITypography.caption2)
                        .foregroundStyle(.secondary)

                    ForEach(dependencies, id: \.self) { dep in
                        Text("• \(dep)")
                            .font(EAITypography.caption2)
                    }
                }
            }

            if let repoURL {
                Link(destination: repoURL) {
                    Label("View source", systemImage: "arrow.up.right.square")
                }
                .font(EAITypography.caption)
                .foregroundStyle(.blue)
            }
        }
        .padding(EAISpacing.md)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 10))
    }
}
