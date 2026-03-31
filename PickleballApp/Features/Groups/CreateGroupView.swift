import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var selectedType: GroupType = .recreational
    @State private var isPrivate = false
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                Section("DinkrGroup Name") {
                    TextField("e.g. South Austin Dinkers", text: $name)
                }
                Section("Type") {
                    Picker("DinkrGroup Type", selection: $selectedType) {
                        ForEach(GroupType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                Section("Description") {
                    TextEditor(text: $description).frame(minHeight: 80)
                }
                Section("Privacy") {
                    Toggle("Private DinkrGroup", isOn: $isPrivate)
                    if isPrivate {
                        Text("Only invited members can see and join this group.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Create DinkrGroup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        isCreating = true
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            isCreating = false
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || isCreating)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    CreateGroupView()
}
