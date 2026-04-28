import Foundation
import SwiftData

@Model
final class Grade {
    var value: Double
    var weight: Double
    var dateAdded: Date
    var notes: String?
    var module: Module?

    init(
        value: Double,
        weight: Double = 5.0,
        dateAdded: Date = .now,
        notes: String? = nil,
        module: Module? = nil
    ) {
        self.value = value
        self.weight = weight
        self.dateAdded = dateAdded
        self.notes = notes
        self.module = module
    }

    /// German university grade scale, including the +0.3 / -0.3 steps.
    static let scale: [Double] = [
        1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0
    ]

    /// "1,3" — German number formatting, one decimal.
    static func formatted(_ value: Double) -> String {
        let f = NumberFormatter()
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        f.locale = Locale(identifier: "de_DE")
        return f.string(from: value as NSNumber) ?? String(format: "%.1f", value)
    }

    /// Weighted average — `Σ(value · weight) / Σ(weight)`. Returns nil if no grades.
    static func weightedAverage<S: Sequence>(_ grades: S) -> Double? where S.Element == Grade {
        var totalWeight = 0.0
        var totalScore = 0.0
        for g in grades {
            let w = max(g.weight, 0)
            totalWeight += w
            totalScore += g.value * w
        }
        guard totalWeight > 0 else { return nil }
        return totalScore / totalWeight
    }
}
