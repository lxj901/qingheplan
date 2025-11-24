import SwiftUI

/// 创作者中心视图 - 极简设计
struct CreatorCenterView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = CreatorCenterViewModel()
    @State private var showingNotifications = false
    @State private var showingPublish = false
    @State private var showingSettings = false
    @State private var showingSearch = false

    var body: some View {
        ZStack {
            // 背景色
            Color(red: 0.965, green: 0.969, blue: 0.976)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部导航栏
                topNavigationBar

                // 主滚动区域
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 用户信息区 (占满宽度)
                        userInfoSection

                        VStack(spacing: 16) {
                            // 创作工具
                            creatorToolsSection

                            // 活动广场
                            activitySquareSection

                            // 消息通知
                            notificationsSection
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingPublish) {
            NewPublishPostView()
        }
        .sheet(isPresented: $showingSettings) {
            Text("设置页面")
        }
        .sheet(isPresented: $showingSearch) {
            Text("搜索页面")
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text("创作者中心")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                // 占位,保持标题居中
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .background(Color.white.opacity(0.8))
        }
    }

    // MARK: - 用户信息区域
    private var userInfoSection: some View {
        VStack(spacing: 0) {
            // 用户基本信息
            HStack(spacing: 12) {
                // 头像
                if let avatarURL = viewModel.userAvatar, let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                } else {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(viewModel.userName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)

                        Text("LV.5")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }

                    HStack(spacing: 8) {
                        Text("ID: 9527882")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 12)

                        Text("生活 / 科技博主")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: {}) {
                    Text("个人主页")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 32)

            // 核心数据卡片
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    statItem(label: "总播放", value: "128.5w", trend: "+2.3k")
                    statItem(label: "粉丝数", value: "4.2w", trend: "+120")
                    statItem(label: "获赞与收藏", value: "89.6w", trend: "+450")
                }
                .padding(12)

                // 数据助手条
                NavigationLink {
                    DataCenterView()
                        .asSubView()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppConstants.Colors.primaryGreen)

                        HStack(spacing: 4) {
                            Text("昨日数据分析：完播率提升")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("12%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppConstants.Colors.primaryGreen)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                    .padding(12)
                    .background(Color(red: 0.97, green: 0.975, blue: 0.98))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 16)
            }
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 15, x: 0, y: 2)
            .padding(.horizontal, 16)
        }
        .background(Color.white)
    }

    private func statItem(label: String, value: String, trend: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.6))

            HStack(spacing: 2) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10))
                Text(trend)
                    .font(.system(size: 10))
            }
            .foregroundColor(.red)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red.opacity(0.1))
            .cornerRadius(4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 创作工具区
    private var creatorToolsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("创作工具")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary.opacity(0.8))

                Spacer()
            }
            .padding(.horizontal, 4)

            HStack(spacing: 12) {
                toolItem(icon: "square.stack.3d.up.fill", label: "合集", color: .blue)
                toolItem(icon: "book.fill", label: "专栏", color: .orange)
                toolItem(icon: "bubble.left.and.bubble.right.fill", label: "圈子", color: .pink)
            }
        }
    }

    private func toolItem(icon: String, label: String, color: Color) -> some View {
        NavigationLink {
            destinationView(for: label)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
    }

    @ViewBuilder
    private func destinationView(for label: String) -> some View {
        switch label {
        case "合集":
            CollectionManagementView().asSubView()
        case "专栏":
            ColumnManagementView().asSubView()
        case "圈子":
            CreateCircleFlowView().asSubView()
        case "活动":
            ActivityCenterView().asSubView()
        default:
            Text("\(label)功能开发中")
        }
    }

    // MARK: - 活动广场区
    private var activitySquareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("活动广场")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary.opacity(0.8))
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    activityCard(
                        title: "秋日采风计划",
                        subtitle: "发布相关笔记瓜分百万流量",
                        tag: "流量扶持",
                        tagColor: AppConstants.Colors.primaryGreen,
                        imageURL: "https://images.unsplash.com/photo-1504609773096-104ff2c73ba4?auto=format&fit=crop&w=600&q=80"
                    )

                    activityCard(
                        title: "寻找城市角落",
                        subtitle: "赢取索尼相机大奖",
                        tag: "有奖征集",
                        tagColor: .orange,
                        imageURL: "https://images.unsplash.com/photo-1496449903678-68ddcb189a24?auto=format&fit=crop&w=600&q=80"
                    )
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func activityCard(title: String, subtitle: String, tag: String, tagColor: Color, imageURL: String) -> some View {
        NavigationLink {
            ActivityCenterView()
                .asSubView()
        } label: {
            ZStack(alignment: .bottomLeading) {
                // 背景图片
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
                .frame(width: 280, height: 144)
                .clipped()

                // 渐变遮罩
                LinearGradient(
                    colors: [Color.black.opacity(0.7), Color.black.opacity(0.2), Color.clear],
                    startPoint: .bottom,
                    endPoint: .top
                )

                // 内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(tag)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(tagColor)
                        .cornerRadius(4)

                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .padding(16)
            }
            .frame(width: 280, height: 144)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }

    // MARK: - 消息通知区
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("消息通知")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary.opacity(0.8))

                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(spacing: 16) {
                notificationItem(
                    isUnread: true,
                    message: "恭喜！您的文章《Vue3 最佳实践》入选了本周技术专栏。",
                    time: "10分钟前"
                )

                notificationItem(
                    isUnread: false,
                    message: "用户 Alice 关注了你。",
                    time: "2小时前"
                )
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
    }

    private func notificationItem(isUnread: Bool, message: String, time: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(isUnread ? Color.red : Color.clear)
                .frame(width: 8, height: 8)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.primary.opacity(0.7))
                    .lineLimit(2)

                Text(time)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            Spacer()
        }
    }


}

// MARK: - ViewModel
class CreatorCenterViewModel: ObservableObject {
    @Published var userName: String = "守一杂说"
    @Published var userAvatar: String?
    @Published var worksOverview: CreatorWorksOverview?
    @Published var statistics: CreatorStatisticsData?
    @Published var followersCount: Int = 0
    @Published var totalLikes: Int = 0
    @Published var yesterdayViews: Int = 0
    @Published var yesterdayFollowers: Int = 0
    @Published var yesterdayLikes: Int = 0
    @Published var isLoading: Bool = false
    @Published var hasUnreadNotifications: Bool = false

    func loadData() {
        isLoading = true
        userName = AuthManager.shared.currentUser?.nickname ?? userName
        userAvatar = AuthManager.shared.currentUser?.avatar

        // 检查未读通知
        hasUnreadNotifications = NotificationManager.shared.unreadCount > 0

        Task {
            do {
                async let overview = CreatorAPIService.shared.fetchWorksOverview()
                async let stats = CreatorAPIService.shared.fetchStatistics(days: 7)

                let fetchedOverview = try await overview
                let fetchedStats = try await stats

                await MainActor.run {
                    self.worksOverview = fetchedOverview
                    self.statistics = fetchedStats
                    self.totalLikes = fetchedStats.overview.totalLikes
                    self.yesterdayViews = 0
                    self.yesterdayFollowers = 0
                    self.yesterdayLikes = 0
                    self.followersCount = 0
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("❌ CreatorCenterViewModel 加载失败: \(error)")
            }
        }
    }
}

// MARK: - 作品管理视图
struct WorksManagementView: View {
    @StateObject private var viewModel = WorksManagementViewModel()
    @State private var selectedStatus = "all"

    private let statusOptions = [
        ("all", "全部"),
        ("published", "已发布"),
        ("reviewing", "审核中"),
        ("rejected", "未通过"),
        ("private", "仅我可见")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 状态筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(statusOptions, id: \.0) { status in
                        statusButton(status: status.0, title: status.1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))

            // 作品列表
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.works.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.works, id: \.id) { work in
                            WorkItemView(work: work)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("作品管理")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadWorks(status: selectedStatus)
        }
    }

    private func statusButton(status: String, title: String) -> some View {
        Button(action: {
            selectedStatus = status
            viewModel.loadWorks(status: status)
        }) {
            Text(title)
                .font(.system(size: 14, weight: selectedStatus == status ? .semibold : .regular))
                .foregroundColor(selectedStatus == status ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedStatus == status ? AppConstants.Colors.primaryGreen : Color(.systemGray6))
                .cornerRadius(16)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("暂无作品")
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            Text("开始创作你的第一篇作品吧")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 作品项视图
struct WorkItemView: View {
    let work: Work

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // 封面图
                if let firstImage = work.images?.first, let url = URL(string: firstImage) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    if let title = work.title {
                        Text(title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }

                    Text(work.content)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                                .font(.system(size: 12))
                            Text("\(work.viewsCount)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .font(.system(size: 12))
                            Text("\(work.likesCount)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 12))
                            Text("\(work.commentsCount)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 作品管理ViewModel
class WorksManagementViewModel: ObservableObject {
    @Published var works: [Work] = []
    @Published var isLoading: Bool = false

    func loadWorks(status: String) {
        isLoading = true
        Task {
            do {
                let items = try await CreatorAPIService.shared.fetchWorks(status: status)
                await MainActor.run {
                    self.works = items
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("❌ 加载作品列表失败: \(error)")
            }
        }
    }
}

struct Work: Codable, Identifiable {
    let id: String
    let title: String?
    let content: String
    let images: [String]?
    let viewsCount: Int
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let status: String
    let visibility: String
    let moderationStatus: String
    let createdAt: String
    let updatedAt: String
}

// MARK: - 预览
#Preview {
    NavigationStack {
        CreatorCenterView()
    }
}
