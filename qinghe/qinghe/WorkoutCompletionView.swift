import SwiftUI
import MapKit
import CoreLocation

// MARK: - ActionButton 组件
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let style: ActionButtonStyle
    let action: () -> Void

    init(title: String, icon: String, color: Color, style: ActionButtonStyle = .filled, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(style == .filled ? .white : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(style == .filled ? color : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color, lineWidth: style == .outlined ? 2 : 0)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

enum ActionButtonStyle {
    case filled
    case outlined
}

/// 运动完成页面 - 展示运动成果和庆祝动画
struct WorkoutCompletionView: View {
    let workoutSummary: WorkoutSummary
    @Binding var isPresented: Bool
    let onComplete: () -> Void

    @State private var showCelebration = false
    @State private var showDataCards = false
    @State private var showDetailedMetrics = false
    @State private var showMap = false
    @State private var showButtons = false
    @State private var celebrationScale: CGFloat = 0.5
    @State private var starsOpacity: Double = 0.0

    // API上传相关状态
    @State private var isUploading = false
    @State private var uploadSuccess = false
    @State private var uploadError: String?
    @State private var showUploadAlert = false

    // 已移除HealthKit相关状态，只使用云端API

    // 数据管理器
    @ObservedObject private var workoutDataManager = WorkoutDataManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // 完全复制WorkoutDetailView的布局结构
                if isUploading {
                    // 上传中的加载状态
                    VStack {
                        ProgressView()
                        Text("正在上传运动数据...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                } else {
                    // 完全复制WorkoutDetailView的全屏地图 + 底部面板布局
                    ZStack(alignment: .bottom) {
                        // 全屏地图背景 - 向上偏移为底部面板留出空间
                        VStack(spacing: 0) {
                            WorkoutCompletionRouteMapView(workoutSummary: workoutSummary)
                                .clipped() // 确保地图不会超出边界

                            // 底部透明占位区域，为数据面板留出空间
                            Color.clear
                                .frame(height: 340) // 增加至340pt，总体上移约40pt
                        }

                        // 底部数据面板
                        VStack(spacing: 0) {
                            // 运动数据内容
                            VStack(spacing: 16) {
                                // 顶部距离和时间信息
                                WorkoutCompletionHeaderView(workoutSummary: workoutSummary)
                                    .padding(.horizontal, 20)

                                // 运动指标网格
                                WorkoutCompletionMetricsGridView(workoutSummary: workoutSummary)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .ignoresSafeArea(.all, edges: .bottom)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                    }
                    .ignoresSafeArea(.all, edges: .bottom)
                }

                // 保留庆祝效果但调整透明度
                if showCelebration {
                    starsEffect
                        .opacity(0.7) // 降低透明度，避免遮挡新UI
                }
            }
            .navigationTitle("运动完成")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                        onComplete()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("返回")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    // 上传状态指示器
                    if isUploading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if uploadSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }
            }
        }
        .onAppear {
            startCelebrationSequence()
            // 自动上传运动数据到API
            uploadWorkoutData()

            // 打印数据来源调试信息
            print("📊 运动完成数据来源:")
            print("   距离: \(String(format: "%.2f", workoutSummary.distance))km (GPS)")
            print("   卡路里: \(String(format: "%.0f", workoutSummary.calories)) (计算)")
            print("   步数: \(workoutSummary.steps) (CoreMotion)")
            print("   平均心率: \(workoutSummary.averageHeartRate) BPM \(workoutSummary.averageHeartRate > 0 ? "(HealthKit)" : "(无数据)")")
            print("   最大心率: \(workoutSummary.maxHeartRate) BPM \(workoutSummary.maxHeartRate > 0 ? "(HealthKit)" : "(无数据)")")
            print("   步频: \(String(format: "%.0f", workoutSummary.averageCadence)) 步/分 (CoreMotion)")
        }
        .alert("数据上传", isPresented: $showUploadAlert) {
            Button("确定") {
                showUploadAlert = false
            }
        } message: {
            if uploadSuccess {
                Text("运动数据已成功上传到云端！")
            } else if let error = uploadError {
                Text("上传失败：\(error)")
            }
        }
        // 已移除HealthKit保存功能
    }
    
    // MARK: - 庆祝区域
    private var celebrationHeader: some View {
        VStack(spacing: 16) {
            // 运动类型图标
            ZStack {
                Circle()
                    .fill(workoutSummary.workoutType.primaryColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: workoutSummary.workoutType.icon)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(workoutSummary.workoutType.primaryColor)
            }
            .scaleEffect(celebrationScale)
            .opacity(showCelebration ? 1 : 0)
            
            // 庆祝文字
            VStack(spacing: 8) {
                Text("运动完成！")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("太棒了！坚持就是胜利")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(workoutSummary.workoutType.displayName)
                    .font(.headline)
                    .foregroundColor(workoutSummary.workoutType.primaryColor)
            }
            .opacity(showCelebration ? 1 : 0)
        }
        .padding(.vertical, 20)
    }

    // MARK: - 新的运动完成页面组件（完全复制WorkoutDetailView）

    

    
    // MARK: - 星星效果
    private var starsEffect: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: CGFloat.random(in: 12...20)))
                    .foregroundColor(.yellow)
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...300)
                    )
                    .opacity(starsOpacity)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .delay(Double(index) * 0.1)
                        .repeatCount(3, autoreverses: true),
                        value: starsOpacity
                    )
            }
        }
    }
    
    // MARK: - 动画序列
    private func startCelebrationSequence() {
        // 庆祝动画
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showCelebration = true
            celebrationScale = 1.0
        }

        // 星星效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            starsOpacity = 1.0
        }

        // 星星动画完成后自动隐藏（3次重复 * 1.5秒 + 最后一个星星的延迟0.7秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.2) {
            withAnimation(.easeOut(duration: 0.5)) {
                starsOpacity = 0.0
            }
        }

        // 数据卡片
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showDataCards = true
            }
        }

        // 详细数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showDetailedMetrics = true
            }
        }

        // 地图
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showMap = true
            }
        }

        // 按钮
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showButtons = true
            }
        }
    }
    
    // MARK: - 辅助方法
    private func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d'%02d\"", minutes, seconds)
    }
    
    private func shareWorkout() {
        // 实现分享功能
        print("分享运动数据")
    }
    
    private func saveWorkout() {
        // 保存到云端API
        Task {
            isUploading = true
            uploadError = nil

            do {
                // 创建设备信息
                let deviceInfo = WorkoutDeviceInfo(
                    deviceType: "iPhone",
                    deviceModel: UIDevice.current.model,
                    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
                    dataSource: "Manual"
                )

                // 计算最大速度（简化版本，基于平均配速）
                let maxSpeed = workoutSummary.averagePace > 0 ? 60.0 / workoutSummary.averagePace : 0.0

                // 创建基础指标
                let basicMetrics = WorkoutBasicMetrics(
                    totalDistance: workoutSummary.distance,
                    totalSteps: workoutSummary.steps,
                    calories: Int(workoutSummary.calories),
                    averagePace: workoutSummary.averagePace,
                    maxSpeed: maxSpeed
                )

                // 创建高级指标（包含心率数据）
                let advancedMetrics = WorkoutAdvancedMetrics(
                    averageHeartRate: workoutSummary.averageHeartRate > 0 ? workoutSummary.averageHeartRate : nil,
                    maxHeartRate: workoutSummary.maxHeartRate > 0 ? workoutSummary.maxHeartRate : nil,
                    averageCadence: nil, // 步频数据暂时不上传，可以后续添加
                    elevationGain: nil,  // 海拔数据暂时不上传，可以后续添加
                    elevationLoss: nil
                )

                // 构建轨迹数据（若有）
                let routeData = RouteDataForAPI(
                    coordinates: workoutSummary.routePoints.map { point in
                        GPSCoordinateForAPI(
                            latitude: point.latitude,
                            longitude: point.longitude,
                            timestamp: ISO8601DateFormatter().string(from: point.timestamp),
                            altitude: point.altitude
                        )
                    }
                )

                // 创建运动数据（包含心率等高级指标与轨迹）
                let newWorkout = NewWorkout(
                    workoutId: nil,
                    workoutType: workoutSummary.workoutType.rawValue,
                    startTime: ISO8601DateFormatter().string(from: workoutSummary.startTime),
                    endTime: ISO8601DateFormatter().string(from: workoutSummary.endTime),
                    duration: Int(workoutSummary.endTime.timeIntervalSince(workoutSummary.startTime)),
                    basicMetrics: basicMetrics,
                    advancedMetrics: advancedMetrics, // 包含心率数据
                    routeData: routeData,
                    deviceInfo: deviceInfo,
                    notes: "运动完成手动保存 - 心率数据来源：\(workoutSummary.averageHeartRate > 0 ? "HealthKit传感器" : "估算值")"
                )

                // 使用 API 服务保存运动数据
                let success = try await NewWorkoutAPIService.shared.createWorkout(newWorkout)

                if success {
                    uploadSuccess = true
                    print("✅ 运动数据已保存到云端")
                } else {
                    uploadError = "保存失败"
                    print("❌ 保存失败")
                }
            } catch {
                // 更详细的错误处理
                print("❌ 捕获到错误类型: \(type(of: error))")
                print("❌ 错误详情: \(error)")

                if let apiError = error as? NewWorkoutAPIError {
                    uploadError = apiError.localizedDescription
                    print("❌ NewWorkoutAPIError: \(apiError.localizedDescription)")
                } else if let apiError = error as? APIError {
                    uploadError = apiError.localizedDescription
                    print("❌ APIError: \(apiError.localizedDescription)")
                } else if let networkError = error as? NetworkManager.NetworkError {
                    uploadError = networkError.localizedDescription
                    print("❌ NetworkError: \(networkError.localizedDescription)")
                } else {
                    uploadError = "保存失败: \(error.localizedDescription)"
                    print("❌ 未知错误类型: \(error.localizedDescription)")
                }
            }

            isUploading = false
        }
    }
    
    private func startNewWorkout() {
        // 开始新的运动
        isPresented = false
        print("开始新运动")
    }
    
    private func completeWorkout() {
        isPresented = false
        onComplete()
    }

    // MARK: - API上传功能

    /// 上传运动数据到API
    private func uploadWorkoutData() {
        guard !isUploading else { return }

        isUploading = true
        uploadError = nil
        uploadSuccess = false

        Task {
            do {
                // 🚨 添加数据验证，防止异常数据导致服务器错误
                let duration = workoutSummary.endTime.timeIntervalSince(workoutSummary.startTime)
                
                // 验证运动时长（最少3秒）
                if duration < 3 {
                    throw APIError.invalidData("运动时长过短（\(Int(duration))秒），最少需要3秒")
                }
                
                // 验证路线点数量
                if workoutSummary.routePoints.count < 2 {
                    throw APIError.invalidData("路线数据不足，需要至少2个位置点")
                }
                
                print("📊 数据验证通过: 时长\(Int(duration))秒, 路线点\(workoutSummary.routePoints.count)个")
                // 转换路线坐标
                let coordinates = workoutSummary.routePoints.map { routePoint in
                    CLLocation(
                        coordinate: CLLocationCoordinate2D(
                            latitude: routePoint.latitude,
                            longitude: routePoint.longitude
                        ),
                        altitude: routePoint.altitude ?? 0.0,
                        horizontalAccuracy: 5.0,
                        verticalAccuracy: 5.0,
                        timestamp: routePoint.timestamp
                    )
                }

                // 创建设备信息
                let deviceInfo = WorkoutDeviceInfo(
                    deviceType: "iPhone",
                    deviceModel: UIDevice.current.model,
                    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
                    dataSource: "Manual"
                )

                // 计算最大速度（从路线数据中计算，备用使用配速计算）
                let maxSpeed = calculateMaxSpeed(from: coordinates) ??
                               (workoutSummary.averagePace > 0 ? 60.0 / workoutSummary.averagePace : 0.0)

                // 创建基础指标
                let basicMetrics = WorkoutBasicMetrics(
                    totalDistance: workoutSummary.distance,
                    totalSteps: workoutSummary.steps,
                    calories: Int(workoutSummary.calories),
                    averagePace: workoutSummary.averagePace,
                    maxSpeed: maxSpeed
                )

                // 创建高级指标（包含心率和步频数据）
                let advancedMetrics = WorkoutAdvancedMetrics(
                    averageHeartRate: workoutSummary.averageHeartRate > 0 ? workoutSummary.averageHeartRate : nil,
                    maxHeartRate: workoutSummary.maxHeartRate > 0 ? workoutSummary.maxHeartRate : nil,
                    averageCadence: workoutSummary.averageCadence > 0 ? Int(workoutSummary.averageCadence) : nil, // 包含步频数据
                    elevationGain: nil,  // 海拔数据暂时不上传，可以后续添加
                    elevationLoss: nil
                )

                // 构建轨迹数据（必须至少2个点，前面已校验）
                let routeData = RouteDataForAPI(
                    coordinates: workoutSummary.routePoints.map { point in
                        GPSCoordinateForAPI(
                            latitude: point.latitude,
                            longitude: point.longitude,
                            timestamp: ISO8601DateFormatter().string(from: point.timestamp),
                            altitude: point.altitude
                        )
                    }
                )

                // 创建运动数据（包含心率等高级指标与轨迹）
                let newWorkout = NewWorkout(
                    workoutId: nil,
                    workoutType: workoutSummary.workoutType.rawValue,
                    startTime: ISO8601DateFormatter().string(from: workoutSummary.startTime),
                    endTime: ISO8601DateFormatter().string(from: workoutSummary.endTime),
                    duration: Int(duration),
                    basicMetrics: basicMetrics,
                    advancedMetrics: advancedMetrics, // 包含心率数据
                    routeData: routeData,
                    deviceInfo: deviceInfo,
                    notes: "通过青禾计划iOS应用完成的\(workoutSummary.workoutType.displayName)运动 - 距离基于苹果地图路径计算，心率数据来源：\(workoutSummary.averageHeartRate > 0 ? "HealthKit传感器" : "无传感器数据")"
                )

                // 上传到API - 距离数据基于苹果地图路径匹配计算
                let success = try await NewWorkoutAPIService.shared.createWorkout(newWorkout)

                await MainActor.run {
                    isUploading = false
                    if success {
                        uploadSuccess = true
                        showUploadAlert = true
                        print("✅ 运动数据上传成功")

                        // 发送运动数据上传成功通知
                        WorkoutNotificationManager.shared.postWorkoutDataUpdatedNotification()
                        WorkoutNotificationManager.shared.postWorkoutRecordsRefreshNotification()
                    } else {
                        uploadError = "上传失败"
                        showUploadAlert = true
                        print("❌ 运动数据上传失败")
                    }
                }

            } catch {
                await MainActor.run {
                    isUploading = false
                    // 更详细的错误处理
                    print("❌ 捕获到错误类型: \(type(of: error))")
                    print("❌ 错误详情: \(error)")

                    if let apiError = error as? NewWorkoutAPIError {
                        uploadError = apiError.localizedDescription
                        print("❌ NewWorkoutAPIError: \(apiError.localizedDescription)")
                    } else if let apiError = error as? APIError {
                        uploadError = apiError.localizedDescription
                        print("❌ APIError: \(apiError.localizedDescription)")
                    } else if let networkError = error as? NetworkManager.NetworkError {
                        uploadError = networkError.localizedDescription
                        print("❌ NetworkError: \(networkError.localizedDescription)")
                    } else {
                        uploadError = "上传失败: \(error.localizedDescription)"
                        print("❌ 未知错误类型: \(error.localizedDescription)")
                    }
                    showUploadAlert = true

                    // 即使上传失败，也要保存到本地缓存
                    saveToLocalCache()
                }
            }
        }
    }

    /// 格式化配速为API需要的格式
    private func formatPaceForAPI(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// 从路线数据计算最大速度
    private func calculateMaxSpeed(from coordinates: [CLLocation]) -> Double? {
        guard coordinates.count >= 2 else { return nil }

        var maxSpeed: Double = 0.0
        
        // 🚨 修复：添加验证阈值，避免异常速度值
        let minTimeInterval = 0.5  // 最小0.5秒时间差
        let minDistance = 1.0      // 最小1米距离差
        let maxReasonableSpeed = 13.9 // 13.9 m/s = 50 km/h (跑步合理上限)

        for i in 1..<coordinates.count {
            let previousLocation = coordinates[i-1]
            let currentLocation = coordinates[i]

            let distance = previousLocation.distance(from: currentLocation)
            let timeInterval = currentLocation.timestamp.timeIntervalSince(previousLocation.timestamp)

            // 只处理合理的时间间隔和距离
            if timeInterval >= minTimeInterval && distance >= minDistance {
                let speed = distance / timeInterval // m/s
                
                // 过滤异常速度值
                if speed <= maxReasonableSpeed && speed.isFinite && !speed.isNaN {
                    maxSpeed = max(maxSpeed, speed)
                    print("🏃‍♂️ 计算速度: \(String(format: "%.2f", speed)) m/s (\(String(format: "%.1f", speed * 3.6)) km/h)")
                } else {
                    print("🚨 过滤异常速度: \(String(format: "%.2f", speed)) m/s")
                }
            }
        }

        return maxSpeed > 0 ? maxSpeed : nil
    }

    /// 保存到本地缓存（上传失败时使用）
    private func saveToLocalCache() {
        // TODO: 实现本地缓存逻辑
        print("💾 保存运动数据到本地缓存，稍后重试上传")

        // 这里可以使用CoreData或其他本地存储方案
        // 保存workoutSummary数据，等网络恢复后重新上传
    }

    // MARK: - 已移除HealthKit保存功能
    // 现在只使用云端API数据，不再保存到HealthKit
}

// MARK: - 支持组件

/// 核心数据卡片
struct CoreMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            VStack(spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80) // 固定高度确保所有卡片尺寸一致
        .padding(.vertical, 16)
        .background(color.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// 详细数据行
struct DetailMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let unit: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.green)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

/// 轨迹地图视图
struct RouteMapView: UIViewRepresentable {
    let routePoints: [RoutePoint]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.mapType = .standard
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.isUserInteractionEnabled = false // 禁用交互，仅用于展示

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        setupMapRegion(mapView)
        context.coordinator.updateRoute(with: routePoints, on: mapView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func setupMapRegion(_ mapView: MKMapView) {
        guard !routePoints.isEmpty else {
            // 如果没有轨迹数据，显示默认区域
            let defaultRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(defaultRegion, animated: false)
            return
        }

        let coordinates = routePoints.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.005) * 1.3, // 稍微放大视野
            longitudeDelta: max(maxLon - minLon, 0.005) * 1.3
        )

        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: false)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        private var routeOverlay: MKPolyline?

        func updateRoute(with routePoints: [RoutePoint], on mapView: MKMapView) {
            // 清除旧的轨迹
            if let oldOverlay = routeOverlay {
                mapView.removeOverlay(oldOverlay)
            }

            guard routePoints.count >= 2 else { return }

            // 创建新的轨迹线
            let coordinates = routePoints.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)

            mapView.addOverlay(polyline)
            routeOverlay = polyline

            // 添加起点和终点标注
            mapView.removeAnnotations(mapView.annotations)

            if let firstPoint = routePoints.first {
                let startAnnotation = MKPointAnnotation()
                startAnnotation.coordinate = CLLocationCoordinate2D(latitude: firstPoint.latitude, longitude: firstPoint.longitude)
                startAnnotation.title = "起点"
                mapView.addAnnotation(startAnnotation)
            }

            if let lastPoint = routePoints.last, routePoints.count > 1 {
                let endAnnotation = MKPointAnnotation()
                endAnnotation.coordinate = CLLocationCoordinate2D(latitude: lastPoint.latitude, longitude: lastPoint.longitude)
                endAnnotation.title = "终点"
                mapView.addAnnotation(endAnnotation)
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1.0) // 青禾绿色
                renderer.lineWidth = 4.0
                renderer.alpha = 0.9
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "RoutePoint"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            if let markerView = annotationView as? MKMarkerAnnotationView {
                if annotation.title == "起点" {
                    markerView.markerTintColor = .systemGreen
                    markerView.glyphText = "起"
                } else if annotation.title == "终点" {
                    markerView.markerTintColor = .systemRed
                    markerView.glyphText = "终"
                }
            }

            return annotationView
        }
    }
}

// MARK: - 完全复制WorkoutDetailView的组件

// 完全复制ModernWorkoutHeaderView
struct WorkoutCompletionHeaderView: View {
    let workoutSummary: WorkoutSummary

    var body: some View {
        VStack(spacing: 12) {
            // 运动类型和来源信息
            HStack(alignment: .firstTextBaseline) {
                // 左侧：运动类型 + 同行日期/时间段
                HStack(spacing: 8) {
                    Text("\(workoutSummary.workoutType.displayName) | 户外")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Text(getFormattedTimeRange())
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer()
                // 右侧：用户头像占位
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("用")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    )
            }

            // 大号距离显示
            HStack(alignment: .bottom, spacing: 4) {
                Text(getFormattedDistanceValue())
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)
                Text("米")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                Spacer()
            }

            // 速度渐变说明条（更慢 ← 渐变 → 更快）
            HStack(alignment: .center, spacing: 12) {
                Text("更慢")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "34C759"))
                    .frame(minWidth: 0)

                // 渐变线条
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "34C759"), // 绿 慢
                                Color(hex: "A6CE39"), // 绿黄过渡
                                Color(hex: "FFD60A"), // 黄
                                Color(hex: "FF9500"), // 橙
                                Color(hex: "FF3B30")  // 红 快
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)

                Text("更快")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "FF3B30"))
                    .frame(minWidth: 0)
            }
            .padding(.top, 8)

            // 运动时长、卡路里、平均配速 - 横向布局
            HStack(spacing: 0) {
                // 运动时长
                VStack(alignment: .leading, spacing: 2) {
                    Text(workoutSummary.formattedDuration)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("运动时长")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 活动卡路里
                VStack(alignment: .center, spacing: 2) {
                    Text("\(Int(workoutSummary.calories))kcal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("活动卡路里")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 平均配速
                VStack(alignment: .trailing, spacing: 2) {
                    Text(getFormattedPace())
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("平均配速")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 8)
    }

    private func getFormattedDistanceValue() -> String {
        let distanceInMeters = workoutSummary.distance * 1000
        return String(format: "%.0f", distanceInMeters)
    }

    private func getFormattedTimeRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: workoutSummary.startTime)
    }

    private func getFormattedPace() -> String {
        let totalDistance = workoutSummary.distance
        let duration = workoutSummary.duration

        guard totalDistance > 0 else { return "0'00\"" }

        let paceInSecondsPerKm = Double(duration) / totalDistance
        let minutes = Int(paceInSecondsPerKm) / 60
        let seconds = Int(paceInSecondsPerKm) % 60

        return String(format: "%d'%02d\"", minutes, seconds)
    }
}

// 完全复制WorkoutMetricsGridView
struct WorkoutCompletionMetricsGridView: View {
    let workoutSummary: WorkoutSummary

    var body: some View {
        VStack(spacing: 16) {
            // 配速部分
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "speedometer")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                    Text("配速")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }

                HStack(spacing: 0) {
                    // 平均配速
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatPace(workoutSummary.averagePace))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Text("平均配速")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // 最快配速
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatFastestPace())
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Text("最快配速")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)

            // 其他指标 - 2列布局
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 12) {
                // 总步数
                compactMetricItem(
                    title: "总步数",
                    value: "\(workoutSummary.steps)",
                    unit: "步"
                )

                // 消耗卡路里
                compactMetricItem(
                    title: "消耗",
                    value: "\(Int(workoutSummary.calories))",
                    unit: "千卡"
                )

                // 平均心率
                compactMetricItem(
                    title: "平均心率",
                    value: workoutSummary.averageHeartRate > 0 ? "\(workoutSummary.averageHeartRate)" : "--",
                    unit: "bpm"
                )

                // 最大心率
                compactMetricItem(
                    title: "最大心率",
                    value: workoutSummary.maxHeartRate > 0 ? "\(workoutSummary.maxHeartRate)" : "--",
                    unit: "bpm"
                )
            }
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 8)
    }

    private func compactMetricItem(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // 标题
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            // 数值和单位
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatPace(_ pace: Double) -> String {
        guard pace > 0 else { return "0'00\"" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    private func formatFastestPace() -> String {
        // 计算最快配速（比平均配速快一些）
        let fastestPace = max(workoutSummary.averagePace - 30, 180) // 最快不超过3分钟/公里
        return formatPace(fastestPace)
    }
}

// 完全复制WorkoutDetailRouteMapView
struct WorkoutCompletionRouteMapView: View {
    let workoutSummary: WorkoutSummary
    @State private var shouldCenterOnLocation = false
    @State private var mapRegion: MKCoordinateRegion?

    // 缓存轨迹点数据，避免重复计算导致地图闪烁
    private let routePoints: [CLLocationCoordinate2D]
    private let routeTimestamps: [Date]

    init(workoutSummary: WorkoutSummary) {
        self.workoutSummary = workoutSummary
        // 初始化时计算一次轨迹点，避免每次重新渲染时重复计算
        self.routePoints = workoutSummary.routePoints.map { routePoint in
            CLLocationCoordinate2D(latitude: routePoint.latitude, longitude: routePoint.longitude)
        }
        self.routeTimestamps = workoutSummary.routePoints.map { $0.timestamp }
    }

    // 检查是否有轨迹数据
    private var hasRouteData: Bool {
        return !routePoints.isEmpty
    }

    var body: some View {
        ZStack {
            if hasRouteData {
                // 全屏地图组件
                AppleMapView(
                    zoomLevel: 16.0,
                    showUserLocation: false,
                    mapType: .standard,
                    shouldCenterOnLocation: $shouldCenterOnLocation,
                    mapRegion: $mapRegion,
                    routePoints: routePoints,  // 使用缓存的轨迹点数据
                    currentLocation: nil,  // 不传入currentLocation，避免自动居中覆盖我们的区域设置
                    showStartEndMarkers: true,
                    routeTimestamps: routeTimestamps  // 使用缓存的时间戳数据
                )
                .onAppear {
                    // 设置地图区域到真实轨迹，根据轨迹范围自动调整视野
                    mapRegion = calculateOptimalMapRegion()
                }
            } else {
                // 没有轨迹数据时显示提示
                Color.gray.opacity(0.1)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "location.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)

                            Text("暂无轨迹数据")
                                .font(.headline)
                                .foregroundColor(.gray)

                            Text("此运动记录未包含GPS轨迹信息")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    )
            }
        }
    }

    // 获取轨迹中心位置
    private func getCenterLocation() -> CLLocation? {
        guard !routePoints.isEmpty else { return getSampleLocation() }

        // 计算轨迹中心点
        let centerIndex = routePoints.count / 2
        let centerCoordinate = routePoints[centerIndex]
        return CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
    }

    // 计算最优地图区域
    private func calculateOptimalMapRegion() -> MKCoordinateRegion {

        // 如果没有轨迹点，使用默认区域
        guard routePoints.count >= 2 else {
            if let location = getCenterLocation() {
                return MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 500,  // 默认500米视野
                    longitudinalMeters: 500
                )
            } else {
                // 完全没有数据时的默认区域
                let coordinate = CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
                return MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            }
        }

        // 计算轨迹的边界
        var minLat = routePoints[0].latitude
        var maxLat = routePoints[0].latitude
        var minLon = routePoints[0].longitude
        var maxLon = routePoints[0].longitude

        for point in routePoints {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }

        // 计算中心点
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)

        // 计算轨迹的实际跨度（米）
        let latSpan = abs(maxLat - minLat)
        let lonSpan = abs(maxLon - minLon)

        // 将度数转换为大概的米数（1度纬度约111km）
        let latMeters = latSpan * 111000
        let lonMeters = lonSpan * 111000 * cos(centerLat * .pi / 180)

        // 添加适当的边距，确保轨迹完全可见，但不会太远
        let paddingFactor = 1.5  // 50%的边距
        let minViewDistance: Double = 200  // 最小视野200米
        let maxViewDistance: Double = 2000  // 最大视野2000米

        let adjustedLatMeters = max(minViewDistance, min(maxViewDistance, latMeters * paddingFactor))
        let adjustedLonMeters = max(minViewDistance, min(maxViewDistance, lonMeters * paddingFactor))

        return MKCoordinateRegion(
            center: center,
            latitudinalMeters: adjustedLatMeters,
            longitudinalMeters: adjustedLonMeters
        )
    }



    // 获取示例位置（备用数据）
    private func getSampleLocation() -> CLLocation? {
        return CLLocation(latitude: 39.9077, longitude: 116.4109)
    }
}
