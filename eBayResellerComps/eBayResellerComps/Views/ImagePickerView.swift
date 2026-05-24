import SwiftUI
import UIKit

// Wraps UIImagePickerController (camera + photo library). Not AVCaptureSession.
struct ImagePickerView: View {
    let onImageSelected: (UIImage) -> Void

    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingPicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Choose an Image Source")
                .font(.headline)

            VStack(spacing: 12) {
                Button(action: openCamera) {
                    Label("Take Photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                Button(action: openLibrary) {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 32)

            Button("Cancel", role: .cancel) { dismiss() }
                .padding(.top, 8)

            Spacer()
        }
        .sheet(isPresented: $showingPicker) {
            UIImagePickerRepresentable(sourceType: sourceType, onImageSelected: { image in
                onImageSelected(image)
                showingPicker = false
            })
            .ignoresSafeArea()
        }
    }

    private func openCamera() {
        sourceType = .camera
        showingPicker = true
    }

    private func openLibrary() {
        sourceType = .photoLibrary
        showingPicker = true
    }
}

private struct UIImagePickerRepresentable: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageSelected: (UIImage) -> Void

        init(onImageSelected: @escaping (UIImage) -> Void) {
            self.onImageSelected = onImageSelected
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImageSelected(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Parent sheet dismisses via showingPicker = false in onImageSelected; cancel just
            // lets the picker go away naturally via the sheet.
        }
    }
}

#Preview {
    ImagePickerView(onImageSelected: { _ in })
}
