import SwiftUI
import MapKit
import CoreMotion

// MARK: - 运动指标数据模型
struct WorkoutMetricData {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
}

// MARK: - 运动照片指标数据模型
struct WorkoutPhotoMetrics {
    let distance: Double
    let duration: TimeInterval
    let pace: Double
    let heartRate: Int
}

// MARK: - 运动总结数据模型
struct WorkoutSummary: Codable {
    let workoutType: WorkoutType
    let workoutMode: WorkoutMode
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let distance: Double // 公里
    let calories: Double
    let averageHeartRate: Int
    let maxHeartRate: Int
    let steps: Int
    let averagePace: Double // 分钟/公里
    let averageCadence: Double // 步/分钟
    let routePoints: [RoutePoint]

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var formattedPace: String {
        let minutes = Int(averagePace)
        let seconds = Int((averagePace - Double(minutes)) * 60)
        return String(format: "%d'%02d\"", minutes, seconds)
    }
}

struct WorkoutLiveView: View {
    let workoutType: WorkoutType
    let workoutMode: WorkoutMode

    @State private var isActive = true
    @State private var isPaused = false

    @State private var isMuted = false
    @State private var showMapExpanded = false
    @State private var isScreenLocked = false
    @State private var showEndWorkoutConfirm = false
    @State private var currentPage = 0

    // 使用苹果地图定位服务 - 使用ObservedObject观察共享实例
    @ObservedObject private var locationManager = AppleMapService.shared

    // 运动数据管理器 - 使用ObservedObject观察共享实例
    @ObservedObject private var workoutDataManager = WorkoutDataManager.shared

    // 相机管理器 - 使用ObservedObject观察共享实例
    @ObservedObject private var cameraManager = WorkoutCameraManager.shared

    // AI运动教练服务 - 使用ObservedObject观察共享实例
    @ObservedObject private var aiCoachService = WorkoutAICoachService.shared

    // 音频播放器 - 使用ObservedObject观察共享实例
    @ObservedObject private var audioPlayer = WorkoutAudioPlayer.shared

    // 运动数据 - 从真实GPS获取
    @State private var currentTime = 0
    @State private var timer: Timer?
    @Environment(\.presentationMode) var presentationMode

    // 新增状态变量
    @State private var isPanelExpanded = false
    @State private var elapsedTime = 0
    @State private var isSatelliteMode = false
    @State private var showDataSourceSelection = false

    // 运动数据状态变量
    @State private var distance: Double = 0.0
    @State private var calories: Double = 0.0
    @State private var heartRate: Int = 120
    @State private var pace: Double = 0.0
    @State private var avgPace: Double = 0.0
    @State private var maxPace: Double = 0.0
    @State private var steps: Int = 0
    @State private var cadence: Int = 0
    @State private var elevation: Double = 0.0
    
    // 运动数据状态变量
    @State private var averagePace: Double = 0.0
    @State private var currentPace: Double = 0.0
    
    // 地图控制状态变量
    @State private var shouldCenterOnLocation = false
    
    // 相机相关状态变量
    @State private var showCameraView = false
    @State private var mapRegion: MKCoordinateRegion?

    // AI教练相关状态变量
    @State private var showAICoachPanel = false
    @State private var lastAIGuidanceTime: Date?
    @State private var aiAnalysisTimer: Timer?
    @State private var hasPlayedWelcome = false
    
    var body: some View {
        ZStack {
            // Dynamic background based on workout state
            backgroundGradient
                .ignoresSafeArea()
            
            if isScreenLocked {
                screenLockView
            } else {
                mainContentView
            }
            

            
            if showEndWorkoutConfirm {
                endWorkoutConfirmModal
            }
        }
        // 暂时注释掉缺失的视图
        // .sheet(isPresented: $showDataSourceSelection) {
        //     DataSourceSelectionView()
        // }
        // .sheet(isPresented: $showCameraView) {
        //     WorkoutCameraView(
        //         cameraManager: cameraManager,
        //         workoutData: createWorkoutPhotoData(),
        //         onPhotoTaken: { image in
        //             // 处理拍摄的照片
        //             print("📸 拍摄照片成功")
        //             cameraManager.handleCapturedPhoto(image, workoutData: createWorkoutPhotoData())
        //         }
        //     )
        // }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            startTimer()
            initializeRealLocation()
            updateRealTimeData()
            setupMemoryWarningHandler()
            setupLocationObserver() // 添加位置观察者

            // 启动运动数据管理器
            workoutDataManager.startWorkout(type: workoutType)

            // 请求传感器权限（如果需要）
            requestSensorPermissionsIfNeeded()

            // 初始化相机权限检查
            // cameraManager.checkPermissions() // 暂时注释掉，方法不存在

            // 启动AI运动教练
            startAICoach()

            // 强制启动传感器数据收集（调试用）
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.forceSensorDataCollection()
            }

            // 添加调试信息监控
            print("🔵 WorkoutLiveView onAppear - locationManager实例: \(ObjectIdentifier(locationManager))")
            print("🔵 WorkoutLiveView onAppear - 初始 currentLocation: \(locationManager.currentLocation?.coordinate.latitude ?? 0), \(locationManager.currentLocation?.coordinate.longitude ?? 0)")

            // 确保运动状态和位置追踪同步，并在获取位置后自动居中
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("🔄 检查状态同步 - isActive: \(isActive), isTracking: \(locationManager.isTracking)")
                if isActive && !locationManager.isTracking {
                    print("⚠️ 状态不同步，重新启动位置追踪")
                    locationManager.startTracking()
                }

                // 如果已经有位置信息，立即居中到50米视野
                if let currentLocation = locationManager.currentLocation {
                    let region = MKCoordinateRegion(
                        center: currentLocation.coordinate,
                        latitudinalMeters: 50,
                        longitudinalMeters: 50
                    )
                    mapRegion = region
                    shouldCenterOnLocation = true
                    hasInitiallyCenter = true
                    print("🎯 运动开始：地图居中到用户位置，50米视野")
                }
            }
        }
        .onDisappear {
            stopTimer()
            locationManager.stopTracking()

            // 停止运动数据管理器
            workoutDataManager.stopWorkout()
            workoutDataManager.endWorkout()

            // 停止AI教练
            stopAICoach()
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: isPaused ?
                [Color.orange.opacity(0.1), Color(.systemBackground)] :
                [workoutType.primaryColor.opacity(0.15), Color(.systemBackground)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 0.5), value: isPaused)
    }
    
    private var screenLockView: some View {
        VStack(spacing: 32) {
            // Lock animation
            ZStack {
                Circle()
                    .fill(Color(.systemBackground).opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text("屏幕已锁定")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("防止运动中误触操作\n点击下方按钮解锁")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Current stats during lock
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text(formatTime(currentTime))
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .foregroundColor(.white)
                    Text("时长")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                VStack(spacing: 8) {
                    Text(String(format: "%.2f", locationManager.getMapBasedDistanceInKm()))
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.white)
                    Text("公里")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.vertical, 20)
            
            Button(action: {
                withAnimation(.spring()) {
                    isScreenLocked = false
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 20))
                    Text("解锁屏幕")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(Color(.label))
                .frame(width: 200, height: 56)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: Color(.systemGray4).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.8))
    }
    
    private var mainContentView: some View {
        ZStack {
            // 全屏地图背景
            fullScreenMapView

            // 顶部状态栏（半透明）
            VStack(spacing: 0) {
                topStatusBarOverlay

                // 暂停状态
                if isPaused {
                    pauseStatusBarOverlay
                }

                Spacer()

                // 底部数据面板（可滑动展开/收起）
                bottomDataPanel
            }
        }
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color(.label) : Color(.label).opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(currentPage == index ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .padding(.top, 24) // 下移24px
    }
    
    private var topStatusBar: some View {
        VStack(spacing: 0) {
            HStack {
                // GPS信号检测
                GPSSignalView()

                Spacer()

                // Controls
                HStack(spacing: 12) {
                    Button(action: { isMuted.toggle() }) {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.2.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(isMuted ? 0.1 : 0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Workout status indicator
            if isPaused {
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPaused)
                    
                    Text("运动已暂停")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var pauseStatusBar: some View {
        HStack {
            Rectangle()
                .fill(Color.orange)
                .frame(width: 4)
            
            Text("运动已暂停 - 点击下方按钮选择操作")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.orange)
            
            Spacer()
        }
        .frame(height: 40)
        .background(Color.orange.opacity(0.2))
    }
    
    // MARK: - Page Views
    
    private var primaryStatsPage: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Main Timer - Larger and more prominent
                VStack(spacing: 16) {
                    Text(formatTime(currentTime))
                        .font(.system(size: 72, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Text("运动时长")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .textCase(.uppercase)
                        .tracking(2)
                }
                .padding(.top, 60)
                
                // Primary Metrics Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                    primaryMetricCard(
                        icon: "location.fill",
                        title: "距离",
                        value: String(format: "%.2f", distance),
                        unit: "公里",
                        color: .green
                    )

                    primaryMetricCard(
                        icon: "speedometer",
                        title: getWorkoutSpecificPaceTitle(),
                        value: formatPaceForWorkoutType(currentPace),
                        unit: getWorkoutSpecificPaceUnit(),
                        color: .blue
                    )

                    primaryMetricCard(
                        icon: "flame.fill",
                        title: "卡路里",
                        value: String(format: "%.0f", calories),
                        unit: "千卡",
                        color: .orange
                    )

                    primaryMetricCard(
                        icon: "heart.fill",
                        title: "心率",
                        value: "\(heartRate)",
                        unit: "bpm",
                        color: .red
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 120)
            }
        }
    }
    
    private func primaryMetricCard(icon: String, title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 6)
                    }
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .textCase(.uppercase)
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var mapPage: some View {
        VStack(spacing: 24) {
            // Map Header with current location info
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                    
                    Text("运动轨迹")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showMapExpanded.toggle() }) {
                        Image(systemName: showMapExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Route stats
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text(String(format: "%.2f", locationManager.getMapBasedDistanceInKm()))
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("总距离 (km)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    VStack(spacing: 4) {
                        Text(formatPace(locationManager.getAveragePace()))
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("平均配速")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", elevation))
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("海拔 (m)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // 苹果地图视图
            ZStack {
                AppleMapView(
                    zoomLevel: 17.0,
                    showUserLocation: true, // 显示用户位置蓝点
                    mapType: isSatelliteMode ? .satellite : .standard,
                    shouldCenterOnLocation: $shouldCenterOnLocation,
                    mapRegion: $mapRegion,
                    routePoints: locationManager.routePoints,
                    currentLocation: locationManager.currentLocation // 传递AppleMapService的当前位置
                )
                .frame(height: showMapExpanded ? 400 : 300)

                if locationManager.currentLocation == nil && locationManager.isTracking {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)

                        Text("正在获取GPS定位...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // GPS状态指示器
                if let error = locationManager.locationError {
                    VStack {
                        Image(systemName: "location.slash")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                }
                
                // Map overlay controls
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Button(action: {}) {
                                Image(systemName: "location.north.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.trailing, 16)
                    }
                    
                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.3), value: showMapExpanded)
            
            Spacer()
        }
    }
    
    private var detailedStatsPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Page Title
                Text(getDetailedPageTitle())
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // Performance Metrics - 根据运动类型显示不同指标
                VStack(spacing: 16) {
                    Text(getPerformanceMetricsTitle())
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        // 根据运动类型显示不同的专业指标
                        ForEach(getWorkoutSpecificMetrics(), id: \.title) { metric in
                            detailStatCard(
                                icon: metric.icon,
                                title: metric.title,
                                value: metric.value,
                                subtitle: metric.subtitle,
                                color: metric.color
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // 运动类型特定的额外数据
                VStack(spacing: 16) {
                    Text(getAdditionalDataTitle())
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 8) {
                        ForEach(getAdditionalStats(), id: \.title) { stat in
                            detailStatRow(title: stat.title, value: stat.value)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 120)
            }
        }
    }
    
    private func detailStatCard(icon: String, title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var heartRateZoneView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("当前心率: \(heartRate) bpm")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(getHeartRateZone())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            }
            
            // Heart rate zone bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 16)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .green, .yellow, .orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * getHeartRateZonePercentage(), height: 16)
                }
            }
            .frame(height: 16)
            
            HStack {
                Text("轻松")
                    .font(.caption)
                    .foregroundColor(.blue)
                Spacer()
                Text("有氧")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                Text("混合")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Spacer()
                Text("乳酸")
                    .font(.caption)
                    .foregroundColor(.orange)
                Spacer()
                Text("无氧")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func detailStatRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var secondaryStatsView: some View {
        VStack(spacing: 16) {
            // Stats Grid
            HStack(spacing: 16) {
                statCard(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "卡路里",
                    value: String(format: "%.0f", calories)
                )
                
                statCard(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "心率 bpm",
                    value: "\(heartRate)"
                )
            }
            
            // Detailed Stats
            VStack(spacing: 16) {
                Text("运动数据")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    statRow(title: "步数", value: "\(steps)")
                    statRow(title: "平均配速", value: formatPace(avgPace))
                    statRow(title: "最快配速", value: formatPace(maxPace))
                    statRow(title: "平均心率", value: "\(heartRate) bpm")
                }
            }
            .padding(16)
            .background(Color.gray.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func statCard(icon: String, iconColor: Color, title: String, value: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.light)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color.gray.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
    
    private var bottomControlPanel: some View {
        VStack(spacing: 20) {
            // Quick Actions Bar
            HStack(spacing: 24) {
                // Page navigation hint
                HStack(spacing: 6) {
                    ForEach(["数据", "地图", "详情"], id: \.self) { title in
                        Text(title)
                            .font(.caption2)
                            .foregroundColor(title == getPageTitle() ? .white : .white.opacity(0.5))
                            .fontWeight(title == getPageTitle() ? .medium : .regular)
                    }
                }
                
                Spacer()
                
                // Quick stats
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("\(heartRate)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        Text("BPM")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    VStack(spacing: 2) {
                        Text(formatPace(pace))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("配速")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Main Controls
            HStack(spacing: 40) {
                // Lock Button
                Button(action: {
                    withAnimation(.spring()) {
                        isScreenLocked = true
                    }
                }) {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            )
                        
                        Text("锁屏")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Main Action Button
                Button(action: handleMainAction) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(isPaused ? Color.orange : Color.green)
                                .frame(width: 80, height: 80)
                                .shadow(color: isPaused ? .orange.opacity(0.4) : .green.opacity(0.4), radius: 12, x: 0, y: 4)
                            
                            Image(systemName: getMainActionIcon())
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Text(getMainActionText())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                
                // End Workout Button
                Button(action: {
                    showEndWorkoutConfirm = true
                }) {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.red)
                            )
                        
                        Text("结束")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    

    
    private var endWorkoutConfirmModal: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Warning Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.red)
                }
                
                VStack(spacing: 16) {
                    Text("结束运动")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("确定要结束本次运动吗？运动数据将被保存到运动记录中。")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                // Current workout summary
                VStack(spacing: 16) {
                    Text("本次运动数据")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 32) {
                        VStack(spacing: 8) {
                            Text(formatTime(currentTime))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("运动时长")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack(spacing: 8) {
                            Text(String(format: "%.2f", distance))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("距离 (km)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack(spacing: 8) {
                            Text(String(format: "%.0f", calories))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("卡路里")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("继续运动") {
                        showEndWorkoutConfirm = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("结束并保存") {
                        handleEndWorkout()
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .red))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Helper Methods

    private func initializeRealLocation() {
        // 请求位置权限并开始追踪
        locationManager.requestLocationPermission()

        // 开始苹果地图GPS追踪
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.locationManager.startTracking()

            // 调试信息
            print("✅ 开始苹果地图GPS追踪")
            print("📍 isTracking: \(self.locationManager.isTracking)")
            print("🔐 授权状态: \(self.locationManager.authorizationStatus)")
            print("📍 定位状态: \(self.locationManager.currentLocation != nil ? "已定位" : "未定位")")
        }

        print("🍎 开始苹果地图GPS位置追踪 - 运动类型: \(workoutType.rawValue)")
    }

    // 添加缺失的方法
    private func getDetailedPageTitle() -> String {
        switch workoutType {
        case .running: return "跑步数据详情"
        case .walking: return "步行数据详情"
        case .cycling: return "骑行数据详情"
        case .hiking: return "徒步数据详情"
        case .swimming: return "游泳数据详情"
        case .yoga: return "瑜伽数据详情"
        case .strength: return "力量训练详情"
        case .fitness: return "健身数据详情"
        case .basketball: return "篮球数据详情"
        case .football: return "足球数据详情"
        case .tennis: return "网球数据详情"
        case .badminton: return "羽毛球数据详情"
        case .pingpong: return "乒乓球数据详情"
        case .climbing: return "攀岩数据详情"
        case .dancing: return "舞蹈数据详情"
        case .boxing: return "拳击数据详情"
        case .martialArts: return "武术数据详情"
        case .pilates: return "普拉提数据详情"
        case .aerobics: return "有氧运动详情"
        case .other: return "运动数据详情"
        }
    }

    private func getPerformanceMetricsTitle() -> String {
        switch workoutType {
        case .running: return "跑步表现指标"
        case .walking: return "步行表现指标"
        case .cycling: return "骑行表现指标"
        case .hiking: return "徒步表现指标"
        case .swimming: return "游泳表现指标"
        case .yoga: return "瑜伽表现指标"
        case .strength: return "力量训练指标"
        case .fitness: return "健身表现指标"
        case .basketball: return "篮球表现指标"
        case .football: return "足球表现指标"
        case .tennis: return "网球表现指标"
        case .badminton: return "羽毛球表现指标"
        case .pingpong: return "乒乓球表现指标"
        case .climbing: return "攀岩表现指标"
        case .dancing: return "舞蹈表现指标"
        case .boxing: return "拳击表现指标"
        case .martialArts: return "武术表现指标"
        case .pilates: return "普拉提表现指标"
        case .aerobics: return "有氧运动指标"
        case .other: return "运动表现指标"
        }
    }

    private func getAdditionalDataTitle() -> String {
        switch workoutType {
        case .running: return "跑步附加数据"
        case .walking: return "步行附加数据"
        case .cycling: return "骑行附加数据"
        case .hiking: return "徒步附加数据"
        case .swimming: return "游泳附加数据"
        case .yoga: return "瑜伽附加数据"
        case .strength: return "力量训练数据"
        case .fitness: return "健身附加数据"
        case .basketball: return "篮球附加数据"
        case .football: return "足球附加数据"
        case .tennis: return "网球附加数据"
        case .badminton: return "羽毛球附加数据"
        case .pingpong: return "乒乓球附加数据"
        case .climbing: return "攀岩附加数据"
        case .dancing: return "舞蹈附加数据"
        case .boxing: return "拳击附加数据"
        case .martialArts: return "武术附加数据"
        case .pilates: return "普拉提附加数据"
        case .aerobics: return "有氧运动数据"
        case .other: return "运动附加数据"
        }
    }

    private func getWorkoutSpecificMetrics() -> [WorkoutMetricData] {
        switch workoutType {
        case .running:
            return [
                WorkoutMetricData(icon: "speedometer", title: "当前配速", value: formatPace(currentPace), subtitle: "分钟/公里", color: .blue),
                WorkoutMetricData(icon: "figure.run", title: "步频", value: "\(cadence)", subtitle: "步/分钟", color: .green),
                WorkoutMetricData(icon: "arrow.up", title: "海拔", value: String(format: "%.0f", elevation), subtitle: "米", color: .orange),
                WorkoutMetricData(icon: "figure.walk", title: "步数", value: "\(steps)", subtitle: "步", color: .purple)
            ]
        case .walking:
            return [
                WorkoutMetricData(icon: "speedometer", title: "当前配速", value: formatPace(currentPace), subtitle: "分钟/公里", color: .blue),
                WorkoutMetricData(icon: "figure.walk", title: "步数", value: "\(steps)", subtitle: "步", color: .purple),
                WorkoutMetricData(icon: "arrow.up", title: "海拔", value: String(format: "%.0f", elevation), subtitle: "米", color: .orange),
                WorkoutMetricData(icon: "figure.run", title: "步频", value: "\(cadence)", subtitle: "步/分钟", color: .green)
            ]
        case .cycling:
            return [
                WorkoutMetricData(icon: "speedometer", title: "当前速度", value: String(format: "%.1f", currentPace * 60), subtitle: "公里/小时", color: .blue),
                WorkoutMetricData(icon: "arrow.up", title: "海拔", value: String(format: "%.0f", elevation), subtitle: "米", color: .orange),
                WorkoutMetricData(icon: "gauge", title: "踏频", value: "\(cadence)", subtitle: "转/分钟", color: .green),
                WorkoutMetricData(icon: "location", title: "距离", value: String(format: "%.2f", distance), subtitle: "公里", color: .purple)
            ]
        default:
            return [
                WorkoutMetricData(icon: "speedometer", title: "强度", value: "中等", subtitle: "运动强度", color: .blue),
                WorkoutMetricData(icon: "clock", title: "时长", value: formatTime(currentTime), subtitle: "运动时间", color: .green),
                WorkoutMetricData(icon: "flame", title: "卡路里", value: String(format: "%.0f", calories), subtitle: "千卡", color: .orange),
                WorkoutMetricData(icon: "heart", title: "心率", value: "\(heartRate)", subtitle: "bpm", color: .red)
            ]
        }
    }

    private func getAdditionalStats() -> [(title: String, value: String)] {
        switch workoutType {
        case .running, .walking:
            return [
                ("平均配速", formatPace(averagePace)),
                ("最快配速", formatPace(maxPace)),
                ("总步数", "\(steps)"),
                ("平均步频", "\(cadence) 步/分钟"),
                ("海拔变化", String(format: "%.0f 米", elevation))
            ]
        case .cycling:
            return [
                ("平均速度", String(format: "%.1f 公里/小时", averagePace * 60)),
                ("最高速度", String(format: "%.1f 公里/小时", maxPace * 60)),
                ("平均踏频", "\(cadence) 转/分钟"),
                ("海拔变化", String(format: "%.0f 米", elevation)),
                ("总距离", String(format: "%.2f 公里", distance))
            ]
        default:
            return [
                ("运动时长", formatTime(currentTime)),
                ("消耗卡路里", String(format: "%.0f 千卡", calories)),
                ("平均心率", "\(heartRate) bpm"),
                ("运动强度", "中等"),
                ("运动类型", workoutType.displayName)
            ]
        }
    }

    private func getWorkoutSpecificPaceTitle() -> String {
        switch workoutType {
        case .running, .walking, .hiking: return "配速"
        case .cycling: return "速度"
        case .swimming: return "游泳配速"
        default: return "强度"
        }
    }

    private func getWorkoutSpecificPaceUnit() -> String {
        switch workoutType {
        case .running, .walking, .hiking: return "分/公里"
        case .cycling: return "公里/小时"
        case .swimming: return "分/100米"
        default: return ""
        }
    }

    private func formatPaceForWorkoutType(_ pace: Double) -> String {
        switch workoutType {
        case .running, .walking, .hiking:
            return formatPace(pace)
        case .cycling:
            return String(format: "%.1f", pace * 60) // 转换为公里/小时
        case .swimming:
            return formatPace(pace * 0.1) // 游泳配速通常以100米为单位
        default:
            return "中等"
        }
    }

    private func getHeartRateZone() -> String {
        let maxHR = 220 - 25 // 假设25岁
        let percentage = Double(heartRate) / Double(maxHR)

        switch percentage {
        case 0..<0.6: return "轻松区间"
        case 0.6..<0.7: return "有氧区间"
        case 0.7..<0.8: return "混合区间"
        case 0.8..<0.9: return "乳酸区间"
        default: return "无氧区间"
        }
    }
    
    private func updateRealTimeData() {
        // 实时更新运动数据 - 从真实传感器和GPS获取
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            print("🔄 数据更新 - isActive: \(isActive), isPaused: \(isPaused)")
            print("📊 LocationManager状态 - isTracking: \(locationManager.isTracking), 位置: \(locationManager.currentLocation?.coordinate ?? CLLocationCoordinate2D())")

            if isActive && !isPaused {
                // 从GPS获取真实距离数据
                let gpsDistance = locationManager.getMapBasedDistanceInKm()

                // 计算真实配速（基于GPS距离和时间）
                let realPace = calculateRealPace(distance: gpsDistance, duration: TimeInterval(currentTime))

                // 估算卡路里消耗（基于运动类型、时间和体重）
                let estimatedCalories = calculateCalories(
                    workoutType: workoutType,
                    duration: TimeInterval(currentTime),
                    distance: gpsDistance
                )

                // 在主线程上更新数据
                Task { @MainActor in
                    // 更新WorkoutDataManager的GPS数据（传感器数据由WorkoutDataManager自动更新）
                    workoutDataManager.updateRealTimeData(
                        distance: gpsDistance,
                        calories: estimatedCalories,
                        steps: nil, // 步数由CoreMotion自动更新，不在此处覆盖
                        cadence: nil, // 步频由CoreMotion自动更新，不在此处覆盖
                        heartRate: nil, // 心率由HealthKit自动更新，不在此处覆盖
                        pace: realPace,
                        elevation: locationManager.currentLocation?.altitude
                    )

                    // 从WorkoutDataManager获取更新后的数据显示在UI上
                    distance = workoutDataManager.realTimeDistance
                    calories = workoutDataManager.realTimeCalories
                    steps = workoutDataManager.realTimeSteps
                    heartRate = workoutDataManager.realTimeHeartRate
                    cadence = Int(workoutDataManager.realTimeCadence)
                    currentPace = workoutDataManager.realTimePace
                    averagePace = locationManager.getAveragePace()
                    elevation = workoutDataManager.realTimeElevation

                    // 调试信息：显示数据来源和传感器状态
                    print("📱 UI数据更新:")
                    print("   距离: \(distance)km (来源: GPS)")
                    print("   卡路里: \(calories) (来源: 估算)")
                    print("   步数: \(steps) (来源: \(steps > 0 ? "CoreMotion传感器" : "无数据"))")
                    print("   心率: \(heartRate) (来源: \(heartRate > 0 ? "HealthKit传感器" : "无数据"))")
                    print("   步频: \(cadence) (来源: \(cadence > 0 ? "CoreMotion传感器" : "无数据"))")
                    print("   配速: \(currentPace) (来源: GPS计算)")
                    print("   数据源: \(workoutDataManager.primaryDataSource)")
                    print("   传感器状态: WorkoutDataManager激活=\(workoutDataManager.isWorkoutActive)")
                }

                // 定期清理内存（每分钟检查一次）
                if currentTime % 60 == 0 {
                    AppleMapService.shared.trimLocationHistory()
                }
            }

            // 如果视图已销毁，停止计时器
            if !isActive && !isPaused {
                timer.invalidate()
            }
        }
    }

    /// 计算真实配速
    private func calculateRealPace(distance: Double, duration: TimeInterval) -> Double {
        guard distance > 0 && duration > 0 else { return 0.0 }

        // 配速 = 时间(分钟) / 距离(公里)
        let paceMinutesPerKm = (duration / 60.0) / distance
        return paceMinutesPerKm
    }

    /// 估算卡路里消耗
    private func calculateCalories(workoutType: WorkoutType, duration: TimeInterval, distance: Double) -> Double {
        let durationInHours = duration / 3600.0
        let userWeight: Double = 70.0 // TODO: 从用户资料获取体重

        // 根据运动类型使用不同的MET值（代谢当量）
        let metValue: Double = {
            switch workoutType {
            case .running:
                // 跑步MET值根据配速调整
                if distance > 0 {
                    let speed = distance / durationInHours // km/h
                    if speed > 12 { return 12.0 }
                    else if speed > 10 { return 10.0 }
                    else if speed > 8 { return 8.0 }
                    else { return 6.0 }
                }
                return 8.0
            case .walking: return 3.5
            case .cycling: return 7.5
            case .swimming: return 8.0
            case .hiking: return 6.0
            case .yoga: return 2.5
            case .strength: return 6.0
            default: return 5.0
            }
        }()

        // 卡路里 = MET × 体重(kg) × 时间(小时)
        return metValue * userWeight * durationInHours
    }

    // 请求传感器权限方法
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

    // 强制传感器数据收集方法
    private func forceSensorDataCollection() {
        print("🔧 强制启动传感器数据收集")

        // 确保WorkoutDataManager已经启动传感器收集
        if !workoutDataManager.isWorkoutActive {
            print("⚠️ WorkoutDataManager未激活，重新启动")
            workoutDataManager.startWorkout(type: workoutType)
        }

        // 手动触发一次数据更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🔄 手动触发传感器数据更新")
            print("   实时步数: \(self.workoutDataManager.realTimeSteps)")
            print("   实时心率: \(self.workoutDataManager.realTimeHeartRate)")
            print("   实时步频: \(self.workoutDataManager.realTimeCadence)")
            print("   实时配速: \(self.workoutDataManager.realTimePace)")
        }
    }

    // 添加创建运动照片数据的方法
    private func createWorkoutPhotoData() -> WorkoutPhotoData {
        let codableLocation: CodableLocationCoordinate? = {
            guard let coordinate = locationManager.currentLocation?.coordinate else { return nil }
            return CodableLocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }()

        return WorkoutPhotoData(
            imageData: Data(), // 空数据，实际使用时会被替换
            timestamp: Date(),
            location: codableLocation,
            workoutId: nil
        )
    }
    
    // 设置内存警告处理
    private func setupMemoryWarningHandler() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("⚠️ WorkoutLiveView收到内存警告")
            handleMemoryWarning()
        }
    }
    
    // 设置位置观察者 - 监听AppleMapService的位置更新
    private func setupLocationObserver() {
        // 由于locationManager是@StateObject，我们可以直接观察其currentLocation的变化
        // 但为了确保地图能及时响应，我们添加一个定时器来检查位置变化
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            print("🔍 位置观察者检查 - locationManager实例: \(ObjectIdentifier(locationManager))")
            print("🔍 位置观察者检查 - currentLocation: \(locationManager.currentLocation?.coordinate.latitude ?? 0), \(locationManager.currentLocation?.coordinate.longitude ?? 0)")

            if let currentLocation = locationManager.currentLocation {
                print("🔍 位置观察者检测到位置: \(currentLocation.coordinate)")

                // 如果地图还没有居中过，强制居中地图
                if !hasInitiallyCenter {
                    forceMapCenter(to: currentLocation)
                }
                // 或者位置发生了显著变化，则更新地图中心
                else if shouldUpdateMapCenter(for: currentLocation) {
                    let region = MKCoordinateRegion(
                        center: currentLocation.coordinate,
                        latitudinalMeters: 50,
                        longitudinalMeters: 50
                    )

                    DispatchQueue.main.async {
                        mapRegion = region
                        shouldCenterOnLocation = true
                        lastCenterLocation = currentLocation
                        print("🎯 位置观察者：地图居中到新位置 \(currentLocation.coordinate)，50米视野")
                    }
                }
            } else {
                print("🔍 位置观察者：currentLocation 仍为 nil")
            }

            // 如果视图已销毁，停止计时器
            if !isActive && !isPaused {
                timer.invalidate()
            }
        }
    }

    // 强制地图居中到指定位置
    private func forceMapCenter(to location: CLLocation) {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 50,
            longitudinalMeters: 50
        )

        DispatchQueue.main.async {
            mapRegion = region
            shouldCenterOnLocation = true
            hasInitiallyCenter = true
            lastCenterLocation = location
            print("🎯 强制地图居中：位置 \(location.coordinate)，50米视野")
        }

        // 延迟再次确认居中
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            mapRegion = region
            shouldCenterOnLocation = true
            print("🎯 二次确认地图居中：位置 \(location.coordinate)")
        }
    }
    
    @State private var hasInitiallyCenter = false
    @State private var lastCenterLocation: CLLocation?
    
    // 判断是否需要更新地图中心
    private func shouldUpdateMapCenter(for newLocation: CLLocation) -> Bool {
        guard let lastLocation = lastCenterLocation else {
            lastCenterLocation = newLocation
            hasInitiallyCenter = true
            return true
        }
        
        let distance = newLocation.distance(from: lastLocation)
        if distance > 50 { // 如果位置变化超过50米，重新居中
            lastCenterLocation = newLocation
            return true
        }
        
        return false
    }
    
    // 处理内存警告
    private func handleMemoryWarning() {
        print("🧹 开始清理WorkoutLiveView内存")
        
        // 清理LocationManager缓存
        locationManager.handleMemoryWarning()
        
        // 重置一些非关键状态
        showMapExpanded = false
        isPanelExpanded = false
        
        // 强制垃圾回收
        autoreleasepool {
            // 清理图片缓存等
        }
        
        print("✅ WorkoutLiveView内存清理完成")
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isActive && !isPaused {
                currentTime += 1
                // 所有运动数据现在从真实的GPS位置管理器获取
                // 不再使用模拟数据
            }
        }
    }
    
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func handleMainAction() {
        if !isActive {
            isActive = true
            isPaused = false
            // 确保位置追踪已启动
            if !locationManager.isTracking {
                locationManager.startTracking()
            } else {
                locationManager.resumeTracking()
            }
        } else if !isPaused {
            isPaused = true
            locationManager.pauseTracking()
        } else {
            isPaused = false
            locationManager.resumeTracking()
        }
    }

    private func handleContinueWorkout() {
        isPaused = false
        isActive = true
        locationManager.resumeTracking()
    }

    private func handleEndWorkout() {
        stopTimer()
        locationManager.stopTracking()
        workoutDataManager.endWorkout()

        // 保存运动数据（这里可以添加数据持久化逻辑）
        saveWorkoutData()

        presentationMode.wrappedValue.dismiss()
        // Navigate to workout completion page
        // This would typically save the workout data and show summary

        // 打印运动总结
        print("运动结束 - 总距离: \(String(format: "%.2f", locationManager.mapBasedDistance))米")
        print("运动时长: \(currentTime)秒")
        print("平均速度: \(String(format: "%.2f", AppleMapService.shared.averageSpeed))m/s")
    }

    /// 保存运动数据
    private func saveWorkoutData() {
        let workoutSummary = WorkoutSummary(
            workoutType: workoutType,
            workoutMode: workoutMode,
            startTime: Date().addingTimeInterval(-locationManager.duration),
            endTime: Date(),
            duration: locationManager.duration,
            distance: distance,
            calories: calories,
            averageHeartRate: WorkoutDataManager.shared.averageHeartRate,
            maxHeartRate: WorkoutDataManager.shared.maxHeartRate,
            steps: steps,
            averagePace: averagePace,
            averageCadence: WorkoutDataManager.shared.realTimeCadence, // 添加步频数据
            routePoints: locationManager.routePoints.map { RoutePoint(latitude: $0.latitude, longitude: $0.longitude) }
        )

        // 这里可以保存到CoreData、UserDefaults或发送到服务器
        print("💾 保存运动数据: \(workoutSummary)")

        // 示例：保存到UserDefaults（实际应用中应使用CoreData）
        if let encoded = try? JSONEncoder().encode(workoutSummary) {
            let key = "workout_\(Date().timeIntervalSince1970)"
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func getPageTitle() -> String {
        switch currentPage {
        case 0: return "数据"
        case 1: return "地图"
        case 2: return "详情"
        default: return "数据"
        }
    }
    

    
    private func getHeartRateZonePercentage() -> Double {
        let maxHR = 220 - 25
        return min(1.0, Double(heartRate) / Double(maxHR))
    }
    

    
    private func getWorkoutTypeName() -> String {
        switch workoutType {
        case .running: return "户外跑步"
        case .walking: return "户外步行"
        case .cycling: return "户外骑行"
        case .hiking: return "户外徒步"
        case .swimming: return "户外游泳"
        case .yoga: return "瑜伽"
        case .strength: return "力量训练"
        case .fitness: return "健身训练"
        case .basketball: return "篮球运动"
        case .football: return "足球运动"
        case .tennis: return "网球运动"
        case .badminton: return "羽毛球运动"
        case .pingpong: return "乒乓球运动"
        case .climbing: return "攀岩运动"
        case .dancing: return "舞蹈运动"
        case .boxing: return "拳击训练"
        case .martialArts: return "武术训练"
        case .pilates: return "普拉提训练"
        case .aerobics: return "有氧运动"
        case .other: return "其他运动"
        }
    }
    
    private func getWorkoutModeDescription() -> String {
        switch workoutMode {
        case .free: return "自由模式"
        case .target: return "目标模式"
        case .interval: return "间歇训练模式"
        case .course: return "课程运动模式"
        }
    }
    
    private func getDataSourceIcon(_ dataSource: String) -> String {
        switch dataSource {
        case "HealthKit": return "heart.fill"
        case "Apple Watch": return "applewatch"
        case "GPS": return "location.fill"
        case "Simulation": return "cpu"
        default: return "questionmark.circle"
        }
    }
    
    private func getDataQualityColor(_ dataQuality: String) -> Color {
        switch dataQuality {
        case "Excellent": return .green
        case "Good": return .blue
        case "Fair": return .orange
        case "Poor": return .red
        default: return .gray
        }
    }
    
    private func getMainActionIcon() -> String {
        if !isActive { return "play.fill" }
        if isPaused { return "play.fill" }
        return "pause.fill"
    }
    
    private func getMainActionText() -> String {
        if !isActive { return "开始" }
        if isPaused { return "已暂停" }
        return "暂停"
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    private func formatPace(_ paceValue: Double) -> String {
        if paceValue == 0 { return "0'00\"" }
        let minutes = Int(paceValue)
        let seconds = Int((paceValue - Double(minutes)) * 60)
        return String(format: "%d'%02d\"", minutes, seconds)
    }
}


struct CompassView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.9))
                .shadow(radius: 2)
            
            Circle()
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
            
            Image(systemName: "location.north.fill")
                .font(.system(size: 16))
                .foregroundColor(.red)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            // Simulate compass rotation
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 2)) {
                    rotation += Double.random(in: -30...30)
                }
            }
        }
    }
}

// MARK: - 新的地图为主的运动实况视图组件

extension WorkoutLiveView {

    // 全屏地图视图
    private var fullScreenMapView: some View {
        ZStack {
            // 主地图视图 - 使用真实的Apple地图
            AppleMapView(
                zoomLevel: 17.0,
                showUserLocation: true, // 显示用户位置蓝点
                mapType: isSatelliteMode ? .satellite : .standard,
                shouldCenterOnLocation: $shouldCenterOnLocation,
                mapRegion: $mapRegion,
                routePoints: locationManager.routePoints,
                currentLocation: locationManager.currentLocation // 传递AppleMapService的当前位置
            )
            .ignoresSafeArea(.all)

            // 地图控制按钮
            mapControlButtons

            // GPS信号指示器
            gpsSignalIndicator

            // 运动轨迹统计浮窗
            routeStatsOverlay
        }
    }

    // 顶部状态栏覆盖层
    private var topStatusBarOverlay: some View {
        HStack {
            // 时间显示
            Text(formatTime(elapsedTime))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)

            Spacer()

            // 锁屏按钮
            Button(action: { isScreenLocked.toggle() }) {
                Image(systemName: isScreenLocked ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.6), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
        )
    }

    // 暂停状态栏覆盖层
    private var pauseStatusBarOverlay: some View {
        HStack {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)

            Text("运动已暂停")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.9))
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    // 地图控制按钮 (右侧垂直居中)
    private var mapControlButtons: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                VStack(spacing: 16) {
                    // 定位按钮
                    Button(action: centerMapOnCurrentLocation) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }

                    // 卫星图切换按钮
                    Button(action: toggleMapType) {
                        Image(systemName: isSatelliteMode ? "globe.asia.australia.fill" : "globe.asia.australia")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(isSatelliteMode ? Color.green.opacity(0.8) : Color.gray.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }

                    // 调试按钮（仅在开发模式下显示）
                    #if DEBUG
                    NavigationLink(destination: LocationDebugView()) {
                        Image(systemName: "ladybug")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.orange.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    #endif
                }
                .padding(.trailing, 20)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // GPS信号指示器
    private var gpsSignalIndicator: some View {
        VStack {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)

                    Text("GPS")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    // 信号强度指示器
                    HStack(spacing: 2) {
                        ForEach(0..<4) { index in
                            Rectangle()
                                .fill(index < 3 ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 3, height: CGFloat(4 + index * 2))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())

                Spacer()
            }
            .padding(.leading, 20)
            .padding(.top, 120)

            Spacer()
        }
    }

    // 运动轨迹统计浮窗
    private var routeStatsOverlay: some View {
        VStack {
            Spacer()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("轨迹统计")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("距离")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            Text(String(format: "%.2f km", distance))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("平均配速")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            Text(formatPace(averagePace))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("定位状态")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            Text(locationManager.currentLocation != nil ? "已定位" : "定位中")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .padding(.bottom, 200) // 为底部面板留出空间
        }
    }

    // 底部数据面板 - 充满下方
    private var bottomDataPanel: some View {
        VStack(spacing: 0) {
            // 拖拽指示器
            dragIndicator

            // 主要运动数据 - 可滑动
            ScrollView {
                VStack(spacing: 16) {
                    mainStatsSection

                    // 扩展数据区域
                    if isPanelExpanded {
                        extendedStatsSection
                    }
                }
            }
            .frame(maxHeight: isPanelExpanded ? .infinity : 200)

            // 控制按钮 - 只在面板展开时显示
            if isPanelExpanded {
                controlButtonsSection
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
        .frame(maxHeight: .infinity)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPanelExpanded)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -50 {
                        isPanelExpanded = true
                    } else if value.translation.height > 50 {
                        isPanelExpanded = false
                    }
                }
        )
    }

    // 拖拽指示器
    private var dragIndicator: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            Button(action: { isPanelExpanded.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: isPanelExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))

                    Text(isPanelExpanded ? "收起数据" : "展开数据")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.bottom, 8)
        }
    }

    // 主要运动数据区域
    private var mainStatsSection: some View {
        VStack(spacing: 16) {
            // 核心数据行
            HStack(spacing: 20) {
                // 距离
                WorkoutStatCard(
                    title: "距离",
                    value: String(format: "%.2f", distance),
                    unit: "km",
                    color: .green
                )

                // 配速
                WorkoutStatCard(
                    title: "配速",
                    value: formatPace(currentPace),
                    unit: "/km",
                    color: .blue
                )

                // 心率
                WorkoutStatCard(
                    title: "心率",
                    value: "\(heartRate)",
                    unit: "bpm",
                    color: .red
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // 扩展数据区域
    private var extendedStatsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                WorkoutStatCard(
                    title: "步数",
                    value: "\(steps)",
                    unit: "步",
                    color: .purple
                )

                WorkoutStatCard(
                    title: "平均配速",
                    value: formatPace(averagePace),
                    unit: "/km",
                    color: .cyan
                )

                WorkoutStatCard(
                    title: "平均速度",
                    value: String(format: "%.1f", distance > 0 ? (distance / (Double(currentTime) / 3600.0)) : 0.0),
                    unit: "km/h",
                    color: .blue
                )
            }

            // 更多详细数据
            HStack(spacing: 20) {
                WorkoutStatCard(
                    title: "最大配速",
                    value: formatPace(max(currentPace - 0.5, 3.0)),
                    unit: "/km",
                    color: .mint
                )

                WorkoutStatCard(
                    title: "海拔",
                    value: String(format: "%.0f", elevation),
                    unit: "m",
                    color: .brown
                )

                WorkoutStatCard(
                    title: "步频",
                    value: String(format: "%.0f", workoutDataManager.realTimeCadence),
                    unit: "spm",
                    color: .indigo
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct GPSSignalView: View {
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

// MARK: - Button Styles

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Extensions

extension WorkoutType {

    var systemImage: String {
        return self.icon
    }
}

// MARK: - 新增组件


// 数据卡片组件
struct WorkoutStatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// WorkoutLiveView的扩展方法
extension WorkoutLiveView {

    // 地图控制方法
    func centerMapOnCurrentLocation() {
        // 获取当前真实位置并将地图居中到系统用户位置，使用50米视野
        if let currentLocation = locationManager.currentLocation {
            // 创建以真实当前位置为中心的50米视野区域
            let region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                latitudinalMeters: 50, // 50米范围视野
                longitudinalMeters: 50
            )

            withAnimation(.easeInOut(duration: 1.0)) {
                mapRegion = region
                shouldCenterOnLocation = true
                hasInitiallyCenter = true
                lastCenterLocation = currentLocation
            }

            // 获取当前位置地址信息
            Task {
                if let address = await locationManager.getCurrentLocationAddress() {
                    print("🍎 定位到当前位置: \(address)")
                } else {
                    print("🍎 获取位置信息失败")
                }
            }

            print("🎯 导航按钮：地图已居中到用户位置，50米视野：\(currentLocation.coordinate)")
        } else {
            print("当前位置不可用，请检查GPS信号")
        }
    }

    func toggleMapType() {
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

    func takePhoto() {
        // 简化实现，直接使用相机管理器拍照
        if cameraManager.takePhoto() != nil {
            print("📸 拍照成功")
        } else {
            print("❌ 拍照失败")
        }
    }
    


    // 控制按钮区域
    var controlButtonsSection: some View {
        VStack(spacing: 16) {
            if isPaused {
                // 暂停状态下显示继续和结束按钮
                HStack(spacing: 20) {
                    // 继续运动按钮
                    Button(action: {
                        isPaused = false
                        startTimer()
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

                    // 结束运动按钮 - 需要长按
                    Button(action: {}) {
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
                    .onLongPressGesture(minimumDuration: 1.0) {
                        showEndWorkoutConfirm = true
                    }
                }
            } else {
                // 正常状态下的控制按钮
                VStack(spacing: 16) {
                    // 主要控制按钮行
                    HStack(spacing: 30) {
                        // 锁屏按钮
                        Button(action: {
                            withAnimation(.spring()) {
                                isScreenLocked = true
                            }
                        }) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }

                        // 暂停按钮
                        Button(action: togglePause) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.orange)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }

                        // 相机按钮
                        Button(action: takePhoto) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.green.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }

                    // 数据源状态指示器
                    Button(action: {
                        showDataSourceSelection = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: getDataSourceIcon(workoutDataManager.primaryDataSource))
                                .font(.system(size: 14))

                            Text(workoutDataManager.primaryDataSource)
                                .font(.caption)
                                .fontWeight(.medium)

                            Circle()
                                .fill(getDataQualityColor(workoutDataManager.dataQuality))
                                .frame(width: 8, height: 8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(15)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }

    private func togglePause() {
        isPaused.toggle()
        if isPaused {
            timer?.invalidate()
            print("⏸️ 暂停运动")
        } else {
            startTimer()
            print("▶️ 恢复运动")
        }
    }




    /// 步行模式专用指标
    private func getWalkingMetrics() -> [WorkoutMetricData] {
        let walkingSpeed = distance > 0 && locationManager.duration > 0 ?
            (distance / (locationManager.duration / 3600.0)) : 0.0

        return [
            WorkoutMetricData(
                icon: "figure.walk",
                title: "步数",
                value: "\(steps)",
                subtitle: "总步数",
                color: .blue
            ),
            WorkoutMetricData(
                icon: "speedometer",
                title: "步行速度",
                value: String(format: "%.1f", walkingSpeed),
                subtitle: "km/h",
                color: .green
            ),
            WorkoutMetricData(
                icon: "metronome",
                title: "步频",
                value: "\(cadence)",
                subtitle: "步/分钟",
                color: .purple
            ),
            WorkoutMetricData(
                icon: "heart.fill",
                title: "心率区间",
                value: getHeartRateZone(),
                subtitle: "运动强度",
                color: .red
            ),
            WorkoutMetricData(
                icon: "arrow.up.circle",
                title: "海拔变化",
                value: String(format: "%.0f", elevation),
                subtitle: "累计爬升",
                color: .orange
            ),
            WorkoutMetricData(
                icon: "location.fill",
                title: "轨迹点",
                value: "\(locationManager.routePoints.count)",
                subtitle: "GPS点数",
                color: .cyan
            )
        ]
    }

    /// 跑步模式专用指标
    private func getRunningMetrics() -> [WorkoutMetricData] {
        let avgStride = steps > 0 ? Int((distance * 1000) / Double(steps) * 100) : 0 // 转换为cm

        return [
            WorkoutMetricData(
                icon: "figure.run",
                title: "步数",
                value: "\(steps)",
                subtitle: "总步数",
                color: .blue
            ),
            WorkoutMetricData(
                icon: "speedometer",
                title: "最快配速",
                value: formatPace(maxPace),
                subtitle: "最佳表现",
                color: .green
            ),
            WorkoutMetricData(
                icon: "metronome",
                title: "步频",
                value: "\(cadence)",
                subtitle: "步/分钟",
                color: .purple
            ),
            WorkoutMetricData(
                icon: "ruler",
                title: "平均步幅",
                value: "\(avgStride)",
                subtitle: "厘米",
                color: .indigo
            ),
            WorkoutMetricData(
                icon: "heart.fill",
                title: "最大心率",
                value: "\(workoutDataManager.maxHeartRate)",
                subtitle: "bpm",
                color: .red
            ),
            WorkoutMetricData(
                icon: "arrow.up.circle",
                title: "海拔变化",
                value: String(format: "%.0f", elevation),
                subtitle: "累计爬升",
                color: .orange
            )
        ]
    }

    /// 骑行模式专用指标
    private func getCyclingMetrics() -> [WorkoutMetricData] {
        let avgSpeed = distance > 0 && locationManager.duration > 0 ?
            (distance / (locationManager.duration / 3600.0)) : 0.0
        let maxSpeed = avgSpeed * 1.3 // 估算最大速度
        let power = Int(avgSpeed * 70.0 * 2.5) // 估算功率（假设体重70kg）
        let cadenceRpm = Int(Double(cadence) * 0.6) // 转换为踏频(转/分)

        return [
            WorkoutMetricData(
                icon: "speedometer",
                title: "平均时速",
                value: String(format: "%.1f", avgSpeed),
                subtitle: "km/h",
                color: .blue
            ),
            WorkoutMetricData(
                icon: "gauge.high",
                title: "最高时速",
                value: String(format: "%.1f", maxSpeed),
                subtitle: "km/h",
                color: .green
            ),
            WorkoutMetricData(
                icon: "bolt.fill",
                title: "功率",
                value: "\(power)",
                subtitle: "瓦特",
                color: .yellow
            ),
            WorkoutMetricData(
                icon: "metronome",
                title: "踏频",
                value: "\(cadenceRpm)",
                subtitle: "转/分钟",
                color: .purple
            ),
            WorkoutMetricData(
                icon: "heart.fill",
                title: "平均心率",
                value: "\(workoutDataManager.averageHeartRate)",
                subtitle: "bpm",
                color: .red
            ),
            WorkoutMetricData(
                icon: "arrow.up.circle",
                title: "海拔变化",
                value: String(format: "%.0f", elevation),
                subtitle: "累计爬升",
                color: .orange
            )
        ]
    }

    /// 徒步模式专用指标
    private func getHikingMetrics() -> [WorkoutMetricData] {
        let avgElevationGain = elevation / max(distance, 0.1) // 每公里爬升

        return [
            WorkoutMetricData(
                icon: "figure.hiking",
                title: "步数",
                value: "\(steps)",
                subtitle: "总步数",
                color: .blue
            ),
            WorkoutMetricData(
                icon: "mountain.2.fill",
                title: "爬升强度",
                value: String(format: "%.0f", avgElevationGain),
                subtitle: "米/公里",
                color: .brown
            ),
            WorkoutMetricData(
                icon: "metronome",
                title: "步频",
                value: "\(cadence)",
                subtitle: "步/分钟",
                color: .purple
            ),
            WorkoutMetricData(
                icon: "speedometer",
                title: "徒步配速",
                value: formatPace(averagePace),
                subtitle: "分/公里",
                color: .green
            ),
            WorkoutMetricData(
                icon: "heart.fill",
                title: "心率区间",
                value: getHeartRateZone(),
                subtitle: "运动强度",
                color: .red
            ),
            WorkoutMetricData(
                icon: "arrow.up.circle",
                title: "总爬升",
                value: String(format: "%.0f", elevation),
                subtitle: "累计爬升",
                color: .orange
            )
        ]
    }

    /// 获取游泳指标数据
    private func getSwimmingMetrics() -> [WorkoutMetricData] {
        return [
            WorkoutMetricData(
                icon: "figure.pool.swim",
                title: "游泳距离",
                value: String(format: "%.2f", distance),
                subtitle: "公里",
                color: .cyan
            ),
            WorkoutMetricData(
                icon: "clock.fill",
                title: "游泳时长",
                value: formatDuration(locationManager.duration),
                subtitle: "运动时间",
                color: .blue
            ),
            WorkoutMetricData(
                icon: "heart.fill",
                title: "平均心率",
                value: "\(heartRate)",
                subtitle: "bpm",
                color: .red
            ),
            WorkoutMetricData(
                icon: "flame.fill",
                title: "消耗热量",
                value: String(format: "%.0f", calories),
                subtitle: "千卡",
                color: .orange
            )
        ]
    }

    /// 获取瑜伽指标数据
    private func getYogaMetrics() -> [WorkoutMetricData] {
        return [
            WorkoutMetricData(
                icon: "figure.yoga",
                title: "练习时长",
                value: formatDuration(locationManager.duration),
                subtitle: "分钟",
                color: .purple
            ),
            WorkoutMetricData(
                icon: "heart.fill",
                title: "平均心率",
                value: "\(heartRate)",
                subtitle: "bpm",
                color: .red
            ),
            WorkoutMetricData(
                icon: "flame.fill",
                title: "消耗热量",
                value: String(format: "%.0f", calories),
                subtitle: "千卡",
                color: .orange
            ),
            WorkoutMetricData(
                icon: "leaf.fill",
                title: "放松指数",
                value: "深度",
                subtitle: "身心状态",
                color: .green
            )
        ]
    }

    /// 获取力量训练指标数据
    private func getStrengthMetrics() -> [WorkoutMetricData] {
        return [
            WorkoutMetricData(
                icon: "dumbbell",
                title: "训练时长",
                value: formatDuration(locationManager.duration),
                subtitle: "分钟",
                color: .brown
            ),
            WorkoutMetricData(
                icon: "heart.fill",
                title: "平均心率",
                value: "\(heartRate)",
                subtitle: "bpm",
                color: .red
            ),
            WorkoutMetricData(
                icon: "flame.fill",
                title: "消耗热量",
                value: String(format: "%.0f", calories),
                subtitle: "千卡",
                color: .orange
            ),
            WorkoutMetricData(
                icon: "bolt.fill",
                title: "训练强度",
                value: "高强度",
                subtitle: "力量训练",
                color: .yellow
            )
        ]
    }

    /// 获取其他运动指标数据
    private func getOtherMetrics() -> [WorkoutMetricData] {
        return [
            WorkoutMetricData(
                icon: "figure.mixed.cardio",
                title: "运动时长",
                value: formatDuration(locationManager.duration),
                subtitle: "分钟",
                color: .gray
            ),
            WorkoutMetricData(
                icon: "heart.fill",
                title: "平均心率",
                value: "\(heartRate)",
                subtitle: "bpm",
                color: .red
            ),
            WorkoutMetricData(
                icon: "flame.fill",
                title: "消耗热量",
                value: String(format: "%.0f", calories),
                subtitle: "千卡",
                color: .orange
            ),
            WorkoutMetricData(
                icon: "chart.line.uptrend.xyaxis",
                title: "活跃度",
                value: "中等",
                subtitle: "运动强度",
                color: .blue
            )
        ]
    }





    /// 获取训练负荷
    private func getTrainingLoad() -> String {
        let intensity = Double(heartRate) / Double(220 - workoutDataManager.userAge)
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

    /// 获取恢复时间
    private func getRecoveryTime() -> String {
        let intensity = Double(heartRate) / Double(220 - workoutDataManager.userAge)
        let recoveryHours = intensity * (locationManager.duration / 3600.0) * 12

        if recoveryHours < 1 {
            return "< 1小时"
        } else if recoveryHours < 24 {
            return String(format: "%.0f小时", recoveryHours)
        } else {
            return String(format: "%.1f天", recoveryHours / 24)
        }
    }

    /// 获取地形难度
    private func getTerrainDifficulty() -> String {
        let elevationGain = elevation / max(distance, 0.1)

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

    /// 格式化时长
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    // MARK: - AI运动教练相关方法

    /// 启动AI运动教练
    private func startAICoach() {
        print("🤖 启动AI运动教练")

        // 发送运动开始首问
        Task<Void, Never> {
            do {
                await MainActor.run {
                    // 在主线程上执行
                }
                let response: WorkoutAIAnalysisResponse = try await aiCoachService.startWorkout(
                    workoutType: workoutType,
                    userId: UserManager.shared.currentUser?.id != nil ? String(UserManager.shared.currentUser!.id) : nil
                )

                if response.success {
                    hasPlayedWelcome = true
                    print("✅ AI教练欢迎语音已播放")
                }
            } catch {
                print("❌ AI教练启动失败: \(error)")
            }
        }

        // 启动定期分析
        startAIAnalysisTimer()
    }

    /// 停止AI运动教练
    private func stopAICoach() {
        print("🤖 停止AI运动教练")

        aiAnalysisTimer?.invalidate()
        aiAnalysisTimer = nil

        // 停止音频播放
        audioPlayer.stopAudio()
    }

    /// 启动AI分析定时器
    private func startAIAnalysisTimer() {
        aiAnalysisTimer?.invalidate()

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

    /// 执行AI分析
    private func performAIAnalysis() async {
        guard isActive && !isPaused else { return }

        do {
            let response: WorkoutAIAnalysisResponse = try await aiCoachService.analyzeWorkout(
                workoutType: workoutType,
                heartRate: heartRate > 0 ? heartRate : nil,
                cadence: cadence > 0 ? cadence : nil,
                pace: currentPace > 0 ? currentPace : nil,
                distance: distance > 0 ? distance : nil,
                duration: currentTime > 0 ? Int(currentTime) : nil,
                userId: UserManager.shared.currentUser?.id != nil ? String(UserManager.shared.currentUser!.id) : nil
            )

            if response.success, let data = response.data {
                lastAIGuidanceTime = Date()

                // 根据分析结果更新UI状态
                updateUIBasedOnAIAnalysis(data.analysis)

                print("🤖 AI分析完成 - 指导: \(data.guidance.message)")
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
                heartRate: heartRate > 0 ? heartRate : nil,
                cadence: cadence > 0 ? cadence : nil,
                pace: currentPace > 0 ? currentPace : nil
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



}

#Preview {
    WorkoutLiveView(
        workoutType: WorkoutType.running,
        workoutMode: WorkoutMode.free
    )
}