import Foundation

struct PollTimeSlot: Identifiable, Codable, Hashable {
    var id: String
    var dateTime: Date
    var votes: [String]  // userIds who voted for this slot

    var voteCount: Int { votes.count }
}

struct AvailabilityPoll: Identifiable, Codable {
    var id: String
    var groupId: String
    var createdByUserId: String
    var createdByName: String
    var question: String        // e.g. "When should we play this week?"
    var timeSlots: [PollTimeSlot]
    var createdAt: Date
    var closesAt: Date
    var linkedSessionId: String?  // set when host creates a session from the winning slot

    var isOpen: Bool { Date() < closesAt }
    var winningSlot: PollTimeSlot? {
        timeSlots.max { $0.voteCount < $1.voteCount }
    }
    var totalVotes: Int { Set(timeSlots.flatMap { $0.votes }).count }  // unique voters
}

extension AvailabilityPoll {
    static let mock: AvailabilityPoll = {
        let now = Date()
        let cal = Calendar.current
        let slot1Date = cal.date(byAdding: .day, value: 1, to: now).flatMap {
            cal.date(bySettingHour: 18, minute: 0, second: 0, of: $0)
        } ?? now
        let slot2Date = cal.date(byAdding: .day, value: 2, to: now).flatMap {
            cal.date(bySettingHour: 7, minute: 30, second: 0, of: $0)
        } ?? now
        let slot3Date = cal.date(byAdding: .day, value: 3, to: now).flatMap {
            cal.date(bySettingHour: 17, minute: 0, second: 0, of: $0)
        } ?? now
        return AvailabilityPoll(
            id: "poll_001",
            groupId: "group_001",
            createdByUserId: "user_002",
            createdByName: "Maria Chen",
            question: "When should we play this week?",
            timeSlots: [
                PollTimeSlot(id: "slot_1", dateTime: slot1Date,
                             votes: ["user_002", "user_003", "user_004"]),
                PollTimeSlot(id: "slot_2", dateTime: slot2Date,
                             votes: ["user_002", "user_005"]),
                PollTimeSlot(id: "slot_3", dateTime: slot3Date,
                             votes: ["user_003", "user_004", "user_005", "user_006"]),
            ],
            createdAt: cal.date(byAdding: .hour, value: -3, to: now) ?? now,
            closesAt: cal.date(byAdding: .hour, value: 21, to: now) ?? now,
            linkedSessionId: nil
        )
    }()
}
