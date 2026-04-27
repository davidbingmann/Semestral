import SwiftUI

struct TaskCardView: View {
    let task: KanbanTask
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMove: (KanbanStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let m = task.module {
                    ModuleSwatch(colorHex: m.colorHex, size: 8)
                    Text(m.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }

            Text(task.title.isEmpty ? "Untitled" : task.title)
                .font(.body)
                .foregroundStyle(task.title.isEmpty ? .secondary : .primary)

            if let d = task.deadline {
                Text(d, style: .relative)
                    .font(.caption)
                    .foregroundStyle(deadlineColor(for: d))
                    .monospacedDigit()
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
        .contextMenu {
            Button("Edit…") { onEdit() }
            Menu("Move to") {
                ForEach(KanbanStatus.allCases) { s in
                    Button(s.label) { onMove(s) }
                        .disabled(s == task.status)
                }
            }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }

    private func deadlineColor(for date: Date) -> Color {
        if task.status == .done { return .secondary }
        if date < .now { return .red }
        if date < Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? date {
            return .orange
        }
        return .secondary
    }
}
