import SwiftUI

struct AddServiceRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var serviceDescription = ""
    @State private var servicedBy = ""

    let onAdd: (ServiceRecord) -> Void

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("What was serviced", text: $serviceDescription, axis: .vertical)
                    .lineLimit(1...3)
                TextField("Serviced By", text: $servicedBy)
            }
            .navigationTitle("Add Service Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(ServiceRecord(date: date, serviceDescription: serviceDescription, servicedBy: servicedBy))
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddServiceRecordView { _ in }
}
