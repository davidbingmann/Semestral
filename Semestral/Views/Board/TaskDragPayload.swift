import CoreTransferable
import SwiftData
import UniformTypeIdentifiers

struct TaskDragPayload: Codable, Transferable {
    let id: PersistentIdentifier

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
