import SwiftUI

// MARK: - Mock Photo Model

private struct CourtPhoto: Identifiable {
    let id: Int
    let gradient: [Color]
    let label: String
}

private let mockPhotos: [CourtPhoto] = [
    CourtPhoto(id: 0, gradient: [Color.dinkrSky, Color.dinkrGreen],         label: "Court 1 – Main Entrance"),
    CourtPhoto(id: 1, gradient: [Color.dinkrGreen, Color.dinkrNavy],        label: "Court 2 – Indoor Hall"),
    CourtPhoto(id: 2, gradient: [Color.dinkrSky, Color.dinkrNavy],          label: "Court 3 – Outdoor Hard Court"),
    CourtPhoto(id: 3, gradient: [Color.dinkrAmber, Color.dinkrCoral],       label: "Court 4 – Evening Lights"),
    CourtPhoto(id: 4, gradient: [Color.dinkrGreen, Color.dinkrAmber],       label: "Pro Shop Area"),
    CourtPhoto(id: 5, gradient: [Color.dinkrCoral, Color.dinkrSky],         label: "Locker Room Hallway"),
]

// MARK: - CourtPhotoGalleryView

struct CourtPhotoGalleryView: View {
    let courtName: String

    @Environment(\.dismiss) private var dismiss

    @State private var selectedIndex: Int = 0
    @State private var scale: CGFloat = 1.0
    @State private var showUploadAlert = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Toolbar row
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.white.opacity(0.25))
                    }
                    .padding(.leading, 20)

                    Spacer()

                    Text(courtName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    // Upload button
                    Button {
                        showUploadAlert = true
                    } label: {
                        Image(systemName: "photo.badge.plus")
                            .font(.title3)
                            .foregroundStyle(Color.dinkrGreen)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 16)
                .padding(.bottom, 12)

                // MARK: Thumbnail strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(mockPhotos) { photo in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedIndex = photo.id
                                    scale = 1.0
                                }
                            } label: {
                                ZStack {
                                    LinearGradient(
                                        colors: photo.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                selectedIndex == photo.id ? Color.dinkrGreen : Color.clear,
                                                lineWidth: 2.5
                                            )
                                    )

                                    Image(systemName: "sportscourt")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 64)
                .padding(.bottom, 10)

                // MARK: Main photo area
                ZStack {
                    // Photo placeholder via gradient
                    LinearGradient(
                        colors: mockPhotos[selectedIndex].gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea(edges: .bottom)

                    // Court icon watermark
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(.white.opacity(0.15))

                    // AsyncImage stub — would load a real URL in production
                    AsyncImage(url: nil) { phase in
                        switch phase {
                        case .empty:
                            EmptyView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            EmptyView()
                        @unknown default:
                            EmptyView()
                        }
                    }

                    // Photo count badge
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(selectedIndex + 1) / \(mockPhotos.count)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .padding(.top, 14)
                                .padding(.trailing, 16)
                        }
                        Spacer()
                    }

                    // Caption overlay + upload button at bottom
                    VStack {
                        Spacer()
                        HStack(alignment: .bottom) {
                            Text(mockPhotos[selectedIndex].label)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                                .padding(.leading, 20)
                                .padding(.bottom, 24)

                            Spacer()

                            Button {
                                showUploadAlert = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.dinkrGreen)
                                        .frame(width: 46, height: 46)
                                        .shadow(color: Color.dinkrGreen.opacity(0.5), radius: 8)
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.55)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = min(max(value, 1.0), 3.5)
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                scale = 1.0
                            }
                        }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 0)
            }
        }
        .alert("Upload Photo", isPresented: $showUploadAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Coming soon! Photo uploads will be available in a future update.")
        }
    }
}

// MARK: - Preview

#Preview {
    CourtPhotoGalleryView(courtName: "Westside Pickleball Complex")
}
