import Foundation

// MARK: - No-Show Report

struct NoShowReport: Identifiable, Codable {
    var id: String
    var sessionId: String
    var reportedUserId: String
    var reportedByUserId: String
    var createdAt: Date
}

// MARK: - Attendance Confirmation

/// Per-player attendance record written after a session ends.
struct AttendanceRecord: Identifiable, Codable {
    var id: String          // "\(sessionId)_\(userId)"
    var sessionId: String
    var userId: String
    var confirmedAt: Date
    var noShowReports: [String]   // userIds who reported this player as absent
    var status: AttendanceStatus

    enum AttendanceStatus: String, Codable {
        case pending       // confirmation window open
        case confirmed     // player confirmed they showed up
        case noShow        // 2+ reports filed → marked no-show
        case excused       // host manually excused the player
    }
}

// MARK: - Session Confirmation Prompt

/// Lightweight struct surfaced to the current user when a session
/// they RSVPed to has ended and is awaiting confirmation.
struct SessionConfirmationPrompt: Identifiable {
    var id: String { sessionId }
    var sessionId: String
    var sessionCourtName: String
    var sessionDateTime: Date
    var hostId: String
    var hostName: String
    var rsvpUserIds: [String]     // all players to confirm/report
    var currentUserId: String
    var deadline: Date            // confirmation window closes (sessionDateTime + 24h)

    var isExpired: Bool { Date() > deadline }
    var timeAgoString: String {
        let interval = Date().timeIntervalSince(sessionDateTime)
        let hours = Int(interval / 3600)
        if hours < 1 { return "just ended" }
        if hours == 1 { return "1 hour ago" }
        return "\(hours) hours ago"
    }
}

// MARK: - No-Show Service

@Observable
final class NoShowService {
    static let shared = NoShowService()
    private init() {}

    /// Pending prompts for the current user. In production these come from
    /// Firestore queries; here we surface a mock prompt for demo purposes.
    var pendingPrompts: [SessionConfirmationPrompt] = []

    // MARK: - Load Prompts

    func loadPendingPrompts(for userId: String) async {
        // Production: query Firestore for sessions where:
        //   - userId is in rsvps
        //   - dateTime is in the past (> session end)
        //   - confirmation window still open (< 24h ago)
        //   - user hasn't already submitted attendance
        //
        // Mock: surface one demo prompt using first mock session's metadata
        let pastDate = Date().addingTimeInterval(-5400)   // 90 min ago
        let mockSession = GameSession.mockSessions[0]

        pendingPrompts = [
            SessionConfirmationPrompt(
                sessionId: mockSession.id,
                sessionCourtName: mockSession.courtName,
                sessionDateTime: pastDate,
                hostId: mockSession.hostId,
                hostName: mockSession.hostName,
                rsvpUserIds: mockSession.rsvps,
                currentUserId: userId,
                deadline: pastDate.addingTimeInterval(86400)
            )
        ]
    }

    // MARK: - Confirm Attendance

    func confirmAttendance(sessionId: String, userId: String) async {
        // Production: write AttendanceRecord to Firestore
        //   path: game_sessions/{sessionId}/attendance/{userId}
        //   status: .confirmed
        // Award reliability points to user

        // Stub: award +0.05 reliability (capped at 5.0)
        print("[NoShowService] \(userId) confirmed attendance for \(sessionId)")

        await MainActor.run {
            pendingPrompts.removeAll { $0.sessionId == sessionId }
        }
    }

    // MARK: - Report No-Show

    func reportNoShow(sessionId: String, absentUserId: String, reportedByUserId: String) async {
        // Production:
        // 1. Write NoShowReport to Firestore
        //    path: game_sessions/{sessionId}/no_show_reports/{absentUserId}
        // 2. Cloud Function listens: if report count >= 2, set attendance status = .noShow
        //    and decrement absentUser.reliabilityScore by 0.15 (floor 1.0)
        // 3. Notify absentUser via FCM

        print("[NoShowService] \(reportedByUserId) reported \(absentUserId) as no-show in \(sessionId)")
    }

    // MARK: - Dismiss (remind later)

    func dismissPrompt(sessionId: String) {
        pendingPrompts.removeAll { $0.sessionId == sessionId }
    }
}
