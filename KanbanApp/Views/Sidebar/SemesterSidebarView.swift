import SwiftUI
import SwiftData

struct SemesterSidebarView: View {
    @Query(sort: \Semester.startDate, order: .reverse) private var semesters: [Semester]
    @Query private var allModules: [Module]
    @Binding var selected: BoardSelection?

    var body: some View {
        List(selection: $selected) {
            ForEach(semesters) { sem in
                Section(sem.name) {
                    Label("All Modules", systemImage: "square.stack")
                        .tag(BoardSelection.semester(sem))

                    ForEach(sem.modules) { mod in
                        ModuleSidebarRow(module: mod)
                            .tag(BoardSelection.module(mod))
                    }
                }
            }
        }
        .navigationTitle("Boards")
        .overlay {
            if semesters.isEmpty {
                ContentUnavailableView(
                    "No Semesters Yet",
                    systemImage: "calendar.badge.plus",
                    description: Text("Open the Modules tab to add a semester and modules.")
                )
            }
        }
        .onChange(of: allModules) { _, _ in cleanupSelection() }
        .onChange(of: semesters) { _, _ in cleanupSelection() }
    }

    private func cleanupSelection() {
        switch selected {
        case .module(let m):
            if !allModules.contains(m) { selected = nil }
        case .semester(let s):
            if !semesters.contains(s) { selected = nil }
        case nil:
            break
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
