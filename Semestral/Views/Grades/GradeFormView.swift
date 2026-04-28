import SwiftUI
import SwiftData

struct GradeFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let semester: Semester
    let existing: Grade?

    @State private var selectedModule: Module?
    @State private var value: Double = 1.0
    @State private var valueText: String = "1,0"
    @State private var weight: Double = 5.0
    @State private var dateAdded: Date = .now
    @State private var notes: String = ""
    @State private var creatingModule = false

    private var isEditing: Bool { existing != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? "Edit Grade" : "New Grade")
                .font(.title2).bold()

            Form {
                LabeledContent("Module") { moduleMenu }

                LabeledContent("Grade") { gradePicker }

                LabeledContent("ECTS") { weightStepper }

                DatePicker("Date", selection: $dateAdded, displayedComponents: .date)

                LabeledContent("Notes") {
                    TextField("Optional", text: $notes, prompt: Text("e.g. Final exam"))
                        .textFieldStyle(.roundedBorder)
                }
            }
            .formStyle(.grouped)

            HStack {
                if isEditing {
                    Button(role: .destructive) { delete() } label: {
                        Text("Delete")
                    }
                }
                Spacer()
                Button("Cancel") { dismiss() }
                Button(isEditing ? "Save" : "Create") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedModule == nil)
            }
        }
        .padding()
        .frame(minWidth: 480, minHeight: 380)
        .onAppear(perform: load)
        .sheet(isPresented: $creatingModule) {
            ModuleFormView(semester: semester, existing: nil) { newModule in
                selectedModule = newModule
            }
        }
    }

    // MARK: - Pieces

    private var moduleMenu: some View {
        Menu {
            if !semester.modules.isEmpty {
                Picker(selection: $selectedModule) {
                    ForEach(semester.modules) { m in
                        Text(m.name).tag(m as Module?)
                    }
                } label: {
                    Text("Module")
                }
                .pickerStyle(.inline)

                Divider()
            }

            Button {
                creatingModule = true
            } label: {
                Label("New Module…", systemImage: "plus")
            }
        } label: {
            HStack(spacing: 6) {
                if let m = selectedModule {
                    ModuleSwatch(colorHex: m.colorHex, size: 8)
                    Text(m.name)
                } else {
                    Text("None").foregroundStyle(.secondary)
                }
            }
        }
        .fixedSize()
    }

    private var gradePicker: some View {
        HStack(spacing: 8) {
            TextField("", text: $valueText, prompt: Text("1,0"))
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 70)
                .onChange(of: valueText) { _, new in
                    if let parsed = parseGrade(new) { value = parsed }
                }
                .onSubmit { normalizeValueText() }

            Menu {
                ForEach(Grade.scale, id: \.self) { g in
                    Button {
                        value = g
                        valueText = Grade.formatted(g)
                    } label: {
                        if abs(g - value) < 0.01 {
                            Label(Grade.formatted(g), systemImage: "checkmark")
                        } else {
                            Text(Grade.formatted(g))
                        }
                    }
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()

            Text(Grade.formatted(value))
                .font(.title3.weight(.semibold))
                .foregroundStyle(GradeStyle.color(for: value))
                .monospacedDigit()
                .frame(minWidth: 36, alignment: .trailing)
        }
    }

    private func parseGrade(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        // Accept both "," and "." as the decimal separator. Don't route through
        // a localized NumberFormatter — de_DE treats "." as a grouping separator,
        // so "1.3" would parse as 13.
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized) else { return nil }
        guard (0.7...6.0).contains(value) else { return nil }
        return value
    }

    private func normalizeValueText() {
        valueText = Grade.formatted(value)
    }

    private var weightStepper: some View {
        HStack(spacing: 10) {
            Stepper(value: $weight, in: 0.5...30.0, step: 0.5) {
                EmptyView()
            }
            .labelsHidden()
            .fixedSize()

            Text(weightLabel)
                .font(.callout.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private var weightLabel: String {
        if weight == weight.rounded() { return String(format: "%.0f ECTS", weight) }
        return String(format: "%.1f ECTS", weight)
    }

    // MARK: - Lifecycle

    private func load() {
        if let g = existing {
            selectedModule = g.module
            value = g.value
            weight = g.weight
            dateAdded = g.dateAdded
            notes = g.notes ?? ""
        } else {
            selectedModule = semester.modules.first
        }
        valueText = Grade.formatted(value)
    }

    private func save() {
        guard let m = selectedModule else { return }
        if let parsed = parseGrade(valueText) { value = parsed }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        let storedNotes: String? = trimmedNotes.isEmpty ? nil : trimmedNotes

        if let g = existing {
            g.module = m
            g.value = value
            g.weight = weight
            g.dateAdded = dateAdded
            g.notes = storedNotes
        } else {
            let g = Grade(
                value: value,
                weight: weight,
                dateAdded: dateAdded,
                notes: storedNotes,
                module: m
            )
            context.insert(g)
        }
        try? context.save()
        dismiss()
    }

    private func delete() {
        guard let g = existing else { return }
        context.delete(g)
        try? context.save()
        dismiss()
    }
}
