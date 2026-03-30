import SwiftUI
import UIKit

// MARK: - ViewModel

@Observable
final class EditProfileViewModel {
    var displayName: String
    var username: String
    var bio: String
    var city: String
    var skillLevel: SkillLevel
    var isWomenOnly: Bool
    var selectedImage: UIImage?
    var uploadProgress: Double = 0
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var didSave: Bool = false

    // Stored avatar URL after upload or pre-existing
    private var avatarURL: String?

    init(user: User) {
        self.displayName = user.displayName
        self.username = user.username
        self.bio = user.bio
        self.city = user.city
        self.skillLevel = user.skillLevel
        self.isWomenOnly = user.isWomenOnly
        self.avatarURL = user.avatarURL
    }

    // MARK: - Validation

    var displayNameError: String? {
        if displayName.trimmingCharacters(in: .whitespaces).count < 2 {
            return "Display name must be at least 2 characters."
        }
        return nil
    }

    var usernameError: String? {
        if username.contains(" ") {
            return "Username cannot contain spaces."
        }
        if username.count < 3 {
            return "Username must be at least 3 characters."
        }
        return nil
    }

    var canSave: Bool {
        displayNameError == nil && usernameError == nil && !displayName.isEmpty && !username.isEmpty
    }

    // MARK: - Save

    func save(userId: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // 1. Upload avatar if a new image was selected
        var resolvedAvatarURL: String? = avatarURL
        if let image = selectedImage {
            let path = StoragePaths.avatar(userId: userId)
            resolvedAvatarURL = try await ImageService.shared.upload(image, path: path)
        }

        // 2. Build updated fields dict
        var fields: [String: Any] = [
            "displayName": displayName.trimmingCharacters(in: .whitespaces),
            "username": username.lowercased().trimmingCharacters(in: .whitespaces),
            "bio": bio,
            "city": city,
            "skillLevel": skillLevel.rawValue,
            "isWomenOnly": isWomenOnly,
        ]
        if let url = resolvedAvatarURL {
            fields["avatarURL"] = url
        }

        // 3. Persist to Firestore
        try await FirestoreService.shared.updateDocument(
            collection: FirestoreCollections.users,
            documentId: userId,
            data: fields
        )

        didSave = true
    }
}

// MARK: - View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    let user: User
    @State private var vm: EditProfileViewModel

    init(user: User) {
        self.user = user
        _vm = State(initialValue: EditProfileViewModel(user: user))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                scrollContent
                if vm.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { triggerSave() }
                        .fontWeight(.semibold)
                        .disabled(vm.isLoading || !vm.canSave)
                }
            }
            .onChange(of: vm.didSave) { _, saved in
                if saved {
                    HapticManager.success()
                    dismiss()
                }
            }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                photoSection
                fieldSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color.appBackground)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(spacing: 10) {
            ProfileImagePicker(
                selectedImage: $vm.selectedImage,
                currentURLString: user.avatarURL,
                displayName: vm.displayName,
                onUpload: { _ in }
            )
            .configure(uploadPath: StoragePaths.avatar(userId: user.id))

            Text("Tap to change photo")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Fields Section

    private var fieldSection: some View {
        VStack(spacing: 16) {
            // Display Name
            EditFieldCard(label: "Display Name", required: true) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        TextField("Your name", text: $vm.displayName)
                            .font(.body)
                            .onChange(of: vm.displayName) { _, new in
                                if new.count > 30 {
                                    vm.displayName = String(new.prefix(30))
                                }
                            }
                        Spacer()
                        Text("\(vm.displayName.count)/30")
                            .font(.caption2)
                            .foregroundStyle(vm.displayName.count >= 28 ? Color.dinkrAmber : Color.secondary)
                    }
                    if let err = vm.displayNameError {
                        Text(err)
                            .font(.caption2)
                            .foregroundStyle(Color.dinkrCoral)
                    }
                }
            }

            // Username
            EditFieldCard(label: "Username", required: false) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 2) {
                        Text("@")
                            .foregroundStyle(Color.dinkrGreen)
                            .fontWeight(.semibold)
                        TextField("username", text: $vm.username)
                            .font(.body)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: vm.username) { _, new in
                                let cleaned = new
                                    .lowercased()
                                    .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "." }
                                let trimmed = String(cleaned.prefix(20))
                                if vm.username != trimmed { vm.username = trimmed }
                            }
                        Spacer()
                        Text("\(vm.username.count)/20")
                            .font(.caption2)
                            .foregroundStyle(vm.username.count >= 18 ? Color.dinkrAmber : Color.secondary)
                    }
                    if let err = vm.usernameError {
                        Text(err)
                            .font(.caption2)
                            .foregroundStyle(Color.dinkrCoral)
                    }
                }
            }

            // Bio
            EditFieldCard(label: "Bio", required: false) {
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment: .topLeading) {
                        if vm.bio.isEmpty {
                            Text("Tell people about your pickleball story...")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 1)
                        }
                        TextEditor(text: $vm.bio)
                            .font(.body)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .onChange(of: vm.bio) { _, new in
                                if new.count > 150 {
                                    vm.bio = String(new.prefix(150))
                                }
                            }
                    }
                    HStack {
                        Spacer()
                        Text("\(vm.bio.count)/150")
                            .font(.caption2)
                            .foregroundStyle(vm.bio.count >= 140 ? Color.dinkrAmber : Color.secondary)
                    }
                }
            }

            // City
            EditFieldCard(label: "City", required: false) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.dinkrSky)
                    TextField("e.g. Austin, TX", text: $vm.city)
                        .font(.body)
                }
            }

            // Skill Level
            EditFieldCard(label: "Skill Level", required: false) {
                SkillLevelSegmentedPicker(selection: $vm.skillLevel)
            }

            // Women's player toggle
            EditFieldCard(label: "Player Preferences", required: false) {
                Toggle(isOn: $vm.isWomenOnly) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.stand")
                            .foregroundStyle(Color.dinkrSky)
                        Text("Women's player")
                            .font(.body)
                    }
                }
                .tint(Color.dinkrGreen)
            }

            // Error banner
            if let errMsg = vm.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.dinkrCoral)
                    Text(errMsg)
                        .font(.caption)
                        .foregroundStyle(Color.dinkrCoral)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.dinkrCoral.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.3)
                Text("Saving…")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    // MARK: - Save Action

    private func triggerSave() {
        Task {
            do {
                try await vm.save(userId: user.id)
            } catch {
                vm.errorMessage = error.localizedDescription
                HapticManager.error()
            }
        }
    }
}

// MARK: - EditFieldCard

private struct EditFieldCard<Content: View>: View {
    let label: String
    let required: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                if required {
                    Text("*")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.dinkrCoral)
                }
            }
            content()
                .padding(12)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - SkillLevelSegmentedPicker

private struct SkillLevelSegmentedPicker: View {
    @Binding var selection: SkillLevel

    var body: some View {
        VStack(spacing: 8) {
            // Row 1: first 4 levels
            HStack(spacing: 6) {
                ForEach(SkillLevel.allCases.prefix(4), id: \.self) { level in
                    skillChip(level)
                }
            }
            // Row 2: remaining levels
            HStack(spacing: 6) {
                ForEach(SkillLevel.allCases.dropFirst(4), id: \.self) { level in
                    skillChip(level)
                }
            }
        }
    }

    @ViewBuilder
    private func skillChip(_ level: SkillLevel) -> some View {
        let isSelected = selection == level
        Button {
            HapticManager.selection()
            withAnimation(.easeInOut(duration: 0.15)) {
                selection = level
            }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(skillColor(for: level))
                    .frame(width: 8, height: 8)
                Text(level.label)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(
                isSelected
                    ? skillColor(for: level).opacity(0.18)
                    : Color.appBackground
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? skillColor(for: level) : Color.secondary.opacity(0.25),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func skillColor(for level: SkillLevel) -> Color {
        switch level.color {
        case "green": return Color.dinkrGreen
        case "blue":  return Color.dinkrSky
        case "orange": return Color.dinkrAmber
        case "red":   return Color.dinkrCoral
        default:      return Color.dinkrGreen
        }
    }
}

// MARK: - Preview

#Preview {
    EditProfileView(user: User.mockCurrentUser)
}
