import SwiftUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var selectedType: PostType = .general
    @State private var isPosting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Post Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(PostType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("What's on your mind?") {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        isPosting = true
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            isPosting = false
                            dismiss()
                        }
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct NewsRowView: View {
    let title: String
    let source: String
    let date: String

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.pickleballGreen.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "newspaper")
                        .foregroundStyle(Color.pickleballGreen)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Text(source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    CreatePostView()
}
