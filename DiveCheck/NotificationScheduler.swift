import Foundation
import UserNotifications

/// Local (on-device) reminders for two dates the app already tracks but
/// doesn't otherwise surface: an Equipment Locker item's next service due
/// date, and how long it's been since an Emergency Action Plan was last
/// reviewed. Everything here is scheduled directly via
/// `UNUserNotificationCenter` -- no push infrastructure, no server.
///
/// Scheduling is a harmless no-op if the user hasn't granted notification
/// permission yet (the request just silently won't fire); `requestAuthorization()`
/// is what actually prompts, wired to a toggle in Settings.
enum NotificationScheduler {
    @discardableResult
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    // MARK: - Equipment service reminders

    private static func equipmentIdentifier(_ id: UUID) -> String {
        "equipment-service-\(id.uuidString)"
    }

    /// Reschedules (or cancels, if `dueDate` is nil/in the past) the
    /// service-due reminder for one piece of gear, firing at 9am on the due
    /// date. Safe to call any time the item's due date or name changes --
    /// re-adding with the same identifier replaces whatever was scheduled
    /// before.
    static func scheduleEquipmentReminder(itemID: UUID, name: String, dueDate: Date?) {
        let identifier = equipmentIdentifier(itemID)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        guard let dueDate, dueDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Equipment Service Due"
        content.body = "\(name.isEmpty ? "Your gear" : name) is due for service today."
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelEquipmentReminder(itemID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [equipmentIdentifier(itemID)])
    }

    // MARK: - EAP review reminders

    private static func eapIdentifier(_ id: UUID) -> String {
        "eap-review-\(id.uuidString)"
    }

    /// DAN recommends reviewing an EAP every few months since facilities
    /// close, numbers change, and supplies expire -- this reminds 6 months
    /// after the last review (or 6 months from today if it's never been
    /// reviewed).
    static func scheduleEAPReviewReminder(planID: UUID, locationName: String, lastReviewedAt: Date?) {
        let identifier = eapIdentifier(planID)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        let baseline = lastReviewedAt ?? Date()
        guard let dueDate = Calendar.current.date(byAdding: .month, value: 6, to: baseline) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Emergency Action Plan Review"
        content.body = "It's been about 6 months -- review the EAP for \(locationName.isEmpty ? "your dive location" : locationName). Facilities close, numbers change, and supplies expire."
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelEAPReviewReminder(planID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [eapIdentifier(planID)])
    }
}
