import SwiftUI

/// 通知行视图组件
struct NotificationRowView: View {
    let notification: SystemNotification
    let onTap: () -> Void
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActionSheet = false
    @State private var showingSystemNotificationDetail = false

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
        .sheet(isPresented: $showingSystemNotificationDetail) {
            SystemNotificationDetailView(notification: notification)
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
        case .like:
            print("🔔 点赞通知数据: \(String(describing: notification.data))")
            // 获取点赞用户的ID
            let likerUserId = notification.data?.liker?.id ?? notification.fromUser?.id
            // 优先使用 data.postId，如果不存在则使用 relatedId
            if let postId = notification.data?.postId {
                print("🔔 点赞通知：跳转到帖子详情并高亮点赞区域，帖子ID: \(postId), 用户ID: \(String(describing: likerUserId))")
                navigationManager.navigateToPost(id: postId, highlightSection: "likes", highlightUserId: likerUserId.map { String($0) })
            } else if let relatedId = notification.relatedId, notification.relatedType == "post" {
                print("🔔 点赞通知：使用relatedId作为帖子ID: \(relatedId), 用户ID: \(String(describing: likerUserId))")
                navigationManager.navigateToPost(id: relatedId, highlightSection: "likes", highlightUserId: likerUserId.map { String($0) })
            } else {
                print("⚠️ 点赞通知：缺少帖子ID数据")
                print("⚠️ 通知数据详情: postId=\(String(describing: notification.data?.postId)), relatedId=\(String(describing: notification.relatedId)), relatedType=\(String(describing: notification.relatedType))")
            }

        case .bookmark:
            print("🔔 收藏通知数据: \(String(describing: notification.data))")
            // 获取收藏用户的ID（收藏通知中可能没有专门的字段，使用fromUser）
            let bookmarkerUserId = notification.fromUser?.id
            // 优先使用 data.postId，如果不存在则使用 relatedId
            if let postId = notification.data?.postId {
                print("🔔 收藏通知：跳转到帖子详情并高亮收藏区域，帖子ID: \(postId), 用户ID: \(String(describing: bookmarkerUserId))")
                navigationManager.navigateToPost(id: postId, highlightSection: "bookmarks", highlightUserId: bookmarkerUserId.map { String($0) })
            } else if let relatedId = notification.relatedId, notification.relatedType == "post" {
                print("🔔 收藏通知：使用relatedId作为帖子ID: \(relatedId), 用户ID: \(String(describing: bookmarkerUserId))")
                navigationManager.navigateToPost(id: relatedId, highlightSection: "bookmarks", highlightUserId: bookmarkerUserId.map { String($0) })
            } else {
                print("⚠️ 收藏通知：缺少帖子ID数据")
                print("⚠️ 通知数据详情: postId=\(String(describing: notification.data?.postId)), relatedId=\(String(describing: notification.relatedId)), relatedType=\(String(describing: notification.relatedType))")
            }
        case .comment:
            print("🔔 评论通知数据: \(String(describing: notification.data))")
            // 优先使用 data.postId 和 commentId
            if let postId = notification.data?.postId, let commentId = notification.data?.commentId {
                print("🔔 评论通知：跳转到评论详情，帖子ID: \(postId), 评论ID: \(commentId)")
                navigationManager.navigateToComment(postId: postId, commentId: commentId)
            } else if let postId = notification.data?.postId {
                print("🔔 评论通知：跳转到帖子详情，帖子ID: \(postId)")
                navigationManager.navigateToPost(id: postId)
            } else if let relatedId = notification.relatedId, notification.relatedType == "post" {
                print("🔔 评论通知：使用relatedId作为帖子ID: \(relatedId)")
                navigationManager.navigateToPost(id: relatedId)
            } else {
                print("⚠️ 评论通知：缺少帖子ID数据")
                print("⚠️ 通知数据详情: postId=\(String(describing: notification.data?.postId)), relatedId=\(String(describing: notification.relatedId)), relatedType=\(String(describing: notification.relatedType))")
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
            print("🔔 系统通知：以 sheet 方式打开")
            showingSystemNotificationDetail = true
        }
    }
}

/// 系统通知详情视图
struct SystemNotificationDetailView: View {
    let notification: SystemNotification
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    titleSection
                    Divider()
                    contentSection
                    timeSection

                    if notification.fromUser != nil {
                        Divider()
                        fromUserSection
                    }

                    if notification.relatedType != nil || notification.relatedId != nil {
                        Divider()
                        relatedInfoSection
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("通知详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - 子视图

    private var headerSection: some View {
        EmptyView()
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标题")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text(notification.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("内容")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text(notification.content)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
    }
    
    private var timeSection: some View {
        Text(notification.createdAt.formattedDateTime)
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .padding(.top, 4)
    }

    private var fromUserSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("发送者")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            if let fromUser = notification.fromUser {
                HStack(spacing: 12) {
                    userAvatar(fromUser)
                    userInfo(fromUser)
                }
            }
        }
    }

    private func userAvatar(_ fromUser: NotificationFromUser) -> some View {
        Group {
            if !fromUser.avatar.isEmpty {
                AsyncImage(url: URL(string: fromUser.avatar)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 40, height: 40)
            }
        }
    }

    private func userInfo(_ fromUser: NotificationFromUser) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(fromUser.nickname)
                    .font(.system(size: 16, weight: .medium))

                if fromUser.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
            }

            Text("ID: \(fromUser.id)")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }

    private var relatedInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("相关信息")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            if let relatedType = notification.relatedType {
                HStack {
                    Text("类型:")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(relatedType)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
            }

            if let relatedId = notification.relatedId {
                HStack {
                    Text("ID:")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(relatedId)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
            }
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
