import SwiftUI
import PhotosUI

// MARK: - ViewModel

@Observable
final class CreateListingViewModel {
    var brand: String = ""
    var model: String = ""
    var category: MarketCategory = .paddles
    var condition: ListingCondition = .good
    var price: String = ""
    var description: String = ""
    var location: String = ""
    var selectedImages: [UIImage] = []
    var isLoading: Bool = false
    var uploadProgress: Double = 0
    var errorMessage: String? = nil
    var didPost: Bool = false

    var canPost: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty &&
        !price.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(price) != nil
    }

    var priceDouble: Double? { Double(price) }

    // MARK: - Submit

    func submit(sellerId: String, sellerName: String) async throws {
        isLoading = true
        uploadProgress = 0
        errorMessage = nil
        defer { isLoading = false }

        let listingId = UUID().uuidString
        var photoURLs: [String] = []

        // Upload photos
        let totalImages = Double(max(selectedImages.count, 1))
        for (index, image) in selectedImages.enumerated() {
            let path = StoragePaths.listingPhoto(listingId: listingId, index: index)
            let url = try await ImageService.shared.upload(image, path: path)
            photoURLs.append(url)
            uploadProgress = Double(index + 1) / totalImages
        }

        // Build listing
        let listing = MarketListing(
            id: listingId,
            sellerId: sellerId,
            sellerName: sellerName,
            category: category,
            brand: brand.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
            condition: condition,
            price: priceDouble ?? 0,
            description: description,
            photos: photoURLs,
            status: .active,
            location: location.trimmingCharacters(in: .whitespaces),
            createdAt: Date(),
            isFeatured: false,
            viewCount: 0
        )

        // Write to Firestore
        try await FirestoreService.shared.setDocument(
            listing,
            collection: FirestoreCollections.marketListings,
            documentId: listingId
        )

        uploadProgress = 1.0
        didPost = true
    }
}

// MARK: - View

struct CreateListingView: View {
    @Environment(\.dismiss) private var dismiss

    // In a real app these would come from an authenticated session
    var sellerId: String = User.mockCurrentUser.id
    var sellerName: String = User.mockCurrentUser.displayName

    @State private var vm = CreateListingViewModel()
    @State private var showImagePicker = false
    @State private var pendingPickedImage: UIImage? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                scrollContent
                if vm.isLoading {
                    uploadOverlay
                }
            }
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("List Item") { triggerSubmit() }
                        .fontWeight(.semibold)
                        .disabled(!vm.canPost || vm.isLoading)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $pendingPickedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: pendingPickedImage) { _, newImage in
                if let img = newImage, vm.selectedImages.count < 6 {
                    vm.selectedImages.append(img)
                    pendingPickedImage = nil
                }
            }
            .onChange(of: vm.didPost) { _, posted in
                if posted {
                    HapticManager.success()
                    dismiss()
                }
            }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                photoGridSection
                categorySection
                detailsSection
                priceSuggestionChip
                previewSection
                if let err = vm.errorMessage {
                    errorBanner(err)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(Color.appBackground)
    }

    // MARK: - Photo Grid

    private var photoGridSection: some View {
        ListingSectionCard(label: "Photos", icon: "photo.stack.fill", iconColor: Color.dinkrSky) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
            LazyVGrid(columns: columns, spacing: 8) {
                // Existing images
                ForEach(vm.selectedImages.indices, id: \.self) { idx in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: vm.selectedImages[idx])
                            .resizable()
                            .scaledToFill()
                            .frame(height: 90)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button {
                            let i: Int = idx
                            withAnimation { vm.selectedImages.remove(at: i) }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color.dinkrCoral)
                                .font(.system(size: 18))
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Add Photo cell (if < 6)
                if vm.selectedImages.count < 6 {
                    Button { showImagePicker = true } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.cardBackground)
                                .frame(height: 90)
                            VStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color.dinkrGreen)
                                Text("Add Photo")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("\(vm.selectedImages.count)/6 photos")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 2)
        }
    }

    // MARK: - Category Picker

    private var categorySection: some View {
        ListingSectionCard(label: "Category", icon: "square.grid.2x2.fill", iconColor: Color.dinkrGreen) {
            SelectableCategoryGrid(selection: $vm.category)
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        ListingSectionCard(label: "Item Details", icon: "tag.fill", iconColor: Color.dinkrAmber) {
            VStack(spacing: 14) {
                // Brand
                LabeledTextField(icon: "building.2", placeholder: "Brand (e.g. Selkirk)", text: $vm.brand)

                Divider()

                // Model
                LabeledTextField(icon: "pencil", placeholder: "Model (e.g. Vanguard Power Air)", text: $vm.model)

                Divider()

                // Price
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(Color.dinkrGreen)
                        .font(.system(size: 16))
                    Text("$")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.dinkrGreen)
                    TextField("0.00", text: $vm.price)
                        .keyboardType(.decimalPad)
                        .font(.body)
                }

                Divider()

                // Condition picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Condition")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ConditionPicker(selection: $vm.condition)
                }

                Divider()

                // Description
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "text.alignleft")
                            .foregroundStyle(Color.dinkrSky)
                            .font(.system(size: 14))
                        Text("Description")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    ZStack(alignment: .topLeading) {
                        if vm.description.isEmpty {
                            Text("Describe the item, any wear or damage…")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 1)
                        }
                        TextEditor(text: $vm.description)
                            .font(.body)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                }

                Divider()

                // Location
                LabeledTextField(icon: "mappin.circle.fill", placeholder: "Location (e.g. Austin, TX)", text: $vm.location, iconColor: Color.dinkrCoral)
            }
        }
    }

    // MARK: - Price Suggestion

    @ViewBuilder
    private var priceSuggestionChip: some View {
        let suggestion = priceSuggestion(for: vm.category)
        HStack(spacing: 6) {
            Image(systemName: "lightbulb.fill")
                .font(.caption2)
                .foregroundStyle(Color.dinkrAmber)
            Text("Similar \(vm.category.rawValue): \(suggestion)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.dinkrAmber.opacity(0.10))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Live Preview Card

    @ViewBuilder
    private var previewSection: some View {
        if vm.canPost {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dinkrSky)
                    Text("Preview")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                ListingCardView(listing: previewListing)
                    .frame(maxWidth: 200)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: - Upload Overlay

    private var uploadOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 5)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: vm.uploadProgress)
                        .stroke(Color.dinkrGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 64, height: 64)
                        .animation(.linear(duration: 0.2), value: vm.uploadProgress)
                    Text("\(Int(vm.uploadProgress * 100))%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("Uploading listing…")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: - Error Banner

    @ViewBuilder
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.dinkrCoral)
            Text(message)
                .font(.caption)
                .foregroundStyle(Color.dinkrCoral)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dinkrCoral.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private var previewListing: MarketListing {
        MarketListing(
            id: "preview",
            sellerId: sellerId,
            sellerName: sellerName,
            category: vm.category,
            brand: vm.brand.isEmpty ? "Brand" : vm.brand,
            model: vm.model.isEmpty ? "Model" : vm.model,
            condition: vm.condition,
            price: vm.priceDouble ?? 0,
            description: vm.description,
            photos: [],
            status: .active,
            location: vm.location.isEmpty ? "Location" : vm.location,
            createdAt: Date(),
            isFeatured: false,
            viewCount: 0
        )
    }

    private func priceSuggestion(for category: MarketCategory) -> String {
        switch category {
        case .paddles:     return "~$80–$220"
        case .balls:       return "~$15–$35"
        case .bags:        return "~$40–$120"
        case .apparel:     return "~$15–$60"
        case .shoes:       return "~$40–$120"
        case .accessories: return "~$10–$50"
        case .courts:      return "~$500+"
        case .other:       return "varies"
        }
    }

    private func triggerSubmit() {
        Task {
            do {
                try await vm.submit(sellerId: sellerId, sellerName: sellerName)
            } catch {
                vm.errorMessage = error.localizedDescription
                HapticManager.error()
            }
        }
    }
}

// MARK: - ListingSectionCard

private struct ListingSectionCard<Content: View>: View {
    let label: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            content()
                .padding(14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - SelectableCategoryGrid

private struct SelectableCategoryGrid: View {
    @Binding var selection: MarketCategory

    let items: [(category: MarketCategory, icon: String, label: String, color: Color)] = [
        (.paddles,     "figure.pickleball", "Paddles",     Color.dinkrCoral),
        (.balls,       "circle.fill",       "Balls",       Color.dinkrAmber),
        (.bags,        "bag.fill",          "Bags",        Color.dinkrSky),
        (.apparel,     "tshirt.fill",       "Apparel",     .purple),
        (.shoes,       "shoeprints.fill",   "Shoes",       .teal),
        (.accessories, "sparkles",          "Accessories", .pink),
        (.courts,      "sportscourt",       "Courts",      Color.dinkrGreen),
        (.other,       "ellipsis.circle",   "Other",       .secondary),
    ]

    let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(items, id: \.label) { item in
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selection = item.category
                    }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selection == item.category
                                      ? item.color
                                      : item.color.opacity(0.12))
                                .frame(width: 50, height: 50)
                            Image(systemName: item.icon)
                                .font(.title3)
                                .foregroundStyle(selection == item.category ? .white : item.color)
                        }
                        Text(item.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(selection == item.category ? item.color : .primary)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - ConditionPicker

private struct ConditionPicker: View {
    @Binding var selection: ListingCondition

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ListingCondition.allCases, id: \.self) { cond in
                    let isSelected = selection == cond
                    Button {
                        HapticManager.selection()
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selection = cond
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(conditionColor(cond))
                                .frame(width: 8, height: 8)
                            Text(cond.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            isSelected
                                ? conditionColor(cond).opacity(0.15)
                                : Color.appBackground
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isSelected ? conditionColor(cond) : Color.secondary.opacity(0.25),
                                    lineWidth: isSelected ? 1.5 : 1
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func conditionColor(_ condition: ListingCondition) -> Color {
        switch condition {
        case .brandNew:  return Color.dinkrGreen
        case .likeNew:   return Color.dinkrSky
        case .good:      return Color.dinkrAmber
        case .fair:      return Color.dinkrCoral
        case .forParts:  return .secondary
        }
    }
}

// MARK: - LabeledTextField

private struct LabeledTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var iconColor: Color = Color.dinkrNavy

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.system(size: 16))
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .font(.body)
        }
    }
}

// MARK: - Preview

#Preview {
    CreateListingView()
}
