import SwiftUI

/// "Set time…" placeholder that swaps to an inline `.hourAndMinute` picker + Remove button.
/// Mirrors the `DatePopoverButton` set/remove pattern for the time half of a date+time pair.
struct OptionalTimeField: View {
    @Binding var date: Date
    @Binding var hasTime: Bool

    var body: some View {
        if hasTime {
            HStack(spacing: 8) {
                DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
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
}
