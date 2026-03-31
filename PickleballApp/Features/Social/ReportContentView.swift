import SwiftUI

// MARK: - Enums

enum ReportType {
    case post, user, listing
}

enum ReportReason: String, CaseIterable, Identifiable {
    case spam         = "Spam or misleading"
    case harassment   = "Harassment or bullying"
    case inappropriate = "Inappropriate content"
    case fakeProfile  = "Fake profile"
    case other        = "Other"

    var id: String { rawValue }
    var displayText: String { rawValue }
}

// MARK: - ReportContentView

struct ReportContentView: View {
    let reportType: ReportType
    let contentPreview: String
    let reportedUserName: String
    var onDismiss: () -> Void = {}

    @State private var selectedReason: ReportReason? = nil
    @State private var additionalDetails = ""
    @State private var blockUser = false
    @State private var showSuccess = false
    @Environment(\.dismiss) private var dismiss

    private var previewText: String {
        let trimmed = contentPreview.trimmingCharacters(in: .whitespaces)
        return trimmed.count > 50 ? String(trimmed.prefix(50)) + "…" : trimmed
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if showSuccess {
                    successView
                } else {
                    reportForm
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Report Form

    private var reportForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Content preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reporting")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(previewText)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }

                // Reason picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why are you reporting this?")
                        .font(.subheadline.weight(.semibold))

                    VStack(spacing: 0) {
                        ForEach(ReportReason.allCases) { reason in
                            ReportReasonRow(
                                reason: reason,
                                isSelected: selectedReason == reason
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedReason = reason
                                }
                            }
                            if reason != ReportReason.allCases.last {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }
                    .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                }

                // Additional details (shown when "Other" is selected)
                if selectedReason == .other {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Additional details")
                            .font(.subheadline.weight(.semibold))
                        TextEditor(text: $additionalDetails)
                            .frame(minHeight: 80)
                            .padding(10)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .font(.subheadline)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Block user toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Block \(reportedUserName)")
                            .font(.subheadline.weight(.medium))
                        Text("They won't be able to see your profile or posts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $blockUser)
                        .labelsHidden()
                        .tint(Color.dinkrGreen)
                }
                .padding(14)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))

                // Submit button
                Button {
                    submitReport()
                } label: {
                    Text("Submit Report")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedReason != nil ? Color.red : Color.red.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(selectedReason == nil)
                .buttonStyle(.plain)
            }
            .padding(20)
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.dinkrGreen)
            Text("Thanks for keeping Dinkr safe")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("We'll review your report and take action if it violates our community guidelines.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button {
                dismiss()
                onDismiss()
            } label: {
                Text("Done")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Actions

    private func submitReport() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showSuccess = true
        }
    }
}

// MARK: - ReportReasonRow

private struct ReportReasonRow: View {
    let reason: ReportReason
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.dinkrGreen : Color.secondary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(Color.dinkrGreen)
                            .frame(width: 11, height: 11)
                    }
                }
                Text(reason.displayText)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ReportContentView(
        reportType: .post,
        contentPreview: "Just had the most epic game at Westside Courts!",
        reportedUserName: "Alex Rivera"
    )
}
