import SwiftUI

// MARK: - Tab Selection Environment
struct TabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<MainTab>? = nil
}

extension EnvironmentValues {
    var tabSelection: Binding<MainTab>? {
        get { self[TabSelectionKey.self] }
        set { self[TabSelectionKey.self] = newValue }
    }
}

/// 用户详情页面 - 快手风格设计
struct UserProfileView: View {
    let userId: String
    let isRootView: Bool // 是否为根视图（决定是否显示Tab栏）
    let isPersonalCenter: Bool // 是否为个人中心
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode

    // 便利初始化器，保持向后兼容
    init(userId: String, isRootView: Bool) {
        self.userId = userId
        self.isRootView = isRootView
        self.isPersonalCenter = false
    }

    // 完整初始化器
    init(userId: String, isRootView: Bool, isPersonalCenter: Bool) {
        self.userId = userId
        self.isRootView = isRootView
        self.isPersonalCenter = isPersonalCenter
    }
    @StateObject private var viewModel = UserProfileViewModel()
    @State private var selectedTab: ProfileTab = .posts
    @State private var scrollOffset: CGFloat = 0
    @State private var showNavTitle: Bool = false
    @State private var navBarOpacity: Double = 0.0
    @State private var navBarBlur: Double = 0.0

    // 关注列表相关
    @State private var showFollowersList = false
    @State private var showFollowingList = false

    // 更多选项相关
    @State private var showMoreOptions = false
    @State private var showBlockConfirmation = false

    // 设置页面相关
    @State private var showingSettings = false

    // 编辑资料相关
    @State private var showEditProfile = false

    // 背景图上传相关
    @State private var showingBackgroundImagePicker = false
    @State private var isUploadingBackgroundImage = false

    // 移除本地导航路径，使用父级导航系统

    // 举报相关
    @State private var showingReportSheet = false
    @State private var reportingPostId: String?

    // 聊天相关
    @State private var showingChatDetail = false

    // 帖子详情相关
    @State private var showingPostDetail = false
    @State private var selectedPostId: String?
    @State private var sheetNavigationPath = NavigationPath() // Sheet内部的导航路径

    // Tab切换相关
    @Environment(\.tabSelection) private var tabSelection

    // 菜单导航相关
    @State private var showingHealthStats = false
    @State private var showingMemberCenter = false
    @State private var showingMyPosts = false
    @State private var showingMyBookmarks = false
    @State private var showingCreatorCenter = false
    @State private var showingActivityCenter = false
    @State private var showingWidgetSettings = false
    @State private var showingFeedbackHelp = false

    // 便利初始化方法，默认为子视图（隐藏Tab栏）
    init(userId: String) {
        self.userId = userId
        self.isRootView = false
        self.isPersonalCenter = false
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    // 背景色
                    Color(.systemBackground)
                        .ignoresSafeArea()

                    // 主要内容区域
                    if viewModel.isLoading && viewModel.userProfile == nil {
                        loadingView
                    } else if let userProfile = viewModel.userProfile {
                        kuaishouStyleContentView(userProfile)
                    } else {
                        errorView
                    }
                }
            }
            .ignoresSafeArea(.container, edges: .top) // 让整个视图忽略顶部安全区域
            .navigationBarHidden(true)
            .modifier(TabBarVisibilityModifier(shouldShow: isRootView))
            // 移除本地导航目标，使用父级导航系统
        }
        .sheet(isPresented: $showFollowersList) {
            UserListView(userId: userId, listType: .followers)
        }
        .sheet(isPresented: $showFollowingList) {
            UserListView(userId: userId, listType: .following)
        }
        .sheet(isPresented: $showingBackgroundImagePicker) {
            ImagePicker { image in
                uploadBackgroundImage(image)
            }
        }
        .sheet(isPresented: $showEditProfile) {
            if let userProfile = viewModel.userProfile {
                NavigationStack {
                    EditProfileView(userProfile: Binding(
                        get: { userProfile },
                        set: { newProfile in
                            viewModel.userProfile = newProfile
                        }
                    ))
                }
            }
        }
        .fullScreenCover(isPresented: $showingHealthStats) {
            NavigationStack {
                WorkoutAnalysisDetailView()
            }
        }
        // 从右向左的标准 push 动画
        .navigationDestination(isPresented: $showingMemberCenter) {
            MembershipCenterView()
                .asSubView()
        }
        .navigationDestination(isPresented: $showingMyPosts) {
            MyPostsView()
        }
        .navigationDestination(isPresented: $showingMyBookmarks) {
            MyBookmarksView()
        }
        .navigationDestination(isPresented: $showingCreatorCenter) {
            CreatorCenterView()
                .asSubView()
        }
        .navigationDestination(isPresented: $showingActivityCenter) {
            ActivityCenterView()
                .asSubView()
        }
        .navigationDestination(isPresented: $showingWidgetSettings) {
            WidgetSettingsView()
                .asSubView()
        }
        .sheet(isPresented: $showingFeedbackHelp) {
            NavigationStack {
                FeedbackHelpView(navigationPath: .constant(NavigationPath()))
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            if let postId = reportingPostId {
                ReportPostView(postId: postId) { reason, description in
                    Task {
                        // TODO: 实现举报功能
                        print("举报帖子: \(postId), 原因: \(reason), 描述: \(String(describing: description))")
                    }
                }
            }
        }
        .alert("无法关注", isPresented: $viewModel.showBlockedUserAlert) {
            Button("确定", role: .cancel) {
                viewModel.showBlockedUserAlert = false
            }
        } message: {
            Text(viewModel.blockedUserMessage ?? "您已屏蔽该用户，如需关注请先从黑名单中移除")
        }
        .sheet(isPresented: $showingChatDetail) {
            if let userProfile = viewModel.userProfile {
                NavigationView {
                    ChatWithUserView(targetUser: userProfile)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("关闭") {
                                    showingChatDetail = false
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingPostDetail, onDismiss: {
            // Sheet关闭时重置导航路径
            sheetNavigationPath = NavigationPath()
        }) {
            if let postId = selectedPostId {
                NavigationStack(path: $sheetNavigationPath) {
                    PostDetailView(postId: postId, isSheetPresentation: true)
                        .navigationBarHidden(true)
                        .navigationDestination(for: CommunityNavigationDestination.self) { destination in
                            switch destination {
                            case .userProfile(let userId):
                                UserProfileView(userId: userId, isRootView: false)
                                    .navigationBarHidden(true)
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
                                    highlightUserId: highlightUserId,
                                    isSheetPresentation: true
                                )
                                .navigationBarHidden(true)
                            case .shortVideoFeed(let initialPostId, let videoPosts):
                                ShortVideoFeedView(initialPostId: initialPostId, videoPosts: videoPosts)
                                    .environmentObject(GDTAdManager.shared)
                                    .navigationBarHidden(true)
                            case .tagDetail(let tagName):
                                TagDetailView(tagName: tagName)
                                    .navigationBarHidden(true)
                            case .bookCategory:
                                ClassicsCategoryDetailView()
                            case .aiQuestionBank:
                                AIQuestionBankView()
                            case .meritStatistics:
                                GongGuoGeView()
                            case .noteCenter:
                                NoteCenterView()
                            case .reviewPlan:
                                ReviewPlanView()
                            case .sleepManagement:
                                SleepDashboardView()
                            }
                        }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowUserProfileInCommunity"))) { notification in
                    if let userId = notification.userInfo?["userId"] as? String {
                        print("🔍 UserProfileView Sheet: 收到用户详情通知，用户ID: \(userId)")
                        // 在sheet内部的导航栈中导航
                        sheetNavigationPath.append(CommunityNavigationDestination.userProfile(userId))
                    }
                }
            }
        }
        .actionSheet(isPresented: $showMoreOptions) {
            moreOptionsActionSheet
        }
        .fullScreenCover(isPresented: $showingSettings) {
            NavigationView {
                SettingsView()
                    .navigationBarHidden(true)
            }
            .asSubView() // 标记为子页面，隐藏Tab栏
        }
        .alert("确认屏蔽", isPresented: $showBlockConfirmation) {
            Button("取消", role: .cancel) { }
            Button("屏蔽", role: .destructive) {
                Task {
                    await viewModel.blockUser(reason: "用户举报")
                }
            }
        } message: {
            Text("屏蔽后将无法看到该用户的内容，确定要屏蔽吗？")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToActivityCenter"))) { _ in
            // 处理推送通知导航到活动中心
            showingActivityCenter = true
        }
        .overlay(
            // 错误提示 Toast
            VStack {
                Spacer()

                if let errorMessage = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)

                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Button("关闭") {
                            viewModel.errorMessage = nil
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
                }
            }
        )
        .onAppear {
            if viewModel.userProfile?.id != Int(userId) {
                Task {
                    await viewModel.loadUserProfile(userId: userId)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BackgroundImageUpdated"))) { notification in
            if let backgroundImageUrl = notification.userInfo?["backgroundImage"] as? String {
                print("🔔 收到背景图更新通知: \(backgroundImageUrl)")
                // 更新本地用户资料数据
                Task { @MainActor in
                    if var userProfile = viewModel.userProfile {
                        print("📝 更新前背景图: \(userProfile.backgroundImage ?? "无")")
                        userProfile.backgroundImage = backgroundImageUrl
                        viewModel.userProfile = userProfile
                        print("📝 更新后背景图: \(userProfile.backgroundImage ?? "无")")
                        print("📝 viewModel.userProfile 已更新，触发UI刷新")
                    } else {
                        print("❌ viewModel.userProfile 为 nil，无法更新背景图")
                    }
                }
            }
        }
    }

    // MARK: - 快手风格导航栏
    private func kuaishouStyleNavigationBar(safeAreaTop: CGFloat) -> some View {
        HStack {
            // 返回按钮 - 个人中心时隐藏
            if !isPersonalCenter {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }

            Spacer()

            // 搜索按钮
            Button(action: {
                // TODO: 实现搜索功能
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }

            // 更多选项/设置按钮
            Button(action: {
                if isPersonalCenter {
                    showingSettings = true
                } else {
                    showMoreOptions = true
                }
            }) {
                Image(systemName: isPersonalCenter ? "gearshape" : "ellipsis")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, safeAreaTop + 8) // 使用动态安全区域高度 + 8px间距
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.3),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: safeAreaTop + 60) // 动态调整背景高度
        )
    }

    // MARK: - 更多选项菜单
    private var moreOptionsActionSheet: ActionSheet {
        guard let userProfile = viewModel.userProfile else {
            return ActionSheet(title: Text("选项"))
        }

        var buttons: [ActionSheet.Button] = []

        // 如果不是自己
        if userProfile.isMe != true {
            // 屏蔽/取消屏蔽选项
            if userProfile.isBlocked == true {
                buttons.append(.default(Text("取消屏蔽")) {
                    Task {
                        await viewModel.unblockUser()
                    }
                })
            } else {
                buttons.append(.destructive(Text("屏蔽用户")) {
                    showBlockConfirmation = true
                })
            }

            // 举报选项
            buttons.append(.destructive(Text("举报用户")) {
                // TODO: 实现举报功能
            })
        }

        // 分享选项
        buttons.append(.default(Text("分享用户")) {
            // TODO: 实现分享功能
        })

        // 取消按钮
        buttons.append(.cancel())

        return ActionSheet(
            title: Text("更多选项"),
            buttons: buttons
        )
    }

    // MARK: - 新的用户资料视图
    private func kuaishouStyleContentView(_ userProfile: UserProfile) -> some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 滚动监听器 - 确保能正确捕获滚动事件
                    Color.clear
                        .frame(height: 1)
                        .background(
                            GeometryReader { g in
                                let y = g.frame(in: .named("scrollView")).minY
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: y)
                                    .onAppear {
                                        print("📍 滚动监听器初始化，初始Y值: \(y)")
                                    }
                                    .onChange(of: y) { oldValue, newValue in
                                        print("📈 滚动监听器检测到变化: \(oldValue) -> \(newValue)")

                                        // 直接在这里处理动画逻辑，因为 onPreferenceChange 可能没有被触发
                                        DispatchQueue.main.async {
                                            scrollOffset = newValue

                                            // 标题显示逻辑 - 当向上滚动超过一定距离时显示用户名
                                            let titleThreshold: CGFloat = -120
                                            let shouldShowTitle = newValue < titleThreshold

                                            // 导航栏背景和模糊效果的渐变逻辑
                                            let backgroundStartThreshold: CGFloat = -80
                                            let backgroundFullThreshold: CGFloat = -150

                                            let blurStartThreshold: CGFloat = -100
                                            let blurFullThreshold: CGFloat = -180

                                            // 计算导航栏背景透明度
                                            let backgroundProgress = max(0, min(1, (backgroundStartThreshold - newValue) / (backgroundStartThreshold - backgroundFullThreshold)))
                                            let targetNavBarOpacity = backgroundProgress

                                            // 计算毛玻璃效果透明度
                                            let blurProgress = max(0, min(1, (blurStartThreshold - newValue) / (blurStartThreshold - blurFullThreshold)))
                                            let targetNavBarBlur = blurProgress * 0.8

                                            print("📊 计算结果 - 偏移: \(newValue), 背景透明度: \(targetNavBarOpacity), 模糊度: \(targetNavBarBlur), 显示标题: \(shouldShowTitle)")

                                            // 使用流畅的动画更新状态
                                            if showNavTitle != shouldShowTitle {
                                                print("🏷️ 标题状态变化: \(shouldShowTitle)")
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                    showNavTitle = shouldShowTitle
                                                }
                                            }

                                            // 使用更流畅的动画更新透明度
                                            if abs(navBarOpacity - targetNavBarOpacity) > 0.01 || abs(navBarBlur - targetNavBarBlur) > 0.01 {
                                                print("🎨 透明度变化: 背景 \(navBarOpacity) -> \(targetNavBarOpacity), 模糊 \(navBarBlur) -> \(targetNavBarBlur)")
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    navBarOpacity = targetNavBarOpacity
                                                    navBarBlur = targetNavBarBlur
                                                }
                                            }
                                        }
                                    }
                            }
                        )

                    // 新的 Twitter 风格用户资料区域
                    newUserProfileSection(userProfile)

                    // 帖子列表区域
                    userPostsSection(userProfile)
                }
            }
            .ignoresSafeArea(.container, edges: .top) // 让ScrollView忽略顶部安全区域
            .coordinateSpace(name: "scrollView")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                // 添加调试信息
                print("🔄 滚动偏移量变化: \(value)")

                // 使用主线程更新UI状态，确保动画流畅
                DispatchQueue.main.async {
                    scrollOffset = value

                    // 标题显示逻辑 - 当向上滚动超过一定距离时显示用户名
                    let titleThreshold: CGFloat = -120
                    let shouldShowTitle = value < titleThreshold

                    // 导航栏背景和模糊效果的渐变逻辑
                    let backgroundStartThreshold: CGFloat = -80
                    let backgroundFullThreshold: CGFloat = -150

                    let blurStartThreshold: CGFloat = -100
                    let blurFullThreshold: CGFloat = -180

                    // 计算导航栏背景透明度
                    let backgroundProgress = max(0, min(1, (backgroundStartThreshold - value) / (backgroundStartThreshold - backgroundFullThreshold)))
                    let targetNavBarOpacity = backgroundProgress

                    // 计算毛玻璃效果透明度
                    let blurProgress = max(0, min(1, (blurStartThreshold - value) / (blurStartThreshold - blurFullThreshold)))
                    let targetNavBarBlur = blurProgress * 0.8

                    print("📊 计算结果 - 偏移: \(value), 背景透明度: \(targetNavBarOpacity), 模糊度: \(targetNavBarBlur), 显示标题: \(shouldShowTitle)")

                    // 使用流畅的动画更新状态
                    if showNavTitle != shouldShowTitle {
                        print("🏷️ 标题状态变化: \(shouldShowTitle)")
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showNavTitle = shouldShowTitle
                        }
                    }

                    // 使用更流畅的动画更新透明度
                    if abs(navBarOpacity - targetNavBarOpacity) > 0.01 || abs(navBarBlur - targetNavBarBlur) > 0.01 {
                        print("🎨 透明度变化: 背景 \(navBarOpacity) -> \(targetNavBarOpacity), 模糊 \(navBarBlur) -> \(targetNavBarBlur)")
                        withAnimation(.easeInOut(duration: 0.2)) {
                            navBarOpacity = targetNavBarOpacity
                            navBarBlur = targetNavBarBlur
                        }
                    }
                }
            }
            
            // 导航按钮浮动层 - 独立于ScrollView
            VStack {
                GeometryReader { geometry in
                    navigationOverlay(safeAreaTop: geometry.safeAreaInsets.top)
                }
                .frame(height: 188) // 再增加8pt高度以适应更靠下的按钮位置
                Spacer()
            }
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.all, edges: .top)
        .onAppear {
            Task {
                await viewModel.loadUserProfile(userId: userId)
            }
        }
    }

    // MARK: - 新的 Twitter 风格用户资料区域
    private func newUserProfileSection(_ userProfile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with banner - 延伸到安全区域顶部
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    // 背景横幅 - 优先显示用户背景图，否则使用渐变色
                    ZStack {
                        // 默认渐变背景
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.7),
                                        Color.purple.opacity(0.5),
                                        Color.pink.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // 用户背景图（如果存在）
                        if let backgroundImageUrl = userProfile.backgroundImage,
                           !backgroundImageUrl.isEmpty {
                            AsyncImage(url: URL(string: backgroundImageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        VStack {
                                            ProgressView()
                                                .tint(.white)
                                            Text("加载背景图...")
                                                .foregroundColor(.white)
                                                .font(.caption)
                                        }
                                    )
                            }
                            .onAppear {
                                print("🖼️ newUserProfileSection 正在加载背景图: \(backgroundImageUrl)")
                            }
                        } else {
                            // 调试信息：显示背景图状态
                            Rectangle()
                                .fill(Color.clear)
                                .onAppear {
                                    print("🔍 newUserProfileSection 背景图状态检查:")
                                    print("   - userProfile.backgroundImage: \(userProfile.backgroundImage ?? "nil")")
                                    print("   - isEmpty: \(userProfile.backgroundImage?.isEmpty ?? true)")
                                }
                        }
                    }
                    .frame(height: 200 + geometry.safeAreaInsets.top)
                    .offset(y: -geometry.safeAreaInsets.top)
                    .clipped()
                    .ignoresSafeArea(.all, edges: .top) // 确保完全忽略顶部安全区域

                    // Profile image
                    AsyncImage(url: URL(string: userProfile.avatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.white)
                            .overlay(
                                Text(String(userProfile.nickname.prefix(1)))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .offset(x: 16, y: 30)
                }
            }
            .frame(height: 230)
            .clipped() // 确保内容不会溢出
            .ignoresSafeArea(.all, edges: .top) // 确保整个横幅区域忽略顶部安全区域
            
            // User Info - 左对齐布局
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    Text(userProfile.nickname)
                        .font(.title2).bold()
                        .multilineTextAlignment(.leading)
                    
                    if userProfile.safeIsVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer() // 推送内容到左侧
                }
                
                HStack {
                    Text("@\(userProfile.displayUsername)")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)

                    Spacer() // 推送用户ID到左侧，按钮到右侧

                    // 编辑资料按钮放在最右侧
                    if userProfile.safeIsMe {
                        Button("编辑资料") {
                            showEditProfile = true
                        }
                        .frame(width: 90, height: 36)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(18)
                        .font(.system(size: 15, weight: .medium))
                    }
                }
                
                HStack {
                    if let bio = userProfile.bio, !bio.isEmpty {
                        Text(bio)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("这是个人简介")
                            .multilineTextAlignment(.leading)
                    }
                    Spacer() // 推送内容到左侧
                }
                
                HStack(spacing: 16) {
                    Button(action: { showFollowingList = true }) {
                        Text("\(userProfile.followingCount ?? 0) 正在关注").bold()
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showFollowersList = true }) {
                        Text("\(userProfile.followersCount ?? 0) 关注者").bold()
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer() // 推送内容到左侧
                }
                .font(.subheadline)

                // 资料标签区域
                profileTagsSection(userProfile)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // 操作按钮区域
            actionButtonsSection(userProfile)
        }
    }
    
    // MARK: - 动画导航栏覆盖层
    private func navigationOverlay(safeAreaTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            // 导航栏背景
            ZStack {
                // 系统背景色（滚动时出现，自动适配深色/浅色模式）
                Rectangle()
                    .fill(Color(.systemBackground))
                    .opacity(navBarOpacity)
                
                // 导航按钮和标题
                VStack(spacing: 0) {
                    // 状态栏占位
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: safeAreaTop)
                    
                    // 导航内容 - 调整按钮大小和位置
                    HStack {
                        // 左侧按钮组
                        HStack(spacing: 12) {
                            // 返回按钮 - 个人中心时隐藏
                            if !isPersonalCenter {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 16, weight: .medium)) // 减小图标大小
                                        .foregroundColor(navBarOpacity > 0.3 ? .primary : .white)
                                        .frame(width: 32, height: 32) // 减小按钮尺寸
                                        .background(
                                            Circle()
                                                .fill(
                                                    navBarOpacity < 0.5 ?
                                                    Color.black.opacity(0.4) :
                                                    Color.clear
                                                )
                                        )
                                }
                            }

                            // 相机按钮 - 只有当前用户可见
                            if let userProfile = viewModel.userProfile, userProfile.safeIsMe && !isUploadingBackgroundImage {
                                Button(action: {
                                    print("📸 导航栏相机按钮被点击")
                                    showingBackgroundImagePicker = true
                                }) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(navBarOpacity > 0.3 ? .primary : .white)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(
                                                    navBarOpacity < 0.5 ?
                                                    Color.black.opacity(0.4) :
                                                    Color.clear
                                                )
                                        )
                                }
                            }

                            // 上传状态指示器
                            if isUploadingBackgroundImage {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(navBarOpacity > 0.3 ? .primary : .white)
                                    Text("上传中")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(navBarOpacity > 0.3 ? .primary : .white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            navBarOpacity < 0.5 ?
                                            Color.black.opacity(0.4) :
                                            Color.gray.opacity(0.2)
                                        )
                                )
                            }
                        }

                        Spacer()

                        // 标题显示逻辑
                        if isPersonalCenter {
                            // 个人中心显示固定标题
                            Text("我的")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                                .opacity(navBarOpacity)
                        } else if showNavTitle, let userProfile = viewModel.userProfile {
                            // 其他用户页面显示用户名
                            Text(userProfile.nickname)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                                .opacity(navBarOpacity)
                                .transition(
                                    .asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity
                                    )
                                )
                        }

                        Spacer()

                        // 更多选项/设置按钮
                        Button(action: {
                            if isPersonalCenter {
                                showingSettings = true
                            } else {
                                showMoreOptions = true
                            }
                        }) {
                            Image(systemName: isPersonalCenter ? "gearshape" : "ellipsis")
                                .font(.system(size: 16, weight: .medium)) // 减小图标大小
                                .foregroundColor(navBarOpacity > 0.3 ? .primary : .white)
                                .frame(width: 32, height: 32) // 减小按钮尺寸
                                .background(
                                    Circle()
                                        .fill(
                                            navBarOpacity < 0.5 ?
                                            Color.black.opacity(0.4) :
                                            Color.clear
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 46) // 再增加8pt顶部间距，让按钮位置更靠下
                    .frame(height: 108) // 增加导航栏高度，让整体更高
                }
            }
            .frame(height: safeAreaTop + 68) // 增加高度以容纳更多的顶部间距
        }
        .animation(.easeInOut(duration: 0.25), value: navBarOpacity)
        .animation(.easeInOut(duration: 0.25), value: navBarBlur)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showNavTitle)
    }

    // MARK: - 资料标签区域
    private func profileTagsSection(_ userProfile: UserProfile) -> some View {
        let tags = buildProfileTags(userProfile)

        if tags.isEmpty {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                // 使用自定义的流式布局来显示标签
                FlowLayoutView(tags: tags)
            }
            .padding(.top, 12)
        )
    }

    // MARK: - 单行标签布局视图
    private struct FlowLayoutView: View {
        let tags: [String]

        var body: some View {
            // 使用 ScrollView 确保所有标签都在一行显示
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(.darkGray))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .lineLimit(1)
                            .fixedSize()
                    }

                    // 添加一个占位符，确保内容始终左对齐
                    Spacer(minLength: 0)
                        .frame(maxWidth: .infinity)
                }
                .frame(minWidth: UIScreen.main.bounds.width - 32, alignment: .leading)
            }
        }
    }

    // MARK: - 构建资料标签
    private func buildProfileTags(_ userProfile: UserProfile) -> [String] {
        var tags: [String] = []

        let ipLocation = userProfile.ipLocation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let location = userProfile.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // 处理IP归属地 - 只清理字段内部的重复，不与所在地比较
        var cleanedIpLocation = ipLocation
        if !ipLocation.isEmpty {
            // 检查IP归属地本身是否包含重复信息（如"北京北京"、"北京市北京市"等）
            let components = ipLocation.components(separatedBy: CharacterSet(charactersIn: " ，,、"))
            let uniqueComponents = Array(Set(components)).filter { !$0.isEmpty }

            // 如果组件数量明显少于原始组件，说明有重复
            if uniqueComponents.count < components.count && uniqueComponents.count > 0 {
                cleanedIpLocation = uniqueComponents.joined(separator: "")
                print("🔍 检测到IP归属地重复信息，原始: '\(ipLocation)'，清理后: '\(cleanedIpLocation)'")
            }

            tags.append(cleanedIpLocation)
        }

        // 处理所在地 - 独立显示，不与IP归属地比较
        if !location.isEmpty {
            tags.append(location)
        }

        // 性别和年龄
        let genderAge = buildGenderAgeTag(userProfile)
        if !genderAge.isEmpty {
            tags.append(genderAge)
        }

        return tags
    }

    // MARK: - 构建性别年龄标签
    private func buildGenderAgeTag(_ userProfile: UserProfile) -> String {
        var components: [String] = []

        // 性别
        if let gender = userProfile.gender, !gender.isEmpty && gender != "private" {
            let genderText = gender == "male" ? "男" : (gender == "female" ? "女" : "")
            if !genderText.isEmpty {
                components.append(genderText)
            }
        }

        // 年龄
        if let age = calculateAge(from: userProfile.birthday) {
            components.append("\(age)岁")
        }

        return components.joined(separator: " · ")
    }

    // MARK: - 计算年龄
    private func calculateAge(from birthday: String?) -> Int? {
        guard let birthday = birthday, !birthday.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let birthDate = formatter.date(from: birthday) else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)

        return ageComponents.year
    }

    // MARK: - 操作按钮区域
    private func actionButtonsSection(_ userProfile: UserProfile) -> some View {
        HStack(spacing: 12) {
            if !userProfile.safeIsMe {
                // 根据屏蔽状态显示不同的按钮
                if userProfile.safeIsBlocked {
                    // 显示"移出黑名单"按钮
                    Button("移出黑名单") {
                        Task {
                            await viewModel.unblockUser()
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(.systemGray5))
                    .foregroundColor(.red)
                    .cornerRadius(22)
                } else {
                    // 关注按钮
                    Button(userProfile.safeIsFollowing ? "已关注" : "关注") {
                        Task {
                            if userProfile.safeIsFollowing {
                                await viewModel.unfollowUser()
                            } else {
                                await viewModel.followUser()
                            }
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(userProfile.safeIsFollowing ? Color(.systemGray5) : ModernDesignSystem.Colors.primaryGreen)
                    .foregroundColor(userProfile.safeIsFollowing ? .primary : .white)
                    .cornerRadius(22)
                }

                // 发私信按钮
                Button(action: {
                    startChatWithUser()
                }) {
                    Text("发私信")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(22)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }

    // MARK: - 用户帖子列表区域（改为竖向菜单列表）
    private func userPostsSection(_ userProfile: UserProfile) -> some View {
        VStack(spacing: 0) {
            if userProfile.safeIsMe {
                // 当前用户：显示竖向菜单列表
                verticalMenuList(userProfile: userProfile)
            } else {
                // 其他用户：显示帖子列表
                currentPostsContentView
                    .padding(.top, 16)
            }
        }
    }

    // MARK: - 竖向菜单列表
    private func verticalMenuList(userProfile: UserProfile, screenHeight: CGFloat = UIScreen.main.bounds.height) -> some View {
        VStack(spacing: 0) {
            // 我的作品
            modernMenuCard(
                icon: "doc.text.fill",
                title: "我的作品",
                subtitle: "查看我的所有创作",
                count: userProfile.postsCount ?? 0,
                gradientColors: [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.4, green: 0.7, blue: 1.0)],
                iconBackgroundColors: [Color(red: 0.3, green: 0.65, blue: 1.0), Color(red: 0.5, green: 0.75, blue: 1.0)],
                action: {
                    showingMyPosts = true
                }
            )

            // 我的收藏
            modernMenuCard(
                icon: "bookmark.fill",
                title: "我的收藏",
                subtitle: "我收藏的精彩内容",
                count: nil,
                gradientColors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.7, blue: 0.3)],
                iconBackgroundColors: [Color(red: 1.0, green: 0.65, blue: 0.25), Color(red: 1.0, green: 0.75, blue: 0.35)],
                action: {
                    showingMyBookmarks = true
                }
            )

            // 会员中心
            modernMenuCard(
                icon: "crown.fill",
                title: "会员中心",
                subtitle: "专属特权与服务",
                count: nil,
                gradientColors: [Color(red: 1.0, green: 0.8, blue: 0.2), Color(red: 1.0, green: 0.85, blue: 0.4)],
                iconBackgroundColors: [Color(red: 1.0, green: 0.82, blue: 0.3), Color(red: 1.0, green: 0.87, blue: 0.5)],
                action: {
                    showingMemberCenter = true
                }
            )

            // 创作者中心
            modernMenuCard(
                icon: "pencil.and.list.clipboard",
                title: "创作者中心",
                subtitle: "数据分析与创作工具",
                count: nil,
                gradientColors: [Color(red: 0.6, green: 0.4, blue: 1.0), Color(red: 0.7, green: 0.5, blue: 1.0)],
                iconBackgroundColors: [Color(red: 0.65, green: 0.45, blue: 1.0), Color(red: 0.75, green: 0.55, blue: 1.0)],
                action: {
                    showingCreatorCenter = true
                }
            )

            // 桌面组件
            modernMenuCard(
                icon: "square.grid.2x2.fill",
                title: "桌面组件",
                subtitle: "个性化桌面小组件",
                count: nil,
                gradientColors: [Color(red: 0.2, green: 0.8, blue: 0.6), Color(red: 0.3, green: 0.9, blue: 0.7)],
                iconBackgroundColors: [Color(red: 0.25, green: 0.85, blue: 0.65), Color(red: 0.35, green: 0.95, blue: 0.75)],
                action: {
                    showingWidgetSettings = true
                }
            )

            // 帮助与反馈
            modernMenuCard(
                icon: "questionmark.circle.fill",
                title: "帮助与反馈",
                subtitle: "常见问题与意见反馈",
                count: nil,
                gradientColors: [Color(red: 1.0, green: 0.4, blue: 0.6), Color(red: 1.0, green: 0.5, blue: 0.7)],
                iconBackgroundColors: [Color(red: 1.0, green: 0.45, blue: 0.65), Color(red: 1.0, green: 0.55, blue: 0.75)],
                action: {
                    showingFeedbackHelp = true
                }
            )

            // 添加底部占位空间，确保在 iPad 上所有内容都可见和可滚动
            Spacer()
                .frame(minHeight: max(screenHeight * 0.5, 300))
        }
        .padding(.top, 12)
        .frame(minHeight: max(screenHeight, 600))
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 现代化菜单卡片
    private func modernMenuCard(
        icon: String,
        title: String,
        subtitle: String,
        count: Int?,
        gradientColors: [Color],
        iconBackgroundColors: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标容器
                ZStack {
                    // 图标背景渐变
                    LinearGradient(
                        colors: iconBackgroundColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 56, height: 56)
                    .cornerRadius(16)

                    // 图标
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }

                // 文字内容
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        Spacer()

                        // 数量徽章
                        if let count = count, count > 0 {
                            Text("\(count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(
                                        colors: gradientColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                    }

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .fill(Color(.separator).opacity(0.3))
                    .frame(height: 0.5),
                alignment: .bottom
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 当前帖子内容视图
    private var currentPostsContentView: some View {
        VStack(spacing: 0) {
            if viewModel.isLoadingPosts && viewModel.userPosts.isEmpty {
                // 首次加载状态
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("加载帖子中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else if viewModel.userPosts.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("暂无帖子")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("该用户还没有发布任何帖子")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else {
                // 帖子列表 - 瀑布流布局
                WaterfallLayout(
                    items: viewModel.userPosts,
                    columns: 2,
                    spacing: 4,
                    horizontalPadding: 4,
                    onLoadMore: {
                        if viewModel.hasMorePosts && !viewModel.isLoadingPosts {
                            Task {
                                print("🔄 触发分页加载，当前页: \(viewModel.postsCurrentPage)")
                                await viewModel.loadMorePosts()
                            }
                        }
                    }
                ) { post in
                    WaterfallPostCard(
                        post: post,
                        onTap: {
                            print("🔍 UserProfileView: 导航到帖子详情，帖子ID: \(post.id)")
                            selectedPostId = post.id
                            showingPostDetail = true
                        },
                        onLike: {
                            Task {
                                await toggleLikePost(post.id)
                            }
                        },
                        onUserTap: {
                            // 在用户详情页面，不需要跳转到自己
                        }
                    )
                }
                .frame(minHeight: 600)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // 首次加载帖子
            if viewModel.userPosts.isEmpty {
                Task {
                    await viewModel.loadUserPosts(userId: userId, refresh: true)
                }
            }
        }
    }

    // MARK: - 当前收藏内容视图
    private var currentBookmarksContentView: some View {
        LazyVStack(spacing: 0) {
            // 检查是否为当前用户本人
            if viewModel.userProfile?.isMe != true {
                VStack(spacing: 16) {
                    Image(systemName: "lock")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("私密内容")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("只有本人才能查看收藏内容")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else if viewModel.isLoadingBookmarks && viewModel.bookmarkedPosts.isEmpty {
                // 首次加载状态
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("加载收藏中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else if viewModel.bookmarkedPosts.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("暂无收藏")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("你还没有收藏任何帖子")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else {
                // 收藏列表
                ForEach(viewModel.bookmarkedPosts) { post in
                    PostCardView(
                        post: post,
                        showHotBadge: false,
                        showEditButton: false,
                        onLike: {
                            Task {
                                await toggleLikeBookmarkedPost(post.id)
                            }
                        },
                        onBookmark: {
                            Task {
                                await toggleBookmarkBookmarkedPost(post.id)
                            }
                        },
                        onShare: {
                            Task {
                                await shareBookmarkedPost(post.id)
                            }
                        },
                        onReport: {
                            reportingPostId = post.id
                            showingReportSheet = true
                        },
                        onNavigateToDetail: { postId in
                            print("🔍 UserProfileView: 导航到帖子详情，帖子ID: \(postId)")
                            selectedPostId = postId
                            showingPostDetail = true
                        },
                        onNavigateToUserProfile: { author in
                            // 可以跳转到作者的用户详情页面
                        }
                    )
                    .onAppear {
                        // 当滚动到倒数第3个收藏帖子时，加载更多
                        if post.id == viewModel.bookmarkedPosts.suffix(3).first?.id &&
                           viewModel.hasMoreBookmarks &&
                           !viewModel.isLoadingBookmarks {
                            Task {
                                print("🔄 触发收藏分页加载，当前页: \(viewModel.bookmarksCurrentPage)")
                                await viewModel.loadMoreBookmarks()
                            }
                        }
                    }
                }

                // 加载更多指示器
                if viewModel.isLoadingBookmarks && !viewModel.bookmarkedPosts.isEmpty {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("加载更多...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 50)
                    .padding(.vertical, 10)
                } else if !viewModel.hasMoreBookmarks && !viewModel.bookmarkedPosts.isEmpty {
                    Text("没有更多收藏了")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(height: 50)
                        .padding(.vertical, 10)
                }
            }
        }
        .onAppear {
            // 首次加载收藏（仅当为本人时）
            if viewModel.userProfile?.isMe == true && viewModel.bookmarkedPosts.isEmpty {
                Task {
                    await viewModel.loadUserBookmarks(refresh: true)
                }
            }
        }
    }

    // MARK: - 简化的导航栏区域
    private var simplifiedNavigationArea: some View {
        HStack {
            // 返回按钮 - 个人中心时隐藏
            if !isPersonalCenter {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
            }

            Spacer()

            // 页面标题
            Text(isPersonalCenter ? "我的" : "图文列表")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // 更多选项/设置按钮
            Button(action: {
                if isPersonalCenter {
                    showingSettings = true
                } else {
                    showMoreOptions = true
                }
            }) {
                Image(systemName: isPersonalCenter ? "gearshape" : "ellipsis")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - Twitter风格头部区域
    private func twitterStyleHeaderView(_ userProfile: UserProfile) -> some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(Color.blue)
                .frame(height: 150)
            
            // Profile image
            AsyncImage(url: URL(string: userProfile.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.white)
                    .overlay(
                        Text(String(userProfile.nickname.prefix(1)))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
            .offset(x: 16, y: 40)
        }
        .frame(height: 180)
    }

    // MARK: - Twitter风格用户信息区域
    private func twitterStyleUserInfoView(_ userProfile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(userProfile.nickname)
                    .font(.title2).bold()
                
                if userProfile.safeIsVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                }
            }
            
            Text("@\(userProfile.displayUsername)")
                .foregroundColor(.gray)
            
            if let bio = userProfile.bio, !bio.isEmpty {
                Text(bio)
            } else {
                Text("这是个人简介")
            }
            

        }
        .padding(.horizontal)
        .padding(.top, 40)
    }

    // MARK: - Twitter风格统计数据区域
    private func twitterStyleStatsView(_ userProfile: UserProfile) -> some View {
        HStack(spacing: 16) {
            Button(action: { showFollowingList = true }) {
                Text("\(userProfile.followingCount ?? 0) 正在关注").bold()
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { showFollowersList = true }) {
                Text("\(userProfile.followersCount ?? 0) 关注者").bold()
            }
            .buttonStyle(PlainButtonStyle())
        }
        .font(.subheadline)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Twitter风格操作按钮区域
    private func twitterStyleActionButtonsView(_ userProfile: UserProfile) -> some View {
        HStack(spacing: 12) {
            if userProfile.safeIsMe {
                // 编辑资料按钮
                Button("编辑资料") {
                    showEditProfile = true
                }
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(22)
            } else {
                // 根据屏蔽状态显示不同的按钮
                if userProfile.safeIsBlocked {
                    // 显示"移出黑名单"按钮
                    Button("移出黑名单") {
                        Task {
                            await viewModel.unblockUser()
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(.systemGray5))
                    .foregroundColor(.red)
                    .cornerRadius(22)
                } else {
                    // 关注按钮
                    Button(userProfile.safeIsFollowing ? "已关注" : "关注") {
                        Task {
                            if userProfile.safeIsFollowing {
                                await viewModel.unfollowUser()
                            } else {
                                await viewModel.followUser()
                            }
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(userProfile.safeIsFollowing ? Color(.systemGray5) : ModernDesignSystem.Colors.primaryGreen)
                    .foregroundColor(userProfile.safeIsFollowing ? .primary : .white)
                    .cornerRadius(22)
                }

                // 发私信按钮
                Button(action: {
                    startChatWithUser()
                }) {
                    Text("发私信")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(22)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }





    // MARK: - Twitter风格内容展示区域
    private func kuaishouStyleContentSection(_ userProfile: UserProfile) -> some View {
        VStack(spacing: 0) {
            // Twitter风格的标签栏
            HStack(spacing: 0) {
                Button(action: {
                    selectedTab = .posts
                }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("帖子")
                                .font(.system(size: 16, weight: selectedTab == .posts ? .semibold : .medium))
                                .foregroundColor(selectedTab == .posts ? .primary : .secondary)

                            Text("(\(userProfile.postsCount ?? 0))")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Rectangle()
                            .fill(selectedTab == .posts ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)

                Button(action: {
                    selectedTab = .bookmarks
                }) {
                    VStack(spacing: 8) {
                        Text("收藏")
                            .font(.system(size: 16, weight: selectedTab == .bookmarks ? .semibold : .medium))
                            .foregroundColor(selectedTab == .bookmarks ? .primary : .secondary)

                        Rectangle()
                            .fill(selectedTab == .bookmarks ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // 内容列表（保持原有的内容列表模块不变）
            ProfileContentModule(
                selectedTab: selectedTab,
                userProfile: userProfile,
                viewModel: viewModel,
                minHeight: 400
            )
        }
    }



    // MARK: - 开始聊天功能
    private func startChatWithUser() {
        guard viewModel.userProfile != nil else { return }

        // 直接打开半屏聊天窗口
        showingChatDetail = true
    }



    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(ModernDesignSystem.Colors.primaryGreen)
            Text("加载中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - 错误视图
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("加载失败")
                .font(.headline)
                .fontWeight(.semibold)

            Text(viewModel.errorMessage ?? "请检查网络连接后重试")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("重试") {
                Task {
                    await viewModel.loadUserProfile(userId: userId)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(ModernDesignSystem.Colors.primaryGreen)
            .foregroundColor(.white)
            .cornerRadius(25)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - 简单内容视图
    private func simpleContentView(_ userProfile: UserProfile) -> some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top

            ZStack {
                // 主要滚动内容
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // 滚动监听器
                            Color.clear
                                .frame(height: 1)
                                .background(
                                    GeometryReader { g in
                                        let y = g.frame(in: .global).minY
                                        Color.clear
                                            .preference(key: ScrollOffsetPreferenceKey.self, value: y)
                                    }
                                )

                            // 大 Header 区域 - 高度约 250
                            largeHeaderView(userProfile, safeAreaTop: safeAreaTop)

                            // 吸顶的 Segment 控件
                            stickySegmentView
                                .background(
                                    GeometryReader { segmentGeometry in
                                        Color.clear
                                            .preference(key: TabBarOffsetPreferenceKey.self,
                                                      value: segmentGeometry.frame(in: .named("scrollView")).minY)
                                    }
                                )

                            // 内容区域
                            profileContentSection
                                .padding(.top, 20)
                        }
                    }
                    .ignoresSafeArea(.container, edges: .top) // 让ScrollView忽略顶部安全区域
                    .coordinateSpace(name: "scrollView")

                }

                // 固定的吸顶 Segment 控件
                VStack(spacing: 0) {
                    // 导航栏占位空间
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: safeAreaTop + 54)

                    // 固定的 Segment 控件
                    if shouldShowStickySegment() {
                        stickySegmentView
                            .background(
                                ZStack {
                                    Color(.systemBackground)
                                    Rectangle()
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.9)
                                }
                            )
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.25), value: shouldShowStickySegment())
                    }

                    Spacer()
                }
                .allowsHitTesting(shouldShowStickySegment())
            }
        }
        .onAppear {
            Task {
                await viewModel.loadUserProfile(userId: userId)

                // 添加简单的调试信息来确保页面正确加载
                print("🚀 UserProfileView 页面已加载，用户ID: \(userId)")
                print("📊 当前用户资料状态: \(viewModel.userProfile?.nickname ?? "未加载")")

                // 添加 kuaishouStyleContentView 调试信息
                if let userProfile = viewModel.userProfile {
                    print("🎯 kuaishouStyleContentView 被调用")
                    print("🔍 用户资料: \(userProfile.nickname)")
                    print("🔍 背景图URL: \(userProfile.backgroundImage ?? "无背景图")")
                }
            }
        }

    }

    // MARK: - 旧的主要内容视图（待删除）
    private func mainContentView(_ userProfile: UserProfile, geometry: GeometryProxy) -> some View {
        let safeAreaTop = geometry.safeAreaInsets.top
        let navBarHeight: CGFloat = 44
        let totalNavHeight = safeAreaTop + navBarHeight

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 顶部占位空间 - 为导航栏留出空间
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: totalNavHeight)

                    // 滚动监听器
                    GeometryReader { scrollGeometry in
                        let offset = scrollGeometry.frame(in: .named("scrollView")).minY - totalNavHeight
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: offset)
                    }
                    .frame(height: 0)

                    // 横幅和头像模块
                    ProfileHeaderModule(
                        userProfile: userProfile,
                        scrollOffset: scrollOffset,
                        onAvatarOffsetChange: { offset in
                            // 头像偏移处理已简化
                        }
                    )

                    // 用户信息模块
                    ProfileInfoModule(
                        userProfile: userProfile,
                        viewModel: viewModel,
                        scrollOffset: scrollOffset
                    )

                    // 统计数据模块
                    ProfileStatsModule(
                        userProfile: userProfile,
                        showFollowersList: $showFollowersList,
                        showFollowingList: $showFollowingList,
                        scrollOffset: scrollOffset
                    )

                    // 标签页导航模块
                    ProfileTabsModule(
                        selectedTab: $selectedTab,
                        userProfile: userProfile,
                        scrollOffset: scrollOffset
                    )
                    .background(
                        GeometryReader { tabGeometry in
                            Color.clear
                                .preference(key: TabBarOffsetPreferenceKey.self,
                                          value: tabGeometry.frame(in: .named("scrollView")).minY - totalNavHeight)
                        }
                    )

                    // 内容展示模块
                    ProfileContentModule(
                        selectedTab: selectedTab,
                        userProfile: userProfile,
                        viewModel: viewModel,
                        minHeight: max(geometry.size.height - totalNavHeight - 400, 300)
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .coordinateSpace(name: "scrollView")


            // 固定标签栏 - 当滚动到指定位置时显示在导航栏下方
            VStack(spacing: 0) {
                // 导航栏占位空间
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: safeAreaTop + navBarHeight)

                // 固定标签栏模块
                if shouldShowStickyTabBar() {
                    StickyProfileTabsModule(
                        selectedTab: $selectedTab,
                        userProfile: userProfile,
                        isVisible: shouldShowStickyTabBar()
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.25), value: shouldShowStickyTabBar())
                }

                Spacer()
            }
            .allowsHitTesting(shouldShowStickyTabBar())
        }



    }

    // MARK: - 计算最小内容高度
    private func calculateMinContentHeight(geometry: GeometryProxy) -> CGFloat {
        // 计算已使用的高度
        let bannerHeight: CGFloat = 200 // 横幅高度
        let userInfoHeight: CGFloat = 200 // 用户信息区域估计高度
        let tabBarHeight: CGFloat = 50 // 标签栏高度

        let usedHeight = bannerHeight + userInfoHeight + tabBarHeight
        let availableHeight = geometry.size.height

        // 确保内容区域至少填充剩余的屏幕空间
        let minContentHeight = max(availableHeight - usedHeight, geometry.size.height * 0.6)
        return minContentHeight
    }

    // MARK: - 用户资料头部区域
    private func profileHeaderSection(_ userProfile: UserProfile) -> some View {
        VStack(spacing: 0) {
            // 横幅图片
            bannerImageView

            // 用户信息区域
            userInfoSection(userProfile)
        }
    }

    // MARK: - 大 Header 视图
    private func largeHeaderView(_ userProfile: UserProfile, safeAreaTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            // 横幅背景区域
            ZStack(alignment: .bottomLeading) {
                // 背景渐变 - 直接延伸到屏幕顶部
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.7),
                                Color.purple.opacity(0.5),
                                Color.pink.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200 + safeAreaTop)
                    .offset(y: -safeAreaTop) // 向上偏移到屏幕顶部
                    .clipped()

                // 用户背景图片
                if let backgroundImageUrl = userProfile.backgroundImage,
                   !backgroundImageUrl.isEmpty {
                    AsyncImage(url: URL(string: backgroundImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                VStack {
                                    ProgressView()
                                        .tint(.white)
                                    Text("加载背景图...")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            )
                    }
                    .frame(height: 200 + safeAreaTop)
                    .offset(y: -safeAreaTop)
                    .clipped()
                    .onAppear {
                        print("🎯 modernHeaderView 检测到背景图URL: \(backgroundImageUrl)")
                        print("🖼️ modernHeaderView 正在加载背景图: \(backgroundImageUrl)")
                    }
                } else {
                    // 调试信息：显示背景图状态
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 200 + safeAreaTop)
                        .offset(y: -safeAreaTop)
                        .onAppear {
                            print("🔍 modernHeaderView 背景图状态检查:")
                            print("   - userProfile.backgroundImage: \(userProfile.backgroundImage ?? "nil")")
                            print("   - isEmpty: \(userProfile.backgroundImage?.isEmpty ?? true)")
                        }
                }

                // 上传状态覆盖层
                if isUploadingBackgroundImage {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .frame(height: 200 + safeAreaTop)
                        .offset(y: -safeAreaTop)
                        .overlay(
                            VStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("上传中...")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                            .offset(y: safeAreaTop / 2)
                        )
                        .clipped()
                }

                // 点击提示（仅当前用户可见）
                if userProfile.safeIsMe && !isUploadingBackgroundImage {
                    VStack {
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                Text("点击更换背景")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.6))
                            )
                            .padding(.trailing, 16)
                            .padding(.top, safeAreaTop + 16)
                        }
                        Spacer()
                    }
                    .frame(height: 200 + safeAreaTop)
                    .offset(y: -safeAreaTop)
                    .clipped()
                }

                // 头像区域 - 位于横幅底部
                HStack {
                    // 头像
                    AsyncImage(url: URL(string: userProfile.avatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray)
                            .overlay(
                                Text(String(userProfile.nickname.prefix(1)))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: calculateAvatarSize(), height: calculateAvatarSize())
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .scaleEffect(calculateAvatarScale())
                    .animation(.easeInOut(duration: 0.25), value: scrollOffset)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // 只有当前用户可以更换背景图
                if userProfile.safeIsMe && !isUploadingBackgroundImage {
                    showingBackgroundImagePicker = true
                }
            }

            // 用户信息区域
            VStack(alignment: .leading, spacing: 16) {
                // 用户名和操作按钮行
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 8) {
                        // 用户名
                        HStack {
                            Text(userProfile.nickname)
                                .font(.title2)
                                .fontWeight(.bold)

                            if userProfile.safeIsVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                            }
                        }

                        Text("@\(userProfile.displayUsername)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // 操作按钮组
                    actionButtonsGroup(userProfile)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // 简介和统计数据
                VStack(alignment: .leading, spacing: 12) {
                    if let bio = userProfile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.body)
                            .padding(.horizontal, 16)
                    }

                    // 统计数据（帖子、关注、粉丝）
                    HStack(spacing: 20) {
                        // 帖子数量
                        HStack(spacing: 4) {
                            Text("\(userProfile.postsCount ?? 0)")
                                .fontWeight(.bold)
                            Text("帖子")
                                .foregroundColor(.secondary)
                        }

                        Button(action: { showFollowingList = true }) {
                            HStack(spacing: 4) {
                                Text("\(userProfile.followingCount ?? 0)")
                                    .fontWeight(.bold)
                                Text("正在关注")
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button(action: { showFollowersList = true }) {
                            HStack(spacing: 4) {
                                Text("\(userProfile.followersCount ?? 0)")
                                    .fontWeight(.bold)
                                Text("关注者")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    // MARK: - 横幅图片
    private var bannerImageView: some View {
        GeometryReader { geometry in
            // 简化的视差效果：禁止下拉时背景图被拉伸；仅在向上滑动时提供轻微视差
            let parallaxOffset = max(-scrollOffset * 0.3, 0) // scrollOffset<0 时生效；下拉(>0)为0
            let scaleEffect: CGFloat = 1 // 关闭缩放，避免下拉时出现放大效果

            ZStack {
                // 背景渐变
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.7),
                                Color.purple.opacity(0.5),
                                Color.pink.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .onAppear {
                        print("🎨 紫色渐变背景已显示")
                        if let userProfile = viewModel.userProfile {
                            print("🎨 当前用户资料存在，背景图: \(userProfile.backgroundImage ?? "nil")")
                        } else {
                            print("🎨 当前用户资料为 nil")
                        }
                    }

                // 用户背景图片
                if let userProfile = viewModel.userProfile,
                   let backgroundImageUrl = userProfile.backgroundImage,
                   !backgroundImageUrl.isEmpty {
                    AsyncImage(url: URL(string: backgroundImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .scaleEffect(scaleEffect)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                VStack {
                                    ProgressView()
                                        .tint(.white)
                                    Text("加载背景图...")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            )
                    }
                    .onAppear {
                        print("🖼️ parallaxHeaderView 正在加载背景图: \(backgroundImageUrl)")
                    }
                } else {
                    // 调试信息：显示背景图状态
                    Rectangle()
                        .fill(Color.clear)
                        .onAppear {
                            print("🔍 parallaxHeaderView 背景图状态检查:")
                            if let userProfile = viewModel.userProfile {
                                print("   - userProfile.backgroundImage: \(userProfile.backgroundImage ?? "nil")")
                                print("   - isEmpty: \(userProfile.backgroundImage?.isEmpty ?? true)")
                            } else {
                                print("   - viewModel.userProfile 为 nil")
                            }
                        }
                }

                // 上传状态覆盖层
                if isUploadingBackgroundImage {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            VStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("上传中...")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        )
                }

                // 点击提示（仅当前用户可见）
                if let userProfile = viewModel.userProfile,
                   userProfile.safeIsMe && !isUploadingBackgroundImage {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                Text("点击更换背景")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.6))
                            )
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .scaleEffect(scaleEffect)
            .frame(width: geometry.size.width, height: 200 + parallaxOffset)
            .offset(y: -parallaxOffset)
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture {
                // 只有当前用户可以更换背景图
                if let userProfile = viewModel.userProfile,
                   userProfile.safeIsMe && !isUploadingBackgroundImage {
                    showingBackgroundImagePicker = true
                }
            }
        }
        .frame(height: 200)
    }

    // MARK: - 简单用户信息区域
    private func simpleUserInfoSection(_ userProfile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 头像区域 - 向上移动
            HStack {
                // 头像
                AsyncImage(url: URL(string: userProfile.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray)
                        .overlay(
                            Text(String(userProfile.nickname.prefix(1)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .background(
                    GeometryReader { avatarGeometry in
                        Color.clear
                            .preference(key: AvatarOffsetPreferenceKey.self,
                                      value: avatarGeometry.frame(in: .named("scrollView")).minY)
                            .onAppear {
                                let offset = avatarGeometry.frame(in: .named("scrollView")).minY
                                print("🎯 头像监听器初始化，初始偏移量: \(offset)")
                            }
                    }
                )

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, -10) // 向上移动头像

            // 用户名和操作按钮行 - 与用户名对齐
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    // 用户名
                    HStack {
                        Text(userProfile.nickname)
                            .font(.title2)
                            .fontWeight(.bold)

                        if userProfile.safeIsVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                        }
                    }

                    // 用户ID和编辑资料按钮
                    HStack(spacing: 8) {
                        Text("@\(userProfile.displayUsername)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // 编辑资料按钮放在ID右边
                        if userProfile.safeIsMe {
                            Button("编辑资料") {
                                showEditProfile = true
                            }
                            .frame(width: 70, height: 24)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .font(.system(size: 12, weight: .medium))
                        }
                    }
                }

                Spacer()

                // 其他操作按钮组（如果需要）
                if userProfile.safeIsMe {
                    // 可以在这里添加其他按钮，比如设置按钮等
                    EmptyView()
                } else {
                    HStack(spacing: 8) {
                        // 根据屏蔽状态显示不同的按钮
                        if userProfile.safeIsBlocked {
                            // 显示"移出黑名单"按钮
                            Button("移出黑名单") {
                                Task {
                                    await viewModel.unblockUser()
                                }
                            }
                            .frame(height: 32)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .foregroundColor(.red)
                            .cornerRadius(16)
                            .font(.system(size: 14, weight: .medium))
                        } else {
                            // 关注按钮
                            Button(userProfile.safeIsFollowing ? "已关注" : "关注") {
                                Task {
                                    if userProfile.safeIsFollowing {
                                        await viewModel.unfollowUser()
                                    } else {
                                        await viewModel.followUser()
                                    }
                                }
                            }
                            .frame(width: 80, height: 32)
                            .background(userProfile.safeIsFollowing ? Color(.systemGray6) : ModernDesignSystem.Colors.primaryGreen)
                            .foregroundColor(userProfile.safeIsFollowing ? .primary : .white)
                            .cornerRadius(16)
                            .font(.system(size: 14, weight: .medium))
                        }

                        // 聊天按钮
                        Button(action: {
                            startChatWithUser()
                        }) {
                            Image(systemName: "message")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 16)

            // 简介和统计数据
            VStack(alignment: .leading, spacing: 8) {
                if let bio = userProfile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .padding(.top, 4)
                }

                // 统计数据（帖子、关注、粉丝）
                HStack(spacing: 20) {
                    // 帖子数量
                    HStack(spacing: 4) {
                        Text("\(userProfile.postsCount ?? 0)")
                            .fontWeight(.bold)
                        Text("帖子")
                            .foregroundColor(.secondary)
                    }

                    Button(action: { showFollowingList = true }) {
                        HStack(spacing: 4) {
                            Text("\(userProfile.followingCount ?? 0)")
                                .fontWeight(.bold)
                            Text("正在关注")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: { showFollowersList = true }) {
                        HStack(spacing: 4) {
                            Text("\(userProfile.followersCount ?? 0)")
                                .fontWeight(.bold)
                            Text("关注者")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 8) // 减少顶部间距
    }

    // MARK: - 操作按钮组
    private func actionButtonsGroup(_ userProfile: UserProfile) -> some View {
        Group {
            if userProfile.safeIsMe {
                Button("编辑资料") {
                    showEditProfile = true
                }
                .font(.system(size: 14, weight: .medium))
                .frame(width: 100, height: 32)
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(16)
            } else {
                HStack(spacing: 8) {
                // 根据屏蔽状态显示不同的按钮
                if userProfile.safeIsBlocked {
                    // 显示"移出黑名单"按钮
                    Button("移出黑名单") {
                        Task {
                            await viewModel.unblockUser()
                        }
                    }
                    .frame(height: 32)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .foregroundColor(.red)
                    .cornerRadius(16)
                    .font(.system(size: 14, weight: .medium))
                } else {
                    // 关注按钮
                    Button(userProfile.safeIsFollowing ? "已关注" : "关注") {
                        Task {
                            if userProfile.safeIsFollowing {
                                await viewModel.unfollowUser()
                            } else {
                                await viewModel.followUser()
                            }
                        }
                    }
                    .frame(width: 80, height: 32)
                    .background(userProfile.safeIsFollowing ? Color(.systemGray6) : ModernDesignSystem.Colors.primaryGreen)
                    .foregroundColor(userProfile.safeIsFollowing ? .primary : .white)
                    .cornerRadius(16)
                    .font(.system(size: 14, weight: .medium))
                }

                // 聊天按钮
                Button(action: {
                    startChatWithUser()
                }) {
                    Image(systemName: "message")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .frame(width: 32, height: 32)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
        }
        }
    }

    // MARK: - 吸顶 Segment 控件
    private var stickySegmentView: some View {
        HStack {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)

                            // 显示数量
                            if tab == .posts, let userProfile = viewModel.userProfile {
                                Text("(\(userProfile.postsCount ?? 0))")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Rectangle()
                            .fill(selectedTab == tab ? ModernDesignSystem.Colors.primaryGreen : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - 用户信息区域（旧版本）
    private func userInfoSection(_ userProfile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 头像行
            HStack {
                // 头像
                profileAvatarView(userProfile)

                Spacer()
            }
            .padding(.top, -40) // 让头像部分覆盖横幅

            // 用户名和操作按钮行
            HStack(alignment: .center) {
                // 用户名和认证信息
                userNameSection(userProfile)

                Spacer()

                // 操作按钮
                actionButtonsView(userProfile, viewModel: viewModel)
            }

            // 个人简介
            if let bio = userProfile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
            }



            // 统计数据
            userStatsSection(userProfile)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .background(Color(.systemBackground))
    }

    // MARK: - 头像视图
    private func profileAvatarView(_ userProfile: UserProfile) -> some View {
        let avatarScale = calculateAvatarScale()

        return AvatarWithMemberBadge(
            avatarUrl: userProfile.avatar,
            isMember: userProfile.isMember ?? false,
            size: 80,
            cornerRadius: 40  // 圆形头像
        )
        .overlay(
            Circle()
                .stroke(Color(.systemBackground), lineWidth: 4)
        )
        .scaleEffect(avatarScale)
    }

    // MARK: - 计算头像大小
    private func calculateAvatarSize() -> CGFloat {
        let baseSize: CGFloat = 80
        let minSize: CGFloat = 60

        if scrollOffset >= 0 {
            return baseSize
        }

        let threshold: CGFloat = -150
        let progress = min(max(-scrollOffset / (-threshold), 0), 1)
        return baseSize - (progress * (baseSize - minSize))
    }

    // MARK: - 计算头像缩放
    private func calculateAvatarScale() -> CGFloat {
        let threshold: CGFloat = -150
        let minScale: CGFloat = 0.7

        if scrollOffset >= 0 {
            return 1.0
        }

        let progress = min(max(-scrollOffset / (-threshold), 0), 1)
        return 1 - (progress * (1 - minScale))
    }

    // MARK: - 判断是否显示吸顶 Segment
    private func shouldShowStickySegment() -> Bool {
        // 当滚动超过大 Header 区域时显示吸顶 Segment
        let stickyThreshold: CGFloat = -200 // 大约是 Header 的高度
        return scrollOffset <= stickyThreshold
    }



    // MARK: - 用户名区域
    private func userNameSection(_ userProfile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(userProfile.nickname)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if userProfile.isVerified == true {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
            }

            Text("@\(userProfile.displayUsername)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 统计数据区域
    private func userStatsSection(_ userProfile: UserProfile) -> some View {
        HStack(alignment: .top, spacing: 20) {
            // 正在关注
            Button(action: {
                showFollowingList = true
            }) {
                statItem(
                    count: userProfile.followingCount ?? 0,
                    label: "正在关注"
                )
            }
            .buttonStyle(PlainButtonStyle())

            // 关注者
            Button(action: {
                showFollowersList = true
            }) {
                statItem(
                    count: userProfile.followersCount ?? 0,
                    label: "关注者"
                )
            }
            .buttonStyle(PlainButtonStyle())

            // 帖子数（不可点击）
            if let postsCount = userProfile.postsCount {
                statItem(
                    count: postsCount,
                    label: "帖子"
                )
            }
            
            Spacer()
        }
    }

    // MARK: - 统计项目
    private func statItem(count: Int, label: String) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 操作按钮
    private func actionButtonsView(_ userProfile: UserProfile, viewModel: UserProfileViewModel) -> some View {
        HStack(spacing: 12) {
            // 消息按钮
            Button(action: {
                // 发送消息
            }) {
                Image(systemName: "message")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(width: 36, height: 36)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )

            // 编辑资料按钮（如果是自己）
            if userProfile.isMe == true {
                Button(action: {
                    showEditProfile = true
                }) {
                    Text("编辑资料")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(height: 36)
                .padding(.horizontal, 20)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .cornerRadius(18)
            } else {
                // 根据屏蔽状态显示不同的按钮
                if userProfile.safeIsBlocked {
                    // 显示"移出黑名单"按钮
                    Button(action: {
                        Task {
                            await viewModel.unblockUser()
                        }
                    }) {
                        Text("移出黑名单")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    .frame(height: 36)
                    .padding(.horizontal, 20)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.red, lineWidth: 1)
                    )
                    .cornerRadius(18)
                } else {
                    // 关注/取消关注按钮（如果不是自己）
                    Button(action: {
                        Task {
                            if userProfile.isFollowing == true {
                                await viewModel.unfollowUser()
                            } else {
                                await viewModel.followUser()
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            if viewModel.isFollowActionLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: userProfile.isFollowing == true ? .primary : .white))
                            }

                            Text(userProfile.isFollowing == true ? "已关注" : "关注")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(userProfile.isFollowing == true ? .primary : .white)
                        }
                    }
                    .frame(height: 36)
                    .padding(.horizontal, 20)
                    .background(
                        userProfile.isFollowing == true ?
                        Color.clear : ModernDesignSystem.Colors.primaryGreen
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                userProfile.isFollowing == true ?
                                Color(.systemGray4) : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .cornerRadius(18)
                    .disabled(viewModel.isFollowActionLoading || viewModel.isLoading)
                }
            }
        }
    }

    // MARK: - 标签页导航
    private var profileTabsSection: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }

                    // 当切换到收藏标签时，加载收藏数据
                    if tab == .bookmarks && viewModel.userProfile?.isMe == true && viewModel.bookmarkedPosts.isEmpty {
                        Task {
                            await viewModel.loadUserBookmarks(refresh: true)
                        }
                    }
                }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)

                            // 显示数量
                            if tab == .posts, let userProfile = viewModel.userProfile {
                                Text("(\(userProfile.postsCount ?? 0))")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity) // 均分宽度
                .padding(.vertical, 12)
            }
        }
        .background(
            ZStack {
                // 基础背景
                Color(.systemBackground)
                    .opacity(shouldShowTabBarShadow() ? calculateTabBarOpacity() : 1.0)

                // 推特风格的毛玻璃效果
                if shouldShowTabBarShadow() {
                    Rectangle()
                        .fill(.regularMaterial)
                        .opacity(calculateTabBarOpacity() * 0.8)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: shouldShowTabBarShadow())
        )
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 0.5),
            alignment: .bottom
        )
        .shadow(
            color: shouldShowTabBarShadow() ? .black.opacity(0.1) : .clear,
            radius: shouldShowTabBarShadow() ? 4 : 0,
            x: 0,
            y: 2
        )
        .animation(.easeInOut(duration: 0.2), value: shouldShowTabBarShadow())
    }

    // MARK: - 计算标签栏阴影显示
    private func shouldShowTabBarShadow() -> Bool {
        let shadowThreshold: CGFloat = -200
        return scrollOffset < shadowThreshold
    }

    // MARK: - 计算标签栏背景透明度
    private func calculateTabBarOpacity() -> Double {
        let startThreshold: CGFloat = -150
        let fullOpacityThreshold: CGFloat = -250

        if scrollOffset >= startThreshold {
            return 0.0
        }

        let progress = min(max((startThreshold - scrollOffset) / (startThreshold - fullOpacityThreshold), 0), 1)
        return Double(progress) * 0.95
    }

    // MARK: - 判断是否显示固定标签栏
    private func shouldShowStickyTabBar() -> Bool {
        // 当滚动超过横幅和用户信息区域时显示固定标签栏
        let stickyThreshold: CGFloat = -350 // 横幅200 + 用户信息150
        return scrollOffset <= stickyThreshold
    }

    // MARK: - 固定标签栏视图
    private var stickyTabBarView: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }

                    // 当切换到收藏标签时，加载收藏数据
                    if tab == .bookmarks && viewModel.userProfile?.isMe == true && viewModel.bookmarkedPosts.isEmpty {
                        Task {
                            await viewModel.loadUserBookmarks(refresh: true)
                        }
                    }
                }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)

                            // 显示数量
                            if tab == .posts, let userProfile = viewModel.userProfile {
                                Text("(\(userProfile.postsCount ?? 0))")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity) // 均分宽度
                .padding(.vertical, 12)
            }
        }
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .opacity(0.95)
        )
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 0.5),
            alignment: .bottom
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - 内容区域
    private var profileContentSection: some View {
        VStack(spacing: 0) {
            switch selectedTab {
            case .posts:
                postsContentView
            case .bookmarks:
                bookmarksContentView
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 帖子内容
    private var postsContentView: some View {
        VStack(spacing: 0) {
            if viewModel.isLoadingPosts && viewModel.userPosts.isEmpty {
                // 首次加载状态
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("加载帖子中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else if viewModel.userPosts.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("暂无帖子")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("该用户还没有发布任何帖子")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else {
                // 帖子列表 - 瀑布流布局
                WaterfallLayout(
                    items: viewModel.userPosts,
                    columns: 2,
                    spacing: 4,
                    horizontalPadding: 4,
                    onLoadMore: {
                        if viewModel.hasMorePosts && !viewModel.isLoadingPosts {
                            Task {
                                print("🔄 触发分页加载，当前页: \(viewModel.postsCurrentPage)")
                                await viewModel.loadMorePosts()
                            }
                        }
                    }
                ) { post in
                    WaterfallPostCard(
                        post: post,
                        onTap: {
                            print("🔍 UserProfileView: 导航到帖子详情，帖子ID: \(post.id)")
                            selectedPostId = post.id
                            showingPostDetail = true
                        },
                        onLike: {
                            Task {
                                await toggleLikePost(post.id)
                            }
                        },
                        onUserTap: {
                            // 在用户详情页面，不需要跳转到自己
                        }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            // 首次加载帖子
            if viewModel.userPosts.isEmpty {
                Task {
                    await viewModel.loadUserPosts(userId: userId, refresh: true)
                }
            }
        }
    }

    // MARK: - 收藏内容

    private var bookmarksContentView: some View {
        VStack(spacing: 0) {
            // 检查是否为当前用户本人
            if viewModel.userProfile?.isMe != true {
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "lock")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("私密内容")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("只有本人才能查看收藏内容")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else if viewModel.isLoadingBookmarks && viewModel.bookmarkedPosts.isEmpty {
                // 首次加载状态
                VStack(spacing: 16) {
                    Spacer()

                    ProgressView()
                        .scaleEffect(1.2)
                    Text("加载收藏中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else if viewModel.bookmarkedPosts.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "bookmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("暂无收藏")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("你还没有收藏任何帖子")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 400)
            } else {
                // 收藏列表
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.bookmarkedPosts) { post in
                        PostCardView(
                            post: post,
                            showHotBadge: false,
                            showEditButton: false,
                            onLike: {
                                Task {
                                    await toggleLikeBookmarkedPost(post.id)
                                }
                            },
                            onBookmark: {
                                Task {
                                    await toggleBookmarkBookmarkedPost(post.id)
                                }
                            },
                            onShare: {
                                Task {
                                    await shareBookmarkedPost(post.id)
                                }
                            },
                            onReport: {
                                reportingPostId = post.id
                                showingReportSheet = true
                            },
                            onNavigateToDetail: { postId in
                                print("🔍 UserProfileView: 导航到帖子详情，帖子ID: \(postId)")
                                selectedPostId = postId
                                showingPostDetail = true
                            },
                            onNavigateToUserProfile: { author in
                                // 可以跳转到作者的用户详情页面
                            }
                        )
                        .onAppear {
                            // 当滚动到倒数第3个收藏帖子时，加载更多
                            if post.id == viewModel.bookmarkedPosts.suffix(3).first?.id &&
                               viewModel.hasMoreBookmarks &&
                               !viewModel.isLoadingBookmarks {
                                Task {
                                    print("🔄 触发收藏分页加载，当前页: \(viewModel.bookmarksCurrentPage)")
                                    await viewModel.loadMoreBookmarks()
                                }
                            }
                        }
                    }

                    // 加载更多指示器
                    if viewModel.isLoadingBookmarks && !viewModel.bookmarkedPosts.isEmpty {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("加载更多...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 50)
                        .padding(.vertical, 10)
                    } else if !viewModel.hasMoreBookmarks && !viewModel.bookmarkedPosts.isEmpty {
                        Text("没有更多收藏了")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(height: 50)
                            .padding(.vertical, 10)
                    }

                    // 添加底部填充空间，确保内容能够填充到屏幕底部
                    Spacer()
                        .frame(minHeight: 100)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            // 首次加载收藏（仅当为本人时）
            if viewModel.userProfile?.isMe == true && viewModel.bookmarkedPosts.isEmpty {
                Task {
                    await viewModel.loadUserBookmarks(refresh: true)
                }
            }
        }
    }

    // MARK: - 帖子交互功能
    private func toggleLikePost(_ postId: String) async {
        guard let index = viewModel.userPosts.firstIndex(where: { $0.id == postId }) else { return }

        do {
            let result = try await CommunityAPIService.shared.toggleLike(postId: postId)
            await MainActor.run {
                viewModel.userPosts[index].isLiked = result.isLiked

                if result.isLiked {
                    viewModel.userPosts[index].likesCount += 1
                } else {
                    viewModel.userPosts[index].likesCount = max(0, viewModel.userPosts[index].likesCount - 1)
                }
            }
        } catch {
            print("点赞失败：\(error)")
        }
    }

    private func toggleBookmarkPost(_ postId: String) async {
        guard let index = viewModel.userPosts.firstIndex(where: { $0.id == postId }) else { return }

        do {
            let result = try await CommunityAPIService.shared.toggleBookmark(postId: postId)
            await MainActor.run {
                viewModel.userPosts[index].isBookmarked = result.isBookmarked

                if result.isBookmarked {
                    viewModel.userPosts[index].bookmarksCount += 1
                } else {
                    viewModel.userPosts[index].bookmarksCount = max(0, viewModel.userPosts[index].bookmarksCount - 1)
                }
            }
        } catch {
            print("收藏失败：\(error)")
        }
    }

    private func sharePost(_ postId: String) async {
        do {
            let _ = try await CommunityAPIService.shared.sharePost(postId: postId)
            print("分享成功")
        } catch {
            print("分享失败：\(error)")
        }
    }

    // MARK: - 收藏列表交互功能
    private func toggleLikeBookmarkedPost(_ postId: String) async {
        guard let index = viewModel.bookmarkedPosts.firstIndex(where: { $0.id == postId }) else { return }

        do {
            let result = try await CommunityAPIService.shared.toggleLike(postId: postId)
            await MainActor.run {
                viewModel.bookmarkedPosts[index].isLiked = result.isLiked

                if result.isLiked {
                    viewModel.bookmarkedPosts[index].likesCount += 1
                } else {
                    viewModel.bookmarkedPosts[index].likesCount = max(0, viewModel.bookmarkedPosts[index].likesCount - 1)
                }
            }
        } catch {
            print("点赞失败：\(error)")
        }
    }

    private func toggleBookmarkBookmarkedPost(_ postId: String) async {
        guard let index = viewModel.bookmarkedPosts.firstIndex(where: { $0.id == postId }) else { return }

        do {
            let result = try await CommunityAPIService.shared.toggleBookmark(postId: postId)
            await MainActor.run {
                viewModel.bookmarkedPosts[index].isBookmarked = result.isBookmarked

                if result.isBookmarked {
                    viewModel.bookmarkedPosts[index].bookmarksCount += 1
                } else {
                    viewModel.bookmarkedPosts[index].bookmarksCount = max(0, viewModel.bookmarkedPosts[index].bookmarksCount - 1)
                    // 如果取消收藏，从收藏列表中移除
                    viewModel.bookmarkedPosts.remove(at: index)
                }
            }
        } catch {
            print("收藏失败：\(error)")
        }
    }

    private func shareBookmarkedPost(_ postId: String) async {
        do {
            let _ = try await CommunityAPIService.shared.sharePost(postId: postId)
            print("分享成功")
        } catch {
            print("分享失败：\(error)")
        }
    }
}

// MARK: - PreferenceKey 定义
struct HeaderOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct TabBarOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct AvatarOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension UserProfileView {
    // MARK: - 背景图上传
    private func uploadBackgroundImage(_ image: UIImage) {
        Task {
            await MainActor.run {
                isUploadingBackgroundImage = true
            }

            do {
                // 1. 上传图片到服务器
                let uploadResponse = try await ChatAPIService.shared.uploadImage(image)
                print("✅ 背景图上传成功: \(uploadResponse.url)")

                // 2. 更新用户资料
                let updateResponse = try await CommunityAPIService.shared.updateUserProfile(
                    backgroundImage: uploadResponse.url
                )

                if updateResponse.success {
                    print("✅ 背景图更新成功")

                    await MainActor.run {
                        // 更新本地用户资料数据
                        if var userProfile = viewModel.userProfile {
                            print("📝 uploadBackgroundImage 更新前背景图: \(userProfile.backgroundImage ?? "无")")
                            userProfile.backgroundImage = uploadResponse.url
                            viewModel.userProfile = userProfile
                            print("📝 uploadBackgroundImage 更新后背景图: \(userProfile.backgroundImage ?? "无")")
                            print("📝 uploadBackgroundImage viewModel.userProfile 已更新")

                            // 发送通知让其他组件知道背景图已更新
                            print("📡 发送背景图更新通知: \(uploadResponse.url)")
                            NotificationCenter.default.post(
                                name: NSNotification.Name("BackgroundImageUpdated"),
                                object: nil,
                                userInfo: ["backgroundImage": uploadResponse.url]
                            )
                            print("📡 通知已发送")
                        } else {
                            print("❌ uploadBackgroundImage viewModel.userProfile 为 nil")
                        }
                        isUploadingBackgroundImage = false
                    }
                } else {
                    print("❌ 背景图更新失败: \(updateResponse.message ?? "未知错误")")
                    await MainActor.run {
                        isUploadingBackgroundImage = false
                    }
                }

            } catch {
                print("❌ 背景图上传失败: \(error)")
                await MainActor.run {
                    isUploadingBackgroundImage = false
                }
            }
        }
    }
}

// MARK: - 现代化菜单按钮样式
struct ModernMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - 预览
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(userId: "123")
    }
}
