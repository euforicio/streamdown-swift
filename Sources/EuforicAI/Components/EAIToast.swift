import SwiftUI

public struct EAIToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String

    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                Group {
                    if isPresented {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, EAISpacing.md)
                            .padding(.vertical, EAISpacing.sm)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.bottom, EAISpacing.lg)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .onAppear {
                                Task {
                                    try? await Task.sleep(for: .seconds(2))
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        isPresented = false
                                    }
                                }
                            }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isPresented)
            }
    }
}

extension View {
    public func saiToast(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(EAIToastModifier(isPresented: isPresented, message: message))
    }
}
