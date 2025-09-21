import SwiftUI
import PhotosUI

/// 头像选择器视图
struct AvatarPickerView: View {
    let currentAvatarURL: String
    let onImageSelected: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部当前头像预览
            VStack(spacing: 16) {
                Text("更换头像")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)

                // 当前头像显示
                NetworkAwareAsyncImage(url: URL(string: currentAvatarURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(ModernDesignSystem.Colors.backgroundSecondary)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 35))
                                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        )
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(ModernDesignSystem.Colors.borderMedium, lineWidth: 2)
                )

                Text("当前头像")
                    .font(.caption)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }
            .padding(.top, 24) // 减少顶部间距，为标题留出更多空间
            .padding(.bottom, 32)
                
                // 选择选项
                VStack(spacing: 16) {
                    // 拍照选项
                    Button(action: {
                        sourceType = .camera
                        showingCamera = true
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(ModernDesignSystem.Colors.primaryGreen.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("拍照")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                                
                                Text("使用相机拍摄新头像")
                                    .font(.system(size: 14))
                                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(ModernDesignSystem.Colors.backgroundCard)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ModernDesignSystem.Colors.borderLight, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 相册选择选项
                    Button(action: {
                        sourceType = .photoLibrary
                        showingImagePicker = true
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(ModernDesignSystem.Colors.accentBlue.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(ModernDesignSystem.Colors.accentBlue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("从相册选择")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                                
                                Text("从相册中选择一张照片")
                                    .font(.system(size: 14))
                                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(ModernDesignSystem.Colors.backgroundCard)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ModernDesignSystem.Colors.borderLight, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 取消按钮
                Button("取消") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                .padding(.bottom, 32)
        }
        .background(ModernDesignSystem.Colors.backgroundPrimary)
        .presentationDetents([.height(420)]) // 稍微增加高度，确保内容不被遮挡
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingImagePicker) {
            AvatarImagePicker(sourceType: sourceType) { image in
                onImageSelected(image)
                dismiss()
            }
        }
        .sheet(isPresented: $showingCamera) {
            AvatarImagePicker(sourceType: .camera) { image in
                onImageSelected(image)
                dismiss()
            }
        }
    }
}

/// 头像图片选择器包装器
struct AvatarImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: AvatarImagePicker

        init(_ parent: AvatarImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.onImagePicked(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.onImagePicked(originalImage)
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 预览
#Preview {
    AvatarPickerView(
        currentAvatarURL: "https://example.com/avatar.jpg"
    ) { image in
        print("选择了图片: \(image)")
    }
}
