import SwiftUI
import MapKit
import CoreMotion
import Combine


struct KeepStyleWorkoutLiveView: View {
    let workoutType: WorkoutType
    let workoutMode: WorkoutMode
    let workoutTarget: WorkoutTarget?

    // 状态管理
    @State private var isActive = true
    @State private var isPaused = false
    @State private var showEndAlert = false
    @State private var showWorkoutCompletion = false
    @State private var isDataPanelExpanded = false
    @State private var currentDataPage = 0
    @State private var isMuted = false

    // 锁屏和拍照功能 - 使用ObservedObject观察共享实例
    @ObservedObject private var lockManager = WorkoutScreenLockManager.shared
    @ObservedObject private var cameraManager = WorkoutCameraManager.shared
    @State private var showCameraView = false

    // AI教练服务 - 使用ObservedObject观察共享实例
    @ObservedObject private var aiCoachService = WorkoutAICoachService.shared

    // 使用苹果地图定位服务
    @ObservedObject private var locationManager = AppleMapService.shared

    // 使用运动数据管理器获取数据
    @ObservedObject private var unifiedDataManager = WorkoutDataManager.shared

    // API统计数据管理器
    @ObservedObject private var apiStatsManager = APIBasedWorkoutStatsManager.shared

    // 地图控制状态变量
    @State private var shouldCenterOnLocation = false
    @State private var mapRegion: MKCoordinateRegion?
    @State private var isSatelliteMode = false
    @State private var hasInitiallyCentered = false  // 首次获取定位后自动居中50米
    @State private var isFollowingUser = false       // 长按定位按钮切换跟随模式

    // 运动数据
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    @State private var dataUpdateTimer: Timer? // 数据同步定时器

    @Environment(\.presentationMode) var presentationMode

    // 目标完成状态
    @State private var isTargetCompleted = false

    // AI教练相关状态变量
    @State private var aiAnalysisTimer: Timer?
    @State private var lastAIGuidanceTime: Date?
    
    // 初始化方法
    init(workoutType: WorkoutType, workoutMode: WorkoutMode, workoutTarget: WorkoutTarget? = nil) {
        self.workoutType = workoutType
        self.workoutMode = workoutMode
        self.workoutTarget = workoutTarget
    }

    var body: some View {
        ZStack {
            if lockManager.isScreenLocked {
                // 锁屏界面
                WorkoutLockScreenView(
                    lockManager: lockManager,
                    cameraManager: cameraManager,
                    lockScreenData: createLockScreenData(),
                    onUnlock: {
                        lockManager.unlockScreen()
                    },
                    onTakePhoto: {
                        if lockManager.allowCameraInLockScreen {
                            showCameraView = true
                        }
                    }
                )
            } else {
                // 正常运动界面
                normalWorkoutView
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .asSubView() // 隐藏自定义 TabBar
        .alert("结束运动", isPresented: $showEndAlert) {
            Button("取消", role: .cancel) { }
            Button("确认结束", role: .destructive) {
                endWorkout()
            }
        } message: {
            Text("确定要结束本次运动吗？运动数据将被保存。")
        }
        .fullScreenCover(isPresented: $showWorkoutCompletion) {
            WorkoutCompletionView(
                workoutSummary: createWorkoutSummary(),
                isPresented: $showWorkoutCompletion
            ) {
                // 完成回调 - 关闭整个运动会话
                presentationMode.wrappedValue.dismiss()
            }
        }
        .fullScreenCover(isPresented: $showCameraView) {
            WorkoutCameraView(
                cameraManager: cameraManager,
                workoutData: createWorkoutPhotoData(),
                onPhotoTaken: { image in
                    // 处理拍摄的照片
                    print("📸 照片拍摄完成")
                }
            )
        }
        .onAppear {
            startWorkout()
            setupLockManager()

            // 立即检查并设置地图区域，避免延迟导致的缩放动画
            if let loc = locationManager.currentLocation {
                let region = MKCoordinateRegion(
                    center: loc.coordinate,
                    latitudinalMeters: 50,
                    longitudinalMeters: 50
                )
                mapRegion = region
                hasInitiallyCentered = true
                print("🎯 Keep页：立即设置50米视野 -> \(loc.coordinate)")
            } else {
                // 如果当前位置不可用，监听位置更新
                setupInitialLocationObserver()
            }

            // 跟随模式：开启时每秒检查一次，自动以50米视野跟随
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                guard isFollowingUser, let loc = locationManager.currentLocation else { return }
                let region = MKCoordinateRegion(
                    center: loc.coordinate,
                    latitudinalMeters: 50,
                    longitudinalMeters: 50
                )
                mapRegion = region
                shouldCenterOnLocation = true
            }
        }
        .onDisappear {
            stopWorkout()
        }
        .onTapGesture {
            // 更新交互时间，重置自动锁屏计时器
            lockManager.updateLastInteractionTime()
        }
    }
    
    // MARK: - 全屏地图视图
    private var fullScreenMapView: some View {
        ZStack {
            // 苹果地图
            AppleMapView(
                zoomLevel: 17.0,
                showUserLocation: true,
                mapType: isSatelliteMode ? .satellite : .standard,
                shouldCenterOnLocation: $shouldCenterOnLocation,
                mapRegion: $mapRegion,
                routePoints: locationManager.routePoints,
                currentLocation: locationManager.currentLocation
            )
            .ignoresSafeArea(.all)

            // 地图控制按钮
            mapControlButtons


        }
    }
    
    // MARK: - 顶部状态栏
    private var topStatusBar: some View {
        HStack {
            // GPS信号检测 - 移到原来搜索图标的位置
            GPSSignalStatusView()

            Spacer()

            // 声音开关按钮
            Button(action: {
                isMuted.toggle()
            }) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.2.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(isMuted ? 0.6 : 0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - 地图控制按钮 (右侧垂直居中)
    private var mapControlButtons: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                VStack(spacing: 16) {
                    // 定位按钮
                    Button(action: centerMapOnUser) {
                        Image(systemName: isFollowingUser ? "location.north.line.fill" : "location.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background((isFollowingUser ? Color.green : Color.blue).opacity(0.85))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    // 长按切换“跟随模式”
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                            isFollowingUser.toggle()
                            let impact = UIImpactFeedbackGenerator(style: .soft)
                            impact.impactOccurred()
                            print("🧭 跟随模式: \(isFollowingUser ? "开启" : "关闭")")
                        }
                    )

                    // 卫星图切换按钮
                    Button(action: toggleMapType) {
                        Image(systemName: isSatelliteMode ? "globe.asia.australia.fill" : "globe.asia.australia")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(isSatelliteMode ? Color.green.opacity(0.8) : Color.gray.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.trailing, 20)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
    // MARK: - 底部数据面板 - 统一视图
    private var bottomDataPanel: some View {
        VStack(spacing: 0) {
            // 拖拽指示器
            VStack(spacing: 12) {
                // 拖拽条
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                // 状态指示器
                HStack {
                    // 运动状态
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isPaused ? Color.orange : Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isPaused ? 1.0 : 1.2)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPaused)

                        Text(isPaused ? "已暂停" : "运动中")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // 展开提示
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isDataPanelExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isDataPanelExpanded ? "收起" : "详情")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))

                            Image(systemName: isDataPanelExpanded ? "chevron.down" : "chevron.up")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            // 数据内容区域
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // 根据展开状态显示不同的数据视图
                    if isDataPanelExpanded {
                        // 展开数据视图 - 只显示高级运动分析数据
                        expandedDataDisplay
                    } else {
                        // 基础数据视图 - 显示基础运动指标
                        compactDataDisplay
                    }
                }
            }
            .frame(maxHeight: isDataPanelExpanded ? UIScreen.main.bounds.height * 0.75 : 120)

            // 控制按钮区域 - 只在面板展开时显示
            if isDataPanelExpanded {
                controlButtons
                    .padding(.top, 4)
            }
        }
        .frame(maxHeight: isDataPanelExpanded ? UIScreen.main.bounds.height * 0.85 : 240)
        .background(modernPanelBackground)
        .gesture(panelDragGesture)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isDataPanelExpanded)
    }

    // MARK: - 现代化面板背景
    private var modernPanelBackground: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 24,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 24
        )
        .fill(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.88),
                    Color.black.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            // 顶部高光效果
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24
            )
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -8)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: - 面板拖拽手势 - 简化版本
    private var panelDragGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                let translation = value.translation.height

                // 简化的拖拽逻辑
                if translation < -50 {
                    // 向上滑动超过50点，展开面板
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isDataPanelExpanded = true
                    }
                    // 添加触觉反馈
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                } else if translation > 50 {
                    // 向下滑动超过50点，收起面板
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isDataPanelExpanded = false
                    }
                    // 添加触觉反馈
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }
            }
    }
    
    // MARK: - 紧凑数据显示 - 优化空间利用
    private var compactDataDisplay: some View {
        VStack(spacing: 8) {
            // 目标进度器（如果有目标的话）
            if let target = workoutTarget {
                targetProgressView(target)
                    .padding(.bottom, 4)
            }
            
            // 主要数据 - 距离，更紧凑的设计
            VStack(spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(String(format: "%.2f", unifiedDataManager.realTimeDistance))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("km")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .offset(y: -2)
                }

                Text("总距离")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            // 次要数据 - 更紧凑的卡片布局
            HStack(spacing: 8) {
                // 时长卡片
                compactDataCard(
                    value: formatTime(elapsedTime),
                    label: "总时长",
                    color: .white,
                    backgroundColor: Color.white.opacity(0.08)
                )

                // 配速卡片
                compactDataCard(
                    value: formatPace(locationManager.getCurrentPace()),
                    label: "实时配速",
                    color: Color(hex: "#4CAF50"),
                    backgroundColor: Color(hex: "#4CAF50").opacity(0.15)
                )

                // 卡路里卡片 - 使用真实传感器数据
                compactDataCard(
                    value: String(format: "%.0f", unifiedDataManager.realTimeCalories),
                    label: "卡路里",
                    color: .orange,
                    backgroundColor: Color.orange.opacity(0.15)
                )
            }

            // AI 教练推荐卡片 - 紧凑版本
            if let analysisResult = aiCoachService.lastAnalysisResult {
                compactAIGuidanceCard(guidance: analysisResult.guidance)
                    .padding(.top, 4)
            }

            // 今日累计数据 - 云端数据 + 当前运动数据
            VStack(spacing: 4) {
                Text("今日运动数据")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)

                HStack(spacing: 8) {
                    // 今日步数
                    todayStatsCard(
                        value: "\(unifiedDataManager.todayTotalSteps)",
                        label: "今日步数",
                        color: .blue,
                        backgroundColor: Color.blue.opacity(0.1)
                    )

                    // 今日距离
                    todayStatsCard(
                        value: String(format: "%.1f", unifiedDataManager.todayTotalDistance),
                        label: "今日距离",
                        color: .green,
                        backgroundColor: Color.green.opacity(0.1)
                    )

                    // 今日卡路里
                    todayStatsCard(
                        value: String(format: "%.0f", unifiedDataManager.todayTotalCalories),
                        label: "消耗卡路里",
                        color: .red,
                        backgroundColor: Color.red.opacity(0.1)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - 今日统计数据卡片
    private func todayStatsCard(value: String, label: String, color: Color, backgroundColor: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
        )
    }

    // MARK: - 紧凑数据卡片
    private func compactDataCard(value: String, label: String, color: Color, backgroundColor: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
    }

    // MARK: - 紧凑版 AI 指导卡片
    private func compactAIGuidanceCard(guidance: WorkoutGuidance) -> some View {
        HStack(spacing: 8) {
            // AI 图标
            Image(systemName: "brain.head.profile")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 20)

            // 指导内容
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("AI 教练")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Spacer()

                    // 优先级标签
                    Text(guidance.priorityText)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color(hex: guidance.priorityColor).opacity(0.3))
                        .clipShape(Capsule())
                }

                Text(guidance.message)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            // 音频播放指示器
            if aiCoachService.isAudioPlaying {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                    .scaleEffect(1.1)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: aiCoachService.isAudioPlaying)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 现代化数据卡片 (用于展开视图)
    private func modernDataCard(value: String, label: String, color: Color, backgroundColor: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
    }
    
    // MARK: - 展开数据显示 - Keep风格重新设计
    private var expandedDataDisplay: some View {
        VStack(spacing: 16) {
            // 分页数据视图
            TabView(selection: $currentDataPage) {
                // 第一页：核心数据
                coreDataPage
                    .tag(0)

                // 第二页：详细统计
                detailedStatsPage
                    .tag(1)

                // 第三页：运动分析
                analysisPage
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 400) // 增加高度以确保数据完全显示

            // 页面指示器
            modernPageIndicator
        }
        .padding(.horizontal, 20)
    }



    // MARK: - 核心数据页面
    private var coreDataPage: some View {
        VStack(spacing: 20) {
            // 页面标题
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(Color(hex: "#4CAF50"))

                Text("核心数据")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            // 核心数据网格 - 移除重复的基础数据，只显示扩展数据
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                enhancedDataCard(
                    title: "平均速度",
                    value: String(format: "%.1f", locationManager.averageSpeed * 3.6),
                    subtitle: "km/h",
                    icon: "gauge.medium",
                    color: .white,
                    accentColor: .blue
                )

                enhancedDataCard(
                    title: "最大速度",
                    value: String(format: "%.1f", locationManager.averageSpeed * 3.6),
                    subtitle: "km/h",
                    icon: "bolt.fill",
                    color: .white,
                    accentColor: .yellow
                )

                enhancedDataCard(
                    title: "平均配速",
                    value: formatPace(locationManager.getAveragePace()),
                    subtitle: "min/km",
                    icon: "speedometer",
                    color: .white,
                    accentColor: .cyan
                )

                enhancedDataCard(
                    title: "路线点数",
                    value: "\(locationManager.routePoints.count)",
                    subtitle: "GPS点",
                    icon: "location.fill",
                    color: .white,
                    accentColor: .red
                )
            }
        }
    }

    // MARK: - 详细统计页面
    private var detailedStatsPage: some View {
        VStack(spacing: 20) {
            // 页面标题
            HStack {
                Image(systemName: getWorkoutSpecificIcon())
                    .font(.title2)
                    .foregroundColor(Color(hex: "#4CAF50"))

                Text(getDetailedStatsTitle())
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            // 统计数据网格 - 根据运动类型显示不同指标
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(getWorkoutSpecificStatCards(), id: \.title) { card in
                    statisticCard(
                        title: card.title,
                        value: card.value,
                        unit: card.unit,
                        icon: card.icon,
                        color: card.color
                    )
                }
            }
        }
    }

    /// 获取运动类型特定的图标
    private func getWorkoutSpecificIcon() -> String {
        return workoutType.icon
    }

    /// 获取详细统计标题
    private func getDetailedStatsTitle() -> String {
        switch workoutType {
        case .walking:
            return "步行统计"
        case .running:
            return "跑步统计"
        case .cycling:
            return "骑行统计"
        case .hiking:
            return "徒步统计"
        case .swimming:
            return "游泳统计"
        case .yoga:
            return "瑜伽统计"
        case .strength:
            return "力量训练统计"
        case .fitness:
            return "健身统计"
        case .basketball:
            return "篮球统计"
        case .football:
            return "足球统计"
        case .tennis:
            return "网球统计"
        case .badminton:
            return "羽毛球统计"
        case .pingpong:
            return "乒乓球统计"
        case .climbing:
            return "攀岩统计"
        case .dancing:
            return "舞蹈统计"
        case .boxing:
            return "拳击统计"
        case .martialArts:
            return "武术统计"
        case .pilates:
            return "普拉提统计"
        case .aerobics:
            return "有氧运动统计"
        case .other:
            return "运动统计"
        }
    }

    /// 获取运动类型特定的统计卡片
    private func getWorkoutSpecificStatCards() -> [(title: String, value: String, unit: String, icon: String, color: Color)] {
        switch workoutType {
        case .walking:
            return [
                ("步行速度", String(format: "%.1f", (locationManager.mapBasedDistance / max(locationManager.duration / 3600.0, 0.01))), "km/h", "speedometer", Color(hex: "#4CAF50")),
                ("步数", String(unifiedDataManager.realTimeSteps), "步", "figure.walk", .purple),
                ("步频", String(format: "%.0f", unifiedDataManager.realTimeCadence), "步/分", "metronome", .blue),
                ("消耗脂肪", String(format: "%.1f", unifiedDataManager.realTimeCalories * 0.12), "g", "flame.fill", .orange),
                ("心率区间", getHeartRateZone(), "", "heart.fill", .red),
                ("步行效率", String(format: "%.1f", Double(unifiedDataManager.realTimeSteps) / max(unifiedDataManager.realTimeCalories, 1)), "步/卡", "chart.line.uptrend.xyaxis", .cyan)
            ]
        case .running:
            return [
                ("最快配速", formatPace(locationManager.getBestPace()), "", "timer", Color(hex: "#4CAF50")),
                ("步数", String(unifiedDataManager.realTimeSteps), "步", "figure.run", .purple),
                ("步频", String(format: "%.0f", unifiedDataManager.realTimeCadence), "步/分", "metronome", .blue),
                ("平均步幅", String(format: "%.0f", (locationManager.mapBasedDistance * 1000) / max(Double(unifiedDataManager.realTimeSteps), 1)), "cm", "ruler", .cyan),
                ("训练负荷", getTrainingLoad(), "", "bolt.fill", .yellow),
                ("跑步效率", String(format: "%.2f", locationManager.mapBasedDistance / max(locationManager.duration / 3600.0, 0.01)), "km/h", "speedometer", .green)
            ]
        case .cycling:
            return [
                ("平均时速", String(format: "%.1f", (locationManager.mapBasedDistance / max(locationManager.duration / 3600.0, 0.01))), "km/h", "speedometer", Color(hex: "#4CAF50")),
                ("最高时速", String(format: "%.1f", locationManager.maxSpeed * 3.6), "km/h", "bolt.fill", .yellow), // 修复：使用maxSpeed而不是averageSpeed
                ("估算功率", String(format: "%.0f", calculateCyclingPower()), "W", "bolt.circle.fill", .orange), // 修复：使用更准确的功率计算
                ("功率密度", String(format: "%.1f", calculateCyclingPower() / 70.0), "W/kg", "scalemass.fill", .purple), // 修复：基于实际功率计算
                ("踏频", String(format: "%.0f", unifiedDataManager.realTimeCadence * 0.6), "转/分", "metronome", .blue),
                ("骑行效率", String(format: "%.1f", locationManager.mapBasedDistance / max(locationManager.duration / 3600.0, 0.01)), "km/h", "chart.line.uptrend.xyaxis", .cyan)
            ]
        case .hiking:
            return [
                ("徒步配速", formatPace(locationManager.getAveragePace()), "", "timer", Color(hex: "#4CAF50")),
                ("步数", String(unifiedDataManager.realTimeSteps), "步", "figure.hiking", .purple),
                ("爬升强度", String(format: "%.0f", 50.0), "m/km", "mountain.2.fill", .brown),
                ("爬升速度", String(format: "%.0f", 25.0), "m/h", "arrow.up.circle.fill", .orange),
                ("地形难度", getTerrainDifficulty(), "", "map.fill", .red),
                ("徒步效率", String(format: "%.1f", Double(unifiedDataManager.realTimeSteps) / max(50.0, 1)), "步/m", "chart.line.uptrend.xyaxis", .cyan)
            ]
        case .swimming:
            return [
                ("游泳配速", formatPace(locationManager.getAveragePace()), "", "timer", Color(hex: "#4CAF50")),
                ("游泳时长", formatTime(Int(locationManager.duration)), "", "clock.fill", .blue),
                ("平均速度", String(format: "%.1f", locationManager.mapBasedDistance * 1000 / max(locationManager.duration, 1)), "m/s", "speedometer", .cyan),
                ("游泳强度", "中等", "", "bolt.fill", .orange),
                ("消耗能量", String(format: "%.0f", unifiedDataManager.realTimeCalories), "kcal", "flame.fill", .red),
                ("游泳距离", String(format: "%.0f", locationManager.mapBasedDistance * 1000), "m", "ruler", .purple)
            ]
        case .yoga:
            return [
                ("练习时长", formatTime(Int(locationManager.duration)), "", "clock.fill", .blue),
                ("消耗热量", String(format: "%.0f", unifiedDataManager.realTimeCalories), "kcal", "flame.fill", .red),
                ("练习强度", "轻度", "", "bolt.fill", .green),
                ("心率区间", getHeartRateZone(), "", "heart.fill", .red),
                ("放松时间", formatTime(Int(locationManager.duration * 0.3)), "", "moon.fill", .purple),
                ("活跃时间", formatTime(Int(locationManager.duration * 0.7)), "", "sun.max.fill", .orange)
            ]
        case .strength:
            return [
                ("训练时长", formatTime(Int(locationManager.duration)), "", "clock.fill", .blue),
                ("消耗热量", String(format: "%.0f", unifiedDataManager.realTimeCalories), "kcal", "flame.fill", .red),
                ("训练强度", "高强度", "", "bolt.fill", .red),
                ("休息时间", formatTime(Int(locationManager.duration * 0.4)), "", "pause.fill", .gray),
                ("活跃时间", formatTime(Int(locationManager.duration * 0.6)), "", "play.fill", .green),
                ("肌肉群", "全身", "", "figure.strengthtraining.traditional", .brown)
            ]
        default:
            return [
                ("运动时长", formatTime(Int(locationManager.duration)), "", "clock.fill", .blue),
                ("消耗热量", String(format: "%.0f", unifiedDataManager.realTimeCalories), "kcal", "flame.fill", .red),
                ("平均强度", "中等", "", "bolt.fill", .orange),
                ("活跃时间", formatTime(Int(locationManager.duration)), "", "play.fill", .green),
                ("总距离", String(format: "%.2f", locationManager.mapBasedDistance), "km", "ruler", .purple),
                ("平均速度", String(format: "%.1f", locationManager.mapBasedDistance / max(locationManager.duration / 3600.0, 0.01)), "km/h", "speedometer", .cyan)
            ]
        }
    }

    /// 获取心率区间
    private func getHeartRateZone() -> String {
        // 使用真实心率数据
        let realHeartRate = unifiedDataManager.realTimeHeartRate
        let maxHR = 220 - 30 // 假设30岁，实际应该从用户配置获取
        let hrPercentage = Double(realHeartRate) / Double(maxHR)

        switch hrPercentage {
        case 0.0..<0.5:
            return "轻松"
        case 0.5..<0.6:
            return "有氧"
        case 0.6..<0.7:
            return "燃脂"
        case 0.7..<0.8:
            return "无氧"
        case 0.8..<0.9:
            return "极限"
        default:
            return "最大"
        }
    }

    /// 获取训练负荷
    private func getTrainingLoad() -> String {
        let intensity = 0.7 // 假设强度
        let load = intensity * (locationManager.duration / 60.0)

        switch load {
        case 0..<30:
            return "轻松"
        case 30..<60:
            return "中等"
        case 60..<90:
            return "高强度"
        default:
            return "极高"
        }
    }

    /// 获取地形难度
    private func getTerrainDifficulty() -> String {
        let elevationGain = 50.0 / max(locationManager.mapBasedDistance, 0.1)

        switch elevationGain {
        case 0..<50:
            return "平缓"
        case 50..<100:
            return "轻微"
        case 100..<200:
            return "中等"
        case 200..<300:
            return "困难"
        default:
            return "极难"
        }
    }

    // MARK: - 运动分析页面 - 只显示AI教练推荐
    private var analysisPage: some View {
        VStack(spacing: 20) {
            // 页面标题
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.orange)

                Text("AI运动教练")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // AI服务状态指示器
                aiServiceStatusIndicator
            }

            // 只显示AI教练推荐内容
            if let analysisResult = aiCoachService.lastAnalysisResult {
                aiCoachRecommendationUI(analysisResult)
            } else {
                // AI分析状态
                if aiCoachService.isAnalyzing {
                    aiAnalyzingIndicator
                } else {
                    // 显示等待AI分析的提示
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40))
                            .foregroundColor(.orange.opacity(0.6))

                        Text("AI教练正在准备推荐...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(32)
                }
            }
        }
    }

    // MARK: - AI服务状态指示器
    private var aiServiceStatusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(aiCoachService.serviceStatus.color)
                .frame(width: 8, height: 8)
                .scaleEffect(aiCoachService.isAnalyzing ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                          value: aiCoachService.isAnalyzing)

            Text(aiCoachService.serviceStatus.displayText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - 现代化页面指示器
    private var modernPageIndicator: some View {
        VStack(spacing: 8) {
            // 圆点指示器
            HStack(spacing: 8) {
                ForEach(0..<getTotalPages(), id: \.self) { index in
                    Circle()
                        .fill(index == currentDataPage ? Color(hex: "#4CAF50") : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentDataPage ? 1.3 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentDataPage)
                }
            }

            // 页面标题
            Text(getPageTitle(for: currentDataPage))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .animation(.easeInOut(duration: 0.3), value: currentDataPage)
        }
        .padding(.top, 24) // 下移24px
    }

    // MARK: - 增强数据卡片
    private func enhancedDataCard(title: String, value: String, subtitle: String, icon: String, color: Color, accentColor: Color) -> some View {
        VStack(spacing: 8) {
            // 图标和标题
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }

            // 数值
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - 统计卡片
    private func statisticCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)

            VStack(spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - AI教练推荐UI
    private func aiCoachRecommendationUI(_ result: WorkoutAnalysisResult) -> some View {
        VStack(spacing: 16) {
            // AI教练推荐卡片
            aiGuidanceCard(guidance: result.guidance)

            // 音频播放状态
            if aiCoachService.isAudioPlaying {
                audioPlaybackIndicator
            }
        }
    }



    // MARK: - AI指导卡片
    private func aiGuidanceCard(guidance: WorkoutGuidance) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行
            HStack(spacing: 8) {
                Image(systemName: guidance.priorityIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: guidance.priorityColor))

                Text("AI教练指导")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // 优先级标签
                Text(guidance.priorityText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: guidance.priorityColor).opacity(0.2))
                    .clipShape(Capsule())
            }

            // AI指导内容
            Text(guidance.message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(4)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: guidance.priorityColor).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: guidance.priorityColor).opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - AI分析项目
    private func aiAnalysisItem(title: String, item: AnalysisItem, icon: String) -> some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: item.statusColor))
                .frame(width: 20)

            // 内容
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    // 状态标签
                    Text(item.statusText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color(hex: item.statusColor).opacity(0.2))
                        .clipShape(Capsule())
                }

                Text(item.message)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: item.statusColor).opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    // MARK: - AI分析中指示器
    private var aiAnalyzingIndicator: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))

            Text("AI教练正在分析运动数据...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - 音频播放指示器
    private var audioPlaybackIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 12))
                .foregroundColor(.blue)
                .scaleEffect(aiCoachService.isAudioPlaying ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                          value: aiCoachService.isAudioPlaying)

            Text("正在播放AI语音指导")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
                )
        )
    }





    // MARK: - 辅助方法
    private func getPageTitle(for index: Int) -> String {
        switch index {
        case 0: return "核心数据"
        case 1: return "详细统计"
        case 2: return "运动分析"
        default: return ""
        }
    }

    private func getTotalPages() -> Int {
        return 3
    }
    
    // MARK: - 目标进度器（优化版本）
    private func targetProgressView(_ target: WorkoutTarget) -> some View {
        VStack(spacing: 14) {
            // 顶部信息行 - 增强视觉层次
            HStack {
                // 目标类型图标 - 更大更醒目
                ZStack {
                    Circle()
                        .fill(isTargetCompleted ? .green.opacity(0.25) : workoutType.primaryColor.opacity(0.25))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: isTargetCompleted ? 
                                            [.green.opacity(0.8), .green.opacity(0.4)] :
                                            [workoutType.primaryColor.opacity(0.8), workoutType.primaryColor.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    
                    Image(systemName: target.type.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isTargetCompleted ? .green : workoutType.primaryColor)
                        .scaleEffect(isTargetCompleted ? 1.1 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isTargetCompleted)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(target.type.displayName)目标")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(target.displayValue) \(target.type.unit)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // 进度百分比 - 增强显示
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(Int(calculateProgress(for: target) * 100))")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(isTargetCompleted ? .green : .white)
                        
                        Text("%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isTargetCompleted ? .green.opacity(0.8) : .white.opacity(0.7))
                            .offset(y: -1)
                    }
                    
                    Text("完成度")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // 增强的进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景条 - 更现代的设计
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.4))
                        .frame(height: 8)
                        .overlay(
                            // 内部高光
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                    
                    // 进度条 - 增强的渐变效果
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: isTargetCompleted ? 
                                    [.green, Color(red: 0.3, green: 0.8, blue: 0.3), .green.opacity(0.8)] : 
                                    [workoutType.primaryColor, workoutType.primaryColor.opacity(0.9), workoutType.primaryColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(calculateProgress(for: target), 1.0), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: calculateProgress(for: target))
                        .overlay(
                            // 进度条顶部光泽效果
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .clear, .white.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: geometry.size.width * min(calculateProgress(for: target), 1.0), height: 8)
                        )
                        .shadow(color: isTargetCompleted ? .green.opacity(0.5) : workoutType.primaryColor.opacity(0.3), 
                               radius: 4, x: 0, y: 2)
                    
                    // 增强的进度指示器
                    if calculateProgress(for: target) > 0.03 {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 12, height: 12)
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                            
                            Circle()
                                .fill(isTargetCompleted ? .green : workoutType.primaryColor)
                                .frame(width: 6, height: 6)
                        }
                        .offset(x: (geometry.size.width * min(calculateProgress(for: target), 1.0)) - 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: calculateProgress(for: target))
                    }
                }
            }
            .frame(height: 8)
            
            // 目标完成提示 - 增强的庆祝效果
            if isTargetCompleted {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(.green.opacity(0.2))
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    Text("🎉 目标达成！运动将在3秒后自动结束")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.green.opacity(0.4), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .top)))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isTargetCompleted)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(
            // 增强的渐变背景
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: isTargetCompleted ? 
                            [Color.green.opacity(0.2), Color.green.opacity(0.08), Color.green.opacity(0.05)] :
                            [Color.white.opacity(0.15), Color.white.opacity(0.08), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // 外边框渐变
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: isTargetCompleted ?
                                    [.green.opacity(0.6), .green.opacity(0.3), .green.opacity(0.1)] :
                                    [workoutType.primaryColor.opacity(0.5), workoutType.primaryColor.opacity(0.3), workoutType.primaryColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .overlay(
                    // 内部高光
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .padding(1)
                )
        )
        .shadow(color: isTargetCompleted ? .green.opacity(0.2) : .black.opacity(0.15), 
               radius: 12, x: 0, y: 6)
    }
    
    // 计算目标进度
    private func calculateProgress(for target: WorkoutTarget) -> Double {
        switch target.type {
        case .distance:
            return unifiedDataManager.realTimeDistance / target.value
        case .duration:
            return Double(elapsedTime) / (target.value * 60) // 转换为秒
        case .calories:
            return unifiedDataManager.realTimeCalories / target.value
        case .pace:
            let currentPace = locationManager.getCurrentPace()
            if currentPace > 0 && target.value > 0 {
                // 配速目标：当前配速越接近目标配速，进度越高
                let paceProgress = min(target.value / currentPace, 1.0)
                return paceProgress
            }
            return 0.0
        }
    }

    
    // MARK: - 控制按钮
    private var controlButtons: some View {
        VStack(spacing: 16) {
            if isPaused {
                // 暂停状态下显示继续和结束按钮
                HStack(spacing: 20) {
                    // 继续运动按钮
                    Button(action: {
                        resumeWorkout()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 18))
                            Text("继续")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 120, height: 50)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }

                    // 结束运动按钮 - 点击显示确认弹窗
                    Button(action: {
                        showEndAlert = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 18))
                            Text("结束")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 120, height: 50)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
            } else {
                // 正常状态下的控制按钮
                HStack(spacing: 0) {
                    // 锁屏按钮 - 增加左右间距
                    Button(action: {
                        lockManager.lockScreen()
                    }) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 25) // 左侧间距
                    .padding(.trailing, 15) // 右侧间距

                    Spacer()

                    // 主控制按钮 - Keep风格大圆按钮
                    Button(action: togglePause) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 80, height: 80)
                            .background(Color.white)
                            .clipShape(Circle())
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPaused)
                    }
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

                    Spacer()

                    // 相机按钮 - 增加左右间距
                    Button(action: takePhoto) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.green.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 15) // 左侧间距
                    .padding(.trailing, 25) // 右侧间距
                }
            }
        }
        .padding(.vertical, 20)
    }





    // MARK: - 功能方法

    private func startWorkout() {
        // 确保授权，然后在获得授权后再启动追踪
        locationManager.requestLocationPermission()
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startTracking()
        } else {
            print("⏳ 等待定位授权后再启动追踪")
        }

        // 请求传感器权限
        requestSensorPermissionsIfNeeded()

        // 启动运动数据管理器获取真实传感器数据
        unifiedDataManager.startWorkout(type: workoutType)

        // 启动AI教练服务 - 包含运动开始首问
        let userId = AuthManager.shared.getUserInfo()?.id.description
        aiCoachService.startAICoaching(for: workoutType, userId: userId)

        // 启动AI分析定时器
        startAIAnalysisTimer()

        // 刷新统计数据（使用缓存机制）
        Task {
            await apiStatsManager.refreshStats()
        }

        startTimer()

        // 启动数据同步定时器（每秒同步一次GPS距离数据到WorkoutDataManager）
        startDataUpdateTimer()

        isActive = true
        isPaused = false
        print("🚀 开始运动 - 类型: \(workoutType.rawValue)")
        print("📊 运动数据管理器已启动")
        print("🔄 GPS距离数据同步定时器已启动")
    }

    private func stopWorkout() {
        locationManager.stopTracking()

        // 停止运动数据管理器
        unifiedDataManager.stopWorkout()

        // 停止AI教练服务
        aiCoachService.stopAICoaching()

        // 停止AI分析定时器
        stopAIAnalysisTimer()

        // 停止数据同步定时器
        stopDataUpdateTimer()

        stopTimer()
        isActive = false
        print("🛑 停止运动")
        print("🔄 GPS距离数据同步定时器已停止")
    }

    private func togglePause() {
        if isPaused {
            resumeWorkout()
        } else {
            pauseWorkout()
        }
    }

    private func pauseWorkout() {
        isPaused = true
        locationManager.pauseTracking()
        stopTimer()
        print("暂停运动")
    }

    private func resumeWorkout() {
        isPaused = false
        locationManager.resumeTracking()
        startTimer()
        print("恢复运动")
    }

    private func endWorkout() {
        stopWorkout()
        // 显示运动完成页面而不是直接关闭
        showWorkoutCompletion = true
    }

    /// 手动触发AI分析
    private func triggerManualAIAnalysis() {
        Task {
            do {
                try await aiCoachService.analyzeWorkoutData(
                    workoutType: workoutType,
                    heartRate: unifiedDataManager.realTimeHeartRate > 0 ? unifiedDataManager.realTimeHeartRate : nil,
                    cadence: unifiedDataManager.realTimeCadence > 0 ? Int(unifiedDataManager.realTimeCadence) : nil,
                    pace: unifiedDataManager.realTimePace > 0 ? unifiedDataManager.realTimePace : nil,
                    distance: unifiedDataManager.realTimeDistance > 0 ? unifiedDataManager.realTimeDistance : nil,
                    duration: Int(elapsedTime),
                    userId: AuthManager.shared.getUserInfo()?.id.description
                )
                print("🤖 手动AI分析完成")
            } catch {
                print("❌ AI运动分析失败: \(error)")
            }
        }
    }

    // MARK: - AI运动教练相关方法

    /// 启动AI分析定时器
    private func startAIAnalysisTimer() {
        aiAnalysisTimer?.invalidate()

        print("🤖 启动AI分析定时器")

        // 每30秒进行一次完整分析
        aiAnalysisTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                await self.performAIAnalysis()
            }
        }

        // 每10秒进行一次实时分析
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { timer in
            Task { @MainActor in
                if self.isActive && !self.isPaused {
                    await self.performRealTimeAIAnalysis()
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    /// 停止AI分析定时器
    private func stopAIAnalysisTimer() {
        print("🤖 停止AI分析定时器")
        aiAnalysisTimer?.invalidate()
        aiAnalysisTimer = nil
    }

    /// 执行AI分析
    private func performAIAnalysis() async {
        guard isActive && !isPaused else { return }

        do {
            let response: WorkoutAIAnalysisResponse = try await aiCoachService.analyzeWorkout(
                workoutType: workoutType,
                heartRate: unifiedDataManager.realTimeHeartRate > 0 ? unifiedDataManager.realTimeHeartRate : nil,
                cadence: unifiedDataManager.realTimeCadence > 0 ? Int(unifiedDataManager.realTimeCadence) : nil,
                pace: unifiedDataManager.realTimePace > 0 ? unifiedDataManager.realTimePace : nil,
                distance: unifiedDataManager.realTimeDistance > 0 ? unifiedDataManager.realTimeDistance : nil,
                duration: elapsedTime > 0 ? elapsedTime : nil,
                userId: AuthManager.shared.getUserInfo()?.id.description
            )

            if response.success, let data = response.data {
                lastAIGuidanceTime = Date()

                // 根据分析结果更新UI状态
                updateUIBasedOnAIAnalysis(data.analysis)

                print("🤖 AI分析完成 - 指导: \(data.guidance.message)")
                print("📊 运动数据 - 心率: \(unifiedDataManager.realTimeHeartRate), 步频: \(unifiedDataManager.realTimeCadence), 配速: \(unifiedDataManager.realTimePace)")
            }
        } catch {
            print("❌ AI分析失败: \(error)")
        }
    }

    /// 执行实时AI分析
    private func performRealTimeAIAnalysis() async {
        guard isActive && !isPaused else { return }

        // 避免过于频繁的分析
        if let lastTime = lastAIGuidanceTime,
           Date().timeIntervalSince(lastTime) < 8.0 {
            return
        }

        do {
            let response: WorkoutAIAnalysisResponse = try await aiCoachService.realTimeAnalysis(
                workoutType: workoutType,
                heartRate: unifiedDataManager.realTimeHeartRate > 0 ? unifiedDataManager.realTimeHeartRate : nil,
                cadence: unifiedDataManager.realTimeCadence > 0 ? Int(unifiedDataManager.realTimeCadence) : nil,
                pace: unifiedDataManager.realTimePace > 0 ? unifiedDataManager.realTimePace : nil
            )

            if response.success, let data = response.data {
                // 实时分析不更新lastAIGuidanceTime，避免影响完整分析的频率
                print("🤖 实时AI分析完成 - 状态: \(data.analysis.overall)")
            }
        } catch {
            print("❌ 实时AI分析失败: \(error)")
        }
    }

    /// 根据AI分析结果更新UI
    private func updateUIBasedOnAIAnalysis(_ analysis: WorkoutAIAnalysisResponse.AnalysisData.Analysis) {
        // 根据心率状态更新UI颜色或提示
        if let heartRateAnalysis = analysis.heartRate {
            switch heartRateAnalysis.status {
            case "warning":
                // 可以在这里添加UI警告提示
                print("⚠️ 心率警告: \(heartRateAnalysis.message)")
            case "danger":
                // 可以在这里添加UI危险提示
                print("🚨 心率危险: \(heartRateAnalysis.message)")
            default:
                break
            }
        }

        // 根据整体状态更新UI
        switch analysis.overall {
        case "warning":
            // 可以改变界面颜色或显示警告图标
            break
        case "danger":
            // 可以显示紧急提示
            break
        default:
            break
        }
    }

    // MARK: - 传感器权限请求

    /// 请求传感器权限
    private func requestSensorPermissionsIfNeeded() {
        print("📱 请求传感器权限")

        // 请求HealthKit权限
        Task {
            let authorized = await HealthKitManager.shared.requestAuthorization()
            if authorized {
                print("✅ HealthKit权限已获取")
            } else {
                print("❌ HealthKit权限被拒绝")
            }
        }

        // 检查CoreMotion权限
        if CMPedometer.isStepCountingAvailable() {
            print("✅ CoreMotion步数检测可用")
        } else {
            print("❌ CoreMotion步数检测不可用")
        }

        if CMPedometer.isCadenceAvailable() {
            print("✅ CoreMotion步频检测可用")
        } else {
            print("❌ CoreMotion步频检测不可用")
        }

        if CMPedometer.isPaceAvailable() {
            print("✅ CoreMotion配速检测可用")
        } else {
            print("❌ CoreMotion配速检测不可用")
        }
    }

    private func centerMapOnUser() {
        // 获取用户当前位置并将地图居中
        locationManager.requestLocationPermission()

        if let currentLocation = locationManager.currentLocation {
            let region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                latitudinalMeters: 50, // 50米范围视野
                longitudinalMeters: 50
            )

            withAnimation(.easeInOut(duration: 1.2)) {
                mapRegion = region
                shouldCenterOnLocation = true
            }

            // 添加触觉反馈
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            print("🎯 地图已居中到用户位置: \(currentLocation.coordinate)，50米视野")
        } else {
            // 如果当前位置不可用，仅在已授权时开始位置追踪
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                locationManager.startTracking()
            } else {
                print("⏳ 等待定位授权再获取位置信息...")
            }
            print("⚠️ 正在获取位置信息，请稍候...")

            // 添加轻微触觉反馈表示正在处理
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()

            // 延迟重试
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let location = locationManager.currentLocation {
                    let region = MKCoordinateRegion(
                        center: location.coordinate,
                        latitudinalMeters: 50,
                        longitudinalMeters: 50
                    )
                    withAnimation(.easeInOut(duration: 1.2)) {
                        mapRegion = region
                        shouldCenterOnLocation = true
                    }
                    print("🎯 延迟获取位置成功: \(location.coordinate)，50米视野")
                }
            }
        }
    }

    private func toggleMapType() {
        print("🔘 toggleMapType 方法被调用")
        print("🔘 切换前 isSatelliteMode: \(isSatelliteMode)")

        // 切换卫星图模式
        isSatelliteMode.toggle()

        print("🔘 切换后 isSatelliteMode: \(isSatelliteMode)")

        withAnimation(.easeInOut(duration: 0.5)) {
            // 地图类型会通过mapType参数自动更新
        }

        // 添加触觉反馈
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        print("🛰️ 卫星图模式: \(isSatelliteMode ? "已开启" : "已关闭")")
    }

    private func takePhoto() {
        // 更新交互时间
        lockManager.updateLastInteractionTime()

        // 显示拍照界面
        showCameraView = true
    }

    // MARK: - 计时器管理

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isPaused {
                elapsedTime += 1
                
                // 检查目标完成状态
                checkTargetCompletion()
            }
        }
    }
    
    // 检查目标完成
    private func checkTargetCompletion() {
        guard let target = workoutTarget, !isTargetCompleted else { return }
        
        let progress = calculateProgress(for: target)
        if progress >= 1.0 {
            isTargetCompleted = true
            
            // 延迟3秒后自动结束运动
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if isTargetCompleted {
                    endWorkout()
                }
            }
            
            print("🎯 目标完成！将在3秒后自动结束运动")
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - 数据同步定时器管理

    /// 启动数据同步定时器，每秒同步GPS距离数据到WorkoutDataManager
    private func startDataUpdateTimer() {
        dataUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !self.isPaused && self.isActive {
                self.syncGPSDataToWorkoutManager()
            }
        }
        print("🔄 数据同步定时器已启动")
    }

    /// 停止数据同步定时器
    private func stopDataUpdateTimer() {
        dataUpdateTimer?.invalidate()
        dataUpdateTimer = nil
        print("🔄 数据同步定时器已停止")
    }

    /// 同步GPS距离数据到WorkoutDataManager
    private func syncGPSDataToWorkoutManager() {
        // 从AppleMapService获取GPS计算的距离
        let gpsDistance = locationManager.getMapBasedDistanceInKm()

        // 计算基于GPS距离和时间的卡路里消耗
        let estimatedCalories = calculateCalories(
            workoutType: workoutType,
            duration: TimeInterval(elapsedTime),
            distance: gpsDistance
        )

        // 计算实时配速
        let realPace = calculateRealPace(distance: gpsDistance, duration: TimeInterval(elapsedTime))

        // 更新WorkoutDataManager的实时数据
        unifiedDataManager.updateRealTimeData(
            distance: gpsDistance,
            calories: estimatedCalories,
            steps: nil, // 步数由CoreMotion自动更新，不在此处覆盖
            cadence: nil, // 步频由CoreMotion自动更新，不在此处覆盖
            heartRate: nil, // 心率由HealthKit自动更新，不在此处覆盖
            pace: realPace,
            elevation: locationManager.currentLocation?.altitude
        )

        // 每10秒打印一次同步状态（避免日志过多）
        if elapsedTime % 10 == 0 {
            print("🔄 GPS数据已同步 - 距离: \(String(format: "%.2f", gpsDistance))km, 卡路里: \(String(format: "%.0f", estimatedCalories))")
        }
    }

    // MARK: - 计算方法

    /// 计算卡路里消耗
    private func calculateCalories(workoutType: WorkoutType, duration: TimeInterval, distance: Double) -> Double {
        // 基础代谢率（假设70kg体重）
        let weight = 70.0 // kg
        let durationInHours = duration / 3600.0

        // 不同运动类型的MET值（代谢当量）
        let metValue: Double
        switch workoutType {
        case .running:
            // 跑步MET值基于配速计算
            if distance > 0 && duration > 0 {
                let pace = (duration / 60.0) / distance // 分钟/公里
                if pace < 4.0 { // 快于4分/公里
                    metValue = 15.0
                } else if pace < 5.0 { // 4-5分/公里
                    metValue = 12.0
                } else if pace < 6.0 { // 5-6分/公里
                    metValue = 10.0
                } else { // 慢于6分/公里
                    metValue = 8.0
                }
            } else {
                metValue = 10.0 // 默认值
            }
        case .walking:
            metValue = 3.5
        case .cycling:
            metValue = 8.0
        case .swimming:
            metValue = 11.0
        case .hiking:
            metValue = 6.0
        case .yoga:
            metValue = 3.0
        case .strength:
            metValue = 6.0
        case .fitness:
            metValue = 7.0
        default:
            metValue = 5.0
        }

        // 卡路里计算公式：MET × 体重(kg) × 时间(小时)
        return metValue * weight * durationInHours
    }

    /// 计算实时配速
    private func calculateRealPace(distance: Double, duration: TimeInterval) -> Double {
        guard distance > 0, duration > 0 else { return 0.0 }

        // 配速 = 时间(分钟) / 距离(公里)
        let timeInMinutes = duration / 60.0
        return timeInMinutes / distance
    }

    /// 计算骑行功率（估算）
    private func calculateCyclingPower() -> Double {
        // 基于速度、体重和阻力系数的功率估算
        let weight = 70.0 // kg，假设体重
        let currentSpeedKmh = locationManager.currentSpeed * 3.6
        let airResistanceCoeff = 0.3 // 空气阻力系数
        let rollingResistanceCoeff = 0.005 // 滚动阻力系数
        let efficiency = 0.22 // 人体效率

        // 功率计算公式（简化版）
        // P = (空气阻力 + 滚动阻力 + 重力阻力) × 速度 / 效率
        let airResistance = airResistanceCoeff * currentSpeedKmh * currentSpeedKmh
        let rollingResistance = rollingResistanceCoeff * weight * 9.8
        let totalResistance = airResistance + rollingResistance

        let powerWatts = (totalResistance * currentSpeedKmh / 3.6) / efficiency

        return max(powerWatts, 0.0)
    }

    // MARK: - 格式化方法

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    private func formatPace(_ pace: Double) -> String {
        guard pace > 0 && pace.isFinite else { return "--'--\"" }

        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)

        return String(format: "%d'%02d\"", minutes, seconds)
    }
}

// MARK: - 现代化GPS信号视图
struct ModernGPSSignalView: View {
    @State private var signalStrength = 3
    @State private var isSearching = false
    @State private var satelliteCount = 8
    @State private var accuracy = 5.0

    // 添加locationManager引用
    @ObservedObject private var locationManager = AppleMapService.shared

    var body: some View {
        HStack(spacing: 6) {
            // GPS图标 - 现代化设计
            ZStack {
                Circle()
                    .fill(getSignalColor().opacity(0.2))
                    .frame(width: 28, height: 28)

                Image(systemName: "location.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(getSignalColor())
                    .opacity(isSearching ? 0.6 : 1.0)
                    .scaleEffect(isSearching ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isSearching)
            }

            // 信号强度指示器 - 圆点设计
            HStack(spacing: 3) {
                ForEach(1...4, id: \.self) { dot in
                    Circle()
                        .fill(dot <= signalStrength ? getSignalColor() : Color.white.opacity(0.3))
                        .frame(width: 4, height: 4)
                        .scaleEffect(dot <= signalStrength ? 1.0 : 0.7)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: signalStrength)
                }
            }

            // 信号状态文本 - 简洁显示
            Text(getSignalStatusText())
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(getSignalColor())
                .opacity(0.9)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(getSignalColor().opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            startSignalSimulation()
        }
    }

    private func getSignalColor() -> Color {
        if isSearching { return .orange }
        switch signalStrength {
        case 4: return .green
        case 3: return .mint
        case 2: return .yellow
        default: return .red
        }
    }

    private func getSignalStatusText() -> String {
        if isSearching { return "定位中" }
        return "GPS"
    }

    private func startSignalSimulation() {
        // 使用真实GPS状态而不是模拟数据
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            // 获取真实GPS状态
            let currentLocation = locationManager.currentLocation
            let isTracking = locationManager.isTracking

            if isTracking && currentLocation != nil {
                // 基于真实GPS精度设置信号强度
                if let location = currentLocation {
                    let horizontalAccuracy = location.horizontalAccuracy

                    if horizontalAccuracy < 5 {
                        signalStrength = 4 // 优秀信号
                        satelliteCount = 12
                        accuracy = horizontalAccuracy
                    } else if horizontalAccuracy < 10 {
                        signalStrength = 3 // 良好信号
                        satelliteCount = 8
                        accuracy = horizontalAccuracy
                    } else if horizontalAccuracy < 20 {
                        signalStrength = 2 // 一般信号
                        satelliteCount = 6
                        accuracy = horizontalAccuracy
                    } else {
                        signalStrength = 1 // 弱信号
                        satelliteCount = 4
                        accuracy = horizontalAccuracy
                    }
                }
                isSearching = false
            } else {
                // GPS未启动或无信号
                signalStrength = 1
                satelliteCount = 0
                accuracy = 999.0
                isSearching = true
            }
        }
    }
}

// MARK: - GPS信号状态视图
struct GPSSignalStatusView: View {
    @State private var signalStrength = 3
    @State private var isSearching = false
    @State private var isConnected = true

    // 添加locationManager引用
    @ObservedObject private var locationManager = AppleMapService.shared

    var body: some View {
        HStack(spacing: 8) {
            // GPS状态圆点指示器
            Circle()
                .fill(getSignalColor())
                .frame(width: 8, height: 8)
                .scaleEffect(isSearching ? 1.5 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isSearching)

            // GPS文字
            Text("GPS")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)

            // 信号强度指示器
            VStack(spacing: 1) {
                ForEach(1...3, id: \.self) { level in
                    Rectangle()
                        .fill(level <= signalStrength ? getSignalColor() : Color.white.opacity(0.3))
                        .frame(width: 3, height: CGFloat(level * 2 + 2))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: signalStrength)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(getSignalColor().opacity(0.5), lineWidth: 1)
                )
        )
        .onAppear {
            startGPSSimulation()
        }
    }

    private func getSignalColor() -> Color {
        if isSearching { return .orange }
        if !isConnected { return .red }
        switch signalStrength {
        case 3: return .green
        case 2: return .yellow
        default: return .orange
        }
    }

    private func startGPSSimulation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            // 使用真实GPS状态
            if locationManager.isTracking && locationManager.currentLocation != nil {
                // GPS正常工作
                isConnected = true
                isSearching = false

                // 基于真实GPS精度设置信号强度
                if let location = locationManager.currentLocation {
                    let accuracy = location.horizontalAccuracy
                    if accuracy < 10 {
                        signalStrength = 3
                    } else if accuracy < 20 {
                        signalStrength = 2
                    } else {
                        signalStrength = 1
                    }
                }
            } else {
                // GPS未启动或搜索中
                isConnected = false
                isSearching = true
                signalStrength = 1
            }
        }
    }
}

// MARK: - Keep风格按钮样式
struct KeepButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - KeepStyleWorkoutLiveView 扩展
extension KeepStyleWorkoutLiveView {
    /// 创建运动总结数据
    private func createWorkoutSummary() -> WorkoutSummary {
        let endTime = Date()
        let startTime = endTime.addingTimeInterval(-TimeInterval(elapsedTime))

        return WorkoutSummary(
            workoutType: workoutType,
            workoutMode: workoutMode,
            startTime: startTime,
            endTime: endTime,
            duration: TimeInterval(elapsedTime),
            distance: unifiedDataManager.realTimeDistance,
            calories: unifiedDataManager.realTimeCalories,
            averageHeartRate: unifiedDataManager.realTimeHeartRate > 0 ? unifiedDataManager.realTimeHeartRate : 75,
            maxHeartRate: unifiedDataManager.realTimeHeartRate > 0 ? unifiedDataManager.realTimeHeartRate + 20 : 95,
            steps: unifiedDataManager.realTimeSteps,
            averagePace: calculateAveragePace(),
            averageCadence: unifiedDataManager.realTimeCadence, // 添加步频数据
            routePoints: locationManager.routePoints.map { point in
                RoutePoint(
                    latitude: point.latitude,
                    longitude: point.longitude,
                    altitude: nil,
                    timestamp: Date(),
                    speed: nil
                )
            }
        )
    }

    /// 计算平均配速
    private func calculateAveragePace() -> Double {
        guard unifiedDataManager.realTimeDistance > 0, elapsedTime > 0 else {
            return 0.0
        }

        // 配速 = 时间(分钟) / 距离(公里)
        let timeInMinutes = Double(elapsedTime) / 60.0
        return timeInMinutes / unifiedDataManager.realTimeDistance
    }

    // MARK: - 锁屏和拍照功能

    /// 正常运动界面
    private var normalWorkoutView: some View {
        ZStack {
            // Keep风格全屏地图背景
            fullScreenMapView

            // 顶部状态栏
            VStack(spacing: 0) {
                topStatusBar

                Spacer()

                // 底部数据面板
                bottomDataPanel
            }
        }
    }

    /// 设置锁屏管理器
    private func setupLockManager() {
        // 配置自动锁屏
        lockManager.autoLockEnabled = true
        lockManager.autoLockDelay = 300 // 5分钟无操作自动锁屏
        lockManager.showDataInLockScreen = true
        lockManager.allowCameraInLockScreen = false // 锁屏状态下不允许拍照
    }

    /// 创建锁屏数据
    private func createLockScreenData() -> LockScreenData {
        return LockScreenData(
            elapsedTime: TimeInterval(elapsedTime),
            distance: locationManager.getMapBasedDistanceInKm(),
            pace: formatPace(locationManager.getCurrentPace()),
            heartRate: Int(unifiedDataManager.realTimeHeartRate),
            calories: Int(unifiedDataManager.realTimeCalories),
            workoutType: workoutType.displayName
        )
    }

    /// 创建运动照片数据
    private func createWorkoutPhotoData() -> ExtendedWorkoutPhotoData {
        return ExtendedWorkoutPhotoData(
            workoutType: workoutType.displayName,
            distance: locationManager.getMapBasedDistanceInKm(),
            duration: TimeInterval(elapsedTime),
            pace: formatPace(locationManager.getCurrentPace()),
            heartRate: Int(unifiedDataManager.realTimeHeartRate),
            calories: Int(unifiedDataManager.realTimeCalories),
            location: locationManager.currentLocation?.coordinate,
            timestamp: Date()
        )
    }

    /// 设置初始位置观察器，监听位置更新并立即设置地图区域
    private func setupInitialLocationObserver() {
        // 使用简单的定时器检查位置更新
        var checkCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            checkCount += 1
            if let location = self.locationManager.currentLocation, !self.hasInitiallyCentered {
                DispatchQueue.main.async {
                    let region = MKCoordinateRegion(
                        center: location.coordinate,
                        latitudinalMeters: 50,
                        longitudinalMeters: 50
                    )
                    self.mapRegion = region
                    self.hasInitiallyCentered = true
                    print("🎯 Keep页：位置更新后立即设置50米视野 -> \(location.coordinate)")
                }
                timer.invalidate()
            } else if checkCount > 50 {
                // 5秒后停止检查 (50 * 0.1s = 5s)
                timer.invalidate()
            }
        }
    }

}


