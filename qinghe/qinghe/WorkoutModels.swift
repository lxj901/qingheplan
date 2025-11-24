import SwiftUI
import Foundation
import CoreLocation

// MARK: - 运动类型枚举
enum WorkoutType: String, CaseIterable, Codable {
    case running = "running"
    case walking = "walking"
    case cycling = "cycling"
    case swimming = "swimming"
    case hiking = "hiking"
    case yoga = "yoga"
    case fitness = "fitness"
    case basketball = "basketball"
    case football = "football"
    case tennis = "tennis"
    case badminton = "badminton"
    case pingpong = "pingpong"
    case climbing = "climbing"
    case dancing = "dancing"
    case boxing = "boxing"
    case martialArts = "martial_arts"
    case pilates = "pilates"
    case aerobics = "aerobics"
    case strength = "strength"
    case other = "other"
    
    var chineseName: String {
        switch self {
        case .running: return "跑步"
        case .walking: return "步行"
        case .cycling: return "骑行"
        case .swimming: return "游泳"
        case .hiking: return "徒步"
        case .yoga: return "瑜伽"
        case .fitness: return "健身"
        case .basketball: return "篮球"
        case .football: return "足球"
        case .tennis: return "网球"
        case .badminton: return "羽毛球"
        case .pingpong: return "乒乓球"
        case .climbing: return "攀岩"
        case .dancing: return "舞蹈"
        case .boxing: return "拳击"
        case .martialArts: return "武术"
        case .pilates: return "普拉提"
        case .aerobics: return "有氧运动"
        case .strength: return "力量训练"
        case .other: return "其他运动"
        }
    }

    var displayName: String {
        return chineseName
    }
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .hiking: return "figure.hiking"
        case .yoga: return "figure.yoga"
        case .fitness: return "dumbbell"
        case .basketball: return "basketball"
        case .football: return "soccerball"
        case .tennis: return "tennisball"
        case .badminton: return "figure.badminton"
        case .pingpong: return "figure.table.tennis"
        case .climbing: return "figure.climbing"
        case .dancing: return "figure.dance"
        case .boxing: return "figure.boxing"
        case .martialArts: return "figure.martial.arts"
        case .pilates: return "figure.pilates"
        case .aerobics: return "figure.aerobics"
        case .strength: return "dumbbell"
        case .other: return "figure.mixed.cardio"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .running: return .orange
        case .walking: return .green
        case .cycling: return .blue
        case .swimming: return .cyan
        case .hiking: return .brown
        case .yoga: return .purple
        case .fitness: return .red
        case .basketball: return .orange
        case .football: return .green
        case .tennis: return .yellow
        case .badminton: return .pink
        case .pingpong: return .red
        case .climbing: return .gray
        case .dancing: return .pink
        case .boxing: return .red
        case .martialArts: return .black
        case .pilates: return .purple
        case .aerobics: return .mint
        case .strength: return .red
        case .other: return .gray
        }
    }
}

// MARK: - 运动记录项
struct WorkoutRecordItem: Identifiable, Codable {
    let id = UUID()
    let workoutId: Int
    let workoutType: WorkoutType
    let date: Date
    let duration: Int // 秒
    let distance: Double? // 公里
    let calories: Int
    let notes: String?
    let apiWorkout: QingheWorkout? // 原始API数据
    
    var formattedDuration: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        return String(format: "%.2f km", distance)
    }
}

// MARK: - API 运动数据模型
struct QingheWorkout: Codable {
    let workoutId: Int
    let workoutType: String
    let startTime: String
    let endTime: String
    let duration: Int
    let basicMetrics: WorkoutBasicMetrics
    let advancedMetrics: WorkoutAdvancedMetrics?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case workoutId = "workout_id"
        case workoutType = "workout_type"
        case startTime = "start_time"
        case endTime = "end_time"
        case duration
        case basicMetrics = "basic_metrics"
        case advancedMetrics = "advanced_metrics"
        case notes
    }
}

struct WorkoutBasicMetrics: Codable {
    let totalDistance: Double
    let totalSteps: Int
    let calories: Int
    let averagePace: Double
    let maxSpeed: Double

    enum CodingKeys: String, CodingKey {
        case totalDistance = "totalDistance"
        case totalSteps = "totalSteps"
        case calories
        case averagePace = "averagePace"
        case maxSpeed = "maxSpeed"
    }

    // 转换为API上传格式（averagePace为字符串）
    func forAPIUpload() -> WorkoutBasicMetricsForUpload {
        return WorkoutBasicMetricsForUpload(
            totalDistance: totalDistance,
            totalSteps: totalSteps,
            calories: calories,
            averagePace: String(format: "%.2f", averagePace), // 转换为字符串格式
            maxSpeed: maxSpeed
        )
    }
}

// 用于API上传的基础指标结构体（averagePace为字符串）
struct WorkoutBasicMetricsForUpload: Codable {
    let totalDistance: Double
    let totalSteps: Int
    let calories: Int
    let averagePace: String  // 注意：这里是字符串类型
    let maxSpeed: Double

    enum CodingKeys: String, CodingKey {
        case totalDistance = "totalDistance"
        case totalSteps = "totalSteps"
        case calories
        case averagePace = "averagePace"
        case maxSpeed = "maxSpeed"
    }
}

struct WorkoutAdvancedMetrics: Codable {
    let averageHeartRate: Int?
    let maxHeartRate: Int?
    let averageCadence: Int?
    let elevationGain: Double?
    let elevationLoss: Double?

    enum CodingKeys: String, CodingKey {
        case averageHeartRate = "averageHeartRate"
        case maxHeartRate = "maxHeartRate"
        case averageCadence = "averageCadence"
        case elevationGain = "elevationGain"
        case elevationLoss = "elevationLoss"
    }
}

struct WorkoutDeviceInfo: Codable {
    let deviceType: String
    let deviceModel: String?
    let appVersion: String
    let dataSource: String?

    enum CodingKeys: String, CodingKey {
        case deviceType = "deviceType"
        case deviceModel = "deviceModel"
        case appVersion = "appVersion"
        case dataSource = "dataSource"
    }
}

// MARK: - 兼容的 Workout 模型
struct Workout: Codable {
    let workoutId: Int
    let workoutType: String
    let startTime: String
    let endTime: String
    let duration: Int
    let basicMetrics: WorkoutBasicMetrics
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case workoutId = "workout_id"
        case workoutType = "workout_type"
        case startTime = "start_time"
        case endTime = "end_time"
        case duration
        case basicMetrics = "basic_metrics"
        case notes
    }
}

// MARK: - 打卡相关模型
struct SimpleCheckin: Codable {
    let id: Int
    let date: String
    let time: String
    let note: String?
    let consecutiveDays: Int
    let locationAddress: String?

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case time
        case note
        case consecutiveDays = "consecutive_days"
        case locationAddress = "location_address"
    }
}

struct NewCheckinStatsData: Codable {
    let totalDays: Int
    let consecutiveDays: Int
    let currentStreak: Int
    
    enum CodingKeys: String, CodingKey {
        case totalDays = "total_days"
        case consecutiveDays = "consecutive_days"
        case currentStreak = "current_streak"
    }
}

// MARK: - 运动模式枚举  
enum WorkoutMode: String, CaseIterable, Codable {
    case free = "free"
    case target = "target"
    case interval = "interval"
    case course = "course"
    
    var displayName: String {
        switch self {
        case .free: return "自由运动"
        case .target: return "目标运动"
        case .interval: return "间歇训练"
        case .course: return "课程运动"
        }
    }
    
    var icon: String {
        switch self {
        case .free: return "figure.run"
        case .target: return "target"
        case .interval: return "timer"
        case .course: return "book"
        }
    }
}

// MARK: - 运动目标类型
enum WorkoutTargetType: String, CaseIterable, Codable {
    case distance = "distance"
    case duration = "duration"
    case calories = "calories"
    case pace = "pace"

    var displayName: String {
        switch self {
        case .distance: return "距离"
        case .duration: return "时长"
        case .calories: return "卡路里"
        case .pace: return "配速"
        }
    }

    var unit: String {
        switch self {
        case .distance: return "km"
        case .duration: return "分钟"
        case .calories: return "卡路里"
        case .pace: return "分/公里"
        }
    }
    
    var icon: String {
        switch self {
        case .distance: return "map"
        case .duration: return "clock.fill"
        case .calories: return "flame.fill"
        case .pace: return "speedometer"
        }
    }
}

// MARK: - 运动目标模型
struct WorkoutTarget: Codable {
    let type: WorkoutTargetType
    let value: Double

    var displayText: String {
        switch type {
        case .distance:
            return String(format: "%.1f %@", value, type.unit)
        case .duration:
            return String(format: "%.0f %@", value, type.unit)
        case .calories:
            return String(format: "%.0f %@", value, type.unit)
        case .pace:
            let minutes = Int(value)
            let seconds = Int((value - Double(minutes)) * 60)
            return String(format: "%d:%02d %@", minutes, seconds, type.unit)
        }
    }
    
    var displayValue: String {
        switch type {
        case .distance:
            return String(format: "%.1f", value)
        case .duration:
            return String(format: "%.0f", value)
        case .calories:
            return String(format: "%.0f", value)
        case .pace:
            let minutes = Int(value)
            let seconds = Int((value - Double(minutes)) * 60)
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - 新运动数据模型
struct NewWorkout: Codable {
    let workoutId: Int?
    let workoutType: String
    let startTime: String
    let endTime: String
    let duration: Int
    let basicMetrics: WorkoutBasicMetrics
    let advancedMetrics: WorkoutAdvancedMetrics? // 添加高级指标字段
    let routeData: RouteDataForAPI? // 轨迹数据（可选）
    let deviceInfo: WorkoutDeviceInfo
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case workoutId = "workoutId"
        case workoutType = "workoutType"
        case startTime = "startTime"
        case endTime = "endTime"
        case duration
        case basicMetrics = "basicMetrics"
        case advancedMetrics = "advancedMetrics" // 添加编码键
        case routeData = "routeData"
        case deviceInfo = "deviceInfo"
        case notes
    }

    // 创建用于API上传的版本（不包含workoutId）
    func forAPIUpload() -> NewWorkoutForUpload {
        return NewWorkoutForUpload(
            workoutType: workoutType,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            basicMetrics: basicMetrics.forAPIUpload(), // 转换基础指标格式
            advancedMetrics: advancedMetrics, // 包含高级指标
            routeData: routeData,
            deviceInfo: deviceInfo,
            notes: notes
        )
    }

    func toQingheWorkout() -> QingheWorkout {
        return QingheWorkout(
            workoutId: workoutId ?? 0,
            workoutType: workoutType,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            basicMetrics: basicMetrics,
            advancedMetrics: nil, // 添加缺少的参数
            notes: notes
        )
    }
}

// MARK: - 用于API上传的运动数据模型（不包含workoutId）
struct NewWorkoutForUpload: Codable {
    let workoutType: String
    let startTime: String
    let endTime: String
    let duration: Int
    let basicMetrics: WorkoutBasicMetricsForUpload  // 使用专门的上传格式
    let advancedMetrics: WorkoutAdvancedMetrics? // 添加高级指标字段
    let routeData: RouteDataForAPI? // 轨迹数据（可选）
    let deviceInfo: WorkoutDeviceInfo
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case workoutType = "workoutType"
        case startTime = "startTime"
        case endTime = "endTime"
        case duration
        case basicMetrics = "basicMetrics"
        case advancedMetrics = "advancedMetrics" // 添加编码键
        case routeData = "routeData"
        case deviceInfo = "deviceInfo"
        case notes
    }
}

// MARK: - 新运动统计数据模型
struct NewWorkoutStatistics: Codable {
    let totalWorkouts: Int
    let totalDistance: Double
    let totalDuration: Int
    let totalCalories: Int
    let averageDistance: Double
    let averageDuration: Int
    let averageCalories: Int
    let workoutsByType: [String: Int]
    let monthlyStats: [MonthlyWorkoutStats]

    enum CodingKeys: String, CodingKey {
        case totalWorkouts = "total_workouts"
        case totalDistance = "total_distance"
        case totalDuration = "total_duration"
        case totalCalories = "total_calories"
        case averageDistance = "average_distance"
        case averageDuration = "average_duration"
        case averageCalories = "average_calories"
        case workoutsByType = "workouts_by_type"
        case monthlyStats = "monthly_stats"
    }
}

struct MonthlyWorkoutStats: Codable {
    let month: String
    let workoutCount: Int
    let totalDistance: Double
    let totalDuration: Int
    let totalCalories: Int

    enum CodingKeys: String, CodingKey {
        case month
        case workoutCount = "workout_count"
        case totalDistance = "total_distance"
        case totalDuration = "total_duration"
        case totalCalories = "total_calories"
    }
}

// MARK: - 今日运动数据模型
struct TodayWorkoutData: Codable {
    let totalDistance: Double
    let totalDuration: Int
    let totalCalories: Int
    let workoutCount: Int
    let workouts: [QingheWorkout]

    enum CodingKeys: String, CodingKey {
        case totalDistance = "total_distance"
        case totalDuration = "total_duration"
        case totalCalories = "total_calories"
        case workoutCount = "workout_count"
        case workouts
    }

    init(totalDistance: Double = 0.0, totalDuration: Int = 0, totalCalories: Int = 0, workoutCount: Int = 0, workouts: [QingheWorkout] = []) {
        self.totalDistance = totalDistance
        self.totalDuration = totalDuration
        self.totalCalories = totalCalories
        self.workoutCount = workoutCount
        self.workouts = workouts
    }
}

// MARK: - 运动记录 ViewModel (重构版 - 移除模拟数据)
@MainActor
class WorkoutRecordsViewModel: ObservableObject {
    @Published var filteredWorkouts: [WorkoutRecordItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMoreData = true
    @Published var selectedTimeRange = 1 // 默认选择"周"
    @Published var selectedWorkoutType: WorkoutType?

    private var currentPage = 1
    private let pageSize = 20
    private let apiService = NewWorkoutAPIService.shared

    func loadWorkouts() async {
        isLoading = true
        currentPage = 1
        errorMessage = nil

        do {
            // 从真实API获取运动记录
            let (startDate, endDate) = getTimeRangeFilter()
            let workouts = try await apiService.getWorkouts(
                page: currentPage,
                limit: pageSize,
                workoutType: selectedWorkoutType?.rawValue,
                startDate: startDate,
                endDate: endDate
            )

            // 转换为WorkoutRecordItem
            filteredWorkouts = workouts.map { apiWorkout in
                WorkoutRecordItem(
                    workoutId: apiWorkout.workoutId,
                    workoutType: WorkoutType(rawValue: apiWorkout.workoutType) ?? .other,
                    date: parseDate(from: apiWorkout.startTime) ?? Date(),
                    duration: apiWorkout.duration,
                    distance: apiWorkout.basicMetrics.totalDistance > 0 ? apiWorkout.basicMetrics.totalDistance : nil,
                    calories: apiWorkout.basicMetrics.calories,
                    notes: apiWorkout.notes,
                    apiWorkout: apiWorkout
                )
            }

            hasMoreData = workouts.count >= pageSize

            print("✅ 运动记录加载成功 - 数量: \(workouts.count)")

        } catch {
            errorMessage = "加载运动记录失败: \(error.localizedDescription)"
            filteredWorkouts = []
            hasMoreData = false

            print("❌ 运动记录加载失败: \(error)")
        }

        isLoading = false
    }

    func loadMoreWorkouts() async {
        guard !isLoading && hasMoreData else { return }

        isLoading = true
        currentPage += 1

        do {
            let (startDate, endDate) = getTimeRangeFilter()
            let moreWorkouts = try await apiService.getWorkouts(
                page: currentPage,
                limit: pageSize,
                workoutType: selectedWorkoutType?.rawValue,
                startDate: startDate,
                endDate: endDate
            )

            let newWorkoutItems = moreWorkouts.map { apiWorkout in
                WorkoutRecordItem(
                    workoutId: apiWorkout.workoutId,
                    workoutType: WorkoutType(rawValue: apiWorkout.workoutType) ?? .other,
                    date: parseDate(from: apiWorkout.startTime) ?? Date(),
                    duration: apiWorkout.duration,
                    distance: apiWorkout.basicMetrics.totalDistance > 0 ? apiWorkout.basicMetrics.totalDistance : nil,
                    calories: apiWorkout.basicMetrics.calories,
                    notes: apiWorkout.notes,
                    apiWorkout: apiWorkout
                )
            }

            filteredWorkouts.append(contentsOf: newWorkoutItems)
            hasMoreData = moreWorkouts.count >= pageSize

            print("✅ 更多运动记录加载成功 - 数量: \(moreWorkouts.count)")

        } catch {
            errorMessage = "加载更多记录失败: \(error.localizedDescription)"
            currentPage -= 1 // 回退页码

            print("❌ 加载更多记录失败: \(error)")
        }

        isLoading = false
    }

    func refreshData() async {
        await loadWorkouts()
    }

    func clearErrorMessage() {
        errorMessage = nil
    }

    func applyFilters() async {
        await loadWorkouts()
    }

    // 计算属性
    var totalDistance: Double {
        return filteredWorkouts.compactMap { $0.distance }.reduce(0, +)
    }

    var totalCalories: Int {
        return filteredWorkouts.map { $0.calories }.reduce(0, +)
    }

    var formattedTotalDuration: String {
        let totalSeconds = filteredWorkouts.map { $0.duration }.reduce(0, +)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }

    // MARK: - 私有方法

    private func getTimeRangeFilter() -> (startDate: String?, endDate: String?) {
        let calendar = Calendar.current
        let now = Date()
        let formatter = ISO8601DateFormatter()

        switch selectedTimeRange {
        case 0: // 今天
            if let interval = calendar.dateInterval(of: .day, for: now) {
                return (formatter.string(from: interval.start), formatter.string(from: interval.end))
            }
        case 1: // 本周
            if let interval = calendar.dateInterval(of: .weekOfYear, for: now) {
                return (formatter.string(from: interval.start), formatter.string(from: interval.end))
            }
        case 2: // 本月
            if let interval = calendar.dateInterval(of: .month, for: now) {
                return (formatter.string(from: interval.start), formatter.string(from: interval.end))
            }
        case 3: // 本年
            if let interval = calendar.dateInterval(of: .year, for: now) {
                return (formatter.string(from: interval.start), formatter.string(from: interval.end))
            }
        default:
            break
        }

        return (nil, nil)
    }

    private func parseDate(from dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}

