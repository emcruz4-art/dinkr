import SwiftUI

// MARK: - AssessmentQuestion Model

struct AssessmentQuestion: Identifiable {
    let id: Int
    let question: String
    let answers: [String]
    let correctIndex: Int
    let explanation: String
}

// MARK: - Question Data

private let assessmentQuestions: [AssessmentQuestion] = [
    AssessmentQuestion(
        id: 0,
        question: "How long have you been playing pickleball?",
        answers: ["Just getting started", "Less than a year", "1–3 years", "3+ years"],
        correctIndex: -1,
        explanation: "Your experience shapes your overall skill baseline."
    ),
    AssessmentQuestion(
        id: 1,
        question: "Which shot are you most comfortable with?",
        answers: ["Dink", "Third shot drop", "Drive", "Lob"],
        correctIndex: -1,
        explanation: "Shot preference reflects your playing style and comfort zone."
    ),
    AssessmentQuestion(
        id: 2,
        question: "Can you consistently hit a third shot drop?",
        answers: ["Not yet", "Sometimes — still working on it", "Usually yes", "Yes, it's a weapon of mine"],
        correctIndex: -1,
        explanation: "The third shot drop is a hallmark skill of intermediate+ players."
    ),
    AssessmentQuestion(
        id: 3,
        question: "Do you know the kitchen (NVZ) rules?",
        answers: ["Not really", "I know the basics", "Yes, solid understanding", "Yes, including momentum rules"],
        correctIndex: -1,
        explanation: "Understanding NVZ rules is essential for competitive play."
    ),
    AssessmentQuestion(
        id: 4,
        question: "What's your typical game format?",
        answers: ["Open play / drop-in", "Casual doubles with friends", "Organized recreational league", "Competitive tournaments"],
        correctIndex: -1,
        explanation: "Your game format reflects your current commitment level."
    ),
    AssessmentQuestion(
        id: 5,
        question: "How would you describe your net game?",
        answers: ["I avoid the net", "I get to the net sometimes", "I'm comfortable at the net", "I dominate at the NVZ line"],
        correctIndex: -1,
        explanation: "Net-game confidence is a strong indicator of skill level."
    ),
    AssessmentQuestion(
        id: 6,
        question: "Do you play in any organized leagues?",
        answers: ["No, not yet", "I've tried it once or twice", "Yes, recreational league", "Yes, competitive/rated league"],
        correctIndex: -1,
        explanation: "League play signals consistent engagement with the sport."
    ),
    AssessmentQuestion(
        id: 7,
        question: "How often do you play per week?",
        answers: ["Less than once a week", "Once a week", "2–3 times a week", "4+ times a week"],
        correctIndex: -1,
        explanation: "Frequency of play is a strong driver of skill development."
    )
]

// MARK: - Skill Result

private struct SkillResult {
    let level: String
    let emoji: String
    let description: String
}

private func computeSkillResult(answers: [Int]) -> SkillResult {
    // Score based on answer indices (higher index = more advanced)
    let total = answers.reduce(0, +)
    let maxScore = (assessmentQuestions.count - 1) * 3 // each Q has 4 options → max index 3
    let ratio = Double(total) / Double(maxScore)

    switch ratio {
    case ..<0.25:
        return SkillResult(
            level: "2.0 — Beginner",
            emoji: "🌱",
            description: "You're just getting started — welcome! Dinkr will help you find beginner-friendly games and coaches to accelerate your progress."
        )
    case 0.25..<0.42:
        return SkillResult(
            level: "2.5 — Developing",
            emoji: "🎯",
            description: "You've got the basics down and are building consistency. Focus on dinking rallies and kitchen positioning to level up."
        )
    case 0.42..<0.58:
        return SkillResult(
            level: "3.0 — Intermediate",
            emoji: "⚡️",
            description: "You can hold your own in casual games. Working on your third shot drop and net game will get you to the next tier fast."
        )
    case 0.58..<0.75:
        return SkillResult(
            level: "3.5 — Intermediate",
            emoji: "🏓",
            description: "You're competitive and strategic. You understand court positioning and are developing a well-rounded game."
        )
    case 0.75..<0.88:
        return SkillResult(
            level: "4.0 — Advanced",
            emoji: "🔥",
            description: "You're a strong player with consistent shot-making and good tactical awareness. Tournament play is where you belong."
        )
    default:
        return SkillResult(
            level: "4.5+ — Elite",
            emoji: "🏆",
            description: "You're operating at a high competitive level. Time to find tournament brackets and elite training partners."
        )
    }
}

// MARK: - Answer Card

private struct AnswerCard: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void

    @State private var tapped = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                tapped = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                tapped = false
            }
            onTap()
        }) {
            HStack {
                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.dinkrGreen : Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? Color.dinkrGreen : Color.secondary.opacity(0.2),
                                lineWidth: 1.5
                            )
                    )
            )
            .scaleEffect(tapped ? 0.97 : (isSelected ? 1.02 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Confetti Burst

private struct ConfettiBurstView: View {
    @State private var burst = false

    private let confettiEmojis = ["🎉", "✨", "🏓", "⭐️", "🎊", "💥", "🌟", "🥳"]

    var body: some View {
        ZStack {
            ForEach(Array(confettiEmojis.enumerated()), id: \.offset) { index, emoji in
                let angle = Double(index) / Double(confettiEmojis.count) * 360.0
                let radians = angle * .pi / 180
                let distance: CGFloat = burst ? 110 : 0

                Text(emoji)
                    .font(.system(size: burst ? 28 : 10))
                    .offset(
                        x: cos(radians) * distance,
                        y: sin(radians) * distance
                    )
                    .opacity(burst ? 1.0 : 0.0)
                    .scaleEffect(burst ? 1.0 : 0.2)
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.65)
                            .delay(Double(index) * 0.04),
                        value: burst
                    )
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                burst = true
            }
        }
    }
}

// MARK: - Result View

private struct SkillResultView: View {
    let result: SkillResult
    let onConfirm: () -> Void
    let onAdjust: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Confetti burst around emoji
            ZStack {
                ConfettiBurstView()

                Text(result.emoji)
                    .font(.system(size: 72))
                    .scaleEffect(appeared ? 1.0 : 0.3)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1), value: appeared)
            }
            .frame(width: 240, height: 240)

            VStack(spacing: 12) {
                Text("You're a")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text(result.level)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(Color.dinkrGreen)
                    .multilineTextAlignment(.center)
                    .scaleEffect(appeared ? 1.0 : 0.7)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.25), value: appeared)

                Text(result.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: onConfirm) {
                    Text("This looks right!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dinkrGreen)
                        .cornerRadius(16)
                }

                Button(action: onAdjust) {
                    Text("Adjust my level")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.dinkrNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.cardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.dinkrNavy.opacity(0.3), lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .onAppear {
            appeared = true
        }
    }
}

// MARK: - SkillAssessmentView

struct SkillAssessmentView: View {
    var onComplete: (String) -> Void = { _ in }

    @State private var currentQuestionIndex = 0
    @State private var selectedAnswerIndex: Int? = nil
    @State private var answers: [Int] = []
    @State private var showResult = false
    @State private var progressValue: Double = 0.0

    private var currentQuestion: AssessmentQuestion {
        assessmentQuestions[currentQuestionIndex]
    }

    private var isLastQuestion: Bool {
        currentQuestionIndex == assessmentQuestions.count - 1
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if showResult {
                let result = computeSkillResult(answers: answers)
                SkillResultView(
                    result: result,
                    onConfirm: {
                        onComplete(result.level)
                    },
                    onAdjust: {
                        // Reset to allow manual adjustment
                        currentQuestionIndex = 0
                        answers = []
                        selectedAnswerIndex = nil
                        progressValue = 0
                        withAnimation(.spring()) {
                            showResult = false
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                questionContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showResult)
    }

    private var questionContent: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.dinkrGreen)
                            .frame(width: geo.size.width * progressValue, height: 6)
                            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: progressValue)
                    }
                }
                .frame(height: 6)

                Text("Question \(currentQuestionIndex + 1) of \(assessmentQuestions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 28)

            // Question text
            Text(currentQuestion.question)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .id("question-\(currentQuestionIndex)")
                .transition(.opacity)

            // Answer options
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(currentQuestion.answers.enumerated()), id: \.offset) { index, answer in
                        AnswerCard(
                            text: answer,
                            isSelected: selectedAnswerIndex == index
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                selectedAnswerIndex = index
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // Next button
            Button {
                guard let selected = selectedAnswerIndex else { return }
                var updatedAnswers = answers
                updatedAnswers.append(selected)

                let nextProgress = Double(currentQuestionIndex + 1) / Double(assessmentQuestions.count)

                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    progressValue = nextProgress
                }

                if isLastQuestion {
                    answers = updatedAnswers
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        showResult = true
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        answers = updatedAnswers
                        currentQuestionIndex += 1
                        selectedAnswerIndex = nil
                    }
                }
            } label: {
                Text(isLastQuestion ? "See My Level" : "Next")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        selectedAnswerIndex != nil
                            ? Color.dinkrGreen
                            : Color.dinkrGreen.opacity(0.35)
                    )
                    .cornerRadius(16)
                    .animation(.easeInOut(duration: 0.2), value: selectedAnswerIndex)
            }
            .disabled(selectedAnswerIndex == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .padding(.top, 16)
        }
    }
}

// MARK: - Preview

#Preview("Assessment") {
    SkillAssessmentView { level in
        print("Completed with level: \(level)")
    }
}

#Preview("Result") {
    SkillResultView(
        result: SkillResult(
            level: "3.5 — Intermediate",
            emoji: "🏓",
            description: "You're competitive and strategic. You understand court positioning and are developing a well-rounded game."
        ),
        onConfirm: {},
        onAdjust: {}
    )
}
