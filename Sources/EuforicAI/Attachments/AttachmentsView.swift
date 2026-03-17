import SwiftUI

public enum EAIAttachmentLayout: Sendable {
    case grid
    case inline
    case list
}

public struct AttachmentsView: View {
    let attachments: [EAIAttachment]
    let layout: EAIAttachmentLayout
    var onTap: ((EAIAttachment) -> Void)?
    var onRemove: ((EAIAttachment) -> Void)?

    public init(
        attachments: [EAIAttachment],
        layout: EAIAttachmentLayout = .inline,
        onTap: ((EAIAttachment) -> Void)? = nil,
        onRemove: ((EAIAttachment) -> Void)? = nil
    ) {
        self.attachments = attachments
        self.layout = layout
        self.onTap = onTap
        self.onRemove = onRemove
    }

    public var body: some View {
        switch layout {
        case .grid:
            gridLayout
        case .inline:
            inlineLayout
        case .list:
            listLayout
        }
    }

    private var gridLayout: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: EAISpacing.sm) {
            ForEach(attachments) { attachment in
                attachmentCard(attachment)
            }
        }
    }

    private var inlineLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: EAISpacing.sm) {
                ForEach(attachments) { attachment in
                    attachmentChip(attachment)
                }
            }
        }
    }

    private var listLayout: some View {
        VStack(alignment: .leading, spacing: EAISpacing.xs) {
            ForEach(attachments) { attachment in
                attachmentRow(attachment)
            }
        }
    }

    private func attachmentCard(_ attachment: EAIAttachment) -> some View {
        VStack(spacing: EAISpacing.xs) {
            Image(systemName: attachment.iconName)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(height: 40)

            Text(attachment.name)
                .font(EAITypography.caption2)
                .lineLimit(1)
                .truncationMode(.middle)

            if let size = attachment.formattedSize {
                Text(size)
                    .font(EAITypography.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(EAISpacing.sm)
        .frame(maxWidth: .infinity)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 8))
        .onTapGesture { onTap?(attachment) }
        .overlay(alignment: .topTrailing) {
            removeButton(attachment)
        }
    }

    private func attachmentChip(_ attachment: EAIAttachment) -> some View {
        HStack(spacing: EAISpacing.xs) {
            Image(systemName: attachment.iconName)
                .font(EAITypography.caption2)
                .foregroundStyle(.secondary)
            Text(attachment.name)
                .font(EAITypography.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, EAISpacing.sm)
        .padding(.vertical, EAISpacing.xs)
        .background(EAIColors.secondaryBackground, in: Capsule())
        .onTapGesture { onTap?(attachment) }
        .overlay(alignment: .topTrailing) {
            removeButton(attachment)
        }
    }

    private func attachmentRow(_ attachment: EAIAttachment) -> some View {
        HStack(spacing: EAISpacing.sm) {
            Image(systemName: attachment.iconName)
                .font(EAITypography.caption)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(attachment.name)
                .font(EAITypography.caption)
                .lineLimit(1)

            Spacer()

            if let size = attachment.formattedSize {
                Text(size)
                    .font(EAITypography.caption2)
                    .foregroundStyle(.tertiary)
            }

            if onRemove != nil {
                Button {
                    onRemove?(attachment)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, EAISpacing.xxs)
        .onTapGesture { onTap?(attachment) }
    }

    @ViewBuilder
    private func removeButton(_ attachment: EAIAttachment) -> some View {
        if let onRemove {
            Button {
                onRemove(attachment)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: -4)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AttachmentsView(attachments: [
            EAIAttachment(name: "main.swift", kind: .code, size: 1024),
            EAIAttachment(name: "photo.png", kind: .image, size: 2_048_000),
        ], layout: .inline)

        AttachmentsView(attachments: [
            EAIAttachment(name: "report.pdf", kind: .document, size: 512_000),
            EAIAttachment(name: "data.json", kind: .file, size: 4096),
        ], layout: .list)
    }
    .padding()
}
