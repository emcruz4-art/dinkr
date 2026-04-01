import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @State private var name = ""
    @State private var description = ""
    @State private var selectedType: GroupType = .recreational
    @State private var isPrivate = false
    @State private var isCreating = false
    @State private var errorMessage: String?

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
                if let err = errorMessage {
                    Section {
                        Text(err).foregroundStyle(.red).font(.caption)
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
                        Task { await createGroup() }
                    }
                    .disabled(name.isEmpty || isCreating)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func createGroup() async {
        guard let uid = authService.currentUser?.id,
              let displayName = authService.currentUser?.displayName else { return }
        isCreating = true
        defer { isCreating = false }
        let groupId = UUID().uuidString
        let group = DinkrGroup(
            id: groupId,
            name: name,
            type: selectedType,
            description: description,
            memberIds: [uid],
            adminIds: [uid],
            chatThreadId: nil,
            eventIds: [],
            isPrivate: isPrivate,
            bannerURL: nil,
            memberCount: 1
        )
        do {
            try await FirestoreService.shared.setDocument(
                group,
                collection: FirestoreCollections.groups,
                documentId: groupId
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CreateGroupView()
        .environment(AuthService())
}
