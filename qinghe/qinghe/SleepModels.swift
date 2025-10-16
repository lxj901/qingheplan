import Foundation
import SwiftUI

// MARK: - Sleep Stage Types
enum SleepStageType: String, Codable, CaseIterable {
    case awake = "awake"
    case light = "light"
    case deep = "deep"
    case rem = "rem"
    
    var displayName: String {
        switch self {
        case .awake:
            return "清醒"
        case .light:
            return "浅睡"
        case .deep:
            return "深睡"
        case .rem:
            return "REM"
        }
    }
    
    var color: Color {
        switch self {
        case .awake:
            return Color(red: 1.0, green: 0.42, blue: 0.42)
        case .light:
            return Color(red: 0.31, green: 0.80, blue: 0.77)
        case .deep:
            return Color(red: 0.27, green: 0.72, blue: 0.82)
        case .rem:
            return Color(red: 0.59, green: 0.81, blue: 0.71)
        }
    }
}

// MARK: - Sleep Stage Model
struct SleepStage: Identifiable, Codable {
    let id: UUID
    let stage: SleepStageType
    let startTime: Date
    let duration: TimeInterval
    
    init(id: UUID = UUID(), stage: SleepStageType, startTime: Date, duration: TimeInterval) {
        self.id = id
        self.stage = stage
        self.startTime = startTime
        self.duration = duration
    }
    
    var endTime: Date {
        return startTime.addingTimeInterval(duration)
    }
}

// MARK: - Sleep Record Model
struct SleepRecord: Identifiable, Codable {
    let id: UUID
    let sleepId: Int?
    let originalSessionId: String?
    let bedTime: Date
    let sleepTime: Date
    let wakeTime: Date
    let totalSleepDuration: TimeInterval
    let sleepEfficiency: Double
    let sleepQualityScore: Int
    let sleepStages: [SleepStage]
    let environmentData: SleepEnvironment?
    let notes: String?
    let createdAt: Date
    
    init(id: UUID = UUID(), sleepId: Int? = nil, originalSessionId: String? = nil, bedTime: Date, sleepTime: Date, wakeTime: Date, sleepStages: [SleepStage] = [], sleepQuality: SleepQuality? = nil, sleepScore: Int = 75, sleepEfficiency: Double = 0.85, totalSleepTime: Int = 480, notes: String? = nil, environmentData: SleepEnvironment? = nil) {
        self.id = id
        self.sleepId = sleepId
        self.originalSessionId = originalSessionId
        self.bedTime = bedTime
        self.sleepTime = sleepTime
        self.wakeTime = wakeTime
        self.sleepStages = sleepStages
        self.sleepQualityScore = sleepScore
        self.sleepEfficiency = sleepEfficiency
        self.totalSleepDuration = TimeInterval(totalSleepTime * 60)
        self.notes = notes
        self.environmentData = environmentData
        self.createdAt = Date()
    }
    
    var formattedBedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: bedTime)
    }
    
    var formattedSleepTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: sleepTime)
    }
    
    var formattedWakeTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: wakeTime)
    }
    
    var formattedSleepDuration: String {
        let hours = Int(totalSleepDuration) / 3600
        let minutes = (Int(totalSleepDuration) % 3600) / 60
        return String(format: "%dh%02dm", hours, minutes)
    }
    
    // MARK: - API 数据转换
    
    /// 转换为API上传格式
    func toAPIUploadFormat() -> [String: Any] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // 计算各睡眠阶段的时长（分钟）
        let deepDuration = sleepStages
            .filter { $0.stage == .deep }
            .reduce(0.0) { $0 + $1.duration } / 60.0
        
        let lightDuration = sleepStages
            .filter { $0.stage == .light }
            .reduce(0.0) { $0 + $1.duration } / 60.0
        
        let remDuration = sleepStages
            .filter { $0.stage == .rem }
            .reduce(0.0) { $0 + $1.duration } / 60.0
        
        let awakeDuration = sleepStages
            .filter { $0.stage == .awake }
            .reduce(0.0) { $0 + $1.duration } / 60.0
        
        // 获取睡眠日期（使用就寝日期）
        let sleepDateFormatter = DateFormatter()
        sleepDateFormatter.dateFormat = "yyyy-MM-dd"
        sleepDateFormatter.timeZone = TimeZone.current
        let sleepDateString = sleepDateFormatter.string(from: bedTime)
        
        // 转换质量评分（1-10范围）
        let qualityScore = min(max(Double(sleepQualityScore) / 10.0, 1.0), 10.0)
        
        return [
            "sleepDate": sleepDateString,
            "startTime": dateFormatter.string(from: bedTime),
            "endTime": dateFormatter.string(from: wakeTime),
            "duration": Int(totalSleepDuration / 60.0), // 转换为分钟
            "quality": qualityScore,
            "deepSleepDuration": Int(deepDuration),
            "lightSleepDuration": Int(lightDuration),
            "remSleepDuration": Int(remDuration),
            "awakeDuration": Int(awakeDuration)
        ]
    }
    
    // MARK: - API 数据转换
    
    /// 转换为API上传格式
    func toAPIUploadFormat() -> [String: Any] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // 计算各睡眠阶段的时长（分钟）
        let deepDuration = sleepStages
            .filter { $0.stage == .deep }
            .reduce(0.0) { $0 + $1.duration } / 60.0
        
        let lightDuration = sleepStages
            .filter { $0.stage == .light }
            .reduce(0.0) { $0 + $1.duration } / 60.0
        
        let remDuration = sleepStages
            .filter { $0.stage == .rem }
            .reduce(0.0) { $0 + $1.duration } / 60.0
        
        let awakeDuration = sleepStages
            .filter { $0.stage == .awake }
            .reduce(0.0) { $0 + $1.duration } / 60.0
        
        // 获取睡眠日期（使用就寝日期）
        let sleepDateFormatter = DateFormatter()
        sleepDateFormatter.dateFormat = "yyyy-MM-dd"
        sleepDateFormatter.timeZone = TimeZone.current
        let sleepDateString = sleepDateFormatter.string(from: bedTime)
        
        // 转换质量评分（1-10范围）
        let qualityScore = min(max(Double(sleepQualityScore) / 10.0, 1.0), 10.0)
        
        return [
            "sleepDate": sleepDateString,
            "startTime": dateFormatter.string(from: bedTime),
            "endTime": dateFormatter.string(from: wakeTime),
            "duration": Int(totalSleepDuration / 60.0), // 转换为分钟
            "quality": qualityScore,
            "deepSleepDuration": Int(deepDuration),
            "lightSleepDuration": Int(lightDuration),
            "remSleepDuration": Int(remDuration),
            "awakeDuration": Int(awakeDuration)
        ]
    }
}

// MARK: - Sleep Environment
struct SleepEnvironment: Codable {
    let temperature: Double?
    let humidity: Double?
    let noiseLevel: Double?
    let lightLevel: Double?
    
    init(temperature: Double? = nil, humidity: Double? = nil, noiseLevel: Double? = nil, lightLevel: Double? = nil) {
        self.temperature = temperature
        self.humidity = humidity
        self.noiseLevel = noiseLevel
        self.lightLevel = lightLevel
    }
}

// MARK: - Sleep Quality
enum SleepQuality: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        switch self {
        case .excellent: return "优秀"
        case .good: return "良好" 
        case .fair: return "一般"
        case .poor: return "较差"
        }
    }
}

// MARK: - Local Audio File
struct LocalAudioFile: Identifiable, Codable {
    let id: UUID
    let fileName: String
    let relativePath: String  // 🔥 改为相对路径
    let duration: TimeInterval
    let fileSize: Int64
    let recordingDate: Date
    let sessionId: String
    let isUploaded: Bool

    init(id: UUID = UUID(), fileName: String, relativePath: String, duration: TimeInterval, fileSize: Int64, recordingDate: Date = Date(), sessionId: String, isUploaded: Bool = false) {
        self.id = id
        self.fileName = fileName
        self.relativePath = relativePath  // 🔥 存储相对路径
        self.duration = duration
        self.fileSize = fileSize
        self.recordingDate = recordingDate
        self.sessionId = sessionId
        self.isUploaded = isUploaded
    }
    
    // 🔥 新增：动态计算完整路径
    var fullPath: String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(relativePath).path
    }
    
    // 🔥 兼容性：保留旧的filePath属性
    var filePath: String {
        return fullPath
    }
}

// MARK: - Sleep Local Audio Segment
struct SleepLocalAudioSegment: Identifiable, Codable {
    let id: UUID
    let type: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let confidence: Double
    let sessionId: String
    // 新增：事件音频文件名与路径（可选）、事件发生时间戳
    let fileName: String?
    let filePath: String?
    let eventDate: Date?

    init(id: UUID = UUID(), type: String, startTime: TimeInterval, endTime: TimeInterval, confidence: Double, sessionId: String, fileName: String? = nil, filePath: String? = nil, eventDate: Date? = nil) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
        self.sessionId = sessionId
        self.fileName = fileName
        self.filePath = filePath
        self.eventDate = eventDate
    }

    var duration: TimeInterval {
        return endTime - startTime
    }
    
    // 🔥 动态计算音频文件的完整路径
    var actualFilePath: String? {
        guard let fileName = fileName else { return filePath }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fullPath = documentsPath.appendingPathComponent("SleepRecordings").appendingPathComponent(fileName).path
        return fullPath
    }

    var typeName: String {
        // 将英文/多来源标签统一为中文展示名称
        let t = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch t {
        case "snore", "snoring", "呼噜", "鼾", "鼾声":
            return "打鼾"
        case "talk", "talking", "speech", "梦话", "说话", "语音":
            return "梦话"
        case "breath", "breathing", "呼吸", "呼吸声":
            return "呼吸"
        case "movement", "move", "动作", "翻身":
            return "动作"
        case "silence", "quiet", "静音", "安静", "静默":
            return "静音"
        case "environment", "env", "noise", "环境", "环境声", "噪声", "背景噪声":
            return "环境声"
        case "cough", "coughing", "咳嗽":
            return "咳嗽"
        case "audio":
            return "音频片段"
        default:
            return type // 未知类型原样返回，便于排查
        }
    }
}

// MARK: - Sleep Audio Analysis Result
struct SleepAudioAnalysisResult: Codable {
    let sessionId: String
    let overallQuality: Double
    let sleepQualityScore: Double
    let qualityLevel: SleepAudioQualityLevel
    let sleepQualityInsights: [String]
    let soundTypeStatistics: [String: SoundTypeStatistics]
    let analysisDate: Date
    
    init(sessionId: String, overallQuality: Double = 75.0, sleepQualityScore: Double = 75.0, qualityLevel: SleepAudioQualityLevel = .good, sleepQualityInsights: [String] = [], soundTypeStatistics: [String: SoundTypeStatistics] = [:], analysisDate: Date = Date()) {
        self.sessionId = sessionId
        self.overallQuality = overallQuality
        self.sleepQualityScore = sleepQualityScore
        self.qualityLevel = qualityLevel
        self.sleepQualityInsights = sleepQualityInsights
        self.soundTypeStatistics = soundTypeStatistics
        self.analysisDate = analysisDate
    }
    
    func getStatistics(for soundType: LocalSleepAudioAnalyzer.SoundType) -> SoundTypeStatistics? {
        return soundTypeStatistics[soundType.rawValue]
    }
}

// MARK: - Sleep Audio Quality Level
enum SleepAudioQualityLevel: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"

    var colorHex: String {
        switch self {
        case .excellent: return "#4CAF50"
        case .good: return "#2196F3"
        case .fair: return "#FF9800"
        case .poor: return "#F44336"
        }
    }

    var color: String {
        return colorHex
    }
}

// MARK: - Sound Type Statistics
struct SoundTypeStatistics: Codable {
    let count: Int
    let totalDuration: TimeInterval
    let averageConfidence: Double
    
    init(count: Int, totalDuration: TimeInterval, averageConfidence: Double) {
        self.count = count
        self.totalDuration = totalDuration
        self.averageConfidence = averageConfidence
    }
    
    var formattedDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%d分%02d秒", minutes, seconds)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        // 安全地处理字符串，避免索引越界
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        // 确保字符串不为空
        guard !cleanHex.isEmpty else {
            self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
            return
        }

        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64

        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, ((int >> 8) & 0xF) * 17, ((int >> 4) & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            // 默认为黑色，避免无效值
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Sleep Statistics Model
struct SleepStatistics: Codable {
    let averageSleepDuration: TimeInterval
    let averageSleepEfficiency: Double
    let averageSleepQuality: Double
    let consistencyScore: Double
    let totalRecords: Int
    let period: StatisticsPeriod
    let generatedAt: Date

    init(averageSleepDuration: TimeInterval = 0, averageSleepEfficiency: Double = 0, averageSleepQuality: Double = 0, consistencyScore: Double = 0, totalRecords: Int = 0, period: StatisticsPeriod = .week, generatedAt: Date = Date()) {
        self.averageSleepDuration = averageSleepDuration
        self.averageSleepEfficiency = averageSleepEfficiency
        self.averageSleepQuality = averageSleepQuality
        self.consistencyScore = consistencyScore
        self.totalRecords = totalRecords
        self.period = period
        self.generatedAt = generatedAt
    }
}

// MARK: - Statistics Period
enum StatisticsPeriod: String, Codable, CaseIterable {
    case week = "week"
    case month = "month"
    case year = "year"

    var displayName: String {
        switch self {
        case .week: return "本周"
        case .month: return "本月"
        case .year: return "本年"
        }
    }
}

// MARK: - Sleep Insight Type
enum SleepInsightType: String, Codable, CaseIterable {
    case sleepDuration = "sleep_duration"
    case sleepQuality = "sleep_quality"
    case bedtimeConsistency = "bedtime_consistency"
    case sleepEnvironment = "sleep_environment"
    case general = "general"

    var displayName: String {
        switch self {
        case .sleepDuration: return "睡眠时长"
        case .sleepQuality: return "睡眠质量"
        case .bedtimeConsistency: return "作息规律"
        case .sleepEnvironment: return "睡眠环境"
        case .general: return "一般建议"
        }
    }

    var icon: String {
        switch self {
        case .sleepDuration: return "clock.fill"
        case .sleepQuality: return "star.fill"
        case .bedtimeConsistency: return "calendar.circle.fill"
        case .sleepEnvironment: return "house.fill"
        case .general: return "lightbulb.fill"
        }
    }
}

// MARK: - Sleep Insight Priority
enum SleepInsightPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }
}

// MARK: - Sleep Insight Model
struct SleepInsight: Identifiable, Codable {
    let id: UUID
    let type: SleepInsightType
    let title: String
    let message: String?
    let description: String
    let priority: SleepInsightPriority
    let priorityLevel: SleepInsightPriority?
    let actionable: Bool
    let createdAt: Date

    init(id: UUID = UUID(), type: SleepInsightType, title: String, message: String? = nil, description: String = "", priority: SleepInsightPriority = .medium, priorityLevel: SleepInsightPriority? = nil, actionable: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.description = description
        self.priority = priority
        self.priorityLevel = priorityLevel ?? priority
        self.actionable = actionable
        self.createdAt = createdAt
    }
}

// MARK: - Sleep Goal Model
struct SleepGoal: Codable {
    let targetBedtime: Date
    let targetWakeTime: Date
    let targetSleepDuration: TimeInterval
    let createdAt: Date

    init(targetBedtime: Date, targetWakeTime: Date, targetSleepDuration: TimeInterval = 8 * 3600, createdAt: Date = Date()) {
        self.targetBedtime = targetBedtime
        self.targetWakeTime = targetWakeTime
        self.targetSleepDuration = targetSleepDuration
        self.createdAt = createdAt
    }
}

// MARK: - Sleep Report Model
struct SleepReport: Codable {
    let period: StatisticsPeriod
    let statistics: SleepStatistics
    let insights: [SleepInsight]
    let generatedAt: Date

    init(period: StatisticsPeriod, statistics: SleepStatistics, insights: [SleepInsight] = [], generatedAt: Date = Date()) {
        self.period = period
        self.statistics = statistics
        self.insights = insights
        self.generatedAt = generatedAt
    }
}

// 注意：SleepDataManager 已在 SleepDataManager.swift 中定义

// MARK: - Audio Segment Model
struct AudioSegment: Identifiable, Codable {
    let id: UUID
    let startTime: TimeInterval
    let endTime: TimeInterval
    let type: String
    let confidence: Double

    init(startTime: TimeInterval, endTime: TimeInterval, type: String, confidence: Double = 1.0) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.confidence = confidence
    }
}