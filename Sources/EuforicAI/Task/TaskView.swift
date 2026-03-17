import SwiftUI

public struct TaskView: View {
    let title: String
    let status: EAIToolStatus
    let detail: String

    public init(title: String, status: EAIToolStatus = .pending, detail: String = "") {
        self.title = title
        self.status = status
        self.detail = detail
    }

    public var body: some View {
        TaskItemView(title: title, status: status, detail: detail)
    }
}
