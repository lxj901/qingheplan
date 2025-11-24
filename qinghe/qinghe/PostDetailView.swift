import SwiftUI

// MARK: - NavigationLazyView for performance optimization
struct NavigationLazyView<Content: View>: View {
    let build: () -> Content

    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}
import UIKit

// MARK: - 高亮区域类型
enum HighlightSection {
    case likes
    case bookmarks
    case comments
}

/// 重新设计的帖子详情页面 - 全屏沉浸式体验
struct PostDetailView: View {
    let postId: String
    let highlightSection: HighlightSection?
    let highlightUserId: String?
    let isSheetPresentation: Bool  // 是否以 sheet 方式显示
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PostDetailViewModel
    @StateObject private var adManager = GDTAdManager.shared
    // @StateObject private var userProfileManager = UserProfileNavigationManager() // 暂时注释掉
    @State private var showingCommentInput = false
    @State private var showingImageViewer = false
    @State private var selectedImageIndex = 0

    @State private var showingMoreOptions = false
    @State private var showingReportView = false
    @State private var showingBlockUserView = false
    @State private var showingBlockPostAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var scrollOffset: CGFloat = 0
    @State private var keyboardHeight: CGFloat = 0
    @State private var topSafeAreaInset: CGFloat = 44
    @State private var navigationBarHeight: CGFloat = 0  // 导航栏实际高度

    // 移除本地导航路径，使用父级导航系统

    // 详情页广告相关状态
    @State private var detailPageAdViews: [UIView] = []
    @State private var isDetailPageAdLoaded = false

    // Banner 广告相关状态
    @State private var bannerAdView: UIView?
    @State private var isBannerAdLoaded = false

    // 高亮动画状态
    @State private var isHighlighted = false

    // 视频手势控制状态
    @State private var showPlayPauseIndicator = false
    @State private var showLikeAnimation = false
    @State private var likeAnimationOffset: CGPoint = .zero

    // 应用生命周期状态
    @State private var wasPlayingBeforeBackground = false

    private let communityService = CommunityAPIService.shared

    init(postId: String, highlightSection: HighlightSection? = nil, highlightUserId: String? = nil, isSheetPresentation: Bool = false) {
        self.postId = postId
        self.highlightSection = highlightSection
        self.highlightUserId = highlightUserId
        self.isSheetPresentation = isSheetPresentation
        self._viewModel = StateObject(wrappedValue: PostDetailViewModel())
        print("🚀 PostDetailView 初始化，postId: \(postId), highlightSection: \(String(describing: highlightSection)), highlightUserId: \(highlightUserId ?? "无"), isSheetPresentation: \(isSheetPresentation)")
    }

    var body: some View {
        content
            .navigationBarHidden(true)  // 隐藏系统导航栏，使用自定义导航栏
            .statusBarHidden(false)
        .fullScreenCover(isPresented: $showingImageViewer) {
            imageViewerSheet
        }

        .sheet(isPresented: $showingCommentInput, onDismiss: {
            viewModel.replyingToComment = nil
        }) {
            commentInputSheet
        }
        .sheet(isPresented: $showingReportView) {
            reportSheet
        }
        .sheet(isPresented: $showingBlockUserView) {
            blockUserSheet
        }
        .sheet(isPresented: $viewModel.showingLikesUsers) {
            likesUsersSheet
        }
        .sheet(isPresented: $viewModel.showingBookmarksUsers) {
            bookmarksUsersSheet
        }
        .confirmationDialog("更多选项", isPresented: $showingMoreOptions, titleVisibility: .visible) {
            moreOptionsButtons
        }
        .alert("确认删除", isPresented: $showingDeleteConfirmation) {
            deleteAlert
        } message: {
            Text("确定要删除这条帖子吗？删除后无法恢复。")
        }
        .alert("屏蔽帖子", isPresented: $showingBlockPostAlert) {
            blockAlert
        } message: {
            Text("屏蔽此帖子将同时屏蔽作者，您将不会再看到该用户的任何内容。")
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .alert("成功", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("确定") {
                viewModel.successMessage = nil
            }
        } message: {
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
            }
        }
        .onAppear {
            setupOnAppear()
            // 加载详情页广告
            loadDetailPageNativeAds()
        }
        .onDisappear {
            print("🔄 PostDetailView: 页面消失，清理资源")
            // 清理详情页广告
            clearDetailPageAds()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            handleKeyboardShow(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // 应用即将进入后台
            print("🔄 PostDetailView: 应用即将进入后台")
            wasPlayingBeforeBackground = ShortVideoPlayerManager.shared.isPlaying
            if wasPlayingBeforeBackground {
                ShortVideoPlayerManager.shared.pause()
                print("⏸️ PostDetailView: 暂停视频播放")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 应用返回前台
            print("🔄 PostDetailView: 应用返回前台")
            if wasPlayingBeforeBackground {
                ShortVideoPlayerManager.shared.resume()
                print("▶️ PostDetailView: 恢复视频播放")
                wasPlayingBeforeBackground = false
            }
        }
        // 不在这里使用 .asSubView()，由调用方添加修饰符
        // 避免双重应用导致计数器问题
    }
    
    // MARK: - 主要内容视图
    private var content: some View {
        ZStack {
            // 背景
            Color(.systemBackground)
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.post == nil {
                loadingView
            } else if let post = viewModel.post {
                mainContentView(post)
            } else {
                // 调试：显示详细状态
                let _ = print("⚠️ PostDetailView 显示错误视图 - isLoading: \(viewModel.isLoading), post: \(viewModel.post == nil ? "nil" : "存在"), errorMessage: \(viewModel.errorMessage ?? "无")")
                errorView
            }

            // 顶部导航栏
            VStack {
                customNavigationBar
                Spacer()
            }
            .ignoresSafeArea(edges: .top)

            // 底部交互区域（只在非视频内容时显示）
            if let post = viewModel.post, !hasVideo(post) {
                VStack {
                    Spacer()
                    modernBottomBar
                }
            }
        }
    }
    
    // MARK: - Sheet 视图
    private var imageViewerSheet: some View {
        Group {
            if let post = viewModel.post {
                ImageViewerSheet(
                    images: post.images,
                    selectedIndex: $selectedImageIndex
                )
            }
        }
    }
    

    
    private var commentInputSheet: some View {
        CommentInputSheet(
            postId: postId,
            replyingToComment: viewModel.replyingToComment,
            onSubmit: { content in
                let success = await viewModel.postComment(content: content)
                if success {
                    await MainActor.run {
                        viewModel.replyingToComment = nil
                    }
                }
                return success
            }
        )
        .id("\(postId)-\(viewModel.replyingToComment?.id ?? "new")")
    }
    
    private var reportSheet: some View {
        ReportPostView(postId: postId, onReport: { reason, description in
            // Handle report
        })
    }
    
    private var blockUserSheet: some View {
        Group {
            if let post = viewModel.post {
                BlockUserView(
                    userId: String(post.author.id),
                    username: post.author.nickname,
                    nickname: post.author.nickname,
                    avatar: post.author.avatar
                )
            }
        }
    }
    
    private var likesUsersSheet: some View {
        PostInteractionUsersView(postId: postId, type: .likes, highlightUserId: highlightUserId)
    }
    
    private var bookmarksUsersSheet: some View {
        PostInteractionUsersView(postId: postId, type: .bookmarks, highlightUserId: highlightUserId)
    }
    
    // MARK: - Alert 按钮
    private var deleteAlert: some View {
        Group {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                Task {
                    let success = await viewModel.deletePost()
                    if success {
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private var blockAlert: some View {
        Group {
            Button("取消", role: .cancel) { }
            Button("确认屏蔽", role: .destructive) {
                Task {
                    await blockPost()
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    private func setupOnAppear() {
        print("🔍 PostDetailView setupOnAppear - postId: \(postId)")

        // 初始化安全区域
        if isSheetPresentation {
            // Sheet 方式显示时使用较小的顶部间距
            topSafeAreaInset = 8
            print("📐 PostDetailView 以 Sheet 方式显示，使用固定顶部间距: \(topSafeAreaInset)")
        } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first {
            // 全屏方式显示时使用系统安全区域
            topSafeAreaInset = window.safeAreaInsets.top
            print("📐 PostDetailView 全屏显示，使用系统安全区域顶部: \(topSafeAreaInset)")
        }

        // 只在需要时加载帖子数据，避免重复加载
        print("🔍 PostDetailView 检查是否需要加载 - viewModel.post?.id: \(viewModel.post?.id ?? "nil"), postId: \(postId)")
        if viewModel.post?.id != postId {
            print("✅ PostDetailView 开始加载帖子数据")
            Task.detached(priority: .userInitiated) { @MainActor in
                await viewModel.loadPost(postId: postId)
            }
        } else {
            print("⏭️ PostDetailView 跳过加载（已存在相同帖子）")
        }
    }
    
    private func handleKeyboardShow(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            keyboardHeight = keyboardFrame.cgRectValue.height
        }
    }
    
    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        Group {
            if let post = viewModel.post {
                if hasVideo(post) {
                    // 视频内容：显示简洁导航栏
                    videoNavigationBar
                } else {
                    // 其他内容：显示用户信息导航栏
                    userInfoNavigationBar(post)
                }
            } else {
                // 加载中或错误状态：显示默认导航栏
                defaultNavigationBar
            }
        }
    }

    // MARK: - 默认导航栏
    private var defaultNavigationBar: some View {
        HStack {
            // 返回按钮
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppConstants.Colors.primaryText)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemBackground).opacity(0.9))
                    .clipShape(Circle())
            }

            Spacer()

            Text("帖子详情")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppConstants.Colors.primaryText)

            Spacer()

            // 更多选项按钮
            Button(action: { showingMoreOptions = true }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppConstants.Colors.primaryText)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemBackground).opacity(0.9))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, topSafeAreaInset + 4)
        .padding(.bottom, 12)
        .background(
            ZStack {
                // 主背景
                Color(.systemBackground)
                    .ignoresSafeArea(edges: .top)

                // 底部阴影分隔线
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5)
                }
            }
        )
    }

    // MARK: - 视频导航栏（简洁版）
    private var videoNavigationBar: some View {
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

    // MARK: - 用户信息导航栏
    private func userInfoNavigationBar(_ post: Post) -> some View {
        HStack(spacing: 12) {
            // 返回按钮
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppConstants.Colors.primaryText)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemBackground).opacity(0.9))
                    .clipShape(Circle())
            }

            // 用户头像
            Button(action: {
                print("🔍 导航栏：点击用户头像，用户ID: \(post.author.id)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowUserProfileInCommunity"),
                    object: nil,
                    userInfo: ["userId": String(post.author.id)]
                )
            }) {
                AsyncImage(url: URL(string: post.author.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(AppConstants.Colors.primaryGreen.opacity(0.2))
                        .overlay(
                            Text(String(post.author.nickname.prefix(1)))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppConstants.Colors.primaryGreen)
                        )
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            }

            // 用户昵称
            Button(action: {
                print("🔍 导航栏：点击用户昵称，用户ID: \(post.author.id)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowUserProfileInCommunity"),
                    object: nil,
                    userInfo: ["userId": String(post.author.id)]
                )
            }) {
                HStack(spacing: 4) {
                    Text(post.author.nickname)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppConstants.Colors.primaryText)

                    if post.author.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            // 关注按钮（只在非当前用户的帖子时显示）
            if !isCurrentUserPost(post) {
                Button(action: {
                    Task {
                        await viewModel.toggleFollowUser()
                    }
                }) {
                    HStack(spacing: 4) {
                        if viewModel.isFollowActionLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .foregroundColor(.white)
                        } else {
                            Text(viewModel.isFollowingAuthor ? "已关注" : "关注")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 28)  // 固定关注按钮高度
                    .padding(.horizontal, 16)
                    .background(viewModel.isFollowingAuthor ? Color(.systemGray) : AppConstants.Colors.primaryGreen)
                    .cornerRadius(14)
                }
                .disabled(viewModel.isFollowActionLoading)
            }

            // 更多选项按钮
            Button(action: { showingMoreOptions = true }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppConstants.Colors.primaryText)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemBackground).opacity(0.9))
                    .clipShape(Circle())
            }
        }
        .frame(height: 36)  // 固定 HStack 内容高度为 36
        .padding(.horizontal, 16)
        .padding(.top, topSafeAreaInset + 4)
        .padding(.bottom, 12)
        .background(
            ZStack {
                // 主背景
                Color(.systemBackground)
                    .ignoresSafeArea(edges: .top)

                // 底部阴影分隔线
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5)
                }
            }
        )
    }

    // MARK: - 判断是否有图片和文字内容
    private func hasImagesAndText(_ post: Post) -> Bool {
        return (post.images != nil && !post.images!.isEmpty) && !post.content.isEmpty
    }

    // MARK: - 判断是否是视频内容
    private func hasVideo(_ post: Post) -> Bool {
        return post.video != nil
    }

    // MARK: - 图片+文字内容布局（小红书风格）
    private func imageTextContentLayout(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 计算导航栏的精确高度
            // 导航栏组成：topSafeAreaInset + top padding(4) + 内容高度(36) + bottom padding(12) + 分隔线(0.5)
            let navBarHeight = topSafeAreaInset + 4 + 36 + 12 + 0.5

            // 顶部间距（导航栏高度）- 图片紧贴导航栏
            Color.clear
                .frame(height: navBarHeight)

            // 图片轮播（全宽，无边距，紧贴导航栏）
            if let images = post.images, !images.isEmpty {
                PostDetailImageCarousel(
                    images: images,
                    onImageTap: { index in
                        selectedImageIndex = index
                        showingImageViewer = true
                    }
                )
                .offset(y: 0)  // 确保没有额外的偏移
            }

            // 文字内容（在轮播图下方）
            if !post.content.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    postTextContent(post.content)

                    // AI生成标识
                    if post.isAIGenerated == true {
                        aiGeneratedBadge
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            // 发布时间
            Text(formatDate(post.createdAt))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 8)
        }
    }

    // MARK: - 视频内容布局（抖音风格）
    private func videoContentLayout(_ post: Post) -> some View {
        ZStack(alignment: .bottom) {
            // 视频播放区域 - 全屏显示（使用自研播放器）
            if let video = post.video {
                ShortVideoPlayerView(
                    videoURL: video,
                    autoPlay: true,
                    loop: true,
                    muted: false,
                    showControls: false
                )
                .id(video) // 使用视频 URL 作为 ID，确保切换视频时重新创建视图
                .ignoresSafeArea()
            }

            // 手势控制层（单击暂停/播放，双击点赞）
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    print("🎯 PostDetailView: 检测到双击手势")
                    handleDoubleTap(post: post)
                }
                .onTapGesture(count: 1) {
                    print("🎯 PostDetailView: 检测到单击手势")
                    handleSingleTap()
                }
                .ignoresSafeArea()

            // 顶部渐变遮罩（用于标题文字的背景）
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)

                Spacer()
            }
            .ignoresSafeArea(edges: .top)

            // 底部渐变遮罩（用于用户信息和文字描述的背景）
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

            // 内容层 - 底部对齐
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 12) {
                    // 左侧：用户信息和描述
                    VStack(alignment: .leading, spacing: 8) {
                        // 用户昵称（带 @ 符号）
                        Text("@\(post.author.nickname)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                        // 文字描述
                        if !post.content.isEmpty {
                            Text(post.content)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }

                        // 标签
                        if let tags = post.tags, !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.9))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .frame(height: 32)
                        }

                        // 位置信息
                        if let location = post.location {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12))
                                Text(location)
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                        }

                        // AI生成标识
                        if post.isAIGenerated == true {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11))
                                Text("AI生成")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.orange.opacity(0.95))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.25))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, calculateBottomPadding(safeAreaBottom: geometry.safeAreaInsets.bottom))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // 右侧：互动按钮（与左侧用户信息底部对齐）
                    VStack(spacing: 24) {
                        // 头像 + 关注按钮
                        ZStack(alignment: .bottom) {
                            // 用户头像
                            Button(action: {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("NavigateToUserProfile"),
                                    object: nil,
                                    userInfo: ["userId": post.author.id]
                                )
                            }) {
                                if let avatarURL = post.author.avatar {
                                    AsyncImage(url: URL(string: avatarURL)) { image in
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
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.white)
                                        .frame(width: 48, height: 48)
                                }
                            }

                            // 关注按钮（只在未关注且非当前用户的帖子时显示）
                            if !isCurrentUserPost(post) && !viewModel.isFollowingAuthor {
                                Button(action: {
                                    Task {
                                        await viewModel.toggleFollowUser()
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(AppConstants.Colors.primaryGreen)
                                        .clipShape(Circle())
                                }
                                .offset(y: 8)
                            }
                        }

                        // 点赞按钮
                        videoActionButton(
                            icon: post.isLiked ? "heart.fill" : "heart",
                            count: post.likesCount,
                            isActive: post.isLiked,
                            action: {
                                Task {
                                    await viewModel.toggleLike()
                                }
                            }
                        )

                        // 评论按钮
                        videoActionButton(
                            icon: "message",
                            count: post.commentsCount,
                            isActive: false,
                            action: {
                                // 滚动到评论区
                            }
                        )

                        // 收藏按钮
                        videoActionButton(
                            icon: post.isBookmarked ? "star.fill" : "star",
                            count: post.bookmarksCount,
                            isActive: post.isBookmarked,
                            activeColor: .yellow,
                            action: {
                                Task {
                                    await viewModel.toggleBookmark()
                                }
                            }
                        )
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, calculateBottomPadding(safeAreaBottom: geometry.safeAreaInsets.bottom))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }

            // 底部区域：广告或评论输入框（二选一，在同一位置）
            VStack {
                Spacer()

                if isBannerAdLoaded, let adView = bannerAdView {
                    // Banner 广告
                    BannerAdContainer(adView: adView, onAdClosed: {
                        // 广告关闭回调
                        print("🎯 视频详情页：广告关闭回调触发")
                        withAnimation {
                            isBannerAdLoaded = false
                            bannerAdView = nil
                        }
                        print("🎯 视频详情页：isBannerAdLoaded = \(isBannerAdLoaded)")
                    })
                } else {
                    // 底部交互栏（当广告关闭后显示）
                    videoBottomCommentBar
                        .onAppear {
                            print("🎯 视频详情页：评论输入框已显示")
                        }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // 播放/暂停指示器（居中显示，最上层）
            if showPlayPauseIndicator {
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

            // 点赞动画特效（居中显示，最上层）
            if showLikeAnimation {
                VStack {
                    Spacer()
                    likeAnimationView
                        .onAppear {
                            print("🎯 点赞动画视图已显示")
                        }
                    Spacer()
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            // 加载 Banner 广告
            loadBannerAd()
        }
        .onDisappear {
            // 销毁 Banner 广告
            adManager.destroyBannerAd()
            isBannerAdLoaded = false
            bannerAdView = nil
        }
    }

    // MARK: - 视频互动按钮（精致版）
    private func videoActionButton(icon: String, count: Int, isActive: Bool, activeColor: Color = .red, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // 图标容器 - 添加半透明背景和毛玻璃效果
                ZStack {
                    // 背景圆形
                    Circle()
                        .fill(
                            isActive
                            ? activeColor.opacity(0.2)
                            : Color.black.opacity(0.3)
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(
                                    isActive
                                    ? activeColor.opacity(0.5)
                                    : Color.white.opacity(0.3),
                                    lineWidth: 1.5
                                )
                        )

                    // 图标
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isActive ? activeColor : .white)
                }
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)

                // 数量文字
                if count > 0 {
                    Text(formatCount(count))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.4))
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 1)
                }
            }
            .scaleEffect(isActive ? 1.0 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
        }
    }

    // MARK: - 格式化数字
    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000.0)
        } else if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }

    // MARK: - 默认内容布局
    private func defaultContentLayout(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 计算导航栏的精确高度
            let navBarHeight = topSafeAreaInset + 4 + 36 + 12 + 0.5

            // 顶部间距（导航栏高度）
            Color.clear
                .frame(height: navBarHeight)

            // 帖子文本内容
            if !post.content.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    postTextContent(post.content)

                    // AI生成标识
                    if post.isAIGenerated == true {
                        aiGeneratedBadge
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)  // 导航栏下方的间距
            }

            // 图片内容 - 与头像对齐
            if let images = post.images, !images.isEmpty {
                TwitterStyleImageGrid(
                    images: images,
                    onImageTap: { index in
                        selectedImageIndex = index
                        showingImageViewer = true
                    }
                )
                .padding(.leading, 20) // 与头像左边缘对齐
                .padding(.trailing, 20)
                .padding(.top, post.content.isEmpty ? 16 : 24) // 如果有文本内容，增加间距避免误触
            }
        }
    }

    // MARK: - 主要内容视图
    private func mainContentView(_ post: Post) -> some View {
        Group {
            if hasVideo(post) {
                // 视频内容：使用全屏布局，不使用 ScrollView
                videoContentLayout(post)
            } else {
                // 其他内容：使用 ScrollView 布局
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // 帖子内容区域
                        postContentSection(post)

                        // 详情页插入广告区域（在帖子内容和评论之间）
                        detailPageAdSection

                        // 评论区域
                        commentsSection
                    }
                    .padding(.bottom, 180) // 增加底部间距，为底部栏和安全区域留出更多空间
                }
                .ignoresSafeArea(edges: .top)  // 忽略顶部安全区域，让内容从屏幕顶部开始
            }
        }
    }

    // MARK: - 帖子内容区域
    private func postContentSection(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 判断内容类型并使用对应的布局
            if hasVideo(post) {
                // 视频内容：使用视频详情页布局
                videoContentLayout(post)
            } else if hasImagesAndText(post) {
                // 图片+文字内容：使用轮播图布局
                imageTextContentLayout(post)
            } else {
                // 其他内容：使用默认布局
                defaultContentLayout(post)
            }

            // 标签 - 统一左对齐
            if let tags = post.tags, !tags.isEmpty {
                modernTagsView(tags)
                    .padding(.horizontal, 20)  // 统一使用 20 的水平间距
                    .padding(.top, 16)
            }

            // 打卡记录信息 - 与发布时间对齐
            if let checkin = post.checkin {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)

                        Text("打卡记录")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("时间:")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .leading)

                            Text("\(checkin.date) \(checkin.time)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)

                            Spacer()
                        }

                        if let address = checkin.locationAddress, !address.isEmpty {
                            HStack {
                                Text("地点:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .leading)

                                Text(address)
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Spacer()
                            }
                        }

                        if let note = checkin.note, !note.isEmpty {
                            HStack(alignment: .top) {
                                Text("备注:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .leading)

                                Text(note)
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)

                                Spacer()
                            }
                        }

                        // 连续打卡天数显示
                        if let consecutiveDays = checkin.consecutiveDays, consecutiveDays > 0 {
                            HStack {
                                Text("连续:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .leading)

                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)

                                    Text("连续打卡 \(consecutiveDays) 天")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.orange)
                                }

                                Spacer()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)  // 统一使用 20 的水平间距
                .padding(.top, 16)
            }

            // 运动记录信息
            if let workout = post.workout {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)

                        Text("运动记录")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("类型:")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .leading)

                            Text(getWorkoutTypeChinese(workout.workoutType))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)

                            Spacer()
                        }

                        HStack {
                            Text("时间:")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .leading)

                            Text("\(workout.startTime) - \(workout.endTime)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)

                            Spacer()
                        }

                        HStack {
                            Text("时长:")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .leading)

                            Text("\(workout.duration) 秒")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)

                            Spacer()
                        }

                        // 距离
                        if let distance = workout.totalDistance, !distance.isEmpty {
                            HStack {
                                Text("距离:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .leading)

                                Text(distance)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                        }

                        // 卡路里
                        if let calories = workout.calories {
                            HStack {
                                Text("卡路里:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .leading)

                                Text("\(calories)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                        }

                        if let steps = workout.totalSteps {
                            HStack {
                                Text("步数:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .leading)

                                Text("\(steps)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)  // 统一使用 20 的水平间距
                .padding(.top, 16)
            }

            // 位置信息
            if post.location != nil {
                // PostLocationInfoView(
                //     location: post.location,
                //     latitude: post.latitude,
                //     longitude: post.longitude,
                //     style: .detailed
                // )
                if let location = post.location {
                    Text("📍 \(location)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.leading, 20) // 与头像左边缘对齐
                        .padding(.trailing, 20)
                        .padding(.top, 16)
                }
            }

            // 帖子统计信息（已移除显示）
            postStatsView(post)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            // 帖子内容区域底部留白
            Spacer()
                .frame(height: 32)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - 现代化用户头部
    private func modernUserHeader(_ post: Post) -> some View {
        HStack(spacing: 12) {
            // 将用户头像和用户名合并到一个可点击区域中
            Button(action: {
                // 使用通知系统导航到用户资料页面
                print("🔍 帖子详情页面：点击用户头像，用户ID: \(post.author.id)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowUserProfileInCommunity"),
                    object: nil,
                    userInfo: ["userId": String(post.author.id)]
                )
            }) {
                HStack(spacing: 12) {
                    // 用户头像（带自己标识）
                    ZStack {
                        AsyncImage(url: URL(string: post.author.avatar ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(AppConstants.Colors.primaryGreen.opacity(0.2))
                                .overlay(
                                    Text(String(post.author.nickname.prefix(1)))
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(AppConstants.Colors.primaryGreen)
                                )
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())

                        // 只有当前用户的帖子才显示"我"标识
                        if isCurrentUserPost(post) {
                            Circle()
                                .fill(AppConstants.Colors.primaryGreen)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Text("我")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 16, y: 16) // 移到下方
                        }
                    }

                    // 用户信息
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(post.author.nickname)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            if post.author.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                        }

                        Text(formatDate(post.createdAt))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // 关注按钮（只在非当前用户的帖子时显示）
            if !isCurrentUserPost(post) {
                Button(action: {
                    Task {
                        await viewModel.toggleFollowUser()
                    }
                }) {
                    HStack(spacing: 4) {
                        if viewModel.isFollowActionLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Text(viewModel.isFollowingAuthor ? "取消关注" : "关注")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(viewModel.isFollowingAuthor ? Color(.systemGray) : AppConstants.Colors.primaryGreen)
                    .cornerRadius(20)
                }
                .disabled(viewModel.isFollowActionLoading)
            }
        }
    }

    // MARK: - 帖子文本内容
    private func postTextContent(_ content: String) -> some View {
        Text(content)
            .dynamicFont(.body)
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
    }

    // MARK: - AI生成标识
    private var aiGeneratedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "info.circle")
                .font(.system(size: 11))
            Text("此内容由AI生成，仅供参考")
                .font(.system(size: 12))
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }

    // MARK: - 现代化图片网格
    private func modernImageGrid(_ images: [String]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: images.count == 1 ? 1 : 2)

        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                // CachedAsyncImage(
                //     url: imageUrl,
                //     content: { image in
                //         image
                //             .resizable()
                //             .aspectRatio(contentMode: .fill)
                //     },
                //     placeholder: {
                //     Rectangle()
                //         .fill(Color.gray.opacity(0.2))
                //         .overlay(
                //             VStack(spacing: 4) {
                //                 ProgressView()
                //                     .scaleEffect(0.8)
                //                 Text("加载中...")
                //                     .font(.system(size: 10))
                //                     .foregroundColor(.gray)
                //             }
                //         )
                //     },
                //     useCache: false
                // )
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            VStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("加载中...")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        )
                }
                .frame(height: images.count == 1 ? 400 : 200)
                .clipped()
                .onTapGesture {
                    selectedImageIndex = index
                    showingImageViewer = true
                }
            }
        }
    }

    // MARK: - 现代化标签视图
    private func modernTagsView(_ tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Button(action: {
                        navigateToTagSearch(tag)
                    }) {
                        Text("#\(tag)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppConstants.Colors.primaryGreen.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 0) // 确保没有额外的水平内边距
        }
    }

    // MARK: - 帖子统计信息（已移除，不在内容区域显示）
    private func postStatsView(_ post: Post) -> some View {
        // 不再显示统计信息
        EmptyView()
    }



    // MARK: - 帖子详情卡片（保留原有的，以防需要）
    private func postDetailCard(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 用户信息
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: post.author.avatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(AppConstants.Colors.primaryGreen.opacity(0.2))
                            .overlay(
                                Text(String(post.author.nickname.prefix(1)))
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(AppConstants.Colors.primaryGreen)
                            )
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())

                    // 只有当前用户的帖子才显示"我"标识
                    if isCurrentUserPost(post) {
                        Circle()
                            .fill(AppConstants.Colors.primaryGreen)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text("我")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 16, y: 16) // 移到下方
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(post.author.nickname)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConstants.Colors.primaryText)
                        
                        if post.author.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(formatDate(post.createdAt))
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.Colors.tertiaryText)
                }
                
                Spacer()
                
                // 关注按钮（只在非当前用户的帖子时显示）
                if !isCurrentUserPost(post) {
                    Button(action: {
                        Task {
                            await viewModel.toggleFollowUser()
                        }
                    }) {
                        HStack(spacing: 4) {
                            if viewModel.isFollowActionLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Text(viewModel.isFollowingAuthor ? "取消关注" : "关注")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(viewModel.isFollowingAuthor ? Color(.systemGray) : AppConstants.Colors.primaryGreen)
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isFollowActionLoading)
                }
            }
            
            // 帖子内容
            Text(post.content)
                .font(.system(size: 16))
                .foregroundColor(AppConstants.Colors.primaryText)
                .lineLimit(nil)
            
            // 图片内容
            if let images = post.images, !images.isEmpty {
                TwitterStyleImageGrid(
                    images: images,
                    onImageTap: { index in
                        // 处理图片点击
                        selectedImageIndex = index
                        showingImageViewer = true
                    }
                )
            }
            
            // 标签
            if let tags = post.tags, !tags.isEmpty {
                tagsView(tags)
            }
            
            // 互动按钮
            interactionButtons(post)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 标签视图
    private func tagsView(_ tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Button(action: {
                        navigateToTagDetail(tag)
                    }) {
                        // 如果标签不以#开头，添加#号显示
                        Text(tag.hasPrefix("#") ? tag : "#\(tag)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppConstants.Colors.primaryGreen.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 1)
        }
    }
    
    // MARK: - 互动按钮
    private func interactionButtons(_ post: Post) -> some View {
        HStack(spacing: 24) {
            // 点赞按钮
            Button(action: { viewModel.toggleLike() }) {
                HStack(spacing: 4) {
                    Image(systemName: (viewModel.post?.isLiked ?? false) ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor((viewModel.post?.isLiked ?? false) ? .red : AppConstants.Colors.secondaryText)

                    Text("\(viewModel.post?.likesCount ?? 0)")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.Colors.secondaryText)
                }
            }

            // 评论按钮
            Button(action: { showingCommentInput = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppConstants.Colors.secondaryText)

                    Text("\(viewModel.post?.commentsCount ?? 0)")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.Colors.secondaryText)
                }
            }
            


            Spacer()

            // 收藏按钮
            Button(action: { viewModel.toggleBookmark() }) {
                Image(systemName: (viewModel.post?.isBookmarked ?? false) ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor((viewModel.post?.isBookmarked ?? false) ? AppConstants.Colors.primaryGreen : AppConstants.Colors.secondaryText)
            }
        }
    }
    
    // MARK: - 现代化评论区域
    private var commentsSection: some View {
        VStack(spacing: 0) {
            // 更好的分隔区域
            VStack(spacing: 0) {
                // 渐变分隔线
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.gray.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                // 分隔区域
                Rectangle()
                    .fill(Color(.systemGroupedBackground))
                    .frame(height: 12)

                // 底部分隔线
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 0.5)
            }
            
            // 互动用户列表区域
            if let post = viewModel.post {
                interactionUsersSection(post)
            }

            // 使用统一的评论系统
            UnifiedCommentListView(
                postId: viewModel.postId,
                onNavigateToProfile: { userId in
                    print("🔍 评论区域：点击用户，用户ID: \(userId)")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowUserProfileInCommunity"),
                        object: nil,
                        userInfo: ["userId": userId]
                    )
                },
                onCommentCountChanged: { newCount in
                    // 更新帖子的评论总数
                    viewModel.updateCommentsCount(newCount)
                }
            )
        }
    }
    
    // MARK: - 互动用户区域
    private func interactionUsersSection(_ post: Post) -> some View {
        VStack(spacing: 0) {
            // 点赞用户列表按钮
            if post.likesCount > 0 {
                Button(action: {
                    viewModel.showingLikesUsers = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                        
                        Text("点赞")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("\(post.likesCount)")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        highlightSection == .likes && isHighlighted
                            ? Color.yellow.opacity(0.3)
                            : Color(.systemBackground)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .animation(.easeInOut(duration: 0.3), value: isHighlighted)
                
                Divider()
                    .padding(.leading, 48)
            }
            
            // 收藏用户列表按钮
            if post.bookmarksCount > 0 {
                Button(action: {
                    viewModel.showingBookmarksUsers = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                        
                        Text("收藏")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("\(post.bookmarksCount)")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        highlightSection == .bookmarks && isHighlighted
                            ? Color.yellow.opacity(0.3)
                            : Color(.systemBackground)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .animation(.easeInOut(duration: 0.3), value: isHighlighted)
                
                Divider()
                    .padding(.leading, 48)
            }
            
            // 如果有互动用户，添加底部间距
            if post.likesCount > 0 || post.bookmarksCount > 0 {
                Rectangle()
                    .fill(Color(.systemGroupedBackground))
                    .frame(height: 12)
            }
        }
        .onAppear {
            // 如果有高亮区域，延迟触发高亮动画并打开对应列表
            if let section = highlightSection {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isHighlighted = true
                    
                    // 自动打开对应的用户列表
                    switch section {
                    case .likes:
                        viewModel.showingLikesUsers = true
                    case .bookmarks:
                        viewModel.showingBookmarksUsers = true
                    case .comments:
                        // 评论区域不需要打开 sheet，直接滚动到评论区即可
                        break
                    }
                    
                    // 3秒后取消高亮
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        isHighlighted = false
                    }
                }
            }
        }
    }
    
    // MARK: - 详情页广告区域
    private var detailPageAdSection: some View {
        VStack(spacing: 0) {
            if !detailPageAdViews.isEmpty {
                // 广告分隔区域
                VStack(spacing: 0) {
                    // 渐变分隔线
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color.gray.opacity(0.1),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)

                    // 分隔区域
                    Rectangle()
                        .fill(Color(.systemGroupedBackground))
                        .frame(height: 12)
                }

                // 广告内容
                ForEach(Array(detailPageAdViews.enumerated()), id: \.offset) { index, adView in
                    AdCardView(adView: adView)
                        .id("detail_page_ad_\(index)")
                }

                // 分隔区域
                Rectangle()
                    .fill(Color(.systemGroupedBackground))
                    .frame(height: 12)
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("加载中...")
                .font(.system(size: 16))
                .foregroundColor(AppConstants.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 错误视图
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppConstants.Colors.tertiaryText)
            
            Text("加载失败")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppConstants.Colors.primaryText)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            } else {
                Text("请检查网络连接后重试")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.secondaryText)
            }
            
            Button("重试") {
                Task {
                    await viewModel.loadPost(postId: postId)
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppConstants.Colors.primaryGreen)
            .cornerRadius(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - 更多选项菜单
    @ViewBuilder
    private var moreOptionsButtons: some View {
        if viewModel.post != nil {
            // 根据是否是自己的帖子显示不同选项
            let isOwnPost = isCurrentUserPost(viewModel.post!)

            if isOwnPost {
                // 只保留删除功能，移除编辑功能
                Button("删除", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            } else {
                Button("举报") {
                    showingReportView = true
                }
                Button("屏蔽用户") {
                    showingBlockUserView = true
                }
                Button("屏蔽帖子", role: .destructive) {
                    showingBlockPostAlert = true
                }
            }
        }

        Button("取消", role: .cancel) { }
    }
    
    // MARK: - 辅助方法

    /// 屏蔽帖子
    private func blockPost() async {
        guard let post = viewModel.post else { return }

        // 预检查：不能屏蔽自己的帖子
        if let currentUserId = AuthManager.shared.getCurrentUserId(),
           post.author.id == currentUserId {
            await MainActor.run {
                viewModel.errorMessage = "无法屏蔽自己发布的帖子"
                viewModel.showError = true
            }
            return
        }

        do {
            let success = try await communityService.blockPost(
                postId: post.id,
                reason: "屏蔽不感兴趣的帖子内容"
            )

            if success {
                // 屏蔽成功，返回上一页
                await MainActor.run {
                    dismiss()
                }
            } else {
                await MainActor.run {
                    viewModel.errorMessage = "屏蔽失败，请稍后重试"
                    viewModel.showError = true
                }
            }
        } catch {
            await MainActor.run {
                // 检查是否是特定的业务逻辑错误
                let nsError = error as NSError
                switch nsError.code {
                case -1:
                    viewModel.errorMessage = "无法屏蔽自己发布的帖子"
                case -2:
                    viewModel.errorMessage = "服务器暂时无法处理，请稍后重试"
                default:
                    viewModel.errorMessage = "网络错误：\(error.localizedDescription)"
                }

                viewModel.showError = true
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        // 尝试多种日期格式解析
        let formatters = [
            ISO8601DateFormatter(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return formatter
            }()
        ]

        var date: Date?
        for formatter in formatters {
            if let iso8601Formatter = formatter as? ISO8601DateFormatter {
                date = iso8601Formatter.date(from: dateString)
            } else if let dateFormatter = formatter as? DateFormatter {
                date = dateFormatter.date(from: dateString)
            }
            if date != nil { break }
        }

        guard let parsedDate = date else {
            return dateString
        }

        // 始终显示 yyyy-MM-dd HH:mm 格式（不显示秒）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.string(from: parsedDate)
    }

    // MARK: - 视频底部评论栏（仅显示评论输入框）
    private var videoBottomCommentBar: some View {
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
    }

    // MARK: - 现代化底部栏
    private var modernBottomBar: some View {
        VStack(spacing: 0) {
            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)

            HStack(spacing: 16) {
                // 评论输入框
                Button(action: {
                    showingCommentInput = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)

                        Text("写评论...")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(24)
                }
                .buttonStyle(PlainButtonStyle())

                // 互动按钮组（只在非视频内容时显示）
                if let post = viewModel.post, !hasVideo(post) {
                    modernInteractionButtons(post)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .padding(.bottom, keyboardHeight > 0 ? keyboardHeight - 34 : 0)
            .background(
                Color.white
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
    }

    // MARK: - 现代化交互按钮（精致版）
    private func modernInteractionButtons(_ post: Post) -> some View {
        HStack(spacing: 12) {
            // 点赞按钮
            Button(action: {
                viewModel.toggleLike()
            }) {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill((viewModel.post?.isLiked ?? false) ? Color.red.opacity(0.1) : Color.gray.opacity(0.08))
                            .frame(width: 36, height: 36)

                        Image(systemName: (viewModel.post?.isLiked ?? false) ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor((viewModel.post?.isLiked ?? false) ? .red : .secondary)
                    }

                    if (viewModel.post?.likesCount ?? 0) > 0 {
                        Text("\(viewModel.post?.likesCount ?? 0)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor((viewModel.post?.isLiked ?? false) ? .red : .secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // 收藏按钮
            Button(action: {
                viewModel.toggleBookmark()
            }) {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill((viewModel.post?.isBookmarked ?? false) ? AppConstants.Colors.primaryGreen.opacity(0.1) : Color.gray.opacity(0.08))
                            .frame(width: 36, height: 36)

                        Image(systemName: (viewModel.post?.isBookmarked ?? false) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor((viewModel.post?.isBookmarked ?? false) ? AppConstants.Colors.primaryGreen : .secondary)
                    }

                    if (viewModel.post?.bookmarksCount ?? 0) > 0 {
                        Text("\(viewModel.post?.bookmarksCount ?? 0)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor((viewModel.post?.isBookmarked ?? false) ? AppConstants.Colors.primaryGreen : .secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - 判断是否是当前用户的帖子
    private func isCurrentUserPost(_ post: Post) -> Bool {
        // 从AuthManager获取当前用户信息
        guard let currentUserId = AuthManager.shared.getCurrentUserId() else {
            return false
        }

        // 比较用户ID
        return currentUserId == post.author.id
    }

    /// 创建 CommunityPost 对象用于 UserProfileNavigationManager
    private func createCommunityPostFromPostDetail(_ post: Post) -> Post {
        return post
    }

    /// 导航到标签详情页面
    private func navigateToTagDetail(_ tagName: String) {
        // 统一标签格式：如果不以#开头，添加#号
        let searchTag = tagName.hasPrefix("#") ? tagName : "#\(tagName)"
        print("🏷️ 导航到标签详情页面: \(searchTag)")

        // 发送通知，让父级视图处理导航
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToTagDetail"),
            object: nil,
            userInfo: ["tagName": searchTag]
        )
    }
    
    /// 导航到标签搜索页面
    private func navigateToTagSearch(_ tagName: String) {
        // 统一标签格式：如果不以#开头，添加#号
        let searchTag = tagName.hasPrefix("#") ? tagName : "#\(tagName)"
        print("🏷️ 导航到标签搜索页面: \(searchTag)")

        // 发送通知，让父级视图处理导航到搜索页面
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToTagSearch"),
            object: nil,
            userInfo: ["tagName": searchTag]
        )
    }

    // MARK: - 详情页广告相关方法

    /// 加载详情页广告
    private func loadDetailPageNativeAds() {
        print("🎯 详情页：开始调用 loadDetailPageNativeAds")
        print("🎯 详情页：广告管理器状态 - isDetailPageAdLoaded: \(adManager.isDetailPageAdLoaded)")

        adManager.loadDetailPageNativeAds { success, adViews in
            print("🎯 详情页：广告加载回调 - success: \(success), adViews.count: \(adViews.count)")
            DispatchQueue.main.async {
                if success && !adViews.isEmpty {
                    self.detailPageAdViews = adViews
                    self.isDetailPageAdLoaded = true
                    print("🎯 详情页：详情页广告加载成功，数量: \(adViews.count)")
                    print("🎯 详情页：广告视图详情: \(adViews.map { "\($0.frame.size)" })")
                } else {
                    print("❌ 详情页：详情页广告加载失败 - success: \(success), isEmpty: \(adViews.isEmpty)")
                    if !success {
                        print("❌ 详情页：广告加载失败，可能原因：网络问题、广告位配置问题或无广告填充")
                    }
                }
            }
        }
    }

    /// 清理详情页广告
    private func clearDetailPageAds() {
        print("🎯 详情页：清理详情页广告")
        DispatchQueue.main.async {
            self.detailPageAdViews.removeAll()
            self.isDetailPageAdLoaded = false
        }
        // 销毁广告管理器中的详情页广告
        adManager.destroyDetailPageAd()
    }

    // MARK: - Banner 广告相关方法

    /// 加载 Banner 广告
    private func loadBannerAd() {
        print("🎯 视频详情页：开始加载 Banner 广告")

        // 获取当前的 ViewController
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ 无法获取 ViewController")
            return
        }

        // 查找最顶层的 ViewController
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        adManager.loadBannerAd(viewController: topViewController) { success, adView in
            print("🎯 视频详情页：Banner 广告加载回调 - success: \(success)")
            DispatchQueue.main.async {
                if success, let adView = adView {
                    self.bannerAdView = adView
                    self.isBannerAdLoaded = true
                    print("🎯 视频详情页：Banner 广告加载成功")
                } else {
                    print("❌ 视频详情页：Banner 广告加载失败")
                }
            }
        }
    }

    /// 计算底部间距（根据广告状态和安全区域）
    private func calculateBottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
        if isBannerAdLoaded {
            // 广告已加载：广告高度 60pt（为广告留出空间）
            return 50
        } else {
            // 广告关闭后：为底部交互栏留出空间（约 80pt）
            return 80
        }
    }

    // MARK: - 视频手势处理

    /// 处理单击手势（暂停/播放）
    private func handleSingleTap() {
        ShortVideoPlayerManager.shared.togglePlayPause()

        // 显示播放/暂停指示器
        withAnimation(.easeInOut(duration: 0.2)) {
            showPlayPauseIndicator = true
        }

        // 0.5秒后隐藏指示器
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showPlayPauseIndicator = false
            }
        }
    }

    /// 处理双击手势（点赞）
    private func handleDoubleTap(post: Post) {
        print("🎯 PostDetailView: handleDoubleTap 被调用")
        print("🎯 当前点赞状态: \(viewModel.post?.isLiked ?? false)")

        // 如果还没有点赞，则执行点赞
        if !(viewModel.post?.isLiked ?? false) {
            print("🎯 执行点赞操作")
            Task {
                await viewModel.toggleLike()
            }
        }

        // 显示点赞动画
        print("🎯 显示点赞动画，showLikeAnimation: \(showLikeAnimation) -> true")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showLikeAnimation = true
        }

        // 1秒后隐藏动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🎯 隐藏点赞动画")
            withAnimation(.easeOut(duration: 0.3)) {
                showLikeAnimation = false
            }
        }
    }

    /// 点赞动画视图（抖音风格）
    private var likeAnimationView: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 80, weight: .bold))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.2), radius: 5)
            .scaleEffect(showLikeAnimation ? 1.3 : 0.5)
            .opacity(showLikeAnimation ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showLikeAnimation)
    }

    // 运动类型中文映射
    private func getWorkoutTypeChinese(_ workoutType: String) -> String {
        switch workoutType.lowercased() {
        case "running", "run":
            return "跑步"
        case "walking", "walk":
            return "步行"
        case "cycling", "bike", "bicycle":
            return "骑行"
        case "swimming", "swim":
            return "游泳"
        case "hiking", "hike":
            return "徒步"
        case "yoga":
            return "瑜伽"
        case "fitness", "gym", "workout":
            return "健身"
        case "basketball":
            return "篮球"
        case "football", "soccer":
            return "足球"
        case "tennis":
            return "网球"
        case "badminton":
            return "羽毛球"
        case "pingpong", "tabletennis":
            return "乒乓球"
        case "climbing":
            return "攀岩"
        case "dancing", "dance":
            return "舞蹈"
        case "boxing":
            return "拳击"
        case "martial arts", "martialarts":
            return "武术"
        case "pilates":
            return "普拉提"
        case "aerobics":
            return "有氧运动"
        case "strength", "weightlifting":
            return "力量训练"
        case "cardio":
            return "有氧训练"
        default:
            return workoutType
        }
    }
}

// MARK: - 小红书风格图片轮播器组件
struct PostDetailImageCarousel: View {
    let images: [String]
    let onImageTap: (Int) -> Void

    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            // 图片轮播区域
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill() // 填充满宽度
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.2)
                                .clipped()
                        case .failure(_):
                            // 加载失败状态
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.2)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 32))
                                            .foregroundColor(.gray)
                                        Text("加载失败")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        case .empty:
                            // 加载中状态
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.2)
                                .overlay(
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                        Text("加载中...")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.2)
                        }
                    }
                    .onTapGesture {
                        onImageTap(index)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: UIScreen.main.bounds.width * 1.2) // 宽度的1.2倍，适合大部分图片比例
            .clipped()  // 裁剪超出边界的内容
            .edgesIgnoringSafeArea(.horizontal)  // 忽略水平安全区域

            // 主题色指示器（在图片下方）
            if images.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<images.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index == currentIndex ? AppConstants.Colors.primaryGreen : Color.gray.opacity(0.3))
                            .frame(width: index == currentIndex ? 16 : 6, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 20)
            }

            // 底部缩小的白色指示器
            if images.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 4, height: 4)
                            .scaleEffect(index == currentIndex ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .padding(.top, 6)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - 打卡数据视图
    private func checkinDataView(_ checkin: CheckinData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)

                Text("打卡记录")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("时间:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)

                    Text("\(checkin.date) \(checkin.time)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()
                }

                if let address = checkin.locationAddress, !address.isEmpty {
                    HStack {
                        Text("地点:")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        Text(address)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()
                    }
                }

                if let note = checkin.note, !note.isEmpty {
                    let formattedNote = formatCheckinNote(note)
                    if !formattedNote.isEmpty {
                        HStack(alignment: .top) {
                            Text("备注:")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .leading)

                            Text(formattedNote)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .lineLimit(2)

                            Spacer()
                        }
                    }
                }

                // 连续打卡天数显示
                if let consecutiveDays = checkin.consecutiveDays, consecutiveDays > 0 {
                    HStack {
                        Text("连续:")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)

                            Text("连续打卡 \(consecutiveDays) 天")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.orange)
                        }

                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.green.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 运动数据视图
    private func workoutDataView(_ workout: PostWorkoutData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)

                Text("运动记录")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("类型:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)

                    Text(getWorkoutTypeChinese(workout.workoutType))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()
                }

                HStack {
                    Text("时间:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)

                    Text(formatWorkoutTime(workout.startTime, workout.endTime))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()
                }

                HStack {
                    Text("时长:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)

                    Text(formatDuration(workout.duration))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()
                }

                // 距离
                if let distance = workout.totalDistance, !distance.isEmpty {
                    HStack {
                        Text("距离:")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        Text(distance)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }

                // 卡路里
                if let calories = workout.calories {
                    HStack {
                        Text("卡路里:")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        Text("\(calories)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }

                if let steps = workout.totalSteps {
                    HStack {
                        Text("步数:")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        Text("\(steps)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.orange.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 辅助函数

    // 格式化运动时长
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%d小时%d分钟", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d分钟%d秒", minutes, remainingSeconds)
        } else {
            return String(format: "%d秒", remainingSeconds)
        }
    }

    // 格式化打卡备注
    private func formatCheckinNote(_ note: String) -> String {
        // 检查是否包含连续天数信息的模式
        if note.contains("连续") && note.contains("天") {
            return note
        }

        // 检查是否包含"第X天"的模式
        if note.contains("第") && note.contains("天") {
            return note
        }

        // 检查是否包含数字+天的模式（如"15天"）
        let dayPattern = #"\d+天"#
        if note.range(of: dayPattern, options: .regularExpression) != nil {
            return note
        }

        // 如果备注是"iOS应用打卡"或类似的系统默认备注，不显示
        if note == "iOS应用打卡" || note.isEmpty {
            return ""
        }

        // 其他情况直接返回原备注
        return note
    }

    // 格式化运动时间
    private func formatWorkoutTime(_ startTime: String, _ endTime: String) -> String {
        // 尝试多种时间格式
        let formatters = [
            "HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'"
        ]

        for formatString in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = formatString

            if let start = formatter.date(from: startTime),
               let end = formatter.date(from: endTime) {
                let timeFormatter = DateFormatter()
                // 修改为显示完整的年月日时分
                timeFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                let startTimeStr = timeFormatter.string(from: start)
                let endTimeStr = timeFormatter.string(from: end)

                // 如果是同一天，只显示一次日期
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let startDateStr = dateFormatter.string(from: start)
                let endDateStr = dateFormatter.string(from: end)

                if startDateStr == endDateStr {
                    let onlyTimeFormatter = DateFormatter()
                    onlyTimeFormatter.dateFormat = "HH:mm"
                    let startOnlyTime = onlyTimeFormatter.string(from: start)
                    let endOnlyTime = onlyTimeFormatter.string(from: end)
                    return "\(startDateStr) \(startOnlyTime) - \(endOnlyTime)"
                } else {
                    return "\(startTimeStr) - \(endTimeStr)"
                }
            }
        }

        // 如果都解析失败，尝试提取时间部分
        let startTimeExtracted = extractTimeFromString(startTime)
        let endTimeExtracted = extractTimeFromString(endTime)

        if !startTimeExtracted.isEmpty && !endTimeExtracted.isEmpty {
            return "\(startTimeExtracted) - \(endTimeExtracted)"
        }

        // 最后的备选方案
        return "运动时间"
    }

    // 从字符串中提取时间
    private func extractTimeFromString(_ timeString: String) -> String {
        // 尝试匹配 HH:mm:ss 或 HH:mm 格式
        let timePattern = #"\d{1,2}:\d{2}(:\d{2})?"#
        if let range = timeString.range(of: timePattern, options: .regularExpression) {
            let timeStr = String(timeString[range])
            // 如果包含秒，去掉秒部分
            if timeStr.count > 5 {
                return String(timeStr.prefix(5))
            }
            return timeStr
        }

        // 如果没有找到时间格式，返回空字符串
        return ""
    }

    // 运动类型中文映射
    private func getWorkoutTypeChinese(_ workoutType: String) -> String {
        switch workoutType.lowercased() {
        case "running", "run":
            return "跑步"
        case "walking", "walk":
            return "步行"
        case "cycling", "bike", "bicycle":
            return "骑行"
        case "swimming", "swim":
            return "游泳"
        case "hiking", "hike":
            return "徒步"
        case "yoga":
            return "瑜伽"
        case "fitness", "gym", "workout":
            return "健身"
        case "basketball":
            return "篮球"
        case "football", "soccer":
            return "足球"
        case "tennis":
            return "网球"
        case "badminton":
            return "羽毛球"
        case "pingpong", "tabletennis":
            return "乒乓球"
        case "climbing":
            return "攀岩"
        case "dancing", "dance":
            return "舞蹈"
        case "boxing":
            return "拳击"
        case "martial arts", "martialarts":
            return "武术"
        case "pilates":
            return "普拉提"
        case "aerobics":
            return "有氧运动"
        case "strength", "weightlifting":
            return "力量训练"
        case "cardio":
            return "有氧训练"
        default:
            return workoutType
        }
    }

}





#Preview {
    PostDetailView(postId: "test-post-id")
}
