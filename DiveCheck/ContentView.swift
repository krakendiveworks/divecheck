import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStore()
    @State private var path: [ChecklistRoute] = []

    var body: some View {
        // DisclaimerView takes over the whole app until the diver
        // accepts it -- see AppStore.hasAcknowledgedDisclaimer.
        if store.hasAcknowledgedDisclaimer {
            mainNavigation
        } else {
            DisclaimerView(store: store)
        }
    }

    private var mainNavigation: some View {
        NavigationStack(path: $path) {
            List {
                Section("Menu") {
                    NavigationLink(value: ChecklistRoute.plan) {
                        ToolRow(
                            title: "Plan",
                            subtitle: "Checklists, Locations, Emergency Action Plans",
                            symbolName: "map.fill"
                        )
                    }
                    NavigationLink(value: ChecklistRoute.dives) {
                        ToolRow(
                            title: "Dives",
                            subtitle: "Dive Logs, Statistics",
                            symbolName: "book.closed.fill"
                        )
                    }
                    NavigationLink(value: ChecklistRoute.equipment) {
                        ToolRow(
                            title: "Equipment",
                            subtitle: "Locker, Maintenance, Service History",
                            symbolName: "shippingbox.fill"
                        )
                    }
                    NavigationLink(value: ChecklistRoute.wallet) {
                        ToolRow(
                            title: "Wallet",
                            subtitle: "Certifications, Diver Medical ID",
                            symbolName: "wallet.pass.fill"
                        )
                    }
                    NavigationLink(value: ChecklistRoute.calculators) {
                        ToolRow(
                            title: "Calculators",
                            subtitle: "Gas planning, oxygen exposure, and weight tools",
                            symbolName: "function"
                        )
                    }
                    if store.isTrainingSectionEnabled {
                        NavigationLink(value: ChecklistRoute.training) {
                            ToolRow(
                                title: "Training",
                                subtitle: "Certification skill requirements by agency",
                                symbolName: "graduationcap.fill"
                            )
                        }
                    }
                    NavigationLink(value: ChecklistRoute.settings) {
                        ToolRow(
                            title: "Settings",
                            subtitle: "Default units",
                            symbolName: "gearshape.fill"
                        )
                    }
                }
            }
            .navigationTitle("DiveCheck")
            .navigationDestination(for: ChecklistRoute.self) { route in
                // Every pushed screen in the app routes through here, so
                // attaching the Home button at this single point (rather
                // than to each of the ~30 destination views individually)
                // gets it everywhere "from any item in the app" without
                // having to touch every screen. Tapping it clears the path
                // back to the root Menu list in one jump, regardless of
                // how deep the current screen is nested.
                destination(for: route)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                path.removeAll()
                            } label: {
                                Image(systemName: "house.fill")
                            }
                            .accessibilityLabel("Home")
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: ChecklistRoute) -> some View {
        switch route {
        case .diveChecklists:
            DiveChecklistsListView(store: store)
        case .category(let categoryID):
            CategoryDetailView(store: store, categoryID: categoryID)
        case .subcategory(let categoryID, let subcategoryID):
            SubcategoryDetailView(store: store, categoryID: categoryID, subcategoryID: subcategoryID)
        case .checklist(let categoryID, let subcategoryID, let checklistID):
            let categoryName = store.categories.first { $0.id == categoryID }?.name ?? ""
            let subcategoryName = subcategoryID.flatMap { subID in
                store.categories.first { $0.id == categoryID }?.subcategories.first { $0.id == subID }?.name
            }
            if let subcategoryID {
                ChecklistDetailView(
                    checklist: store.binding(categoryID: categoryID, subcategoryID: subcategoryID, checklistID: checklistID),
                    onSaveSnapshot: { snapshot in
                        store.saveSnapshot(snapshot, categoryName: categoryName, subcategoryName: subcategoryName)
                    }
                )
            } else {
                ChecklistDetailView(
                    checklist: store.binding(categoryID: categoryID, checklistID: checklistID),
                    onSaveSnapshot: { snapshot in
                        store.saveSnapshot(snapshot, categoryName: categoryName, subcategoryName: nil)
                    }
                )
            }
        case .history:
            HistoryListView(store: store)
        case .savedChecklist(let savedID):
            SavedChecklistDetailView(store: store, savedID: savedID)
        case .equipmentLocker:
            EquipmentLockerListView(store: store)
        case .equipmentDetail(let equipmentID):
            EquipmentDetailView(equipment: store.equipmentBinding(for: equipmentID))
        case .diveLog:
            DiveLogListView(store: store, path: $path)
        case .diveLogDetail(let entryID):
            DiveLogDetailView(store: store, entryID: entryID)
        case .bluetoothDiveImport:
            BluetoothDiveImportView(store: store)
        case .garminFitImport:
            GarminFITImportView(store: store)
        case .calculators:
            CalculatorsListView()
        case .sacCalculator:
            SACCalculatorView()
        case .modCalculator:
            MODCalculatorView()
        case .ppo2Calculator:
            PPO2CalculatorView()
        case .bestMixCalculator:
            BestMixCalculatorView()
        case .eadCalculator:
            EADCalculatorView()
        case .endCalculator:
            ENDCalculatorView()
        case .gasTimeCalculator:
            GasTimeCalculatorView()
        case .minimumGasCalculator:
            MinimumGasCalculatorView()
        case .cnsOxygenCalculator:
            CNSOxygenCalculatorView()
        case .weightCheckCalculator:
            WeightCheckCalculatorView()
        case .tankFillCalculator:
            TankFillCalculatorView()
        case .locations:
            LocationsListView(store: store, path: $path)
        case .locationDetail(let locationID):
            LocationDetailView(store: store, locationID: locationID, path: $path)
        case .emergencyActionPlans:
            EmergencyActionPlansListView(store: store, path: $path)
        case .eapDetail(let eapID):
            EAPDetailView(store: store, eapID: eapID)
        case .plan:
            PlanMenuView(store: store)
        case .dives:
            DivesMenuView(store: store)
        case .equipment:
            EquipmentMenuView(store: store)
        case .wallet:
            WalletMenuView(store: store)
        case .settings:
            SettingsView(store: store)
        case .statistics:
            StatisticsView(store: store)
        case .maintenanceSchedule:
            MaintenanceScheduleView(store: store)
        case .serviceHistory:
            ServiceHistoryView(store: store)
        case .certifications:
            CertificationsListView(store: store, path: $path)
        case .certificationDetail(let certificationID):
            CertificationDetailView(store: store, certificationID: certificationID)
        case .savedCertifications:
            SavedCertificationsListView(store: store)
        case .savedCertificationDetail(let savedID):
            SavedCertificationDetailView(store: store, savedID: savedID)
        case .diverMedicalID:
            DiverMedicalIDView(store: store)
        case .savedDiverMedicalIDs:
            SavedDiverMedicalIDsListView(store: store)
        case .savedDiverMedicalIDDetail(let savedID):
            SavedDiverMedicalIDDetailView(store: store, savedID: savedID)
        case .diveSiteMap:
            DiveSiteMapView(store: store, path: $path)
        case .diveComputers:
            DiveComputersListView(store: store, path: $path)
        case .diveComputerDetail(let computerID):
            DiveComputerDetailView(store: store, computerID: computerID)
        case .training:
            TrainingAgenciesListView(store: store)
        case .trainingAgency(let agencyID):
            TrainingCertificationsListView(store: store, agencyID: agencyID)
        case .trainingCertification(let agencyID, let certificationID):
            TrainingCertificationDetailView(store: store, agencyID: agencyID, certificationID: certificationID)
        case .trainingChecklist(let agencyID, let certificationID, let checklistID):
            ChecklistDetailView(
                checklist: store.trainingBinding(agencyID: agencyID, certificationID: certificationID, checklistID: checklistID)
            )
        case .studentTracking:
            StudentTrackingListView(store: store)
        case .studentTrackingAgency(let agencyID):
            StudentTrackingAgencyProgramsListView(store: store, agencyID: agencyID)
        case .trainingRosterProgram(let agencyID, let programID):
            TrainingCandidatesListView(store: store, agencyID: agencyID, programID: programID, path: $path)
        case .trainingCandidateDetail(let agencyID, let programID, let candidateID):
            TrainingCandidateDetailView(store: store, agencyID: agencyID, programID: programID, candidateID: candidateID)
        case .trainingCandidateChecklist(let agencyID, let programID, let candidateID, let checklistID):
            ChecklistDetailView(
                checklist: store.trainingCandidateBinding(agencyID: agencyID, programID: programID, candidateID: candidateID, checklistID: checklistID)
            )
        }
    }
}

#Preview {
    ContentView()
}
