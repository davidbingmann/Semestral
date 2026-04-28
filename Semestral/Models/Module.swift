import Foundation
import SwiftData

@Model
final class Module {
    var name: String
    var colorHex: String
    var semester: Semester?

    @Relationship(deleteRule: .cascade, inverse: \Exam.module)
    var exams: [Exam] = []

    @Relationship(deleteRule: .cascade, inverse: \KanbanTask.module)
    var tasks: [KanbanTask] = []

    @Relationship(deleteRule: .cascade, inverse: \Grade.module)
    var grades: [Grade] = []

    /// Legacy fields kept only so SwiftData lightweight migration accepts existing stores.
    /// `examDate` / `examDateHasTime` are drained into `exams` once by `Exam.migrateLegacyExamDates`.
    /// `isPortfolio` was briefly used as a module-level mode flag and is now unread.
    var examDate: Date?
    var examDateHasTime: Bool = true
    var isPortfolio: Bool = false

    init(name: String, colorHex: String, semester: Semester? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.semester = semester
    }

    static let palette: [String] = [
        "#4F86C6", "#5BAD72", "#D4736A", "#A67DC5",
        "#E09B3D", "#5BBCB8", "#D46A9B", "#8D9EAD"
    ]

    static let defaultColorHex = "#8D9EAD"

    static func nextColor(for semester: Semester) -> String {
        let used = semester.modules.map(\.colorHex)
        if let fresh = palette.first(where: { !used.contains($0) }) {
            return fresh
        }
        return palette.min(by: { a, b in
            used.filter { $0 == a }.count < used.filter { $0 == b }.count
        }) ?? palette[0]
    }
}
