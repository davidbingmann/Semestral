import SwiftUI

struct PlusFAB: View {
    let action: () -> Void

    @State private var hovering = false
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.accentColor)
                Circle().strokeBorder(.white.opacity(0.14), lineWidth: 0.5)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)
            .shadow(
                color: .black.opacity(hovering ? 0.32 : 0.20),
                radius: hovering ? 12 : 8,
                x: 0,
                y: hovering ? 6 : 3
            )
            .scaleEffect(pressed ? 0.92 : (hovering ? 1.06 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
        .animation(.spring(response: 0.32, dampingFraction: 0.7), value: hovering)
        .animation(.spring(response: 0.22, dampingFraction: 0.65), value: pressed)
    }
}
