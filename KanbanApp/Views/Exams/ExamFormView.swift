import SwiftUI
import SwiftData

struct ExamFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let semester: Semester

    @State private var selectedModule: Module?
    @State private var examDate: Date = .now
    @State private var hasTime: Bool = false
    @State private var creatingModule = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Exam")
                .font(.title2).bold()

            Form {
                LabeledContent("Module") { moduleMenu }

                LabeledContent("Date") {
                    DatePopoverButton(date: $examDate)
                }

                LabeledContent("Time") { timeField }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedModule == nil)
            }
        }
        .padding()
        .frame(minWidth: 460, minHeight: 320)
        .onAppear {
            if selectedModule == nil { selectedModule = semester.modules.first }
            syncFields(to: selectedModule)
        }
        .onChange(of: selectedModule) { _, newModule in
            syncFields(to: newModule)
        }
        .sheet(isPresented: $creatingModule) {
            ModuleFormView(semester: semester, existing: nil) { newModule in
                selectedModule = newModule
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

    private func syncFields(to module: Module?) {
        if let m = module, let d = m.examDate {
            examDate = d
            hasTime = m.examDateHasTime
        } else {
            examDate = .now
            hasTime = false
        }
    }

    private func save() {
        guard let m = selectedModule else { return }
        m.examDate = examDate
        m.examDateHasTime = hasTime
        try? context.save()
        dismiss()
    }
}
