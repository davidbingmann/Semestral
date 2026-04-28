import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            KanbanBoardView()
                .tabItem { Label("Board", systemImage: "rectangle.split.3x1") }

            CalendarTab()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            ExamsTab()
                .tabItem { Label("Exams", systemImage: "graduationcap") }

            GradesTab()
                .tabItem { Label("Grades", systemImage: "chart.bar.fill") }
        }
        .frame(minWidth: 960, minHeight: 640)
        .task {
            KanbanTask.deleteExpired(in: context)
            Module.expireOldExams(in: context)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Semester.self, Module.self, KanbanTask.self, Grade.self], inMemory: true)
}
