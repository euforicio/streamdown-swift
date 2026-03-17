import SwiftUI

public struct EAISeparator: View {
    let orientation: Axis

    public init(_ orientation: Axis = .horizontal) {
        self.orientation = orientation
    }

    public var body: some View {
        switch orientation {
        case .horizontal:
            Rectangle()
                .fill(EAIColors.border)
                .frame(height: 1)
        case .vertical:
            Rectangle()
                .fill(EAIColors.border)
                .frame(width: 1)
        }
    }
}
