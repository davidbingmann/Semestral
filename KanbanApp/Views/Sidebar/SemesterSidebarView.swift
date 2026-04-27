import SwiftUI
import SwiftData

struct SemesterSidebarView: View {
    @Query(sort: \Semester.startDate, order: .reverse) private var semesters: [Semester]
    @Query private var allModules: [Module]
    @Binding var selected: Module?

    var body: some View {
        List(selection: $selected) {
            ForEach(semesters) { sem in
                Section(sem.name) {
                    ForEach(sem.modules) { mod in
                        ModuleSidebarRow(module: mod).tag(mod)
                    }
                }
            }
        }
        .navigationTitle("Modules")
        .overlay {
            if semesters.isEmpty {
                ContentUnavailableView(
                    "No Semesters Yet",
                    systemImage: "calendar.badge.plus",
                    description: Text("Open Settings (⌘,) to add a semester and modules.")
                )
            }
        }
        .onChange(of: allModules) { _, modules in
            if let current = selected, !modules.contains(current) {
                selected = nil
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
