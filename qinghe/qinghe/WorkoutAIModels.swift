import SwiftUI
import CoreLocation
import CoreMotion
import Foundation

// MARK: - AI 运动教练模型

struct WorkoutAnalysisResult: Codable {
    let guidance: WorkoutGuidance
    let analysisItems: [AnalysisItem]
    let timestamp: Date
}

struct WorkoutGuidance: Codable {
    let message: String
    let priorityText: String
    let priorityColor: String
    let priorityIcon: String

    init(message: String, priorityText: String = "一般", priorityColor: String = "#4CAF50", priorityIcon: String = "lightbulb.fill") {
        self.message = message
        self.priorityText = priorityText
        self.priorityColor = priorityColor
        self.priorityIcon = priorityIcon
    }
}

struct AnalysisItem: Codable {
    let message: String
    let statusText: String
    let statusColor: String

    init(message: String, statusText: String = "正常", statusColor: String = "#4CAF50") {
        self.message = message
        self.statusText = statusText
        self.statusColor = statusColor
    }
}

enum AIServiceStatus {
    case connected
    case analyzing
    case disconnected
    case error

    var color: Color {
        switch self {
        case .connected: return .green
        case .analyzing: return .orange
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    var displayText: String {
        switch self {
        case .connected: return "已连接"
        case .analyzing: return "分析中"
        case .disconnected: return "未连接"
        case .error: return "错误"
        }
    }
}

// MARK: - AI教练服务 (已移至 WorkoutAICoachService.swift)

// MARK: - AI运动教练数据模型

struct WorkoutAIAnalysisRequest: Codable {
    let workoutData: WorkoutDataForAI
    let userId: String?
    let options: AnalysisOptions?

    struct WorkoutDataForAI: Codable {
        let workoutType: String
        let heartRate: Int?
        let cadence: Int?
        let pace: Double?
        let distance: Double?
        let duration: Int?
        let timestamp: String?
    }

    struct AnalysisOptions: Codable {
        let generateAudio: Bool
    }
}

struct WorkoutAIAnalysisResponse: Codable {
    let success: Bool
    let data: AnalysisData?
    let error: String?
    let message: String?

    struct AnalysisData: Codable {
        let guidance: Guidance
        let audio: AudioInfo?
        let isWorkoutStart: Bool
        let timestamp: String

        // 从 guidance.analysis 中提取 analysis 数据
        var analysis: Analysis {
            return guidance.analysis ?? Analysis(
                heartRate: nil,
                cadence: nil,
                pace: nil,
                distance: nil,
                duration: nil,
                overall: "unknown"
            )
        }

        struct Analysis: Codable {
            let heartRate: MetricAnalysis?
            let cadence: MetricAnalysis?
            let pace: MetricAnalysis?
            let distance: MetricAnalysis?
            let duration: MetricAnalysis?
            let overall: String

            struct MetricAnalysis: Codable {
                let status: String // normal/warning/danger/unknown
                let value: Double?
                let message: String
            }
        }

        struct Guidance: Codable {
            let type: String
            let priority: String // low/medium/high
            let message: String
            let analysis: Analysis?
            let isWelcome: Bool?

            enum CodingKeys: String, CodingKey {
                case type, priority, message, analysis, isWelcome
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                type = try container.decode(String.self, forKey: .type)
                priority = try container.decode(String.self, forKey: .priority)
                message = try container.decode(String.self, forKey: .message)
                isWelcome = try container.decodeIfPresent(Bool.self, forKey: .isWelcome)
                analysis = try container.decodeIfPresent(Analysis.self, forKey: .analysis)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(type, forKey: .type)
                try container.encode(priority, forKey: .priority)
                try container.encode(message, forKey: .message)
                try container.encodeIfPresent(isWelcome, forKey: .isWelcome)
                try container.encodeIfPresent(analysis, forKey: .analysis)
            }
        }

        struct AudioInfo: Codable {
            let success: Bool
            let audioUrl: String?
            let audioId: String?
            let processingTime: Double?
        }
    }
}

struct WorkoutStartRequest: Codable {
    let workoutType: String
    let userId: String?
}

struct AudioLifecycleRequest: Codable {
    let audioId: String
    let audioUrl: String?
    let error: String?
}

// MARK: - 运动数据管理器 (重构版 - 移除模拟数据)
@MainActor
class WorkoutDataManager: ObservableObject {
    static let shared = WorkoutDataManager()

    // 真实运动数据 - 从传感器和GPS获取
    @Published var realTimeDistance: Double = 0.0
    @Published var realTimeCalories: Double = 0.0
    @Published var realTimeSteps: Int = 0
    @Published var realTimeCadence: Double = 0.0
    @Published var realTimeHeartRate: Int = 0
    @Published var realTimePace: Double = 0.0
    @Published var realTimeElevation: Double = 0.0

    // 今日统计数据 - 从HealthKit获取
    @Published var todayTotalSteps: Int = 0
    @Published var todayTotalDistance: Double = 0.0
    @Published var todayTotalCalories: Double = 0.0

    // 运动会话数据
    @Published var averageHeartRate: Int = 0
    @Published var maxHeartRate: Int = 0
    @Published var primaryDataSource: String = "传感器"
    @Published var userAge: Int = 30
    @Published var dataQuality: String = "良好"

    // 运动状态
    @Published var isWorkoutActive = false

    // 私有属性
    private var workoutTimer: Timer?
    private var workoutStartTime: Date?
    private var heartRateHistory: [Int] = []

    // 计步与步频（CoreMotion）
    private let pedometer = CMPedometer()

    private init() {
        loadTodayDataFromHealthSources()
    }

    func startWorkout(type: WorkoutType) {
        isWorkoutActive = true
        workoutStartTime = Date()
        heartRateHistory.removeAll()
        averageHeartRate = 0
        maxHeartRate = 0

        // 重置实时数据
        realTimeDistance = 0.0
        realTimeCalories = 0.0
        realTimeSteps = 0

        // 启动计步与步频
        startPedometerUpdates()

        // HealthKit：请求授权并订阅心率
        Task {
            let ok = await HealthKitManager.shared.requestAuthorization()
            if ok {
                print("✅ HealthKit授权成功，开始监听心率数据")
                HealthKitManager.shared.startHeartRateStreaming { [weak self] bpm in
                    Task { @MainActor in
                        print("💓 收到心率数据: \(bpm) BPM")
                        self?.realTimeHeartRate = Int(bpm.rounded())
                        self?.updateHeartRateStatistics(Int(bpm.rounded()))
                    }
                }
            } else {
                print("❌ HealthKit授权失败，无法获取心率数据")
            }
        }

        print("✅ 运动数据管理器已启动 - 类型: \(type.displayName)")
    }

    func stopWorkout() {
        isWorkoutActive = false
        workoutTimer?.invalidate()
        workoutTimer = nil
        stopPedometerUpdates()
        HealthKitManager.shared.stopHeartRateStreaming()
        print("⏹️ 运动数据管理器已停止")
    }

    func endWorkout() {
        stopWorkout()
        workoutStartTime = nil
        print("🏁 运动会话已结束")
    }

    // 更新真实运动数据 - 从外部传感器数据源调用
    func updateRealTimeData(
        distance: Double? = nil,
        calories: Double? = nil,
        steps: Int? = nil,
        cadence: Double? = nil,
        heartRate: Int? = nil,
        pace: Double? = nil,
        elevation: Double? = nil
    ) {
        if let distance = distance {
            realTimeDistance = distance
        }
        if let calories = calories {
            realTimeCalories = calories
        }
        if let steps = steps {
            realTimeSteps = steps
        }
        if let cadence = cadence {
            realTimeCadence = cadence
        }
        if let heartRate = heartRate {
            realTimeHeartRate = heartRate
            updateHeartRateStatistics(heartRate)
        }
        if let pace = pace {
            realTimePace = pace
        }
        if let elevation = elevation {
            realTimeElevation = elevation
        }
    }

    private func updateHeartRateStatistics(_ heartRate: Int) {
        heartRateHistory.append(heartRate)

        // 计算平均心率
        if !heartRateHistory.isEmpty {
            averageHeartRate = heartRateHistory.reduce(0, +) / heartRateHistory.count
        }

        // 更新最大心率
        if heartRate > maxHeartRate {
            maxHeartRate = heartRate
        }
    }

    private func loadTodayDataFromHealthSources() {
        // 优先使用 CoreMotion 统计今日步数与距离
        if CMPedometer.isStepCountingAvailable() {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            pedometer.queryPedometerData(from: startOfDay, to: Date()) { [weak self] data, error in
                Task { @MainActor in
                    guard let self = self else { return }
                    if let d = data, error == nil {
                        self.todayTotalSteps = d.numberOfSteps.intValue
                        if let dist = d.distance?.doubleValue {
                            self.todayTotalDistance = dist / 1000.0 // m -> km
                        }
                    }
                }
            }
        }
        // 使用 HealthKit 查询今日能量/距离（作为汇总，优先展示 HealthKit 数据）
        HealthKitManager.shared.queryTodayTotals { [weak self] energyKcal, distanceKm in
            guard let self = self else { return }
            self.todayTotalCalories = energyKcal
            // 若 HealthKit 有更准确的步行跑步距离，覆盖 pedometer 的统计
            if distanceKm > 0 { self.todayTotalDistance = distanceKm }
            print("📊 今日数据(含HealthKit) - 步数: \(self.todayTotalSteps), 距离: \(self.todayTotalDistance)km, 卡路里: \(self.todayTotalCalories)")
        }
    }

    // MARK: - CoreMotion 实时更新
    private func startPedometerUpdates() {
        guard CMPedometer.isPaceAvailable() || CMPedometer.isCadenceAvailable() || CMPedometer.isStepCountingAvailable() else {
            print("⚠️ 设备不支持步数/步频/配速实时检测")
            return
        }
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            Task { @MainActor in
                guard let self = self, let d = data, error == nil else { return }
                // 实时步数
                if CMPedometer.isStepCountingAvailable() {
                    self.realTimeSteps = d.numberOfSteps.intValue
                }
                // 实时步频（步/秒 -> 步/分）
                if CMPedometer.isCadenceAvailable(), let cadence = d.currentCadence?.doubleValue {
                    self.realTimeCadence = cadence * 60.0
                }
                // 实时配速（min/km）估算：currentPace 是 秒/米(s/m)
                if CMPedometer.isPaceAvailable(), let secondsPerMeter = d.currentPace?.doubleValue, secondsPerMeter > 0 {
                    // s/m -> s/km -> min/km
                    let secondsPerKm = secondsPerMeter * 1000.0
                    self.realTimePace = secondsPerKm / 60.0
                }
            }
        }
    }

    private func stopPedometerUpdates() {
        pedometer.stopUpdates()
    }

}

// MARK: - API统计数据管理器
@MainActor
class APIBasedWorkoutStatsManager: ObservableObject {
    static let shared = APIBasedWorkoutStatsManager()

    @Published var isLoading = false
    @Published var lastRefreshTime: Date?

    private var cache: [String: Any] = [:]
    private let cacheExpiry: TimeInterval = 300 // 5分钟缓存

    private init() {}

    func refreshStats() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        // 模拟API调用
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        lastRefreshTime = Date()

        // 更新缓存
        cache["lastUpdate"] = Date()

        print("📊 统计数据已刷新")
    }
}