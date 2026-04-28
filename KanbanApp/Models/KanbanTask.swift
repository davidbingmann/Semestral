import Foundation
import SwiftData
import SwiftUI

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

    var color: Color {
        switch self {
        case .todo: .red
        case .inProgress: .yellow
        case .done: .green
        }
    }
}

enum KanbanRecurrence: String, Codable, CaseIterable, Identifiable {
    case daily, weekly, monthly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        }
    }

    func advance(_ date: Date) -> Date {
        let cal = Calendar.current
        switch self {
        case .daily:   return cal.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:  return cal.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly: return cal.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
}

@Model
final class KanbanTask {
    var title: String
    var notes: String
    var deadline: Date?
    var deadlineHasTime: Bool = true
    var module: Module?
    var status: KanbanStatus
    var completedAt: Date?
    var recurrence: KanbanRecurrence?
    var hiddenUntil: Date?

    init(
        title: String = "",
        notes: String = "",
        deadline: Date? = nil,
        deadlineHasTime: Bool = true,
        module: Module? = nil,
        status: KanbanStatus = .todo,
        recurrence: KanbanRecurrence? = nil
    ) {
        self.title = title
        self.notes = notes
        self.deadline = deadline
        self.deadlineHasTime = deadlineHasTime
        self.module = module
        self.status = status
        self.completedAt = status == .done ? .now : nil
        self.recurrence = recurrence
        self.hiddenUntil = nil
    }

    var isVisible: Bool {
        guard let hidden = hiddenUntil else { return true }
        return hidden <= .now
    }

    func updateStatus(_ new: KanbanStatus) {
        if new == .done, let rec = recurrence {
            rollover(using: rec)
            return
        }
        status = new
        completedAt = (new == .done) ? .now : nil
        if new != .done { hiddenUntil = nil }
    }

    private func rollover(using rec: KanbanRecurrence) {
        let cal = Calendar.current
        let now = Date.now
        if let dl = deadline {
            deadline = rec.advance(dl)
        }
        let nextDay = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now) ?? now)
        if let dl = deadline {
            let preWindow = cal.date(byAdding: .day, value: -14, to: dl) ?? dl
            hiddenUntil = max(nextDay, preWindow)
        } else {
            hiddenUntil = max(nextDay, cal.startOfDay(for: rec.advance(now)))
        }
        status = .todo
        completedAt = nil
    }

    static func deleteExpired(in context: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
        let sentinel = Date.distantFuture
        let predicate = #Predicate<KanbanTask> { task in
            (task.completedAt ?? sentinel) < cutoff
        }
        let descriptor = FetchDescriptor<KanbanTask>(predicate: predicate)
        let expired = (try? context.fetch(descriptor)) ?? []
        for task in expired where task.recurrence == nil {
            context.delete(task)
        }
        try? context.save()
    }
}
