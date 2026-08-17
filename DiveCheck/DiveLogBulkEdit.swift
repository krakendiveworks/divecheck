import Foundation

/// A set of field values to stamp onto multiple Dive Log entries at once
/// (Admin Mode's bulk edit, see BulkEditDiveLogView.swift). Each field is
/// paired with its own "apply" flag rather than relying on
/// Optional-means-skip -- that keeps "leave this field alone on every
/// selected dive" distinct from "set it to nil/a default," which matters
/// for a field like Location that's itself already Optional on
/// DiveLogEntry.
struct DiveLogBulkEdit {
    var applyLocation = false
    var locationID: UUID?
    var diveSiteID: UUID?

    var applySiteType = false
    var siteType: SiteType = .reef

    var applyEntryType = false
    var entryType: DiveEntryType = .boat

    var applyDiveType = false
    var diveType: DiveLogType = .openCircuit

    var applyWaterType = false
    var waterType: WaterType = .salt

    var applyWaterSurfaceCondition = false
    var waterSurfaceCondition: WaterSurfaceCondition = .calm

    var applySkyCondition = false
    var skyCondition: SkyCondition = .sunny

    var applyWindSpeedRange = false
    var windSpeedRange: WindSpeedRange = .calm

    var applyWindDirection = false
    var windDirection: WindDirection = .n

    /// Whether at least one field is actually checked to apply -- gates the
    /// bulk-edit sheet's Apply button so a no-op edit can't be submitted.
    var hasAnyField: Bool {
        applyLocation || applySiteType || applyEntryType || applyDiveType
            || applyWaterType || applyWaterSurfaceCondition || applySkyCondition
            || applyWindSpeedRange || applyWindDirection
    }
}
