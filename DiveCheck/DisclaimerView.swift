import SwiftUI

/// Shown once, before any other screen, until the diver explicitly accepts
/// the safety disclaimer. ContentView swaps this in for the normal
/// NavigationStack whenever `AppStore.hasAcknowledgedDisclaimer` is false --
/// there's no way to dismiss or skip past it other than tapping Continue,
/// which requires the acknowledgment checkbox to be checked first.
struct DisclaimerView: View {
    /// The disclaimer text itself, shared with SettingsView so the
    /// read-only "Disclaimer" section there shows the diver exactly what
    /// they agreed to rather than a re-paraphrased copy.
    static let disclaimerText = "This application and checklists are provided as a reference tool and does not replace proper training from a certified instructor or personal responsibility for your own diving. By using this application and checklists, you acknowledge that diving involves inherent risks and that you are solely responsible for your own safety."

    @ObservedObject var store: AppStore
    @State private var hasCheckedAcknowledgment = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(Self.disclaimerText)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    acknowledgmentRow

                    Button {
                        store.hasAcknowledgedDisclaimer = true
                        store.disclaimerAcknowledgedDate = Date()
                    } label: {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!hasCheckedAcknowledgment)
                }
                .padding()
            }
            .navigationTitle("Before You Begin")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var acknowledgmentRow: some View {
        Button {
            hasCheckedAcknowledgment.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: hasCheckedAcknowledgment ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(hasCheckedAcknowledgment ? Color.accentColor : .secondary)
                Text("I understand and accept the terms above.")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DisclaimerView(store: AppStore())
}
