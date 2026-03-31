import SwiftUI

// MARK: - Account Deletion View

struct AccountDeletionView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: Step State
    @State private var currentStep: DeletionStep = .warning
    @State private var confirmationText: String = ""
    @State private var isProcessing: Bool = false

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Step 1: Warning
                if currentStep == .warning {
                    warningScreen
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                // Step 2: Confirmation
                if currentStep == .confirmation {
                    confirmationScreen
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                // Step 3: Processing / Done
                if currentStep == .processing || currentStep == .done {
                    finalScreen
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: currentStep)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep == .warning || currentStep == .confirmation {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(Color.dinkrCoral)
                    }
                }
            }
        }
    }

    // MARK: - Step 1: Warning Screen

    private var warningScreen: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.dinkrCoral.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "trash.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Color.dinkrCoral)
                }
                .padding(.top, 32)

                VStack(spacing: 8) {
                    Text("Delete Your Account?")
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text("This action is permanent and cannot be undone. Here's everything that will be deleted:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Deletion items list
                VStack(spacing: 0) {
                    ForEach(DeletionItem.allCases) { item in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.dinkrCoral.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: item.icon)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.dinkrCoral)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)

                        if item != DeletionItem.allCases.last {
                            Divider()
                                .padding(.leading, 66)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.dinkrCoral.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 16)

                // CTA
                Button {
                    withAnimation {
                        currentStep = .confirmation
                    }
                } label: {
                    Text("Continue to Delete")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dinkrCoral, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Step 2: Confirmation Screen

    private var confirmationScreen: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.dinkrCoral.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Color.dinkrCoral)
                }
                .padding(.top, 32)

                VStack(spacing: 8) {
                    Text("Confirm Deletion")
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text("Type **DELETE** in the field below to confirm you want to permanently delete your account.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Text field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type DELETE to confirm")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    TextField("DELETE", text: $confirmationText)
                        .font(.body.weight(.medium))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isDeleteConfirmed ? Color.dinkrCoral : Color(.separator),
                                    lineWidth: isDeleteConfirmed ? 1.5 : 1
                                )
                        )
                }
                .padding(.horizontal, 16)

                // Confirm button — only visible when text matches
                if isDeleteConfirmed {
                    Button {
                        beginDeletion()
                    } label: {
                        Text("Delete My Account Forever")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.dinkrCoral, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 16)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDeleteConfirmed)
    }

    // MARK: - Step 3: Processing / Done Screen

    private var finalScreen: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        currentStep == .done
                            ? Color.dinkrCoral.opacity(0.12)
                            : Color(.secondarySystemGroupedBackground)
                    )
                    .frame(width: 100, height: 100)

                if currentStep == .processing {
                    ProgressView()
                        .scaleEffect(1.6)
                        .tint(Color.dinkrCoral)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(Color.dinkrCoral)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.65), value: currentStep == .done)

            VStack(spacing: 10) {
                Text(currentStep == .done ? "Account Deletion Requested" : "Processing...")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut, value: currentStep == .done)

                if currentStep == .done {
                    Text("Your account and all associated data have been scheduled for deletion. This process may take up to 30 days to complete. You'll receive a confirmation email when it's done.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                }
            }

            if currentStep == .done {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dinkrCoral, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Helpers

    private var isDeleteConfirmed: Bool {
        confirmationText.trimmingCharacters(in: .whitespaces).uppercased() == "DELETE"
    }

    private func beginDeletion() {
        withAnimation {
            currentStep = .processing
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                currentStep = .done
            }
        }
    }
}

// MARK: - Supporting Types

private enum DeletionStep: Equatable {
    case warning, confirmation, processing, done
}

private enum DeletionItem: String, CaseIterable, Identifiable {
    case games, groups, listings, posts

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .games:    return "sportscourt"
        case .groups:   return "person.3.fill"
        case .listings: return "tag.fill"
        case .posts:    return "photo.on.rectangle.angled"
        }
    }

    var title: String {
        switch self {
        case .games:    return "All Games & Match History"
        case .groups:   return "Groups & Memberships"
        case .listings: return "Marketplace Listings"
        case .posts:    return "Posts & Activity"
        }
    }

    var detail: String {
        switch self {
        case .games:    return "Every game you've played, organized, or joined"
        case .groups:   return "All groups you created or are a member of"
        case .listings: return "Active and past marketplace listings"
        case .posts:    return "Photos, comments, and your activity feed"
        }
    }
}

// MARK: - Preview

#Preview {
    AccountDeletionView()
}
