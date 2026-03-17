import SwiftUI

public struct SchemaDisplayView: View {
    let schema: EAISchemaObject

    public init(schema: EAISchemaObject) {
        self.schema = schema
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            Text(schema.title)
                .font(EAITypography.callout)
                .fontWeight(.semibold)
                .lineLimit(2)

            if let method = schema.method, let path = schema.path {
                HStack(spacing: EAISpacing.sm) {
                    Text(method.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, EAISpacing.xs)
                        .padding(.vertical, 2)
                        .background(EAIColors.background, in: Capsule())
                        .foregroundStyle(.secondary)

                    Text(path)
                        .font(EAITypography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            if !schema.parameters.isEmpty {
                schemaSection("Parameters", fields: schema.parameters)
            }

            if !schema.requestBody.isEmpty {
                schemaSection("Request Body", fields: schema.requestBody)
            }

            if !schema.responseBody.isEmpty {
                schemaSection("Response Body", fields: schema.responseBody)
            }

            if !schema.fields.isEmpty {
                schemaSection("Fields", fields: schema.fields)
            }
        }
        .padding(EAISpacing.md)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func schemaSection(_ title: String, fields: [EAISchemaField]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(EAITypography.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(fields) { field in
                schemaFieldRow(field, indent: 0)
            }
        }
    }

    private func schemaFieldRow(_ field: EAISchemaField, indent: Int) -> AnyView {
        return AnyView(
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 6) {
                    Text(field.key)
                        .font(EAITypography.caption)
                    .fontWeight(.medium)

                if field.required {
                    Text("required")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                if let location = field.location {
                    Text(location)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Text(field.type)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 120, alignment: .trailing)
            }

            if !field.description.isEmpty {
                Text(field.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !field.properties.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(field.properties) { child in
                        schemaFieldRow(child, indent: indent + 1)
                    }
                }
            }
            }
            .padding(.leading, CGFloat(indent) * EAISpacing.md)
            .padding(.vertical, 6)
        )
    }
}
