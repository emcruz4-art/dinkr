import SwiftUI
import PhotosUI
import UIKit

// MARK: - PHPickerViewController Wrapper

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                DispatchQueue.main.async {
                    self?.parent.selectedImage = object as? UIImage
                }
            }
        }
    }
}

// MARK: - Camera Picker Wrapper

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            parent.selectedImage = image
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Unified Profile Image Picker

struct ProfileImagePicker: View {
    @Binding var selectedImage: UIImage?
    var currentURLString: String? = nil
    var displayName: String = ""
    var onUpload: ((String) -> Void)? = nil

    @State private var showActionSheet = false
    @State private var showLibraryPicker = false
    @State private var showCameraPicker = false
    @State private var uploadProgress: Double = 0
    @State private var isUploading = false
    @State private var uploadPath: String? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarContent
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.dinkrGreen, lineWidth: 2))
                .onTapGesture { showActionSheet = true }

            // Camera badge
            ZStack {
                Circle()
                    .fill(Color.dinkrGreen)
                    .frame(width: 28, height: 28)
                Image(systemName: "camera.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .offset(x: 4, y: 4)
            .onTapGesture { showActionSheet = true }

            if isUploading {
                UploadProgressOverlay(progress: uploadProgress)
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
            }
        }
        .confirmationDialog("Profile Photo", isPresented: $showActionSheet, titleVisibility: .visible) {
            Button("Take Photo") { showCameraPicker = true }
            Button("Choose from Library") { showLibraryPicker = true }
            if selectedImage != nil || currentURLString != nil {
                Button("Remove Photo", role: .destructive) { selectedImage = nil }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showLibraryPicker) {
            ImagePicker(selectedImage: $selectedImage)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraView(selectedImage: $selectedImage)
                .ignoresSafeArea()
        }
        .onChange(of: selectedImage) { _, newImage in
            guard let image = newImage, let path = uploadPath else { return }
            Task { await performUpload(image: image, path: path) }
        }
    }

    func configure(uploadPath: String) -> Self {
        var copy = self
        copy._uploadPath = State(initialValue: uploadPath)
        return copy
    }

    private var avatarContent: some View {
        ZStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = currentURLString, !urlString.isEmpty {
                CachedAsyncImage(urlString: urlString)
            } else {
                initialsCircle
            }
        }
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }

    private var initialsCircle: some View {
        ZStack {
            LinearGradient(
                colors: [Color.dinkrGreen, Color.dinkrSky],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(initials.isEmpty ? "?" : initials)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    @MainActor
    private func performUpload(image: UIImage, path: String) async {
        isUploading = true
        uploadProgress = 0
        defer { isUploading = false; uploadProgress = 0 }

        do {
            // Simulate progress increments while real upload runs
            let uploadTask = Task<String, Error> {
                try await ImageService.shared.upload(image, path: path)
            }

            // Animate progress bar while waiting
            var simulatedProgress = 0.0
            while !uploadTask.isCancelled {
                try? await Task.sleep(nanoseconds: 150_000_000)
                simulatedProgress = min(simulatedProgress + Double.random(in: 0.05...0.15), 0.92)
                uploadProgress = simulatedProgress
                if uploadTask.isCancelled { break }
                // Check if done — break out of loop
                if case .success = await uploadTask.result {
                    uploadProgress = 1.0
                    break
                } else if case .failure = await uploadTask.result {
                    break
                }
            }

            let urlString = try await uploadTask.value
            uploadProgress = 1.0
            onUpload?(urlString)
        } catch {
            // Upload failure — caller can observe selectedImage state
        }
    }
}

// MARK: - Upload Progress Overlay

struct UploadProgressOverlay: View {
    let progress: Double

    private let lineWidth: CGFloat = 4
    private let size: CGFloat = 96

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.45)

            // Track ring
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: lineWidth)
                .padding(lineWidth / 2 + 6)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.dinkrGreen, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(lineWidth / 2 + 6)
                .animation(.linear(duration: 0.15), value: progress)

            // Labels
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text("Uploading...")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Previews

#Preview("ProfileImagePicker") {
    VStack(spacing: 32) {
        ProfileImagePicker(selectedImage: .constant(nil), displayName: "Evan Cruz")
        ProfileImagePicker(selectedImage: .constant(nil), displayName: "Jordan Lee")
    }
    .padding()
}

#Preview("UploadProgressOverlay") {
    ZStack {
        Color.dinkrNavy.ignoresSafeArea()
        UploadProgressOverlay(progress: 0.65)
            .frame(width: 96, height: 96)
            .clipShape(Circle())
    }
}
