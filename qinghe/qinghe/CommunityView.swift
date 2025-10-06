import SwiftUI

// 用户详情页面已删除

// MARK: - 社区主页面
struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @StateObject private var adManager = GDTAdManager.shared

    @State private var showingUserProfile = false
    @State private var selectedUserId: String?
    @State private var showingPostDetail = false
    @State private var selectedPostId: String?
    @State private var highlightSection: String?
    @State private var showingReportSheet = false
    @State private var reportingPostId: String?
    @State private var showingSearchView = false
    @State private var searchKeyword: String?
    @State private var searchViewConfiguration: (keyword: String?, show: Bool) = (nil, false)
    @State private var showingPublishPost = false

    // 广告相关状态
    @State private var nativeAdViews: [UIView] = []
    @State private var isAdLoaded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 网络状态指示器
            NetworkStatusIndicator()
                .padding(.horizontal)
                .padding(.top, 4)

            // 顶部Tab栏
            tabBar

            // 分类筛选栏
            categoryBar

            // 帖子列表
            postsList
        }
        .refreshable {
            await viewModel.refreshPosts()
        }
        .overlay(
            // 浮动发布按钮
            floatingPublishButton,
            alignment: .bottomTrailing
        )
        .navigationDestination(isPresented: $showingUserProfile) {
            if let userId = selectedUserId {
                UserProfileView(userId: userId, isRootView: false)
                    .navigationBarHidden(true)
                    .modifier(SwipeBackGestureModifier()) // 添加滑动返回手势
                    .asSubView() // 标记为子页面，隐藏Tab栏
                    .onAppear {
                        print("🔍 社区页面：导航到用户详情页面，用户ID: \(userId)")
                    }
            }
        }
        .navigationDestination(isPresented: $showingPostDetail) {
            if let postId = selectedPostId {
                PostDetailView(
                    postId: postId,
                    highlightSection: highlightSection.flatMap { section in
                        switch section {
                        case "likes": return .likes
                        case "bookmarks": return .bookmarks
                        case "comments": return .comments
                        default: return nil
                        }
                    }
                )
                    .navigationBarHidden(true)
                    .modifier(SwipeBackGestureModifier()) // 添加滑动返回手势
                    .asSubView() // 标记为子页面，隐藏Tab栏
                    .onAppear {
                        print("🔍 社区页面：导航到帖子详情页面，帖子ID: \(postId), 高亮: \(highlightSection ?? "无")")
                    }
                    .onDisappear {
                        // 清除高亮参数
                        highlightSection = nil
                    }
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            if let postId = reportingPostId {
                ReportPostView(postId: postId) { reason, description in
                    Task {
                        await viewModel.reportPost(postId, reason: reason, description: description)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSearchView) {
            CommunitySearchView(
                viewModel: viewModel,
                presetSearchKeyword: searchViewConfiguration.keyword
            )
        }
        .fullScreenCover(isPresented: $showingPublishPost) {
            NewPublishPostView()
        }
        .task {
            await viewModel.loadPosts(refresh: true)
            // 只在推荐标签下加载信息流广告
            print("🎯 CommunityView.task: 当前选中标签: \(viewModel.selectedTab.displayName)")
            if viewModel.selectedTab == .recommended {
                print("🎯 CommunityView.task: 在推荐标签下，开始加载广告")
                loadNativeAds()
            } else {
                print("🎯 CommunityView.task: 不在推荐标签下，跳过广告加载")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTagSearch"))) { notification in
            if let userInfo = notification.userInfo,
               let tagName = userInfo["tagName"] as? String {
                print("🏷️ CommunityView 收到标签搜索通知: \(tagName)")
                print("🏷️ 设置搜索配置...")
                
                // 使用新的配置方式
                searchViewConfiguration = (tagName, true)
                searchKeyword = tagName
                showingSearchView = true
                
                print("🏷️ 搜索配置已设置: keyword=\(tagName), show=true")
            } else {
                print("❌ 解析通知失败，userInfo: \(notification.userInfo ?? [:])")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTagDetail"))) { notification in
            if let userInfo = notification.userInfo,
               let tagName = userInfo["tagName"] as? String {
                print("🏷️ CommunityView 收到标签详情通知: \(tagName)")
                let keywordWithHash = "#\(tagName)"
                
                // 使用新的配置方式
                searchViewConfiguration = (keywordWithHash, true)
                searchKeyword = keywordWithHash
                showingSearchView = true
                
                print("🏷️ 标签详情搜索配置已设置: keyword=\(keywordWithHash), show=true")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToUserProfile"))) { notification in
            if let userId = notification.userInfo?["userId"] as? String {
                print("🔍 CommunityView 收到用户详情导航通知，用户ID: \(userId)")
                selectedUserId = userId
                showingUserProfile = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowUserProfileInCommunity"))) { notification in
            if let userId = notification.userInfo?["userId"] as? String {
                print("🔍 CommunityView 收到社区用户详情通知，用户ID: \(userId)")
                selectedUserId = userId
                showingUserProfile = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToPost"))) { notification in
            if let postId = notification.userInfo?["postId"] as? Int {
                let highlight = notification.userInfo?["highlightSection"] as? String
                print("🔍 CommunityView 收到帖子详情导航通知，帖子ID: \(postId), 高亮区域: \(highlight ?? "无")")
                selectedPostId = String(postId)
                highlightSection = highlight
                showingPostDetail = true
            }
        }
    }
    
    // MARK: - Tab栏
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(CommunityTab.allCases, id: \.self) { tab in
                    Button(action: {
                        Task {
                            await viewModel.switchTab(tab)
                            // 切换到推荐或同城标签时加载广告，切换到其他标签时清理广告
                            if tab == .recommended || tab == .nearby {
                                loadNativeAds()
                            } else {
                                clearNativeAds()
                            }
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(tab.displayName)
                                .font(.system(size: 16, weight: viewModel.selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(viewModel.selectedTab == tab ? .blue : .secondary)
                            
                            if viewModel.selectedTab == tab {
                                Rectangle()
                                    .fill(Color(.systemBlue))
                                    .frame(width: 20, height: 2)
                                    .clipShape(Capsule())
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 20, height: 2)
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - 分类筛选栏
    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PostCategory.allCases, id: \.self) { category in
                    Button(action: {
                        Task {
                            await viewModel.switchCategory(category)
                        }
                    }) {
                        Text(category.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.selectedCategory == category ? .white : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedCategory == category ? Color(.systemBlue) : Color(.systemGray6))
                            )
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - 帖子列表
    private var postsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
                    // 显示帖子
                    PostCardView(
                        post: post,
                        showHotBadge: false,
                        showEditButton: false,
                        onLike: {
                            Task {
                                await viewModel.toggleLike(for: post.id)
                            }
                        },
                        onBookmark: {
                            Task {
                                await viewModel.toggleBookmark(for: post.id)
                            }
                        },
                        onShare: {
                            Task {
                                await viewModel.sharePost(post.id)
                            }
                        },
                        onReport: {
                            reportingPostId = post.id
                            showingReportSheet = true
                        },
                        onNavigateToDetail: { postId in
                            selectedPostId = postId
                            showingPostDetail = true
                        },
                        onNavigateToUserProfile: { author in
                            selectedUserId = String(author.id)
                            showingUserProfile = true
                        }
                    )
                    .onAppear {
                        // 当滚动到倒数第3个帖子时，加载更多
                        if post.id == viewModel.posts.suffix(3).first?.id {
                            Task {
                                await viewModel.loadMorePosts()
                            }
                        }
                    }

                    // 在推荐和同城标签下显示广告
                    if viewModel.selectedTab == .recommended || viewModel.selectedTab == .nearby {
                        // 动态计算广告插入位置，适应分页加载
                        // 每隔6个帖子插入一个广告（在第6、12、18、24...个帖子后）
                        let adInterval = 6
                        let postNumber = index + 1 // 帖子编号从1开始

                        // 检查是否应该在这个位置插入广告
                        if postNumber % adInterval == 0 && !nativeAdViews.isEmpty {
                            let adIndex = (postNumber / adInterval - 1) % nativeAdViews.count
                            AdCardView(adView: nativeAdViews[adIndex])
                                .id("ad_\(postNumber / adInterval)")
                        }
                    }
                }
                
                // 加载更多指示器
                if viewModel.isLoading && !viewModel.posts.isEmpty {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("加载中...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                }
                
                // 没有更多数据提示
                if !viewModel.hasMorePosts && !viewModel.posts.isEmpty {
                    Text("没有更多内容了")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                }
            }
        }
        .overlay(
            Group {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                } else if viewModel.posts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("暂无内容")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("快来发布第一条动态吧！")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                }
            }
        )
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
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
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 100) // 增加底部间距，避免被tab栏遮挡
        .buttonStyle(FloatingButtonStyle())
    }

    // MARK: - 私有方法

    /// 加载信息流广告
    private func loadNativeAds() {
        print("🎯 社区页面：开始调用 loadCommunityNativeAds")
        print("🎯 社区页面：当前选中标签: \(viewModel.selectedTab.displayName)")
        print("🎯 社区页面：广告管理器状态 - isNativeExpressAdLoaded: \(adManager.isNativeExpressAdLoaded)")

        adManager.loadCommunityNativeAds { [self] success, adViews in
            print("🎯 社区页面：广告加载回调 - success: \(success), adViews.count: \(adViews.count)")
            DispatchQueue.main.async {
                if success && !adViews.isEmpty {
                    self.nativeAdViews = adViews
                    self.isAdLoaded = true
                    print("🎯 社区页面：信息流广告加载成功，数量: \(adViews.count)")
                    print("🎯 社区页面：广告视图详情: \(adViews.map { "\($0.frame.size)" })")
                } else {
                    print("❌ 社区页面：信息流广告加载失败 - success: \(success), isEmpty: \(adViews.isEmpty)")
                    if !success {
                        print("❌ 社区页面：广告加载失败，可能原因：网络问题、广告位配置问题或无广告填充")
                    }
                }
            }
        }
    }

    /// 清理信息流广告
    private func clearNativeAds() {
        print("🎯 社区页面：清理信息流广告")
        DispatchQueue.main.async {
            self.nativeAdViews.removeAll()
            self.isAdLoaded = false
        }
        // 销毁广告管理器中的广告
        adManager.destroyNativeExpressAd()
    }
}

// MARK: - 浮动按钮样式
struct FloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 预览
#Preview {
    CommunityView()
}
