import SwiftUI

// MARK: - Model

private struct GroupRule: Identifiable {
    let id: Int           // 1-based display number
    let title: String
    let description: String
    let systemIcon: String
}

// MARK: - View

struct GroupRulesView: View {

    /// Pass `true` for a non-member who hasn't yet agreed.
    var showAgreementButton: Bool = false

    @State private var hasAgreed = false
    @State private var showReportSheet = false

    private let rules: [GroupRule] = [
        GroupRule(
            id: 1,
            title: "Be Respectful and Inclusive",
            description: "Treat every player with kindness regardless of skill, background, or experience. Fair play is non-negotiable.",
            systemIcon: "hand.raised.fill"
        ),
        GroupRule(
            id: 2,
            title: "Skill Level Requirements",
            description: "Games are organised by skill bracket. Join sessions that match your current DUPR rating to keep play balanced.",
            systemIcon: "target"
        ),
        GroupRule(
            id: 3,
            title: "RSVP and Show Up",
            description: "Commit to games only when you can attend. A confirmed RSVP holds a court spot that could go to another player.",
            systemIcon: "calendar.badge.checkmark"
        ),
        GroupRule(
            id: 4,
            title: "No-Show Policy — 3 Strikes",
            description: "Three unexcused no-shows result in automatic removal from the group. Life happens — cancel at least 2 hours before.",
            systemIcon: "exclamationmark.triangle.fill"
        ),
        GroupRule(
            id: 5,
            title: "Payment Policy for Paid Games",
            description: "Court fees must be settled before play begins. The organiser may remove unpaid players to keep sessions fair.",
            systemIcon: "dollarsign.circle.fill"
        ),
        GroupRule(
            id: 6,
            title: "Equipment Sharing Etiquette",
            description: "Shared paddles and balls must be returned in the condition you found them. Report damage immediately to an admin.",
            systemIcon: "hands.sparkles.fill"
        ),
        GroupRule(
            id: 7,
            title: "Photography Consent",
            description: "Always ask before photographing or recording other players. Do not post identifiable images without explicit consent.",
            systemIcon: "camera.fill"
        ),
        GroupRule(
            id: 8,
            title: "Admin Decisions Are Final",
            description: "DinkrGroup admins have the final say on disputes and scheduling. Concerns may be raised privately with an admin.",
            systemIcon: "hammer.fill"
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Subtitle / last updated ────────────────────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Community standards that keep this group safe, fair, and fun for everyone.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Last updated March 2026")
                            .font(.caption)
                            .foregroundStyle(Color.dinkrAmber)
                            .fontWeight(.medium)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)

                // ── Rules list ─────────────────────────────────────────────
                VStack(spacing: 12) {
                    ForEach(rules) { rule in
                        RuleCard(rule: rule)
                    }
                }
                .padding(.horizontal, 20)

                // ── Agreement button (non-members only) ────────────────────
                if showAgreementButton {
                    agreementSection
                        .padding(.top, 28)
                        .padding(.horizontal, 20)
                }

                // ── Report violation ───────────────────────────────────────
                Button {
                    HapticManager.selection()
                    showReportSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.dinkrCoral)
                        Text("Report a Violation")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.dinkrCoral)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dinkrCoral.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.dinkrCoral.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("DinkrGroup Rules")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.appBackground)
        .sheet(isPresented: $showReportSheet) {
            ReportViolationSheet()
        }
    }

    // MARK: - Agreement section

    private var agreementSection: some View {
        VStack(spacing: 14) {
            if hasAgreed {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.dinkrGreen)
                    Text("You've agreed to these rules")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.dinkrGreen.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        hasAgreed = true
                    }
                    HapticManager.medium()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("I Agree to Rules")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.dinkrGreen.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Rule Card

private struct RuleCard: View {
    let rule: GroupRule

    var body: some View {
        HStack(alignment: .top, spacing: 14) {

            // Number badge
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(rule.id)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.dinkrGreen)
            }

            // Content
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(rule.title)
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Image(systemName: rule.systemIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.dinkrNavy.opacity(0.55))
                }
                Text(rule.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.10), lineWidth: 1)
        )
    }
}

// MARK: - Report Violation Sheet

private struct ReportViolationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var reportText = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Describe the violation so admins can investigate promptly.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $reportText)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(Color.secondary.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    )

                Button {
                    HapticManager.medium()
                    dismiss()
                } label: {
                    Text("Submit Report")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dinkrCoral)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(reportText.trimmingCharacters(in: .whitespaces).isEmpty)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Report Violation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Member view") {
    NavigationStack {
        GroupRulesView(showAgreementButton: false)
    }
}

#Preview("Non-member view") {
    NavigationStack {
        GroupRulesView(showAgreementButton: true)
    }
}
