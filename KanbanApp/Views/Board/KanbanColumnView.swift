import SwiftUI

struct KanbanColumnView: View {
    let status: KanbanStatus
    let tasks: [KanbanTask]
    let onEdit: (KanbanTask) -> Void
    let onDelete: (KanbanTask) -> Void
    let onMove: (KanbanTask, KanbanStatus) -> Void
    let onDrop: ([TaskDragPayload]) -> Void

    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(status.label)
                    .font(.headline)
                Text("\(tasks.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.15), in: Capsule())
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(tasks) { task in
                        TaskCardView(
                            task: task,
                            onEdit: { onEdit(task) },
                            onDelete: { onDelete(task) },
                            onMove: { onMove(task, $0) }
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
            .scrollIndicators(.hidden)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background.secondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: isTargeted ? 2 : 0)
        )
        .dropDestination(for: TaskDragPayload.self) { payloads, _ in
            onDrop(payloads)
            return !payloads.isEmpty
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }
}
