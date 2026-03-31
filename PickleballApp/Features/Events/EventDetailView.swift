import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: Event
    @State private var showBracketBuilder = false
    @State private var showRegistration = false
    @State private var showAttendees = false
    @State private var isBookmarked = false
    @State private var showCheckIn = false
    @State private var showRecap = false
    @State private var showTournamentResults = false
    @State private var isFollowingOrganizer = false

    private var mockBracket: Bracket? {
        Bracket.mock.eventId == event.id ? Bracket.mock : nil
    }

    // MARK: - Event type color

    private var typeColor: Color {
        switch event.type {
        case .tournament: return Color.dinkrCoral
        case .clinic:     return Color.dinkrSky
        case .openPlay:   return Color.dinkrGreen
        case .social:     return Color.dinkrAmber
        case .womenOnly:  return .pink
        case .fundraiser: return .purple
        }
    }

    // MARK: - Countdown

    /// Days until event. Returns nil if event is in the past.
    private var daysUntilEvent: Int? {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: event.dateTime).day ?? 0
        return days >= 0 ? days : nil
    }

    /// Days until registration deadline.
    private var daysUntilRegistration: Int? {
        guard let deadline = event.registrationDeadline else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        return days >= 0 ? days : nil
    }

    // MARK: - Similar Events

    private var similarEvents: [Event] {
        Array(Event.mockEvents.filter { $0.id != event.id }.prefix(4))
    }

    // MARK: - Share URL

    private var shareURL: URL {
        URL(string: "https://dinkr.app/events/\(event.id)") ?? URL(string: "https://dinkr.app")!
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Hero banner ──────────────────────────────────────────────
                heroBanner

                VStack(alignment: .leading, spacing: 20) {

                    // ── Date / Location / countdown chips ───────────────────
                    dateLocationSection

                    // ── Registration deadline chip ───────────────────────────
                    if let days = daysUntilRegistration {
                        registrationDeadlineChip(days: days)
                    }

                    // ── Map + Get Directions ─────────────────────────────────
                    if let coords = event.coordinates {
                        mapSection(coords: coords)
                    }

                    Divider()

                    // ── About ────────────────────────────────────────────────
                    Text("About").font(.headline)
                    Text(event.description).font(.subheadline).foregroundStyle(.secondary)

                    // ── Stats row ────────────────────────────────────────────
                    HStack(spacing: 12) {
                        if let fee = event.entryFee {
                            StatChip(icon: "dollarsign.circle", value: String(format: "$%.0f", fee), label: "Entry")
                        }
                        if let max = event.maxParticipants {
                            StatChip(icon: "person.2", value: "\(event.currentParticipants)/\(max)", label: "Registered")
                        }
                        if let prize = event.prizePool {
                            StatChip(icon: "trophy", value: prize, label: "Prize Pool")
                        }
                    }

                    // ── Tags ─────────────────────────────────────────────────
                    if !event.tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(event.tags, id: \.self) { tag in
                                PillTag(text: "#\(tag)")
                            }
                        }
                    }

                    Divider()

                    // ── Organizer card ───────────────────────────────────────
                    organizerCard

                    Divider()

                    // ── Social proof ─────────────────────────────────────────
                    socialProofRow

                    // ── Attendees ────────────────────────────────────────────
                    attendeesSection

                    // ── Nearby parking ───────────────────────────────────────
                    parkingSection

                    // ── Agenda / Schedule ────────────────────────────────────
                    agendaSection

                    Divider()

                    // ── CTA ──────────────────────────────────────────────────
                    if event.isRegistered {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.dinkrGreen)
                            Text("You're registered!")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dinkrGreen.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                    } else if event.entryFee != nil || event.type == .tournament {
                        Button("Register Now") { showRegistration = true }
                            .primaryButton()
                    } else {
                        Button("Learn More") {}
                            .primaryButton()
                    }

                    Divider()

                    // ── Bracket ──────────────────────────────────────────────
                    bracketSection

                    Divider()

                    // ── Similar Events ───────────────────────────────────────
                    similarEventsSection
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Share
                ShareLink(
                    item: shareURL,
                    subject: Text(event.title),
                    message: Text("Check out this event on Dinkr!")
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.dinkrSky)
                }

                // Check In — only visible for registered attendees
                if event.isRegistered {
                    Button {
                        showCheckIn = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    .accessibilityLabel("Check In")
                }

                // Recap — available after event (past events)
                if daysUntilEvent == nil {
                    // Tournament results for completed tournaments
                    if event.type == .tournament {
                        Button {
                            showTournamentResults = true
                        } label: {
                            Image(systemName: "medal.fill")
                                .foregroundStyle(Color.dinkrAmber)
                        }
                        .accessibilityLabel("View Tournament Results")
                    } else {
                        Button {
                            showRecap = true
                        } label: {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(Color.dinkrAmber)
                        }
                        .accessibilityLabel("View Recap")
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isBookmarked.toggle()
                    }
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(isBookmarked ? Color.dinkrAmber : Color.primary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Save event")
            }
        }
        .sheet(isPresented: $showBracketBuilder) {
            BracketBuilderView()
        }
        .sheet(isPresented: $showRegistration) {
            TournamentRegistrationView(event: event)
        }
        .sheet(isPresented: $showAttendees) {
            AttendeeListView(event: event)
        }
        .sheet(isPresented: $showCheckIn) {
            NavigationStack {
                EventCheckInView(event: event)
            }
        }
        .sheet(isPresented: $showRecap) {
            NavigationStack {
                EventRecapView(event: event)
            }
        }
        .sheet(isPresented: $showTournamentResults) {
            NavigationStack {
                TournamentResultsView(
                    eventName: event.title,
                    division: event.tags.first(where: { $0.contains("doubles") || $0.contains("singles") })?.capitalized ?? "Open Division",
                    bracket: mockBracket
                )
            }
        }
    }

    // MARK: - Hero Banner

    @ViewBuilder
    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            // Base gradient using event type color
            LinearGradient(
                colors: [
                    typeColor,
                    typeColor.opacity(0.72),
                    Color.dinkrNavy.opacity(0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 220)

            // Subtle court-pattern overlay
            Canvas { context, size in
                let lineColor = Color.white.opacity(0.06)
                var path = Path()
                let hSpacing: CGFloat = 20
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += hSpacing
                }
                let vSpacing: CGFloat = 28
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += vSpacing
                }
                context.stroke(path, with: .color(lineColor), lineWidth: 0.7)
                var centerPath = Path()
                centerPath.move(to: CGPoint(x: size.width / 2, y: 0))
                centerPath.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                context.stroke(centerPath, with: .color(Color.white.opacity(0.10)), lineWidth: 1.5)
            }
            .frame(height: 220)

            // Bottom scrim for readability
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.42)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)

            // Banner content
            VStack(alignment: .leading, spacing: 8) {
                EventTypeBadge(type: event.type)

                Text(event.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.30), radius: 4, x: 0, y: 2)
                    .lineLimit(3)

                if event.isRegistered {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Registered")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dinkrGreen, in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .frame(height: 220)
    }

    // MARK: - Date / Location Section

    @ViewBuilder
    private var dateLocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                InfoChip(icon: "calendar", label: event.dateTime.shortDateString)
                InfoChip(icon: "clock", label: event.dateTime.timeString)
                if let days = daysUntilEvent, days < 7 {
                    countdownChip(days: days)
                }
            }
            Label(event.location, systemImage: "mappin.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Registration Deadline Chip

    @ViewBuilder
    private func registrationDeadlineChip(days: Int) -> some View {
        let label: String = {
            switch days {
            case 0:  return "Registration closes today!"
            case 1:  return "Registration closes tomorrow"
            default: return "Registration closes in \(days) days"
            }
        }()

        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: 11, weight: .bold))
            Text(label)
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(days <= 3 ? Color.dinkrCoral : Color.dinkrAmber, in: Capsule())
    }

    // MARK: - Map Section

    @ViewBuilder
    private func mapSection(coords: GeoPoint) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: coords.clLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))) {
                Marker(event.title, coordinate: coords.clLocation)
                    .tint(typeColor)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                openMapsDirections(coords: coords)
            } label: {
                Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
            }
            .secondaryButton()
        }
    }

    // MARK: - Organizer Card

    @ViewBuilder
    private var organizerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .foregroundStyle(typeColor)
                Text("Organizer")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                AvatarView(
                    displayName: event.organizer.isEmpty ? "Dinkr" : event.organizer,
                    size: 48
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(event.organizer.isEmpty ? "Dinkr Community" : event.organizer)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Organizer")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.dinkrNavy)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.dinkrAmber, in: Capsule())
                    }
                    HStack(spacing: 3) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < 4 ? "star.fill" : "star.leadinghalf.filled")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.dinkrAmber)
                        }
                        Text("4.8")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isFollowingOrganizer.toggle()
                    }
                } label: {
                    Text(isFollowingOrganizer ? "Following" : "Follow")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isFollowingOrganizer ? Color.dinkrGreen : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            isFollowingOrganizer
                                ? Color.dinkrGreen.opacity(0.15)
                                : Color.dinkrGreen,
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isFollowingOrganizer ? Color.dinkrGreen : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: typeColor.opacity(0.10), radius: 8, x: 0, y: 3)
        }
    }

    // MARK: - Social Proof Row

    @ViewBuilder
    private var socialProofRow: some View {
        HStack(spacing: 10) {
            AvatarGroupView(
                names: ["Sarah J.", "Marcus W.", "others"],
                size: 28,
                maxVisible: 3
            )
            Text("Sarah J., Marcus W. and 3 others you follow are going")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(Color.dinkrGreen.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Nearby Parking

    @ViewBuilder
    private var parkingSection: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.dinkrSky.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "parkingsign.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.dinkrSky)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Nearby Parking")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Parking available at main lot, 2-min walk")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Agenda / Schedule

    private struct AgendaItem {
        let time: String
        let title: String
        let isHighlighted: Bool
    }

    private let agendaItems: [AgendaItem] = [
        AgendaItem(time: "8:00 AM",  title: "Check-in & Warm-up",   isHighlighted: false),
        AgendaItem(time: "9:00 AM",  title: "Opening Ceremony",      isHighlighted: false),
        AgendaItem(time: "9:30 AM",  title: "Round 1 Begins",        isHighlighted: true),
        AgendaItem(time: "12:00 PM", title: "Lunch Break",           isHighlighted: false),
        AgendaItem(time: "1:00 PM",  title: "Semifinals",            isHighlighted: true),
        AgendaItem(time: "3:00 PM",  title: "Finals & Awards",       isHighlighted: true),
    ]

    @ViewBuilder
    private var agendaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundStyle(typeColor)
                Text("Schedule")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(agendaItems.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        // Time column (fixed width for alignment)
                        Text(item.time)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(item.isHighlighted ? typeColor : Color.secondary)
                            .frame(width: 62, alignment: .trailing)

                        // Timeline column: dot + connecting line
                        VStack(spacing: 0) {
                            Circle()
                                .fill(item.isHighlighted ? typeColor : Color.secondary.opacity(0.35))
                                .frame(width: 10, height: 10)
                                .overlay(
                                    item.isHighlighted
                                        ? Circle().strokeBorder(typeColor.opacity(0.28), lineWidth: 3)
                                        : nil
                                )
                                .padding(.top, 2)
                            if index < agendaItems.count - 1 {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.18))
                                    .frame(width: 1.5)
                                    .frame(maxHeight: .infinity)
                                    .padding(.vertical, 2)
                            }
                        }
                        .frame(width: 14)

                        // Event title
                        Text(item.title)
                            .font(.subheadline.weight(item.isHighlighted ? .semibold : .regular))
                            .foregroundStyle(item.isHighlighted ? Color.primary : Color.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 38)
                }
            }
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: typeColor.opacity(0.08), radius: 8, x: 0, y: 3)
        }
    }

    // MARK: - Countdown Chip

    @ViewBuilder
    private func countdownChip(days: Int) -> some View {
        let label: String = {
            switch days {
            case 0:  return "Today!"
            case 1:  return "Tomorrow"
            default: return "Starts in \(days) days"
            }
        }()

        Text(label)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.dinkrAmber, in: Capsule())
    }

    // MARK: - Maps

    private func openMapsDirections(coords: GeoPoint) {
        let lat = coords.latitude
        let lng = coords.longitude
        let urlString = "maps://?daddr=\(lat),\(lng)&dirflg=d"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Attendees Section

    @ViewBuilder
    private var attendeesSection: some View {
        Button {
            showAttendees = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(Color.dinkrGreen)
                    Text("Attendees")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    if let max = event.maxParticipants {
                        Text("\(event.currentParticipants) / \(max)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                let previewUsers: [User] = {
                    var list = [User.mockCurrentUser]
                    list.append(contentsOf: User.mockPlayers)
                    return Array(list.prefix(8))
                }()
                let previewNames = previewUsers.map(\.displayName)
                let overflow = max(0, event.currentParticipants - 5)

                HStack(spacing: 10) {
                    AvatarGroupView(names: previewNames, size: 32, maxVisible: 5)

                    VStack(alignment: .leading, spacing: 2) {
                        if overflow > 0 {
                            Text("+\(overflow) more going")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                        } else {
                            Text("\(event.currentParticipants) going")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                        Text("Tap to see all attendees")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Similar Events Section

    @ViewBuilder
    private var similarEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.dinkrAmber)
                Text("Similar Events")
                    .font(.headline)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(similarEvents) { similar in
                        NavigationLink {
                            EventDetailView(event: similar)
                        } label: {
                            EventMiniCard(event: similar)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Bracket Section

    @ViewBuilder
    private var bracketSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bracket.square.fill")
                    .foregroundStyle(Color.dinkrGreen)
                Text("Bracket")
                    .font(.headline)
                Spacer()
            }

            if let bracket = mockBracket {
                // Condensed first-round preview
                let firstRound = bracket.rounds.first ?? []
                let previewMatches = Array(firstRound.prefix(4))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(previewMatches) { match in
                        compactMatchCard(match)
                    }
                }

                HStack(spacing: 12) {
                    NavigationLink {
                        BracketView(bracket: bracket)
                    } label: {
                        HStack {
                            Text("View Full Bracket")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.dinkrGreen)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Tournament Results link for completed events
                if daysUntilEvent == nil && event.type == .tournament {
                    Button {
                        showTournamentResults = true
                    } label: {
                        HStack {
                            Label("View Tournament Results", systemImage: "medal.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.dinkrAmber)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.dinkrAmber)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("No bracket published yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }

            // Organizer: Create Bracket button
            Button {
                showBracketBuilder = true
            } label: {
                Label("Create Bracket", systemImage: "plus.circle")
            }
            .secondaryButton()
        }
    }

    // MARK: - Compact Match Card

    @ViewBuilder
    private func compactMatchCard(_ match: NewBracketMatch) -> some View {
        VStack(spacing: 0) {
            compactPlayerRow(
                name: match.participantAName ?? "TBD",
                score: match.scoreA,
                isWinner: match.isComplete && match.winnerId == match.participantAId,
                isTBD: match.participantAId == nil
            )
            Divider()
            compactPlayerRow(
                name: match.participantBName ?? "TBD",
                score: match.scoreB,
                isWinner: match.isComplete && match.winnerId == match.participantBId,
                isTBD: match.participantBId == nil
            )
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    @ViewBuilder
    private func compactPlayerRow(name: String, score: String, isWinner: Bool, isTBD: Bool) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(isWinner ? Color.dinkrGreen : Color.clear)
                .frame(width: 3)
            Text(isTBD ? "TBD" : name)
                .font(.system(size: 11, weight: isWinner ? .bold : .regular))
                .foregroundStyle(isTBD ? Color.secondary : Color.primary)
                .lineLimit(1)
            Spacer(minLength: 2)
            if !score.isEmpty {
                Text(score)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isWinner ? Color.dinkrGreen : Color.secondary)
            }
        }
        .padding(.trailing, 6)
        .frame(height: 26)
    }
}

// MARK: - EventMiniCard

private struct EventMiniCard: View {
    let event: Event

    private var typeColor: Color {
        switch event.type {
        case .tournament: return Color.dinkrCoral
        case .clinic:     return Color.dinkrSky
        case .openPlay:   return Color.dinkrGreen
        case .social:     return Color.dinkrAmber
        case .womenOnly:  return .pink
        case .fundraiser: return .purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Mini banner
            LinearGradient(
                colors: [typeColor, typeColor.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 56)
            .overlay(alignment: .bottomLeading) {
                Text(event.dateTime.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.dinkrNavy)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white)
                    .clipShape(Capsule())
                    .padding(.leading, 10)
                    .padding(.bottom, 8)
            }
            .clipShape(
                .rect(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 12
                )
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(event.type.rawValue.capitalized)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(typeColor)

                Text(event.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Label {
                    Text(event.location)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "mappin")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.dinkrCoral)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .frame(width: 160)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: typeColor.opacity(0.18), radius: 8, x: 0, y: 4)
    }
}

// MARK: - TournamentView

struct TournamentView: View {
    var tournaments: [Event] { Event.mockEvents.filter { $0.type == .tournament } }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tournaments) { event in
                    NavigationLink {
                        EventDetailView(event: event)
                    } label: {
                        EventCardView(event: event).padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Tournaments")
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: Event.mockEvents[0])
    }
}
