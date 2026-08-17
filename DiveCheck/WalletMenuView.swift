import SwiftUI

/// "Wallet" section of the home screen: the personal documents a diver
/// carries around from dive to dive rather than ones tied to a specific
/// Location or dive -- certification cards and a personal medical ID.
struct WalletMenuView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        List {
            NavigationLink(value: ChecklistRoute.certifications) {
                ToolRow(
                    title: "Certifications",
                    subtitle: "\(store.certifications.count) saved",
                    symbolName: "seal.fill"
                )
            }
            NavigationLink(value: ChecklistRoute.diverMedicalID) {
                ToolRow(
                    title: "Diver Medical ID",
                    subtitle: store.diverMedicalID == nil ? "Not filled in yet" : "On file",
                    symbolName: "person.text.rectangle.fill"
                )
            }
        }
        .navigationTitle("Wallet")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WalletMenuView(store: AppStore())
    }
}
