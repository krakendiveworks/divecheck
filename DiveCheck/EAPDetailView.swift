import SwiftUI

/// Edits a single Location's Emergency Action Plan. Field set follows DAN's
/// published EAP guidance: how to activate EMS, where emergency equipment
/// is, and who does what -- see the comment on EmergencyActionPlan.swift
/// for the source. The DAN Emergency Hotline is always shown and is not
/// editable; per DAN's own guidance, call local EMS first, then DAN --
/// DAN and the treating physician decide from there whether a chamber is
/// even needed, which is also why this plan has no "nearest chamber" field
/// (chambers aren't always staffed or available, so baking one in here
/// could point someone the wrong way).
struct EAPDetailView: View {
    @ObservedObject var store: AppStore
    let eapID: UUID
    @State private var shareItems: [Any]?

    /// Background for a role/category label row (Response Plan's three
    /// roles, Local Transportation's Primary/Secondary) -- a light tint so
    /// those rows read as headings at a glance rather than blending in
    /// with the actual data-entry fields around them.
    private static let roleHeaderBackground = Color.blue.opacity(0.12)

    private var plan: Binding<EmergencyActionPlan> {
        store.eapBinding(for: eapID)
    }

    private var locationName: String {
        store.location(withID: plan.wrappedValue.locationID)?.name ?? "Location"
    }

    /// As-you-type "(XXX) XXX-XXXX" formatting for a phone field, applied on
    /// every edit via PhoneFormatting. Short numbers like "911" are left
    /// alone -- see PhoneFormatting.swift.
    private func formattedPhoneBinding(_ keyPath: WritableKeyPath<EmergencyActionPlan, String>) -> Binding<String> {
        Binding<String>(
            get: { plan.wrappedValue[keyPath: keyPath] },
            set: { plan.wrappedValue[keyPath: keyPath] = PhoneFormatting.format($0) }
        )
    }

    /// A light-tinted heading row that reads as a label rather than a
    /// data-entry field -- shared by the Response Plan roles and the Local
    /// Transportation Primary/Secondary rows.
    @ViewBuilder
    private func roleHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .listRowBackground(Self.roleHeaderBackground)
    }

    /// A "Name/Org" field plus a phone field with a tap-to-call button --
    /// shared by the Response Plan roles and the Local Transportation
    /// entries, both of which are just "who, and what number" pairs.
    @ViewBuilder
    private func contactRow(nameLabel: String, namePlaceholder: String = "", name: Binding<String>, phone: Binding<String>) -> some View {
        LabeledTextField(label: nameLabel, text: name, placeholder: namePlaceholder)
        HStack {
            Text("Phone")
            Spacer()
            TextField("Phone", text: phone)
                .multilineTextAlignment(.trailing)
                .keyboardType(.phonePad)
                .foregroundStyle(.secondary)
            if let url = PhoneFormatting.telURL(phone.wrappedValue) {
                Link(destination: url) {
                    Image(systemName: "phone.fill")
                }
            }
        }
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Emergency Number")
                    Spacer()
                    TextField("911", text: formattedPhoneBinding(\.localEmergencyNumber))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.phonePad)
                        .foregroundStyle(.secondary)
                    if let url = PhoneFormatting.telURL(plan.wrappedValue.localEmergencyNumber) {
                        Link(destination: url) {
                            Image(systemName: "phone.fill")
                        }
                    }
                }
            } header: {
                Text("Local Emergency Services")
            } footer: {
                Text("Always call local emergency services first. Call DAN once EMS is activated, for a consultation with the treating physician.")
            }

            Section("DAN Emergency Hotline") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DAN Emergency Hotline")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(EmergencyActionPlan.danEmergencyHotline)
                            .font(.headline)
                    }
                    Spacer()
                    if let url = PhoneFormatting.telURL(EmergencyActionPlan.danEmergencyHotline) {
                        Link(destination: url) {
                            Label("Call", systemImage: "phone.fill")
                        }
                    }
                }
            }

            Section("Nearest Hospital") {
                TextField("Hospital Name", text: plan.nearestHospitalName)
                LabeledMultilineField(label: "Address", text: plan.nearestHospitalAddress, placeholder: "Street, city, state/country")
                if let url = mapsURL(for: plan.wrappedValue.nearestHospitalAddress) {
                    Link(destination: url) {
                        Label("Open in Maps", systemImage: "map.fill")
                    }
                }
                HStack {
                    Text("Phone")
                    Spacer()
                    TextField("Phone", text: formattedPhoneBinding(\.nearestHospitalPhone))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.phonePad)
                        .foregroundStyle(.secondary)
                    if let url = PhoneFormatting.telURL(plan.wrappedValue.nearestHospitalPhone) {
                        Link(destination: url) {
                            Image(systemName: "phone.fill")
                        }
                    }
                }
            }

            Section {
                TextField("Facility Name", text: plan.alternateMedicalFacilityName)
                LabeledMultilineField(label: "Address", text: plan.alternateMedicalFacilityAddress, placeholder: "Street, city, state/country")
                if let url = mapsURL(for: plan.wrappedValue.alternateMedicalFacilityAddress) {
                    Link(destination: url) {
                        Label("Open in Maps", systemImage: "map.fill")
                    }
                }
                HStack {
                    Text("Phone")
                    Spacer()
                    TextField("Phone", text: formattedPhoneBinding(\.alternateMedicalFacilityPhone))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.phonePad)
                        .foregroundStyle(.secondary)
                    if let url = PhoneFormatting.telURL(plan.wrappedValue.alternateMedicalFacilityPhone) {
                        Link(destination: url) {
                            Image(systemName: "phone.fill")
                        }
                    }
                }
            } header: {
                Text("Alternate Medical Facility")
            } footer: {
                Text("A backup option -- an urgent care, clinic, or second hospital -- for when the nearest hospital above isn't reachable or isn't the right fit.")
            }

            Section {
                LabeledMultilineField(label: "Address / GPS Coordinates", text: plan.locationInfoAddress, placeholder: "Street address, or GPS coordinates if there's no street address")
                if let url = mapsURL(for: plan.wrappedValue.locationInfoAddress) {
                    Link(destination: url) {
                        Label("Open in Maps", systemImage: "map.fill")
                    }
                }
                LabeledMultilineField(label: "Access Notes for EMS", text: plan.locationInfoAccessNotes, placeholder: "Cross streets, landmarks, gate code, dock/slip number, parking instructions")
            } header: {
                Text("Dive Site Location Information")
            } footer: {
                Text("What to read off to EMS dispatch when calling this in -- whoever makes the call should have this ready.")
            }

            Section("On-Site Emergency Equipment") {
                Toggle("Emergency Oxygen Available", isOn: plan.emergencyOxygenAvailable)
                LabeledMultilineField(label: "Emergency Oxygen Location", text: plan.emergencyOxygenLocation, placeholder: "Onboard the boat, at the shop, etc.")
                Toggle("AED Available", isOn: plan.aedAvailable)
                LabeledMultilineField(label: "AED Location", text: plan.aedLocation, placeholder: "Onboard the boat, at the shop, etc.")
                Toggle("First Aid Kit Available", isOn: plan.firstAidKitAvailable)
                LabeledMultilineField(label: "First Aid Kit Location", text: plan.firstAidKitLocation)
            }

            Section {
                roleHeader("Calls EMS")
                contactRow(nameLabel: "Name / Org", name: plan.emsCallerName, phone: formattedPhoneBinding(\.emsCallerPhone))

                roleHeader("Administers Oxygen / First Aid")
                contactRow(nameLabel: "Name / Org", name: plan.firstAidProviderName, phone: formattedPhoneBinding(\.firstAidProviderPhone))

                roleHeader("Manages Bystanders & Diver Accountability")
                contactRow(nameLabel: "Name / Org", name: plan.accountabilityManagerName, phone: formattedPhoneBinding(\.accountabilityManagerPhone))

                LabeledMultilineField(label: "Additional Roles or Notes", text: plan.assignedRoles, placeholder: "Anything else worth assigning ahead of time")
            } header: {
                Text("Response Plan")
            } footer: {
                Text("Decide roles ahead of time, not in the moment. If you're alone with the injured diver, activate EMS before administering aid.")
            }

            Section {
                Picker("Dive Access", selection: plan.diveAccessType) {
                    ForEach(DiveAccessType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                if plan.wrappedValue.diveAccessType == .land {
                    LabeledMultilineField(label: "Cell Signal Notes", text: plan.landCommunicationNotes, placeholder: "Carrier coverage, dead zones, etc.")
                    LabeledMultilineField(label: "Nearest Landline / Payphone", text: plan.landlineLocation)
                } else {
                    LabeledTextField(label: "VHF Channel", text: plan.vhfChannel, placeholder: "16, 68, etc.")
                    LabeledTextField(label: "Boat Call Sign", text: plan.boatCallSign)
                    LabeledMultilineField(label: "Marina / Harbor Master Contact", text: plan.marinaContact)
                    LabeledMultilineField(label: "Additional Boat Notes", text: plan.boatCommunicationNotes)
                }

                LabeledMultilineField(label: "Additional Communication Notes", text: plan.communicationNotes)
            } header: {
                Text("Communication Channels")
            } footer: {
                Text("Switch between Land-Based and Boat-Based to show the relevant fields -- switching doesn't clear whatever's already saved on the other side, so a Location used for both can have both filled in.")
            }

            Section {
                HStack {
                    Text("Phone")
                    Spacer()
                    TextField("911", text: formattedPhoneBinding(\.lawEnforcementPhone))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.phonePad)
                        .foregroundStyle(.secondary)
                    if let url = PhoneFormatting.telURL(plan.wrappedValue.lawEnforcementPhone) {
                        Link(destination: url) {
                            Image(systemName: "phone.fill")
                        }
                    }
                }
                LabeledMultilineField(label: "Notes", text: plan.lawEnforcementNotes, placeholder: "Department name, non-emergency line, jurisdiction")
            } header: {
                Text("Local Law Enforcement")
            } footer: {
                Text("Defaults to 911 -- update if a direct non-emergency line makes more sense for this Location.")
            }

            Section {
                roleHeader("Primary")
                contactRow(nameLabel: "Name", namePlaceholder: "Taxi company, rideshare dispatch, etc.", name: plan.primaryTransportName, phone: formattedPhoneBinding(\.primaryTransportPhone))

                roleHeader("Secondary")
                contactRow(nameLabel: "Name", name: plan.secondaryTransportName, phone: formattedPhoneBinding(\.secondaryTransportPhone))
            } header: {
                Text("Local Transportation")
            } footer: {
                Text("A non-ambulance way to move people -- getting an uninjured buddy to the hospital to meet the injured diver, sending someone for supplies, etc.")
            }

            Section("Additional Notes") {
                TextField("Scenario notes, allergies to flag, anything else worth having on hand", text: plan.additionalNotes, axis: .vertical)
                    .lineLimit(1...6)
            }

            Section {
                if let lastReviewedAt = plan.wrappedValue.lastReviewedAt {
                    Text("Last reviewed \(lastReviewedAt.formatted(date: .abbreviated, time: .omitted))")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not reviewed yet")
                        .foregroundStyle(.secondary)
                }
                Button {
                    plan.wrappedValue.lastReviewedAt = Date()
                } label: {
                    Label("Mark as Reviewed Today", systemImage: "checkmark.circle")
                }
            } header: {
                Text("Plan Review")
            } footer: {
                Text("DAN recommends reviewing your plan every few months -- facilities close, phone numbers change, and first aid supplies expire.")
            }
        }
        .navigationTitle(locationName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                if let url = EAPPDFRenderer.renderPDF(plan: plan.wrappedValue, locationName: locationName) {
                    shareItems = [url]
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .background(ShareSheetPresenter(items: $shareItems))
    }

    private func mapsURL(for address: String) -> URL? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return nil }
        return URL(string: "http://maps.apple.com/?address=\(encoded)")
    }
}

#Preview {
    NavigationStack {
        EAPDetailView(store: AppStore(), eapID: UUID())
    }
}
