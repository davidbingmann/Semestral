import Foundation
import SwiftData

@Model
final class Module {
    var name: String
    var colorHex: String
    var examDate: Date?
    var semester: Semester?

    @Relationship(deleteRule: .cascade, inverse: \KanbanTask.module)
    var tasks: [KanbanTask] = []

    init(name: String, colorHex: String, examDate: Date? = nil, semester: Semester? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.examDate = examDate
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
