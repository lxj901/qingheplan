import SwiftUI



// MARK: - 主社区视图
struct MainCommunityView: View {
    @StateObject private var communityViewModel = CommunityViewModel()
    @StateObject private var adManager = GDTAdManager.shared
    @StateObject private var attManager = ATTrackingPermissionManager.shared
    @EnvironmentObject private var tabBarManager: TabBarVisibilityManager
    @State private var searchText = ""

    // 导航路径
    @State private var navigationPath = NavigationPath()

    @State private var reportingPostId: String?
    @State private var showingReportSheet = false
    @State private var lastRefreshTime: Date = Date()
    @State private var showingSearch = false  // 添加搜索页面状态
    @State private var presetSearchKeyword: String? = nil  // 预设搜索关键词
    @State private var showingPublishPost = false  // 发布帖子页面状态
    @State private var showingMessages = false  // 显示消息页面

    // 广告相关状态
    @State private var nativeAdViews: [UIView] = []
    @State private var isAdLoaded = false
    @State private var closedAdIndices: Set<Int> = [] // 跟踪被关闭的广告索引

    // 防抖间隔（秒）
    private let refreshDebounceInterval: TimeInterval = 1.0
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 主要内容
                VStack(spacing: 0) {
                    // 顶部标签栏（替代原来的导航栏）
                    topTabBar

                    // 社区内容
                    communityContent
                }
                .navigationBarHidden(true)
                .overlay(
                    // 浮动发布按钮
                    floatingPublishButton,
                    alignment: .bottomTrailing
                )
            }
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
                        .modifier(SwipeBackGestureModifier()) // 添加滑动返回手势
                        .asSubView() // 标记为子页面，隐藏Tab栏
                        .id(postId) // 强制在postId改变时重新创建视图
                        .onAppear {
                            print("🔍 主社区页面：导航到帖子详情页面，帖子ID: \(postId), 高亮: \(highlightSection ?? "无"), 用户ID: \(highlightUserId ?? "无")")
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
                Text("错误：无法显示举报页面")
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
            await communityViewModel.loadPosts(refresh: true)
            // 只在推荐标签下加载信息流广告
            print("🎯 MainCommunityView.task: 当前选中标签: \(communityViewModel.selectedTab.displayName)")
            if communityViewModel.selectedTab == .recommended {
                print("🎯 MainCommunityView.task: 在推荐标签下，开始加载广告")
                loadNativeAds()
            } else {
                print("🎯 MainCommunityView.task: 不在推荐标签下，跳过广告加载")
            }
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
        .fullScreenCover(isPresented: $showingPublishPost) {
            NewPublishPostView()
        }
        .fullScreenCover(isPresented: $showingMessages) {
            MessagesView()
        }
        .asRootView()
    }
    
    // MARK: - 顶部标签栏
    private var topTabBar: some View {
        VStack(spacing: 0) {
            HStack {
                // 左侧消息按钮
                Button(action: {
                    showingMessages = true
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bubble.left")
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
                            Task {
                                // 添加触觉反馈
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()

                                await communityViewModel.switchTab(tab)
                                // 切换到推荐或同城标签时加载广告，切换到其他标签时清理广告
                                if tab == .recommended || tab == .nearby {
                                    loadNativeAds()
                                } else {
                                    clearNativeAds()
                                }
                                // 重置关闭的广告索引
                                closedAdIndices.removeAll()
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
        VStack(spacing: 0) {
            // 帖子列表
            postsList
                .id("posts-\(communityViewModel.selectedTab.rawValue)") // 强制重新创建视图以触发动画
        }
        .refreshable {
            // 防抖机制：避免快速连续刷新
            let now = Date()
            if now.timeIntervalSince(lastRefreshTime) < refreshDebounceInterval {
                return
            }
            lastRefreshTime = now

            await communityViewModel.refreshPosts()
        }
        .animation(.easeInOut(duration: 0.3), value: communityViewModel.selectedTab) // 为标签切换添加动画
    }
    

    

    
    // MARK: - 帖子列表
    private var postsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(communityViewModel.posts.enumerated()), id: \.element.id) { index, post in
                    postCardView(for: post)
                    .onAppear {
                        // 当滚动到倒数第3个帖子时，加载更多
                        if post.id == communityViewModel.posts.suffix(3).first?.id {
                            Task {
                                await communityViewModel.loadMorePosts()
                            }
                        }
                    }

                    // 在推荐和同城标签下显示广告
                    if communityViewModel.selectedTab == .recommended || communityViewModel.selectedTab == .nearby {
                        // 动态计算广告插入位置，适应分页加载
                        // 每隔12个帖子插入一个广告（在第12、24、36、48...个帖子后）
                        let adInterval = 12
                        let postNumber = index + 1 // 帖子编号从1开始

                        // 检查是否应该在这个位置插入广告
                        if postNumber % adInterval == 0 && !nativeAdViews.isEmpty {
                            let adIndex = (postNumber / adInterval - 1) % nativeAdViews.count
                            let adPosition = postNumber / adInterval // 广告位置标识
                            
                            // 只显示未被关闭的广告
                            if !closedAdIndices.contains(adPosition) {
                                AdCardView(adView: nativeAdViews[adIndex], onAdClosed: {
                                    // 广告被关闭时，记录该广告位置
                                    closedAdIndices.insert(adPosition)
                                })
                                .id("ad_\(adPosition)")
                            }
                        }
                    }
                }
                
                // 加载更多指示器
                if communityViewModel.isLoading && !communityViewModel.posts.isEmpty {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.green)
                        
                        Text("加载更多内容...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // 没有更多数据提示
                if !communityViewModel.hasMorePosts && !communityViewModel.posts.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green.opacity(0.6))
                        
                        Text("已显示全部内容")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 24)
                    .transition(.opacity.combined(with: .scale))
                }
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
                            Text("正在加载内容...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("稍等片刻，精彩内容即将呈现")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
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
                            Text("暂无内容")
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
                    .background(Color(.systemBackground))
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
                    navigationPath.append(CommunityNavigationDestination.postDetail(postId, highlightSection: nil))
                }
            },
            onNavigateToUserProfile: { author in
                Task { @MainActor in
                    navigationPath.append(CommunityNavigationDestination.userProfile(String(author.id)))
                }
            }
        )
    }

    // MARK: - 浮动发布按钮
    private var floatingPublishButton: some View {
        Button(action: {
            showingPublishPost = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 100) // 增加底部间距，避免被tab栏遮挡
        .buttonStyle(FloatingButtonStyle())
    }

    // MARK: - 私有方法

    /// 加载信息流广告
    private func loadNativeAds() {
        print("🎯 主社区页面：开始调用 loadCommunityNativeAds")
        print("🎯 主社区页面：当前选中标签: \(communityViewModel.selectedTab.displayName)")
        print("🎯 主社区页面：广告管理器状态 - isNativeExpressAdLoaded: \(adManager.isNativeExpressAdLoaded)")

        adManager.loadCommunityNativeAds { [self] success, adViews in
            print("🎯 主社区页面：广告加载回调 - success: \(success), adViews.count: \(adViews.count)")
            DispatchQueue.main.async {
                if success && !adViews.isEmpty {
                    self.nativeAdViews = adViews
                    self.isAdLoaded = true
                    print("🎯 主社区页面：信息流广告加载成功，数量: \(adViews.count)")
                    print("🎯 主社区页面：广告视图详情: \(adViews.map { "\($0.frame.size)" })")
                } else {
                    print("❌ 主社区页面：信息流广告加载失败 - success: \(success), isEmpty: \(adViews.isEmpty)")
                    if !success {
                        print("❌ 主社区页面：广告加载失败，可能原因：网络问题、广告位配置问题或无广告填充")
                    }
                }
            }
        }
    }

    /// 清理信息流广告
    private func clearNativeAds() {
        print("🎯 主社区页面：清理信息流广告")
        DispatchQueue.main.async {
            self.nativeAdViews.removeAll()
            self.isAdLoaded = false
            self.closedAdIndices.removeAll() // 重置关闭的广告索引
        }
        // 销毁广告管理器中的广告
        adManager.destroyNativeExpressAd()
    }
}

// MARK: - 预览
#Preview {
    MainCommunityView()
        .environmentObject(TabBarVisibilityManager.shared)
}
