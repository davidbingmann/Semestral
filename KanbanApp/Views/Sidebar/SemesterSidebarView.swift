import SwiftUI
import SwiftData

struct SemesterSidebarView: View {
    @Environment(\.modelContext) private var context

    let semester: Semester?
    @Binding var selected: BoardSelection?

    @State private var editingModule: Module?
    @State private var deletingModule: Module?

    var body: some View {
        List(selection: $selected) {
            if let sem = semester {
                Label("All Modules", systemImage: "square.stack")
                    .tag(BoardSelection.semester(sem))

                ForEach(sem.modules) { mod in
                    ModuleSidebarRow(module: mod)
                        .tag(BoardSelection.module(mod))
                        .contextMenu {
                            Button("Edit…") { editingModule = mod }
                            Divider()
                            Button("Delete", role: .destructive) {
                                deletingModule = mod
                            }
                        }
                }
            }
        }
        .navigationTitle(semester?.name ?? "Boards")
        .overlay {
            if semester == nil {
                ContentUnavailableView(
                    "No Semester",
                    systemImage: "calendar.badge.plus",
                    description: Text("Use the menu in the toolbar to add one.")
                )
            }
        }
        .sheet(item: $editingModule) { mod in
            if let sem = mod.semester ?? semester {
                ModuleFormView(semester: sem, existing: mod)
            }
        }
        .confirmationDialog(
            deletingModule.map { "Delete “\($0.name)”?" } ?? "Delete module?",
            isPresented: deleteBinding,
            titleVisibility: .visible,
            presenting: deletingModule
        ) { mod in
            Button("Delete Module", role: .destructive) {
                delete(mod)
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("All tasks and grades for this module will be removed too.")
        }
    }

    private var deleteBinding: Binding<Bool> {
        Binding(
            get: { deletingModule != nil },
            set: { if !$0 { deletingModule = nil } }
        )
    }

    private func delete(_ module: Module) {
        if case .module(let current) = selected, current == module {
            selected = semester.map { .semester($0) }
        }
        context.delete(module)
        try? context.save()
        deletingModule = nil
    }
}

private struct ModuleSidebarRow: View {
    let module: Module

    var body: some View {
        HStack(spacing: 8) {
            ModuleSwatch(colorHex: module.colorHex, size: 10)
            Text(module.name)
        }
    }
}
