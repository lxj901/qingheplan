import SwiftUI
import MapKit
import CoreLocation

/// 运动详情页面 - 基于您提供的设计图重新实现
struct ActivityDetailView: View {
    var body: some View {
        ZStack {
            // 背景色
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 固定的顶部导航栏
                TopBarView()
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 15)
                    .background(Color(UIColor.systemGroupedBackground))

                // 可滚动的内容区域
                ScrollView {
                    VStack(spacing: 24) {
                        // 主要运动数据（时长和距离）
                        MainMetricsView()
                            .padding(.horizontal, 20)

                        // 运动轨迹地图
                        WorkoutRouteMapView()
                            .frame(height: 200)
                            .padding(.horizontal, 20)

                        // 心率、步频和卡路里数据
                        HeartRateAndCadenceView()
                            .padding(.horizontal, 20)

                        // 心率和配速图表（合并在一个卡片中）
                        HeartRateAndPaceChartsView()
                            .padding(.horizontal, 20)

                        // 底部间距
                        Color.clear.frame(height: 50)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Top Bar
struct TopBarView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            Spacer()

            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("跑步 · 户外")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                Text("2025年9月10日 07:30")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { /* more options */ }) {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Main Metrics (时长和距离)
struct MainMetricsView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))

            HStack(spacing: 0) {
                // 时长
                VStack(spacing: 8) {
                    Text("38:00")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                    Text("时长")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // 分割线
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1, height: 60)

                // 距离
                VStack(spacing: 8) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("5.42")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)
                        Text("km")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(.bottom, 8)
                    }
                    Text("距离")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Route Map
struct WorkoutRouteMapView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))

            // 使用真实的地图组件
            WorkoutDetailMapView()
                .cornerRadius(16)

            // 播放按钮
            Button(action: {}) {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 40, height: 40)
                    .shadow(color: Color(.systemGray4).opacity(0.3), radius: 4, x: 0, y: 2)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    )
            }
            .padding(16)
        }
    }
}

// MARK: - Heart Rate, Cadence and Calories
struct HeartRateAndCadenceView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))

            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("平均心率")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("145")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("bpm")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 2)
                    }
                }

                VStack(spacing: 4) {
                    Text("步频")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("160")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("spm")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 2)
                    }
                }

                VStack(spacing: 4) {
                    Text("卡路里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("420")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("kcal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 2)
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Heart Rate and Pace Charts (Combined Card)
struct HeartRateAndPaceChartsView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))

            VStack(alignment: .leading, spacing: 24) {
                // 心率图表
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("心率")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }

                    // 模拟心率波形图
                    GeometryReader { geometry in
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let centerY = height / 2

                            path.move(to: CGPoint(x: 0, y: centerY))

                            for i in 0..<50 {
                                let x = (width / 50) * CGFloat(i)
                                let variation = sin(Double(i) * 0.3) * 15 + sin(Double(i) * 0.1) * 8
                                let y = centerY + CGFloat(variation)
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                    .frame(height: 60)
                }

                // 配速图表
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("配速")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }

                    // 模拟配速柱状图
                    GeometryReader { geometry in
                        let barCount = 20
                        let spacing: CGFloat = 2
                        let totalSpacing = spacing * CGFloat(barCount - 1)
                        let availableWidth = geometry.size.width - totalSpacing
                        let barWidth = max(4, availableWidth / CGFloat(barCount)) // 最小宽度4，动态计算实际宽度

                        HStack(alignment: .bottom, spacing: spacing) {
                            ForEach(0..<barCount, id: \.self) { index in
                                let height = CGFloat.random(in: 20...60)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: barWidth, height: height)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 80)
                }
            }
            .padding(20)
        }
    }
}



// MARK: - Workout Detail Map View
import MapKit

struct WorkoutDetailMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.mapType = .standard
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.isUserInteractionEnabled = false

        // 设置默认区域（北京）
        let coordinate = CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: false)

        // 添加模拟路径
        addSampleRoute(to: mapView)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 更新地图视图
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func addSampleRoute(to mapView: MKMapView) {
        // 创建模拟跑步路径
        let coordinates = [
            CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            CLLocationCoordinate2D(latitude: 39.9052, longitude: 116.4084),
            CLLocationCoordinate2D(latitude: 39.9062, longitude: 116.4094),
            CLLocationCoordinate2D(latitude: 39.9072, longitude: 116.4104),
            CLLocationCoordinate2D(latitude: 39.9082, longitude: 116.4114)
        ]

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}


// MARK: - Preview
struct ActivityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityDetailView()
            .preferredColorScheme(.light)
    }
}

// MARK: - 新的运动详情页面（支持API数据）
struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    let workoutHistoryItem: WorkoutHistoryItem

    @State private var workoutDetail: WorkoutDetailForAPI?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                // 白色背景
                Color(.systemBackground)
                .ignoresSafeArea()

                if isLoading {
                    VStack {
                        ProgressView()
                        Text("加载运动详情...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("加载失败")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("重试") {
                            Task {
                                await loadWorkoutDetail()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    // 新的全屏地图 + 底部面板布局
                    ZStack(alignment: .bottom) {
                        // 全屏地图背景 - 向上偏移为底部面板留出空间
                        VStack(spacing: 0) {
                            WorkoutDetailRouteMapView(workoutDetail: workoutDetail)
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
                                ModernWorkoutHeaderView(workoutDetail: workoutDetail, currentUser: authManager.currentUser)
                                    .padding(.horizontal, 20)

                                // 运动指标网格
                                WorkoutMetricsGridView(workoutDetail: workoutDetail)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .ignoresSafeArea(.all, edges: .bottom)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                    }
                    .ignoresSafeArea(.all, edges: .bottom)
                }
            }
            .navigationTitle(getNavigationTitle())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("返回")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadWorkoutDetail()
            }
        }
        .asSubView()
    }

    private var hasRouteData: Bool {
        // 检查是否有GPS轨迹数据
        guard let routeData = workoutDetail?.routeData else { return false }
        return !routeData.coordinates.isEmpty
    }

    private func loadWorkoutDetail() async {
        isLoading = true
        errorMessage = nil

        do {
            // 如果有真实的workoutId，调用API获取详细数据
            if let workoutId = workoutHistoryItem.workoutId {
                print("📡 正在获取运动详情，workoutId: \(workoutId)")
                let detail = try await NewWorkoutAPIService.shared.getWorkoutDetail(workoutId: String(workoutId))

                await MainActor.run {
                    self.workoutDetail = detail
                    self.isLoading = false
                }

                print("✅ 成功获取运动详情")
                return
            }

            // 如果没有workoutId，使用现有数据构建详情（兼容模拟数据）
            print("⚠️ 没有workoutId，使用模拟数据构建运动详情")
            let detail = WorkoutDetailForAPI(
                workoutId: UUID().uuidString,
                workoutType: convertDisplayNameToAPIType(workoutHistoryItem.type),
                startTime: getCurrentDateTimeString(),
                endTime: getEndDateTimeString(),
                duration: workoutHistoryItem.duration * 60, // 转换为秒
                basicMetrics: BasicMetricsForAPI(
                    totalDistance: getEstimatedDistance(),
                    totalSteps: getEstimatedSteps(),
                    calories: workoutHistoryItem.calories,
                    averagePace: getEstimatedPace(),
                    maxSpeed: getEstimatedMaxSpeed()
                ),
                advancedMetrics: AdvancedMetricsForAPI(
                    averageHeartRate: getEstimatedHeartRate(),
                    maxHeartRate: getEstimatedMaxHeartRate(),
                    averageCadence: getEstimatedCadence(),
                    elevationGain: nil,
                    elevationLoss: nil
                ),
                routeData: nil
            )

            await MainActor.run {
                self.workoutDetail = detail
                self.isLoading = false
            }

        } catch {
            print("❌ 加载运动详情失败: \(error)")
            await MainActor.run {
                self.errorMessage = "加载运动详情失败: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // MARK: - 辅助方法
    private func convertDisplayNameToAPIType(_ displayName: String) -> String {
        switch displayName {
        case "跑步", "户外跑步": return "running"
        case "步行", "户外步行": return "walking"
        case "骑行", "户外骑行": return "cycling"
        case "游泳": return "swimming"
        case "瑜伽": return "yoga"
        case "力量训练": return "strength"
        case "徒步": return "hiking"
        default: return "other"
        }
    }

    private func getCurrentDateTimeString() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: Date())
    }

    private func getEndDateTimeString() -> String {
        let formatter = ISO8601DateFormatter()
        let endTime = Date().addingTimeInterval(TimeInterval(workoutHistoryItem.duration * 60))
        return formatter.string(from: endTime)
    }

    private func getNavigationTitle() -> String {
        guard let detail = workoutDetail else { return "运动" }

        switch detail.workoutType {
        case "running": return "跑步"
        case "walking": return "步行"
        case "cycling": return "骑行"
        case "swimming": return "游泳"
        case "yoga": return "瑜伽"
        case "strength": return "力量训练"
        case "hiking": return "徒步"
        default: return "运动"
        }
    }

    private func getEstimatedDistance() -> Double {
        // 根据运动类型和时长估算距离
        switch workoutHistoryItem.type {
        case "跑步", "户外跑步":
            return Double(workoutHistoryItem.duration) * 0.15 // 假设每分钟150米
        case "步行", "户外步行":
            return Double(workoutHistoryItem.duration) * 0.08 // 步行速度约每分钟80米
        case "骑行", "户外骑行":
            return Double(workoutHistoryItem.duration) * 0.4 // 假设每分钟400米
        default:
            return 0.0
        }
    }

    private func getEstimatedSteps() -> Int {
        // 根据运动类型和时长估算步数
        switch workoutHistoryItem.type {
        case "跑步", "户外跑步":
            return workoutHistoryItem.duration * 180 // 假设每分钟180步
        case "步行", "户外步行":
            return workoutHistoryItem.duration * 120 // 假设每分钟120步
        default:
            return 0
        }
    }

    private func getEstimatedPace() -> Double {
        // 根据运动类型估算配速（分钟/公里）
        switch workoutHistoryItem.type {
        case "跑步", "户外跑步":
            return 6.5 // 假设6分30秒每公里
        case "步行", "户外步行":
            return 12.0 // 假设12分钟每公里
        default:
            return 0.0
        }
    }

    private func getEstimatedMaxSpeed() -> Double {
        // 根据运动类型估算最大速度（公里/小时）
        switch workoutHistoryItem.type {
        case "跑步", "户外跑步":
            return 12.0
        case "步行", "户外步行":
            return 6.0
        case "骑行", "户外骑行":
            return 25.0
        default:
            return 0.0
        }
    }

    private func getEstimatedHeartRate() -> Int? {
        // 根据运动类型估算平均心率
        switch workoutHistoryItem.type {
        case "跑步", "户外跑步":
            return 145
        case "步行", "户外步行":
            return 110
        case "骑行", "户外骑行":
            return 135
        case "力量训练":
            return 125
        default:
            return nil
        }
    }

    private func getEstimatedMaxHeartRate() -> Int? {
        if let avgHR = getEstimatedHeartRate() {
            return avgHR + 20 // 最大心率通常比平均心率高20左右
        }
        return nil
    }

    private func getEstimatedCadence() -> Int? {
        // 根据运动类型估算步频
        switch workoutHistoryItem.type {
        case "跑步", "户外跑步":
            return 180
        case "步行", "户外步行":
            return 120
        default:
            return nil
        }
    }
}

// MARK: - 运动详情主要指标视图
struct WorkoutDetailMainMetricsView: View {
    let workoutDetail: WorkoutDetailForAPI?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

            VStack(spacing: 20) {
                // 时间
                VStack(spacing: 8) {
                    Text(getFormattedDate())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // 主要数据
                HStack(spacing: 0) {
                    // 时长
                    VStack(spacing: 8) {
                        Text(getFormattedDuration())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)

                        Text("时长")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    // 分隔线
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 60)

                    // 距离
                    VStack(spacing: 8) {
                        Text(getFormattedDistance())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)

                        Text("距离")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
    }

    private func getWorkoutIcon() -> String {
        guard let detail = workoutDetail else { return "figure.run" }

        switch detail.workoutType {
        case "running": return "figure.run"
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "swimming": return "figure.pool.swim"
        case "yoga": return "figure.yoga"
        case "strength": return "dumbbell"
        case "hiking": return "figure.hiking"
        default: return "figure.run"
        }
    }

    private func getWorkoutDisplayName() -> String {
        guard let detail = workoutDetail else { return "运动" }

        switch detail.workoutType {
        case "running": return "跑步"
        case "walking": return "步行"
        case "cycling": return "骑行"
        case "swimming": return "游泳"
        case "yoga": return "瑜伽"
        case "strength": return "力量训练"
        case "hiking": return "徒步"
        default: return "运动"
        }
    }

    private func getFormattedDate() -> String {
        guard let detail = workoutDetail else { return "" }

        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: detail.startTime) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年M月d日 HH:mm"
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }
        return detail.startTime
    }

    private func getFormattedDuration() -> String {
        guard let detail = workoutDetail else { return "0:00" }

        let totalSeconds = detail.duration
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func getFormattedDistance() -> String {
        guard let detail = workoutDetail else { return "0.00" }

        let distance = detail.basicMetrics.totalDistance
        if distance >= 1.0 {
            return String(format: "%.2f", distance)
        } else {
            return String(format: "%.0f", distance * 1000) // 显示米
        }
    }
}

// MARK: - 运动详情指标视图
struct WorkoutDetailMetricsView: View {
    let workoutDetail: WorkoutDetailForAPI?

    var body: some View {
        VStack(spacing: 16) {
            // 基础指标
            basicMetricsCard

            // 高级指标（如果有）
            if hasAdvancedMetrics {
                advancedMetricsCard
            }
        }
    }

    private var basicMetricsCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

            VStack(spacing: 16) {
                HStack {
                    Text("基础数据")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    metricItem(title: "卡路里", value: "\(workoutDetail?.basicMetrics.calories ?? 0)", unit: "千卡", icon: "flame.fill", color: .orange)
                    metricItem(title: "步数", value: "\(workoutDetail?.basicMetrics.totalSteps ?? 0)", unit: "步", icon: "figure.walk", color: .green)
                    metricItem(title: "平均配速", value: String(format: "%.1f", workoutDetail?.basicMetrics.averagePace ?? 0), unit: "分/公里", icon: "speedometer", color: .blue)
                    metricItem(title: "最大速度", value: String(format: "%.1f", workoutDetail?.basicMetrics.maxSpeed ?? 0), unit: "公里/小时", icon: "gauge.high", color: .purple)
                }
            }
            .padding(20)
        }
    }

    private var advancedMetricsCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

            VStack(spacing: 16) {
                HStack {
                    Text("高级数据")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    if let avgHR = workoutDetail?.advancedMetrics?.averageHeartRate {
                        metricItem(title: "平均心率", value: "\(avgHR)", unit: "bpm", icon: "heart.fill", color: .red)
                    }

                    if let maxHR = workoutDetail?.advancedMetrics?.maxHeartRate {
                        metricItem(title: "最大心率", value: "\(maxHR)", unit: "bpm", icon: "heart.circle.fill", color: .red)
                    }

                    if let cadence = workoutDetail?.advancedMetrics?.averageCadence {
                        metricItem(title: "步频", value: "\(cadence)", unit: "步/分", icon: "metronome", color: .cyan)
                    }

                    if let elevation = workoutDetail?.advancedMetrics?.elevationGain {
                        metricItem(title: "海拔上升", value: String(format: "%.0f", elevation), unit: "米", icon: "mountain.2.fill", color: .brown)
                    }
                }
            }
            .padding(20)
        }
    }

    private func metricItem(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()
            }

            HStack {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var hasAdvancedMetrics: Bool {
        guard let advanced = workoutDetail?.advancedMetrics else { return false }
        return advanced.averageHeartRate != nil ||
               advanced.maxHeartRate != nil ||
               advanced.averageCadence != nil ||
               advanced.elevationGain != nil
    }
}

// MARK: - 运动轨迹地图视图
struct WorkoutDetailRouteMapView: View {
    let workoutDetail: WorkoutDetailForAPI?
    @State private var shouldCenterOnLocation = false
    @State private var mapRegion: MKCoordinateRegion?

    // 检查是否有轨迹数据
    private var hasRouteData: Bool {
        guard let routeData = workoutDetail?.routeData else { return false }
        return !routeData.coordinates.isEmpty
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
                    routePoints: getRoutePoints(),
                    currentLocation: nil,  // 不传入currentLocation，避免自动居中覆盖我们的区域设置
                    showStartEndMarkers: true,
                    routeTimestamps: getRouteTimestamps()
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

    // 获取真实轨迹点数据
    private func getRoutePoints() -> [CLLocationCoordinate2D] {
        guard let routeData = workoutDetail?.routeData else {
            // 如果没有轨迹数据，返回示例数据
            return getSampleRoutePoints()
        }

        return routeData.coordinates.map { coordinate in
            CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        }
    }

    // 获取轨迹中心位置
    private func getCenterLocation() -> CLLocation? {
        let routePoints = getRoutePoints()
        guard !routePoints.isEmpty else { return getSampleLocation() }

        // 计算轨迹中心点
        let centerIndex = routePoints.count / 2
        let centerCoordinate = routePoints[centerIndex]
        return CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
    }

    // 计算最优地图区域
    private func calculateOptimalMapRegion() -> MKCoordinateRegion {
        let routePoints = getRoutePoints()

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

    // 获取真实轨迹点的时间戳数组（若有）
    private func getRouteTimestamps() -> [Date]? {
        guard let routeData = workoutDetail?.routeData else { return nil }
        let formatter = ISO8601DateFormatter()
        var dates: [Date] = []
        dates.reserveCapacity(routeData.coordinates.count)
        for c in routeData.coordinates {
            if let d = formatter.date(from: c.timestamp) {
                dates.append(d)
            } else {
                return nil
            }
        }
        return dates
    }

    // 获取示例路线点（备用数据）
    private func getSampleRoutePoints() -> [CLLocationCoordinate2D] {
        return [
            CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            CLLocationCoordinate2D(latitude: 39.9052, longitude: 116.4084),
            CLLocationCoordinate2D(latitude: 39.9062, longitude: 116.4094),
            CLLocationCoordinate2D(latitude: 39.9072, longitude: 116.4104),
            CLLocationCoordinate2D(latitude: 39.9082, longitude: 116.4114),
            CLLocationCoordinate2D(latitude: 39.9092, longitude: 116.4124),
            CLLocationCoordinate2D(latitude: 39.9102, longitude: 116.4134),
            CLLocationCoordinate2D(latitude: 39.9112, longitude: 116.4144)
        ]
    }

    // 获取示例位置（备用数据）
    private func getSampleLocation() -> CLLocation? {
        return CLLocation(latitude: 39.9077, longitude: 116.4109)
    }
}

// MARK: - 运动指标网格视图 - 3列2行布局
struct WorkoutMetricsGridView: View {
    let workoutDetail: WorkoutDetailForAPI?

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
                        Text(formatPace(workoutDetail?.basicMetrics.averagePace ?? 0))
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
                    value: "\(workoutDetail?.basicMetrics.totalSteps ?? 0)",
                    unit: "步"
                )

                // 消耗卡路里
                compactMetricItem(
                    title: "消耗",
                    value: "\(workoutDetail?.basicMetrics.calories ?? 0)",
                    unit: "千卡"
                )

                // 平均心率
                compactMetricItem(
                    title: "平均心率",
                    value: (workoutDetail?.advancedMetrics?.averageHeartRate != nil) ? "\(workoutDetail!.advancedMetrics!.averageHeartRate!)" : "--",
                    unit: "bpm"
                )

                // 最大心率
                compactMetricItem(
                    title: "最大心率",
                    value: (workoutDetail?.advancedMetrics?.maxHeartRate != nil) ? "\(workoutDetail!.advancedMetrics!.maxHeartRate!)" : "--",
                    unit: "bpm"
                )
            }
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 8)
    }

    private func metricGridItem(title: String, value: String, unit: String, showUnit: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            // 数值和单位
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)

                if showUnit && !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    private func formatPace(_ paceInSeconds: Double) -> String {
        if paceInSeconds <= 0 {
            return "--"
        }

        let minutes = Int(paceInSeconds) / 60
        let seconds = Int(paceInSeconds) % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    private func formatFastestPace() -> String {
        // 根据最大速度计算最快配速（由 API 数据 basicMetrics.maxSpeed 推导）
        guard let maxSpeed = workoutDetail?.basicMetrics.maxSpeed, maxSpeed > 0 else { return "--" }
        let secondsPerKm = 3600.0 / maxSpeed
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    private func compactMetricItem(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
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
}

// MARK: - 现代化运动详情组件

// 顶部头部信息组件 - 重新设计为突出距离显示
struct ModernWorkoutHeaderView: View {
    let workoutDetail: WorkoutDetailForAPI?
    let currentUser: AuthUser?

    var body: some View {
        VStack(spacing: 12) {
            // 运动类型和来源信息
            HStack(alignment: .firstTextBaseline) {
                // 左侧：运动类型 + 同行日期/时间段
                HStack(spacing: 8) {
                    Text("\(getWorkoutDisplayName()) | 户外")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Text(getFormattedTimeRange())
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer()
                // 右侧：用户头像
                AsyncImage(url: URL(string: currentUser?.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(String((currentUser?.nickname ?? "用户").prefix(1)))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
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
                    Text(getFormattedDuration())
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("运动时长")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 活动卡路里
                VStack(alignment: .center, spacing: 2) {
                    Text("\(getCalories())kcal")
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

    private func getWorkoutIcon() -> String {
        guard let detail = workoutDetail else { return "figure.run" }

        switch detail.workoutType {
        case "running": return "figure.run"
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "swimming": return "figure.pool.swim"
        case "yoga": return "figure.yoga"
        case "strength": return "dumbbell"
        case "hiking": return "figure.hiking"
        default: return "figure.run"
        }
    }

    private func getWorkoutColor() -> Color {
        guard let detail = workoutDetail else { return Color(hex: "007AFF") }

        switch detail.workoutType {
        case "running": return Color(hex: "FF6B35")
        case "walking": return Color(hex: "34C759")
        case "cycling": return Color(hex: "007AFF")
        case "swimming": return Color(hex: "00C7BE")
        case "yoga": return Color(hex: "AF52DE")
        case "strength": return Color(hex: "FF9500")
        case "hiking": return Color(hex: "8E8E93")
        default: return Color(hex: "007AFF")
        }
    }

    private func getWorkoutDisplayName() -> String {
        guard let detail = workoutDetail else { return "运动" }

        switch detail.workoutType {
        case "running": return "跑步"
        case "walking": return "步行"
        case "cycling": return "骑行"
        case "swimming": return "游泳"
        case "yoga": return "瑜伽"
        case "strength": return "力量训练"
        case "hiking": return "徒步"
        default: return "运动"
        }
    }

    private func getWorkoutRouteTitle() -> String {
        return "路线"
    }

    private func getFormattedDistanceValue() -> String {
        guard let detail = workoutDetail else { return "0" }
        let distanceInMeters = detail.basicMetrics.totalDistance * 1000
        return String(format: "%.0f", distanceInMeters)
    }



    private func getFormattedDate() -> String {
        guard let detail = workoutDetail else { return "2025/9/9 09:52" }

        let formatter = ISO8601DateFormatter()
        guard let startDate = formatter.date(from: detail.startTime) else {
            return "2025/9/9 09:52"
        }

        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "zh_CN")
        displayFormatter.dateFormat = "yyyy/M/d HH:mm"

        return displayFormatter.string(from: startDate)
    }

    private func getFormattedDuration() -> String {
        guard let detail = workoutDetail else { return "00:00:00" }

        let duration = detail.duration
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func getCalories() -> String {
        guard let detail = workoutDetail else { return "0" }
        return "\(detail.basicMetrics.calories)"
    }

    private func getFormattedPace() -> String {
        guard let detail = workoutDetail else { return "0'00\"" }

        let totalDistance = detail.basicMetrics.totalDistance
        let duration = detail.duration

        guard totalDistance > 0 else { return "0'00\"" }

        let paceInSecondsPerKm = Double(duration) / totalDistance
        let minutes = Int(paceInSecondsPerKm) / 60
        let seconds = Int(paceInSecondsPerKm) % 60

        return String(format: "%d'%02d\"", minutes, seconds)
    }

    private func getFormattedTimeRange() -> String {
        guard let detail = workoutDetail else { return "" }
        // 使用公共 Helper，统一解析与展示规则（同日合并 + yyyy-MM-dd 格式）
        return DateParsingHelper.formatTimeRange(
            startTime: detail.startTime,
            endTime: detail.endTime,
            sameDayMerge: true,
            dateFormat: "yyyy-MM-dd",
            timeFormat: "HH:mm"
        )
    }
}

// 运动时长指标组件
struct ModernDurationMetricsView: View {
    let workoutDetail: WorkoutDetailForAPI?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("运动时长")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }

            // 3列网格布局
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                // 运动时长
                durationMetricCard(
                    title: "运动时长",
                    value: getFormattedDuration(),
                    unit: "",
                    icon: "clock.fill",
                    color: Color(hex: "007AFF")
                )

                // 总步数
                durationMetricCard(
                    title: "总步数",
                    value: "\(workoutDetail?.basicMetrics.totalSteps ?? 0)",
                    unit: "步",
                    icon: "figure.walk",
                    color: Color(hex: "34C759")
                )

                // 消耗卡路里
                durationMetricCard(
                    title: "消耗",
                    value: "\(workoutDetail?.basicMetrics.calories ?? 0)",
                    unit: "千卡",
                    icon: "flame.fill",
                    color: Color(hex: "FF9500")
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    private func durationMetricCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            // 数值
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // 单位
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 标题
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "f8f9fa"))
        )
    }

    private func getFormattedDuration() -> String {
        guard let detail = workoutDetail else { return "00:00:00" }

        let hours = detail.duration / 3600
        let minutes = (detail.duration % 3600) / 60
        let seconds = detail.duration % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// 核心指标组件 - 显示其他重要数据
struct ModernCoreMetricsView: View {
    let workoutDetail: WorkoutDetailForAPI?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("其他数据")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }

            // 2列网格布局
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                // 平均速度（根据配速计算）
                coreMetricCard(
                    title: "平均速度",
                    value: String(format: "%.1f", calculateAverageSpeed()),
                    unit: "公里/小时",
                    icon: "speedometer",
                    color: Color(hex: "007AFF")
                )

                // 海拔变化（如果有数据）
                if let elevation = workoutDetail?.advancedMetrics?.elevationGain {
                    coreMetricCard(
                        title: "海拔上升",
                        value: String(format: "%.0f", elevation),
                        unit: "米",
                        icon: "mountain.2.fill",
                        color: Color(hex: "8E8E93")
                    )
                } else {
                    // 如果没有海拔数据，显示运动强度
                    coreMetricCard(
                        title: "运动强度",
                        value: getWorkoutIntensity(),
                        unit: "",
                        icon: "bolt.fill",
                        color: Color(hex: "FF9500")
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    private func coreMetricCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部图标和标题
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()
            }

            // 数值和单位
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "f8f9fa"))
        )
    }

    private func getWorkoutIntensity() -> String {
        guard let detail = workoutDetail else { return "中等" }

        // 根据平均配速计算运动强度
        let avgPace = detail.basicMetrics.averagePace
        if avgPace < 300 { // 小于5分钟/公里
            return "高强度"
        } else if avgPace < 420 { // 小于7分钟/公里
            return "中高强度"
        } else if avgPace < 600 { // 小于10分钟/公里
            return "中等强度"
        } else {
            return "低强度"
        }
    }

    private func calculateAverageSpeed() -> Double {
        guard let detail = workoutDetail else { return 0.0 }

        // 根据配速计算平均速度
        // 配速单位：秒/公里，速度单位：公里/小时
        let avgPace = detail.basicMetrics.averagePace
        if avgPace > 0 {
            return 3600.0 / avgPace // 3600秒/小时 ÷ 秒/公里 = 公里/小时
        }
        return 0.0
    }
}

// 性能指标组件 - 重新设计为更清晰的布局
struct ModernPerformanceMetricsView: View {
    let workoutDetail: WorkoutDetailForAPI?

    var body: some View {
        VStack(spacing: 20) {
            // 配速和速度指标
            VStack(spacing: 16) {
                HStack {
                    Text("配速 & 速度")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                }

                HStack(spacing: 12) {
                    // 平均配速
                    performanceMetricCard(
                        title: "平均配速",
                        value: formatPace(workoutDetail?.basicMetrics.averagePace ?? 0),
                        unit: "",
                        icon: "speedometer",
                        color: Color(hex: "007AFF")
                    )

                    // 最大速度
                    performanceMetricCard(
                        title: "最大速度",
                        value: String(format: "%.1f", workoutDetail?.basicMetrics.maxSpeed ?? 0),
                        unit: "公里/小时",
                        icon: "gauge.high",
                        color: Color(hex: "AF52DE")
                    )
                }
            }

            // 心率和步频指标（如果有数据）
            if hasAdvancedMetrics {
                VStack(spacing: 16) {
                    HStack {
                        Text("心率 & 步频")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        // 平均心率
                        if let avgHR = workoutDetail?.advancedMetrics?.averageHeartRate {
                            compactMetricCard(
                                title: "平均心率",
                                value: "\(avgHR)",
                                unit: "bpm",
                                icon: "heart.fill",
                                color: Color(hex: "FF3B30")
                            )
                        }

                        // 最大心率
                        if let maxHR = workoutDetail?.advancedMetrics?.maxHeartRate {
                            compactMetricCard(
                                title: "最大心率",
                                value: "\(maxHR)",
                                unit: "bpm",
                                icon: "heart.circle.fill",
                                color: Color(hex: "FF3B30")
                            )
                        }

                        // 平均步频
                        if let cadence = workoutDetail?.advancedMetrics?.averageCadence {
                            compactMetricCard(
                                title: "平均步频",
                                value: "\(cadence)",
                                unit: "步/分",
                                icon: "metronome",
                                color: Color(hex: "00C7BE")
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    private var hasAdvancedMetrics: Bool {
        return workoutDetail?.advancedMetrics?.averageHeartRate != nil ||
               workoutDetail?.advancedMetrics?.maxHeartRate != nil ||
               workoutDetail?.advancedMetrics?.averageCadence != nil
    }

    private func performanceMetricCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部图标和标题
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()
            }

            // 数值和单位
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "f8f9fa"))
        )
    }

    private func compactMetricCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }

            // 数值
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // 单位
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)

            // 标题
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "f8f9fa"))
        )
    }

    private func formatPace(_ pace: Double) -> String {
        if pace <= 0 { return "0:00" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// 时间信息组件
struct ModernTimeInfoView: View {
    let workoutDetail: WorkoutDetailForAPI?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("时间信息")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }

            VStack(spacing: 12) {
                // 运动时长
                timeInfoRow(
                    title: "运动时长",
                    value: formatDuration(workoutDetail?.duration ?? 0),
                    icon: "clock.fill",
                    color: Color(hex: "007AFF")
                )

                // 开始时间
                timeInfoRow(
                    title: "开始时间",
                    value: formatTime(workoutDetail?.startTime ?? ""),
                    icon: "clock.badge.checkmark",
                    color: Color(hex: "34C759")
                )

                // 结束时间
                timeInfoRow(
                    title: "结束时间",
                    value: formatTime(workoutDetail?.endTime ?? ""),
                    icon: "clock.badge.xmark",
                    color: Color(hex: "FF9500")
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    private func timeInfoRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            // 标题
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Spacer()

            // 数值
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }

    private func formatDuration(_ duration: Int) -> String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func formatTime(_ timeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: timeString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "HH:mm"
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }
        return "--:--"
    }
}

// MARK: - 预览
#Preview {
    WorkoutDetailView(workoutHistoryItem: WorkoutHistoryItem(
        id: UUID(),
        workoutId: 123,
        type: "跑步",
        duration: 45,
        date: "今天 14:30",
        calories: 450,
        source: "青禾计划"
    ))
}


