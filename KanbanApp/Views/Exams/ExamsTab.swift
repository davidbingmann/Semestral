import SwiftUI
import SwiftData

struct ExamsTab: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Exam.date) private var exams: [Exam]

    @Query(sort: \Semester.startDate, order: .reverse)
    private var semesters: [Semester]

    @AppStorage("selectedSemesterID") private var selectedSemesterIDString: String = ""

    @State private var creatingExam = false
    @State private var editingExam: Exam?

    var body: some View {
        TimelineView(.everyMinute) { context in
            let (upcoming, past) = partition(now: context.date)

            Group {
                if exams.isEmpty {
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
                                section(title: "Upcoming", exams: upcoming, isPast: false)
                            }
                            if !past.isEmpty {
                                section(title: "Past", exams: past, isPast: true)
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
        }
        .sheet(isPresented: $creatingExam) {
            if let s = activeSemester {
                ExamFormView(semester: s)
            }
        }
        .sheet(item: $editingExam) { exam in
            if let s = exam.module?.semester ?? activeSemester {
                ExamFormView(semester: s, existing: exam)
            }
        }
    }

    private func section(title: String, exams: [Exam], isPast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 6) {
                ForEach(exams) { exam in
                    ExamRow(exam: exam, isPast: isPast)
                        .contentShape(Rectangle())
                        .onTapGesture { editingExam = exam }
                        .contextMenu {
                            Button("Edit") { editingExam = exam }
                            Button("Delete", role: .destructive) {
                                context.delete(exam)
                                try? context.save()
                            }
                        }
                }
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

    private func partition(now: Date) -> (upcoming: [Exam], past: [Exam]) {
        var upcoming: [Exam] = []
        var past: [Exam] = []
        for e in exams {
            if e.effectiveDate >= now { upcoming.append(e) } else { past.append(e) }
        }
        return (upcoming, Array(past.reversed()))
    }
}

private struct ExamRow: View {
    let exam: Exam
    let isPast: Bool

    private let cal = Calendar.current

    var body: some View {
        HStack(spacing: 12) {
            ModuleSwatch(colorHex: exam.module?.colorHex, size: 10)

            VStack(alignment: .leading, spacing: 1) {
                Text(exam.module?.name ?? "—")
                    .font(.body.weight(.medium))
                    .foregroundStyle(isPast ? .secondary : .primary)
                Text(formattedDate(exam.date, hasTime: exam.hasTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if !isPast {
                Text(exam.date, style: .relative)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(urgencyColor(for: exam.date))
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
