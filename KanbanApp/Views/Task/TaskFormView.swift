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
    @State private var hasTime: Bool = false
    @State private var status: KanbanStatus = .todo
    @State private var recurrence: KanbanRecurrence?
    @State private var creatingModule = false

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

                LabeledContent("Module") { moduleMenu }

                Picker("Status", selection: $status) {
                    ForEach(KanbanStatus.allCases) { s in
                        Text(s.label).tag(s)
                    }
                }

                Toggle("Has deadline", isOn: $hasDeadline.animation())
                if hasDeadline {
                    LabeledContent("Date") {
                        DatePopoverButton(date: $deadline)
                    }
                    LabeledContent("Time") {
                        timeField
                    }
                }

                Picker("Repeat", selection: $recurrence) {
                    Text("Never").tag(KanbanRecurrence?.none)
                    ForEach(KanbanRecurrence.allCases) { r in
                        Text(r.label).tag(KanbanRecurrence?.some(r))
                    }
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
                    .disabled(
                        title.trimmingCharacters(in: .whitespaces).isEmpty
                            || module == nil
                    )
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 520)
        .onAppear(perform: load)
        .sheet(isPresented: $creatingModule) {
            if let s = semester {
                ModuleFormView(semester: s, existing: nil) { newModule in
                    module = newModule
                }
            }
        }
    }

    private var moduleMenu: some View {
        Menu {
            Picker(selection: $module) {
                Text("None").tag(Module?.none)
                ForEach(availableModules) { m in
                    Text(m.name).tag(Module?.some(m))
                }
            } label: {
                Text("Module")
            }
            .pickerStyle(.inline)

            Divider()

            Button {
                creatingModule = true
            } label: {
                Label("New Module…", systemImage: "plus")
            }
            .disabled(semester == nil)
        } label: {
            HStack(spacing: 6) {
                if let m = module {
                    ModuleSwatch(colorHex: m.colorHex, size: 8)
                    Text(m.name)
                } else {
                    Text("None").foregroundStyle(.secondary)
                }
            }
        }
        .fixedSize()
    }

    @ViewBuilder
    private var timeField: some View {
        if hasTime {
            HStack(spacing: 8) {
                DatePicker(
                    "",
                    selection: $deadline,
                    displayedComponents: .hourAndMinute
                )
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

    private func load() {
        if let t = existing {
            title = t.title
            notes = t.notes
            module = t.module
            status = t.status
            recurrence = t.recurrence
            if let d = t.deadline {
                hasDeadline = true
                deadline = d
                hasTime = t.deadlineHasTime
            }
        } else {
            module = defaultModule
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let dl = hasDeadline ? deadline : nil
        let dlHasTime = hasDeadline && hasTime
        let task: KanbanTask
        if let existing {
            task = existing
            task.title = trimmed
            task.notes = notes
            task.deadline = dl
            task.deadlineHasTime = dlHasTime
            task.module = module
            task.recurrence = recurrence
            if task.status != status {
                task.updateStatus(status)
            }
        } else {
            task = KanbanTask(
                title: trimmed,
                notes: notes,
                deadline: dl,
                deadlineHasTime: dlHasTime,
                module: module,
                status: status,
                recurrence: recurrence
            )
            context.insert(task)
        }
        if task.status == .done && task.recurrence != nil {
            task.updateStatus(.done)
        }
        try? context.save()
        dismiss()
    }
}
