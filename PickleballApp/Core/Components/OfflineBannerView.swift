import SwiftUI

// MARK: - OfflineBannerView

struct OfflineBannerView: View {
    let isConnected: Bool
    @State private var showReconnected: Bool = false
    @State private var previouslyConnected: Bool = true
    @State private var hideTask: Task<Void, Never>? = nil

    // Visible when offline OR briefly showing "Back online" after reconnect
    private var isVisible: Bool {
        !isConnected || showReconnected
    }

    var body: some View {
        VStack(spacing: 0) {
            if isVisible {
                banner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVisible)
        .onChange(of: isConnected) { oldValue, newValue in
            if newValue && !oldValue {
                // Just reconnected
                showReconnected = true
                hideTask?.cancel()
                hideTask = Task {
                    try? await Task.sleep(for: .seconds(2))
                    if !Task.isCancelled {
                        withAnimation {
                            showReconnected = false
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var banner: some View {
        if !isConnected {
            offlineBanner
        } else if showReconnected {
            reconnectedBanner
        }
    }

    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .semibold))
            Text("No internet connection")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .foregroundStyle(.black.opacity(0.85))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.dinkrAmber)
        .ignoresSafeArea(edges: .top)
    }

    private var reconnectedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi")
                .font(.system(size: 14, weight: .semibold))
            Text("Back online")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.dinkrGreen)
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - OfflineBannerModifier

struct OfflineBannerModifier: ViewModifier {
    @State private var networkMonitor = NetworkMonitor.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                OfflineBannerView(isConnected: networkMonitor.isConnected)
            }
    }
}

// MARK: - View Extension

extension View {
    func offlineBanner() -> some View {
        modifier(OfflineBannerModifier())
    }
}
