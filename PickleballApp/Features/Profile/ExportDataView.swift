import SwiftUI

// MARK: - ExportDataView

struct ExportDataView: View {
    @State private var exportProfile = true
    @State private var exportGameHistory = true
    @State private var exportMessages = true
    @State private var exportSettings = true

    @State private var isRequesting = false
    @State private var showSuccessToast = false
    @State private var progressValue: Double = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                headerSection
                categoriesSection
                requestSection
                legalSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Export My Data")
            .navigationBarTitleDisplayMode(.large)

            // Success Toast
            if showSuccessToast {
                successToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(99)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSuccessToast)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Section {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dinkrSky.opacity(0.2), Color.dinkrSky.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    Circle()
                        .stroke(Color.dinkrSky.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 64, height: 64)
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(Color.dinkrSky)
                }

                VStack(spacing: 6) {
                    Text("Download Your Dinkr Data")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("Select the categories you'd like to include in your export. We'll prepare a file and send it to your registered email.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        Section {
            ForEach(exportCategories) { category in
                ExportCategoryRow(category: category, isOn: bindingFor(category))
            }
        } header: {
            HStack {
                Text("Select Data to Export")
                Spacer()
                Button(allSelected ? "Deselect All" : "Select All") {
                    let newValue = !allSelected
                    withAnimation {
                        exportProfile = newValue
                        exportGameHistory = newValue
                        exportMessages = newValue
                        exportSettings = newValue
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dinkrSky)
            }
        }
    }

    private var allSelected: Bool {
        exportProfile && exportGameHistory && exportMessages && exportSettings
    }

    private func bindingFor(_ category: ExportCategory) -> Binding<Bool> {
        switch category.id {
        case "profile":       return $exportProfile
        case "game_history":  return $exportGameHistory
        case "messages":      return $exportMessages
        case "settings":      return $exportSettings
        default:              return .constant(false)
        }
    }

    private var exportCategories: [ExportCategory] {
        [
            ExportCategory(
                id: "profile",
                title: "Profile",
                detail: "Name, avatar, bio, skill level, DUPR rating",
                icon: "person.crop.circle.fill",
                color: Color.dinkrGreen
            ),
            ExportCategory(
                id: "game_history",
                title: "Game History",
                detail: "All played games, scores, match results, stats",
                icon: "figure.pickleball",
                color: Color.dinkrSky
            ),
            ExportCategory(
                id: "messages",
                title: "Messages",
                detail: "Direct messages and group chat history",
                icon: "message.fill",
                color: Color.dinkrNavy
            ),
            ExportCategory(
                id: "settings",
                title: "Settings & Preferences",
                detail: "App preferences, notification settings, privacy choices",
                icon: "gearshape.2.fill",
                color: Color.dinkrAmber
            ),
        ]
    }

    // MARK: - Request Section

    private var requestSection: some View {
        Section {
            VStack(spacing: 16) {
                // Progress bar (only shown during export)
                if isRequesting {
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.dinkrSky.opacity(0.15))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.dinkrSky, Color.dinkrGreen],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * progressValue, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: progressValue)
                            }
                        }
                        .frame(height: 8)

                        Text("Preparing your export\u{2026}")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                }

                // Request button
                Button(action: requestExport) {
                    HStack(spacing: 10) {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        Text(isRequesting ? "Processing\u{2026}" : "Request Export")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        isRequesting
                            ? Color.dinkrSky.opacity(0.6)
                            : Color.dinkrSky,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRequesting || nothingSelected)
                .animation(.easeInOut(duration: 0.2), value: isRequesting)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical, 4)
        }
    }

    private var nothingSelected: Bool {
        !exportProfile && !exportGameHistory && !exportMessages && !exportSettings
    }

    private func requestExport() {
        guard !nothingSelected else { return }
        isRequesting = true
        progressValue = 0

        // Simulate progress
        let steps: [(Double, Double)] = [(0.3, 0.4), (0.6, 0.8), (0.85, 1.3), (1.0, 1.8)]
        for (value, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation { progressValue = value }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            isRequesting = false
            withAnimation { showSuccessToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation { showSuccessToast = false }
            }
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dinkrSky)
                Text("Data exports comply with applicable privacy regulations including GDPR and CCPA.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dinkrSky.opacity(0.06))
                    .padding(.horizontal, 4)
            )
        }
    }

    // MARK: - Success Toast

    private var successToast: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.dinkrGreen)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Export Requested!")
                    .font(.subheadline.weight(.bold))
                Text("You'll receive an email within 24 hours.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.dinkrGreen.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }
}

// MARK: - Export Category Model

private struct ExportCategory: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let color: Color
}

// MARK: - Export Category Row

private struct ExportCategoryRow: View {
    let category: ExportCategory
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(category.color.opacity(isOn ? 0.18 : 0.08))
                    .frame(width: 40, height: 40)
                    .animation(.easeInOut(duration: 0.2), value: isOn)
                Image(systemName: category.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isOn ? category.color : category.color.opacity(0.4))
                    .animation(.easeInOut(duration: 0.2), value: isOn)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(category.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isOn ? Color.primary : Color.secondary)
                    .animation(.easeInOut(duration: 0.2), value: isOn)
                Text(category.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Custom checkmark toggle
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(isOn ? Color.dinkrSky : Color(UIColor.systemGray5))
                    .frame(width: 28, height: 28)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isOn.toggle()
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExportDataView()
    }
}
