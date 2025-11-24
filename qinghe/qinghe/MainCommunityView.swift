import SwiftUI

// MARK: - 主社区视图
struct MainCommunityView: View {
    @ObservedObject private var communityViewModel = CommunityViewModel.shared
    @StateObject private var adManager = GDTAdManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var sideMenuManager = SideMenuManager.shared  // 侧边菜单管理器（使用共享实例）
    @EnvironmentObject private var tabBarManager: TabBarVisibilityManager
    @State private var searchText = ""

    // 导航路径
    @State private var navigationPath = NavigationPath()

    @State private var reportingPostId: String?
    @State private var showingReportSheet = false
    @State private var lastRefreshTime: Date = Date()
    @State private var showingSearch = false  // 添加搜索页面状态
    @State private var presetSearchKeyword: String? = nil  // 预设搜索关键词
    @State private var showingMessages = false  // 显示消息页面
    @State private var showingPublishPost = false  // 显示发布帖子页面

    // 防抖间隔（秒）
    private let refreshDebounceInterval: TimeInterval = 1.0
    
    var body: some View {
        ZStack {
            NavigationStack(path: $navigationPath) {
                // 主要内容
                VStack(spacing: 0) {
                    // 顶部标签栏（替代原来的导航栏）
                    topTabBar

                    // 社区内容
                    communityContent
                }
                .navigationBarHidden(true)
            // 使用NavigationLink方式的导航目标
            .navigationDestination(for: CommunityNavigationDestination.self) { destination in
                switch destination {
                case .postDetail(let postId, let highlightSection, let highlightUserId):
                    PostDetailView(
                        postId: postId,
                        highlightSection: highlightSection.flatMap { section in
                            switch section {
                            case "likes": return .likes
                            case "bookmarks": return .bookmarks
                            case "comments": return .comments
                            default: return nil
                            }
                        },
                        highlightUserId: highlightUserId
                    )
                        .navigationBarHidden(true)
                        .enableSwipeBack() // 启用系统原生滑动返回手势
                        .asSubView() // 标记为子页面，隐藏Tab栏
                        .id(postId) // 强制在postId改变时重新创建视图
                        .onAppear {
                            print("🔍 主社区页面：导航到帖子详情页面，帖子ID: \(postId), 高亮: \(highlightSection ?? "无"), 用户ID: \(highlightUserId ?? "无")")
                        }
                case .shortVideoFeed(let initialPostId, let videoPosts):
                    ShortVideoFeedView(initialPostId: initialPostId, videoPosts: videoPosts)
                        .environmentObject(adManager)
                        .navigationBarHidden(true)
                        .asSubView() // 标记为子页面，隐藏Tab栏
                        .onAppear {
                            print("🔍 主社区页面：导航到短视频浏览页面，初始帖子ID: \(initialPostId)")
                        }
                case .userProfile(let userId):
                    UserProfileView(userId: userId, isRootView: false)
                        .navigationBarHidden(true)
                        .modifier(SwipeBackGestureModifier()) // 添加滑动返回手势
                        .asSubView() // 标记为子页面，隐藏Tab栏
                        .onAppear {
                            print("🔍 主社区页面：导航到用户详情页面，用户ID: \(userId)")
                        }
                case .tagDetail(let tagName):
                    TagDetailView(tagName: tagName)
                        .navigationBarHidden(true)
                        .modifier(SwipeBackGestureModifier()) // 添加滑动返回手势
                        .asSubView() // 标记为子页面，隐藏Tab栏
                        .onAppear {
                            print("🔍 主社区页面：导航到标签详情页面，标签: \(tagName)")
                        }
                case .bookCategory:
                    ClassicsCategoryDetailView()
                        .asSubView() // 标记为子页面，隐藏Tab栏
                        .onAppear {
                            print("🔍 主社区页面：导航到书籍分类页面")
                        }
                case .aiQuestionBank:
                    AIQuestionBankView()
                        .asSubView()
                        .onAppear {
                            print("🔍 主社区页面：导航到AI题库页面")
                        }
                case .meritStatistics:
                    GongGuoGeView()
                        .asSubView()
                        .onAppear {
                            print("🔍 主社区页面：导航到功过格页面")
                        }
                case .noteCenter:
                    NoteCenterView()
                        .asSubView()
                        .onAppear {
                            print("🔍 主社区页面：导航到笔记中心页面")
                        }
                case .reviewPlan:
                    ReviewPlanView()
                        .asSubView()
                        .onAppear {
                            print("🔍 主社区页面：导航到复习计划页面")
                        }
                case .sleepManagement:
                    SleepDashboardView()
                        .asSubView()
                        .onAppear {
                            print("🔍 主社区页面：导航到睡眠管理页面")
                        }
                }
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            if let postId = reportingPostId {
                ReportPostView(postId: postId) { reason, description in
                    Task {
                        await communityViewModel.reportPost(postId, reason: reason, description: description)
                    }
                }
                .onAppear {
                    print("📋 MainCommunityView: 显示ReportPostView，帖子ID: \(postId)")
                    print("✅ MainCommunityView: ReportPostView已显示")
                }
            } else {
                Text(localizationManager.localizedString(key: "error"))
                    .onAppear {
                        print("❌ MainCommunityView: reportingPostId为空，无法显示举报页面")
                    }
            }
        }
        .onChange(of: showingReportSheet) { newValue in
            if newValue {
                print("📋 MainCommunityView: sheet被触发，showingReportSheet: \(newValue), reportingPostId: \(reportingPostId ?? "nil")")
            }
        }
        .task {
            // 首次加载时强制刷新数据
            print("🎯 MainCommunityView.task: 视图出现，开始加载数据")
            print("🎯 MainCommunityView.task: 当前选中标签: \(communityViewModel.selectedTab.displayName)")

            // 加载频道列表
            await communityViewModel.loadChannels()

            // 使用 refresh: true 确保首次加载能获取到数据
            await communityViewModel.loadPosts(refresh: true)
        }
        .onAppear {
            // 页面出现时的逻辑可以在这里添加
        }
        .fullScreenCover(isPresented: $showingSearch, onDismiss: {
            Task { @MainActor in
                // 搜索页面关闭时重置预设关键词
                presetSearchKeyword = nil
            }
        }) {
            CommunitySearchView(
                viewModel: communityViewModel,
                presetSearchKeyword: presetSearchKeyword
            )
            .id(presetSearchKeyword ?? "") // 强制在 presetSearchKeyword 变化时重建视图
        }
        .fullScreenCover(isPresented: $showingMessages) {
            MessagesView()
        }
        .fullScreenCover(isPresented: $showingPublishPost) {
            NewPublishPostView()
        }
        .fullScreenCover(isPresented: $sideMenuManager.showingMessagesView) {
            MessagesView()
        }
        .fullScreenCover(isPresented: $sideMenuManager.showingSettingsView) {
            SettingsView()
        }
        .onChange(of: sideMenuManager.pendingNavigation) { newValue in
            if let destination = newValue {
                navigationPath.append(destination)
                sideMenuManager.pendingNavigation = nil
            }
        }
        .asRootView()
        }
    }
    
    // MARK: - 顶部标签栏
    private var topTabBar: some View {
        VStack(spacing: 0) {
            HStack {
                // 左侧更多按钮（三个横线）
                Button(action: {
                    sideMenuManager.toggleMenu()
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)

                        // 未读消息红点（如果有未读消息）
                        if NotificationManager.shared.unreadCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 4, y: -4)
                        }
                    }
                }

                Spacer()

                // 中间标签栏
                HStack(spacing: 28) {
                    ForEach([CommunityTab.following, CommunityTab.recommended, CommunityTab.nearby], id: \.self) { tab in
                        Button(action: {
                            // 添加触觉反馈
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()

                            // 点击标签按钮时，刷新数据并切换标签
                            Task {
                                await communityViewModel.switchTab(tab)
                            }
                        }) {
                            VStack(spacing: 4) {
                                // 标签文字和加载指示器
                                HStack(spacing: 6) {
                                    Text(tab.displayName)
                                        .font(.system(size: 18, weight: communityViewModel.selectedTab == tab ? .semibold : .regular))
                                        .foregroundColor(communityViewModel.selectedTab == tab ? .primary : .secondary)
                                        .animation(.easeInOut(duration: 0.2), value: communityViewModel.selectedTab)

                                    // 加载指示器（只在当前选中的标签且正在加载时显示）
                                    if communityViewModel.selectedTab == tab && communityViewModel.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                            .frame(width: 12, height: 12)
                                            .tint(.green)
                                    }
                                }

                                // 下划线指示器
                                Rectangle()
                                    .fill(communityViewModel.selectedTab == tab ? Color.green : Color.clear)
                                    .frame(width: 16, height: 2)
                                    .animation(.easeInOut(duration: 0.2), value: communityViewModel.selectedTab)
                            }
                        }
                    }
                }

                Spacer()

                // 右侧搜索按钮
                Button(action: {
                    showingSearch = true  // 显示搜索页面
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
        }
    }
    
    // MARK: - 社区内容
    private var communityContent: some View {
        TabView(selection: $communityViewModel.selectedTab) {
            // 关注标签
            tabContentView(for: .following)
                .tag(CommunityTab.following)

            // 推荐标签
            tabContentView(for: .recommended)
                .tag(CommunityTab.recommended)

            // 同城标签
            tabContentView(for: .nearby)
                .tag(CommunityTab.nearby)
        }
        .tabViewStyle(.page(indexDisplayMode: .never)) // 使用分页样式，隐藏页面指示器
        .onChange(of: communityViewModel.selectedTab) { newTab in
            // 如果该 tab 没有数据，加载数据
            if communityViewModel.postsByTab[newTab] == nil {
                Task {
                    await communityViewModel.loadPosts(refresh: true, isLoadingMore: false)
                }
            }
        }
    }

    // MARK: - 标签内容视图
    private func tabContentView(for tab: CommunityTab) -> some View {
        VStack(spacing: 0) {
            // 每个 tab 显示独立的帖子列表
            postsListForTab(tab)
        }
        .background(Color(red: 0.97, green: 0.97, blue: 0.97))
        .refreshable {
            // 防抖机制：避免快速连续刷新
            let now = Date()
            if now.timeIntervalSince(lastRefreshTime) < refreshDebounceInterval {
                return
            }
            lastRefreshTime = now

            await communityViewModel.refreshPosts()
        }
    }



    
    // MARK: - 为指定 tab 创建帖子列表
    private func postsListForTab(_ tab: CommunityTab) -> some View {
        let posts = communityViewModel.postsByTab[tab] ?? []

        return WaterfallLayout(
            items: posts,
            columns: 2,
            spacing: 4,
            horizontalPadding: 4,
            onLoadMore: {
                // 当滚动到最后时，加载更多
                // 注意：不需要设置 selectedTab，因为用户已经在当前 tab 了
                Task {
                    await communityViewModel.loadMorePosts()
                }
            },
            onScroll: {
                // 用户滑动瀑布流
            }
        ) { post in
            WaterfallPostCard(
                post: post,
                onTap: {
                    Task { @MainActor in
                        // 判断是否是视频帖子
                        if post.video != nil {
                            // 获取当前标签的所有视频帖子
                            let videoPosts = communityViewModel.getCurrentTabPosts().filter { $0.video != nil }
                            print("🎬 MainCommunityView: 瀑布流点击视频帖子，跳转到短视频浏览页面，视频数量: \(videoPosts.count)")
                            navigationPath.append(CommunityNavigationDestination.shortVideoFeed(initialPostId: post.id, videoPosts: videoPosts))
                        } else {
                            // 普通帖子，跳转到详情页
                            navigationPath.append(CommunityNavigationDestination.postDetail(post.id, highlightSection: nil))
                        }
                    }
                },
                onLike: {
                    Task {
                        await communityViewModel.toggleLike(for: post.id)
                    }
                },
                onUserTap: {
                    Task { @MainActor in
                        navigationPath.append(CommunityNavigationDestination.userProfile(String(post.author.id)))
                    }
                }
            )
        } footer: {
            // 底部提示
            if communityViewModel.isLoading && !communityViewModel.posts.isEmpty {
                // 加载更多指示器
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.green)

                    Text(localizationManager.localizedString(key: "loading_more"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.vertical, 12)
            } else if !communityViewModel.hasMorePosts && !communityViewModel.posts.isEmpty {
                // 没有更多数据提示
                Text("暂时没有更多精彩内容")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            }
        }
        .overlay(
            Group {
                if communityViewModel.isLoading && communityViewModel.posts.isEmpty {
                    // 美化的加载视图
                    VStack(spacing: 20) {
                        // 脉冲动画的加载指示器
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .scaleEffect(communityViewModel.isLoading ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: communityViewModel.isLoading)

                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.green)
                        }

                        VStack(spacing: 8) {
                            Text(localizationManager.localizedString(key: "loading"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)

                            Text("稍等片刻，精彩内容即将呈现")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0.97, green: 0.97, blue: 0.97))
                    .transition(.opacity.combined(with: .scale))
                } else if communityViewModel.posts.isEmpty {
                    VStack(spacing: 20) {
                        // 空状态图标动画
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.green.opacity(0.6))
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: true)

                        VStack(spacing: 12) {
                            Text(localizationManager.localizedString(key: "no_data"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("快来发布第一条动态吧！")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // 添加一个呼吸灯效果的装饰
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .scaleEffect(1.0)
                            .opacity(0.6)
                            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: true)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0.97, green: 0.97, blue: 0.97))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        )
        .alert("错误", isPresented: .constant(communityViewModel.errorMessage != nil)) {
            Button("确定") {
                communityViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = communityViewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTagSearch"))) { notification in
            if let tagName = notification.userInfo?["tagName"] as? String {
                print("🏷️ 收到标签搜索通知: \(tagName)")
                Task { @MainActor in
                    // tagName已经包含#号，直接使用
                    presetSearchKeyword = tagName
                    // 稍微延迟确保状态更新完成
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05秒
                    // 导航到搜索页面
                    showingSearch = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowUserProfileInCommunity"))) { notification in
            if let userId = notification.userInfo?["userId"] as? String {
                print("🔍 MainCommunityView 收到社区用户详情通知，用户ID: \(userId)")
                Task { @MainActor in
                    navigationPath.append(CommunityNavigationDestination.userProfile(userId))
                    print("🔍 MainCommunityView: 已设置用户详情显示，userId: \(userId)")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToPost"))) { notification in
            // 支持两种类型的帖子ID：String 和 Int
            var postIdString: String?

            if let postId = notification.userInfo?["postId"] as? String {
                postIdString = postId
            } else if let postId = notification.userInfo?["postId"] as? Int {
                postIdString = String(postId)
            }

            if let postId = postIdString {
                let highlightSection = notification.userInfo?["highlightSection"] as? String
                let highlightUserId = notification.userInfo?["highlightUserId"] as? String
                print("🔍 MainCommunityView 收到帖子详情导航通知，帖子ID: \(postId), 高亮区域: \(highlightSection ?? "无"), 高亮用户ID: \(highlightUserId ?? "无")")
                Task { @MainActor in
                    navigationPath.append(CommunityNavigationDestination.postDetail(postId, highlightSection: highlightSection, highlightUserId: highlightUserId))
                    print("🔍 MainCommunityView: 已设置帖子详情显示，postId: \(postId), highlightSection: \(highlightSection ?? "无"), highlightUserId: \(highlightUserId ?? "无")")
                }
            }
        }
    }

    // MARK: - 辅助方法
    private func postCardView(for post: Post) -> some View {
        PostCardView(
            post: post,
            showHotBadge: false,
            showEditButton: false,
            onLike: {
                Task {
                    await communityViewModel.toggleLike(for: post.id)
                }
            },
            onBookmark: {
                Task {
                    await communityViewModel.toggleBookmark(for: post.id)
                }
            },
            onShare: {
                Task {
                    await communityViewModel.sharePost(post.id)
                }
            },
            onReport: {
                print("⚠️ MainCommunityView: 触发举报回调，帖子ID: \(post.id)")
                reportingPostId = post.id
                showingReportSheet = true
                print("⚠️ MainCommunityView: 设置状态 - reportingPostId: \(post.id), showingReportSheet: true")
            },
            onNavigateToDetail: { postId in
                Task { @MainActor in
                    // 判断是否是视频帖子
                    if post.video != nil {
                        // 获取当前标签的所有视频帖子
                        let videoPosts = communityViewModel.getCurrentTabPosts().filter { $0.video != nil }
                        print("🎬 MainCommunityView: 点击视频帖子，跳转到短视频浏览页面，视频数量: \(videoPosts.count)")
                        navigationPath.append(CommunityNavigationDestination.shortVideoFeed(initialPostId: postId, videoPosts: videoPosts))
                    } else {
                        // 普通帖子，跳转到详情页
                        navigationPath.append(CommunityNavigationDestination.postDetail(postId, highlightSection: nil))
                    }
                }
            },
            onNavigateToUserProfile: { author in
                Task { @MainActor in
                    navigationPath.append(CommunityNavigationDestination.userProfile(String(author.id)))
                }
            }
        )
    }

    // MARK: - 私有方法

    // MARK: - 频道筛选栏
    private var channelBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                // 频道按钮
                ForEach(communityViewModel.channels) { channel in
                    Button(action: {
                        Task {
                            await communityViewModel.selectChannel(channel)
                        }
                    }) {
                        Text(channel.name)
                            .font(.system(size: 16, weight: communityViewModel.selectedChannel?.id == channel.id ? .semibold : .regular))
                            .foregroundColor(communityViewModel.selectedChannel?.id == channel.id ? .primary : .secondary)
                            .fixedSize() // 确保文字不被压缩
                    }
                    .disabled(communityViewModel.isLoading)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 40) // 固定高度
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .gesture(DragGesture(minimumDistance: 0), including: .all) // 确保滑动手势优先
    }


}

// MARK: - 预览
#Preview {
    MainCommunityView()
        .environmentObject(TabBarVisibilityManager.shared)
}
