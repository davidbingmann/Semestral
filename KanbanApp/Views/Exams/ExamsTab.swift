import SwiftUI
import SwiftData

struct ExamsTab: View {
    @Query(filter: #Predicate<Module> { $0.examDate != nil }, sort: \Module.examDate)
    private var modulesWithExams: [Module]

    @Query(sort: \Semester.startDate, order: .reverse)
    private var semesters: [Semester]

    @AppStorage("selectedSemesterID") private var selectedSemesterIDString: String = ""

    @State private var creatingExam = false

    var body: some View {
        let now = Date.now
        let (upcoming, past) = partition(now: now)

        return Group {
            if modulesWithExams.isEmpty {
                ContentUnavailableView(
                    "No Exam Dates",
                    systemImage: "graduationcap",
                    description: Text(
                        activeSemester == nil
                        ? "Add a semester first, then tap + to add an exam."
                        : "Tap + to add an exam."
                    )
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        if !upcoming.isEmpty {
                            section(title: "Upcoming", modules: upcoming, isPast: false)
                        }
                        if !past.isEmpty {
                            section(title: "Past", modules: past, isPast: true)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 80)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomLeading) {
            if activeSemester != nil {
                PlusFAB { creatingExam = true }
                    .padding(20)
            }
        }
        .sheet(isPresented: $creatingExam) {
            if let s = activeSemester {
                ExamFormView(semester: s)
            }
        }
    }

    private func section(title: String, modules: [Module], isPast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 6) {
                ForEach(modules) { ExamRow(module: $0, isPast: isPast) }
            }
        }
    }

    private var activeSemester: Semester? {
        guard !selectedSemesterIDString.isEmpty,
              let data = selectedSemesterIDString.data(using: .utf8),
              let id = try? JSONDecoder().decode(PersistentIdentifier.self, from: data),
              let match = semesters.first(where: { $0.persistentModelID == id }) else {
            return semesters.first
        }
        return match
    }

    private func partition(now: Date) -> (upcoming: [Module], past: [Module]) {
        var upcoming: [Module] = []
        var past: [Module] = []
        for m in modulesWithExams {
            guard m.examDate != nil else { continue }
            if effectiveDate(for: m) >= now { upcoming.append(m) } else { past.append(m) }
        }
        return (upcoming, Array(past.reversed()))
    }

    private func effectiveDate(for module: Module) -> Date {
        guard let d = module.examDate else { return .distantFuture }
        if module.examDateHasTime { return d }
        let cal = Calendar.current
        return cal.date(bySettingHour: 23, minute: 59, second: 59, of: d) ?? d
    }
}

private struct ExamRow: View {
    let module: Module
    let isPast: Bool

    private let cal = Calendar.current

    var body: some View {
        HStack(spacing: 12) {
            ModuleSwatch(colorHex: module.colorHex, size: 10)

            VStack(alignment: .leading, spacing: 1) {
                Text(module.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isPast ? .secondary : .primary)
                if let d = module.examDate {
                    Text(formattedDate(d, hasTime: module.examDateHasTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            if let d = module.examDate, !isPast {
                Text(d, style: .relative)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(urgencyColor(for: d))
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.background.secondary)
        )
    }

    private func formattedDate(_ d: Date, hasTime: Bool) -> String {
        if hasTime {
            return d.formatted(.dateTime
                .weekday(.abbreviated)
                .day()
                .month(.abbreviated)
                .year()
                .hour().minute()
            )
        }
        return d.formatted(.dateTime
            .weekday(.abbreviated)
            .day()
            .month(.abbreviated)
            .year()
        )
    }

    private func urgencyColor(for date: Date) -> Color {
        let now = Date.now
        guard let oneWeek = cal.date(byAdding: .day, value: 7, to: now),
              let twoWeeks = cal.date(byAdding: .day, value: 14, to: now) else {
            return .secondary
        }
        if date < oneWeek { return .red }
        if date < twoWeeks { return .yellow }
        return .secondary
    }
}
