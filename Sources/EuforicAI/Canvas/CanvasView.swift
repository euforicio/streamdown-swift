import SwiftUI

public struct CanvasView: View {
    let title: String
    let nodes: [EAINode]
    let edges: [EAIConnectionEdge]
    let highlightedNodeID: String?
    var onSelectNode: ((EAINode) -> Void)?

    public init(
        title: String = "Canvas",
        nodes: [EAINode],
        edges: [EAIConnectionEdge] = [],
        highlightedNodeID: String? = nil,
        onSelectNode: ((EAINode) -> Void)? = nil
    ) {
        self.title = title
        self.nodes = nodes
        self.edges = edges
        self.highlightedNodeID = highlightedNodeID
        self.onSelectNode = onSelectNode
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            Text(title)
                .font(EAITypography.callout)
                .fontWeight(.semibold)

            VStack(spacing: EAISpacing.md) {
                ForEach(nodes) { node in
                    VStack(alignment: .leading, spacing: 4) {
                        NodeView(node: node, isHighlighted: node.id == highlightedNodeID)
                            .onTapGesture { onSelectNode?(node) }

                        if !outgoing(node).isEmpty {
                            VStack(alignment: .leading, spacing: EAISpacing.xs) {
                                ForEach(outgoing(node)) { edge in
                                    EdgeView(edge: edge)
                                }
                            }
                            .padding(.leading, EAISpacing.lg)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(EAISpacing.md)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func outgoing(_ node: EAINode) -> [EAIConnectionEdge] {
        edges.filter { $0.fromNodeID == node.id }
    }
}
