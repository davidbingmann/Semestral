import SwiftUI
import SwiftData

struct ModuleFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let semester: Semester
    let existing: Module?
    var onSave: ((Module) -> Void)? = nil

    @State private var name: String = ""
    @State private var colorHex: String = ""
    @State private var hasExam: Bool = false
    @State private var hasTime: Bool = false
    @State private var examDate: Date = .now

    private var isEditing: Bool { existing != nil }

    /// True when the module already holds multiple Exam rows — editing a single date here
    /// would silently drop the others, so we show a read-only summary instead.
    private var hasMultipleDates: Bool {
        (existing?.exams.count ?? 0) > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? "Edit Module" : "New Module")
                .font(.title2).bold()

            Form {
                TextField("Name", text: $name, prompt: Text("e.g. Programmierung I"))

                LabeledContent("Colour") { paletteSwatches }

                if hasMultipleDates {
                    LabeledContent("Exam dates") {
                        Text("\(existing?.exams.count ?? 0) dates — manage on Exams tab")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    LabeledContent("Exam date") { examDateField }
                    if hasExam {
                        LabeledContent("Time") {
                            OptionalTimeField(date: $examDate, hasTime: $hasTime)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button(isEditing ? "Save" : "Create") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 460, minHeight: 360)
        .onAppear(perform: load)
    }

    @ViewBuilder
    private var examDateField: some View {
        if hasExam {
            HStack(spacing: 8) {
                DatePopoverButton(date: $examDate)
                Spacer()
                Button("Remove") {
                    withAnimation {
                        hasExam = false
                        hasTime = false
                    }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
        } else {
            HStack {
                Text("Not set").foregroundStyle(.secondary)
                Spacer()
                Button("Set date…") {
                    examDate = .now
                    withAnimation { hasExam = true }
                }
            }
        }
    }

    private var paletteSwatches: some View {
        HStack(spacing: 8) {
            ForEach(Module.palette, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Circle().strokeBorder(
                            Color.primary,
                            lineWidth: colorHex == hex ? 2.5 : 0
                        )
                    )
                    .contentShape(Circle())
                    .onTapGesture { colorHex = hex }
            }
        }
    }

    private func load() {
        if let m = existing {
            name = m.name
            colorHex = m.colorHex
            if let first = m.exams.sorted(by: { $0.date < $1.date }).first {
                hasExam = true
                hasTime = first.hasTime
                examDate = first.date
            }
        } else {
            colorHex = Module.nextColor(for: semester)
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let module: Module
        if let m = existing {
            m.name = trimmed
            m.colorHex = colorHex
            module = m
        } else {
            let m = Module(name: trimmed, colorHex: colorHex, semester: semester)
            context.insert(m)
            module = m
        }

        if !hasMultipleDates {
            for exam in Array(module.exams) {
                context.delete(exam)
            }
            if hasExam {
                context.insert(Exam(date: examDate, hasTime: hasTime, module: module))
            }
        }

        try? context.save()
        onSave?(module)
        dismiss()
    }
}
