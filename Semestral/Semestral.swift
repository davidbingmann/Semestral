import SwiftUI
import SwiftData

@main
struct SemestralApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Semester.self, Module.self, KanbanTask.self, Grade.self, Exam.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
