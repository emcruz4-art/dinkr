import SwiftUI
import UIKit

// MARK: - ViewModel

@Observable
final class EditProfileViewModel {
    // Basic Info
    var displayName: String
    var username: String
    var bio: String
    var city: String
    var website: String

    // Playing Info
    var skillLevel: SkillLevel
    var playStyles: [PlayStyle]
    var dominantHand: DominantHand?
    var yearsPlaying: Double   // slider uses Double

    // Availability
    var availabilityDays: Set<Weekday>
    var availableTimes: Set<TimeOfDay>

    // Preferences
    var isWomenOnly: Bool
    var isPrivate: Bool

    // Social
    var socialLinks: SocialLinks

    // Legacy single play style (kept for backward compat)
    var playStyle: PlayStyle?

    // Avatar
    var selectedImage: UIImage?
    private var avatarURL: String?

    // State
    var uploadProgress: Double = 0
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var didSave: Bool = false
    var showPlayStyleSheet: Bool = false

    init(user: User) {
        self.displayName  = user.displayName
        self.username     = user.username
        self.bio          = user.bio
        self.city         = user.city
        self.website      = user.socialLinks.website
        self.skillLevel   = user.skillLevel
        self.playStyles   = user.playStyles ?? (user.playStyle.map { [$0] } ?? [])
        self.dominantHand = user.dominantHand
        self.yearsPlaying = Double(user.yearsPlaying ?? 1)
        self.availabilityDays  = Set(user.availabilityDays ?? [])
        self.availableTimes    = Set(user.availableTimes ?? [])
        self.isWomenOnly  = user.isWomenOnly
        self.isPrivate    = user.isPrivate
        self.socialLinks  = user.socialLinks
        self.playStyle    = user.playStyle
        self.avatarURL    = user.avatarURL
    }

    // MARK: - Validation

    var displayNameError: String? {
        displayName.trimmingCharacters(in: .whitespaces).count < 2
            ? "Display name must be at least 2 characters." : nil
    }

    var usernameError: String? {
        if username.contains(" ") { return "Username cannot contain spaces." }
        if username.count < 3    { return "Username must be at least 3 characters." }
        return nil
    }

    var canSave: Bool {
        displayNameError == nil && usernameError == nil
            && !displayName.isEmpty && !username.isEmpty
    }

    var hasUnsavedChanges: Bool {
        // Returns true so we always guard on dismiss
        true
    }

    // MARK: - Save

    func save(userId: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var resolvedAvatarURL: String? = avatarURL
        if let image = selectedImage {
            let path = StoragePaths.avatar(userId: userId)
            resolvedAvatarURL = try await ImageService.shared.upload(image, path: path)
        }

        // Merge website back into socialLinks for persistence
        socialLinks.website = website

        var fields: [String: Any] = [
            "displayName":  displayName.trimmingCharacters(in: .whitespaces),
            "username":     username.lowercased().trimmingCharacters(in: .whitespaces),
            "bio":          bio,
            "city":         city,
            "skillLevel":   skillLevel.rawValue,
            "isWomenOnly":  isWomenOnly,
            "isPrivate":    isPrivate,
            "playStyle":    playStyles.first?.rawValue ?? "",
            "playStyles":   playStyles.map(\.rawValue),
            "dominantHand": dominantHand?.rawValue ?? "",
            "yearsPlaying": Int(yearsPlaying),
            "availabilityDays":  availabilityDays.map(\.rawValue),
            "availableTimes":    availableTimes.map(\.rawValue),
            "socialLinks.instagram":  socialLinks.instagram,
            "socialLinks.tiktok":     socialLinks.tiktok,
            "socialLinks.youtube":    socialLinks.youtube,
            "socialLinks.linkedin":   socialLinks.linkedin,
            "socialLinks.twitter":    socialLinks.twitter,
            "socialLinks.website":    website,
            "socialLinks.pickleheads": socialLinks.pickleheads,
        ]
        if let url = resolvedAvatarURL {
            fields["avatarURL"] = url
        }

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
    @State private var showDismissAlert = false

    init(user: User) {
        self.user = user
        _vm = State(initialValue: EditProfileViewModel(user: user))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                scrollContent
                if vm.isLoading { loadingOverlay }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if vm.hasUnsavedChanges {
                            showDismissAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Changes") { triggerSave() }
                        .fontWeight(.semibold)
                        .foregroundStyle(vm.canSave ? Color.dinkrGreen : Color.secondary)
                        .disabled(vm.isLoading || !vm.canSave)
                }
            }
            .onChange(of: vm.didSave) { _, saved in
                if saved { HapticManager.success(); dismiss() }
            }
            .alert("Discard Changes?", isPresented: $showDismissAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to leave?")
            }
            .sheet(isPresented: $vm.showPlayStyleSheet) {
                PlayStyleSelectionView(selection: $vm.playStyles)
            }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 28) {
                avatarSection
                basicInfoSection
                playingInfoSection
                availabilitySection
                socialSection
                errorBanner
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color.appBackground)
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 14) {
            // Large avatar
            ZStack(alignment: .bottom) {
                ProfileImagePicker(
                    selectedImage: $vm.selectedImage,
                    currentURLString: user.avatarURL,
                    displayName: vm.displayName,
                    onUpload: { _ in }
                )
                .configure(uploadPath: StoragePaths.avatar(userId: user.id))
                .scaleEffect(1.3)   // Larger avatar in edit context
            }
            .frame(width: 120, height: 120)
            .padding(.top, 8)

            Button {
                // The ProfileImagePicker handles its own action sheet;
                // this label is purely descriptive.
            } label: {
                Label("Change Photo", systemImage: "camera.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dinkrGreen)
            }
            .disabled(true)         // Tapping the avatar above triggers the sheet
            .opacity(1)

            Text("Tap your avatar to update or remove your photo")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Basic Info", icon: "person.fill", color: Color.dinkrGreen)

            // Display Name
            EditFieldCard(label: "Display Name", required: true) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        TextField("Your name", text: $vm.displayName)
                            .font(.body)
                            .onChange(of: vm.displayName) { _, new in
                                if new.count > 30 { vm.displayName = String(new.prefix(30)) }
                            }
                        Spacer()
                        charCount(vm.displayName.count, limit: 30, warnAt: 27)
                    }
                    if let err = vm.displayNameError { inlineError(err) }
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
                                let cleaned = new.lowercased()
                                    .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "." }
                                let trimmed = String(cleaned.prefix(20))
                                if vm.username != trimmed { vm.username = trimmed }
                            }
                        Spacer()
                        charCount(vm.username.count, limit: 20, warnAt: 18)
                    }
                    if let err = vm.usernameError { inlineError(err) }
                }
            }

            // Bio
            EditFieldCard(label: "Bio", required: false) {
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment: .topLeading) {
                        if vm.bio.isEmpty {
                            Text("Tell people about your pickleball story…")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 1)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $vm.bio)
                            .font(.body)
                            .frame(minHeight: 88)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .onChange(of: vm.bio) { _, new in
                                if new.count > 150 { vm.bio = String(new.prefix(150)) }
                            }
                    }
                    HStack {
                        Spacer()
                        charCount(vm.bio.count, limit: 150, warnAt: 130)
                    }
                }
            }

            // Location
            EditFieldCard(label: "Location", required: false) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.dinkrCoral)
                    TextField("City, State or Country", text: $vm.city)
                        .font(.body)
                }
            }

            // Website
            EditFieldCard(label: "Website", required: false) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(Color.dinkrSky)
                    TextField("https://yourwebsite.com", text: $vm.website)
                        .font(.body)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
        }
    }

    // MARK: - Playing Info Section

    private var playingInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Playing Info", icon: "figure.pickleball", color: Color.dinkrSky)

            // Skill Level
            EditFieldCard(label: "Skill Level", required: false) {
                SkillLevelSegmentedPicker(selection: $vm.skillLevel)
            }

            // Play Style — opens full-sheet selection
            EditFieldCard(label: "Play Style", required: false) {
                Button {
                    HapticManager.selection()
                    vm.showPlayStyleSheet = true
                } label: {
                    HStack {
                        if vm.playStyles.isEmpty {
                            Text("Select up to 2 styles")
                                .foregroundStyle(.secondary)
                        } else {
                            HStack(spacing: 6) {
                                ForEach(vm.playStyles, id: \.self) { style in
                                    playStyleTag(style)
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            // Dominant Hand
            EditFieldCard(label: "Dominant Hand", required: false) {
                HStack(spacing: 10) {
                    ForEach(DominantHand.allCases, id: \.self) { hand in
                        handChip(hand)
                    }
                    Spacer()
                }
            }

            // Years Playing
            EditFieldCard(label: "Years Playing", required: false) {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(Color.dinkrAmber)
                        Text(yearsLabel(vm.yearsPlaying))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.dinkrAmber)
                        Spacer()
                    }
                    Slider(value: $vm.yearsPlaying, in: 0...20, step: 1)
                        .tint(Color.dinkrAmber)
                    HStack {
                        Text("New")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("20+ yrs")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Availability Section

    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Availability", icon: "clock.fill", color: Color.dinkrAmber)

            // Days of week
            EditFieldCard(label: "Days Available", required: false) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("When are you typically free to play?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        ForEach(Weekday.allCases) { day in
                            dayChip(day)
                        }
                    }
                }
            }

            // Preferred times
            EditFieldCard(label: "Preferred Times", required: false) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("What time of day do you prefer?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ForEach(TimeOfDay.allCases) { time in
                            timeChip(time)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Social Section

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Social & Links", icon: "link.circle.fill", color: Color.dinkrNavy)

            EditFieldCard(label: "Social Profiles", required: false) {
                VStack(spacing: 0) {
                    SocialLinkField(
                        icon: "camera.fill",
                        color: Color(red: 0.83, green: 0.19, blue: 0.55),
                        placeholder: "Instagram username",
                        text: $vm.socialLinks.instagram
                    )
                    Divider().padding(.leading, 40)
                    SocialLinkField(
                        icon: "music.note",
                        color: .black,
                        placeholder: "TikTok username",
                        text: $vm.socialLinks.tiktok
                    )
                    Divider().padding(.leading, 40)
                    SocialLinkField(
                        icon: "play.rectangle.fill",
                        color: Color(red: 0.93, green: 0.16, blue: 0.16),
                        placeholder: "YouTube handle",
                        text: $vm.socialLinks.youtube
                    )
                    Divider().padding(.leading, 40)
                    SocialLinkField(
                        icon: "text.bubble.fill",
                        color: .black,
                        placeholder: "X (Twitter) username",
                        text: $vm.socialLinks.twitter
                    )
                }
            }

            EditFieldCard(label: "Pickleball Profiles", required: false) {
                VStack(spacing: 0) {
                    SocialLinkField(
                        icon: "p.circle.fill",
                        color: Color.dinkrGreen,
                        placeholder: "Pickleheads profile link",
                        text: $vm.socialLinks.pickleheads,
                        keyboardType: .URL
                    )
                }
            }

            // Privacy toggles
            EditFieldCard(label: "Player Preferences", required: false) {
                VStack(spacing: 12) {
                    Toggle(isOn: $vm.isWomenOnly) {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.stand")
                                .foregroundStyle(Color.dinkrSky)
                            Text("Women's player")
                                .font(.body)
                        }
                    }
                    .tint(Color.dinkrGreen)

                    Divider()

                    Toggle(isOn: $vm.isPrivate) {
                        HStack(spacing: 8) {
                            Image(systemName: vm.isPrivate ? "lock.fill" : "lock.open.fill")
                                .foregroundStyle(vm.isPrivate ? Color.dinkrAmber : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Private account")
                                    .font(.body)
                                Text(vm.isPrivate
                                     ? "Only mutual friends can view your profile"
                                     : "Anyone can view your profile")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(Color.dinkrAmber)
                }
            }
        }
    }

    // MARK: - Error Banner

    @ViewBuilder
    private var errorBanner: some View {
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

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
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

    // MARK: - Sub-components

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private func playStyleTag(_ style: PlayStyle) -> some View {
        let color = playStyleColor(style)
        HStack(spacing: 4) {
            Image(systemName: style.icon)
                .font(.system(size: 11, weight: .semibold))
            Text(style.rawValue)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color, lineWidth: 1))
    }

    @ViewBuilder
    private func handChip(_ hand: DominantHand) -> some View {
        let isSelected = vm.dominantHand == hand
        Button {
            HapticManager.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                vm.dominantHand = isSelected ? nil : hand
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: hand == .left ? "hand.raised.fill" : "hand.raised.fill")
                    .scaleEffect(x: hand == .left ? -1 : 1, y: 1)
                    .font(.system(size: 14))
                Text(hand.rawValue)
                    .font(.subheadline.weight(isSelected ? .bold : .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(isSelected ? Color.dinkrNavy : Color.appBackground)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.dinkrNavy : Color.secondary.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dayChip(_ day: Weekday) -> some View {
        let isSelected = vm.availabilityDays.contains(day)
        Button {
            HapticManager.selection()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.65)) {
                if isSelected { vm.availabilityDays.remove(day) }
                else          { vm.availabilityDays.insert(day) }
            }
        } label: {
            Text(day.short)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .frame(minWidth: 32, minHeight: 32)
                .background(isSelected ? Color.dinkrGreen : Color.appBackground)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(
                        isSelected ? Color.dinkrGreen : Color.secondary.opacity(0.3),
                        lineWidth: isSelected ? 0 : 1
                    )
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func timeChip(_ time: TimeOfDay) -> some View {
        let isSelected = vm.availableTimes.contains(time)
        Button {
            HapticManager.selection()
            withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                if isSelected { vm.availableTimes.remove(time) }
                else          { vm.availableTimes.insert(time) }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: time.icon)
                    .font(.system(size: 13))
                Text(time.rawValue)
                    .font(.subheadline.weight(isSelected ? .bold : .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.dinkrSky : Color.appBackground)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    isSelected ? Color.dinkrSky : Color.secondary.opacity(0.3),
                    lineWidth: isSelected ? 0 : 1
                )
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func charCount(_ count: Int, limit: Int, warnAt: Int) -> some View {
        Text("\(count)/\(limit)")
            .font(.caption2)
            .foregroundStyle(count >= warnAt ? Color.dinkrAmber : Color.secondary)
    }

    @ViewBuilder
    private func inlineError(_ message: String) -> some View {
        Text(message)
            .font(.caption2)
            .foregroundStyle(Color.dinkrCoral)
    }

    private func yearsLabel(_ value: Double) -> String {
        let years = Int(value)
        if years == 0  { return "Just started" }
        if years == 20 { return "20+ years" }
        return years == 1 ? "1 year" : "\(years) years"
    }

    private func playStyleColor(_ style: PlayStyle) -> Color {
        switch style.color {
        case "dinkrCoral":  return Color.dinkrCoral
        case "dinkrGreen":  return Color.dinkrGreen
        case "dinkrSky":    return Color.dinkrSky
        case "dinkrAmber":  return Color.dinkrAmber
        case "dinkrNavy":   return Color.dinkrNavy
        default:            return Color.dinkrGreen
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
            HStack(spacing: 6) {
                ForEach(SkillLevel.allCases.prefix(4), id: \.self) { skillChip($0) }
            }
            HStack(spacing: 6) {
                ForEach(SkillLevel.allCases.dropFirst(4), id: \.self) { skillChip($0) }
            }
        }
    }

    @ViewBuilder
    private func skillChip(_ level: SkillLevel) -> some View {
        let isSelected = selection == level
        Button {
            HapticManager.selection()
            withAnimation(.easeInOut(duration: 0.15)) { selection = level }
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
            .background(isSelected ? skillColor(for: level).opacity(0.18) : Color.appBackground)
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
        case "green":  return Color.dinkrGreen
        case "blue":   return Color.dinkrSky
        case "orange": return Color.dinkrAmber
        case "red":    return Color.dinkrCoral
        default:       return Color.dinkrGreen
        }
    }
}

// MARK: - SocialLinkField

private struct SocialLinkField: View {
    let icon: String
    let color: Color
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(color.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }
            TextField(placeholder, text: $text)
                .font(.body)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    EditProfileView(user: User.mockCurrentUser)
}
