import SwiftUI
import SwiftData

struct ExamsTab: View {
    @Query(filter: #Predicate<Module> { $0.examDate != nil }, sort: \Module.examDate)
    private var modulesWithExams: [Module]

    var body: some View {
        let now = Date.now
        let (upcoming, past) = partition(now: now)

        return Group {
            if modulesWithExams.isEmpty {
                ContentUnavailableView(
                    "No Exam Dates",
                    systemImage: "graduationcap",
                    description: Text("Add an exam date to a module in Settings (⌘,).")
                )
            } else {
                List {
                    if !upcoming.isEmpty {
                        Section("Upcoming") {
                            ForEach(upcoming) { ExamRow(module: $0) }
                        }
                    }
                    if !past.isEmpty {
                        Section("Past") {
                            ForEach(past) { ExamRow(module: $0) }
                        }
                    }
                }
            }
        }
    }

    private func partition(now: Date) -> (upcoming: [Module], past: [Module]) {
        var upcoming: [Module] = []
        var past: [Module] = []
        for m in modulesWithExams {
            guard let d = m.examDate else { continue }
            if d >= now { upcoming.append(m) } else { past.append(m) }
        }
        return (upcoming, Array(past.reversed()))
    }
}

private struct ExamRow: View {
    let module: Module

    var body: some View {
        HStack(spacing: 12) {
            ModuleSwatch(colorHex: module.colorHex, size: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(module.name).font(.body)
                if let d = module.examDate {
                    Text(d.formatted(date: .complete, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let d = module.examDate {
                Text(d, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }
}
