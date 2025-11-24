import SwiftUI

// MARK: - 通知筛选类型
enum NotificationFilterType: CaseIterable {
    case all
    case like
    case comment
    case bookmark
    case follow
    case system

    var title: String {
        switch self {
        case .all:
            return "全部消息"
        case .like:
            return "点赞"
        case .comment:
            return "评论"
        case .bookmark:
            return "收藏"
        case .follow:
            return "关注"
        case .system:
            return "系统"
        }
    }

    // 主要显示的4个标签
    static let mainTabs: [NotificationFilterType] = [.all, .like, .comment, .follow]
}

/// 通知列表视图
struct NotificationListView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var selectedFilterType: NotificationFilterType = .all

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tabBarManager: TabBarVisibilityManager

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            // 筛选标签栏
            filterTabBar

            // 主要内容
            mainContent
        }
        .navigationBarHidden(true)
        .onAppear {
            // 页面出现时使用防抖机制，避免频繁请求
            notificationManager.refreshNotifications()
        }
        .refreshable {
            // 用户主动下拉刷新时强制刷新
            notificationManager.refreshNotifications(force: true)
        }
        .asSubView()
    }

    // MARK: - 加载通知方法
    private func loadNotifications(for filterType: NotificationFilterType) {
        // 重置分页状态，从第一页开始加载
        notificationManager.currentPage = 1
        notificationManager.hasMoreData = true
        notificationManager.fetchNotifications(page: 1, type: getFilterTypeValue(filterType))
    }

    private func loadMoreIfNeeded() {
        notificationManager.loadMoreNotifications(type: getFilterTypeValue(selectedFilterType))
    }

    private func getFilterTypeValue(_ filterType: NotificationFilterType) -> String? {
        switch filterType {
        case .all:
            return nil
        case .like:
            return "like"
        case .comment:
            return "comment"
        case .bookmark:
            return "bookmark"
        case .follow:
            return "follow"
        case .system:
            return "system"
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        ZStack {
            // 居中的标题
            Text("互动消息")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            // 左侧返回按钮
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - 筛选标签栏
    private var filterTabBar: some View {
        HStack(spacing: 0) {
            // 主要的4个标签
            ForEach(NotificationFilterType.mainTabs, id: \.self) { filterType in
                Button(action: {
                    selectedFilterType = filterType
                    // 根据筛选类型加载通知
                    loadNotifications(for: filterType)
                }) {
                    VStack(spacing: 8) {
                        Text(filterType.title)
                            .font(.system(size: 16, weight: selectedFilterType == filterType ? .medium : .regular))
                            .foregroundColor(selectedFilterType == filterType ? .primary : .secondary)

                        // 下划线 - 调整宽度
                        HStack {
                            Spacer()
                            Rectangle()
                                .fill(selectedFilterType == filterType ? Color.primary : Color.clear)
                                .frame(width: 30, height: 2) // 固定宽度30
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity) // 均分宽度
            }


        }
        .padding(.horizontal, 16)
        .padding(.top, 16) // 增加与导航栏的间距
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
    }


    
    // MARK: - 主要内容
    private var mainContent: some View {
        Group {
            if notificationManager.isLoading && notificationManager.notifications.isEmpty {
                loadingView
            } else if let errorMessage = notificationManager.errorMessage {
                errorView(errorMessage)
            } else if notificationManager.notifications.isEmpty {
                EmptyNotificationView()
            } else {
                notificationsList
            }
        }
    }

    // MARK: - 错误视图
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("加载失败")
                .font(.title2)
                .foregroundColor(.primary)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("重试") {
                // 用户点击重试时强制刷新
                notificationManager.refreshNotifications(force: true)
            }
            .font(.body)
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("加载中...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 通知列表
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(notificationManager.notifications) { notification in
                    NotificationRowView(
                        notification: notification,
                        onTap: {
                            // 如果未读，标记为已读
                            if !notification.isRead {
                                notificationManager.markAsRead(notificationId: notification.id)
                            }
                        },
                        onMarkAsRead: {
                            notificationManager.markAsRead(notificationId: notification.id)
                        },
                        onDelete: {
                            notificationManager.deleteNotification(notificationId: notification.id)
                        }
                    )
                    .onAppear {
                        // 当显示到倒数第3个元素时，开始加载更多
                        if let lastNotification = notificationManager.notifications.last,
                           let currentIndex = notificationManager.notifications.firstIndex(where: { $0.id == notification.id }),
                           currentIndex >= notificationManager.notifications.count - 3,
                           notification.id == lastNotification.id {
                            loadMoreIfNeeded()
                        }
                    }

                    // 分隔线
                    if notification.id != notificationManager.notifications.last?.id {
                        Divider()
                            .padding(.leading, 68) // 对齐内容区域
                    }
                }

                // 加载更多指示器
                if notificationManager.isLoadingMore {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("加载更多...")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if !notificationManager.hasMoreData && !notificationManager.notifications.isEmpty {
                    Text("没有更多通知了")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }
}

// MARK: - 筛选弹窗
struct NotificationFilterSheet: View {
    @Binding var selectedFilterType: NotificationFilterType
    let onFilterSelected: (NotificationFilterType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(NotificationFilterType.allCases, id: \.self) { filterType in
                    Button(action: {
                        selectedFilterType = filterType
                        onFilterSelected(filterType)
                        dismiss()
                    }) {
                        HStack {
                            Text(filterType.title)
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedFilterType == filterType {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
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
        .presentationDetents([.medium])
    }
}

/// 通知入口卡片组件（用于消息页面）
struct NotificationEntryCard: View {
    let unreadCount: Int
    let action: () -> Void
    @EnvironmentObject private var notificationManager: NotificationManager

    // 最新通知时间显示
    private var latestNotificationTimeDisplay: String {
        guard let latestNotification = notificationManager.notifications.first else {
            // 如果没有通知，显示当前时间
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: Date())
        }

        // 使用最新通知的创建时间
        return latestNotification.createdAt.timeAgoDisplay
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 图标 - 粉色圆形背景，白色消息图标
                ZStack {
                    // 粉色圆形背景
                    Circle()
                        .fill(Color(red: 1.0, green: 0.4, blue: 0.7)) // 粉色
                        .frame(width: 50, height: 50)

                    // 白色消息图标
                    Image(systemName: "message.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)

                    // 未读数量角标
                    if unreadCount > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)

                            Text("\(unreadCount > 99 ? "99+" : "\(unreadCount)")")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 18, y: -18)
                    }
                }

                // 内容
                VStack(alignment: .leading, spacing: 4) {
                    Text("互动消息")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)

                    Text(unreadCount > 0 ? "\(unreadCount)条未读消息" : "暂无新消息")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 时间显示（显示最新通知时间）
                VStack(alignment: .trailing, spacing: 4) {
                    Text(latestNotificationTimeDisplay)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.systemGray))

                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 通知入口卡片视图（用于NavigationLink）
struct NotificationEntryCardView: View {
    let unreadCount: Int
    @EnvironmentObject private var notificationManager: NotificationManager

    // 最新通知时间显示
    private var latestNotificationTimeDisplay: String {
        guard let latestNotification = notificationManager.notifications.first else {
            // 如果没有通知，显示当前时间
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: Date())
        }

        // 使用最新通知的创建时间
        return latestNotification.createdAt.timeAgoDisplay
    }

    var body: some View {
        HStack(spacing: 12) {
            // 图标 - 粉色圆形背景，白色消息图标
            ZStack {
                // 粉色圆形背景
                Circle()
                    .fill(Color(red: 1.0, green: 0.4, blue: 0.7)) // 粉色
                    .frame(width: 50, height: 50)

                // 白色消息图标
                Image(systemName: "message.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)

                // 未读数量角标
                if unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)

                        Text("\(unreadCount > 99 ? "99+" : "\(unreadCount)")")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 18, y: -18)
                }
            }

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text("互动消息")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Text(unreadCount > 0 ? "\(unreadCount)条未读消息" : "暂无新消息")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 时间显示（显示最新通知时间）
            Text(latestNotificationTimeDisplay)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(.systemGray))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - 预览
#Preview("通知列表") {
    NotificationListView()
        .environmentObject(TabBarVisibilityManager.shared)
}

#Preview("通知入口卡片") {
    VStack(spacing: 16) {
        NotificationEntryCard(unreadCount: 5) {
            print("点击通知入口")
        }
        
        NotificationEntryCard(unreadCount: 0) {
            print("点击通知入口")
        }
        
        NotificationEntryCard(unreadCount: 123) {
            print("点击通知入口")
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
