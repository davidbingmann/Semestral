import SwiftUI
import SwiftData

struct GradesTab: View {
    @Query(sort: \Semester.startDate, order: .reverse)
    private var semesters: [Semester]

    @Query(sort: \Grade.dateAdded, order: .reverse)
    private var allGrades: [Grade]

    @AppStorage("selectedSemesterID") private var selectedSemesterIDString: String = ""

    @State private var creatingGrade = false
    @State private var editingGrade: Grade?

    var body: some View {
        Group {
            if allGrades.isEmpty {
                ContentUnavailableView(
                    "No Grades",
                    systemImage: "graduationcap.fill",
                    description: Text(
                        activeSemester == nil
                        ? "Add a semester first, then tap + to record a grade."
                        : "Tap + to record your first grade."
                    )
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        OverallSummaryCard(grades: allGrades)
                        ForEach(semestersWithGrades) { semester in
                            SemesterSection(
                                semester: semester,
                                onEdit: { editingGrade = $0 },
                                onDelete: delete
                            )
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 96)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomLeading) {
            if activeSemester != nil {
                PlusFAB { creatingGrade = true }
                    .padding(20)
            }
        }
        .sheet(isPresented: $creatingGrade) {
            if let s = activeSemester {
                GradeFormView(semester: s, existing: nil)
            }
        }
        .sheet(item: $editingGrade) { grade in
            if let s = grade.module?.semester ?? activeSemester {
                GradeFormView(semester: s, existing: grade)
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

    private var semestersWithGrades: [Semester] {
        semesters.filter { semester in
            semester.modules.contains { !$0.grades.isEmpty }
        }
    }

    @Environment(\.modelContext) private var context

    private func delete(_ grade: Grade) {
        context.delete(grade)
        try? context.save()
    }
}

// MARK: - Overall summary

private struct OverallSummaryCard: View {
    let grades: [Grade]

    var body: some View {
        let avg = Grade.weightedAverage(grades)
        let totalEcts = grades.reduce(0) { $0 + max($1.weight, 0) }

        HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Overall Average")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let avg {
                    Text(Grade.formatted(avg))
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                        .foregroundStyle(GradeStyle.color(for: avg))
                        .monospacedDigit()
                } else {
                    Text("—")
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                StatPill(label: "Grades", value: "\(grades.count)")
                StatPill(label: "ECTS", value: ectsString(totalEcts))
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.background.secondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.separator.opacity(0.6), lineWidth: 0.5)
        )
    }

    private func ectsString(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}

private struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(.background.tertiary)
        )
    }
}

// MARK: - Semester section

private struct SemesterSection: View {
    let semester: Semester
    let onEdit: (Grade) -> Void
    let onDelete: (Grade) -> Void

    var body: some View {
        let grades = semester.modules.flatMap(\.grades)
        let avg = Grade.weightedAverage(grades)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(semester.name)
                    .font(.title3.weight(.semibold))
                Spacer()
                if let avg {
                    HStack(spacing: 6) {
                        Text("Ø")
                            .foregroundStyle(.secondary)
                        Text(Grade.formatted(avg))
                            .foregroundStyle(GradeStyle.color(for: avg))
                            .monospacedDigit()
                    }
                    .font(.callout.weight(.semibold))
                }
            }
            .padding(.horizontal, 4)

            VStack(spacing: 6) {
                ForEach(sortedGrades(grades)) { grade in
                    GradeRow(grade: grade)
                        .contextMenu {
                            Button("Edit…") { onEdit(grade) }
                            Button("Delete", role: .destructive) { onDelete(grade) }
                        }
                        .onTapGesture(count: 2) { onEdit(grade) }
                }
            }
        }
    }

    private func sortedGrades(_ grades: [Grade]) -> [Grade] {
        grades.sorted { lhs, rhs in
            if lhs.dateAdded != rhs.dateAdded { return lhs.dateAdded > rhs.dateAdded }
            return (lhs.module?.name ?? "") < (rhs.module?.name ?? "")
        }
    }
}

// MARK: - Row

private struct GradeRow: View {
    let grade: Grade

    var body: some View {
        HStack(spacing: 12) {
            ModuleSwatch(colorHex: grade.module?.colorHex, size: 10)

            VStack(alignment: .leading, spacing: 1) {
                Text(grade.module?.name ?? "Unassigned")
                    .font(.body.weight(.medium))
                if let notes = grade.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(grade.dateAdded.formatted(.dateTime.day().month(.abbreviated).year()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            WeightChip(weight: grade.weight)

            Text(Grade.formatted(grade.value))
                .font(.title3.weight(.semibold))
                .foregroundStyle(GradeStyle.color(for: grade.value))
                .monospacedDigit()
                .frame(minWidth: 44, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.background.secondary)
        )
        .contentShape(Rectangle())
    }
}

private struct WeightChip: View {
    let weight: Double

    var body: some View {
        Text("\(formattedWeight) ECTS")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(.background.tertiary))
    }

    private var formattedWeight: String {
        if weight == weight.rounded() { return String(format: "%.0f", weight) }
        return String(format: "%.1f", weight)
    }
}

// MARK: - Color scale

enum GradeStyle {
    static func color(for value: Double) -> Color {
        switch value {
        case ..<1.5:  return .green
        case ..<2.5:  return Color(hex: "#5BBCB8")
        case ..<3.5:  return .orange
        case ..<4.05: return Color(hex: "#E09B3D")
        default:      return .red
        }
    }
}
