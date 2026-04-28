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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? "Edit Module" : "New Module")
                .font(.title2).bold()

            Form {
                TextField("Name", text: $name, prompt: Text("e.g. Programmierung I"))

                LabeledContent("Colour") {
                    paletteSwatches
                }

                LabeledContent("Exam date") {
                    examDateField
                }

                if hasExam {
                    LabeledContent("Time") {
                        timeField
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

    @ViewBuilder
    private var timeField: some View {
        if hasTime {
            HStack(spacing: 8) {
                DatePicker("", selection: $examDate, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Button("Remove") {
                    withAnimation { hasTime = false }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
        } else {
            HStack {
                Text("Not set").foregroundStyle(.secondary)
                Spacer()
                Button("Set time…") {
                    withAnimation { hasTime = true }
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
            if let d = m.examDate {
                hasExam = true
                hasTime = m.examDateHasTime
                examDate = d
            }
        } else {
            colorHex = Module.nextColor(for: semester)
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let exam = hasExam ? examDate : nil
        let result: Module
        if let m = existing {
            m.name = trimmed
            m.colorHex = colorHex
            m.examDate = exam
            m.examDateHasTime = hasExam ? hasTime : true
            result = m
        } else {
            let m = Module(name: trimmed, colorHex: colorHex, examDate: exam, semester: semester)
            m.examDateHasTime = hasExam ? hasTime : true
            context.insert(m)
            result = m
        }
        try? context.save()
        onSave?(result)
        dismiss()
    }
}
