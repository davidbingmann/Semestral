import SwiftUI

struct DatePopoverButton: View {
    @Binding var date: Date

    @State private var isShown = false

    var body: some View {
        Button {
            isShown.toggle()
        } label: {
            Text(date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
                .monospacedDigit()
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $isShown, arrowEdge: .bottom) {
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(12)
        }
    }
}
