import Foundation

/// Preset equipment types shown in the Equipment Locker, so gear can be
/// grouped and filtered consistently.
enum EquipmentCategory: String, Codable, CaseIterable, Identifiable {
    case mask = "Mask"
    case fins = "Fins"
    case regulator = "Regulator"
    case bcd = "BCD"
    case computer = "Computer"
    case rebreather = "Rebreather"
    case exposureProtection = "Exposure Protection"
    case undergarments = "Undergarments"
    case tank = "Tank"
    case light = "Light"
    case other = "Other"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .mask: return "eyeglasses"
        case .fins: return "figure.pool.swim"
        case .regulator: return "lungs.fill"
        case .bcd: return "bag.fill"
        case .computer: return "gauge"
        case .rebreather: return "arrow.triangle.2.circlepath"
        case .exposureProtection: return "thermometer.snowflake"
        case .undergarments: return "tshirt.fill"
        case .tank: return "cylinder.fill"
        case .light: return "flashlight.on.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

/// One service/maintenance event logged against a piece of gear.
struct ServiceRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var serviceDescription: String
    var servicedBy: String

    init(id: UUID = UUID(), date: Date = Date(), serviceDescription: String = "", servicedBy: String = "") {
        self.id = id
        self.date = date
        self.serviceDescription = serviceDescription
        self.servicedBy = servicedBy
    }
}

/// A single owned piece of dive gear: what it is, when it was bought, and
/// its service history — independent of the checklist categories/units.
struct EquipmentItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: EquipmentCategory
    var brand: String
    var model: String
    var serialNumber: String
    var purchaseDate: Date?
    var nextServiceDue: Date?
    var notes: String
    var serviceHistory: [ServiceRecord]

    init(
        id: UUID = UUID(),
        name: String,
        category: EquipmentCategory,
        brand: String = "",
        model: String = "",
        serialNumber: String = "",
        purchaseDate: Date? = nil,
        nextServiceDue: Date? = nil,
        notes: String = "",
        serviceHistory: [ServiceRecord] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.brand = brand
        self.model = model
        self.serialNumber = serialNumber
        self.purchaseDate = purchaseDate
        self.nextServiceDue = nextServiceDue
        self.notes = notes
        self.serviceHistory = serviceHistory
    }

    enum ServiceStatus {
        case ok
        case dueSoon
        case overdue
    }

    /// "Due soon" is within the next 30 days; overdue is anything past today.
    var serviceStatus: ServiceStatus {
        guard let due = nextServiceDue else { return .ok }
        let now = Date()
        if due < now { return .overdue }
        if let soon = Calendar.current.date(byAdding: .day, value: 30, to: now), due <= soon {
            return .dueSoon
        }
        return .ok
    }
}
