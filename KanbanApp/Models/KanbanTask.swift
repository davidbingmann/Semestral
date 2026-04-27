import Foundation
import SwiftData

enum KanbanStatus: String, Codable, CaseIterable, Identifiable {
    case todo, inProgress, done

    var id: String { rawValue }

    var label: String {
        switch self {
        case .todo: "To Do"
        case .inProgress: "In Progress"
        case .done: "Done"
        }
    }
}

@Model
final class KanbanTask {
    var title: String
    var notes: String
    var deadline: Date?
    var module: Module?
    var status: KanbanStatus
    var completedAt: Date?

    init(
        title: String = "",
        notes: String = "",
        deadline: Date? = nil,
        module: Module? = nil,
        status: KanbanStatus = .todo
    ) {
        self.title = title
        self.notes = notes
        self.deadline = deadline
        self.module = module
        self.status = status
        self.completedAt = status == .done ? .now : nil
    }

    func updateStatus(_ new: KanbanStatus) {
        status = new
        completedAt = (new == .done) ? .now : nil
    }

    static func deleteExpired(in context: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
        let sentinel = Date.distantFuture
        let predicate = #Predicate<KanbanTask> { task in
            (task.completedAt ?? sentinel) < cutoff
        }
        try? context.delete(model: KanbanTask.self, where: predicate)
        try? context.save()
    }
}
