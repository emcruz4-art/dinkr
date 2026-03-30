import SwiftUI

struct UserTagPicker: View {
    @Binding var taggedIds: [String]
    @Environment(\.dismiss) private var dismiss

    let candidates: [User] = User.mockPlayers  // In real app: fetch following list
    @State private var searchText = ""

    var filtered: [User] {
        if searchText.isEmpty { return candidates }
        return candidates.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { user in
                    let isTagged = taggedIds.contains(user.id)
                    Button {
                        if isTagged {
                            taggedIds.removeAll { $0 == user.id }
                        } else if taggedIds.count < 10 {
                            taggedIds.append(user.id)
                        }
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(urlString: user.avatarURL, displayName: user.displayName, size: 38)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName).font(.subheadline.weight(.medium))
                                Text("@\(user.username)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isTagged {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.dinkrGreen)
                                    .font(.title3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search friends")
            .navigationTitle("Tag People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.dinkrGreen)
                }
            }
        }
    }
}
