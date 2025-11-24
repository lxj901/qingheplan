import Foundation
import SwiftUI

// MARK: - DeepSeek AI 睡眠分析数据模型

/// DeepSeek AI 睡眠分析主结果
struct DeepSeekSleepAnalysis: Codable, Identifiable {
    let id = UUID()
    let analysisId: String
    let sessionId: String
    let analysisDate: Date
    let processingTime: TimeInterval
    let confidence: Double // 0-100，分析置信度
    
    // 核心分析模块
    let qualityAssessment: DeepSeekSleepQualityAssessment
    let stageAnalysis: SleepStageAnalysis
    let aiInsights: [DeepSeekSleepInsight]
    let personalizedRecommendations: [DeepSeekSleepRecommendation]

    // 分析质量指标
    let reportVersion: String

    enum CodingKeys: String, CodingKey {
        case analysisId, sessionId, analysisDate, processingTime, confidence
        case qualityAssessment, stageAnalysis, aiInsights, personalizedRecommendations, reportVersion
    }

    // 计算属性：睡眠质量文本
    var sleepQualityText: String {
        return qualityAssessment.qualityLevel.displayName
    }
    
    init(sessionId: String, qualityScore: Double = 75.0, insights: [String] = [], recommendations: [String] = [], sleepEfficiency: Double = 85.0, lightSleepPercentage: Double = 45.0, deepSleepPercentage: Double = 25.0, remSleepPercentage: Double = 30.0) {
        self.analysisId = UUID().uuidString
        self.sessionId = sessionId
        self.analysisDate = Date()
        self.processingTime = 2.5
        self.confidence = 85.0
        self.reportVersion = "1.0"

        // 创建质量评估
        self.qualityAssessment = DeepSeekSleepQualityAssessment(
            overallScore: qualityScore,
            qualityLevel: Self.getQualityLevel(from: qualityScore),
            improvementPotential: max(0, 100 - qualityScore)
        )

        // 创建睡眠阶段分析（使用传入的真实数据）
        self.stageAnalysis = SleepStageAnalysis(
            sleepEfficiency: sleepEfficiency,
            lightSleepDuration: 0,
            deepSleepDuration: 0,
            remSleepDuration: 0,
            awakeDuration: 0,
            lightSleepPercentage: lightSleepPercentage,
            deepSleepPercentage: deepSleepPercentage,
            remSleepPercentage: remSleepPercentage,
            sleepContinuity: 0,
            fragmentationIndex: 0,
            cycleCount: 0,
            averageCycleLength: 0
        )
        
        // 创建AI洞察
        self.aiInsights = insights.enumerated().map { index, insight in
            DeepSeekSleepInsight(
                type: index == 0 ? .positive : .info,
                title: "睡眠洞察 \(index + 1)",
                description: insight,
                confidence: Double.random(in: 75...95),
                priority: .medium,
                relatedMetrics: ["睡眠质量", "睡眠效率"],
                actionable: true
            )
        }
        
        // 创建个性化建议
        self.personalizedRecommendations = recommendations.enumerated().map { index, recommendation in
            DeepSeekSleepRecommendation(
                type: .schedule,
                title: "改善建议 \(index + 1)",
                description: recommendation,
                priority: index == 0 ? .high : .medium,
                category: .habit,
                estimatedImpact: .medium,
                implementationDifficulty: .medium,
                timeToSeeResults: "1-2周",
                relatedInsights: []
            )
        }
    }
    
    private static func getQualityLevel(from score: Double) -> DeepSeekSleepQualityLevel {
        switch score {
        case 90...100: return .excellent
        case 75..<90: return .good
        case 60..<75: return .fair
        default: return .poor
        }
    }
}

// MARK: - 综合睡眠质量评估

/// 睡眠质量评估
struct DeepSeekSleepQualityAssessment: Codable {
    let overallScore: Double // 0-100分的总体评分
    let qualityLevel: DeepSeekSleepQualityLevel
    let improvementPotential: Double // 改善潜力（0-100分）
    let efficiencyScore: Double // 睡眠效率评分
    let structureScore: Double // 睡眠结构评分
    let disruptionScore: Double // 干扰因素评分
    let continuityScore: Double // 连续性评分

    init(overallScore: Double, qualityLevel: DeepSeekSleepQualityLevel, improvementPotential: Double, efficiencyScore: Double = 85.0, structureScore: Double = 85.0, disruptionScore: Double = 85.0, continuityScore: Double = 85.0) {
        self.overallScore = overallScore
        self.qualityLevel = qualityLevel
        self.improvementPotential = improvementPotential
        self.efficiencyScore = efficiencyScore
        self.structureScore = structureScore
        self.disruptionScore = disruptionScore
        self.continuityScore = continuityScore
    }
}

/// 睡眠质量等级
enum DeepSeekSleepQualityLevel: String, Codable, CaseIterable {
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
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "睡眠质量极佳，保持现有习惯"
        case .good: return "睡眠质量较好，小幅优化即可"
        case .fair: return "睡眠质量中等，需要改善"
        case .poor: return "睡眠质量不佳，急需改善"
        }
    }
}

// MARK: - AI洞察分析

/// AI洞察
struct DeepSeekSleepInsight: Codable, Identifiable {
    let id = UUID()
    let type: DeepSeekInsightType
    let title: String
    let description: String
    let confidence: Double // 置信度（0-100%）
    let priority: DeepSeekInsightPriority
    let relatedMetrics: [String] // 相关指标
    let actionable: Bool // 是否可操作
    
    enum CodingKeys: String, CodingKey {
        case type, title, description, confidence, priority, relatedMetrics, actionable
    }
}

/// 洞察类型
enum DeepSeekInsightType: String, Codable, CaseIterable {
    case positive = "positive"
    case warning = "warning"
    case info = "info"
    case concern = "concern"
    case neutral = "neutral"

    var displayName: String {
        switch self {
        case .positive: return "积极洞察"
        case .warning: return "警告洞察"
        case .info: return "信息洞察"
        case .concern: return "关注洞察"
        case .neutral: return "中性洞察"
        }
    }

    var icon: String {
        switch self {
        case .positive: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .concern: return "exclamationmark.circle.fill"
        case .neutral: return "circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .positive: return .green
        case .warning: return .orange
        case .info: return .blue
        case .concern: return .red
        case .neutral: return .gray
        }
    }
}

/// 洞察优先级
enum DeepSeekInsightPriority: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .high: return "高优先级"
        case .medium: return "中优先级"
        case .low: return "低优先级"
        }
    }
}

// MARK: - 个性化改善建议

/// 睡眠改善建议
struct DeepSeekSleepRecommendation: Codable, Identifiable {
    let id = UUID()
    let type: DeepSeekRecommendationType
    let title: String
    let description: String
    let priority: DeepSeekRecommendationPriority
    let category: DeepSeekRecommendationCategory
    let estimatedImpact: DeepSeekImpactLevel // 预期影响程度
    let implementationDifficulty: DeepSeekDifficultyLevel // 实施难度
    let timeToSeeResults: String // 见效时间
    let relatedInsights: [String] // 相关洞察ID

    init(type: DeepSeekRecommendationType, title: String, description: String, priority: DeepSeekRecommendationPriority, category: DeepSeekRecommendationCategory, estimatedImpact: DeepSeekImpactLevel, implementationDifficulty: DeepSeekDifficultyLevel, timeToSeeResults: String, relatedInsights: [String]) {
        self.type = type
        self.title = title
        self.description = description
        self.priority = priority
        self.category = category
        self.estimatedImpact = estimatedImpact
        self.implementationDifficulty = implementationDifficulty
        self.timeToSeeResults = timeToSeeResults
        self.relatedInsights = relatedInsights
    }

    enum CodingKeys: String, CodingKey {
        case type, title, description, priority, category, estimatedImpact, implementationDifficulty, timeToSeeResults, relatedInsights
    }
}

/// 建议优先级
enum DeepSeekRecommendationPriority: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .high: return "高优先级"
        case .medium: return "中优先级"
        case .low: return "低优先级"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
    
    var urgency: String {
        switch self {
        case .high: return "立即处理"
        case .medium: return "近期处理"
        case .low: return "长期维护"
        }
    }
}

/// 建议类别
enum DeepSeekRecommendationCategory: String, Codable, CaseIterable {
    case environment = "environment"
    case habit = "habit"
    case timing = "timing"
    case health = "health"
    case technology = "technology"
    case comfort = "comfort"
    case schedule = "schedule"
    case lifestyle = "lifestyle"

    var displayName: String {
        switch self {
        case .environment: return "环境优化"
        case .habit: return "习惯养成"
        case .timing: return "时间调整"
        case .health: return "健康改善"
        case .technology: return "技术辅助"
        case .comfort: return "舒适度"
        case .schedule: return "作息安排"
        case .lifestyle: return "生活方式"
        }
    }

    // 自定义解码器，支持中文类别名称
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)

        // 首先尝试英文原始值
        if let category = DeepSeekRecommendationCategory(rawValue: stringValue) {
            self = category
            return
        }

        // 然后尝试中文显示名称映射
        switch stringValue {
        case "环境优化", "环境", "环境因素":
            self = .environment
        case "习惯养成", "健康习惯", "习惯", "生活习惯":
            self = .habit
        case "时间调整", "时间管理", "时间":
            self = .timing
        case "健康改善", "健康", "医疗", "健康问题":
            self = .health
        case "技术辅助", "技术", "设备":
            self = .technology
        case "舒适度", "舒适", "睡眠舒适度":
            self = .comfort
        case "作息安排", "作息", "睡眠时间", "时间安排":
            self = .schedule
        case "生活方式", "生活", "日常生活":
            self = .lifestyle
        default:
            // 如果都不匹配，默认使用 habit
            print("⚠️ 未知的建议类别: \(stringValue)，使用默认类别 'habit'")
            self = .habit
        }
    }

    var icon: String {
        switch self {
        case .environment: return "house.fill"
        case .habit: return "repeat"
        case .timing: return "clock.fill"
        case .health: return "heart.fill"
        case .technology: return "gear"
        case .comfort: return "bed.double.fill"
        case .schedule: return "calendar"
        case .lifestyle: return "figure.walk"
        }
    }
}

/// 实施难度
enum DeepSeekImplementationDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy: return "容易"
        case .medium: return "中等"
        case .hard: return "困难"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - 辅助扩展

extension DeepSeekSleepAnalysis {
    /// 获取睡眠质量等级的颜色
    var qualityColor: Color {
        return qualityAssessment.qualityLevel.color
    }
    
    /// 获取主要改善建议（高优先级）
    var primaryRecommendations: [DeepSeekSleepRecommendation] {
        return personalizedRecommendations.filter { $0.priority == .high }
    }
    
    /// 获取积极洞察
    var positiveInsights: [DeepSeekSleepInsight] {
        return aiInsights.filter { $0.type == .positive }
    }
    
    /// 获取警告洞察
    var warningInsights: [DeepSeekSleepInsight] {
        return aiInsights.filter { $0.type == .warning }
    }
}

// MARK: - Sleep Stage Analysis

struct SleepStageAnalysis: Codable {
    let sleepEfficiency: Double
    let lightSleepDuration: TimeInterval
    let deepSleepDuration: TimeInterval
    let remSleepDuration: TimeInterval
    let awakeDuration: TimeInterval
    let lightSleepPercentage: Double
    let deepSleepPercentage: Double
    let remSleepPercentage: Double
    let sleepContinuity: Double
    let fragmentationIndex: Double
    let cycleCount: Int
    let averageCycleLength: TimeInterval

    init(sleepEfficiency: Double = 85.0, lightSleepDuration: TimeInterval = 0, deepSleepDuration: TimeInterval = 0, remSleepDuration: TimeInterval = 0, awakeDuration: TimeInterval = 0, lightSleepPercentage: Double = 0, deepSleepPercentage: Double = 0, remSleepPercentage: Double = 0, sleepContinuity: Double = 0, fragmentationIndex: Double = 0, cycleCount: Int = 0, averageCycleLength: TimeInterval = 0) {
        self.sleepEfficiency = sleepEfficiency
        self.lightSleepDuration = lightSleepDuration
        self.deepSleepDuration = deepSleepDuration
        self.remSleepDuration = remSleepDuration
        self.awakeDuration = awakeDuration
        self.lightSleepPercentage = lightSleepPercentage
        self.deepSleepPercentage = deepSleepPercentage
        self.remSleepPercentage = remSleepPercentage
        self.sleepContinuity = sleepContinuity
        self.fragmentationIndex = fragmentationIndex
        self.cycleCount = cycleCount
        self.averageCycleLength = averageCycleLength
    }
}

// MARK: - 增强版建议系统枚举

/// 建议类型
enum DeepSeekRecommendationType: String, Codable, CaseIterable {
    case health = "health"
    case environment = "environment"
    case comfort = "comfort"
    case schedule = "schedule"
    case lifestyle = "lifestyle"
    case maintenance = "maintenance"
    case comprehensive = "comprehensive"
    case habit = "habit"
    case timing = "timing"
    case technology = "technology"

    var displayName: String {
        switch self {
        case .health: return "健康建议"
        case .environment: return "环境优化"
        case .comfort: return "舒适度改善"
        case .schedule: return "作息调整"
        case .lifestyle: return "生活方式"
        case .maintenance: return "维持现状"
        case .comprehensive: return "综合改善"
        case .habit: return "习惯养成"
        case .timing: return "时间管理"
        case .technology: return "技术辅助"
        }
    }

    // 自定义解码器，支持中文类型名称
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)

        // 首先尝试英文原始值
        if let type = DeepSeekRecommendationType(rawValue: stringValue) {
            self = type
            return
        }

        // 然后尝试中文显示名称映射
        switch stringValue {
        case "健康建议", "健康", "医疗", "健康问题":
            self = .health
        case "环境优化", "环境", "环境因素":
            self = .environment
        case "舒适度改善", "舒适度", "舒适":
            self = .comfort
        case "作息调整", "作息", "睡眠时间", "时间安排":
            self = .schedule
        case "生活方式", "生活", "日常生活":
            self = .lifestyle
        case "维持现状", "维持", "保持":
            self = .maintenance
        case "综合改善", "综合", "全面改善":
            self = .comprehensive
        case "习惯养成", "习惯", "生活习惯":
            self = .habit
        case "时间管理", "时间", "时间调整":
            self = .timing
        case "技术辅助", "技术", "设备":
            self = .technology
        default:
            // 如果都不匹配，默认使用 health
            print("⚠️ 未知的建议类型: \(stringValue)，使用默认类型 'health'")
            self = .health
        }
    }
}

/// 影响程度（兼容外部API的扩展取值）
enum DeepSeekImpactLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    // 自定义解码：兼容 "critical"/"very_high"/"severe" 等映射到 .high；未知值回退 .medium
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.lowercased() ?? "medium"
        switch raw {
        case "low": self = .low
        case "medium": self = .medium
        case "high", "critical", "very_high", "very-high", "severe": self = .high
        default:
            print("⚠️ 未知的 DeepSeekImpactLevel 值: \(raw), 回退为 .medium")
            self = .medium
        }
    }

    // 自定义编码维持原始 rawValue
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    var displayName: String {
        switch self {
        case .low: return "轻微影响"
        case .medium: return "中等影响"
        case .high: return "显著影响"
        }
    }

    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

/// 实施难度
enum DeepSeekDifficultyLevel: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"

    var displayName: String {
        switch self {
        case .easy: return "容易"
        case .medium: return "中等"
        case .hard: return "困难"
        }
    }

    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - 扩展建议分类

extension DeepSeekRecommendationCategory {
    static let sleepPosition = DeepSeekRecommendationCategory.health
    static let routine = DeepSeekRecommendationCategory.habit
    static let comprehensive = DeepSeekRecommendationCategory.health
    static let maintenance = DeepSeekRecommendationCategory.habit
}

// MARK: - 用户睡眠档案模型已在 DeepSeekSleepAnalysisEngine.swift 中定义

// MARK: - 新增的 API 集成相关模型

// 注意：SleepStageType 和 SleepStage 已在 SleepModels.swift 中定义，这里不再重复定义

/// 质量因子
struct DeepSeekQualityFactor: Codable {
    let name: String
    let score: Double
    let impact: QualityImpact
    let description: String

    enum QualityImpact: String, Codable {
        case positive = "positive"
        case neutral = "neutral"
        case negative = "negative"

        var color: Color {
            switch self {
            case .positive: return .green
            case .neutral: return .gray
            case .negative: return .red
            }
        }
    }
}

// MARK: - 扩展方法

/// 增强版睡眠阶段分析
extension SleepStageAnalysis {
    init(
        stages: [SleepStage],
        totalSleepTime: TimeInterval,
        sleepEfficiency: Double,
        stageDistribution: [SleepStageType: Double]
    ) {
        self.sleepEfficiency = sleepEfficiency
        self.lightSleepDuration = stages.filter { $0.stage == .light }.reduce(0) { $0 + $1.duration }
        self.deepSleepDuration = stages.filter { $0.stage == .deep }.reduce(0) { $0 + $1.duration }
        self.remSleepDuration = stages.filter { $0.stage == .rem }.reduce(0) { $0 + $1.duration }
        self.awakeDuration = stages.filter { $0.stage == .awake }.reduce(0) { $0 + $1.duration }

        self.lightSleepPercentage = stageDistribution[.light] ?? 0
        self.deepSleepPercentage = stageDistribution[.deep] ?? 0
        self.remSleepPercentage = stageDistribution[.rem] ?? 0

        self.sleepContinuity = Self.calculateContinuity(from: stages)
        self.fragmentationIndex = Self.calculateFragmentation(from: stages)
        self.cycleCount = Self.calculateCycleCount(from: stages)
        self.averageCycleLength = totalSleepTime / Double(max(1, self.cycleCount))
    }

    private static func calculateContinuity(from stages: [SleepStage]) -> Double {
        let awakeStages = stages.filter { $0.stage == .awake }
        return max(0, 100 - Double(awakeStages.count) * 5)
    }

    private static func calculateFragmentation(from stages: [SleepStage]) -> Double {
        return Double(stages.count) / 10.0 // 简化的碎片化指数
    }

    private static func calculateCycleCount(from stages: [SleepStage]) -> Int {
        // 简化的周期计算：每90分钟算一个周期
        let totalDuration = stages.reduce(0) { $0 + $1.duration }
        return max(1, Int(totalDuration / 5400)) // 5400秒 = 90分钟
    }
}

/// 增强版睡眠质量评估
extension DeepSeekSleepQualityAssessment {
    init(
        overallScore: Double,
        sleepEfficiency: Double,
        deepSleepPercentage: Double,
        remSleepPercentage: Double,
        awakeningsCount: Int,
        sleepLatency: TimeInterval,
        factors: [DeepSeekQualityFactor]
    ) {
        self.overallScore = overallScore
        self.qualityLevel = Self.getQualityLevel(from: overallScore)
        self.improvementPotential = max(0, 100 - overallScore)
        self.efficiencyScore = sleepEfficiency
        self.structureScore = (deepSleepPercentage + remSleepPercentage) / 2
        self.disruptionScore = max(0, 100 - Double(awakeningsCount) * 10)
        self.continuityScore = sleepLatency < 1800 ? 90 : 70 // 30分钟内入睡为良好
    }

    private static func getQualityLevel(from score: Double) -> DeepSeekSleepQualityLevel {
        switch score {
        case 90...100: return .excellent
        case 75..<90: return .good
        case 60..<75: return .fair
        default: return .poor
        }
    }
}

/// 增强版洞察
extension DeepSeekSleepInsight {
    init(
        id: String,
        title: String,
        description: String,
        category: InsightCategory,
        importance: DeepSeekInsightPriority,
        confidence: Double,
        relatedMetrics: [String],
        actionable: Bool,
        timestamp: Date
    ) {
        self.type = category.toInsightType()
        self.title = title
        self.description = description
        self.confidence = confidence
        self.priority = importance
        self.relatedMetrics = relatedMetrics
        self.actionable = actionable
    }

    enum InsightCategory {
        case general
        case quality
        case pattern
        case health
        case environment

        func toInsightType() -> DeepSeekInsightType {
            switch self {
            case .general: return .info
            case .quality: return .positive
            case .pattern: return .neutral
            case .health: return .concern
            case .environment: return .warning
            }
        }
    }
}