import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context

    private let cleanupTimer = Timer.publish(every: 3600, on: .main, in: .common).autoconnect()

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
            Exam.migrateLegacyExamDates(in: context)
            runCleanup()
        }
        .onReceive(cleanupTimer) { _ in runCleanup() }
    }

    private func runCleanup() {
        KanbanTask.deleteExpired(in: context)
        Exam.deleteExpired(in: context)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Semester.self, Module.self, KanbanTask.self, Grade.self, Exam.self], inMemory: true)
}
