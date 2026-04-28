import SwiftUI
import SwiftData

struct KanbanColumnView: View {
    let status: KanbanStatus
    let tasks: [KanbanTask]
    let onEdit: (KanbanTask) -> Void
    let onDelete: (KanbanTask) -> Void
    let onMove: (KanbanTask, KanbanStatus) -> Void
    let onDrop: ([TaskDragPayload]) -> Void

    @State private var isTargeted = false
    @State private var arrival: ArrivalInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                Text(status.label)
                    .font(.headline)
                    .foregroundStyle(status.color)
                Text("\(tasks.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(status.color)
                    .monospacedDigit()
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(status.color.opacity(0.15), in: Capsule())
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(tasks) { task in
                        TaskCardView(
                            task: task,
                            onEdit: { onEdit(task) },
                            onDelete: { onDelete(task) },
                            onMove: { onMove(task, $0) }
                        )
                        .modifier(DropArrivalEffect(
                            dropPoint: arrival?.id == task.persistentModelID ? arrival?.point : nil
                        ))
                        .transition(.identity)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
            .scrollIndicators(.hidden)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background.secondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(isTargeted ? 1 : 0), lineWidth: 2)
                .animation(.easeInOut(duration: 0.2), value: isTargeted)
        )
        .coordinateSpace(.named("kanbanColumn"))
        .dropDestination(for: TaskDragPayload.self) { payloads, location in
            for p in payloads {
                arrival = ArrivalInfo(id: p.id, point: location)
            }
            onDrop(payloads)
            return !payloads.isEmpty
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }

    private struct ArrivalInfo: Equatable {
        let id: PersistentIdentifier
        let point: CGPoint
    }
}

private struct DropArrivalEffect: ViewModifier {
    let dropPoint: CGPoint?
    @State private var offset: CGSize = .zero
    @State private var didStart = false

    func body(content: Content) -> some View {
        content
            .offset(offset)
            .background {
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        guard !didStart, let dp = dropPoint else { return }
                        didStart = true
                        let f = proxy.frame(in: .named("kanbanColumn"))
                        var t = Transaction()
                        t.disablesAnimations = true
                        withTransaction(t) {
                            offset = CGSize(
                                width: dp.x - f.midX,
                                height: dp.y - f.midY
                            )
                        }
                        DispatchQueue.main.async {
                            withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                                offset = .zero
                            }
                        }
                    }
                }
            }
    }
}
