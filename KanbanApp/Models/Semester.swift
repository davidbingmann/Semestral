import Foundation
import SwiftData

@Model
final class Semester {
    var name: String
    var startDate: Date
    var endDate: Date

    @Relationship(deleteRule: .cascade, inverse: \Module.semester)
    var modules: [Module] = []

    init(name: String, startDate: Date, endDate: Date) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
    }
}
