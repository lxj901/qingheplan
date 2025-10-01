import Foundation

// MARK: - 睡眠趋势分析数据模型

/// 睡眠趋势分析主结果
struct SleepTrendAnalysis: Codable {
    let analysisDate: Date
    let dataRange: DateInterval
    let shortTermTrend: ShortTermTrend
    let mediumTermTrend: MediumTermTrend
    let longTermTrend: LongTermTrend
    let qualityPrediction: SleepQualityPrediction
    let patternPrediction: SleepPatternPrediction
    let healthRiskAssessment: HealthRiskAssessment
    let improvementSuggestions: [ImprovementSuggestion]
    let personalizedGoals: [PersonalizedGoal]
    let confidence: Double
}

// MARK: - 趋势方向枚举

enum SleepTrendDirection: String, Codable, CaseIterable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"

    var displayName: String {
        switch self {
        case .improving: return "改善中"
        case .stable: return "稳定"
        case .declining: return "下降中"
        }
    }

    var color: String {
        switch self {
        case .improving: return "green"
        case .stable: return "blue"
        case .declining: return "red"
        }
    }
}

// MARK: - 时间周期枚举

enum TrendPeriod: String, Codable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    
    var displayName: String {
        switch self {
        case .week: return "一周"
        case .month: return "一个月"
        case .quarter: return "三个月"
        }
    }
}

// MARK: - 短期趋势（7天）

struct ShortTermTrend: Codable {
    let period: TrendPeriod
    let qualityTrend: SleepTrendDirection
    let qualityVariability: Double
    let durationTrend: SleepTrendDirection
    let efficiencyTrend: SleepTrendDirection
    let consistencyScore: Double
    let keyInsights: [String]
}

// MARK: - 中期趋势（30天）

struct MediumTermTrend: Codable {
    let period: TrendPeriod
    let weeklyPatterns: WeeklyPatterns
    let sleepDebtAnalysis: SleepDebtAnalysis
    let recoveryPatterns: RecoveryPatterns
    let environmentalImpacts: EnvironmentalImpacts
    let overallImprovement: Double
    let keyMilestones: [String]
}

// MARK: - 长期趋势（90天+）

struct LongTermTrend: Codable {
    let period: TrendPeriod
    let seasonalPatterns: SeasonalPatterns
    let healthTrends: DeepSeekHealthTrends
    let lifestyleImpacts: LifestyleImpacts
    let improvementTrajectory: ImprovementTrajectory
    let stabilityIndex: Double
    let predictiveAccuracy: Double
}

// MARK: - 周模式分析

struct WeeklyPatterns: Codable {
    let weekdayAverages: [Int: Double] // 星期几 -> 平均质量分数
    let bestDay: Int // 最佳睡眠日
    let worstDay: Int // 最差睡眠日
    let weekendEffect: Double // 周末效应（正值表示周末睡眠更好）
}

// MARK: - 睡眠债务分析

struct SleepDebtAnalysis: Codable {
    let totalDebt: Double // 总睡眠债务（分钟）
    let averageDebt: Double // 平均每日债务（分钟）
    let debtTrend: SleepTrendDirection
    let recoveryRecommendations: [String]
}

// MARK: - 恢复模式

struct RecoveryPatterns: Codable {
    let averageRecoveryTime: Double // 平均恢复时间（小时）
    let recoveryEfficiency: Double // 恢复效率（0-100）
    let optimalRecoveryConditions: [String]
}

// MARK: - 环境影响

struct EnvironmentalImpacts: Codable {
    let noiseImpact: Double
    let temperatureImpact: Double
    let lightImpact: Double
    let overallEnvironmentalScore: Double
}

// MARK: - 季节性模式

struct SeasonalPatterns: Codable {
    let seasonalVariations: [String: Double] // 季节 -> 质量变化
    let optimalSeason: String
    let seasonalRecommendations: [String]
}

// MARK: - 健康趋势

struct DeepSeekHealthTrends: Codable {
    let snoringTrend: SleepTrendDirection
    let breathingQualityTrend: SleepTrendDirection
    let movementTrend: SleepTrendDirection
    let overallHealthScore: Double
}

// MARK: - 生活方式影响

struct LifestyleImpacts: Codable {
    let exerciseImpact: Double
    let dietImpact: Double
    let stressImpact: Double
    let screenTimeImpact: Double
}

// MARK: - 改善轨迹

struct ImprovementTrajectory: Codable {
    let overallDirection: SleepTrendDirection
    let improvementRate: Double // 每月改善分数
    let projectedQuality: Double // 预计3个月后的质量
    let confidenceLevel: Double
}

// MARK: - 睡眠质量预测

struct ConfidenceInterval: Codable {
    let lower: Double
    let upper: Double
}

struct SleepQualityPrediction: Codable {
    let predictions: [Double] // 未来7天的预测分数
    let confidenceIntervals: [ConfidenceInterval]
    let factorWeights: [String: Double] // 影响因素权重
    let accuracy: Double
    let recommendations: [String]
}

// MARK: - 睡眠模式预测

struct SleepPatternPrediction: Codable {
    let optimalBedtime: Date
    let sleepNeedPrediction: Double // 预测的睡眠需求（小时）
    let potentialIssues: [String]
    let adaptationSuggestions: [String]
}

// MARK: - 健康风险评估

struct HealthRiskAssessment: Codable {
    let overallRiskLevel: RiskLevel
    let identifiedRisks: [HealthRisk]
    let preventionStrategies: [String]
    let monitoringRecommendations: [String]
}

// MARK: - 健康风险

struct HealthRisk: Codable {
    let type: HealthRiskType
    let level: RiskLevel
    let description: String
    let likelihood: Double // 0-100
    let impact: RiskImpact
    let recommendations: [String]
}

// MARK: - 风险类型枚举

enum HealthRiskType: String, Codable {
    case sleepApnea = "sleep_apnea"
    case sleepDeprivation = "sleep_deprivation"
    case qualityDecline = "quality_decline"
    case circadianDisruption = "circadian_disruption"
    
    var displayName: String {
        switch self {
        case .sleepApnea: return "睡眠呼吸暂停风险"
        case .sleepDeprivation: return "睡眠不足风险"
        case .qualityDecline: return "睡眠质量下降风险"
        case .circadianDisruption: return "生物钟紊乱风险"
        }
    }
}

// MARK: - 风险等级枚举

enum RiskLevel: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "低风险"
        case .medium: return "中等风险"
        case .high: return "高风险"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

// MARK: - 风险影响枚举

enum RiskImpact: String, Codable {
    case minimal = "minimal"
    case moderate = "moderate"
    case significant = "significant"
    
    var displayName: String {
        switch self {
        case .minimal: return "轻微影响"
        case .moderate: return "中等影响"
        case .significant: return "显著影响"
        }
    }
}

// MARK: - 改善建议

struct ImprovementSuggestion: Codable {
    let category: ImprovementCategory
    let title: String
    let description: String
    let priority: SuggestionPriority
    let timeframe: SuggestionTimeframe
    let expectedImpact: ExpectedImpact
    let actionSteps: [String]
}

// MARK: - 改善类别枚举

enum ImprovementCategory: String, Codable {
    case immediate = "immediate"
    case routine = "routine"
    case lifestyle = "lifestyle"
    case environment = "environment"
    
    var displayName: String {
        switch self {
        case .immediate: return "立即改善"
        case .routine: return "作息调整"
        case .lifestyle: return "生活方式"
        case .environment: return "环境优化"
        }
    }
}

// MARK: - 建议优先级枚举

enum SuggestionPriority: String, Codable {
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

// MARK: - 建议时间框架枚举

enum SuggestionTimeframe: String, Codable {
    case immediate = "immediate"
    case shortTerm = "short_term"
    case longTerm = "long_term"
    
    var displayName: String {
        switch self {
        case .immediate: return "立即执行"
        case .shortTerm: return "短期内（1-2周）"
        case .longTerm: return "长期坚持（1个月以上）"
        }
    }
}

// MARK: - 预期影响枚举

enum ExpectedImpact: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .high: return "显著改善"
        case .medium: return "中等改善"
        case .low: return "轻微改善"
        }
    }
}

// MARK: - 个性化目标

struct PersonalizedGoal: Codable {
    let title: String
    let description: String
    let targetValue: Double
    let currentValue: Double
    let timeframe: GoalTimeframe
    let category: GoalCategory
    let milestones: [GoalMilestone]
}

// MARK: - 目标时间框架枚举

enum GoalTimeframe: String, Codable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    
    var displayName: String {
        switch self {
        case .week: return "一周内"
        case .month: return "一个月内"
        case .quarter: return "三个月内"
        }
    }
}

// MARK: - 目标类别枚举

enum GoalCategory: String, Codable {
    case quality = "quality"
    case efficiency = "efficiency"
    case duration = "duration"
    case consistency = "consistency"
    
    var displayName: String {
        switch self {
        case .quality: return "睡眠质量"
        case .efficiency: return "睡眠效率"
        case .duration: return "睡眠时长"
        case .consistency: return "作息规律"
        }
    }
}

// MARK: - 目标里程碑

struct GoalMilestone: Codable {
    let title: String
    let targetValue: Double
    let targetDate: Date
    let isCompleted: Bool
}

// MARK: - 缺失的类型定义

struct DeepSeekRecoveryPattern: Codable {
    let patternType: String
    let description: String
    let frequency: Double
    let effectiveness: Double
}

struct DeepSeekEnvironmentalImpact: Codable {
    let factor: String
    let impact: String
    let severity: Double
    let recommendations: [String]
}

struct DeepSeekMilestone: Codable {
    let date: Date
    let achievement: String
    let significance: String
    let metrics: [String: Double]
}

struct DeepSeekSeasonalPattern: Codable {
    let season: String
    let pattern: String
    let impact: Double
    let description: String
}

struct DeepSeekHealthTrend: Codable {
    let metric: String
    let trend: String
    let change: Double
    let timeframe: String
}

struct DeepSeekLifestyleImpact: Codable {
    let factor: String
    let impact: String
    let correlation: Double
    let recommendations: [String]
}

enum DeepSeekTrendDirection: String, Codable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
}

struct DeepSeekImprovementTrajectory: Codable {
    let currentTrend: DeepSeekTrendDirection
    let projectedImprovement: Double
    let timeToGoal: Int
    let confidenceLevel: Double
}
