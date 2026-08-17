import Foundation

/// A saved dive buddy, multi-selectable when logging a dive.
struct DiveBuddy: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
