import SwiftUI

public struct TestResultsView: View {
    let title: String
    let summary: EAITestResultSummary?
    let suites: [EAITestSuite]
    let results: [EAITestResult]
    var onTapResult: ((EAITestResult) -> Void)?
    @State private var expandedSuites: Set<String>

    public init(
        title: String = "Test Results",
        summary: EAITestResultSummary? = nil,
        suites: [EAITestSuite] = [],
        results: [EAITestResult] = [],
        onTapResult: ((EAITestResult) -> Void)? = nil
    ) {
        self.title = title
        self.summary = summary
        self.suites = suites
        self.results = results
        self.onTapResult = onTapResult
        _expandedSuites = State(initialValue: Set(suites.filter(\.defaultOpen).map(\.id)))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EAISpacing.sm) {
            Text(title)
                .font(EAITypography.callout)
                .fontWeight(.semibold)

            if let summary {
                summaryHeader(summary)
            }

            if !results.isEmpty && suites.isEmpty {
                testsSection(for: results)
            }

            if !suites.isEmpty {
                VStack(spacing: EAISpacing.sm) {
                    ForEach(suites) { suite in
                        suiteSection(suite)
                    }
                }
            }
        }
        .padding(EAISpacing.md)
        .background(EAIColors.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func summaryHeader(_ summary: EAITestResultSummary) -> some View {
        VStack(alignment: .leading, spacing: EAISpacing.xs) {
            HStack(spacing: EAISpacing.xs) {
                if summary.passed > 0 {
                    summaryBadge(summary.passed, label: "passed", tone: .green)
                }
                if summary.failed > 0 {
                    summaryBadge(summary.failed, label: "failed", tone: .red)
                }
                if summary.skipped > 0 {
                    summaryBadge(summary.skipped, label: "skipped", tone: .orange)
                }

                Spacer()

                Text(formatDuration(summary.durationMS))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TestResultsProgressView(summary: summary)
        }
    }

    @ViewBuilder
    private func testsSection(for tests: [EAITestResult]) -> some View {
        VStack(spacing: 0) {
            ForEach(tests) { result in
                resultItem(result)
            }
        }
    }

    @ViewBuilder
    private func suiteSection(_ suite: EAITestSuite) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedSuites.contains(suite.id) },
                set: { isExpanded in
                    if isExpanded {
                        expandedSuites.insert(suite.id)
                    } else {
                        expandedSuites.remove(suite.id)
                    }
                }
            )
        ) {
            VStack(spacing: 0) {
                ForEach(suite.tests) { result in
                    resultItem(result)
                    Divider()
                }
            }
            .padding(.leading, EAISpacing.md)
        } label: {
            HStack(spacing: EAISpacing.sm) {
                statusIcon(suite.status)
                    .frame(width: 12, height: 12)
                Text(suite.name)
                    .font(EAITypography.callout)
                Spacer()

                HStack(spacing: EAISpacing.xs) {
                    suiteStatistics(for: suite)
                    if suite.durationMS > 0 {
                        Text(formatDuration(suite.durationMS))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, EAISpacing.sm)
        }
        .padding(.horizontal, EAISpacing.sm)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2))
        )
    }

    @ViewBuilder
    private func suiteStatistics(for suite: EAITestSuite) -> some View {
        let passed = suite.tests.filter { $0.state == .pass }.count
        let failed = suite.tests.filter { $0.state == .fail }.count
        let skipped = suite.tests.filter { $0.state == .skipped }.count

        if passed > 0 {
            Text("\(passed) passed")
                .font(.caption2)
                .foregroundStyle(.green)
        }
        if failed > 0 {
            Text("\(failed) failed")
                .font(.caption2)
                .foregroundStyle(.red)
        }
        if skipped > 0 {
            Text("\(skipped) skipped")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private func resultItem(_ result: EAITestResult) -> some View {
        Button {
            onTapResult?(result)
        } label: {
            VStack(alignment: .leading, spacing: EAISpacing.xs) {
                HStack(spacing: EAISpacing.sm) {
                    statusIcon(result.state)

                    Text(result.name)
                        .font(EAITypography.callout)
                        .foregroundStyle(.primary)

                    Spacer()

                    if result.durationMS > 0 {
                        Text(formatDuration(result.durationMS))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if !result.details.isEmpty {
                    Text(result.details)
                        .font(EAITypography.caption2)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = result.errorMessage {
                    VStack(alignment: .leading, spacing: EAISpacing.xs) {
                        Text(errorMessage)
                            .font(EAITypography.caption2)
                            .foregroundStyle(.red)
                        if let errorStack = result.errorStack {
                            Text(errorStack)
                                .font(.caption2)
                                .fontDesign(.monospaced)
                                .textSelection(.enabled)
                                .foregroundStyle(.red.opacity(0.9))
                                .padding(EAISpacing.xs)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding(.vertical, EAISpacing.sm)
            .padding(.horizontal, EAISpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func summaryBadge(_ count: Int, label: String, tone: Color) -> some View {
        Text("\(count) \(label)")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tone.opacity(0.15), in: Capsule())
            .foregroundStyle(tone)
    }

    @ViewBuilder
    private func statusIcon(_ state: EAITestResultState) -> some View {
        switch state {
        case .pass:
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
        case .fail:
            Image(systemName: "xmark.seal.fill")
                .foregroundStyle(.red)
        case .skipped:
            Image(systemName: "pause.fill")
                .foregroundStyle(.orange)
        case .running:
            ProgressView()
                .controlSize(.mini)
        }
    }

    private func formatDuration(_ value: Double) -> String {
        if value < 1000 {
            return "\(Int(value))ms"
        }
        return String(format: "%.2fs", value / 1000)
    }
}

private struct TestResultsProgressView: View {
    let summary: EAITestResultSummary

    private var passedPercent: Double {
        guard summary.total > 0 else { return 0 }
        return (Double(summary.passed) / Double(summary.total)) * 100
    }

    private var failedPercent: Double {
        guard summary.total > 0 else { return 0 }
        return (Double(summary.failed) / Double(summary.total)) * 100
    }

    var body: some View {
        VStack(spacing: EAISpacing.xs) {
            if summary.total > 0 {
                GeometryReader { geometry in
                    let totalWidth = geometry.size.width
                    let passedWidth = totalWidth * (passedPercent / 100)
                    let failedWidth = totalWidth * (failedPercent / 100)

                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(.green)
                            .frame(width: max(0, passedWidth), height: 6)
                        Rectangle()
                            .fill(.red)
                            .frame(width: max(0, failedWidth), height: 6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 99))
                }
                .frame(height: 6)

                Text(
                    "\(summary.passed)/\(summary.total) tests passed • \(Int(passedPercent))%"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    TestResultsView(
        summary: EAITestResultSummary(
            total: 3,
            passed: 2,
            failed: 1,
            skipped: 0,
            durationMS: 1240
        ),
        suites: [
            EAITestSuite(
                name: "Auth",
                status: .pass,
                tests: [
                    EAITestResult(name: "Should login", state: .pass, durationMS: 40),
                    EAITestResult(
                        name: "Should logout",
                        state: .fail,
                        durationMS: 18,
                        errorMessage: "Expected status 200",
                        errorStack: "at app.test.ts:45:10"
                    ),
                ],
                durationMS: 58
            )
        ]
    )
    .padding()
}
