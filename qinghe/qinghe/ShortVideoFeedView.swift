import SwiftUI

/// 短视频滑动浏览视图 - 抖音式全屏垂直滑动体验
struct ShortVideoFeedView: View {
    // MARK: - Properties
    
    /// 初始显示的帖子ID
    let initialPostId: String?
    
    /// 视频帖子列表
    let videoPosts: [Post]
    
    @StateObject private var viewModel: ShortVideoFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var topSafeAreaInset: CGFloat = 44
    @State private var hasScrolledToInitialPosition: Bool = false

    // 底部栏状态
    @State private var showingCommentInput = false
    @State private var bannerAdView: UIView?
    @State private var isBannerAdLoaded = false
    @EnvironmentObject private var adManager: GDTAdManager
    
    // MARK: - Initialization
    
    init(initialPostId: String? = nil, videoPosts: [Post]) {
        self.initialPostId = initialPostId
        self.videoPosts = videoPosts
        self._viewModel = StateObject(wrappedValue: ShortVideoFeedViewModel(posts: videoPosts))

        // 如果有初始帖子ID，找到对应的索引
        if let postId = initialPostId,
           let index = videoPosts.firstIndex(where: { $0.id == postId }) {
            self._currentIndex = State(initialValue: index)
            print("🎬 ShortVideoFeedView init: 找到初始视频，postId=\(postId), index=\(index), 总视频数=\(videoPosts.count)")
        } else {
            print("🎬 ShortVideoFeedView init: 未找到初始视频或无initialPostId，使用默认索引0，initialPostId=\(initialPostId ?? "nil"), 总视频数=\(videoPosts.count)")
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 垂直滑动的视频列表
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(videoPosts.enumerated()), id: \.element.id) { index, post in
                            ShortVideoPageView(
                                post: post,
                                isCurrentPage: currentIndex == index,
                                topSafeAreaInset: topSafeAreaInset,
                                showBottomBar: false // 不在每个视频页面显示底部栏
                            )
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .id(index)
                            // 添加滚动位置监听，用于检测当前可见的视频
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .preference(
                                            key: VideoScrollPositionPreferenceKey.self,
                                            value: VideoScrollPosition(
                                                index: index,
                                                minY: geometry.frame(in: .named("videoScrollSpace")).minY,
                                                maxY: geometry.frame(in: .named("videoScrollSpace")).maxY
                                            )
                                        )
                                }
                            )
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .ignoresSafeArea()
                .coordinateSpace(name: "videoScrollSpace")
                .onPreferenceChange(VideoScrollPositionPreferenceKey.self) { position in
                    // 只有在完成初始滚动后才响应滚动位置变化
                    if hasScrolledToInitialPosition {
                        updateCurrentIndex(from: position)
                    }
                }
                .onChange(of: currentIndex) { oldValue, newValue in
                    handlePageChange(from: oldValue, to: newValue)
                }
                .onAppear {
                    // 初始滚动到指定视频
                    DispatchQueue.main.async {
                        proxy.scrollTo(currentIndex, anchor: .top)
                        // 滚动完成后，延迟启用滚动监听
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            hasScrolledToInitialPosition = true
                            print("🎬 ShortVideoFeedView: 初始滚动完成，启用滚动监听，currentIndex=\(currentIndex)")
                        }
                    }
                }
            }

            // 顶部导航栏
            VStack {
                topNavigationBar
                Spacer()
            }
            .ignoresSafeArea(edges: .top)

            // 底部固定栏：广告或评论输入框
            VStack {
                Spacer()
                currentBottomBar
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarHidden(true)
        .statusBarHidden(false)
        .onAppear {
            setupOnAppear()
        }
        .onDisappear {
            // 停止所有视频播放
            ShortVideoPlayerManager.shared.pause()
        }
    }
    
    // MARK: - Top Navigation Bar

    private var topNavigationBar: some View {
        HStack {
            // 返回按钮
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }

            Spacer()

            // 搜索按钮
            Button(action: {
                // TODO: 实现搜索功能
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, topSafeAreaInset + 8)
        .padding(.bottom, 8)
    }

    // MARK: - Bottom Bar

    /// 当前视频的底部栏（广告或评论输入框，二选一）
    private var currentBottomBar: some View {
        Group {
            if isBannerAdLoaded, let adView = bannerAdView {
                // 先显示广告
                BannerAdContainer(adView: adView, onAdClosed: {
                    print("🎯 ShortVideoFeedView: 广告关闭回调触发")
                    withAnimation {
                        isBannerAdLoaded = false
                        bannerAdView = nil
                    }
                })
            } else if currentIndex < videoPosts.count {
                // 广告关闭后显示评论输入框
                let currentPost = videoPosts[currentIndex]
                videoBottomCommentBar(for: currentPost)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BannerAdClosed"))) { _ in
            // 监听广告关闭通知，确保状态同步
            print("🎯 ShortVideoFeedView: 收到广告关闭通知，更新状态")
            withAnimation {
                isBannerAdLoaded = false
                bannerAdView = nil
            }
        }
    }

    /// 视频底部评论输入栏（带背景板）
    private func videoBottomCommentBar(for post: Post) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // 背景层（包含毛玻璃效果，覆盖整个区域包括安全区域）
                VStack(spacing: 0) {
                    Color.black.opacity(0.6)
                }
                .background(.ultraThinMaterial)

                // 内容层
                VStack(spacing: 0) {
                    // 分隔线
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 0.5)

                    HStack(spacing: 16) {
                        // 评论输入框
                        Button(action: {
                            showingCommentInput = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "bubble.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))

                                Text("写评论...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(24)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
            }
        }
        .frame(height: 60 + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0))
        .sheet(isPresented: $showingCommentInput) {
            if let viewModel = getPostViewModel(for: post) {
                CommentInputSheet(
                    postId: post.id,
                    replyingToComment: nil,
                    onSubmit: { content in
                        let success = await viewModel.postComment(content: content)
                        if success {
                            await viewModel.loadPost(postId: post.id)
                        }
                        return success
                    }
                )
            }
        }
    }

    /// 获取指定帖子的 ViewModel
    private func getPostViewModel(for post: Post) -> PostDetailViewModel? {
        // 创建一个新的 ViewModel 实例
        let viewModel = PostDetailViewModel()
        Task {
            await viewModel.loadPost(postId: post.id)
        }
        return viewModel
    }
    
    // MARK: - Helper Methods
    
    private func setupOnAppear() {
        // 获取安全区域
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            topSafeAreaInset = window.safeAreaInsets.top
        }

        // 开始播放当前视频
        if currentIndex < videoPosts.count {
            viewModel.playVideo(at: currentIndex)
        }

        // 预加载相邻视频
        viewModel.preloadAdjacentVideos(currentIndex: currentIndex)

        // 加载 Banner 广告
        loadBannerAd()
    }

    // MARK: - Banner Ad Methods

    /// 加载 Banner 广告
    private func loadBannerAd() {
        // 获取当前的 ViewController
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ ShortVideoFeedView: 无法获取 ViewController")
            return
        }

        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        adManager.loadBannerAd(viewController: topViewController) { success, adView in
            DispatchQueue.main.async {
                if success, let adView = adView {
                    self.bannerAdView = adView
                    self.isBannerAdLoaded = true
                    print("✅ ShortVideoFeedView: Banner 广告加载成功")
                } else {
                    print("❌ ShortVideoFeedView: Banner 广告加载失败")
                }
            }
        }
    }
    
    private func handlePageChange(from oldIndex: Int, to newIndex: Int) {
        print("🎬 ShortVideoFeedView: 页面切换 \(oldIndex) -> \(newIndex)")

        // 如果索引相同，不需要切换
        guard oldIndex != newIndex else {
            print("⏭️ ShortVideoFeedView: 索引相同，跳过切换")
            return
        }

        // 注意：不在这里控制播放/暂停，由 ShortVideoPageView 的 handleCurrentPageChange 处理
        // 这样可以避免与 isCurrentPage 的 onChange 冲突

        // 预加载相邻视频
        viewModel.preloadAdjacentVideos(currentIndex: newIndex)

        // 如果接近列表末尾，加载更多
        if newIndex >= videoPosts.count - 2 {
            Task {
                await viewModel.loadMoreVideos()
            }
        }
    }

    /// 根据滚动位置更新当前视频索引
    private func updateCurrentIndex(from position: VideoScrollPosition) {
        // 计算屏幕中心点
        let screenHeight = UIScreen.main.bounds.height
        let screenCenter = screenHeight / 2

        // 判断当前视频是否在屏幕中心附近（容差范围：屏幕高度的 30%）
        let tolerance = screenHeight * 0.3
        let videoCenter = (position.minY + position.maxY) / 2
        let distanceFromCenter = abs(videoCenter - screenCenter)

        // 如果视频中心在屏幕中心附近，且索引发生变化，则更新 currentIndex
        if distanceFromCenter < tolerance && position.index != currentIndex {
            print("📍 ShortVideoFeedView: 检测到滚动位置变化，更新索引 \(currentIndex) -> \(position.index)")
            currentIndex = position.index
        }
    }
}

// MARK: - Video Scroll Position Tracking

/// 视频滚动位置数据结构
struct VideoScrollPosition: Equatable {
    let index: Int
    let minY: CGFloat
    let maxY: CGFloat
}

/// 视频滚动位置 PreferenceKey
struct VideoScrollPositionPreferenceKey: PreferenceKey {
    static var defaultValue: VideoScrollPosition = VideoScrollPosition(index: 0, minY: 0, maxY: 0)

    static func reduce(value: inout VideoScrollPosition, nextValue: () -> VideoScrollPosition) {
        let next = nextValue()
        let screenHeight = UIScreen.main.bounds.height
        let screenCenter = screenHeight / 2

        // 选择距离屏幕中心最近的视频
        let currentDistance = abs((value.minY + value.maxY) / 2 - screenCenter)
        let nextDistance = abs((next.minY + next.maxY) / 2 - screenCenter)

        if nextDistance < currentDistance {
            value = next
        }
    }
}

// MARK: - Short Video Page View

/// 单个短视频页面视图
struct ShortVideoPageView: View {
    let post: Post
    let isCurrentPage: Bool
    let topSafeAreaInset: CGFloat
    let showBottomBar: Bool

    @StateObject private var viewModel: PostDetailViewModel
    @State private var showPlayPauseIndicator = false
    @State private var showLikeAnimation = false
    @State private var isContentExpanded = false
    @State private var shouldShowExpandButton = false
    @State private var showComments = false // 控制评论弹窗显示
    @State private var showCommentInput = false // 控制评论输入框显示
    @State private var replyingToComment: Comment? // 正在回复的评论

    init(post: Post, isCurrentPage: Bool, topSafeAreaInset: CGFloat, showBottomBar: Bool = true) {
        self.post = post
        self.isCurrentPage = isCurrentPage
        self.topSafeAreaInset = topSafeAreaInset
        self.showBottomBar = showBottomBar
        self._viewModel = StateObject(wrappedValue: PostDetailViewModel())
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 视频播放区域
            if let video = post.video {
                ShortVideoPlayerView(
                    videoURL: video,
                    autoPlay: isCurrentPage,
                    loop: true,
                    muted: false,
                    showControls: false
                )
                .id(video)
                .ignoresSafeArea()
                .onChange(of: isCurrentPage) { oldValue, newValue in
                    handleCurrentPageChange(isCurrentPage: newValue)
                }
            }

            // 手势控制层
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    handleDoubleTap()
                }
                .onTapGesture(count: 1) {
                    handleSingleTap()
                }
                .ignoresSafeArea()
            
            // 底部渐变遮罩
            VStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 350)
            }
            .ignoresSafeArea(edges: .bottom)
            
            // 内容层
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 0) {
                    // 左侧：用户信息和描述
                    leftContentView
                        .padding(.horizontal, 16)
                        .padding(.bottom, calculateBottomPadding(safeAreaBottom: geometry.safeAreaInsets.bottom))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 右侧：互动按钮
                    rightActionButtons
                        .padding(.trailing, 16)
                        .padding(.bottom, calculateBottomPadding(safeAreaBottom: geometry.safeAreaInsets.bottom))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            
            // 播放/暂停指示器
            if showPlayPauseIndicator {
                playPauseIndicator
            }
            
            // 点赞动画
            if showLikeAnimation {
                likeAnimationView
            }
        }
        .onAppear {
            // 加载帖子详情数据（点赞、收藏等状态）
            Task {
                await viewModel.loadPost(postId: post.id)
            }

            // 检测内容是否需要展开按钮
            checkIfContentNeedsExpansion()
        }
        .sheet(isPresented: $showComments) {
            commentsSheet
        }
    }
    
    // MARK: - Left Content View

    private var leftContentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 用户昵称
            Text("@\(post.author.nickname)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

            // 文字描述（带展开/收起功能）
            if !post.content.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if shouldShowExpandButton && !isContentExpanded {
                        // 折叠状态：显示省略的文字 + 展开按钮
                        HStack(alignment: .bottom, spacing: 0) {
                            Text(post.content)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(3)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                            Text(" ...展开")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isContentExpanded = true
                            }
                        }
                    } else {
                        // 展开状态或不需要展开按钮：显示完整文字
                        Text(post.content)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                        // 收起按钮（在文字下方）
                        if shouldShowExpandButton && isContentExpanded {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isContentExpanded = false
                                }
                            }) {
                                Text("收起")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
            }

            // 话题标签
            if let tags = post.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "4A90E2"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(hex: "4A90E2").opacity(0.15))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: "4A90E2").opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .frame(height: 28)
            }

            // 位置信息
            if let location = post.location {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11))
                    Text(location)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundColor(Color(hex: "10B981"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "10B981").opacity(0.15))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(hex: "10B981").opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }

            // 底部信息栏：发布时间 + AI 标识
            HStack(spacing: 8) {
                // 发布时间
                Text(formatRelativeTime(post.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))

                // AI 生成标识
                if post.isAIGenerated == true {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("AI生成")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "A78BFA"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "A78BFA").opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "A78BFA").opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - Right Action Buttons
    
    private var rightActionButtons: some View {
        VStack(spacing: 24) {
            // 用户头像 + 关注按钮
            avatarWithFollowButton
            
            // 点赞按钮
            actionButton(
                icon: viewModel.post?.isLiked ?? false ? "heart.fill" : "heart",
                count: viewModel.post?.likesCount ?? post.likesCount,
                isActive: viewModel.post?.isLiked ?? false,
                activeColor: .red
            ) {
                Task {
                    await viewModel.toggleLike()
                }
            }
            
            // 评论按钮
            actionButton(
                icon: "message",
                count: viewModel.post?.commentsCount ?? post.commentsCount,
                isActive: false
            ) {
                showComments = true
            }
            
            // 收藏按钮
            actionButton(
                icon: viewModel.post?.isBookmarked ?? false ? "star.fill" : "star",
                count: viewModel.post?.bookmarksCount ?? post.bookmarksCount,
                isActive: viewModel.post?.isBookmarked ?? false,
                activeColor: .yellow
            ) {
                Task {
                    await viewModel.toggleBookmark()
                }
            }
        }
    }
    
    private var avatarWithFollowButton: some View {
        ZStack(alignment: .bottom) {
            // 用户头像
            AsyncImage(url: URL(string: post.author.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.white)
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
    }
    
    private func actionButton(
        icon: String,
        count: Int,
        isActive: Bool,
        activeColor: Color = .red,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isActive ? activeColor.opacity(0.2) : Color.black.opacity(0.3))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(
                                    isActive ? activeColor.opacity(0.5) : Color.white.opacity(0.3),
                                    lineWidth: 1.5
                                )
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isActive ? activeColor : .white)
                }
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
                
                if count > 0 {
                    Text(formatCount(count))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.4)))
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 1)
                }
            }
        }
    }
    
    // MARK: - Indicators & Animations
    
    private var playPauseIndicator: some View {
        VStack {
            Spacer()
            Image(systemName: ShortVideoPlayerManager.shared.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 70))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 10)
                .transition(.scale.combined(with: .opacity))
            Spacer()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private var likeAnimationView: some View {
        VStack {
            Spacer()
            Image(systemName: "heart.fill")
                .font(.system(size: 100))
                .foregroundColor(.red)
                .shadow(color: .black.opacity(0.3), radius: 10)
                .scaleEffect(showLikeAnimation ? 1.2 : 0.5)
                .opacity(showLikeAnimation ? 0.8 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showLikeAnimation)
            Spacer()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    // MARK: - Comments Sheet

    /// 评论弹窗视图
    private var commentsSheet: some View {
        CommentSheetContent(
            post: post,
            viewModel: viewModel,
            showCommentInput: $showCommentInput,
            replyingToComment: $replyingToComment
        )
    }

    /// 底部评论输入栏
    private var commentInputBar: some View {
        HStack(spacing: 12) {
            // 输入框（点击后打开完整输入页面）
            Button(action: {
                replyingToComment = nil
                showCommentInput = true
            }) {
                HStack {
                    Text("说点什么...")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Gesture Handlers

    /// 处理当前页面状态变化
    private func handleCurrentPageChange(isCurrentPage: Bool) {
        guard let video = post.video else { return }

        if isCurrentPage {
            // 当滑动到当前页面时，延迟一点时间强制播放视频
            // 确保所有暂停操作都完成后再播放
            print("▶️ ShortVideoPageView: 页面变为当前页，准备播放 - \(video)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("🎬 ShortVideoPageView: 强制播放视频 - \(video)")
                ShortVideoPlayerManager.shared.play(
                    url: video,
                    autoPlay: true,
                    loop: true,
                    muted: false
                )
            }
        } else {
            // 当滑动离开当前页面时，只有当前播放的视频是本视频时才暂停
            // 避免暂停其他正在播放的视频
            if ShortVideoPlayerManager.shared.currentVideoURL == video {
                print("⏸️ ShortVideoPageView: 页面离开，暂停播放 - \(video)")
                ShortVideoPlayerManager.shared.pause()
            } else {
                print("⏭️ ShortVideoPageView: 页面离开，但当前播放的是其他视频，跳过暂停 - \(video)")
            }
        }
    }

    private func handleSingleTap() {
        ShortVideoPlayerManager.shared.togglePlayPause()

        withAnimation(.easeInOut(duration: 0.2)) {
            showPlayPauseIndicator = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showPlayPauseIndicator = false
            }
        }
    }

    private func handleDoubleTap() {
        if !(viewModel.post?.isLiked ?? false) {
            Task {
                await viewModel.toggleLike()
            }
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showLikeAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showLikeAnimation = false
            }
        }
    }
    
    // MARK: - Helper Methods

    private func calculateBottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
        // 为底部固定栏留出空间（评论输入框高度 60 + 额外间距 40）
        return 110 + safeAreaBottom
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000.0)
        } else if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }

    /// 检测内容是否需要展开按钮
    private func checkIfContentNeedsExpansion() {
        let content = post.content
        guard !content.isEmpty else {
            shouldShowExpandButton = false
            return
        }

        // 简单的启发式判断：如果内容超过 100 个字符或包含多个换行符，则显示展开按钮
        let hasMultipleLines = content.components(separatedBy: "\n").count > 3
        let isLongContent = content.count > 100

        shouldShowExpandButton = hasMultipleLines || isLongContent
    }

    /// 格式化相对时间
    private func formatRelativeTime(_ dateString: String) -> String {
        // 首先尝试服务器格式：yyyy-MM-dd HH:mm:ss
        let serverFormatter = DateFormatter()
        serverFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        serverFormatter.locale = Locale(identifier: "en_US_POSIX")
        serverFormatter.timeZone = TimeZone.current

        if let date = serverFormatter.date(from: dateString) {
            return formatTimeInterval(from: date)
        }

        // 尝试 ISO8601 格式（带毫秒）
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = iso8601Formatter.date(from: dateString) {
            return formatTimeInterval(from: date)
        }

        // 尝试 ISO8601 格式（不带毫秒）
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: dateString) {
            return formatTimeInterval(from: date)
        }

        // 如果所有格式都失败，返回"刚刚"
        return "刚刚"
    }

    private func formatTimeInterval(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)小时前"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)天前"
        } else if interval < 2592000 {
            let weeks = Int(interval / 604800)
            return "\(weeks)周前"
        } else if interval < 31536000 {
            let months = Int(interval / 2592000)
            return "\(months)个月前"
        } else {
            let years = Int(interval / 31536000)
            return "\(years)年前"
        }
    }
}

// MARK: - Comment Sheet Content
/// 评论弹窗内容视图（需要访问 CommentManager）
struct CommentSheetContent: View {
    let post: Post
    @ObservedObject var viewModel: PostDetailViewModel
    @Binding var showCommentInput: Bool
    @Binding var replyingToComment: Comment?

    // 创建独立的 CommentManager 用于评论弹窗
    @StateObject private var commentManager: CommentManager

    init(post: Post, viewModel: PostDetailViewModel, showCommentInput: Binding<Bool>, replyingToComment: Binding<Comment?>) {
        self.post = post
        self.viewModel = viewModel
        self._showCommentInput = showCommentInput
        self._replyingToComment = replyingToComment

        // 初始化 CommentManager
        self._commentManager = StateObject(wrappedValue: CommentManager(postId: post.id))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text("评论 \(viewModel.post?.commentsCount ?? post.commentsCount)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            Divider()

            // 中间：可滚动的评论列表
            ScrollView {
                UnifiedCommentListView(
                    postId: post.id,
                    onNavigateToProfile: { userId in
                        // TODO: 导航到用户主页
                        print("导航到用户主页: \(userId)")
                    },
                    onCommentCountChanged: { count in
                        // 更新评论数量
                        viewModel.post?.commentsCount = count
                    },
                    showHeader: false
                )
            }

            Divider()

            // 底部：固定输入框
            commentInputBar
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showCommentInput) {
            CommentInputSheet(
                postId: post.id,
                replyingToComment: replyingToComment,
                onSubmit: { content in
                    // 提交评论到 CommentManager
                    let parentCommentId = replyingToComment?.id
                    let replyToUserId = replyingToComment?.author.id
                    let success = await commentManager.createComment(
                        content: content,
                        parentCommentId: parentCommentId,
                        replyToUserId: replyToUserId
                    )
                    if success {
                        // 清除回复状态
                        await MainActor.run {
                            replyingToComment = nil
                        }
                    }
                    return success
                }
            )
        }
    }

    /// 底部评论输入栏
    private var commentInputBar: some View {
        HStack(spacing: 12) {
            // 输入框（点击后打开完整输入页面）
            Button(action: {
                replyingToComment = nil
                showCommentInput = true
            }) {
                HStack {
                    Text("说点什么...")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

