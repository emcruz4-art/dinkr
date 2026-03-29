import SwiftUI
import PhotosUI

struct CreateListingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var brand = ""
    @State private var model = ""
    @State private var selectedCategory: MarketCategory = .paddles
    @State private var selectedCondition: ListingCondition = .good
    @State private var price = ""
    @State private var description = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var isPosting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(MarketCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }
                }
                Section("Item Details") {
                    TextField("Brand (e.g. Selkirk)", text: $brand)
                    TextField("Model (e.g. Vanguard Power Air)", text: $model)
                    Picker("Condition", selection: $selectedCondition) {
                        ForEach(ListingCondition.allCases, id: \.self) { cond in
                            Text(cond.rawValue).tag(cond)
                        }
                    }
                }
                Section("Price") {
                    HStack {
                        Text("$")
                        TextField("0", text: $price)
                            .keyboardType(.decimalPad)
                    }
                }
                Section("Description") {
                    TextEditor(text: $description).frame(minHeight: 80)
                }
                Section("Photos") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Add Photos", systemImage: "photo.badge.plus")
                    }
                }
            }
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("List") {
                        isPosting = true
                        Task {
                            try? await Task.sleep(nanoseconds: 600_000_000)
                            isPosting = false
                            dismiss()
                        }
                    }
                    .disabled(brand.isEmpty || model.isEmpty || price.isEmpty || isPosting)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    CreateListingView()
}
