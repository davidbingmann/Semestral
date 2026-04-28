import SwiftUI
import SwiftData

struct CalendarTab: View {
    @Query(sort: \KanbanTask.deadline) private var tasks: [KanbanTask]
    @Query(filter: #Predicate<Module> { $0.examDate != nil }, sort: \Module.examDate)
    private var modulesWithExams: [Module]
    @State private var currentMonth: Date = Calendar.current.startOfMonth(for: .now)

    private let cal = Calendar.current

    var body: some View {
        let tasksByDay = Dictionary(grouping: tasks) { task -> Date in
            cal.startOfDay(for: task.deadline ?? .distantPast)
        }
        let examsByDay = Dictionary(grouping: modulesWithExams) { module -> Date in
            cal.startOfDay(for: module.examDate ?? .distantPast)
        }
        return VStack(spacing: 12) {
            header
            weekdayHeader
            grid(tasksByDay: tasksByDay, examsByDay: examsByDay)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack {
            Button { shift(by: -1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(currentMonth.formatted(.dateTime.year().month(.wide)))
                .font(.title2).bold()
            Spacer()
            Button { shift(by: 1) } label: { Image(systemName: "chevron.right") }
        }
        .buttonStyle(.borderless)
        .font(.title3)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(Array(orderedWeekdaySymbols().enumerated()), id: \.offset) { _, s in
                Text(s)
                    .font(.caption).bold()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func grid(tasksByDay: [Date: [KanbanTask]], examsByDay: [Date: [Module]]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(monthGrid(), id: \.self) { day in
                DayCell(
                    date: day,
                    inMonth: cal.isDate(day, equalTo: currentMonth, toGranularity: .month),
                    isToday: cal.isDateInToday(day),
                    tasks: tasksByDay[cal.startOfDay(for: day)] ?? [],
                    exams: examsByDay[cal.startOfDay(for: day)] ?? []
                )
            }
        }
    }

    private func shift(by months: Int) {
        if let next = cal.date(byAdding: .month, value: months, to: currentMonth) {
            currentMonth = cal.startOfMonth(for: next)
        }
    }

    private func orderedWeekdaySymbols() -> [String] {
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let offset = cal.firstWeekday - 1
        return Array(symbols[offset...]) + Array(symbols[..<offset])
    }

    private func monthGrid() -> [Date] {
        guard let interval = cal.dateInterval(of: .month, for: currentMonth) else { return [] }
        let firstWeekday = cal.component(.weekday, from: interval.start)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        guard let start = cal.date(byAdding: .day, value: -leading, to: interval.start) else { return [] }
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        dateInterval(of: .month, for: date)?.start ?? date
    }
}

private struct DayCell: View {
    let date: Date
    let inMonth: Bool
    let isToday: Bool
    let tasks: [KanbanTask]
    let exams: [Module]

    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            Text("\(cal.component(.day, from: date))")
                .font(.callout)
                .foregroundStyle(numberColor)
                .frame(width: 24, height: 24)
                .background(isToday ? Color.accentColor : .clear, in: Circle())

            if !exams.isEmpty {
                VStack(spacing: 2) {
                    ForEach(exams.prefix(2)) { exam in
                        Text(exam.name)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(.red)
                            )
                    }
                    if exams.count > 2 {
                        Text("+\(exams.count - 2) more")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 3)
            }

            HStack(spacing: 3) {
                ForEach(Array(tasks.prefix(3))) { t in
                    ModuleSwatch(colorHex: t.module?.colorHex, size: 5)
                }
                if tasks.count > 3 {
                    Text("+\(tasks.count - 3)")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 6)

            Spacer(minLength: 0)
        }
        .padding(.top, 6)
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.background.secondary.opacity(inMonth ? 0.5 : 0.15))
        )
    }

    private var numberColor: Color {
        if isToday { return .white }
        return inMonth ? .primary : .secondary
    }
}
