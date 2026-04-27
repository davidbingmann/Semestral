import SwiftUI
import SwiftData

struct ManageView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Semester.startDate, order: .reverse) private var semesters: [Semester]

    @State private var selected: Semester?
    @State private var editingSemester: Semester?
    @State private var creatingSemester = false
    @State private var editingModule: Module?
    @State private var creatingModule = false

    var body: some View {
        NavigationSplitView {
            semesterSidebar
        } detail: {
            moduleDetail
        }
        .frame(minWidth: 760, minHeight: 480)
        .sheet(isPresented: $creatingSemester) {
            SemesterFormView(existing: nil)
        }
        .sheet(item: $editingSemester) { s in
            SemesterFormView(existing: s)
        }
        .sheet(isPresented: $creatingModule) {
            if let s = selected {
                ModuleFormView(semester: s, existing: nil)
            }
        }
        .sheet(item: $editingModule) { m in
            if let s = selected {
                ModuleFormView(semester: s, existing: m)
            }
        }
        .task {
            if selected == nil { selected = semesters.first }
        }
    }

    private var semesterSidebar: some View {
        List(selection: $selected) {
            ForEach(semesters) { s in
                SemesterRow(semester: s)
                    .tag(s)
                    .contextMenu {
                        Button("Edit…") { editingSemester = s }
                        Button("Delete", role: .destructive) { delete(semester: s) }
                    }
            }
        }
        .navigationTitle("Semesters")
        .toolbar {
            ToolbarItem {
                Button {
                    creatingSemester = true
                } label: {
                    Label("Add Semester", systemImage: "plus")
                }
            }
        }
    }

    @ViewBuilder
    private var moduleDetail: some View {
        if let semester = selected {
            ModuleListView(
                semester: semester,
                onAdd: { creatingModule = true },
                onEdit: { editingModule = $0 },
                onDelete: delete(module:)
            )
        } else {
            ContentUnavailableView(
                "No Semester Selected",
                systemImage: "calendar",
                description: Text("Pick a semester from the sidebar, or add a new one.")
            )
        }
    }

    private func delete(semester: Semester) {
        if selected == semester { selected = nil }
        context.delete(semester)
        try? context.save()
    }

    private func delete(module: Module) {
        context.delete(module)
        try? context.save()
    }
}

private struct SemesterRow: View {
    let semester: Semester

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(semester.name).font(.headline)
            Text("\(semester.startDate.formatted(date: .abbreviated, time: .omitted)) – \(semester.endDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct ModuleListView: View {
    let semester: Semester
    let onAdd: () -> Void
    let onEdit: (Module) -> Void
    let onDelete: (Module) -> Void

    var body: some View {
        Group {
            if semester.modules.isEmpty {
                ContentUnavailableView(
                    "No Modules Yet",
                    systemImage: "rectangle.3.group",
                    description: Text("Add your first module to start planning tasks.")
                )
            } else {
                List {
                    ForEach(semester.modules) { m in
                        ModuleRow(module: m)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) { onEdit(m) }
                            .contextMenu {
                                Button("Edit…") { onEdit(m) }
                                Button("Delete", role: .destructive) { onDelete(m) }
                            }
                    }
                }
            }
        }
        .navigationTitle(semester.name)
        .toolbar {
            ToolbarItem {
                Button(action: onAdd) {
                    Label("Add Module", systemImage: "plus")
                }
            }
        }
    }
}

private struct ModuleRow: View {
    let module: Module

    var body: some View {
        HStack(spacing: 12) {
            ModuleSwatch(colorHex: module.colorHex, size: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(module.name).font(.body)
                if let d = module.examDate {
                    Text("Exam: \(d.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
