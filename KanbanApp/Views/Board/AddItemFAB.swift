import SwiftUI

struct AddItemFAB: View {
    let onAddTask: () -> Void
    let onAddExam: () -> Void

    @State private var hovering = false
    @State private var pressed = false
    @State private var menuShown = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if menuShown {
                menuPanel
                    .padding(.bottom, 60)
                    .transition(
                        .scale(scale: 0.92, anchor: .bottomLeading)
                            .combined(with: .opacity)
                    )
            }

            fabButton
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.75), value: menuShown)
    }

    private var fabButton: some View {
        Button {
            menuShown.toggle()
        } label: {
            ZStack {
                Circle().fill(Color.accentColor)
                Circle().strokeBorder(.white.opacity(0.14), lineWidth: 0.5)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(menuShown ? 45 : 0))
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
        .help(menuShown ? "Close" : "Add task or exam")
    }

    private var menuPanel: some View {
        VStack(spacing: 2) {
            FABMenuItem(title: "New Task", icon: "checkmark.circle") {
                menuShown = false
                onAddTask()
            }
            FABMenuItem(title: "New Exam", icon: "graduationcap") {
                menuShown = false
                onAddExam()
            }
        }
        .padding(6)
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 6)
    }
}

private struct FABMenuItem: View {
    let title: String
    let icon: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body)
                    .frame(width: 18)
                    .foregroundStyle(hovering ? .white : .primary)
                Text(title)
                    .font(.body)
                    .foregroundStyle(hovering ? .white : .primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(hovering ? Color.accentColor : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}
