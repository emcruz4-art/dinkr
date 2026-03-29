import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var user: User
    @State private var isSaving = false

    init(user: User) {
        _user = State(initialValue: user)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Display Name") {
                    TextField("Display Name", text: $user.displayName)
                }
                Section("Username") {
                    TextField("Username", text: $user.username)
                        .textInputAutocapitalization(.never)
                }
                Section("Bio") {
                    TextEditor(text: $user.bio).frame(minHeight: 80)
                }
                Section("Skill Level") {
                    Picker("Skill Level", selection: $user.skillLevel) {
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            Text(level.label).tag(level)
                        }
                    }
                }
                Section("City") {
                    TextField("City", text: $user.city)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(isSaving)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    EditProfileView(user: User.mockCurrentUser)
}
