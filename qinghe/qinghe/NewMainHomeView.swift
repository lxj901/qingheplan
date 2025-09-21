import SwiftUI
import FamilyControls
import Charts

struct NewMainHomeView: View {
    @StateObject private var checkinViewModel = CheckinViewModel()
    @StateObject private var homePageViewModel = HomePageViewModel()
    @StateObject private var appUsageManager = AppUsageManager.shared
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @StateObject private var appRestrictionManager = AppRestrictionManager.shared
    @StateObject private var countdownManager = SelfDisciplineCountdownManager.shared
    @EnvironmentObject private var tabBarManager: TabBarVisibilityManager
    @State private var selectedSegment: Int = 0
    @State private var showingPlanManagement = false
    @State private var showingPersistenceDetail = false
    @State private var showingRecordCenter = false
    @State private var showingWorkout = false // 全屏运动页面
    @State private var showingSleep = false // 全屏睡眠页面
    @State private var showingWorkoutAnalysis = false // 运动分析详细页面
    @State private var showingSleepAnalysis = false // 睡眠分析详细页面
    @State private var showingAppUsageAnalysis = false // 应用使用分析详细页面
    @State private var currentQuoteIndex = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isCheckinButtonPressed = false

    // 新增：直接授权相关状态
    @State private var showingFamilyActivityPicker = false
    @State private var selectedAppsAndCategories = FamilyActivitySelection()
    @State private var showingAuthorizationSuccess = false // 打卡按钮按下状态
    @State private var navigationToConversationId: String? = nil // 推送通知导航
    @State private var showingCheckinInput = false // 显示打卡输入界面
    @State private var showingCheckinCalendar = false // 显示打卡日历界面

    // 运动分析管理器 - 暂时注释掉，因为 WorkoutAnalyticsManager 不存在
    // @StateObject private var workoutAnalytics = WorkoutAnalyticsManager.shared

    // 激励语录数组
    private let motivationalQuotes = [
        "每一天的坚持都是迈向更好自己的一步",
        "自律是通往自由的桥梁",
        "今天的努力，是明天的礼物",
        "成长的过程虽然艰难，但结果值得期待",
        "坚持下去，你会感谢今天努力的自己"
    ]

    // 动态时间问候语
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<12:
            return "早安！新的一天开始了，加油！ ✨"
        case 12..<18:
            return "午安！继续保持专注，你很棒！ ✨"
        default:
            return "晚安！今天辛苦了，明天继续努力！ ✨"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                modernBackgroundGradient

                // 主要内容
                VStack(spacing: 0) {
                    // 顶部固定标题栏
                    modernHeaderView
                        .zIndex(1) // 确保在最上层

                    // 可滚动内容
                    ScrollView {
                        VStack(spacing: 0) {
                            // 在 ScrollView 顶部放置一个隐藏的 GeometryReader 来监听滚动
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                            }
                            .frame(height: 0)

                            LazyVStack(spacing: 18) { // 优化主容器间距到 18pt，符合 iOS 设计规范
                                // 激励语录卡片
                                modernMotivationalQuoteCard
                                    .padding(.horizontal, 16)

                                // 连续坚持、自律时间和计划完成率综合卡片
                                modernCombinedStatsCard
                                    .padding(.horizontal, 16)

                                // 快速操作区
                                modernQuickActionButtons
                                    .padding(.horizontal, 16)

                                // 数据统计模块
                                modernDataVisualizationCard
                                    .padding(.horizontal, 16)

                                // 今日计划
                                modernTodayPlanCard
                                    .padding(.horizontal, 16)

                                // 底部间距
                                Color.clear.frame(height: 100) // 确保底部间距足够，不被TabBar遮挡
                            }
                            .padding(.top, 16) // 保持顶部间距 16pt
                        }
                    }
                    .coordinateSpace(name: "scroll")
                    .padding(.bottom, 0) // 确保内容不被底部TabBar遮挡
                }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    // 实时更新滚动偏移量，不使用动画以确保效果即时响应
                    scrollOffset = value
                }
                .refreshable {
                    await homePageViewModel.refreshData()
                    await checkinViewModel.refreshData()
                }


            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingPersistenceDetail) {
                PersistenceDetailView()
                    .navigationBarHidden(true)
            }
        }
        .onAppear {
            Task {
                await homePageViewModel.fetchData()
                // await workoutAnalytics.refreshAnalyticsData()
                await checkinViewModel.loadInitialData()

                // 更新应用管理器的自律时间
                updateAppManagementData()

                // 恢复应用选择状态
                restoreAppSelection()
            }
        }
        .onChange(of: homePageViewModel.comprehensiveSelfDisciplineTime) { _, newValue in
            // 当综合自律时间发生变化时，实时更新应用管理器
            appUsageManager.updateSelfDisciplineTime(newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CheckinSuccessful"))) { notification in
            // 监听签到成功通知，同步更新状态
            Task { @MainActor in
                if let checkinRecord = notification.object as? CheckinAPIRecord {
                    // 更新两个ViewModel的状态
                    checkinViewModel.hasCheckedInToday = true
                    checkinViewModel.todayCheckinRecord = checkinRecord
                    homePageViewModel.hasCheckedInToday = true
                    homePageViewModel.todayCheckinRecord = checkinRecord

                    // 刷新相关数据
                    await homePageViewModel.loadCheckinStatistics()
                    await checkinViewModel.loadStatistics()
                }
            }
        }
        .asRootView() // 标记为主页面，显示Tab栏
        .onReceive(NotificationCenter.default.publisher(for: .openConversation)) { notification in
            // 处理推送通知导航到对话
            if let conversationId = notification.object as? String {
                navigationToConversationId = conversationId
            }
        }
        .onAppear {
            // 同步 Screen Time 授权状态到 AppUsageManager，避免“本月坚持情况-应用使用”面板误判为未授权
            Task {
                // 先检查最新的授权状态
                screenTimeManager.checkAuthorizationStatus()

                await MainActor.run {
                    let authorized = screenTimeManager.isAuthorized
                    appUsageManager.isAuthorized = authorized

                    print("📱 首页同步权限状态：ScreenTimeManager.isAuthorized = \(authorized)")
                    print("📱 首页同步权限状态：AppUsageManager.isAuthorized = \(appUsageManager.isAuthorized)")

                    if authorized {
                        appUsageManager.refreshData()
                    }
                }
            }
        }
        .navigationDestination(isPresented: .constant(navigationToConversationId != nil)) {
            if let conversationId = navigationToConversationId {
                // 创建一个临时的对话对象用于导航
                let tempConversation = ChatConversation(
                    id: conversationId,
                    title: "对话",
                    type: .privateChat,
                    avatar: nil,
                    lastMessage: nil,
                    lastMessageAt: ISO8601DateFormatter().string(from: Date()),
                    unreadCount: 0,
                    isTop: false,
                    isMuted: false,
                    membersCount: 2,
                    creatorId: 0,
                    creator: nil,
                    memberRecords: [],
                    description: nil,
                    maxMembers: nil,
                    createdAt: nil
                )
                ChatDetailView(conversation: tempConversation)
                    .onDisappear {
                        navigationToConversationId = nil
                    }
            }
        }
        // 打卡成功 Toast 提示
        .overlay(
            VStack {
                if checkinViewModel.showCheckinToast {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)

                        Text(checkinViewModel.checkinToastMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 76/255, green: 175/255, blue: 80/255), Color(red: 45/255, green: 206/255, blue: 137/255)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: checkinViewModel.showCheckinToast)
                }
                Spacer()
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)
        )

        .fullScreenCover(isPresented: $showingWorkout) {
            NavigationView {
                WorkoutModeSelectionView()
                    .navigationTitle("运动中心")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("关闭") {
                                showingWorkout = false
                            }
                            .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                        }
                    }
            }
            .asSubView()
        }
        .fullScreenCover(isPresented: $showingSleep) {
            NavigationView {
                SleepDashboardView()
                    .navigationBarHidden(true)
            }
            .asSubView()
        }
        .fullScreenCover(isPresented: $showingRecordCenter) {
            NavigationView {
                NewRecordCenterView()
            }
        }
        .sheet(isPresented: $showingCheckinInput) {
            CheckinInputView()
        }
        .fullScreenCover(isPresented: $showingWorkoutAnalysis) {
            WorkoutAnalysisDetailView()
        }
        .fullScreenCover(isPresented: $showingSleepAnalysis) {
            SleepRecordsView()
        }
        .fullScreenCover(isPresented: $showingAppUsageAnalysis) {
            AppUsageAnalysisDetailView()
        }

        .familyActivityPicker(isPresented: $showingFamilyActivityPicker, selection: $selectedAppsAndCategories)
        .onChange(of: selectedAppsAndCategories) {
            handleAppSelectionChange()
        }
        .onChange(of: showingFamilyActivityPicker) { _, isPresented in
            // 当系统选择器关闭后，如果有待打开的“应用管理”页，再打开
            // 应用管理页面已删除，无需处理
        }
        .alert("应用管理设置成功", isPresented: $showingAuthorizationSuccess) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("已为您选择的 \(selectedAppsAndCategories.applications.count) 个应用创建默认解锁规则。完成自律活动即可解锁这些应用！")
        }
        .asRootView()

    }

    // MARK: - 现代化背景渐变
    private var modernBackgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 248/255, green: 250/255, blue: 252/255), // 更清淡的背景
                Color(red: 241/255, green: 245/255, blue: 249/255),
                Color(red: 248/255, green: 250/255, blue: 252/255)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - 现代化顶部状态栏
    private var modernHeaderView: some View {
        HStack {
            // 左侧占位，保持标题居中
            Color.clear
                .frame(width: 40, height: 40)
            
            Spacer()
            
            // 中央标题区域
            VStack(spacing: 4) {
                Text("青禾")
                    .font(.system(size: scrollOffset < -50 ? FontManager.shared.fontSize(for: .headline) : FontManager.shared.fontSize(for: .title2), weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                    .animation(.easeInOut(duration: 0.3), value: scrollOffset)

                Text("自律成就更好的自己")
                    .dynamicFont(.caption1)
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                    .opacity(scrollOffset < -80 ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: scrollOffset)
            }
            
            Spacer()
            
            // 右侧占位，保持标题居中
            Color.clear
                .frame(width: 40, height: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 12) // 标题间距
        .padding(.bottom, scrollOffset < -50 ? 8 : 12)
        .background(
            // 动态背景效果
            ZStack {
                // 始终存在的背景
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(calculateBackgroundOpacity())
                    .animation(.easeInOut(duration: 0.25), value: scrollOffset)

                // 边框效果
                if scrollOffset < -30 {
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.black.opacity(0.08))
                            .frame(height: 0.5)
                    }
                    .opacity(calculateBorderOpacity())
                    .animation(.easeInOut(duration: 0.25), value: scrollOffset)
                }
            }
        )
    }

    // MARK: - 激励语录卡片
    private var modernMotivationalQuoteCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))

            Text(motivationalQuotes[currentQuoteIndex])
                .dynamicFont(.subheadline)
                .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentQuoteIndex = (currentQuoteIndex + 1) % motivationalQuotes.count
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.systemGray4).opacity(0.3), radius: 8, x: 0, y: 2)
    }

    // MARK: - 连续坚持、自律时间和计划完成率综合卡片
    private var modernCombinedStatsCard: some View {
        VStack(spacing: 20) {
            // 上半部分：连续坚持和打卡按钮
            HStack(alignment: .center) {
                // 左侧：连续坚持信息
                VStack(alignment: .leading, spacing: 6) {
                    Text("连续坚持")
                        .dynamicFont(.footnote)
                        .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(checkinViewModel.statistics?.consecutiveDays ?? 0)")
                            .dynamicFont(.numberLarge)
                            .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))

                        Text("天")
                            .dynamicFont(.bodyMedium)
                            .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                    }
                }

                Spacer()

                // 右侧：现代化打卡按钮
                modernCheckinButton
            }

            // 分割线
            Rectangle()
                .fill(Color(red: 240/255, green: 240/255, blue: 240/255))
                .frame(height: 1)

            // 下半部分：自律时间和计划完成率
            HStack(spacing: 0) {
                // 左侧 - 今日指标（不可点击）
                VStack(alignment: .leading, spacing: 6) {
                        Text("今日指标")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))

                        // 显示倒计时或总时间
                        if countdownManager.isCountingDown {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text(countdownManager.formattedRemainingTime)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(countdownManager.remainingTimeInSeconds <= 300 ? .red : Color(red: 51/255, green: 51/255, blue: 51/255))

                                    Text("剩余")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                                }

                                // 进度条
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 4)

                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(countdownManager.remainingTimeInSeconds <= 300 ? .red : Color(red: 76/255, green: 175/255, blue: 80/255))
                                            .frame(width: geometry.size.width * countdownManager.progress, height: 4)
                                            .animation(.easeInOut(duration: 0.3), value: countdownManager.progress)
                                    }
                                }
                                .frame(height: 4)
                            }
                        } else {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                // 🔥 修复：如果今日已耗尽，显示 0，否则显示预算值
                                Text("\(countdownManager.hasExhaustedForToday() ? 0 : homePageViewModel.comprehensiveSelfDisciplineTime)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))

                                Text("分钟")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                            }
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 分割线
                Rectangle()
                    .fill(Color(red: 240/255, green: 240/255, blue: 240/255))
                    .frame(width: 1, height: 40)

                // 右侧 - 计划完成率
                VStack(alignment: .trailing, spacing: 6) {
                    Text("计划完成率")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(homePageViewModel.planCompletionRate)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 255/255, green: 59/255, blue: 48/255))

                        Text("%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 255/255, green: 59/255, blue: 48/255))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.systemGray4).opacity(0.3), radius: 8, x: 0, y: 2)
    }

    // MARK: - 滚动效果计算辅助方法
    /// 计算背景透明度：基于滚动偏移量动态调整
    private func calculateBackgroundOpacity() -> Double {
        let offset = abs(scrollOffset)

        if offset <= 20 {
            return 0.0
        } else if offset <= 50 {
            return ((offset - 20) / 30) * 0.4
        } else if offset <= 100 {
            let progress = (offset - 50) / 50
            return 0.4 + (progress * 0.5)
        } else {
            return 0.9
        }
    }

    /// 计算边框透明度：基于滚动偏移量动态调整
    private func calculateBorderOpacity() -> Double {
        let offset = abs(scrollOffset)

        if offset <= 30 {
            return 0.0
        } else if offset <= 80 {
            return ((offset - 30) / 50) * 1.0
        } else {
            return 1.0
        }
    }

    // MARK: - 现代化快速操作区
    private var modernQuickActionButtons: some View {
        HStack(spacing: 12) {
            // 记录中心
            Button(action: {
                showingRecordCenter = true
            }) {
                modernQuickActionButtonContent(
                    icon: "doc.text.fill",
                    title: "记录中心",
                    bgColor: Color(red: 255/255, green: 245/255, blue: 230/255),
                    iconColor: Color(red: 255/255, green: 170/255, blue: 51/255)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // 运动
            modernQuickActionButton(
                icon: "figure.run",
                title: "运动中心",
                bgColor: Color(red: 230/255, green: 255/255, blue: 230/255),
                iconColor: Color(red: 76/255, green: 175/255, blue: 80/255),
                action: { showingWorkout.toggle() }
            )

            // 睡眠
            modernQuickActionButton(
                icon: "moon.zzz.fill",
                title: "睡眠管理",
                bgColor: Color(red: 240/255, green: 230/255, blue: 255/255),
                iconColor: Color(red: 138/255, green: 43/255, blue: 226/255),
                action: { showingSleep.toggle() }
            )
            
            // 应用管理
            modernQuickActionButton(
                icon: "heart.fill",
                title: "健康管家",
                bgColor: Color(red: 230/255, green: 247/255, blue: 255/255),
                iconColor: Color(red: 51/255, green: 170/255, blue: 255/255),
                action: { handleHealthManagerAction() }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.systemGray4).opacity(0.3), radius: 8, x: 0, y: 2)
    }

    // 现代化快速操作按钮
    func modernQuickActionButton(
        icon: String,
        title: String,
        bgColor: Color,
        iconColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            modernQuickActionButtonContent(
                icon: icon,
                title: title,
                bgColor: bgColor,
                iconColor: iconColor
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 快速操作按钮内容（可用于NavigationLink）
    func modernQuickActionButtonContent(
        icon: String,
        title: String,
        bgColor: Color,
        iconColor: Color
    ) -> some View {
        VStack(spacing: 12) {
            // 图标区域
            ZStack {
                Circle()
                    .fill(bgColor)
                    .frame(width: 48, height: 48)
                    .shadow(color: iconColor.opacity(0.2), radius: 4, x: 0, y: 2)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // 文字区域
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - 现代化数据统计模块
    private var modernDataVisualizationCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题和分段控制器
            VStack(spacing: 16) {                HStack {
                    Text("本月坚持情况")
                        .dynamicFont(.headline)
                        .foregroundColor(.primary)

                    Spacer()
                }

                // 现代化分段控制器
                modernSegmentedControl
            }

            // 内容区域
            Group {
                if selectedSegment == 0 {
                    modernHeatmapView
                } else if selectedSegment == 1 {
                    modernWorkoutAnalysisView
                } else if selectedSegment == 2 {
                    modernSleepAnalysisView
                } else {
                    modernAppUsageView
                }
            }
            .frame(minHeight: 200)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.systemGray4).opacity(0.3), radius: 8, x: 0, y: 2)
    }

    // 现代化分段控制器
    private var modernSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        selectedSegment = index
                    }
                }) {
                    Text(segmentTitle(for: index))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedSegment == index ? .white : Color(red: 102/255, green: 102/255, blue: 102/255))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if selectedSegment == index {
                                    LinearGradient(
                                        colors: [Color(red: 76/255, green: 175/255, blue: 80/255), Color(red: 45/255, green: 206/255, blue: 137/255)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .cornerRadius(10)
                                    .shadow(color: Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    private func segmentTitle(for index: Int) -> String {
        switch index {
        case 0: return "坚持情况"
        case 1: return "运动分析"
        case 2: return "睡眠分析"
        case 3: return "健康指数"
        default: return ""
        }
    }

    // MARK: - 现代化今日计划
    private var modernTodayPlanCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题区域
            HStack {
                Text("今日计划")
                    .dynamicFont(.headline)
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))

                Spacer()

                // 添加计划按钮
                Button(action: {
                    // showingPlanManagement.toggle() 已删除，入口隐藏
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                }
            }

            // 计划列表或空状态
            if homePageViewModel.todayPlans.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.6))

                    VStack(spacing: 8) {
                        Text("今日暂无计划")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))

                        Text("制定今日计划，开启高效一天")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                    }

                    Button(action: {
                        // showingPlanManagement.toggle() 已删除，入口隐藏
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("添加计划")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 76/255, green: 175/255, blue: 80/255), Color(red: 56/255, green: 142/255, blue: 60/255)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // 计划列表
                LazyVStack(spacing: 12) {
                    ForEach(homePageViewModel.todayPlans) { plan in
                        modernPlanRow(plan: plan)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.systemGray4).opacity(0.3), radius: 8, x: 0, y: 2)
    }

    // 现代化计划行
    private func modernPlanRow(plan: TodayPlan) -> some View {
        HStack(spacing: 16) {
            // 完成状态指示器
            Button(action: {
                // 切换完成状态的逻辑
                // TODO: 实现计划完成状态切换
            }) {
                ZStack {
                    Circle()
                        .stroke(
                            plan.isCompleted ? Color(red: 76/255, green: 175/255, blue: 80/255) : Color(red: 221/255, green: 221/255, blue: 221/255),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if plan.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                    }
                }
            }

            // 计划信息
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(plan.isCompleted ? Color(red: 153/255, green: 153/255, blue: 153/255) : Color(red: 51/255, green: 51/255, blue: 51/255))
                    .strikethrough(plan.isCompleted)

                Text(plan.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(plan.isCompleted ? Color(.secondarySystemBackground) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 1)
                )
        )
    }





    // MARK: - 辅助方法



    /// 检查指定日期是否已打卡
    private func isDateCheckedIn(_ day: Int) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // 获取当前月份和年份
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        // 构建日期字符串
        let dateString = String(format: "%04d-%02d-%02d", currentYear, currentMonth, day)

        // 检查是否在打卡历史中
        return homePageViewModel.checkinHistory.contains(dateString)
    }

    /// 检查指定日期是否是未来日期
    private func isFutureDate(_ day: Int) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentDay = calendar.component(.day, from: now)
        return day > currentDay
    }

    // MARK: - 数据统计内容视图
    private var modernHeatmapView: some View {
        VStack(spacing: 16) {
            // 周标题行 - 与日历网格保持相同的间距
            HStack(spacing: 8) {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                        .frame(width: 32, height: 20) // 固定宽度和高度，与日历单元格对齐
                }
            }

            // 日历网格 - 使用真实数据
            VStack(spacing: 8) {
                // 动态生成当前月份的日历
                let calendar = Calendar.current
                let now = Date()
                let range = calendar.range(of: .day, in: .month, for: now)
                let numberOfDays = range?.count ?? 30

                // 按周分组显示
                ForEach(0..<((numberOfDays + 6) / 7), id: \.self) { weekIndex in
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            let day = weekIndex * 7 + dayIndex + 1
                            if day <= numberOfDays {
                                modernCalendarDay(day: day, isChecked: isDateCheckedIn(day), isFuture: isFutureDate(day))
                            } else {
                                Color.clear.frame(width: 32, height: 32)
                            }
                        }
                    }
                }
            }

            // 统计信息 - 基于真实数据，居中显示
            HStack(spacing: 16) {
                let calendar = Calendar.current
                let now = Date()
                let range = calendar.range(of: .day, in: .month, for: now)
                let numberOfDays = range?.count ?? 30
                let currentDay = calendar.component(.day, from: now)
                let checkedDaysCount = homePageViewModel.checkinHistory.count
                let completionRate = currentDay > 0 ? Int((Double(checkedDaysCount) / Double(currentDay)) * 100) : 0

                Text("坚持率 \(completionRate)%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))

                Text("本月 \(checkedDaysCount)/\(numberOfDays) 天")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
            }
            .frame(maxWidth: .infinity) // 让 HStack 占满宽度
            .multilineTextAlignment(.center) // 居中对齐
        }
    }

    // 现代化日历日期单元格
    private func modernCalendarDay(day: Int, isChecked: Bool, isFuture: Bool = false) -> some View {
        Button(action: {
            showingCheckinCalendar = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isChecked ?
                            Color(red: 76/255, green: 175/255, blue: 80/255) : // 已打卡：绿色
                            (isFuture ?
                                Color(red: 245/255, green: 245/255, blue: 245/255) : // 未来日期：浅灰色
                                Color(red: 255/255, green: 235/255, blue: 235/255)) // 过去未打卡：浅红色
                    )
                    .frame(width: 32, height: 32)

                Text("\(day)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(
                        isChecked ?
                            .white : // 已打卡：白色文字
                            (isFuture ?
                                Color(red: 153/255, green: 153/255, blue: 153/255) : // 未来日期：灰色文字
                                Color(red: 255/255, green: 59/255, blue: 48/255)) // 过去未打卡：红色文字
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }



    private var modernWorkoutAnalysisView: some View {
        VStack(spacing: 16) {
            workoutAnalysisContent
            workoutAnalysisFooter
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingWorkoutAnalysis.toggle()
        }
    }

    private var workoutAnalysisFooter: some View {
        HStack {
            Spacer()

            Button(action: {
                showingWorkoutAnalysis.toggle()
            }) {
                HStack(spacing: 4) {
                    Text("查看详情")
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var workoutAnalysisContent: some View {
        Group {
            if homePageViewModel.isLoadingWorkoutData {
                workoutLoadingView
            } else if homePageViewModel.weeklyWorkoutData.isEmpty {
                workoutEmptyView
            } else {
                workoutDataView
            }
        }
        .onAppear {
            Task {
                await homePageViewModel.loadWorkoutAnalysisData()
            }
        }
    }

    private var workoutLoadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 76/255, green: 175/255, blue: 80/255)))

            Text("正在分析运动数据...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private var workoutEmptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.6))

            VStack(spacing: 8) {
                Text("暂无运动数据")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))

                Text("开始运动记录，查看详细分析")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                showingWorkout.toggle()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 14, weight: .semibold))
                    Text("开始运动")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(red: 76/255, green: 175/255, blue: 80/255), Color(red: 56/255, green: 142/255, blue: 60/255)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private var workoutDataView: some View {
        // 运动时长折线图
        workoutChart
    }

    private var workoutChart: some View {
        // 运动时长折线图
        VStack(spacing: 0) {
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(homePageViewModel.weeklyWorkoutData, id: \.id) { data in
                        BarMark(
                            x: .value("日期", data.date),
                            y: .value("运动时长", data.duration)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 76/255, green: 175/255, blue: 80/255), Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(6)
                    }
                }
                .frame(height: 120)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)分钟")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let stringValue = value.as(String.self) {
                                Text(stringValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } else {
                // iOS 15 兼容性处理 - 简化的折线图样式
                VStack(spacing: 12) {
                    // 简单的折线图模拟
                    GeometryReader { geometry in
                        let maxDuration = homePageViewModel.weeklyWorkoutData.map { $0.duration }.max() ?? 1
                        let width = geometry.size.width
                        let height = geometry.size.height - 20 // 留出底部标签空间

                        Path { path in
                            for (index, data) in homePageViewModel.weeklyWorkoutData.enumerated() {
                                let x = width * CGFloat(index) / CGFloat(max(1, homePageViewModel.weeklyWorkoutData.count - 1))
                                let y = height - (height * CGFloat(data.duration) / CGFloat(maxDuration))

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color(red: 76/255, green: 175/255, blue: 80/255), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                        // 添加数据点
                        ForEach(Array(homePageViewModel.weeklyWorkoutData.enumerated()), id: \.offset) { index, data in
                            let x = width * CGFloat(index) / CGFloat(max(1, homePageViewModel.weeklyWorkoutData.count - 1))
                            let y = height - (height * CGFloat(data.duration) / CGFloat(maxDuration))

                            Circle()
                                .fill(Color(red: 76/255, green: 175/255, blue: 80/255))
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                    }

                    // 底部日期标签
                    HStack {
                        ForEach(homePageViewModel.weeklyWorkoutData, id: \.id) { data in
                            Text(data.date)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(height: 120)
            }
        }
    }



    private var modernAppUsageView: some View {
        VStack(spacing: 16) {
            // 检查是否有屏幕使用时间权限 - 优先使用 ScreenTimeManager 的状态
            if screenTimeManager.isAuthorized || appUsageManager.isAuthorized {
                // 有权限 - 优先显示真实数据，否则显示已选择的应用
                if !AppUsageManager.shared.appUsageData.isEmpty {
                    // 显示真实的应用使用数据
                    enhancedAppUsageDataView
                } else if !AppUsageManager.shared.appUnlockStatuses.isEmpty {
                    // 显示已选择应用的状态（基于解锁规则）
                    selectedAppsStatusView
                } else if screenTimeManager.isLoading {
                    // 仍在加载中
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 76/255, green: 175/255, blue: 80/255)))

                        Text("正在获取应用使用数据...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    // 已授权但暂无数据，引导用户选择应用
                    noDataPlaceholderView
                }
            } else {
                // 无权限 - 引导用户授权
                VStack(spacing: 16) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.6))
                    
                    VStack(spacing: 8) {
                        Text("需要屏幕使用时间权限")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                        
                        Text("授权后可查看详细的应用使用统计\n并设置应用限制和专注模式")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    
                    Button(action: {
                        requestAuthorizationAndShowPicker()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("立即授权")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 76/255, green: 175/255, blue: 80/255),
                                    Color(red: 56/255, green: 142/255, blue: 60/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }

            // 底部居中的查看详情按钮
            HStack {
                Spacer()

                Button(action: {
                    showingAppUsageAnalysis.toggle()
                }) {
                    HStack(spacing: 4) {
                        Text("查看详情")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                }

                Spacer()
            }
            .padding(.top, 8)
        }
    }

    private func appUsageRow(appName: String, usage: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(appName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))

            Spacer()

            Text(usage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
        }
    }
    
    // MARK: - 增强版应用使用数据视图
    private var enhancedAppUsageDataView: some View {
        VStack(spacing: 16) {
            // 今日使用概览卡片
            todayUsageOverviewCard

            // 应用使用排行榜
            appUsageRankingView

            // 快速操作区域
            quickActionsView
        }
    }

    // MARK: - 今日使用概览卡片
    private var todayUsageOverviewCard: some View {
        VStack(spacing: 12) {
            // 主要统计数据
            HStack(spacing: 20) {
                // 总使用时间
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))

                        Text("今日总计")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                    }

                    Text(formatScreenTime(AppUsageManager.shared.totalScreenTime))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(getScreenTimeColor(AppUsageManager.shared.totalScreenTime))
                }

                Spacer()

                // 使用等级和应用数量
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("使用等级")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))

                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                    }

                    HStack(spacing: 8) {
                        Text(getUsageLevelText(AppUsageManager.shared.totalScreenTime))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(getUsageLevelColor(AppUsageManager.shared.totalScreenTime))

                        Text("·")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))

                        Text("\(homePageViewModel.appUsageData.count)个应用")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                    }
                }
            }

            // 使用时间进度条
            if AppUsageManager.shared.totalScreenTime > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("今日进度")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))

                        Spacer()

                        Text("目标: 6小时")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 背景条
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 240/255, green: 240/255, blue: 240/255))
                                .frame(height: 8)

                            // 进度条
                            RoundedRectangle(cornerRadius: 4)
                                .fill(getScreenTimeColor(AppUsageManager.shared.totalScreenTime))
                                .frame(
                                    width: geometry.size.width * min(1.0, AppUsageManager.shared.totalScreenTime / (6 * 3600)),
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - 应用使用排行榜
    private var appUsageRankingView: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 255/255, green: 215/255, blue: 0/255))

                    Text("使用排行")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                }

                Spacer()

                Text("前3名")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
            }

            VStack(spacing: 8) {
                ForEach(Array(homePageViewModel.appUsageData.prefix(3).enumerated()), id: \.element.id) { index, app in
                    enhancedAppUsageRow(app: app, rank: index + 1)
                }
            }
        }
    }

    // MARK: - 已选择应用状态视图
    private var selectedAppsStatusView: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))

                    Text("已选择的应用")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                }

                Spacer()

                Text("\(AppUsageManager.shared.appUnlockStatuses.count)个应用")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
            }

            // 应用状态列表
            VStack(spacing: 8) {
                ForEach(Array(AppUsageManager.shared.appUnlockStatuses.prefix(3)), id: \.id) { status in
                    selectedAppStatusRow(status: status)
                }
            }

            // 提示信息
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 255/255, green: 149/255, blue: 0/255))

                    Text("完成自律活动即可解锁应用使用时间")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))

                    Spacer()
                }

                if AppUsageManager.shared.appUnlockStatuses.count > 3 {
                    Button(action: {
                        handleHealthManagerAction()
                    }) {
                        Text("查看全部 \(AppUsageManager.shared.appUnlockStatuses.count) 个应用")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                    }
                }
            }
        }
    }

    // MARK: - 已选择应用状态行
    private func selectedAppStatusRow(status: AppUnlockStatus) -> some View {
        HStack(spacing: 12) {
            // 应用图标
            ZStack {
                Circle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.2))
                    .frame(width: 32, height: 32)

                // 优先使用真实应用图标，否则使用默认图标
                if let token = AppUsageManager.shared.getApplicationToken(for: status.appName) {
                    Label(token)
                        .labelStyle(.iconOnly)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                }
            }

            // 应用信息
            VStack(alignment: .leading, spacing: 3) {
                // 应用名称
                if let token = AppUsageManager.shared.getApplicationToken(for: status.appName) {
                    Label(token)
                        .labelStyle(.titleOnly)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                } else {
                    Text(AppUsageManager.shared.getResolvedDisplayName(for: status.appName))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                }

                Text(AppUsageManager.shared.getUnlockStatusDescription(for: status.appName))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(status.isUnlocked ? Color(red: 76/255, green: 175/255, blue: 80/255) : Color(red: 255/255, green: 149/255, blue: 0/255))
            }

            Spacer()

            // 时间信息
            VStack(alignment: .trailing, spacing: 2) {
                Text(AppUsageManager.shared.formatTime(status.remainingTime))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(status.isUnlocked ? Color(red: 76/255, green: 175/255, blue: 80/255) : Color(red: 153/255, green: 153/255, blue: 153/255))

                Text("剩余")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(Color(red: 248/255, green: 249/255, blue: 250/255))
        .cornerRadius(10)
    }

    // MARK: - 无数据占位视图
    private var noDataPlaceholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "apps.iphone")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.6))

            VStack(spacing: 8) {
                Text("暂无应用使用数据")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))

                Text("选择要管理的应用，开始您的自律之旅")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                handleHealthManagerAction()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))

                    Text("选择应用")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(red: 76/255, green: 175/255, blue: 80/255))
                .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - 快速操作区域
    private var quickActionsView: some View {
        HStack(spacing: 12) {
            // 应用管理按钮
            Button(action: {
                handleHealthManagerAction()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "gear")
                        .font(.system(size: 12, weight: .medium))

                    Text("应用管理")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()

            // 专注模式按钮
            Button(action: {
                // TODO: 实现专注模式功能
                print("启动专注模式")
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 12, weight: .medium))

                    Text("专注模式")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(red: 138/255, green: 43/255, blue: 226/255))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 138/255, green: 43/255, blue: 226/255).opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()

            // 数据导出按钮
            Button(action: {
                // TODO: 实现数据导出功能
                print("导出使用数据")
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .medium))

                    Text("导出")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(red: 255/255, green: 149/255, blue: 0/255))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 255/255, green: 149/255, blue: 0/255).opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - 增强版应用使用数据行
    private func enhancedAppUsageRow(app: AppUsageData, rank: Int) -> some View {
        HStack(spacing: 12) {
            // 排名指示器（增强版）
            ZStack {
                Circle()
                    .fill(getRankColor(rank).opacity(0.15))
                    .frame(width: 28, height: 28)

                if rank <= 3 {
                    Image(systemName: rank == 1 ? "crown.fill" : rank == 2 ? "medal.fill" : "star.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(getRankColor(rank))
                } else {
                    Text("\(rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(getRankColor(rank))
                }
            }

            // 应用图标（增强版）
            ZStack {
                Circle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: app.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
            }

            // 应用信息（增强版）
            VStack(alignment: .leading, spacing: 3) {
                Text(app.appName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))

                HStack(spacing: 4) {
                    Text("应用")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))

                    // 使用状态指示器
                    Circle()
                        .fill(app.usageLevel.color)
                        .frame(width: 4, height: 4)

                    Text(getUsageLevelText(app.usageLevel))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(app.usageLevel.color)
                }
            }

            Spacer()

            // 使用时间和进度（增强版）
            VStack(alignment: .trailing, spacing: 4) {
                Text(app.formattedTime)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(app.usageLevel.color)

                // 使用进度条
                if app.usageTime > 0 {
                    let maxUsage = homePageViewModel.appUsageData.first?.usageTime ?? 120
                    let progress = Double(app.usageTime) / Double(maxUsage)

                    GeometryReader { geometry in
                        ZStack(alignment: .trailing) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(red: 240/255, green: 240/255, blue: 240/255))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(app.usageLevel.color)
                                .frame(
                                    width: geometry.size.width * progress,
                                    height: 4
                                )
                        }
                    }
                    .frame(width: 40, height: 4)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(red: 248/255, green: 249/255, blue: 250/255))
        .cornerRadius(10)
    }

    // MARK: - 真实应用使用数据行（保留原版本作为备用）
    private func realAppUsageRow(app: AppUsageData, rank: Int) -> some View {
        HStack(spacing: 12) {
            // 排名指示器
            Text("\(rank)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(getRankColor(rank))
                .frame(width: 20, height: 20)
                .background(getRankColor(rank).opacity(0.1))
                .cornerRadius(10)
            
            // 应用图标
            ZStack {
                Circle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.2))
                    .frame(width: 28, height: 28)

                Image(systemName: app.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
            }

            // 应用信息
            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                
                Text("应用")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
            }

            Spacer()

            // 使用时间
            VStack(alignment: .trailing, spacing: 2) {
                Text(app.formattedTime)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(app.usageLevel.color)
                
                // 使用等级标签
                Text(getUsageLevelText(app.usageLevel))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(app.usageLevel.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(app.usageLevel.color.opacity(0.1))
                    .cornerRadius(3)
            }
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - 屏幕使用时间相关辅助方法
    private func formatScreenTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    private func getScreenTimeColor(_ seconds: TimeInterval) -> Color {
        let hours = seconds / 3600
        switch hours {
        case 0..<2: return Color(red: 52/255, green: 199/255, blue: 89/255) // 健康
        case 2..<4: return Color(red: 255/255, green: 149/255, blue: 0/255) // 适度
        case 4..<6: return Color(red: 255/255, green: 59/255, blue: 48/255) // 过度
        default: return Color(red: 142/255, green: 142/255, blue: 147/255) // 严重
        }
    }
    
    private func getUsageLevelText(_ level: UsageLevel) -> String {
        switch level {
        case .low: return "轻度"
        case .medium: return "适度"
        case .high: return "重度"
        }
    }
    
    private func getUsageLevelText(_ seconds: TimeInterval) -> String {
        let hours = seconds / 3600
        switch hours {
        case 0..<2: return "健康使用"
        case 2..<4: return "适度使用"
        case 4..<6: return "过度使用"
        default: return "严重过度"
        }
    }
    
    private func getUsageLevelColor(_ seconds: TimeInterval) -> Color {
        let hours = seconds / 3600
        switch hours {
        case 0..<2: return Color(red: 52/255, green: 199/255, blue: 89/255)
        case 2..<4: return Color(red: 255/255, green: 149/255, blue: 0/255)
        case 4..<6: return Color(red: 255/255, green: 59/255, blue: 48/255)
        default: return Color(red: 142/255, green: 142/255, blue: 147/255)
        }
    }
    
    private func getRankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 255/255, green: 215/255, blue: 0/255) // 金色
        case 2: return Color(red: 192/255, green: 192/255, blue: 192/255) // 银色
        case 3: return Color(red: 205/255, green: 127/255, blue: 50/255) // 铜色
        default: return Color(red: 142/255, green: 142/255, blue: 147/255) // 灰色
        }
    }
    
    // MARK: - 睡眠分析视图
    private var modernSleepAnalysisView: some View {
        VStack(spacing: 16) {
            if homePageViewModel.isLoading {
                // 加载状态
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 138/255, green: 43/255, blue: 226/255)))

                    Text("正在分析睡眠数据...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if let sleepAnalysis = homePageViewModel.sleepAnalysis {
                // 显示睡眠分析结果
                sleepAnalysisContent(analysis: sleepAnalysis)
            } else {
                // 无数据状态
                VStack(spacing: 16) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(Color(red: 138/255, green: 43/255, blue: 226/255).opacity(0.6))

                    VStack(spacing: 8) {
                        Text("暂无睡眠分析")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))

                        Text("完成一次睡眠记录后将显示AI分析结果")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                            .multilineTextAlignment(.center)
                    }

                    Button(action: {
                        showingSleep.toggle()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("开始睡眠记录")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 138/255, green: 43/255, blue: 226/255), Color(red: 118/255, green: 23/255, blue: 206/255)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: Color(red: 138/255, green: 43/255, blue: 226/255).opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingSleepAnalysis.toggle()
        }
    }

    private var sleepAnalysisHeader: some View {
        // 移除标题，只保留空的视图
        EmptyView()
    }

    // 睡眠分析内容视图
    private func sleepAnalysisContent(analysis: DeepSeekSleepAnalysis) -> some View {
        VStack(spacing: 16) {
            // 睡眠质量评分
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("睡眠质量")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))

                    Text("\(Int(analysis.qualityAssessment.overallScore))分")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 138/255, green: 43/255, blue: 226/255))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("质量等级")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))

                    Text(analysis.sleepQualityText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 138/255, green: 43/255, blue: 226/255))
                }
            }

            // 睡眠阶段分布
            VStack(spacing: 12) {
                HStack {
                    Text("睡眠阶段分布")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                    Spacer()
                    Text("睡眠效率 \(String(format: "%.1f", analysis.stageAnalysis.sleepEfficiency))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                }

                HStack(spacing: 8) {
                    sleepStageBar(
                        label: "深睡",
                        percentage: analysis.stageAnalysis.deepSleepPercentage / 100.0,
                        color: Color(red: 52/255, green: 199/255, blue: 89/255)
                    )
                    sleepStageBar(
                        label: "浅睡",
                        percentage: analysis.stageAnalysis.lightSleepPercentage / 100.0,
                        color: Color(red: 90/255, green: 200/255, blue: 250/255)
                    )
                    sleepStageBar(
                        label: "REM",
                        percentage: analysis.stageAnalysis.remSleepPercentage / 100.0,
                        color: Color(red: 255/255, green: 140/255, blue: 0/255)
                    )
                }
            }

            // AI洞察和建议 - 简化版本，使用睡眠质量作为洞察基础
            VStack(spacing: 8) {
                HStack {
                    Text("睡眠分析")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                    Spacer()
                    Text("质量评估")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 153/255, green: 153/255, blue: 153/255))
                }

                HStack(spacing: 12) {
                    Image(systemName: getSleepQualityIcon(Int(analysis.qualityAssessment.overallScore)))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(getSleepQualityColor(Int(analysis.qualityAssessment.overallScore)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(analysis.sleepQualityText)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                            .lineLimit(1)

                        Text("睡眠效率: \(String(format: "%.1f", analysis.stageAnalysis.sleepEfficiency))%")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 248/255, green: 249/255, blue: 250/255))
                .cornerRadius(8)
            }

            // 查看详情按钮 - 底部居中
            HStack {
                Spacer()

                Button(action: {
                    showingSleepAnalysis.toggle()
                }) {
                    HStack(spacing: 4) {
                        Text("查看详情")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 138/255, green: 43/255, blue: 226/255))
                }

                Spacer()
            }
            .padding(.top, 8)
        }
    }
    
    // 睡眠阶段进度条
    private func sleepStageBar(label: String, percentage: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
            
            VStack(spacing: 2) {
                Rectangle()
                    .fill(color)
                    .frame(width: 20, height: max(4, CGFloat(percentage * 0.8))) // 最小高度4，最大64
                    .cornerRadius(10)
                
                Text("\(Int(percentage))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 睡眠分析辅助方法
    private func getSleepQualityIcon(_ quality: Int) -> String {
        switch quality {
        case 90...100: return "moon.stars.fill"
        case 70..<90: return "moon.fill"
        case 50..<70: return "moon"
        default: return "moon.zzz"
        }
    }
    
    private func getSleepQualityColor(_ quality: Int) -> Color {
        switch quality {
        case 90...100: return Color(red: 52/255, green: 199/255, blue: 89/255)
        case 70..<90: return Color(red: 255/255, green: 149/255, blue: 0/255)
        case 50..<70: return Color(red: 255/255, green: 59/255, blue: 48/255)
        default: return Color(red: 142/255, green: 142/255, blue: 147/255)
        }
    }

    // MARK: - 小型长按钮样式的打卡按钮
    private var modernCheckinButton: some View {
        Button(action: {
            if checkinViewModel.hasCheckedInToday {
                // 如果已打卡，显示坚持详情
                showingPersistenceDetail = true
            } else {
                // 如果未打卡，显示打卡输入界面
                showingCheckinInput = true
            }
        }) {
            HStack(spacing: 8) {
                if checkinViewModel.isCheckingIn {
                    // 加载状态
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 16, height: 16)
                } else {
                    // 图标
                    Image(systemName: checkinViewModel.hasCheckedInToday ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                // 文字
                Text(checkinViewModel.hasCheckedInToday ? "坚持详情" : "打卡")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(height: 36)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: checkinViewModel.hasCheckedInToday ?
                                [Color(red: 52/255, green: 199/255, blue: 89/255), Color(red: 45/255, green: 175/255, blue: 80/255)] :
                                [Color(red: 76/255, green: 175/255, blue: 80/255), Color(red: 56/255, green: 142/255, blue: 60/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(
                color: Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.25),
                radius: 6,
                x: 0,
                y: 3
            )
        }
        .disabled(checkinViewModel.isCheckingIn)
        .scaleEffect(isCheckinButtonPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isCheckinButtonPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isCheckinButtonPressed = pressing
        }, perform: {})

    }

    // MARK: - 应用管理数据更新

    /// 更新应用管理器的自律时间数据
    private func updateAppManagementData() {
        // 获取当前的综合自律时间（计划 + 睡眠 + 运动）
        let currentSelfDisciplineMinutes = homePageViewModel.comprehensiveSelfDisciplineTime

        // 更新应用管理器
        appUsageManager.updateSelfDisciplineTime(currentSelfDisciplineMinutes)

        print("📱 首页更新应用管理数据：综合自律时间 \(currentSelfDisciplineMinutes) 分钟")
    }

    // MARK: - 直接授权相关方法

    /// 请求授权并显示应用选择器
    private func requestAuthorizationAndShowPicker() {
        Task {
            // 先请求 Screen Time 权限
            await screenTimeManager.requestAuthorization()

            await MainActor.run {
                if screenTimeManager.isAuthorized {
                    // 同步授权状态给 AppUsageManager，并刷新使用数据
                    AppUsageManager.shared.isAuthorized = true
                    AppUsageManager.shared.refreshData()
                    // 权限获取成功，直接显示应用选择器
                    showingFamilyActivityPicker = true
                    print("📱 首页：Screen Time 权限获取成功，显示应用选择器")
                } else {
                    // 权限被拒绝，不显示任何UI，让用户留在当前页面
                    print("📱 首页：Screen Time 权限被拒绝，用户可以稍后重试")
                }
            }
        }
    }

    /// 处理用户选择的应用和类别
    private func handleAppSelectionChange() {
        print("📱 [首页FamilyActivityPicker] 用户选择了应用和类别:")
        print("📱 [首页FamilyActivityPicker] 应用数量: \(selectedAppsAndCategories.applications.count)")
        print("📱 [首页FamilyActivityPicker] 类别数量: \(selectedAppsAndCategories.categories.count)")

        // 只有当用户实际选择了应用时才处理
        guard !selectedAppsAndCategories.applications.isEmpty else {
            print("📱 [首页FamilyActivityPicker] 用户未选择任何应用，跳过处理")
            return
        }

        // 1) 保存选择的应用信息（不自动创建规则）
        saveSelectedApplications()

        // 2) 立即将选择应用到系统的 ManagedSettings（需要已授权）
        Task { [selection = selectedAppsAndCategories] in
            await appRestrictionManager.applySelection(appsAndCategories: selection)
        }

        // 3) 保存选择状态
        saveAppSelection()

        // 4) 刷新 UI 所需数据
        Task {
            await MainActor.run {
                appUsageManager.refreshData()
                // 显示成功反馈
                showingAuthorizationSuccess = true

                // 5) 先关闭系统选择器，等其真正消失后再打开“应用管理”页（见 .onChange 监听）
                // 应用管理页面已删除
                showingFamilyActivityPicker = false
            }
        }
    }

    /// 保存用户选择的应用信息（不自动创建规则）
    private func saveSelectedApplications() {
        // 使用 AppUsageManager 的保存方法
        appUsageManager.saveSelectedApplications(selectedAppsAndCategories.applications)
    }

    /// 处理健康管家按钮点击事件
    private func handleHealthManagerAction() {
        // 健康管家功能暂未实现，显示提示

            // 同步授权状态给 AppUsageManager，并刷新使用数据（供首页“应用使用”面板展示）
        print("📱 健康管家功能即将上线")
        // 可以在这里添加健康管家相关的功能
    }

    // MARK: - 应用选择状态保存和恢复

    /// 保存应用选择状态
    private func saveAppSelection() {
        // 保存应用数量，用于判断是否有选择
        let appCount = selectedAppsAndCategories.applications.count
        let categoryCount = selectedAppsAndCategories.categories.count

        UserDefaults.standard.set(appCount, forKey: "saved_app_selection_count")
        UserDefaults.standard.set(categoryCount, forKey: "saved_category_selection_count")
        UserDefaults.standard.set(Date(), forKey: "app_selection_save_time")

        print("📱 已保存应用选择状态：\(appCount) 个应用，\(categoryCount) 个类别")
    }

    /// 恢复应用选择状态
    private func restoreAppSelection() {
        let appCount = UserDefaults.standard.integer(forKey: "saved_app_selection_count")
        let categoryCount = UserDefaults.standard.integer(forKey: "saved_category_selection_count")

        if appCount > 0 || categoryCount > 0 {
            // 有之前的选择，但由于 FamilyActivitySelection 无法直接序列化，
            // 我们通过检查 AppUsageManager 中的解锁规则来判断是否需要重新选择
            if appUsageManager.appUnlockStatuses.isEmpty {
                print("📱 检测到之前有应用选择但当前无解锁规则，可能需要重新选择应用")
            } else {
                print("📱 恢复应用选择状态：\(appCount) 个应用，\(categoryCount) 个类别")
            }
        }
    }
}

// MARK: - 滚动偏移量监听（优化实现）
// ScrollOffsetPreferenceKey 在 SharedTypes.swift 中定义

struct NewMainHomeView_Previews: PreviewProvider {
    static var previews: some View {
        NewMainHomeView()
    }
}


