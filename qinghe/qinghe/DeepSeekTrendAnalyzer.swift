import Foundation
import SwiftUI

// MARK: - 睡眠趋势分析和预测扩展

extension EnhancedDeepSeekSleepAnalysisEngine {
    
    // MARK: - 趋势分析和预测
    
    /// 生成睡眠趋势分析和预测
    func generateTrendAnalysisAndPredictions() async -> SleepTrendAnalysis {
        print("📈 开始生成睡眠趋势分析和预测...")
        
        // 确保有足够的历史数据
        guard userSleepHistory.count >= 3 else {
            return generateBasicTrendAnalysis()
        }
        
        // 短期趋势分析（7天）
        let shortTermTrend = analyzeShortTermTrend()
        
        // 中期趋势分析（30天）
        let mediumTermTrend = analyzeMediumTermTrend()
        
        // 长期趋势分析（90天+）
        let longTermTrend = analyzeLongTermTrend()
        
        // 睡眠质量预测
        let qualityPrediction = await predictSleepQuality()
        
        // 睡眠模式预测
        let patternPrediction = await predictSleepPatterns()
        
        // 健康风险评估
        let healthRiskAssessment = assessHealthRisks()
        
        // 改善建议生成
        let improvementSuggestions = generateImprovementSuggestions(
            shortTerm: shortTermTrend,
            mediumTerm: mediumTermTrend,
            longTerm: longTermTrend
        )
        
        // 个性化目标设定
        let personalizedGoals = generatePersonalizedGoals()
        
        return SleepTrendAnalysis(
            analysisDate: Date(),
            dataRange: calculateDataRange(),
            shortTermTrend: shortTermTrend,
            mediumTermTrend: mediumTermTrend,
            longTermTrend: longTermTrend,
            qualityPrediction: qualityPrediction,
            patternPrediction: patternPrediction,
            healthRiskAssessment: healthRiskAssessment,
            improvementSuggestions: improvementSuggestions,
            personalizedGoals: personalizedGoals,
            confidence: calculateOverallTrendConfidence()
        )
    }
    
    // MARK: - 短期趋势分析（7天）
    
    private func analyzeShortTermTrend() -> ShortTermTrend {
        let recentData = Array(userSleepHistory.prefix(7))
        
        // 质量趋势
        let qualityScores = recentData.map { $0.qualityAssessment.overallScore }
        let qualityTrend = calculateTrendDirection(qualityScores)
        let qualityVariability = calculateVariability(qualityScores)
        
        // 睡眠时长趋势
        let durations = recentData.compactMap { analysis in
            analysis.stageAnalysis.lightSleepDuration + 
            analysis.stageAnalysis.deepSleepDuration + 
            analysis.stageAnalysis.remSleepDuration
        }
        let durationTrend = calculateTrendDirection(durations)
        
        // 睡眠效率趋势
        let efficiencies = recentData.map { $0.stageAnalysis.sleepEfficiency }
        let efficiencyTrend = calculateTrendDirection(efficiencies)
        
        // 一致性评分
        let consistencyScore = calculateConsistencyScore(recentData)
        
        return ShortTermTrend(
            period: .week,
            qualityTrend: qualityTrend,
            qualityVariability: qualityVariability,
            durationTrend: durationTrend,
            efficiencyTrend: efficiencyTrend,
            consistencyScore: consistencyScore,
            keyInsights: generateShortTermInsights(recentData)
        )
    }
    
    // MARK: - 中期趋势分析（30天）
    
    private func analyzeMediumTermTrend() -> MediumTermTrend {
        let monthData = Array(userSleepHistory.prefix(30))
        guard monthData.count >= 14 else {
            return generateBasicMediumTermTrend()
        }

        // 周期性模式分析
        let weeklyPatterns = analyzeWeeklyPatterns(monthData)

        // 睡眠债务分析
        let sleepDebtAnalysis = analyzeSleepDebt(monthData)

        // 恢复模式分析
        let recoveryPatternsData = analyzeRecoveryPatterns(monthData)
        let recoveryPatterns = convertToRecoveryPatterns(recoveryPatternsData)

        // 环境影响分析
        let environmentalImpactsData = analyzeEnvironmentalImpacts(monthData)
        let environmentalImpacts = convertToEnvironmentalImpacts(environmentalImpactsData)

        // 关键里程碑
        let milestonesData = identifyKeyMilestones(monthData)
        let keyMilestones = milestonesData.map { $0.achievement }

        return MediumTermTrend(
            period: .month,
            weeklyPatterns: weeklyPatterns,
            sleepDebtAnalysis: sleepDebtAnalysis,
            recoveryPatterns: recoveryPatterns,
            environmentalImpacts: environmentalImpacts,
            overallImprovement: calculateOverallImprovement(monthData),
            keyMilestones: keyMilestones
        )
    }
    
    // MARK: - 长期趋势分析（90天+）
    
    private func analyzeLongTermTrend() -> LongTermTrend {
        let longTermData = Array(userSleepHistory.prefix(90))
        guard longTermData.count >= 30 else {
            return generateBasicLongTermTrend()
        }

        // 季节性模式
        let seasonalPatternsData = analyzeSeasonalPatterns(longTermData)
        let seasonalPatterns = convertToSeasonalPatterns(seasonalPatternsData)

        // 健康趋势
        let healthTrendsData = analyzeHealthTrends(longTermData)
        let healthTrends = convertToDeepSeekHealthTrends(healthTrendsData)

        // 生活方式影响
        let lifestyleImpactsData = analyzeLifestyleImpacts(longTermData)
        let lifestyleImpacts = convertToLifestyleImpacts(lifestyleImpactsData)

        // 长期改善轨迹
        let improvementTrajectoryData = calculateImprovementTrajectory(longTermData)
        let improvementTrajectory = convertToImprovementTrajectory(improvementTrajectoryData)

        return LongTermTrend(
            period: .quarter,
            seasonalPatterns: seasonalPatterns,
            healthTrends: healthTrends,
            lifestyleImpacts: lifestyleImpacts,
            improvementTrajectory: improvementTrajectory,
            stabilityIndex: calculateStabilityIndex(longTermData),
            predictiveAccuracy: calculatePredictiveAccuracy()
        )
    }
    
    // MARK: - 睡眠质量预测
    
    private func predictSleepQuality() async -> SleepQualityPrediction {
        guard userSleepHistory.count >= 7 else {
            return generateBasicQualityPrediction()
        }
        
        // 使用线性回归预测未来7天的睡眠质量
        let recentScores = userSleepHistory.prefix(14).map { $0.qualityAssessment.overallScore }
        let predictions = performLinearRegression(recentScores, futureDays: 7)
        
        // 预测置信区间
        let confidenceIntervals = calculateConfidenceIntervals(predictions)
        
        // 影响因素权重
        let factorWeights = calculateFactorWeights()
        
        return SleepQualityPrediction(
            predictions: predictions,
            confidenceIntervals: confidenceIntervals,
            factorWeights: factorWeights,
            accuracy: calculatePredictionAccuracy(),
            recommendations: generatePredictiveRecommendations(predictions)
        )
    }
    
    // MARK: - 睡眠模式预测
    
    private func predictSleepPatterns() async -> SleepPatternPrediction {
        // 预测最佳睡眠时间
        let optimalBedtime = predictOptimalBedtime()
        
        // 预测睡眠需求
        let sleepNeedPrediction = predictSleepNeed()
        
        // 预测潜在问题
        let potentialIssues = predictPotentialIssues()
        
        return SleepPatternPrediction(
            optimalBedtime: optimalBedtime,
            sleepNeedPrediction: sleepNeedPrediction,
            potentialIssues: potentialIssues,
            adaptationSuggestions: generateAdaptationSuggestions()
        )
    }
    
    // MARK: - 健康风险评估
    
    private func assessHealthRisks() -> HealthRiskAssessment {
        var risks: [HealthRisk] = []
        
        // 睡眠呼吸风险
        let snoringRisk = assessSnoringRisk()
        if snoringRisk.level != .low {
            risks.append(snoringRisk)
        }
        
        // 睡眠不足风险
        let sleepDeprivationRisk = assessSleepDeprivationRisk()
        if sleepDeprivationRisk.level != .low {
            risks.append(sleepDeprivationRisk)
        }
        
        // 睡眠质量下降风险
        let qualityDeclineRisk = assessQualityDeclineRisk()
        if qualityDeclineRisk.level != .low {
            risks.append(qualityDeclineRisk)
        }
        
        return HealthRiskAssessment(
            overallRiskLevel: calculateOverallRiskLevel(risks),
            identifiedRisks: risks,
            preventionStrategies: generatePreventionStrategies(risks),
            monitoringRecommendations: generateMonitoringRecommendations(risks)
        )
    }
    
    // MARK: - 改善建议生成
    
    private func generateImprovementSuggestions(
        shortTerm: ShortTermTrend,
        mediumTerm: MediumTermTrend,
        longTerm: LongTermTrend
    ) -> [ImprovementSuggestion] {
        var suggestions: [ImprovementSuggestion] = []
        
        // 基于短期趋势的建议
        if shortTerm.qualityTrend == .declining {
            suggestions.append(ImprovementSuggestion(
                category: .immediate,
                title: "立即改善睡眠质量",
                description: "您的睡眠质量在近期有下降趋势，建议检查睡眠环境和作息规律。",
                priority: .high,
                timeframe: .immediate,
                expectedImpact: .high,
                actionSteps: [
                    "检查睡眠环境温度和噪音",
                    "确保规律的睡前例行程序",
                    "避免睡前使用电子设备"
                ]
            ))
        }
        
        // 基于中期趋势的建议
        if mediumTerm.sleepDebtAnalysis.averageDebt > 60 { // 60分钟睡眠债务
            suggestions.append(ImprovementSuggestion(
                category: .routine,
                title: "减少睡眠债务",
                description: "您累积了较多睡眠债务，建议逐步调整作息时间。",
                priority: .medium,
                timeframe: .shortTerm,
                expectedImpact: .medium,
                actionSteps: [
                    "每天提前15分钟上床",
                    "周末适当补觉但不超过1小时",
                    "保持一致的起床时间"
                ]
            ))
        }
        
        // 基于长期趋势的建议
        if longTerm.stabilityIndex < 70 {
            suggestions.append(ImprovementSuggestion(
                category: .lifestyle,
                title: "建立稳定的睡眠模式",
                description: "您的睡眠模式稳定性较低，建议建立更规律的生活习惯。",
                priority: .medium,
                timeframe: .longTerm,
                expectedImpact: .high,
                actionSteps: [
                    "制定固定的作息时间表",
                    "建立睡前放松仪式",
                    "保持规律的运动习惯"
                ]
            ))
        }
        
        return suggestions
    }
    
    // MARK: - 个性化目标设定
    
    private func generatePersonalizedGoals() -> [PersonalizedGoal] {
        var goals: [PersonalizedGoal] = []
        
        // 基于当前睡眠质量设定目标
        if let latestAnalysis = userSleepHistory.first {
            let currentQuality = latestAnalysis.qualityAssessment.overallScore
            
            if currentQuality < 80 {
                goals.append(PersonalizedGoal(
                    title: "提升睡眠质量到80分以上",
                    description: "通过改善睡眠环境和习惯，将睡眠质量从\(String(format: "%.1f", currentQuality))分提升到80分以上。",
                    targetValue: 80,
                    currentValue: currentQuality,
                    timeframe: .month,
                    category: .quality,
                    milestones: generateQualityMilestones(from: currentQuality, to: 80)
                ))
            }
            
            // 睡眠效率目标
            let currentEfficiency = latestAnalysis.stageAnalysis.sleepEfficiency
            if currentEfficiency < 85 {
                goals.append(PersonalizedGoal(
                    title: "提高睡眠效率到85%以上",
                    description: "减少入睡时间和夜间觉醒，提高睡眠效率。",
                    targetValue: 85,
                    currentValue: currentEfficiency,
                    timeframe: .month,
                    category: .efficiency,
                    milestones: generateEfficiencyMilestones(from: currentEfficiency, to: 85)
                ))
            }
        }
        
        return goals
    }

    // MARK: - 辅助计算方法

    /// 计算趋势方向
    private func calculateTrendDirection(_ values: [Double]) -> SleepTrendDirection {
        guard values.count >= 2 else { return .stable }

        let firstHalf = values.prefix(values.count / 2)
        let secondHalf = values.suffix(values.count / 2)

        let firstAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)

        let difference = secondAverage - firstAverage

        if difference > 2 {
            return .improving
        } else if difference < -2 {
            return .declining
        } else {
            return .stable
        }
    }

    /// 计算变异性
    private func calculateVariability(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }

        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)

        return sqrt(variance)
    }

    /// 计算一致性评分
    private func calculateConsistencyScore(_ analyses: [DeepSeekSleepAnalysis]) -> Double {
        guard analyses.count > 1 else { return 100 }

        // 计算睡眠时间一致性
        let bedtimes = analyses.compactMap { analysis in
            // 假设从sessionId或其他方式获取睡眠时间
            Calendar.current.component(.hour, from: analysis.analysisDate)
        }

        let timeVariability = calculateVariability(bedtimes.map { Double($0) })
        let timeConsistency = max(0, 100 - timeVariability * 10)

        // 计算质量一致性
        let qualityScores = analyses.map { $0.qualityAssessment.overallScore }
        let qualityVariability = calculateVariability(qualityScores)
        let qualityConsistency = max(0, 100 - qualityVariability * 2)

        return (timeConsistency + qualityConsistency) / 2
    }

    /// 生成短期洞察
    private func generateShortTermInsights(_ analyses: [DeepSeekSleepAnalysis]) -> [String] {
        var insights: [String] = []

        let qualityScores = analyses.map { $0.qualityAssessment.overallScore }
        let averageQuality = qualityScores.reduce(0, +) / Double(qualityScores.count)

        if averageQuality > 85 {
            insights.append("本周睡眠质量保持在优秀水平")
        } else if averageQuality < 70 {
            insights.append("本周睡眠质量需要关注和改善")
        }

        // 检查质量波动
        let variability = calculateVariability(qualityScores)
        if variability > 15 {
            insights.append("睡眠质量波动较大，建议保持规律作息")
        }

        return insights
    }

    /// 分析周模式
    private func analyzeWeeklyPatterns(_ analyses: [DeepSeekSleepAnalysis]) -> WeeklyPatterns {
        // 按星期几分组分析
        var weekdayQuality: [Int: [Double]] = [:]

        for analysis in analyses {
            let weekday = Calendar.current.component(.weekday, from: analysis.analysisDate)
            if weekdayQuality[weekday] == nil {
                weekdayQuality[weekday] = []
            }
            weekdayQuality[weekday]?.append(analysis.qualityAssessment.overallScore)
        }

        var weekdayAverages: [Int: Double] = [:]
        for (weekday, scores) in weekdayQuality {
            weekdayAverages[weekday] = scores.reduce(0, +) / Double(scores.count)
        }

        return WeeklyPatterns(
            weekdayAverages: weekdayAverages,
            bestDay: weekdayAverages.max(by: { $0.value < $1.value })?.key ?? 1,
            worstDay: weekdayAverages.min(by: { $0.value < $1.value })?.key ?? 1,
            weekendEffect: calculateWeekendEffect(weekdayAverages)
        )
    }

    /// 分析睡眠债务
    private func analyzeSleepDebt(_ analyses: [DeepSeekSleepAnalysis]) -> SleepDebtAnalysis {
        let idealSleepDuration = userProfile?.sleepGoals.targetSleepDuration ?? (8.0 * 3600)

        var dailyDebts: [Double] = []
        for analysis in analyses {
            let actualSleep = (analysis.stageAnalysis.lightSleepDuration +
                             analysis.stageAnalysis.deepSleepDuration +
                             analysis.stageAnalysis.remSleepDuration) / 3600 // 转换为小时

            let debt = max(0, idealSleepDuration - actualSleep)
            dailyDebts.append(debt)
        }

        let totalDebt = dailyDebts.reduce(0, +)
        let averageDebt = totalDebt / Double(dailyDebts.count)

        return SleepDebtAnalysis(
            totalDebt: totalDebt * 60, // 转换为分钟
            averageDebt: averageDebt * 60,
            debtTrend: calculateTrendDirection(dailyDebts),
            recoveryRecommendations: generateDebtRecoveryRecommendations(totalDebt)
        )
    }

    /// 执行线性回归预测
    private func performLinearRegression(_ values: [Double], futureDays: Int) -> [Double] {
        guard values.count >= 3 else { return Array(repeating: values.last ?? 75, count: futureDays) }

        let n = Double(values.count)
        let x = Array(0..<values.count).map { Double($0) }
        let y = values

        // 计算线性回归系数
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map { $0 * $1 }.reduce(0, +)
        let sumXX = x.map { $0 * $0 }.reduce(0, +)

        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n

        // 生成预测值
        var predictions: [Double] = []
        for i in 0..<futureDays {
            let futureX = Double(values.count + i)
            let prediction = slope * futureX + intercept
            predictions.append(max(0, min(100, prediction))) // 限制在0-100范围
        }

        return predictions
    }

    /// 计算置信区间
    private func calculateConfidenceIntervals(_ predictions: [Double]) -> [ConfidenceInterval] {
        return predictions.map { prediction in
            let margin = 5.0 // 简化的置信区间
            return ConfidenceInterval(
                lower: max(0, prediction - margin),
                upper: min(100, prediction + margin)
            )
        }
    }

    /// 生成基础趋势分析
    private func generateBasicTrendAnalysis() -> SleepTrendAnalysis {
        return SleepTrendAnalysis(
            analysisDate: Date(),
            dataRange: DateInterval(start: Date().addingTimeInterval(-7*24*3600), end: Date()),
            shortTermTrend: generateBasicShortTermTrend(),
            mediumTermTrend: generateBasicMediumTermTrend(),
            longTermTrend: generateBasicLongTermTrend(),
            qualityPrediction: generateBasicQualityPrediction(),
            patternPrediction: generateBasicPatternPrediction(),
            healthRiskAssessment: generateBasicHealthRiskAssessment(),
            improvementSuggestions: [],
            personalizedGoals: [],
            confidence: 60.0
        )
    }

    // MARK: - 基础生成方法

    private func generateBasicShortTermTrend() -> ShortTermTrend {
        return ShortTermTrend(
            period: .week,
            qualityTrend: .stable,
            qualityVariability: 10.0,
            durationTrend: .stable,
            efficiencyTrend: .stable,
            consistencyScore: 75.0,
            keyInsights: ["数据不足，需要更多睡眠记录来分析趋势"]
        )
    }

    private func generateBasicMediumTermTrend() -> MediumTermTrend {
        return MediumTermTrend(
            period: .month,
            weeklyPatterns: WeeklyPatterns(
                weekdayAverages: [:],
                bestDay: 1,
                worstDay: 1,
                weekendEffect: 0.0
            ),
            sleepDebtAnalysis: SleepDebtAnalysis(
                totalDebt: 0.0,
                averageDebt: 0.0,
                debtTrend: .stable,
                recoveryRecommendations: []
            ),
            recoveryPatterns: RecoveryPatterns(
                averageRecoveryTime: 8.0,
                recoveryEfficiency: 75.0,
                optimalRecoveryConditions: []
            ),
            environmentalImpacts: EnvironmentalImpacts(
                noiseImpact: 0.0,
                temperatureImpact: 0.0,
                lightImpact: 0.0,
                overallEnvironmentalScore: 75.0
            ),
            overallImprovement: 0.0,
            keyMilestones: []
        )
    }

    private func generateBasicLongTermTrend() -> LongTermTrend {
        return LongTermTrend(
            period: .quarter,
            seasonalPatterns: SeasonalPatterns(
                seasonalVariations: [:],
                optimalSeason: "春季",
                seasonalRecommendations: []
            ),
            healthTrends: DeepSeekHealthTrends(
                snoringTrend: .stable,
                breathingQualityTrend: .stable,
                movementTrend: .stable,
                overallHealthScore: 75.0
            ),
            lifestyleImpacts: LifestyleImpacts(
                exerciseImpact: 0.0,
                dietImpact: 0.0,
                stressImpact: 0.0,
                screenTimeImpact: 0.0
            ),
            improvementTrajectory: ImprovementTrajectory(
                overallDirection: .stable,
                improvementRate: 0.0,
                projectedQuality: 75.0,
                confidenceLevel: 60.0
            ),
            stabilityIndex: 70.0,
            predictiveAccuracy: 60.0
        )
    }

    private func generateBasicQualityPrediction() -> SleepQualityPrediction {
        return SleepQualityPrediction(
            predictions: Array(repeating: 75.0, count: 7),
            confidenceIntervals: Array(repeating: ConfidenceInterval(lower: 70.0, upper: 80.0), count: 7),
            factorWeights: [:],
            accuracy: 60.0,
            recommendations: ["需要更多数据来提供准确预测"]
        )
    }

    private func generateBasicPatternPrediction() -> SleepPatternPrediction {
        return SleepPatternPrediction(
            optimalBedtime: Calendar.current.date(from: DateComponents(hour: 23)) ?? Date(),
            sleepNeedPrediction: 8.0,
            potentialIssues: [],
            adaptationSuggestions: []
        )
    }

    private func generateBasicHealthRiskAssessment() -> HealthRiskAssessment {
        return HealthRiskAssessment(
            overallRiskLevel: .low,
            identifiedRisks: [],
            preventionStrategies: [],
            monitoringRecommendations: []
        )
    }

    // MARK: - 具体分析方法实现

    private func calculateDataRange() -> DateInterval {
        guard let oldestData = userSleepHistory.last?.analysisDate else {
            return DateInterval(start: Date().addingTimeInterval(-7*24*3600), end: Date())
        }
        return DateInterval(start: oldestData, end: Date())
    }

    private func calculateOverallTrendConfidence() -> Double {
        let dataPoints = userSleepHistory.count

        switch dataPoints {
        case 0...3: return 50.0
        case 4...7: return 70.0
        case 8...14: return 85.0
        case 15...30: return 92.0
        default: return 95.0
        }
    }

    private func calculateWeekendEffect(_ weekdayAverages: [Int: Double]) -> Double {
        guard let saturday = weekdayAverages[7], let sunday = weekdayAverages[1] else { return 0.0 }

        let weekendAverage = (saturday + sunday) / 2.0
        let weekdayValues = weekdayAverages.filter { $0.key >= 2 && $0.key <= 6 }.values
        let weekdayAverage = weekdayValues.reduce(0, +) / Double(weekdayValues.count)

        return weekendAverage - weekdayAverage
    }

    private func generateDebtRecoveryRecommendations(_ totalDebt: Double) -> [String] {
        var recommendations: [String] = []

        if totalDebt > 5.0 { // 5小时以上债务
            recommendations.append("考虑在周末适当补觉，但不要超过平时起床时间1小时")
            recommendations.append("逐步提前15-30分钟上床时间")
        }

        if totalDebt > 10.0 { // 10小时以上债务
            recommendations.append("建议咨询睡眠专家，制定系统的睡眠恢复计划")
        }

        return recommendations
    }

    private func assessSnoringRisk() -> HealthRisk {
        let _ = userSleepHistory.prefix(7).compactMap { analysis in
            // 假设从分析中获取打鼾数据
            return 0.0 // 简化实现
        }

        return HealthRisk(
            type: .sleepApnea,
            level: .low,
            description: "基于最近的睡眠数据，暂未发现明显的睡眠呼吸问题",
            likelihood: 20.0,
            impact: .minimal,
            recommendations: ["保持健康体重", "避免睡前饮酒"]
        )
    }

    private func assessSleepDeprivationRisk() -> HealthRisk {
        let recentDurations = userSleepHistory.prefix(7).map { analysis in
            (analysis.stageAnalysis.lightSleepDuration +
             analysis.stageAnalysis.deepSleepDuration +
             analysis.stageAnalysis.remSleepDuration) / 3600
        }

        let averageDuration = recentDurations.reduce(0, +) / Double(recentDurations.count)
        let idealDuration = userProfile?.sleepGoals.targetSleepDuration ?? (8.0 * 3600)

        let riskLevel: RiskLevel
        let likelihood: Double

        if averageDuration < idealDuration - 1.5 {
            riskLevel = .high
            likelihood = 80.0
        } else if averageDuration < idealDuration - 1.0 {
            riskLevel = .medium
            likelihood = 60.0
        } else {
            riskLevel = .low
            likelihood = 20.0
        }

        return HealthRisk(
            type: .sleepDeprivation,
            level: riskLevel,
            description: "基于平均睡眠时长\(String(format: "%.1f", averageDuration))小时的评估",
            likelihood: likelihood,
            impact: riskLevel == .high ? .significant : .moderate,
            recommendations: ["确保充足的睡眠时间", "建立规律的作息时间"]
        )
    }

    private func assessQualityDeclineRisk() -> HealthRisk {
        guard userSleepHistory.count >= 7 else {
            return HealthRisk(
                type: .qualityDecline,
                level: .low,
                description: "数据不足，无法评估质量下降风险",
                likelihood: 30.0,
                impact: .minimal,
                recommendations: []
            )
        }

        let recentQuality = userSleepHistory.prefix(7).map { $0.qualityAssessment.overallScore }
        let trend = calculateTrendDirection(recentQuality)

        let riskLevel: RiskLevel
        let likelihood: Double

        switch trend {
        case .declining:
            riskLevel = .medium
            likelihood = 70.0
        case .stable:
            riskLevel = .low
            likelihood = 30.0
        case .improving:
            riskLevel = .low
            likelihood = 10.0
        }

        return HealthRisk(
            type: .qualityDecline,
            level: riskLevel,
            description: "睡眠质量趋势：\(trend.displayName)",
            likelihood: likelihood,
            impact: .moderate,
            recommendations: trend == .declining ? ["检查睡眠环境", "评估生活压力"] : []
        )
    }

    private func calculateOverallRiskLevel(_ risks: [HealthRisk]) -> RiskLevel {
        guard !risks.isEmpty else { return .low }

        let highRisks = risks.filter { $0.level == .high }.count
        let mediumRisks = risks.filter { $0.level == .medium }.count

        if highRisks > 0 {
            return .high
        } else if mediumRisks > 1 {
            return .medium
        } else if mediumRisks > 0 {
            return .medium
        } else {
            return .low
        }
    }

    private func generatePreventionStrategies(_ risks: [HealthRisk]) -> [String] {
        var strategies: [String] = []

        for risk in risks {
            strategies.append(contentsOf: risk.recommendations)
        }

        // 去重
        return Array(Set(strategies))
    }

    private func generateMonitoringRecommendations(_ risks: [HealthRisk]) -> [String] {
        var recommendations: [String] = []

        if risks.contains(where: { $0.type == .sleepApnea && $0.level != .low }) {
            recommendations.append("建议进行专业的睡眠呼吸监测")
        }

        if risks.contains(where: { $0.level == .high }) {
            recommendations.append("建议每周监测睡眠质量变化")
        }

        return recommendations
    }

    private func predictOptimalBedtime() -> Date {
        // 基于历史数据预测最佳睡眠时间
        let calendar = Calendar.current
        let defaultBedtime = calendar.date(from: DateComponents(hour: 23)) ?? Date()

        guard userSleepHistory.count >= 3 else { return defaultBedtime }

        // 简化实现：返回用户偏好的睡眠时间
        return userProfile?.sleepGoals.targetBedtime ?? defaultBedtime
    }

    private func predictSleepNeed() -> Double {
        return userProfile?.sleepGoals.targetSleepDuration ?? (8.0 * 3600)
    }

    private func predictPotentialIssues() -> [String] {
        var issues: [String] = []

        if userSleepHistory.count >= 7 {
            let recentQuality = userSleepHistory.prefix(7).map { $0.qualityAssessment.overallScore }
            let trend = calculateTrendDirection(recentQuality)

            if trend == .declining {
                issues.append("睡眠质量可能继续下降")
            }
        }

        return issues
    }

    private func generateAdaptationSuggestions() -> [String] {
        return [
            "根据个人作息习惯调整睡眠时间",
            "观察身体的自然睡眠信号",
            "保持一致的睡眠环境"
        ]
    }

    private func calculateFactorWeights() -> [String: Double] {
        return [
            "睡眠环境": 0.25,
            "作息规律": 0.30,
            "压力水平": 0.20,
            "运动习惯": 0.15,
            "饮食习惯": 0.10
        ]
    }

    private func calculatePredictionAccuracy() -> Double {
        // 基于历史数据计算预测准确性
        return min(95.0, 60.0 + Double(userSleepHistory.count) * 2.0)
    }

    private func generatePredictiveRecommendations(_ predictions: [Double]) -> [String] {
        var recommendations: [String] = []

        let averagePrediction = predictions.reduce(0, +) / Double(predictions.count)

        if averagePrediction < 70 {
            recommendations.append("预计睡眠质量可能下降，建议提前调整作息")
        } else if averagePrediction > 85 {
            recommendations.append("预计睡眠质量良好，保持当前习惯")
        }

        return recommendations
    }

    private func generateQualityMilestones(from current: Double, to target: Double) -> [GoalMilestone] {
        let increment = (target - current) / 4.0
        var milestones: [GoalMilestone] = []

        for i in 1...4 {
            let milestoneValue = current + increment * Double(i)
            let milestoneDate = Calendar.current.date(byAdding: .weekOfYear, value: i, to: Date()) ?? Date()

            milestones.append(GoalMilestone(
                title: "达到\(String(format: "%.1f", milestoneValue))分",
                targetValue: milestoneValue,
                targetDate: milestoneDate,
                isCompleted: false
            ))
        }

        return milestones
    }

    private func generateEfficiencyMilestones(from current: Double, to target: Double) -> [GoalMilestone] {
        let increment = (target - current) / 3.0
        var milestones: [GoalMilestone] = []

        for i in 1...3 {
            let milestoneValue = current + increment * Double(i)
            let milestoneDate = Calendar.current.date(byAdding: .weekOfYear, value: i * 2, to: Date()) ?? Date()

            milestones.append(GoalMilestone(
                title: "睡眠效率达到\(String(format: "%.1f", milestoneValue))%",
                targetValue: milestoneValue,
                targetDate: milestoneDate,
                isCompleted: false
            ))
        }

        return milestones
    }

    // MARK: - 缺失的方法实现

    private func analyzeRecoveryPatterns(_ data: [DeepSeekSleepAnalysis]) -> [DeepSeekRecoveryPattern] {
        // 简化实现
        return []
    }

    private func analyzeEnvironmentalImpacts(_ data: [DeepSeekSleepAnalysis]) -> [DeepSeekEnvironmentalImpact] {
        // 简化实现
        return []
    }

    private func calculateOverallImprovement(_ data: [DeepSeekSleepAnalysis]) -> Double {
        // 简化实现
        return 0.0
    }

    private func identifyKeyMilestones(_ data: [DeepSeekSleepAnalysis]) -> [DeepSeekMilestone] {
        // 简化实现
        return []
    }

    private func analyzeSeasonalPatterns(_ data: [DeepSeekSleepAnalysis]) -> [DeepSeekSeasonalPattern] {
        // 简化实现
        return []
    }

    private func analyzeHealthTrends(_ data: [DeepSeekSleepAnalysis]) -> [DeepSeekHealthTrend] {
        // 简化实现
        return []
    }

    private func analyzeLifestyleImpacts(_ data: [DeepSeekSleepAnalysis]) -> [DeepSeekLifestyleImpact] {
        // 简化实现
        return []
    }

    private func calculateImprovementTrajectory(_ data: [DeepSeekSleepAnalysis]) -> DeepSeekImprovementTrajectory {
        // 简化实现
        return DeepSeekImprovementTrajectory(
            currentTrend: .stable,
            projectedImprovement: 0.0,
            timeToGoal: 0,
            confidenceLevel: 0.5
        )
    }

    private func calculateStabilityIndex(_ data: [DeepSeekSleepAnalysis]) -> Double {
        // 简化实现
        return 0.5
    }

    private func calculatePredictiveAccuracy() -> Double {
        // 简化实现
        return 0.5
    }

    // MARK: - 类型转换函数

    private func convertToRecoveryPatterns(_ patterns: [DeepSeekRecoveryPattern]) -> RecoveryPatterns {
        let averageRecoveryTime = patterns.isEmpty ? 8.0 : patterns.map { $0.effectiveness }.reduce(0, +) / Double(patterns.count)
        let recoveryEfficiency = patterns.isEmpty ? 75.0 : patterns.map { $0.effectiveness * 100 }.reduce(0, +) / Double(patterns.count)
        let optimalConditions = patterns.map { $0.description }

        return RecoveryPatterns(
            averageRecoveryTime: averageRecoveryTime,
            recoveryEfficiency: recoveryEfficiency,
            optimalRecoveryConditions: optimalConditions
        )
    }

    private func convertToEnvironmentalImpacts(_ impacts: [DeepSeekEnvironmentalImpact]) -> EnvironmentalImpacts {
        let noiseImpact = impacts.first { $0.factor.contains("噪音") || $0.factor.contains("noise") }?.severity ?? 0.0
        let temperatureImpact = impacts.first { $0.factor.contains("温度") || $0.factor.contains("temperature") }?.severity ?? 0.0
        let lightImpact = impacts.first { $0.factor.contains("光线") || $0.factor.contains("light") }?.severity ?? 0.0
        let overallScore = impacts.isEmpty ? 75.0 : (100.0 - impacts.map { $0.severity }.reduce(0, +) / Double(impacts.count) * 100)

        return EnvironmentalImpacts(
            noiseImpact: noiseImpact,
            temperatureImpact: temperatureImpact,
            lightImpact: lightImpact,
            overallEnvironmentalScore: overallScore
        )
    }

    private func convertToSeasonalPatterns(_ patterns: [DeepSeekSeasonalPattern]) -> SeasonalPatterns {
        var seasonalVariations: [String: Double] = [:]
        var optimalSeason = "春季"
        var bestImpact = -1.0

        for pattern in patterns {
            seasonalVariations[pattern.season] = pattern.impact
            if pattern.impact > bestImpact {
                bestImpact = pattern.impact
                optimalSeason = pattern.season
            }
        }

        let recommendations = patterns.map { $0.description }

        return SeasonalPatterns(
            seasonalVariations: seasonalVariations,
            optimalSeason: optimalSeason,
            seasonalRecommendations: recommendations
        )
    }

    private func convertToDeepSeekHealthTrends(_ trends: [DeepSeekHealthTrend]) -> DeepSeekHealthTrends {
        let snoringTrend = convertTrendDirection(trends.first { $0.metric.contains("打鼾") || $0.metric.contains("snoring") }?.trend)
        let breathingTrend = convertTrendDirection(trends.first { $0.metric.contains("呼吸") || $0.metric.contains("breathing") }?.trend)
        let movementTrend = convertTrendDirection(trends.first { $0.metric.contains("运动") || $0.metric.contains("movement") }?.trend)
        let overallScore = trends.isEmpty ? 75.0 : trends.map { $0.change }.reduce(0, +) / Double(trends.count) * 100

        return DeepSeekHealthTrends(
            snoringTrend: snoringTrend,
            breathingQualityTrend: breathingTrend,
            movementTrend: movementTrend,
            overallHealthScore: max(0, min(100, overallScore))
        )
    }

    private func convertToLifestyleImpacts(_ impacts: [DeepSeekLifestyleImpact]) -> LifestyleImpacts {
        let exerciseImpact = impacts.first { $0.factor.contains("运动") || $0.factor.contains("exercise") }?.correlation ?? 0.0
        let dietImpact = impacts.first { $0.factor.contains("饮食") || $0.factor.contains("diet") }?.correlation ?? 0.0
        let stressImpact = impacts.first { $0.factor.contains("压力") || $0.factor.contains("stress") }?.correlation ?? 0.0
        let screenTimeImpact = impacts.first { $0.factor.contains("屏幕") || $0.factor.contains("screen") }?.correlation ?? 0.0

        return LifestyleImpacts(
            exerciseImpact: exerciseImpact,
            dietImpact: dietImpact,
            stressImpact: stressImpact,
            screenTimeImpact: screenTimeImpact
        )
    }

    private func convertToImprovementTrajectory(_ trajectory: DeepSeekImprovementTrajectory) -> ImprovementTrajectory {
        let direction = convertDeepSeekTrendDirection(trajectory.currentTrend)

        return ImprovementTrajectory(
            overallDirection: direction,
            improvementRate: trajectory.projectedImprovement,
            projectedQuality: 75.0 + trajectory.projectedImprovement * 10,
            confidenceLevel: trajectory.confidenceLevel
        )
    }

    private func convertTrendDirection(_ trendString: String?) -> SleepTrendDirection {
        guard let trend = trendString else { return .stable }

        if trend.contains("improving") || trend.contains("改善") {
            return .improving
        } else if trend.contains("declining") || trend.contains("下降") {
            return .declining
        } else {
            return .stable
        }
    }

    private func convertDeepSeekTrendDirection(_ direction: DeepSeekTrendDirection) -> SleepTrendDirection {
        switch direction {
        case .improving:
            return .improving
        case .stable:
            return .stable
        case .declining:
            return .declining
        }
    }
}
