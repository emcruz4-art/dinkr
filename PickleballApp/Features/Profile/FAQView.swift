import SwiftUI

// MARK: - FAQ Item Model

private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - FAQ Data

private let faqItems: [FAQItem] = [
    FAQItem(
        question: "How is my DUPR rating calculated?",
        answer: "DUPR (Dynamic Universal Pickleball Rating) is calculated using your verified match results. It considers your opponent's rating, the score, and whether it was singles or doubles. Ratings update automatically after each logged game."
    ),
    FAQItem(
        question: "How do I find games near me?",
        answer: "Head to the Play tab and tap 'Games'. Your location is used to surface open sessions nearby. Use the format filter chips (Doubles, Singles, Open Play) and the Today toggle to narrow results."
    ),
    FAQItem(
        question: "How do I set my account to private?",
        answer: "Go to Profile → Edit Profile → Player Preferences and toggle on 'Private account'. When private, only mutual friends (people you both follow) can see your full profile and stats."
    ),
    FAQItem(
        question: "How does the Marketplace work?",
        answer: "Browse listings under the Market tab. Tap any listing to see details, then tap 'Make Offer' to send the seller a price and message. Track your submitted offers under Market → My Offers."
    ),
    FAQItem(
        question: "How do I host a game?",
        answer: "Tap the + button in the Play tab header, or use the 'Host Game' quick action on the Home screen. Fill in the court, format, skill level, and time. Your game will appear in the nearby feed for other players."
    ),
    FAQItem(
        question: "How does the video highlights feed work?",
        answer: "Tap the 'Watch All' button in the Video Highlights widget on the Home screen. Scroll vertically through drill challenges and best-of clips. Double-tap to like a video."
    ),
    FAQItem(
        question: "How is my Reliability Score calculated?",
        answer: "Reliability is based on how consistently you show up to games you've joined. Canceling within 2 hours drops your score. Maintaining a score above 4.8 earns you the 'Reliable Pro' badge."
    ),
    FAQItem(
        question: "What's the difference between Follow and Friend?",
        answer: "Following is one-way — you see someone's public posts and activity. Friends are mutual follows. Private accounts are only visible to mutual friends."
    ),
    FAQItem(
        question: "How do I join a group?",
        answer: "Navigate to the Groups tab and browse or search for groups. Tap any group card to view details, then tap 'Join'. Some groups require admin approval."
    ),
    FAQItem(
        question: "How do I report a problem or give feedback?",
        answer: "Go to Settings → Support → Send Feedback. We read every submission and use your ideas to improve Dinkr. For urgent issues, email support@dinkr.app."
    )
]

// MARK: - FAQ View

struct FAQView: View {
    @State private var searchText = ""
    @State private var expandedIDs: Set<UUID> = []

    private var filteredItems: [FAQItem] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return faqItems
        }
        let query = searchText.lowercased()
        return faqItems.filter {
            $0.question.lowercased().contains(query) ||
            $0.answer.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search questions...", text: $searchText)
                            .font(.subheadline)
                            .autocorrectionDisabled()
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // FAQ accordion items
                    if filteredItems.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 38, weight: .light))
                                .foregroundStyle(Color.dinkrGreen.opacity(0.5))
                            Text("No results for \"\(searchText)\"")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredItems) { item in
                                FAQAccordionCard(
                                    item: item,
                                    isExpanded: expandedIDs.contains(item.id)
                                ) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                        if expandedIDs.contains(item.id) {
                                            expandedIDs.remove(item.id)
                                        } else {
                                            expandedIDs.insert(item.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Footer card
                    FAQFooterCard()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - FAQ Accordion Card

private struct FAQAccordionCard: View {
    let item: FAQItem
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Question row
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Text(item.question)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.dinkrGreen)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Answer (expanded)
            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)

                Text(item.answer)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isExpanded ? Color.dinkrGreen.opacity(0.3) : Color(UIColor.separator).opacity(0.3),
                    lineWidth: 1
                )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isExpanded)
    }
}

// MARK: - FAQ Footer Card

private struct FAQFooterCard: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.dinkrGreen.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.dinkrGreen)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Still have questions?")
                        .font(.subheadline.weight(.semibold))
                    Text("Our team is happy to help.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Button {
                if let url = URL(string: "mailto:support@dinkr.app") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Send Feedback", systemImage: "envelope.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.dinkrGreen, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dinkrGreen.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    FAQView()
}
