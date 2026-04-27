import SwiftUI
import SwiftData

struct ModuleFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let semester: Semester
    let existing: Module?

    @State private var name: String = ""
    @State private var colorHex: String = ""
    @State private var hasExam: Bool = false
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

                Toggle("Has exam", isOn: $hasExam.animation())
                if hasExam {
                    DatePicker(
                        "Exam date",
                        selection: $examDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
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
                examDate = d
            }
        } else {
            colorHex = Module.nextColor(for: semester)
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let exam = hasExam ? examDate : nil
        if let m = existing {
            m.name = trimmed
            m.colorHex = colorHex
            m.examDate = exam
        } else {
            let m = Module(name: trimmed, colorHex: colorHex, examDate: exam, semester: semester)
            context.insert(m)
        }
        try? context.save()
        dismiss()
    }
}
