import SwiftUI

extension EAIStreamingState {
    public var isActive: Bool { self == .streaming }
    public var isDone: Bool { self == .complete }
}
