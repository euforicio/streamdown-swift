import SwiftUI

public struct FileTreeNode: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let isDirectory: Bool
    public let children: [FileTreeNode]

    public init(
        id: String = UUID().uuidString,
        name: String,
        isDirectory: Bool = false,
        children: [FileTreeNode] = []
    ) {
        self.id = id
        self.name = name
        self.isDirectory = isDirectory || !children.isEmpty
        self.children = children
    }
}

public struct FileTreeView: View {
    let nodes: [FileTreeNode]

    public init(nodes: [FileTreeNode]) {
        self.nodes = nodes
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(nodes) { node in
                FileTreeNodeView(node: node, depth: 0)
            }
        }
    }
}

struct FileTreeNodeView: View {
    let node: FileTreeNode
    let depth: Int

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                guard node.isDirectory else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: EAISpacing.xs) {
                    if node.isDirectory {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(width: 12)
                    } else {
                        Color.clear.frame(width: 12)
                    }

                    Image(systemName: node.isDirectory ? (isExpanded ? "folder.fill" : "folder") : fileIcon(node.name))
                        .font(EAITypography.caption)
                        .foregroundStyle(node.isDirectory ? .orange : .secondary)

                    Text(node.name)
                        .font(EAITypography.monoSmall)
                        .foregroundStyle(.primary)
                }
                .padding(.leading, CGFloat(depth) * EAISpacing.base)
                .padding(.vertical, EAISpacing.xxs)
            }
            .buttonStyle(.plain)

            if node.isDirectory {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(node.children) { child in
                        FileTreeNodeView(node: child, depth: depth + 1)
                    }
                }
                .frame(maxHeight: isExpanded ? .none : 0)
                .clipped()
                .opacity(isExpanded ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
    }

    private func fileIcon(_ name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "js", "ts", "jsx", "tsx": return "chevron.left.forwardslash.chevron.right"
        case "json", "yaml", "yml", "toml": return "doc.text"
        case "md": return "doc.richtext"
        case "png", "jpg", "jpeg", "gif", "svg": return "photo"
        default: return "doc"
        }
    }
}

#Preview {
    FileTreeView(nodes: [
        FileTreeNode(name: "Sources", children: [
            FileTreeNode(name: "Models", children: [
                FileTreeNode(name: "Message.swift"),
                FileTreeNode(name: "Source.swift"),
            ]),
            FileTreeNode(name: "Views", children: [
                FileTreeNode(name: "ChatView.swift"),
            ]),
        ]),
        FileTreeNode(name: "Package.swift"),
        FileTreeNode(name: "README.md"),
    ])
    .padding()
}
