import Foundation
import SwiftData

@Model
final class Exam {
    var date: Date
    var hasTime: Bool = true
    var module: Module?

    init(date: Date, hasTime: Bool = true, module: Module? = nil) {
        self.date = date
        self.hasTime = hasTime
        self.module = module
    }

    /// Treat date-only exams as expiring at 23:59:59 of that day.
    var effectiveDate: Date {
        if hasTime { return date }
        let cal = Calendar.current
        return cal.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
    }

    /// Delete exams whose effective end is more than a day in the past.
    static func deleteExpired(in context: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        let predicate = #Predicate<Exam> { exam in
            exam.date < cutoff
        }
        do {
            let stale = try context.fetch(FetchDescriptor<Exam>(predicate: predicate))
            var didDelete = false
            for e in stale where e.effectiveDate < cutoff {
                context.delete(e)
                didDelete = true
            }
            if didDelete { try context.save() }
        } catch {
            // best-effort cleanup; surface nothing
        }
    }

    /// One-shot migration: copy legacy `Module.examDate` into Exam rows for any module
    /// that has a legacy date but no Exam entries yet, then null the legacy field.
    static func migrateLegacyExamDates(in context: ModelContext) {
        do {
            let modules = try context.fetch(FetchDescriptor<Module>())
            var didChange = false
            for m in modules {
                guard let legacy = m.examDate, m.exams.isEmpty else { continue }
                let exam = Exam(date: legacy, hasTime: m.examDateHasTime, module: m)
                context.insert(exam)
                m.examDate = nil
                didChange = true
            }
            if didChange { try context.save() }
        } catch {
            // best-effort migration; surface nothing
        }
    }
}
