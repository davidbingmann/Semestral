import SwiftUI

struct KanbanColumnView: View {
    let status: KanbanStatus
    let tasks: [KanbanTask]
    let onEdit: (KanbanTask) -> Void
    let onDelete: (KanbanTask) -> Void
    let onMove: (KanbanTask, KanbanStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(status.label)
                    .font(.headline)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 4)

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
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}
