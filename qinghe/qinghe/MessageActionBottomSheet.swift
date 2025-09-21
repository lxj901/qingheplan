import SwiftUI

/// 消息操作底部菜单栏
struct MessageActionBottomSheet: View {
    let message: ChatMessage
    @Environment(\.dismiss) private var dismiss

    // 操作回调
    let onReply: () -> Void
    let onForward: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 拖拽指示器
            dragIndicator

            // 消息预览
            messagePreview

            // 分隔线
            Divider()
                .background(ModernDesignSystem.Colors.borderLight)

            // 操作选项
            actionOptions

            Spacer(minLength: 0)

            // 底部安全区域
            Color.clear
                .frame(height: 20)
        }
        .background(Color.white)
    }
    
    // MARK: - 拖拽指示器
    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 36, height: 4)
            .padding(.top, 8)
            .padding(.bottom, 16)
    }
    
    // MARK: - 消息预览
    private var messagePreview: some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // 发送者头像
            AsyncImage(url: URL(string: message.sender.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(ModernDesignSystem.Colors.backgroundSecondary)
                    .overlay(
                        Text(String(message.sender.nickname.first ?? "?"))
                            .font(ModernDesignSystem.Typography.caption1)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    )
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                // 发送者名称
                Text(message.sender.nickname)
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                
                // 消息内容预览
                Text(messageContentPreview)
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.md)
    }
    
    // MARK: - 操作选项
    private var actionOptions: some View {
        VStack(spacing: 0) {
            // 回复
            ActionOptionRow(
                icon: "arrowshape.turn.up.left",
                title: "回复",
                subtitle: "回复这条消息",
                action: {
                    dismiss()
                    onReply()
                }
            )
            
            // 转发
            ActionOptionRow(
                icon: "arrowshape.turn.up.right",
                title: "转发",
                subtitle: "转发到其他聊天",
                action: {
                    dismiss()
                    onForward()
                }
            )
            
            // 复制（仅文本消息）
            if message.type == .text {
                ActionOptionRow(
                    icon: "doc.on.doc",
                    title: "复制",
                    subtitle: "复制消息内容",
                    action: {
                        UIPasteboard.general.string = message.content
                        dismiss()
                    }
                )
            }
        }
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
    }
    
    // MARK: - 私有方法
    
    /// 消息内容预览
    private var messageContentPreview: String {
        switch message.type {
        case .text:
            return message.content
        case .image:
            return "[图片]"
        case .video:
            return "[视频]"
        case .audio:
            return "[语音]"
        case .file:
            return "[文件]"
        case .system:
            return message.content
        }
    }
    

}



// MARK: - 预览
#Preview {
    let mockUser = ChatUser(
        id: 1,
        nickname: "张三",
        avatar: nil,
        isVerified: false,
        isOnline: true
    )

    let mockMessage = ChatMessage(
        id: "1",
        conversationId: "conv1",
        senderId: 1,
        content: "这是一条测试消息，用于预览消息操作底部菜单的显示效果。",
        type: .text,
        status: .sent,
        createdAt: "2024-01-01T12:00:00Z",
        sender: mockUser
    )

    MessageActionBottomSheet(
        message: mockMessage,
        onReply: { print("回复消息") },
        onForward: { print("转发消息") }
    )
}
