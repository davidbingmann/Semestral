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
        let all: [KanbanTask] = switch self {
        case .semester(let s): s.modules.flatMap(\.tasks)
        case .module(let m):   m.tasks
        }
        return all.filter(\.isVisible)
    }
}

struct KanbanBoardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Semester.startDate, order: .reverse) private var semesters: [Semester]
    @Query private var allModules: [Module]

    @AppStorage("selectedSemesterID") private var selectedSemesterIDString: String = ""
    @State private var selectedSemester: Semester?
    @State private var selected: BoardSelection?
    @State private var creatingTask = false
    @State private var creatingSemester = false
    @State private var creatingExam = false
    @State private var editingTask: KanbanTask?

    var body: some View {
        NavigationSplitView {
            SemesterSidebarView(semester: selectedSemester, selected: $selected)
                .frame(minWidth: 220)
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottomLeading) {
                    if selectedSemester != nil {
                        AddItemFAB(
                            onAddTask: { creatingTask = true },
                            onAddExam: { creatingExam = true }
                        )
                        .padding(20)
                    }
                }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                semesterMenu
            }
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
                semester: selected?.semester ?? selectedSemester,
                defaultModule: selected?.defaultModule,
                existing: nil
            )
        }
        .sheet(item: $editingTask) { t in
            TaskFormView(
                semester: t.module?.semester ?? selected?.semester ?? selectedSemester,
                defaultModule: t.module ?? selected?.defaultModule,
                existing: t
            )
        }
        .sheet(isPresented: $creatingSemester) {
            SemesterFormView(existing: nil)
        }
        .sheet(isPresented: $creatingExam) {
            if let sem = selectedSemester {
                ExamFormView(semester: sem)
            }
        }
        .task {
            if selectedSemester == nil { resolveSelectedSemester() }
        }
        .onChange(of: semesters) { old, new in
            if selectedSemester == nil {
                resolveSelectedSemester()
                return
            }
            if let added = new.first(where: { !old.contains($0) }) {
                selectedSemester = added
            } else if let current = selectedSemester, !new.contains(current) {
                resolveSelectedSemester()
            }
        }
        .onChange(of: selectedSemester) { _, new in
            persistSelectedSemester(new)
            selected = new.map { .semester($0) }
        }
        .onChange(of: allModules) { _, _ in cleanupBoardSelection() }
    }

    private var semesterMenu: some View {
        Menu {
            if !semesters.isEmpty {
                Picker(selection: $selectedSemester) {
                    ForEach(semesters) { sem in
                        Text(sem.name).tag(sem as Semester?)
                    }
                } label: {
                    Text("Semester")
                }
                .pickerStyle(.inline)

                Divider()
            }

            Button {
                creatingSemester = true
            } label: {
                Label("New Semester…", systemImage: "plus")
            }
        } label: {
            Text(selectedSemester?.name ?? "No Semester")
                .font(.headline)
        }
        .menuIndicator(.visible)
        .fixedSize()
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
            TimelineView(.everyMinute) { _ in
                BoardColumns(
                    title: scope.title,
                    tasks: scope.tasks,
                    onEdit: { editingTask = $0 },
                    onDelete: delete(task:),
                    onMove: move(task:to:)
                )
            }
        case .none:
            ContentUnavailableView(
                selectedSemester == nil ? "No Semester" : "Select a Module",
                systemImage: "rectangle.split.3x1",
                description: Text(
                    selectedSemester == nil
                    ? "Use the menu in the toolbar to create a semester."
                    : "Pick from the sidebar to see its board."
                )
            )
        }
    }

    private func resolveSelectedSemester() {
        if let current = selectedSemester, semesters.contains(current) { return }
        if let stored = decodeSemesterID(),
           let match = semesters.first(where: { $0.persistentModelID == stored }) {
            selectedSemester = match
        } else {
            selectedSemester = semesters.first
        }
    }

    private func persistSelectedSemester(_ sem: Semester?) {
        guard let sem,
              let data = try? JSONEncoder().encode(sem.persistentModelID),
              let str = String(data: data, encoding: .utf8) else {
            selectedSemesterIDString = ""
            return
        }
        selectedSemesterIDString = str
    }

    private func decodeSemesterID() -> PersistentIdentifier? {
        guard !selectedSemesterIDString.isEmpty,
              let data = selectedSemesterIDString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PersistentIdentifier.self, from: data)
    }

    private func cleanupBoardSelection() {
        if case .module(let m) = selected, !allModules.contains(m) {
            selected = selectedSemester.map { .semester($0) }
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
        HStack(alignment: .top, spacing: 16) {
            ForEach(KanbanStatus.allCases) { status in
                KanbanColumnView(
                    status: status,
                    tasks: filteredTasks(for: status),
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onMove: onMove,
                    onDrop: { payloads in handleDrop(payloads, to: status) }
                )
            }
        }
        .padding(16)
        .navigationTitle(title)
    }

    private func handleDrop(_ payloads: [TaskDragPayload], to status: KanbanStatus) {
        for payload in payloads {
            if let task = tasks.first(where: { $0.persistentModelID == payload.id }),
               task.status != status {
                onMove(task, status)
            }
        }
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
