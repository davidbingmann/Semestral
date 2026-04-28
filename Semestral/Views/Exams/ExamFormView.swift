import SwiftUI
import SwiftData

struct ExamFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let semester: Semester
    let existing: Exam?

    @State private var selectedModule: Module?
    @State private var examDate: Date = .now
    @State private var hasTime: Bool = false
    @State private var creatingModule = false

    @State private var isPortfolio: Bool = false
    @State private var portfolioDates: [DraftExam] = []

    private struct DraftExam: Identifiable {
        let id = UUID()
        var date: Date
        var hasTime: Bool
    }

    init(semester: Semester, existing: Exam? = nil) {
        self.semester = semester
        self.existing = existing
    }

    private var isEditing: Bool { existing != nil }

    private var canSave: Bool {
        guard selectedModule != nil else { return false }
        if isPortfolio { return !portfolioDates.isEmpty }
        return true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? "Edit Exam" : "New Exam")
                .font(.title2).bold()

            Form {
                LabeledContent("Module") { moduleMenu }

                if !isEditing {
                    Toggle("Portfolio", isOn: $isPortfolio.animation())
                }

                if isPortfolio {
                    portfolioSection
                } else {
                    LabeledContent("Date") {
                        DatePopoverButton(date: $examDate)
                    }
                    LabeledContent("Time") {
                        OptionalTimeField(date: $examDate, hasTime: $hasTime)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button(isEditing ? "Save" : "Add") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
        }
        .padding()
        .frame(minWidth: 460, minHeight: 320)
        .onAppear(perform: load)
        .sheet(isPresented: $creatingModule) {
            ModuleFormView(semester: semester, existing: nil) { newModule in
                selectedModule = newModule
            }
        }
    }

    private var portfolioSection: some View {
        Section("Exam dates") {
            ForEach($portfolioDates) { $draft in
                portfolioRow(for: $draft)
            }
            Button {
                withAnimation {
                    portfolioDates.append(DraftExam(date: .now, hasTime: false))
                }
            } label: {
                Label("Add date", systemImage: "plus")
            }
        }
    }

    @ViewBuilder
    private func portfolioRow(for draft: Binding<DraftExam>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                DatePopoverButton(date: draft.date)
                Spacer()
                Button {
                    withAnimation {
                        portfolioDates.removeAll { $0.id == draft.wrappedValue.id }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            }

            HStack(spacing: 8) {
                Text("Time").foregroundStyle(.secondary).font(.caption)
                Spacer()
                OptionalTimeField(date: draft.date, hasTime: draft.hasTime)
            }
        }
        .padding(.vertical, 2)
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

    private func load() {
        if let e = existing {
            selectedModule = e.module
            examDate = e.date
            hasTime = e.hasTime
        } else if selectedModule == nil {
            selectedModule = semester.modules.first
        }
    }

    private func save() {
        guard let m = selectedModule else { return }
        if let e = existing {
            e.date = examDate
            e.hasTime = hasTime
            if e.module !== m { e.module = m }
        } else if isPortfolio {
            for d in portfolioDates {
                context.insert(Exam(date: d.date, hasTime: d.hasTime, module: m))
            }
        } else {
            context.insert(Exam(date: examDate, hasTime: hasTime, module: m))
        }
        try? context.save()
        dismiss()
    }
}
