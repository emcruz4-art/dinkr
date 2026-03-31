import SwiftUI

// MARK: - CommunityRule Model

private struct CommunityRule: Identifiable {
    let id: UUID
    let icon: String
    let iconColor: Color
    let title: String
    let body: String

    init(icon: String, iconColor: Color, title: String, body: String) {
        self.id = UUID()
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.body = body
    }
}

// MARK: - CommunityRulesView

struct CommunityRulesView: View {
    @State private var showReportSheet = false

    private let rules: [CommunityRule] = [
        CommunityRule(
            icon: "heart.fill",
            iconColor: Color.dinkrCoral,
            title: "Be Respectful",
            body: "Treat every player the way you'd want to be treated on the court. Differences in skill level, age, background, or experience are never grounds for ridicule or hostility.\n\nConstructive feedback is welcome; personal attacks are not. Disagreements happen — handle them with grace. A kind word after a tough match goes further than you think."
        ),
        CommunityRule(
            icon: "scale.3d",
            iconColor: Color.dinkrGreen,
            title: "Play Fair",
            body: "Honesty on the court and in the app is non-negotiable. Report scores accurately, call lines in good faith, and never manipulate ratings or rankings for personal gain.\n\nCheating, sandbagging, or gaming the matchmaking system harms the entire community. When in doubt on a call, give the point to your opponent — that's the spirit of the game.\n\nCommercia activity, unauthorized promotions, and spam are prohibited on all Dinkr surfaces."
        ),
        CommunityRule(
            icon: "person.3.fill",
            iconColor: Color.dinkrSky,
            title: "Inclusive Community",
            body: "Dinkr is for everyone. We do not tolerate discrimination based on race, gender, sexual orientation, religion, disability, national origin, or any other protected characteristic.\n\nWe actively work to make pickleball accessible — in language, design, and culture. Help us by welcoming newcomers, offering encouragement, and calling out exclusionary behavior when you see it.\n\nRepresent the Dinkr community proudly both on and off the app."
        ),
        CommunityRule(
            icon: "text.badge.checkmark",
            iconColor: Color.dinkrNavy,
            title: "Content Standards",
            body: "Everything you post — photos, videos, comments, group messages — must comply with these guidelines and applicable law. Explicit, violent, or hateful content will be removed immediately.\n\nDo not share another person's private information without their consent. Impersonating another player, public figure, or Dinkr staff is prohibited and may result in permanent account removal.\n\nSponsored or commercial content must be clearly labeled. Unauthorized advertising, affiliate links, and solicitation are not allowed."
        ),
        CommunityRule(
            icon: "flag.fill",
            iconColor: Color.dinkrAmber,
            title: "Reporting Policy",
            body: "If you witness a violation, use the in-app report tool on any post, message, or profile. Reports are reviewed by our Trust & Safety team, typically within 48 hours.\n\nReports are confidential — the reported user will not be told who flagged them. False or malicious reports undermine the system and may themselves result in action against the reporting account.\n\nFor urgent safety concerns, contact us directly at safety@dinkr.io."
        ),
        CommunityRule(
            icon: "exclamationmark.shield.fill",
            iconColor: Color.dinkrCoral,
            title: "Consequences",
            body: "Violations may result in a range of actions depending on severity and history: a warning, temporary feature restrictions, content removal, account suspension, or permanent ban.\n\nSerious violations — including threats, harassment campaigns, or illegal content — will be escalated to law enforcement when appropriate. Dinkr reserves the right to take action at its discretion to protect the community.\n\nYou may appeal moderation decisions by emailing appeals@dinkr.io within 30 days of the action."
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Welcome header
                welcomeHeader

                // Rule sections
                ForEach(rules) { rule in
                    CommunityRuleSection(rule: rule)
                }

                // Report button
                reportButton
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Community Guidelines")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showReportSheet) {
            ReportContentView(
                reportType: .post,
                contentPreview: "Community Guidelines Violation",
                reportedUserName: "User"
            )
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrGreen, Color.dinkrGreen.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Text("🏓")
                        .font(.system(size: 26))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome to Dinkr")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.dinkrNavy)
                    Text("Last updated March 2026")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Text("Dinkr is built on respect, inclusivity, and love for the game 🏓")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("These guidelines exist so every player — from first-timer to 5.0 — feels safe, welcome, and excited to come back. Please read them and play accordingly.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Report Button

    private var reportButton: some View {
        VStack(spacing: 10) {
            Divider()

            Text("See something that doesn't belong here?")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Button {
                showReportSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Report a Violation")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.dinkrCoral, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - CommunityRuleSection

private struct CommunityRuleSection: View {
    let rule: CommunityRule
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header — tappable to collapse
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(rule.iconColor.opacity(0.14))
                            .frame(width: 38, height: 38)
                        Image(systemName: rule.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(rule.iconColor)
                    }

                    Text(rule.title)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.dinkrNavy)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                // Body text
                Text(rule.body)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CommunityRulesView()
    }
}
