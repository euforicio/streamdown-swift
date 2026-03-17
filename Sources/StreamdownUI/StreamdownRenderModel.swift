import Observation
import Streamdown

@MainActor
@Observable
public final class StreamdownRenderModel {
    private(set) var snapshot: StreamdownRenderSnapshot = .empty

    @ObservationIgnored private let parser: StreamdownRenderActor
    @ObservationIgnored private var renderTask: Task<Void, Never>?
    @ObservationIgnored private var requestID = 0

    public init(parser: StreamdownRenderActor = StreamdownRenderActor()) {
        self.parser = parser
    }

    func render(
        content: String,
        mode: StreamdownMode,
        parseIncompleteMarkdown: Bool,
        normalizeHtmlIndentation: Bool
    ) async {
        requestID += 1
        let currentRequestID = requestID
        let previousSnapshot = snapshot

        renderTask?.cancel()
        renderTask = Task.detached(priority: .userInitiated) { [parser] in
            let nextSnapshot = await parser.renderSnapshot(
                content: content,
                mode: mode,
                parseIncompleteMarkdown: parseIncompleteMarkdown,
                normalizeHtmlIndentation: normalizeHtmlIndentation,
                previous: previousSnapshot
            )

            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard self.requestID == currentRequestID else { return }
                self.snapshot = nextSnapshot
            }
        }
    }

    func cancel() {
        renderTask?.cancel()
        renderTask = nil
    }
}
