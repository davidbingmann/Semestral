import SwiftUI
import SwiftData

enum BoardSelection: Hashable {
    case semester(Semester)
    case module(Module)

    var semester: Semester? {
        switch self {
        case .semester(let s): s
        case .module(let m):   m.semester
        }
    }

    var defaultModule: Module? {
        switch self {
        case .semester(let s): s.modules.first
        case .module(let m):   m
        }
    }

    var title: String {
        switch self {
        case .semester(let s): s.name
        case .module(let m):   m.name
        }
    }

    var tasks: [KanbanTask] {
        switch self {
        case .semester(let s): s.modules.flatMap(\.tasks)
        case .module(let m):   m.tasks
        }
    }
}

struct KanbanBoardView: View {
    @Environment(\.modelContext) private var context

    @State private var selected: BoardSelection?
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
                .disabled(selected?.defaultModule == nil)
            }
        }
        .sheet(isPresented: $creatingTask) {
            TaskFormView(
                semester: selected?.semester,
                defaultModule: selected?.defaultModule,
                existing: nil
            )
        }
        .sheet(item: $editingTask) { t in
            TaskFormView(
                semester: t.module?.semester ?? selected?.semester,
                defaultModule: t.module ?? selected?.defaultModule,
                existing: t
            )
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selected {
        case .semester(let s) where s.modules.isEmpty:
            ContentUnavailableView(
                "No Modules in This Semester",
                systemImage: "rectangle.3.group",
                description: Text("Add a module in the Modules tab to start creating tasks.")
            )
        case .some(let scope):
            BoardColumns(
                title: scope.title,
                tasks: scope.tasks,
                onEdit: { editingTask = $0 },
                onDelete: delete(task:),
                onMove: move(task:to:)
            )
        case .none:
            ContentUnavailableView(
                "Select a Semester or Module",
                systemImage: "rectangle.split.3x1",
                description: Text("Pick from the sidebar to see its board.")
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
    let title: String
    let tasks: [KanbanTask]
    let onEdit: (KanbanTask) -> Void
    let onDelete: (KanbanTask) -> Void
    let onMove: (KanbanTask, KanbanStatus) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(KanbanStatus.allCases) { status in
                KanbanColumnView(
                    status: status,
                    tasks: filteredTasks(for: status),
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onMove: onMove
                )
            }
        }
        .padding(12)
        .navigationTitle(title)
    }

    private func filteredTasks(for status: KanbanStatus) -> [KanbanTask] {
        tasks
            .filter { $0.status == status }
            .sorted { lhs, rhs in
                switch (lhs.deadline, rhs.deadline) {
                case let (l?, r?): l < r
                case (_?, nil):    true
                case (nil, _?):    false
                case (nil, nil):   lhs.title < rhs.title
                }
            }
    }
}
