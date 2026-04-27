import SwiftUI
import SwiftData

struct KanbanBoardView: View {
    @Environment(\.modelContext) private var context

    @State private var selected: Module?
    @State private var creatingTask = false
    @State private var editingTask: KanbanTask?

    var body: some View {
        NavigationSplitView {
            SemesterSidebarView(selected: $selected)
                .frame(minWidth: 220)
        } detail: {
            detail
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    creatingTask = true
                } label: {
                    Label("Add Task", systemImage: "plus")
                }
                .disabled(selected == nil)
            }
        }
        .sheet(isPresented: $creatingTask) {
            TaskFormView(
                semester: selected?.semester,
                defaultModule: selected,
                existing: nil
            )
        }
        .sheet(item: $editingTask) { t in
            TaskFormView(
                semester: t.module?.semester ?? selected?.semester,
                defaultModule: t.module ?? selected,
                existing: t
            )
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let module = selected {
            BoardColumns(
                module: module,
                onEdit: { editingTask = $0 },
                onDelete: delete(task:),
                onMove: move(task:to:)
            )
        } else {
            ContentUnavailableView(
                "Select a Module",
                systemImage: "rectangle.split.3x1",
                description: Text("Pick a module from the sidebar to see its board.")
            )
        }
    }

    private func delete(task: KanbanTask) {
        context.delete(task)
        try? context.save()
    }

    private func move(task: KanbanTask, to status: KanbanStatus) {
        task.updateStatus(status)
        try? context.save()
    }
}

private struct BoardColumns: View {
    let module: Module
    let onEdit: (KanbanTask) -> Void
    let onDelete: (KanbanTask) -> Void
    let onMove: (KanbanTask, KanbanStatus) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(KanbanStatus.allCases) { status in
                KanbanColumnView(
                    status: status,
                    tasks: tasks(for: status),
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onMove: onMove
                )
            }
        }
        .padding(12)
        .navigationTitle(module.name)
    }

    private func tasks(for status: KanbanStatus) -> [KanbanTask] {
        module.tasks
            .filter { $0.status == status }
            .sorted { lhs, rhs in
                switch (lhs.deadline, rhs.deadline) {
                case let (l?, r?): return l < r
                case (_?, nil):    return true
                case (nil, _?):    return false
                case (nil, nil):   return lhs.title < rhs.title
                }
            }
    }
}
