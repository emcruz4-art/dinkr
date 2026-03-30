import SwiftUI

// MARK: - Feedback Type

private enum FeedbackType: String, CaseIterable {
    case bugReport = "Bug Report"
    case featureRequest = "Feature Request"
    case general = "General Feedback"
}

// MARK: - Feedback View

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var feedbackType: FeedbackType = .general
    @State private var message = ""
    @State private var email = ""
    @State private var didSubmit = false
    @State private var isSubmitting = false

    private var isSubmitDisabled: Bool {
        message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Main form
                ScrollView {
                    VStack(spacing: 20) {
                        // Type picker
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Feedback Type", systemImage: "tag")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.3)

                            Picker("Feedback Type", selection: $feedbackType) {
                                ForEach(FeedbackType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Message
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Message", systemImage: "text.alignleft")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.3)

                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .frame(minHeight: 120)

                                if message.isEmpty {
                                    Text("Describe your feedback...")
                                        .font(.subheadline)
                                        .foregroundStyle(Color(UIColor.placeholderText))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 13)
                                        .allowsHitTesting(false)
                                }

                                TextEditor(text: $message)
                                    .font(.subheadline)
                                    .scrollContentBackground(.hidden)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .frame(minHeight: 120)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(UIColor.separator).opacity(0.4), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)

                        // Email (optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Email (optional)", systemImage: "envelope")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.3)

                            TextField("your@email.com", text: $email)
                                .font(.subheadline)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(UIColor.separator).opacity(0.4), lineWidth: 1)
                                )

                            Text("We'll only use this to follow up on your feedback.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)

                        // Submit button
                        Button {
                            submitFeedback()
                        } label: {
                            HStack(spacing: 8) {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.85)
                                }
                                Text("Submit Feedback")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                isSubmitDisabled
                                    ? Color.dinkrGreen.opacity(0.4)
                                    : Color.dinkrGreen,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .disabled(isSubmitDisabled)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
                .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())

                // Success overlay
                if didSubmit {
                    ZStack {
                        Color(UIColor.systemBackground)
                            .opacity(0.96)
                            .ignoresSafeArea()

                        VStack(spacing: 18) {
                            ZStack {
                                Circle()
                                    .fill(Color.dinkrGreen.opacity(0.14))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color.dinkrGreen)
                            }

                            VStack(spacing: 6) {
                                Text("Thanks for your feedback!")
                                    .font(.title3.weight(.bold))
                                Text("We read every submission and use your ideas to improve Dinkr.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: didSubmit)
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func submitFeedback() {
        isSubmitting = true
        // Stub: simulate submission delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isSubmitting = false
            withAnimation {
                didSubmit = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FeedbackView()
}
