import SwiftUI
import SwiftData

struct SemesterFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let existing: Semester?

    @State private var name: String = ""
    @State private var startDate: Date = .now
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    @State private var degree: DegreeType = .bachelor

    private var isEditing: Bool { existing != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? "Edit Semester" : "New Semester")
                .font(.title2).bold()

            Form {
                TextField("Name", text: $name, prompt: Text("e.g. WiSe 2025/26"))
                Picker("Degree", selection: $degree) {
                    ForEach(DegreeType.allCases) { d in
                        Text(d.label).tag(d)
                    }
                }
                DatePicker("Start", selection: $startDate, displayedComponents: .date)
                DatePicker("End", selection: $endDate, displayedComponents: .date)
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
        .frame(minWidth: 420, minHeight: 280)
        .onAppear {
            if let s = existing {
                name = s.name
                startDate = s.startDate
                endDate = s.endDate
                degree = s.degree ?? .bachelor
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let s = existing {
            s.name = trimmed
            s.startDate = startDate
            s.endDate = endDate
            s.degree = degree
        } else {
            let s = Semester(name: trimmed, startDate: startDate, endDate: endDate, degree: degree)
            context.insert(s)
        }
        try? context.save()
        dismiss()
    }
}
