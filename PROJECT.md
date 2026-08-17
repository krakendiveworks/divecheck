# DiveCheck

A native iOS app (SwiftUI, iOS 16+) for scuba divers: pre-dive checklists organized by discipline, an equipment locker for tracking owned gear and service history, and a detailed dive log. Built for iPhone and iPad, single-user, offline-first (all data lives on-device via `UserDefaults`, optionally mirrored to iCloud -- see CloudSync.swift).

Xcode project: `DiveCheck.xcodeproj`. Bundle identifier: `com.billmitlehner.divecheck.personal`. Deployment target: iOS 16.0. Swift 5.0.

---

## 1. Feature Overview

### Navigation structure

The home screen (`ContentView.swift`) is a flat 6-item menu; every feature below lives one level under one of these:

- **Plan** (`PlanMenuView.swift`) — Checklists, Locations (with a Dive Site Map), Emergency Action Plans
- **Dives** (`DivesMenuView.swift`) — Dive Logs, Statistics, Dive Computers
- **Equipment** (`EquipmentMenuView.swift`) — Equipment Locker, Maintenance Schedule, Service History
- **Wallet** (`WalletMenuView.swift`) — Certifications, Diver Medical ID -- the personal documents a diver carries from dive to dive rather than ones tied to a specific Location or dive
- **Calculators** (`CalculatorsListView.swift`) — grouped into three sections (see 1.13): Gas Mix & Exposure Limits (MOD, PPO2, Best Mix, EAD, END, CNS O2 Toxicity), Gas Consumption & Reserves (SAC/RMV, Gas Time Remaining, Minimum Gas), and Weighting (Weight Check)
- **Settings** (`SettingsView.swift`) — default units (feet/meters, °F/°C, lbs/kg) applied to new Dive Log entries only, a Reminders toggle for local notifications (see 1.8), and an Admin Mode toggle that unlocks Dive Log bulk actions (see 1.3's "Admin Mode" subsection)

`PlaceholderToolView.swift` is a generic reusable "coming soon" screen that was used by Statistics/Maintenance Schedule/Service History before they were built out; it's no longer wired to any route but is left in the project in case a future stub screen needs it.

### 1.1 Checklists

Tapping **Checklists** under **Plan** lists five categories, in this order: **Open Circuit**, **Closed Circuit**, **Technical Diving**, **General Items**, **Travel** — plus a sixth row, **Saved Checklists**, below them.

- **Open Circuit** and **Technical Diving** are each a single comprehensive starter checklist, organized into sections (Exposure Protection, Core Gear, Air/Gas Supply, Instrumentation, Safety & Signaling, Site Safety, Documentation, etc.) covering a full multi-dive day.
- **Closed Circuit** contains two "units": **Hollis Prism 2** (Assembly, Operational, and Post-Dive checklists transcribed from the manufacturer's manual, including recorded-value fields for battery voltages, O2 sensor readings, scrubber pack info, cylinder analysis, and nested lettered sub-steps) and **Common Gear** (mask, fins, exposure protection, bailout bottle/regulator, sorb/sanitizing supplies, lights, SMB, reef hook, jon line, site safety kit).
- **General Items** is the "day of diving" extras list (water, food, towel, save-a-dive kit, etc.) — not gear.
- **Travel** covers trip logistics (documents, insurance, packing).

Behavior:
- Tapping a category with only one checklist and no sub-units (General Items, Open Circuit, Technical Diving, Travel, and Closed Circuit's Common Gear unit) jumps straight into that checklist — no intermediate list screen.
- Categories/units support adding custom checklists or new equipment units via a "+" menu.
- Checklist items can have nested sub-items (lettered sub-steps), inline data-entry fields (text or Good/Replaced-style choice pickers), and non-checkable "note" rows used as section headers or instructional text.
- Each checklist has its own progress bar and a **Reset** button (clears checkmarks only, keeps custom items).
- **Save to History**: any checklist can be frozen as a read-only, timestamped snapshot, browsable later from **Saved Checklists** (Plan → Checklists → Saved Checklists). Saved snapshots cannot be edited or re-checked.

### 1.2 Equipment Locker

Reachable via **Equipment → Equipment Locker**. An inventory of gear the diver owns, independent of the checklist screens (by design — not linked to checklist units).

- Each item: name, category (Mask, Fins, Regulator, BCD, Computer, Rebreather, Exposure Protection, Undergarments, Tank, Light, Other), brand, model, serial number, purchase date, next service due date, notes, and a full service history (date, description, serviced-by).
- The list flags gear as **overdue** (red) or **due soon** (orange, within 30 days) based on the next-service date. `ServiceStatusBadge` (in `LabeledFields.swift`) is the shared badge component for this — used here and in Maintenance Schedule below.

#### Maintenance Schedule

Reachable via **Equipment → Maintenance Schedule** (`MaintenanceScheduleView.swift`). Doesn't add any new data — it's every item in the Equipment Locker re-grouped by `EquipmentItem.serviceStatus`/`nextServiceDue` into **Overdue**, **Due Soon**, **Scheduled** (has a future date, not yet due soon), and **No Service Date Set**, each sorted soonest-first. Tapping an item opens its existing detail screen to actually update the date.

#### Service History

Reachable via **Equipment → Service History** (`ServiceHistoryView.swift`). Also reuses existing data rather than adding any — one section per equipment item showing its purchase date and its full `serviceHistory` (date/description/serviced-by), newest first. Read-only; tap the item name to jump to its detail screen to add or edit a record.

### 1.3 Dive Log

A detailed per-dive log, reachable via **Dives → Dive Logs**. Tapping "Log Dive" creates a blank entry (pre-filled with the default units set in **Settings**) and opens it immediately for editing.

Fields, grouped into sections:
- **Overview** — date & time, dive type (Open Circuit / Closed Circuit / Technical), location (two-step picker: pick/add a Location, then optionally pick/add a Dive Site within it — see 1.4 below), site type, entry type (Shore / Boat / Dock / Boat Ramp).
- **Depth & Time** — duration (minutes, explicitly labeled), max depth and average depth with a per-entry feet/meters toggle that relabels the fields live **and converts the existing numbers** (see "Dynamic unit conversion" below).
- **Conditions** — water and air temperature with a per-entry °F/°C toggle (also converts existing numbers), visibility (uses the same depth unit and converts with it), water type (Salt/Fresh), water surface condition (Calm/Wavelets/Chop/Surge/Rough/Very Rough), sky condition (Sunny/Partly Cloudy/Cloudy/Overcast/Rain), wind speed range (knot bands), and wind direction (8-point compass, the direction the wind is blowing *toward*, per explicit request — not the meteorological "from" convention).
- **Gas & Consumption** — conditional on dive type: gas mix/cylinder config/tank size/service pressure/start-end pressure/additional cylinders for Open Circuit & Technical, or O2 setpoint/diluent/bailout gas for Closed Circuit. SAC Rate and RMV/SCR fields stay manually editable but can be filled in by a **Calculate from Tank Data** button (see `SACCalculation.swift`, same math as the standalone SAC/RMV calculator) once Tank Size, Service Pressure, Start/End Pressure, Average Depth, and Duration are filled in.
- **Dive Buddies** — multi-select from a saved buddy list; new buddies can be added inline and are saved for future dives.
- **Gear & What You Wore** — a single merged section: multi-select gear actually used, pulled from the Equipment Locker (this is how exposure protection — wetsuit/drysuit, hood, gloves, undergarments — and all other gear get recorded, rather than duplicating free-text fields). The only field that stayed standalone here is **Weight Used** (also converts lbs/kg live on toggle), since it varies dive to dive even with the same gear.
- **Reflection** — a 1–5 star rating and "Notes / What You Saw" (free text).

Every field in the Dive Log keeps a persistent label next to its value (not just placeholder text), so a bare number like "45" always reads as "Duration (min): 45" rather than losing its meaning once typed.

**Dynamic unit conversion**: switching the Depth Unit, Temperature Unit, or Weight Unit segmented control doesn't just relabel the fields — it converts the numbers already typed in (feet⇄meters via ×3.28084, °F⇄°C via the standard formula, lbs⇄kg via ×2.20462), rounded to one decimal place. Logic lives in `UnitConversion.swift`; blank or non-numeric text is left alone rather than converted. Each Picker's `selection` binding does the conversion in its `set` closure before the unit itself changes, using the entry's *current* unit as "from".

**Legacy free-text location**: `DiveLogEntry.location: String` still exists (unused by the UI now) purely so entries saved before the structured Locations feature still decode and display something via `AppStore.displayLocationName(for:)`'s fallback — new/edited entries use `locationID`/`diveSiteID` instead.

**Admin Mode (bulk actions)**: when **Settings → Admin Mode** is on, `DiveLogListView.swift` gets a **Select** button (top-left) that switches every row into a manual checkbox (hand-rolled, not SwiftUI's `List(selection:)`/`EditMode`, to keep row-tap behavior unambiguous) and shows a bottom action bar with **Select All / Deselect All**, **Delete** (bulk, with a confirmation alert), and **Edit** (opens `BulkEditDiveLogView.swift`). Off by default -- these are the kind of "touches a lot of dives at once" actions that shouldn't be one accidental tap away on the normal screen.

- **Bulk delete** reuses `AppStore.deleteDiveLogEntry(_:)` per entry (via `deleteDiveLogEntries(_:)`), so photo cleanup stays in the one place it's already handled.
- **Bulk edit** (`BulkEditDiveLogView.swift` / `DiveLogBulkEdit.swift`) stamps a chosen set of fields — Location, Dive Type, Site Type, Entry Type, Water Type, Water Surface, Sky, Wind Speed, Wind Direction — onto every selected entry at once. Each field has its own "Apply ___" toggle, so checking Site Type doesn't silently blank out Entry Type (or anything else) on every selected dive; unchecked fields are left exactly as they were on each entry. `AppStore.bulkUpdateDiveLogEntries(_:with:)` applies it.
- **Forget Downloaded Dives** (on the Bluetooth import screen, `BluetoothDiveImportView.swift`) is also gated behind Admin Mode. It clears the per-computer "already downloaded" fingerprint LibDCSwift keeps to avoid re-pulling the same dives every time -- useful while testing, but not something a diver should be able to trigger by accident, so it lives under the same toggle as the Dive Log's bulk actions rather than being its own separate setting.

### Statistics

Reachable via **Dives → Statistics** (`StatisticsView.swift`). Computed live from `store.diveLogEntries` on every view -- nothing here is stored separately, so it can't drift out of sync with the Dive Log.

- **Overview** — total dive count, total dive time (all logged durations summed, formatted as `Xh Ym`), longest dive, shortest dive (each with its location and date). Entries with a blank or non-numeric duration are excluded from the time-based stats rather than counted as zero.
- **By Dive Type** — count for Open Circuit / Closed Circuit / Technical.
- **By Location** — dive count per Location (via `AppStore.displayLocationName(for:)`; entries with no Location assigned show as "Unassigned"), sorted most-dived first.
- **By Dive Computer** — total time and dive count per saved `DiveComputer` (via `AppStore.displayDeviceName(for:)`), sorted by time. See 1.12 for how a dive gets attributed to a specific physical computer rather than just a device-name string; hand-logged dives (and any without a resolved computer) are grouped under "Manually Logged".

### 1.4 Locations

A standalone "Locations" tool under **Plan**, plus the two-step picker used from the Dive Log. Each **Location** (`SavedLocation.swift`) has a name and any number of nested **Dive Sites** (`DiveSite`) — e.g. a Location "Key Largo, FL" can hold Dive Sites "Molasses Reef", "Christ of the Abyss", etc., so a place you return to repeatedly doesn't need re-entering for every distinct site.

- **LocationsListView.swift** — top-level CRUD list (add/delete Locations), reachable via **Plan → Locations**. Tapping a Location opens...
- **LocationDetailView.swift** — rename the Location, add/delete its Dive Sites, and jump straight to its Emergency Action Plan (see 1.5).
- **LocationPickerView.swift** — the two-step sheet used from Dive Log entries: pick/add a Location, then pick/add a Dive Site under it (or use the Location with no specific site). Setting a Location/Dive Site here writes `locationID`/`diveSiteID` back onto the `DiveLogEntry`.
- Deleting a Location or Dive Site clears any dangling references on dive log entries (and deletes the Location's Emergency Action Plan, if any) via `AppStore.deleteLocation(_:)` / `deleteDiveSite(_:fromLocationID:)`, rather than leaving orphaned ids around.

**Import note**: Shearwater (LibDCSwift) and Garmin (`.fit`) dive computer downloads only ever report raw GPS coordinates for a dive, never a location or dive site name — so imported dives are not auto-matched to a Location. Assign one manually from the Dive Log entry after importing.

### 1.5 Emergency Action Plans

A tool (under **Plan → Emergency Action Plans**) for building one Emergency Action Plan (EAP) per Location, modeled on [DAN's published EAP guidance](https://dan.org/safety-prevention/diver-safety/divers-blog/how-to-create-an-effective-emergency-action-plan-eap/): how to activate EMS, where emergency equipment is and how to use it, and who does what if something goes wrong.

- **EmergencyActionPlan.swift** — the model, organized to match the on-screen section order: local emergency number (defaults to "911"), nearest hospital and a fully separate Alternate Medical Facility (both name/address/phone -- the Directions field on each is still on the model for back-compat but no longer shown on-screen or in the PDF, see below), Dive Site Location Information for reading off to EMS (address/GPS coordinates + access notes -- cross streets, landmarks, gate codes), on-site equipment availability (Emergency Oxygen/AED/First Aid Kit, each a `Bool` + a location string, rather than just a location string implying presence), three named response-plan roles (Calls EMS / Administers Oxygen & First Aid / Manages Bystanders & Diver Accountability, each a name-or-org + phone pair) plus a free-text "Additional Roles or Notes" catch-all, Communication Channels split by a `DiveAccessType` (Land-Based: cell signal notes + nearest landline/payphone; Boat-Based: VHF channel, boat call sign, marina/harbor master contact, additional boat notes -- plus a free-text catch-all shown either way), local law enforcement (phone, also defaults to "911", plus notes), local transportation (two name+phone slots -- e.g. a taxi company and a rideshare dispatch line), additional notes, and a last-reviewed date (DAN recommends periodic review since facilities/numbers/supplies change). Has a custom `init(from decoder:)` that decodes every field leniently with a fallback (`decodeIfPresent(...) ?? default`), so the plan's fields can keep evolving (as they now have three times) without breaking already-persisted EAPs. The pre-existing free-text `assignedRoles` and `communicationNotes` fields were kept as-is (just relabeled to "Additional Roles or Notes" / "Additional Communication Notes" in the UI) rather than migrated into the new structured fields, so nothing anyone had already typed into them is lost -- same reasoning applied again this pass: `landCommunicationNotes` is now labeled "Cell Signal Notes" but is still the same stored field, and `nearestHospitalDirections`/`alternateMedicalFacilityDirections` were removed from the UI and PDF but left on the model rather than deleted outright.
- **No "nearest recompression chamber" field, intentionally.** Chambers aren't always staffed or available for a given case, so the plan doesn't try to name one — it always routes EMS first, then DAN; DAN and the treating physician are the ones who decide where a diver actually needs to go.
- **DAN's 24/7 Emergency Hotline (+1-919-684-9111)** is a hardcoded constant (`EmergencyActionPlan.danEmergencyHotline`), shown in its own section (below Local Emergency Services) with a tap-to-call link — it is not user-editable.
- **Nearest Hospital / Alternate Medical Facility → Open in Maps**: each address field feeds its own `http://maps.apple.com/?address=...` link (opens the Maps app directly on-device); the separate free-text Directions field that used to sit alongside each was removed from the form and PDF as redundant now that both have a working Maps link. Dive Site Location Information's address field gets the same Open in Maps link.
- **Section order on-screen (and in the PDF)**: Local Emergency Services → DAN Hotline → Nearest Hospital → Alternate Medical Facility → Dive Site Location Information → On-Site Emergency Equipment → Response Plan → Communication Channels → Local Law Enforcement → Local Transportation → Additional Notes → Plan Review. Local Law Enforcement now sits right after Communication Channels rather than up near the top, so the reader's already worked through "how do we talk to each other" before "who else might need to be called."
- **EmergencyActionPlansListView.swift** — lists all saved Locations with an on-file/no-plan indicator; tapping a Location lazily creates a blank plan for it (`AppStore.ensureEAP(forLocationID:)`) and opens it.
- **EAPDetailView.swift** — the edit form, plus a "Mark as Reviewed Today" button that stamps `lastReviewedAt`. A private `contactRow(nameLabel:namePlaceholder:name:phone:)` `@ViewBuilder` helper renders a name/org field plus a tap-to-call phone field, shared by the three Response Plan roles and the two Local Transportation entries rather than repeating that pair six times. A companion `roleHeader(_:)` helper renders each role/category label (the three Response Plan roles, "Primary"/"Secondary" under Local Transportation) with `.listRowBackground(Color.blue.opacity(0.12))` so those heading rows read as labels at a glance rather than blending in with the actual input fields around them. Communication Channels leads with a segmented `Picker("Dive Access", selection:)` bound to `plan.diveAccessType` (`DiveAccessType`, a `String`/`Codable`/`CaseIterable` enum with `.land`/`.boat` cases) that shows only the relevant field set below it -- switching the picker doesn't clear whatever's saved on the other side, so a Location used for both shore and boat dives over time can have both filled in.
- **PhoneFormatting.swift** — formats every phone field on this screen as-you-type ("(555) 123-4567") via the shared `formattedPhoneBinding(_:)` keypath helper in `EAPDetailView.swift` (works unchanged for every new phone field since they're all still flat `String` properties on `EmergencyActionPlan`, not nested). Numbers of 6 digits or fewer (e.g. "911", "112") are left exactly as typed rather than forced into a shape that doesn't fit; the DAN Hotline constant is displayed as static text so it isn't run through this. Also holds the shared `telURL(_:)` helper used for every tap-to-call link on this screen.
- One plan per Location (`AppStore.emergencyActionPlan(forLocationID:)`); also reachable directly from that Location's `LocationDetailView`.
- **EAPPDFRenderer.swift / ShareSheet.swift** — the share-icon toolbar button on EAPDetailView renders the plan to a PDF (plain UIKit text drawing, no HTML/PDFKit round-trip, now commonly two pages given how much the plan holds) and hands it to a `UIActivityViewController`, so it can be printed, AirDropped, or posted on a boat instead of only ever being viewed on-screen. Every section on-screen has a matching block in the renderer, drawn in the same order described above (Local Law Enforcement after Communication Channels, no Directions lines, "DIVE SITE LOCATION INFORMATION" header), and each optional section (Alternate Medical Facility, Dive Site Location Information, Response Plan roles, Communication Channels, Local Transportation) only prints if at least one of its fields is filled in, so an EAP that hasn't been fully filled out doesn't produce a PDF full of empty headers. The Communication Channels block prints only the field set matching the plan's current `diveAccessType`, plus the free-text catch-all if filled in. `ShareSheet.swift`'s `ShareSheetPresenter` presents that activity controller *imperatively* (`UIViewController.present(_:animated:)`) rather than handing it to SwiftUI's `.sheet` as content -- `UIActivityViewController` assumes it's been properly presented, and activities that present something further of their own (Print's AirPrint panel, Mail's compose sheet) lost that context and came up blank when embedded as a `.sheet`'s child controller instead. Attached via `.background(ShareSheetPresenter(items: $shareItems))` on `EAPDetailView`.
- **NotificationScheduler.swift** schedules a local "time to review this EAP" reminder 6 months after `lastReviewedAt` (or 6 months from today if it's never been reviewed) whenever `AppStore.emergencyActionPlans` saves -- see 1.6.

### 1.6 Diver Medical ID

A single personal medical ID card (`DiverMedicalID.swift`, edited via `DiverMedicalIDView.swift`, reachable under **Wallet → Diver Medical ID**) — separate from the per-Location EAPs above, this is what a buddy or EMS would need if *you're* the one who's hurt: name, date of birth, blood type, allergies, medications, medical conditions, an emergency contact, a physician, and a DAN membership number field (shown alongside a reminder of the DAN Emergency Hotline). There's only ever one of these (`AppStore.diverMedicalID: DiverMedicalID?`, lazily created via `AppStore.medicalIDBinding`), unlike EAPs which are one per Location. Its two phone fields use the same `PhoneFormatting.swift` as the EAP screen.

Two separate PDF exports live on this screen, and it's worth being clear about the difference:

- **Typed medical info** — the share-icon toolbar button (same `ShareSheetPresenter` pattern as the EAP PDF export -- see 1.5) renders the fields on this screen fresh to a one-page PDF via `DiverMedicalIDPDFRenderer.swift` and hands it off to print/AirDrop/save.
- **Uploaded WRSTC form** — a "WRSTC Medical Form" section at the top of the screen lets the diver upload an existing PDF of a signed WRSTC (World Recreational Scuba Training Council) medical statement/questionnaire via SwiftUI's `.fileImporter` (`allowedContentTypes: [.pdf]`), rather than re-typing what's already on a signed paper form. The uploaded file is saved to disk via `DocumentStorage.swift` (same directory-of-files-by-filename pattern as `PhotoStorage.swift`, just without the JPEG-specific resizing since documents are opaque binary data) and referenced by `DiverMedicalID.wrstcFormFilename: String?`/`wrstcFormUploadedAt: Date?` (both Optional -- Codable-safe with no custom decoder needed). Once a form is on file, View/Export/Replace/Remove each render as their own full-width `Button` row in the section (not crammed into one `HStack` -- an early version did that and the icon+text labels wrapped illegibly on narrower widths). View opens `DocumentPreview.swift` (a `QLPreviewController` wrapper, deliberately using the classic `UIViewControllerRepresentable` + delegate approach rather than SwiftUI's newer `.quickLookPreview(_:)` modifier, to stay unambiguous about iOS 16 compatibility) inside a `NavigationStack` with an explicit toolbar "Done" button -- QLPreviewController normally gets a dismiss button for free when UIKit presents it directly, but doesn't when it's embedded as a SwiftUI `.sheet`'s content instead (same root cause as the EAP/Diver Medical ID PDF ShareSheet fix in 1.5), and relying on swipe-to-dismiss alone was unreliable since the PDF's own scrolling could capture the gesture. Export reuses the same `ShareSheetPresenter` as the typed-info export, just pointed at the uploaded file's URL instead of a freshly-rendered one; Replace re-opens the file importer and deletes the old file once a new one saves successfully; Remove deletes the file and clears both fields. `.fileImporter`'s returned URL is security-scoped (especially for iCloud Drive/other-app file providers), so `DocumentStorage.save(from:)` brackets its read in `start`/`stopAccessingSecurityScopedResource`.

### 1.7 Certifications

Under **Wallet → Certifications** (`CertificationsListView.swift` / `CertificationDetailView.swift`, model in `Certification.swift`): free-form cards for Open Water, specialty, and professional-level certifications — agency and course name are plain text rather than a fixed enum, since certifying agencies and their catalogs aren't something to hardcode. Each card holds a cert number, date certified, instructor/facility, an optional expiration date, and notes. `Certification.isExpired`/`isExpiringSoon` (60-day window, mirroring Equipment Locker's "due soon" logic) drive a red/orange `StatusBadge` in the list.

Each cert can also hold a photo of the physical card (`Certification.cardImageFilename: String?`, same file-on-disk-by-filename pattern as Dive Log Photos in 1.10, reusing `PhotoStorage.swift`). `CertificationDetailView.swift` shows the saved image at the top of the form with **Take Photo** (`CameraCapture.swift`, a `UIImagePickerController` camera wrapper -- PhotosPicker itself has no camera-capture mode) and **Choose Photo**/**Replace Photo** (`PhotosPicker`) buttons, plus **Remove**. Taking or picking a new photo deletes whatever image previously occupied that slot so nothing's orphaned; `AppStore.deleteCertification(_:)` does the same when the whole certification is deleted. The camera button only appears where `UIImagePickerController.isSourceTypeAvailable(.camera)` is true (e.g. hidden on Simulator). Uses the new `INFOPLIST_KEY_NSCameraUsageDescription` build setting.

Tapping the thumbnail (a small expand-arrows icon in its bottom-right corner hints it's tappable) opens **FullScreenImageViewer.swift** via `.fullScreenCover` -- a reusable black-background image viewer with pinch-to-zoom (`MagnificationGesture`), drag-to-pan once zoomed in, double-tap to toggle between fit and 3x zoom, and a Close button, so a photographed card's fine print is actually readable. It's a standalone, image-agnostic view (`FullScreenImageViewer(image: UIImage)`) rather than something cert-specific, so it can be reused anywhere else in the app a thumbnail needs a full-screen look (e.g. Dive Log Photos in 1.10 don't use it yet, but could).

### 1.8 Reminders (local notifications)

`NotificationScheduler.swift` wraps `UNUserNotificationCenter` for two on-device reminders the app already has the data for but didn't otherwise surface:

- **Equipment service due** — fires at 9am on an Equipment Locker item's `nextServiceDue`. Rescheduled (upsert by a stable per-item identifier) every time `AppStore.equipmentLocker` saves; canceled when the item's deleted.
- **EAP review due** — fires 6 months after an EAP's `lastReviewedAt` (or 6 months from today if never reviewed). Rescheduled every time `AppStore.emergencyActionPlans` saves; canceled when the plan (or its Location) is deleted.

Scheduling is a harmless no-op without permission -- the request just won't display. A **Reminders** toggle on `SettingsView.swift` is what actually prompts for `UNUserNotificationCenter` authorization (`INFOPLIST_KEY_NSLocationWhenInUseUsageDescription`-style permission prompts aren't needed for notifications, but the toggle re-syncs against current data so reminders show up immediately instead of waiting for the next edit).

### 1.9 Dive Site Map & GPS-suggested Locations

- **SavedLocation.swift / DiveSite** — both gained optional `latitude`/`longitude` fields (Codable-safe: plain `Double?`, no custom decoder changes needed). Set either manually (a "Use My Current Location" button in `LocationDetailView.swift`, via `LocationServices.swift`'s `CurrentLocationProvider`, which wraps `CLLocationManager` and requires the `NSLocationWhenInUseUsageDescription` permission already added to the build settings) or automatically from an import (below).
- **DiveSiteMapView.swift** — reachable via a map-icon toolbar button on `LocationsListView.swift`; drops a pin for every Location/Dive Site that has coordinates (skips ones that don't), tapping a pin jumps to that Location's detail screen. Uses the region-based `Map`/`MapAnnotation` API rather than iOS 17's `Map(position:)`, since this project's deployment target is iOS 16.
- **GPS-suggested Locations on import** — `DiveLogEntry` gained optional `gpsLatitude`/`gpsLongitude`, set by both the Bluetooth (`DiveImportMapping`) and Garmin (`GarminDiveMapping`) import mappings whenever the dive computer reported a GPS fix. `LocationServices.swift`'s `LocationSuggestion.suggestName(latitude:longitude:)` reverse-geocodes those coordinates (via `CLGeocoder`, no location permission needed for this one-off lookup) into a human-readable name. The Garmin screen shows this as an "Assign Location: X" button before the one-dive-at-a-time import; the Bluetooth screen is a batch importer with no natural per-dive review step, so it auto-assigns quietly after import and the user can always rename/reassign afterward. Either way, `AppStore.addLocation(name:latitude:longitude:)` dedupes by name and backfills coordinates onto an existing same-named Location rather than creating a duplicate.

### 1.10 Dive Log Photos

`PhotoStorage.swift` saves photos picked via `PhotosPicker` (PhotosUI, no library-access permission needed) as JPEG files (downscaled to a 2000px max dimension) in the app's Documents directory, referencing them from `DiveLogEntry.photoFilenames: [String]?` by filename only -- not embedded as base64 in the JSON blob AppStore persists, so photos can't bloat every launch's decode or eat into CloudSync's iCloud budget (see 1.11). The Dive Log entry's Photos section shows a horizontal scroll of thumbnails with a per-photo delete button; `AppStore.deleteDiveLogEntry(_:)` also deletes the underlying files so nothing's orphaned on disk.

### 1.11 iCloud Sync (currently disabled -- personal team)

`CloudSync.swift` mirrors every array `AppStore` persists (checklists, saved history, equipment, dive log, locations, buddies, EAPs, certifications, the medical ID card, and the three default-unit settings) to `NSUbiquitousKeyValueStore` alongside the existing `UserDefaults` storage -- a lightweight sync layer chosen over a full CloudKit/Core Data migration to keep the change additive rather than rewriting the whole persistence layer. `AppStore.init()` prefers the iCloud copy of each key on launch (falling back to the local UserDefaults copy, and pushing that up to iCloud if so, e.g. on first run after adding this feature) and listens for `NSUbiquitousKeyValueStore.didChangeExternallyNotification` to pull in changes pushed from the user's other devices while the app's open.

**Currently inert on purpose.** A personal (free) Apple ID team can't enable the iCloud capability, so `CODE_SIGN_ENTITLEMENTS` was removed from both build configurations to keep the project buildable/signable on a personal team. `DiveCheck.entitlements` (with the `com.apple.developer.ubiquity-kvstore-identifier` key) is still sitting in the project, just unreferenced by any build setting. With no entitlement, every `CloudSync` call is a harmless no-op -- the app runs exactly as it did before this feature (UserDefaults-only, this device only); nothing crashes or errors, it just doesn't sync.

**To re-enable once on a paid Apple Developer account:** in Xcode, select the DiveCheck target → Signing & Capabilities → "+ Capability" → iCloud → check "Key-value storage" (this both re-adds `CODE_SIGN_ENTITLEMENTS` pointing at `DiveCheck.entitlements` and registers the capability on the App ID in your developer account -- doing it through Xcode's UI rather than hand-editing the build setting back in is what actually provisions it). No code changes needed; `CloudSync.swift`, `AppStore.swift`'s load/save wiring, and the entitlements file are all still in place.

Tradeoffs worth remembering once it's back on: `NSUbiquitousKeyValueStore` caps out around 1MB total across all keys, which is why Dive Log photos (1.10) deliberately stay device-local instead of syncing, and why this only became viable once dive log entries store photos as separate files rather than inline base64.

### 1.12 Dive Computers

`DiveComputer.swift` / `AppStore.diveComputers` -- a saved record per physical dive computer, reachable via **Dives → Dive Computers** (`DiveComputersListView.swift` / `DiveComputerDetailView.swift` for renaming). This exists because the original design (just stamping `DiveLogEntry.sourceDevice` with whatever raw name the import reported) had a real bug: Bluetooth peripherals don't always report a usable `.name` (falls back to a generic "dive computer" string), and Garmin's `productName`/`manufacturer` fallback chain can return the same generic value for two different physical watches of the same model -- so Statistics' "By Dive Computer" breakdown would silently collapse multiple computers into one bucket instead of listing them separately.

- **`AppStore.resolveDiveComputer(matchKey:detectedModelName:)`** is the fix: it matches (or creates) a `DiveComputer` by a stable **hardware identifier** rather than the display name -- the paired `CBPeripheral.identifier` (a UUID stable for this iOS install) for Bluetooth imports, or the FIT file's device serial number for Garmin imports (falling back to a model-name key only when no serial number is present, e.g. older FIT files -- two same-model Garmin units without serials still won't be distinguished in that case). If the detected model name collides with an already-saved computer's name, a "(2)", "(3)", etc. suffix disambiguates it automatically.
- **`DiveLogEntry.sourceDeviceID: UUID?`** references the resolved computer; the older `sourceDevice: String?` stays around purely as a fallback label for entries imported before this feature existed. `AppStore.displayDeviceName(for:)` is the single place that resolves "what to show" for an entry: the saved computer's (renamable) name, else the legacy string, else "Manually Logged" -- used by the Dive Log list/detail screens and by Statistics' "By Dive Computer" grouping.
- **Renaming is retroactive.** Since Statistics/the Dive Log both look up the name live via `sourceDeviceID`, renaming a computer (e.g. "Petrel 3" → "Petrel 3 - Backup" to tell two units apart) immediately updates everywhere it's shown -- no re-import needed.
- **Manually-logged dives** can still note which computer was used via a "Source Computer" row on `DiveLogDetailView.swift` (opens `DiveComputerPickerView.swift`, which can also add a brand-new computer inline) -- useful for a computer you own but haven't wired up Bluetooth import for, or for fixing up an entry that only has the legacy `sourceDevice` string.
- **Known gap:** entries imported before this feature (only a `sourceDevice` string, no `sourceDeviceID`) aren't automatically backfilled to a `DiveComputer` record -- there's no way to recover the original hardware identifier after the fact. Reassign them manually via the Source Computer picker if you want them grouped with newer imports from the same unit.

### 1.13 Calculators

`CalculatorsListView.swift`, reachable from the home screen's **Calculators** row -- ten single-purpose, stateless gas-planning/safety tools, all standalone `Form` screens using shared `NumberWheel`/`ResultRow` components (`LabeledFields.swift`) and hardcoded to imperial units (ft/psi/cu ft). Deliberately excludes anything that computes actual no-decompression limits or deco stops -- that's left to a certified dive computer rather than baked into the app. The list screen groups them into three `Section`s by what question they answer, rather than one flat list:

- **Gas Mix & Exposure Limits** — MOD, PPO2, Best Mix, EAD, END, CNS O2 Toxicity: is this mix/depth/time combination within safe operating limits?
- **Gas Consumption & Reserves** — SAC/RMV, Gas Time Remaining, Minimum Gas: how much gas will/did I use, and how much do I need in reserve?
- **Weighting** — Weight Check: how much lead do I need to be neutrally buoyant?

- **EADCalculatorView.swift** — Equivalent Air Depth: the depth that would feel equally narcotic on air as a given Nitrox mix at a given depth. Pairs with MOD.
- **ENDCalculatorView.swift** — Equivalent Narcotic Depth: EAD's Trimix counterpart -- accounts for helium (not narcotic) alongside O2 and N2. A "Count O2 as Narcotic" toggle (default on) switches between the modern, more conservative convention (END = (Depth + 33) × (FN2 + FO2) − 33, which correctly reduces to actual depth for air itself) and the older N2-only convention that shares EAD's `/0.79` structure. Both reduce to EAD's formula at 0% helium.
- **GasTimeCalculatorView.swift** — Gas Time Remaining / Turn Pressure: the forward-looking counterpart to SAC/RMV -- given an RMV, depth, tank info, current pressure, and a reserve, shows minutes of gas left and what pressure to turn the dive at.
- **MinimumGasCalculatorView.swift** — Minimum Gas ("Rock Bottom"): gas reserve needed for a set number of divers sharing one supply to solve a problem at depth and make a controlled ascent (with a safety stop) back to the surface, using a stressed breathing rate. Standard technical-diving gas-planning material, not a decompression calculation.
- **CNSOxygenCalculatorView.swift** — CNS Oxygen Toxicity %: looks up the NOAA single-exposure oxygen time limit for a dive's PPO2 (rounded up to the next table step, the conservative direction) and expresses bottom time as a percentage of it. An optional "Starting CNS %" field lets a second dive of the day carry over a running total; it doesn't model surface-interval decay itself.
- **WeightCheckCalculatorView.swift** — Weight Check: starting weight-belt estimate built from body weight, body build, diver experience, exposure suit, neoprene accessories, water type, cylinder setup, and worn hardware, with an itemized breakdown (Exposure Baseline, Neoprene Accessories, Water Adjustment, Body Build, Experience Margin, Cylinder/Doubles, Hardware Worn) shown alongside the total. Suit baselines follow the PADI Peak Performance Buoyancy starting-point percentages as published in Scuba Diving Magazine's buoyancy calculator guide (swimsuit is a flat few pounds, 3mm is 5% of body weight, 5mm/7mm is 10%, drysuits are 10% plus an undergarment allowance split into light/medium/heavy tiers) rather than the flatter, higher estimate this calculator originally shipped with (which unconditionally applied the 10% baseline meant for 5mm+ suits to every suit thickness, then stacked a flat lb addition on top). Line-item structure (separate Neoprene Accessories, Cylinder Offset, Hardware Offset) follows Dive With Frank's DWF Weight Estimator. Body Build (`BodyBuild` enum) and Diver Experience (`DiverExperience` enum) are both small, clearly-labeled offsets rather than precise physics -- Experience in particular is a practical breath-control margin, not a buoyancy calculation, and is called out as skippable in the footer. Hood/gloves are independent toggles (+1 lb each). Tank Material (`TankMaterial` enum) now pairs with a "Doubles (Backmount)" toggle -- doubles double each cylinder's material offset and add a flat rigging offset for the manifold/bands. A worn backplate/hardware weight field subtracts from the estimate (it's ballast already on the diver, not something to add lead on top of). All enums are defined in this file and none are persisted -- the calculator is stateless like the others in 1.13.

---

## 2. Architecture

- **UI**: SwiftUI, `NavigationStack` with a single `[ChecklistRoute]` path array owned by `ContentView`, driving all navigation (both `NavigationLink(value:)` taps and programmatic pushes, e.g. "create a new dive log entry, then navigate straight into it").
- **State**: one `AppStore` (`ObservableObject`) holds all app data as `@Published` arrays. Each feature's data is a separate array with its own key, encoded/decoded as JSON via `Codable`, persisted through `CloudSync.swift` (UserDefaults + mirrored to iCloud Key-Value storage -- see 1.11) rather than talking to `UserDefaults` directly:
  - `categories: [DiveCategory]` — the checklist tree (`DiveCheck.categories.v2`)
  - `savedChecklists: [SavedChecklist]` — checklist history snapshots (`DiveCheck.history.v1`)
  - `equipmentLocker: [EquipmentItem]` (`DiveCheck.equipment.v1`)
  - `diveLogEntries: [DiveLogEntry]` (`DiveCheck.divelog.v1`)
  - `savedLocations: [SavedLocation]` (`DiveCheck.locations.v1`) — each holds a nested `diveSites: [DiveSite]` array; `SavedLocation` has a custom `init(from decoder:)` so Locations saved before Dive Sites existed (just an id + name) still decode instead of failing.
  - `savedBuddies: [DiveBuddy]` (`DiveCheck.buddies.v1`)
  - `emergencyActionPlans: [EmergencyActionPlan]` (`DiveCheck.eap.v1`) — one per Location, looked up by `locationID`.
  - `certifications: [Certification]` (`DiveCheck.certifications.v1`)
  - `diverMedicalID: DiverMedicalID?` (`DiveCheck.medicalID.v1`) — the one personal medical ID card, nil until filled in.
  - `diveComputers: [DiveComputer]` (`DiveCheck.divecomputers.v1`) — one per physical dive computer, matched at import time by a stable hardware identifier rather than display name (see 1.12).
- **Checklist content versioning**: `SeedData.contentVersion` is compared against a value stored on-device (`DiveCheck.seedVersion`, intentionally UserDefaults-only/not synced -- it's a per-install implementation detail, not user data). When the bundled starter-checklist content changes, bump `contentVersion` so the app reseeds automatically — otherwise a device with existing saved data would never see updated starter content. This only applies to the checklist tree; Equipment Locker, Dive Log, Locations, Buddies, Emergency Action Plans, Certifications, and the Diver Medical ID start empty and have no seed content to version.
- **Editing pattern**: leaf views (e.g. `ChecklistDetailView`, `EquipmentDetailView`, `DiveLogDetailView`) take a `Binding` into the store (via helper methods like `AppStore.binding(categoryID:checklistID:)`, `equipmentBinding(for:)`, `diveLogBinding(for:)`), so edits flow directly back into the published array and persist automatically via each store's `didSet`.
- **Recursive checklist items**: `ChecklistItem` contains `subItems: [ChecklistItem]`, rendered by a self-recursive `ChecklistItemRow` view — this is how the Prism 2 checklists' numbered/lettered nested steps work at arbitrary depth.

### File structure

```
DiveCheck/
  DiveCheckApp.swift          — @main app entry point
  ContentView.swift           — home screen, navigation path & route dispatch

  Models/
    Route.swift                — ChecklistRoute navigation enum
    ItemField.swift             — recorded-value field on a checklist item (text or choice)
    ChecklistItem.swift          — one checklist step (label, text, note, fields, sub-items)
    Checklist.swift              — named checklist (header fields + items)
    DiveSubcategory.swift        — equipment "unit" within a category (e.g. Hollis Prism 2)
    DiveCategory.swift            — top-level home-screen grouping
    SavedChecklist.swift          — frozen checklist snapshot for History
    Equipment.swift               — EquipmentCategory, ServiceRecord, EquipmentItem
    DiveLogEntry.swift            — DiveLogEntry + all its supporting enums (units, conditions, etc.)
    SavedLocation.swift            — SavedLocation (name + nested DiveSite array), both with optional lat/long
    DiveBuddy.swift                 — saved dive buddy
    EmergencyActionPlan.swift        — one EAP per Location + the DAN hotline constant
    Certification.swift              — a saved diver certification card
    DiverMedicalID.swift              — the one personal medical ID card
    DiveComputer.swift                — one saved physical dive computer (see 1.12)

  Store/
    AppStore.swift               — the ObservableObject holding + persisting everything
    SeedData.swift                — starter checklist content + content-version gate
    CloudSync.swift                — UserDefaults + iCloud Key-Value Storage mirroring (see 1.11)

  Views/
    ContentView.swift's siblings, plus:
    CategoryDetailView.swift, SubcategoryDetailView.swift
    ChecklistDetailView.swift, ChecklistItemRow.swift
    AddChecklistItemView.swift, AddChecklistView.swift, AddSubcategoryView.swift
    HistoryListView.swift, SavedChecklistDetailView.swift
    EquipmentLockerListView.swift, EquipmentDetailView.swift, AddEquipmentView.swift, AddServiceRecordView.swift
    DiveLogListView.swift, DiveLogDetailView.swift, EquipmentPickerView.swift, BuddyPickerView.swift, LocationPickerView.swift
    BulkEditDiveLogView.swift, DiveLogBulkEdit.swift  — Admin Mode bulk edit (see 1.3)
    LocationsListView.swift, LocationDetailView.swift, DiveSiteMapView.swift
    EmergencyActionPlansListView.swift, EAPDetailView.swift, EAPPDFRenderer.swift
    DiverMedicalIDView.swift, DiverMedicalIDPDFRenderer.swift
    CertificationsListView.swift, CertificationDetailView.swift
    DiveComputersListView.swift, DiveComputerDetailView.swift, DiveComputerPickerView.swift
    BluetoothDiveImportView.swift, GarminFITImportView.swift, GarminFITParser.swift
    PlanMenuView.swift, DivesMenuView.swift, EquipmentMenuView.swift, WalletMenuView.swift  — four of the six home-screen menu levels (Calculators and Settings are their own top-level screens, not menu-only)
    PlaceholderToolView.swift        — reusable "coming soon" screen, currently unused (see Navigation structure above)
    SettingsView.swift                — default units + Reminders toggle
    StatisticsView.swift              — dive stats rolled up across the whole Dive Log
    MaintenanceScheduleView.swift      — Equipment Locker items grouped by service urgency
    ServiceHistoryView.swift           — combined purchase-date + service-record log across all gear
    PhoneFormatting.swift              — as-you-type phone number formatting + telURL helper (EAP, Diver Medical ID)
    LocationServices.swift            — reverse-geocoding for import suggestions + CurrentLocationProvider
    NotificationScheduler.swift        — local reminders for equipment service + EAP review (see 1.8)
    SACCalculation.swift               — SAC/RMV math shared by the Dive Log's Calculate button and SACCalculatorView
    PhotoStorage.swift                 — saves/loads/deletes photo files in Documents (Dive Log photos, Certification card images)
    CameraCapture.swift                — UIImagePickerController camera wrapper (Certification card photo capture, see 1.7)
    DocumentStorage.swift              — saves/loads/deletes uploaded document files in Documents (WRSTC medical form PDF, see 1.6)
    DocumentPreview.swift              — QLPreviewController wrapper for viewing an uploaded document in a sheet (WRSTC medical form PDF, see 1.6)
    ShareSheet.swift                   — UIActivityViewController wrapper (EAP PDF share, Diver Medical ID PDF share)
    LabeledFields.swift             — reusable LabeledTextField / LabeledMultilineField / StatusBadge
    UnitConversion.swift            — feet/meters, °F/°C, lbs/kg conversion helpers

  DiveCheck.entitlements          — iCloud Key-Value Storage capability, currently unreferenced/disabled (see 1.11)
  Assets.xcassets/               — AppIcon (dive-flag-fin + checkmark design) + AccentColor
```

Three files — `GearItem.swift`, `ChecklistViewModel.swift`, `AddItemView.swift` — are leftovers from the very first version of the app (before the multi-category redesign). They're wrapped in `#if false` and excluded from the Xcode project entirely; they're harmless and can be deleted manually.

---

## 3. Known Limitations / Ideas for Later

- **Equipment Locker is intentionally independent** from the checklist Units (e.g. an owned "Hollis Prism 2" doesn't link to its checklists) — this was a deliberate choice to keep the two systems simple and decoupled.
- **Signing**: `CODE_SIGN_STYLE` is Automatic with `DEVELOPMENT_TEAM` already set. **iCloud Sync is currently disabled** (1.11) because a personal/free Apple ID team can't enable the iCloud capability -- `CODE_SIGN_ENTITLEMENTS` was removed from both build configurations so the project stays buildable on a personal team. Re-enable via Signing & Capabilities → "+ Capability" → iCloud → "Key-value storage" once on a paid account; no code changes needed.
- **iPad support (`TARGETED_DEVICE_FAMILY = "1,2"`)** runs correctly (single-column `NavigationStack`, adaptive layouts, no hardcoded iPhone-only sizing found in a pass over the codebase) but isn't iPad-*optimized* — it doesn't use `NavigationSplitView` for a two/three-column layout the way a "real" iPad app would. That's a bigger, separate redesign than "make it run on iPad."
- **Dive Site Map pins require coordinates**, which aren't set automatically for a Location added by name alone (the common case) -- only for ones set manually via "Use My Current Location" or auto-filled from a GPS-tagged import.
- **iCloud sync (`CloudSync.swift`) is Key-Value Storage, not CloudKit** -- see 1.11 for the ~1MB budget and what that does and doesn't cover (notably, not photos).

---

## 4. Getting Started

1. Unzip and open `DiveCheck.xcodeproj` in Xcode 15 or later.
2. Confirm your development team is selected under the target's Signing & Capabilities tab (already set to one team, but re-check if this is opened under a different Apple ID).
3. iCloud Sync (1.11) is off by default since it needs a paid Apple Developer account -- skip unless/until you're on one. To turn it on: Signing & Capabilities → "+ Capability" → iCloud → check "Key-value storage."
4. Add the two Swift Package dependencies described in section 5 below (required for the dive-computer import feature to compile).
5. Build and run on a simulator or device running iOS 16+. Bluetooth import and "Use My Current Location" both require a physical device — the simulator has no Bluetooth radio and simulated location is unreliable for this.

---

## 5. Dive Computer Import (Bluetooth / Garmin .fit)

Reachable from the Dive Log screen's "+" menu: **Import via Bluetooth (Shearwater, Aqualung, Oceanic, and more)** and **Import from Garmin (.fit file)**.

- **Any BLE-capable dive computer LibDCSwift/libdivecomputer supports** — `BluetoothDiveImportView.swift` scans for and connects directly to the dive computer over Bluetooth LE and downloads dives, using the [LibDCSwift](https://github.com/deepsealabs/libdc-swift) package, which wraps the real `libdivecomputer` C library (the same reverse-engineered-but-battle-tested protocol implementations used by Subsurface and other real dive-log apps) rather than reimplementing any protocol from scratch. This screen is entirely brand-agnostic — device detection, connection, and download all go through `DeviceConfiguration`/`DiveLogRetriever`, which already know about dozens of models across many brands (`DeviceConfiguration.supportedModels` in the LibDCSwift package is the source of truth). As of LibDCSwift 1.9.0 that list includes:
  - **Shearwater** — Perdix, Perdix AI, Perdix 2/3, Petrel, Petrel 2/3, Peregrine, Peregrine TX, Teric, Tern, NERD 2. (Only brand actually tested against this screen so far, on a real Petrel 3.)
  - **Aqualung** — i770R, i550C, i300C, i200C, i330R, i330R Console.
  - **Oceanic** — Geo 4.0, Veo 4.0, Pro Plus 4, Atom 3.1, Geo Air.
  - **Sherwood** — Wisdom 3, Sage. **Apeks** — DSX.
  - **Suunto** — EON Steel, EON Core, EON Steel Black, D5.
  - **Scubapro/Uwatec** — G2, G2 TEK, G2 Console, G2 HUD, G3, Aladin A1/A2, Luna 2.0/2.0 AI.
  - **Heinrichs Weikamp** — OSTC 2, OSTC 2 TR, OSTC 3, OSTC 4, OSTC Plus, OSTC Sport.
  - **Mares** — Icon HD, Puck Pro, Puck 4, Smart, Smart Air, Quad, Quad Air, Genius.
  - **Cressi** — Goa, Cartesio, Leonardo 2.0, Donatello.
  - **Divesoft** — Freedom, Liberty. **Halcyon** — Symbios. **Seac** — Screen. Plus DeepSix Excursion, Deepblu Cosmiq+, Oceans S1, McLean Extreme, and the Dive System/Ratio iDive line.

  Oceanic/Aqualung/Sherwood computers use a distinct BLE advertising quirk (they broadcast their serial number as the device name, e.g. `"FH020399"`, rather than a product name) — `DeviceConfiguration.resolveOceanicBLEName(_:)` decodes the model out of the first two characters before falling back to the normal name-based lookup, so those brands still auto-detect correctly.

  **Important caveat**: this only reaches dive computers with Bluetooth LE. Older Oceanic computers that only ever had USB or infrared docking stations (Atom, Atom 2.0, Pro Plus 2/3, VT3, VTX, etc.) cannot be reached from an iPhone at all — iOS has no generic USB-serial or infrared support the way a desktop Subsurface install would. If a dive computer isn't in the list above, it either isn't supported by libdivecomputer yet or doesn't have Bluetooth.
- **Garmin** — Garmin does not allow third-party apps to pair directly over Bluetooth with a Descent watch; that channel is reserved for the official Garmin Connect app. `GarminFITImportView.swift` instead lets you pick a `.fit` file (exported from Garmin Connect, or copied off the watch over USB) and parses it with `GarminFITParser.swift`, which is a vendored (copied directly into this target, not an SPM dependency — see that file's header comment for why) copy of the parsing logic from [fit-parser-swift](https://github.com/deepsealabs/fit-parser-swift), built on top of Garmin's own official [FIT Objective-C SDK](https://github.com/garmin/fit-objective-c-sdk).

Both screens map the imported dive into a normal, fully-editable `DiveLogEntry` (depth/temperature are left in the metric units the dive computer/FIT file reports, with the entry's unit toggles set to match) and skip re-importing a dive that already exists in the log at the same date/time.

### Required package dependencies (add once, in Xcode)

These can't be added by editing `project.pbxproj` by hand safely, so they need to be added once via Xcode's UI:

1. **File > Add Package Dependencies…**
2. Enter `https://github.com/deepsealabs/libdc-swift` → in the "Choose Package Products" list, add **only LibDCSwift** to the DiveCheck target. **Leave `LibDCBridge` unchecked / set to "None."** The package also publishes a separate dynamic-library product also named `LibDCBridge` — if that gets added to the target directly (easy to do by accident, since Xcode lists it right next to LibDCSwift with its own checkbox), the same underlying code ends up linked twice, once statically (pulled in transitively through LibDCSwift) and once dynamically (the direct product) — see the troubleshooting note below for the exact error this causes and how to undo it.
3. **File > Add Package Dependencies…** again.
4. Enter `https://github.com/garmin/fit-objective-c-sdk` → add the **FIT** product to the DiveCheck target. Do **not** add `fit-parser-swift` as a package — its parsing logic is vendored directly into this project as `GarminFITParser.swift` instead (see "Known limitations" below for why), so this app only needs Garmin's underlying SDK, not that wrapper package.
5. Build. Xcode will resolve both packages over the network the first time.

**If you already added `fit-parser-swift`** (e.g. from an earlier version of these instructions), remove it: **Project navigator > select the DiveCheck project (blue icon) > Package Dependencies tab > select `fit-parser-swift` > click `−`**. Then also check the DiveCheck target's **General > Frameworks, Libraries, and Embedded Content** list for any leftover `FITParser` or `FITParserCLI` rows and remove those too before adding `fit-objective-c-sdk` in its place.

### Troubleshooting

**Build error: "Swift package target 'LibDCBridge' is linked as a static library by 'DiveCheck' and 'LibDCBridge-product', but cannot be built dynamically because there is a package product with the same name."**

This means the `LibDCBridge` product ended up directly linked to the DiveCheck target in addition to `LibDCSwift` (see step 2 above — nothing in this app's code ever does `import LibDCBridge` directly, so it should never be linked directly, only pulled in transitively). To fix it:

1. Select the project in the navigator, select the **DiveCheck** target, open the **General** tab.
2. Under **Frameworks, Libraries, and Embedded Content**, find `LibDCBridge` in the list and remove it (select it, click the **−** button). Leave `LibDCSwift` in place.
3. **Product > Clean Build Folder** (⇧⌘K), then build again.

**Build error: "'FITParser' is missing a dependency on 'SwiftFIT' because dependency scan of Swift module 'FITParser' discovered a dependency on 'SwiftFIT'."**

This is a bug in the `fit-parser-swift` package itself, not this project: its `FITParser.swift` does `import SwiftFIT` directly, but its `Package.swift` only declares a dependency on the combined `FIT` product (which bundles the `SwiftFIT` and `ObjcFIT` targets together) rather than declaring an explicit dependency on the `SwiftFIT` module by name. Older/looser toolchains let this slide; newer Xcode/Swift versions do stricter module-level dependency-graph validation and reject it. The fix already applied in this project is to not depend on `fit-parser-swift` at all — its logic is vendored directly into `GarminFITParser.swift`, which sits in the same target as the rest of the app and only needs the official `fit-objective-c-sdk` package (see the setup steps above). If you still see this error, it means `fit-parser-swift` is still added as a package dependency somewhere — remove it per the "If you already added fit-parser-swift" note above.

**Crash on launch/connect: "State restoration of CBCentralManager is only allowed for applications that have specified the 'bluetooth-central' background mode."**

LibDCSwift's `CoreBluetoothManager` initializes its `CBCentralManager` with a restore identifier (`CBCentralManagerOptionRestoreIdentifierKey`) so a dive-log download can keep running / resume if the app gets backgrounded mid-transfer. iOS requires the app to declare the `bluetooth-central` background mode before it'll allow that, or it crashes immediately on the first `CBCentralManager` init.

An earlier version of this project tried to fix this by hand-writing `INFOPLIST_KEY_UIBackgroundModes = "bluetooth-central";` directly into `project.pbxproj`. That didn't reliably work (array-valued Info.plist keys via the `INFOPLIST_KEY_*` build-setting shorthand are undocumented enough that hand-writing them isn't trustworthy, and it's not worth guessing at project-file syntax when Xcode has a purpose-built UI for exactly this), so that line has been removed. **Add the capability through Xcode's UI instead:**

1. Select the DiveCheck target > **Signing & Capabilities** tab.
2. Click **+ Capability** (top left), search for **Background Modes**, double-click to add it.
3. Check **Uses Bluetooth LE accessories**.
4. If you still see the crash after that, it's very likely a stale build: quit Xcode, delete DerivedData for this project (Xcode > Settings > Locations tab > click the arrow next to the DerivedData path to reveal it in Finder, then delete the `DiveCheck-*` folder inside — a plain Clean Build Folder doesn't always invalidate a cached Info.plist), then reopen and rebuild.

**Duplicate entries under Frameworks, Libraries, and Embedded Content (e.g. `LibDCSwift` or `FITParser` listed twice).** Removing and re-adding a package while troubleshooting the errors above can leave a stray duplicate row behind rather than cleanly replacing the old one. Open the DiveCheck target's **General > Frameworks, Libraries, and Embedded Content** list and check for repeats — keep one `LibDCSwift` row, and remove `FITParser`/`FITParserCLI` entirely per the note above.

**Screen gets stuck on "Downloading dive N…" even though the dive computer finished sending and eventually drops the connection.** Confirmed on a real Shearwater Petrel 3 (22 dives) — the console log shows LibDCSwift's own `DiveLogRetriever` logging `✅ Download completed` and `📋 Finalized dive numbering`, i.e. the download genuinely finished, but the screen never updates. Root cause: LibDCSwift's 0.25s progress-timer callback and its completion handler both land on the main queue via their own separate nested `DispatchQueue.main.async` calls, and there's a race right at the end of a transfer where a straggling progress tick that was already in flight gets applied *after* the completion state, flipping `diveViewModel.progress` back from `.completed` to `.inProgress` with no further update ever coming to unstick it. Fixed in `BluetoothDiveImportView.swift` by capturing the terminal result once, inside our own `completion` closure, into a local `downloadOutcome` value that the view trusts instead of reading the live (and later-clobberable) `diveViewModel.progress` directly — see the comment on `downloadOutcome`'s declaration for the full ordering argument for why that single read is race-free.

### Known limitations / not yet tested

- Confirmed working end-to-end on a real Shearwater Petrel 3 over Bluetooth (connect, download, 22-dive import). Garmin `.fit` file import has not yet been tested against a real exported file.
- The Bluetooth screen currently relies on LibDCSwift's automatic device-family detection from the advertised BLE name; there's no manual "pick your exact model" fallback UI yet if that detection guesses wrong (LibDCSwift supports forcing a specific model — see `DeviceConfiguration.openBLEDevice(forcedModel:)` — this would be a natural next addition).
- Gas mix / tank pressure fields are a best-effort mapping (pressures are converted from bar to psi to match the rest of the app); double-check them against the dive computer's own display after importing.

No other external dependencies are used — everything else is built with stock SwiftUI and Foundation.
