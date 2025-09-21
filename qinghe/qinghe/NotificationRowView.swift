import SwiftUI

/// 通知行视图组件
struct NotificationRowView: View {
    let notification: SystemNotification
    let onTap: () -> Void
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActionSheet = false

    var body: some View {
        HStack(spacing: 12) {
            // 通知类型图标
            notificationIcon
            
            // 通知内容
            notificationContent
            
            Spacer()
            
            // 右侧状态和操作
            rightSideContent
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
            handleNotificationTap()
        }
        .onLongPressGesture {
            showingActionSheet = true
        }
        .actionSheet(isPresented: $showingActionSheet) {
            notificationActionSheet
        }
    }
    
    // MARK: - 通知图标
    private var notificationIcon: some View {
        ZStack {
            Circle()
                .fill(notification.type.color.opacity(0.1))
                .frame(width: 44, height: 44)
            
            Image(systemName: notification.type.iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(notification.type.color)
        }
    }
    
    // MARK: - 通知内容
    private var notificationContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 标题
            Text(notification.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .lineLimit(1)

            // 内容
            Text(notification.content)
                .font(.system(size: 14))
                .foregroundColor(Color(.darkGray))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // 时间
            Text(notification.createdAt.timeAgoDisplay)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(.systemGray))
        }
    }
    
    // MARK: - 右侧内容
    private var rightSideContent: some View {
        VStack(spacing: 8) {
            // 未读标记
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 8, height: 8)
            }
            
            Spacer()
            
            // 箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(height: 60)
    }
    
    // MARK: - 操作菜单
    private var notificationActionSheet: ActionSheet {
        var buttons: [ActionSheet.Button] = []
        
        // 标记已读/未读
        if notification.isRead {
            buttons.append(.default(Text("标记为未读")) {
                // 这里可以添加标记为未读的功能
            })
        } else {
            buttons.append(.default(Text("标记为已读")) {
                onMarkAsRead()
            })
        }
        
        // 删除通知
        buttons.append(.destructive(Text("删除")) {
            onDelete()
        })
        
        buttons.append(.cancel())
        
        return ActionSheet(
            title: Text(notification.title),
            message: Text("选择操作"),
            buttons: buttons
        )
    }
    
    // MARK: - 处理通知点击
    private func handleNotificationTap() {
        let navigationManager = NavigationManager.shared
        print("🔔 处理通知点击，类型: \(notification.type.displayName), ID: \(notification.id)")

        // 根据通知类型跳转到相应页面
        switch notification.type {
        case .like, .bookmark:
            print("🔔 \(notification.type.displayName)通知数据: \(String(describing: notification.data))")
            if let postIdString = notification.data?.postId,
               let postId = Int(postIdString) {
                print("🔔 \(notification.type.displayName)通知：跳转到帖子详情，帖子ID: \(postId)")
                navigationManager.navigateToPost(id: postId)
            } else {
                print("⚠️ \(notification.type.displayName)通知：缺少帖子ID数据")
                print("⚠️ 通知数据详情: postId=\(String(describing: notification.data?.postId)), relatedId=\(String(describing: notification.relatedId)), relatedType=\(String(describing: notification.relatedType))")

                // 尝试使用relatedId作为备用方案
                if let relatedId = notification.relatedId, let postId = Int(relatedId) {
                    print("🔔 使用relatedId作为帖子ID: \(postId)")
                    navigationManager.navigateToPost(id: postId)
                }
            }
        case .comment:
            print("🔔 评论通知数据: \(String(describing: notification.data))")
            if let postIdString = notification.data?.postId,
               let commentIdString = notification.data?.commentId,
               let postId = Int(postIdString),
               let commentId = Int(commentIdString) {
                print("🔔 评论通知：跳转到评论详情，帖子ID: \(postId), 评论ID: \(commentId)")
                navigationManager.navigateToComment(postId: postId, commentId: commentId)
            } else if let postIdString = notification.data?.postId,
                      let postId = Int(postIdString) {
                print("🔔 评论通知：跳转到帖子详情，帖子ID: \(postId)")
                navigationManager.navigateToPost(id: postId)
            } else {
                print("⚠️ 评论通知：缺少帖子ID数据")
                print("⚠️ 通知数据详情: postId=\(String(describing: notification.data?.postId)), relatedId=\(String(describing: notification.relatedId)), relatedType=\(String(describing: notification.relatedType))")

                // 尝试使用relatedId作为备用方案
                if let relatedId = notification.relatedId, let postId = Int(relatedId) {
                    print("🔔 使用relatedId作为帖子ID: \(postId)")
                    navigationManager.navigateToPost(id: postId)
                }
            }
        case .follow:
            // 优先使用新的数据结构
            if let followerId = notification.data?.follower?.id {
                print("🔔 关注通知：跳转到用户资料，用户ID: \(followerId)")
                navigationManager.navigateToProfile(userId: followerId)
            } else if let userId = notification.data?.userId {
                print("🔔 关注通知：跳转到用户资料（兼容），用户ID: \(userId)")
                navigationManager.navigateToProfile(userId: userId)
            } else if let relatedId = notification.relatedId, let userId = Int(relatedId) {
                print("🔔 关注通知：跳转到用户资料（relatedId），用户ID: \(userId)")
                navigationManager.navigateToProfile(userId: userId)
            } else {
                print("⚠️ 关注通知：缺少用户ID数据")
            }
        case .system:
            print("🔔 系统通知：处理系统通知")
            handleSystemNotification()
        }
    }

    // MARK: - 处理系统通知
    private func handleSystemNotification() {
        let navigationManager = NavigationManager.shared

        // 根据系统通知的内容决定跳转行为
        print("处理系统通知: \(notification.content)")

        // 解析系统通知的相关数据
        if let relatedType = notification.relatedType, let relatedId = notification.relatedId {
            switch relatedType {
            case "post":
                // 跳转到帖子详情
                if let postId = Int(relatedId) {
                    navigationManager.navigateToPost(id: postId)
                }
            case "user":
                // 跳转到用户资料
                if let userId = Int(relatedId) {
                    navigationManager.navigateToProfile(userId: userId)
                }
            case "announcement":
                // 系统公告，可以跳转到公告详情页面
                print("📢 系统公告通知: \(notification.content)")
                // 这里可以添加跳转到公告页面的逻辑
            default:
                print("⚠️ 未知的系统通知类型: \(relatedType)")
            }
        } else {
            // 如果没有相关数据，可能是纯文本系统通知
            print("📝 纯文本系统通知: \(notification.content)")
        }
    }
}

/// 空状态通知视图
struct EmptyNotificationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("暂无通知")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("当有新的互动时，您会在这里看到通知")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 通知筛选视图
struct NotificationFilterView: View {
    @Binding var selectedType: SystemNotificationType?
    let onFilter: (SystemNotificationType?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("通知类型") {
                    ForEach([nil] + SystemNotificationType.allCases, id: \.self) { type in
                        HStack {
                            if let type = type {
                                Image(systemName: type.iconName)
                                    .foregroundColor(type.color)
                                    .frame(width: 24)
                                Text(type.displayName)
                            } else {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.primary)
                                    .frame(width: 24)
                                Text("全部")
                            }

                            Spacer()

                            if selectedType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedType = type
                            onFilter(type)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("筛选通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 预览
#Preview("通知行") {
    VStack {
        NotificationRowView(
            notification: SystemNotification(
                id: "1",
                type: .like,
                title: "新的点赞",
                content: "用户张三点赞了您的帖子《我的健身日记》",
                data: SystemNotificationData(
                    liker: NotificationUser(id: 123, nickname: "张三", avatar: ""),
                    follower: nil,
                    commenter: nil,
                    postId: "456",
                    postTitle: "我的健身日记",
                    commentId: nil,
                    commentContent: nil,
                    userId: 123,
                    userName: "张三",
                    userAvatar: nil
                ),
                isRead: false,
                readAt: nil,
                priority: "normal",
                relatedId: "456",
                relatedType: "post",
                fromUser: NotificationFromUser(id: 123, nickname: "张三", avatar: "", isVerified: 0),
                createdAt: Date().addingTimeInterval(-300).ISO8601Format(), // 5分钟前
                updatedAt: Date().addingTimeInterval(-300).ISO8601Format()
            ),
            onTap: {},
            onMarkAsRead: {},
            onDelete: {}
        )

        Divider()

        NotificationRowView(
            notification: SystemNotification(
                id: "2",
                type: .comment,
                title: "新的评论",
                content: "用户李四评论了您的帖子：这个健身计划很不错！",
                data: nil,
                isRead: true,
                readAt: "2025-08-27T20:35:00Z",
                priority: "normal",
                relatedId: "456",
                relatedType: "post",
                fromUser: NotificationFromUser(id: 124, nickname: "李四", avatar: "", isVerified: 0),
                createdAt: "2025-08-27T20:30:00Z",
                updatedAt: "2025-08-27T20:30:00Z"
            ),
            onTap: {},
            onMarkAsRead: {},
            onDelete: {}
        )
    }
    .padding()
}

#Preview("空状态") {
    EmptyNotificationView()
}
