import Foundation

/// A small data-capture field attached to a checklist item or a checklist's
/// header (e.g. a voltage reading, a Good/Replaced choice, a date packed) —
/// mirrors the blanks found on the paper Prism 2 forms.
struct ItemField: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case text
        case choice
    }

    let id: UUID
    var label: String
    var kind: Kind
    var textValue: String
    var options: [String]
    var selectedOption: String?

    init(
        id: UUID = UUID(),
        label: String,
        kind: Kind,
        textValue: String = "",
        options: [String] = [],
        selectedOption: String? = nil
    ) {
        self.id = id
        self.label = label
        self.kind = kind
        self.textValue = textValue
        self.options = options
        self.selectedOption = selectedOption
    }

    static func text(_ label: String) -> ItemField {
        ItemField(label: label, kind: .text)
    }

    static func choice(_ label: String, options: [String]) -> ItemField {
        ItemField(label: label, kind: .choice, options: options)
    }
}
