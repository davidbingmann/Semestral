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
                if let rec = task.recurrence {
                    Label(rec.label, systemImage: "arrow.triangle.2.circlepath")
                        .labelStyle(.iconOnly)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .help("Repeats \(rec.label.lowercased())")
                }
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
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 1.5, x: 0, y: 0.5)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture { onEdit() }
        .draggable(TaskDragPayload(id: task.persistentModelID))
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
        let effective = effectiveDeadline(for: date)
        if effective < .now { return .red }
        if effective < Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? effective {
            return .orange
        }
        return .secondary
    }

    private func effectiveDeadline(for date: Date) -> Date {
        if task.deadlineHasTime { return date }
        let cal = Calendar.current
        return cal.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
    }
}
