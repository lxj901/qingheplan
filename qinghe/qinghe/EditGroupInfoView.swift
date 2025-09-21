import SwiftUI

/// 编辑群聊信息视图
struct EditGroupInfoView: View {
    let conversation: ChatConversation
    let onUpdate: (ChatConversation) -> Void
    
    @StateObject private var viewModel = GroupInfoViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var groupAvatar: String = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isLoading = false
    
    var body: some View {
        Form {
                // 群头像
                Section {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Group {
                                if let selectedImage = selectedImage {
                                    // 显示选中的图片
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    // 显示原有头像或占位符
                                    AsyncImage(url: URL(string: groupAvatar.isEmpty ? (conversation.avatar ?? "") : groupAvatar)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle()
                                            .fill(ModernDesignSystem.Colors.backgroundSecondary)
                                            .overlay(
                                                VStack {
                                                    Image(systemName: "camera")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                                                    Text("点击更换")
                                                        .font(ModernDesignSystem.Typography.caption2)
                                                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                                                }
                                            )
                                    }
                                }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(ModernDesignSystem.Colors.borderLight, lineWidth: 1)
                            )
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, ModernDesignSystem.Spacing.md)
                }
                
                // 群名称
                Section("群名称") {
                    TextField("请输入群名称", text: $groupName)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                // 群描述
                Section("群描述") {
                    TextField("请输入群描述", text: $groupDescription, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // 群设置
                Section("群设置") {
                    HStack {
                        Text("群成员数量")
                        Spacer()
                        Text("\(conversation.membersCount ?? 0)人")
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    }
                    
                    HStack {
                        Text("最大成员数")
                        Spacer()
                        Text("\(conversation.maxMembers ?? 500)人")
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    }
                    
                    HStack {
                        Text("创建时间")
                        Spacer()
                        Text(conversation.lastMessageAt.map(formatDate) ?? "未知")
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    }
                }
            }
        .navigationTitle("编辑群信息")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveGroupInfo()
                }
                .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                selectedImage = image
                // TODO: 在实际应用中，这里应该上传图片到服务器并获取URL
                // 暂时可以将图片转换为base64或保存到本地
                uploadImageAndUpdateAvatar(image)
            }
        }
        .onAppear {
            setupInitialValues()
        }
        .overlay {
            if isLoading {
                ProgressView("保存中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func setupInitialValues() {
        groupName = conversation.title ?? ""
        groupDescription = conversation.description ?? ""
        groupAvatar = conversation.avatar ?? ""
    }

    private func uploadImageAndUpdateAvatar(_ image: UIImage) {
        // TODO: 在实际应用中，这里应该调用API上传图片
        // 暂时模拟上传过程
        Task {
            // 模拟上传延迟
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

            // 在实际应用中，这里应该是服务器返回的图片URL
            // 暂时使用一个占位URL或将图片保存到本地
            let imageData = image.jpegData(compressionQuality: 0.8)
            if let data = imageData {
                // 可以保存到本地或转换为base64
                let base64String = data.base64EncodedString()
                await MainActor.run {
                    groupAvatar = "data:image/jpeg;base64,\(base64String)"
                }
            }
        }
    }
    
    private func saveGroupInfo() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = groupDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else { return }
        
        isLoading = true
        
        Task {
            await viewModel.updateGroupInfo(
                name: trimmedName,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                avatar: groupAvatar.isEmpty ? nil : groupAvatar
            )
            
            if !viewModel.showError {
                // 创建更新后的会话对象
                let updatedConversation = ChatConversation(
                    id: conversation.id,
                    title: trimmedName,
                    type: conversation.type,
                    avatar: groupAvatar.isEmpty ? conversation.avatar : groupAvatar,
                    lastMessage: conversation.lastMessage,
                    lastMessageAt: conversation.lastMessageAt,
                    unreadCount: conversation.unreadCount,
                    isTop: conversation.isTop,
                    isMuted: conversation.isMuted,
                    membersCount: conversation.membersCount,
                    creatorId: conversation.creatorId,
                    creator: conversation.creator,
                    memberRecords: conversation.memberRecords,
                    description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                    maxMembers: conversation.maxMembers,
                    createdAt: conversation.createdAt
                )
                
                onUpdate(updatedConversation)
                dismiss()
            }
            
            isLoading = false
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        displayFormatter.locale = Locale(identifier: "zh_CN")
        
        return displayFormatter.string(from: date)
    }
}

// MARK: - 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
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
    let mockConversation = ChatConversation(
        id: "group1",
        title: "iOS开发交流群",
        type: .group,
        avatar: nil,
        lastMessage: nil,
        lastMessageAt: "2024-01-20T14:30:00Z",
        unreadCount: 0,
        isTop: false,
        isMuted: false,
        membersCount: 128,
        creatorId: 1,
        creator: ChatUser(
            id: 1,
            nickname: "群主",
            avatar: nil,
            isVerified: true,
            isOnline: true,
            lastSeenAt: nil
        ),
        memberRecords: [],
        description: "专业的iOS开发技术交流群，欢迎大家分享经验和问题",
        maxMembers: 500,
        createdAt: "2024-01-01T00:00:00Z"
    )

    EditGroupInfoView(conversation: mockConversation) { updatedConversation in
        print("群信息已更新: \(updatedConversation.title ?? "")")
    }
}
