import SwiftUI
import UIKit

/// Default units applied to newly-created Dive Log entries. Purely a
/// starting point -- every entry still has its own per-dive unit toggles
/// (see DiveLogDetailView), and changing a default here never touches
/// dives already logged.
struct SettingsView: View {
    @ObservedObject var store: AppStore
    @ObservedObject private var syncManager = SyncManager.shared
    @State private var remindersAuthorized = false
    @State private var didCheckAuthorization = false
    @State private var isShowingProfessionalInfoSheet = false
    @State private var googleSignInError: String?

    /// Whether the diver has already provided the agency/professional
    /// number gate required to turn Training on -- see `trainingToggleBinding`.
    private var hasProfessionalInfo: Bool {
        !(store.trainingProfessionalAgency ?? "").isEmpty && !(store.trainingProfessionalNumber ?? "").isEmpty
    }

    /// Intercepts turning Training on: if the diver hasn't provided their
    /// certifying agency and professional/instructor number yet, this
    /// opens the entry sheet instead of flipping the toggle immediately.
    /// The sheet itself sets `isTrainingSectionEnabled = true` once saved.
    /// Turning Training off always goes straight through.
    private var trainingToggleBinding: Binding<Bool> {
        Binding(
            get: { store.isTrainingSectionEnabled },
            set: { newValue in
                if newValue && !hasProfessionalInfo {
                    isShowingProfessionalInfoSheet = true
                } else {
                    store.isTrainingSectionEnabled = newValue
                }
            }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle("Reminders", isOn: Binding(
                    get: { remindersAuthorized },
                    set: { enabled in
                        if enabled {
                            Task {
                                remindersAuthorized = await NotificationScheduler.requestAuthorization()
                                // Re-schedule against whatever's already set so
                                // reminders show up right away instead of
                                // waiting for the next edit.
                                if remindersAuthorized {
                                    for item in store.equipmentLocker {
                                        NotificationScheduler.scheduleEquipmentReminder(itemID: item.id, name: item.name, dueDate: item.nextServiceDue)
                                    }
                                    for plan in store.emergencyActionPlans {
                                        let locationName = store.location(withID: plan.locationID)?.name ?? ""
                                        NotificationScheduler.scheduleEAPReviewReminder(planID: plan.id, locationName: locationName, lastReviewedAt: plan.lastReviewedAt)
                                    }
                                }
                            }
                        } else {
                            for item in store.equipmentLocker {
                                NotificationScheduler.cancelEquipmentReminder(itemID: item.id)
                            }
                            for plan in store.emergencyActionPlans {
                                NotificationScheduler.cancelEAPReviewReminder(planID: plan.id)
                            }
                            remindersAuthorized = false
                        }
                    }
                ))
            } header: {
                Text("Reminders")
            } footer: {
                Text("Local notifications for Equipment Locker items due for service and Emergency Action Plans due for their periodic review. Turning this off if you'd previously granted permission in Settings > Notifications just cancels the reminders already scheduled -- you can turn it back on any time.")
            }

            Section {
                Picker("Depth", selection: $store.defaultDepthUnit) {
                    ForEach(DepthUnit.allCases) { unit in
                        Text(unit == .feet ? "Feet" : "Meters").tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                Picker("Temperature", selection: $store.defaultTemperatureUnit) {
                    ForEach(TemperatureUnit.allCases) { unit in
                        Text(unit == .fahrenheit ? "°F" : "°C").tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                Picker("Weight", selection: $store.defaultWeightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit == .lbs ? "lbs" : "kg").tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Default Units")
            } footer: {
                Text("Used to pre-fill a new Dive Log entry's unit toggles. You can still change units per-dive at any time -- switching them there converts the numbers already entered, it doesn't just relabel them. Existing dive log entries aren't affected by changing these defaults.")
            }

            Section {
                Toggle("Admin Mode", isOn: $store.isAdminModeEnabled)
            } header: {
                Text("Admin Mode")
            } footer: {
                Text("Adds a Select button to the Dive Log for choosing multiple dives at once -- Select All, bulk delete, and bulk-editing shared fields like Location, Site Type, and Entry Type across everything selected. Off by default since these actions touch a lot of dives at once.")
            }

            Section {
                Toggle("Training", isOn: trainingToggleBinding)
                if hasProfessionalInfo {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "person.text.rectangle.fill")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.trainingProfessionalAgency ?? "")
                            Text("Professional # \(store.trainingProfessionalNumber ?? "")")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Edit") {
                            isShowingProfessionalInfoSheet = true
                        }
                        .font(.footnote)
                    }
                    .font(.footnote)
                }
            } header: {
                Text("Training")
            } footer: {
                Text("Shows a Training row on the main menu with certification skill requirements grouped by agency and certification level -- a checklist per skill with the official performance requirement noted underneath. This section is meant for instructors and divemasters tracking certification requirements, so turning it on requires entering the agency you're credentialed with and your professional/instructor number. Turning it off just hides the menu entry; nothing already checked off is lost.")
            }

            Section {
                backupSyncSection
            } header: {
                Text("Backup & Sync")
            } footer: {
                Text("Automatically backs up everything -- checklists, equipment, dive log, certifications (including uploaded photos and PDFs), Emergency Action Plans, Diver Medical ID, and training records -- to the cloud account you choose, so it's there if you get a new phone or want it on another device. Off by default. Picking iCloud Drive uses whichever iCloud account this device is signed into; Google Drive needs its own sign-in.")
            }

            // Read-only record of the safety disclaimer the diver had to
            // accept before using the app -- see DisclaimerView.swift.
            // Nothing here is editable; there's no way to revoke
            // acknowledgment from Settings.
            Section {
                Text(DisclaimerView.disclaimerText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    if let date = store.disclaimerAcknowledgedDate {
                        Text("Accepted \(date.formatted(date: .abbreviated, time: .shortened))")
                    } else {
                        Text("Accepted")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            } header: {
                Text("Disclaimer")
            }

            // Plain read-only build markers -- exists so a build that
            // actually picked up the latest seed content can be told apart
            // at a glance from one running stale/cached code, e.g. to check
            // whether a device that's missing a checklist is really running
            // the build that added it. Bump SeedData/TrainingSeedData's
            // contentVersion as usual; these labels just mirror whatever
            // that constant currently is, no extra bookkeeping needed.
            Section {
                LabeledContent("Checklist Content", value: "v\(SeedData.contentVersion)")
                LabeledContent("Training Content", value: "v\(TrainingSeedData.contentVersion)")
            } header: {
                Text("Build Info")
            } footer: {
                Text("If a checklist you expect to see is missing, compare these numbers against what's in the source on your Mac -- a mismatch means this device is still running an older build.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !didCheckAuthorization else { return }
            didCheckAuthorization = true
            remindersAuthorized = await NotificationScheduler.isAuthorized()
        }
        .sheet(isPresented: $isShowingProfessionalInfoSheet) {
            TrainingProfessionalInfoSheet(
                agency: store.trainingProfessionalAgency ?? "",
                number: store.trainingProfessionalNumber ?? "",
                onSave: { agency, number in
                    store.trainingProfessionalAgency = agency
                    store.trainingProfessionalNumber = number
                    store.isTrainingSectionEnabled = true
                }
            )
        }
        .alert("Couldn't Sign In", isPresented: Binding(
            get: { googleSignInError != nil },
            set: { isPresented in if !isPresented { googleSignInError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(googleSignInError ?? "")
        }
    }

    /// Whether GoogleDriveBackend.swift has actually been added to this
    /// build -- it's delivered separately from the base project (see that
    /// file's doc comment), so until it's added and set up, this stays
    /// false and the Google Drive option explains what's needed instead of
    /// offering a sign-in button that can't work yet.
    private var isGoogleDriveAvailable: Bool {
        SyncManager.googleDriveFactory != nil
    }

    private var isGoogleSignedIn: Bool {
        SyncManager.googleIsSignedInHandler?() ?? false
    }

    @ViewBuilder
    private var backupSyncSection: some View {
        Picker("Provider", selection: $syncManager.provider) {
            ForEach(SyncProvider.allCases, id: \.self) { provider in
                Text(provider.displayName).tag(provider)
            }
        }
        .pickerStyle(.segmented)

        if syncManager.provider == .googleDrive {
            if isGoogleDriveAvailable {
                if isGoogleSignedIn {
                    LabeledContent("Account", value: syncManager.accountLabel ?? "Signed in")
                    Button("Sign Out", role: .destructive) {
                        SyncManager.googleSignOutHandler?()
                        syncManager.refreshAccountLabel()
                    }
                } else {
                    Button {
                        signInWithGoogle()
                    } label: {
                        Label("Sign in with Google", systemImage: "person.crop.circle.badge.checkmark")
                    }
                }
            } else {
                Label("Google Drive isn't set up in this build yet -- see GOOGLE_DRIVE_SETUP.md for the one-time steps.", systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        if syncManager.provider != .none {
            HStack {
                Text("Status")
                Spacer()
                if syncManager.isSyncing {
                    ProgressView()
                } else if let lastSyncedAt = syncManager.lastSyncedAt {
                    Text("Synced \(lastSyncedAt.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                } else {
                    Text("Not synced yet")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
            if let lastError = syncManager.lastError {
                Label(lastError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            Button {
                Task { await syncManager.syncNow() }
            } label: {
                Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(syncManager.isSyncing || (syncManager.provider == .googleDrive && !isGoogleSignedIn))
        }
    }

    /// Presents Google's sign-in UI, which needs a real UIViewController to
    /// present from -- SwiftUI has no view of its own for this, so this
    /// reaches for the key window's root view controller the same way
    /// other UIKit-bridged presentations in this app (CameraCapture,
    /// ShareSheetPresenter) ultimately get one, just without a
    /// UIViewControllerRepresentable wrapper since GoogleSignIn's API
    /// wants the view controller handed to it directly.
    private func signInWithGoogle() {
        guard let handler = SyncManager.googleSignInHandler else { return }
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController
        else { return }
        handler(rootViewController) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    syncManager.refreshAccountLabel()
                    Task { await syncManager.syncNow() }
                case .failure(let error):
                    googleSignInError = error.localizedDescription
                }
            }
        }
    }
}

/// Gates turning Training on -- collects the certifying agency and
/// professional/instructor number SettingsView requires before it will
/// flip `isTrainingSectionEnabled`. Cancelling leaves Training off and
/// discards whatever was typed; Save only enables once both fields are
/// non-empty.
private struct TrainingProfessionalInfoSheet: View {
    @State var agency: String
    @State var number: String
    var onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss

    private var trimmedAgency: String { agency.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedNumber: String { number.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Certifying Agency (e.g. PADI, SDI)", text: $agency)
                        .textInputAutocapitalization(.words)
                    TextField("Professional/Instructor Number", text: $number)
                        .textInputAutocapitalization(.characters)
                } footer: {
                    Text("The Training section is meant for instructors and divemasters tracking certification requirements. This is stored on-device (and synced to your other Apple devices) and shown read-only in Settings once saved.")
                }
            }
            .navigationTitle("Training Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(trimmedAgency, trimmedNumber)
                        dismiss()
                    }
                    .disabled(trimmedAgency.isEmpty || trimmedNumber.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(store: AppStore())
    }
}
