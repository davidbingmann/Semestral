import Foundation
import SwiftData

enum DegreeType: String, Codable, CaseIterable, Identifiable {
    case bachelor, master

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bachelor: "Bachelor"
        case .master:   "Master"
        }
    }

    var ectsTarget: Double {
        switch self {
        case .bachelor: 180
        case .master:   120
        }
    }
}

@Model
final class Semester {
    var name: String
    var startDate: Date
    var endDate: Date
    var degree: DegreeType?

    @Relationship(deleteRule: .cascade, inverse: \Module.semester)
    var modules: [Module] = []

    init(
        name: String,
        startDate: Date,
        endDate: Date,
        degree: DegreeType = .bachelor
    ) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.degree = degree
    }
}
