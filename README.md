# DiveCheck

A native iOS app (SwiftUI, iOS 16+) for scuba divers: pre-dive checklists organized by discipline, an equipment locker for tracking owned gear and service history, a detailed dive log, a PADI/SDI certification training tracker (including a full multi-candidate PADI Divemaster program), and a set of dive-planning calculators.

Single-user, offline-first: most data lives on-device via `UserDefaults`, with a smaller set of personal records (dive log, equipment, locations, buddies, EAPs, certifications, dive computers, medical ID, preferences) additionally mirrored to iCloud — see `DiveCheck/CloudSync.swift`.

See [`PROJECT.md`](./PROJECT.md) for the full feature reference (every screen, data model, and behavior in the app).

## Building

Open `DiveCheck.xcodeproj` in Xcode.

- Bundle identifier: `com.billmitlehner.divecheck.personal`
- Deployment target: iOS 16.0
- Swift 5.0
- No external dependencies (no CocoaPods/SPM packages) — everything is built on Apple's own frameworks (SwiftUI, Foundation, PassKit-adjacent, EventKit/UserNotifications, CoreBluetooth for dive computer import, MapKit for the dive site map, PDFKit for EAP/medical ID document generation).

## Project layout

- `DiveCheck/` — all Swift source, organized as one file per model/view (no nested folders). Seed content for the starter checklist tree, training agencies, and the PADI Divemaster program lives in `SeedData.swift`, `TrainingSeedData.swift`, and `DivemasterSeedData.swift` respectively.
- `DiveCheck.xcodeproj/` — the Xcode project file.
- `PROJECT.md` — the living feature/architecture reference for the app.
