import SwiftUI
import SwiftData

struct TaskFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let semester: Semester?
    let defaultModule: Module?
    let existing: KanbanTask?

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var module: Module?
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = .now
    @State private var status: KanbanStatus = .todo

    private var isEditing: Bool { existing != nil }

    private var availableModules: [Module] {
        semester?.modules ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? "Edit Task" : "New Task")
                .font(.title2).bold()

            Form {
                TextField("Title", text: $title, prompt: Text("e.g. Read Chapter 3"))

                if !availableModules.isEmpty {
                    Picker("Module", selection: $module) {
                        Text("None").tag(Module?.none)
                        ForEach(availableModules) { m in
                            Text(m.name).tag(Module?.some(m))
                        }
                    }
                }

                Picker("Status", selection: $status) {
                    ForEach(KanbanStatus.allCases) { s in
                        Text(s.label).tag(s)
                    }
                }

                Toggle("Has deadline", isOn: $hasDeadline.animation())
                if hasDeadline {
                    DatePicker(
                        "Deadline",
                        selection: $deadline,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button(isEditing ? "Save" : "Create") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 520)
        .onAppear(perform: load)
    }

    private func load() {
        if let t = existing {
            title = t.title
            notes = t.notes
            module = t.module
            status = t.status
            if let d = t.deadline {
                hasDeadline = true
                deadline = d
            }
        } else {
            module = defaultModule
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let dl = hasDeadline ? deadline : nil
        if let t = existing {
            t.title = trimmed
            t.notes = notes
            t.deadline = dl
            t.module = module
            if t.status != status {
                t.updateStatus(status)
            }
        } else {
            let t = KanbanTask(
                title: trimmed,
                notes: notes,
                deadline: dl,
                module: module,
                status: status
            )
            context.insert(t)
        }
        try? context.save()
        dismiss()
    }
}
