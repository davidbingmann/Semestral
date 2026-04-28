import SwiftUI
import SwiftData

struct SemesterSidebarView: View {
    let semester: Semester?
    @Binding var selected: BoardSelection?

    var body: some View {
        List(selection: $selected) {
            if let sem = semester {
                Label("All Modules", systemImage: "square.stack")
                    .tag(BoardSelection.semester(sem))

                ForEach(sem.modules) { mod in
                    ModuleSidebarRow(module: mod)
                        .tag(BoardSelection.module(mod))
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
