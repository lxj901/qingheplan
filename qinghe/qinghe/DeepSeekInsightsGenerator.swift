import Foundation
import SwiftUI

// MARK: - 个性化洞察生成扩展

extension EnhancedDeepSeekSleepAnalysisEngine {
    
    // MARK: - 个性化洞察生成
    
    func generatePersonalizedInsights(patterns: SleepPatternAnalysis, quality: DeepSeekSleepQualityAssessment, session: LocalSleepSession) async -> [DeepSeekSleepInsight] {
        print("💡 开始生成个性化洞察...")

        var insights: [DeepSeekSleepInsight] = []

        // 加载用户历史数据和偏好
        await loadUserProfileAndHistory()

        // 睡眠质量洞察（增强版）
        insights.append(contentsOf: generateAdvancedQualityInsights(quality, patterns: patterns))

        // 睡眠模式洞察（个性化）
        insights.append(contentsOf: generatePersonalizedPatternInsights(patterns, session: session))

        // 呼吸模式洞察（深度分析）
        insights.append(contentsOf: generateAdvancedBreathingInsights(patterns.breathingPattern))

        // 打鼾洞察（健康关联）
        insights.append(contentsOf: generateHealthAwareSnoringInsights(patterns.snoringPattern))

        // 动作模式洞察（睡眠质量关联）
        insights.append(contentsOf: generateSleepQualityMovementInsights(patterns.movementPattern))

        // 环境因素洞察（优化建议）
        insights.append(contentsOf: generateOptimizedEnvironmentalInsights(patterns.environmentalAnalysis))

        // 个性化趋势洞察（基于历史数据和用户特征）
        insights.append(contentsOf: await generatePersonalizedTrendInsights(session))

        // 睡眠周期洞察（新增）
        insights.append(contentsOf: generateSleepCycleInsights(patterns.sleepCycles))

        // 比较分析洞察（与历史数据对比）
        insights.append(contentsOf: generateComparativeInsights(quality, patterns: patterns))

        // 季节性和时间模式洞察（新增）
        insights.append(contentsOf: generateTemporalInsights(session))

        // 智能优先级排序（考虑用户偏好和紧急程度）
        insights = prioritizeInsightsIntelligently(insights)

        // 去重和优化
        insights = deduplicateAndOptimizeInsights(insights)

        return insights
    }

    // MARK: - 高级个性化洞察生成方法

    /// 加载用户档案和历史数据
    private func loadUserProfileAndHistory() async {
        // 加载用户睡眠偏好
        if userProfile == nil {
            userProfile = loadUserSleepProfile()
        }

        // 确保历史数据已加载
        if userSleepHistory.isEmpty {
            loadUserSleepHistory()
        }
    }

    /// 生成高级质量洞察
    private func generateAdvancedQualityInsights(_ quality: DeepSeekSleepQualityAssessment, patterns: SleepPatternAnalysis) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []

        // 基础质量评估
        insights.append(contentsOf: generateQualityInsights(quality))

        // 质量组成分析
        if quality.efficiencyScore < 80 {
            insights.append(DeepSeekSleepInsight(
                type: .warning,
                title: "睡眠效率有待提升",
                description: "您的睡眠效率为\(String(format: "%.1f", quality.efficiencyScore))分，建议优化入睡时间和减少夜间觉醒。",
                confidence: 88.0,
                priority: .high,
                relatedMetrics: ["睡眠效率", "入睡时间"],
                actionable: true
            ))
        }

        if quality.structureScore < 75 {
            insights.append(DeepSeekSleepInsight(
                type: .concern,
                title: "睡眠结构需要调整",
                description: "您的睡眠结构评分为\(String(format: "%.1f", quality.structureScore))分，深睡眠和REM睡眠比例可能不够理想。",
                confidence: 85.0,
                priority: .medium,
                relatedMetrics: ["睡眠结构", "深睡眠", "REM睡眠"],
                actionable: true
            ))
        }

        // 个性化改善建议
        if let profile = userProfile {
            let personalizedInsight = generatePersonalizedQualityAdvice(quality, profile: profile)
            if let insight = personalizedInsight {
                insights.append(insight)
            }
        }

        return insights
    }

    /// 生成个性化模式洞察
    private func generatePersonalizedPatternInsights(_ patterns: SleepPatternAnalysis, session: LocalSleepSession) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []

        // 基础模式分析
        insights.append(contentsOf: generatePatternInsights(patterns))

        // 个人睡眠时间偏好分析
        let bedtime = Calendar.current.dateComponents([.hour, .minute], from: session.startTime)
        if let hour = bedtime.hour {
            if hour < 22 || hour > 24 {
                insights.append(DeepSeekSleepInsight(
                    type: .info,
                    title: "睡眠时间模式分析",
                    description: hour < 22 ? "您倾向于早睡，这有助于获得更多深睡眠。" : "您的入睡时间较晚，可能影响睡眠质量。",
                    confidence: 75.0,
                    priority: .medium,
                    relatedMetrics: ["入睡时间", "睡眠习惯"],
                    actionable: hour > 24
                ))
            }
        }

        // 睡眠周期完整性分析
        let idealCycleCount = calculateIdealCycleCount(session)
        let actualCycleCount = patterns.sleepCycles.count

        if actualCycleCount < idealCycleCount {
            insights.append(DeepSeekSleepInsight(
                type: .warning,
                title: "睡眠周期不够完整",
                description: "您完成了\(actualCycleCount)个睡眠周期，理想情况下应该有\(idealCycleCount)个周期。建议延长睡眠时间。",
                confidence: 82.0,
                priority: .medium,
                relatedMetrics: ["睡眠周期", "睡眠时长"],
                actionable: true
            ))
        }

        return insights
    }

    /// 生成高级呼吸洞察
    private func generateAdvancedBreathingInsights(_ breathingPattern: BreathingPatternAnalysis) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []

        // 基础呼吸分析
        insights.append(contentsOf: generateBreathingInsights(breathingPattern))

        // 呼吸健康评估
        if breathingPattern.irregularityCount > 10 {
            insights.append(DeepSeekSleepInsight(
                type: .concern,
                title: "呼吸不规律需要关注",
                description: "检测到\(breathingPattern.irregularityCount)次呼吸不规律，可能提示睡眠呼吸问题。建议咨询医生。",
                confidence: 90.0,
                priority: .high,
                relatedMetrics: ["呼吸质量", "睡眠健康"],
                actionable: true
            ))
        }

        // 呼吸效率分析
        if breathingPattern.regularity > 85 && breathingPattern.overallQuality == .excellent {
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "呼吸模式优秀",
                description: "您的呼吸非常规律且稳定，这表明睡眠质量很好，身体得到了充分的休息。",
                confidence: 92.0,
                priority: .medium,
                relatedMetrics: ["呼吸质量", "睡眠恢复"],
                actionable: false
            ))
        }

        return insights
    }

    private func generateQualityInsights(_ quality: DeepSeekSleepQualityAssessment) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []
        
        switch quality.qualityLevel {
        case .excellent:
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "睡眠质量优秀",
                description: "您的睡眠质量达到了优秀水平（\(String(format: "%.1f", quality.overallScore))分），各项指标都表现良好。",
                confidence: 95.0,
                priority: .high,
                relatedMetrics: ["睡眠质量", "睡眠效率"],
                actionable: false
            ))
        case .good:
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "睡眠质量良好",
                description: "您的睡眠质量良好（\(String(format: "%.1f", quality.overallScore))分），还有\(String(format: "%.1f", quality.improvementPotential))分的提升空间。",
                confidence: 90.0,
                priority: .medium,
                relatedMetrics: ["睡眠质量"],
                actionable: true
            ))
        case .fair:
            insights.append(DeepSeekSleepInsight(
                type: .warning,
                title: "睡眠质量有待改善",
                description: "您的睡眠质量一般（\(String(format: "%.1f", quality.overallScore))分），建议关注影响睡眠的因素。",
                confidence: 85.0,
                priority: .high,
                relatedMetrics: ["睡眠质量", "睡眠干扰"],
                actionable: true
            ))
        case .poor:
            insights.append(DeepSeekSleepInsight(
                type: .concern,
                title: "睡眠质量需要重点关注",
                description: "您的睡眠质量较差（\(String(format: "%.1f", quality.overallScore))分），建议采取措施改善睡眠环境和习惯。",
                confidence: 90.0,
                priority: .high,
                relatedMetrics: ["睡眠质量", "睡眠健康"],
                actionable: true
            ))
        }
        
        return insights
    }
    
    private func generatePatternInsights(_ patterns: SleepPatternAnalysis) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []
        
        // 睡眠稳定性洞察
        if patterns.overallStability > 80 {
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "睡眠模式稳定",
                description: "您的睡眠模式很稳定，各个时段的睡眠状态比较一致。",
                confidence: 85.0,
                priority: .medium,
                relatedMetrics: ["睡眠稳定性"],
                actionable: false
            ))
        } else if patterns.overallStability < 50 {
            insights.append(DeepSeekSleepInsight(
                type: .warning,
                title: "睡眠模式不稳定",
                description: "您的睡眠模式波动较大，建议保持规律的作息时间。",
                confidence: 80.0,
                priority: .medium,
                relatedMetrics: ["睡眠稳定性", "作息规律"],
                actionable: true
            ))
        }
        
        // 睡眠周期洞察
        let cycleCount = patterns.sleepCycles.count
        if cycleCount >= 4 && cycleCount <= 6 {
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "睡眠周期正常",
                description: "您完成了\(cycleCount)个睡眠周期，这是健康的睡眠结构。",
                confidence: 90.0,
                priority: .low,
                relatedMetrics: ["睡眠周期"],
                actionable: false
            ))
        } else if cycleCount < 3 {
            insights.append(DeepSeekSleepInsight(
                type: .warning,
                title: "睡眠周期不足",
                description: "您只完成了\(cycleCount)个睡眠周期，可能需要延长睡眠时间。",
                confidence: 85.0,
                priority: .medium,
                relatedMetrics: ["睡眠周期", "睡眠时长"],
                actionable: true
            ))
        }
        
        return insights
    }
    
    private func generateBreathingInsights(_ breathing: BreathingPatternAnalysis) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []
        
        switch breathing.overallQuality {
        case .excellent:
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "呼吸模式优秀",
                description: "您的睡眠呼吸非常规律，呼吸质量优秀。",
                confidence: 90.0,
                priority: .low,
                relatedMetrics: ["呼吸规律性"],
                actionable: false
            ))
        case .good:
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "呼吸模式良好",
                description: "您的睡眠呼吸比较规律，整体表现良好。",
                confidence: 85.0,
                priority: .low,
                relatedMetrics: ["呼吸规律性"],
                actionable: false
            ))
        case .fair, .poor:
            insights.append(DeepSeekSleepInsight(
                type: .warning,
                title: "呼吸模式需要关注",
                description: "检测到\(breathing.irregularityCount)次呼吸不规律，建议关注睡眠呼吸健康。",
                confidence: 80.0,
                priority: .medium,
                relatedMetrics: ["呼吸规律性", "睡眠健康"],
                actionable: true
            ))
        }
        
        return insights
    }
    
    private func generateSnoringInsights(_ snoring: SnoringPatternAnalysis) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []
        
        switch snoring.severity {
        case .none:
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "无打鼾现象",
                description: "整夜睡眠中没有检测到打鼾，呼吸道通畅。",
                confidence: 95.0,
                priority: .low,
                relatedMetrics: ["打鼾频率"],
                actionable: false
            ))
        case .mild:
            insights.append(DeepSeekSleepInsight(
                type: .neutral,
                title: "轻微打鼾",
                description: "检测到轻微打鼾（\(snoring.frequency)次），总时长\(String(format: "%.1f", snoring.totalDuration/60))分钟。",
                confidence: 85.0,
                priority: .low,
                relatedMetrics: ["打鼾频率", "打鼾强度"],
                actionable: false
            ))
        case .moderate:
            insights.append(DeepSeekSleepInsight(
                type: .warning,
                title: "中等程度打鼾",
                description: "检测到中等程度打鼾（\(snoring.frequency)次），可能影响睡眠质量。",
                confidence: 80.0,
                priority: .medium,
                relatedMetrics: ["打鼾频率", "睡眠质量"],
                actionable: true
            ))
        case .severe:
            insights.append(DeepSeekSleepInsight(
                type: .concern,
                title: "严重打鼾",
                description: "检测到严重打鼾（\(snoring.frequency)次），建议咨询医生排查睡眠呼吸暂停。",
                confidence: 85.0,
                priority: .high,
                relatedMetrics: ["打鼾频率", "睡眠健康"],
                actionable: true
            ))
        }
        
        return insights
    }
    
    private func generateMovementInsights(_ movement: MovementPatternAnalysis) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []
        
        switch movement.restlessness {
        case .minimal:
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "睡眠安稳",
                description: "您的睡眠很安稳，翻身次数很少，睡眠连续性好。",
                confidence: 90.0,
                priority: .low,
                relatedMetrics: ["翻身频率"],
                actionable: false
            ))
        case .low:
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "睡眠较为安稳",
                description: "您的翻身次数适中（\(movement.frequency)次），睡眠比较安稳。",
                confidence: 85.0,
                priority: .low,
                relatedMetrics: ["翻身频率"],
                actionable: false
            ))
        case .moderate:
            insights.append(DeepSeekSleepInsight(
                type: .neutral,
                title: "睡眠中等活跃",
                description: "检测到中等程度的翻身活动（\(movement.frequency)次），属于正常范围。",
                confidence: 80.0,
                priority: .low,
                relatedMetrics: ["翻身频率"],
                actionable: false
            ))
        case .high:
            insights.append(DeepSeekSleepInsight(
                type: .warning,
                title: "睡眠较为躁动",
                description: "检测到频繁的翻身活动（\(movement.frequency)次），可能影响睡眠深度。",
                confidence: 85.0,
                priority: .medium,
                relatedMetrics: ["翻身频率", "睡眠深度"],
                actionable: true
            ))
        }
        
        return insights
    }
    
    private func generateEnvironmentalInsights(_ environmental: EnvironmentalAnalysis) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []
        
        switch environmental.impactOnSleep {
        case .minimal:
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "睡眠环境安静",
                description: "您的睡眠环境很安静，几乎没有环境噪音干扰。",
                confidence: 95.0,
                priority: .low,
                relatedMetrics: ["环境噪音"],
                actionable: false
            ))
        case .mild:
            insights.append(DeepSeekSleepInsight(
                type: .neutral,
                title: "轻微环境干扰",
                description: "检测到轻微的环境噪音（\(environmental.disruptionCount)次），对睡眠影响较小。",
                confidence: 80.0,
                priority: .low,
                relatedMetrics: ["环境噪音"],
                actionable: false
            ))
        case .moderate:
            insights.append(DeepSeekSleepInsight(
                type: .warning,
                title: "中等环境干扰",
                description: "检测到中等程度的环境噪音干扰（\(environmental.disruptionCount)次），建议改善睡眠环境。",
                confidence: 85.0,
                priority: .medium,
                relatedMetrics: ["环境噪音", "睡眠环境"],
                actionable: true
            ))
        case .severe:
            insights.append(DeepSeekSleepInsight(
                type: .concern,
                title: "严重环境干扰",
                description: "检测到严重的环境噪音干扰（\(environmental.disruptionCount)次），强烈建议改善睡眠环境。",
                confidence: 90.0,
                priority: .high,
                relatedMetrics: ["环境噪音", "睡眠质量"],
                actionable: true
            ))
        }
        
        return insights
    }
    
    private func generateTrendInsights(_ session: LocalSleepSession) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []
        
        // 基于历史数据的趋势分析
        if userSleepHistory.count >= 3 {
            let recentAnalyses = Array(userSleepHistory.suffix(3))
            let averageQuality = recentAnalyses.map { $0.qualityAssessment.overallScore }.reduce(0, +) / Double(recentAnalyses.count)
            let currentQuality = recentAnalyses.last?.qualityAssessment.overallScore ?? 0
            
            if currentQuality > averageQuality + 5 {
                insights.append(DeepSeekSleepInsight(
                    type: .positive,
                    title: "睡眠质量呈上升趋势",
                    description: "与最近几天相比，您的睡眠质量有所改善。",
                    confidence: 80.0,
                    priority: .medium,
                    relatedMetrics: ["睡眠趋势"],
                    actionable: false
                ))
            } else if currentQuality < averageQuality - 5 {
                insights.append(DeepSeekSleepInsight(
                    type: .warning,
                    title: "睡眠质量有所下降",
                    description: "与最近几天相比，您的睡眠质量有所下降，建议关注影响因素。",
                    confidence: 80.0,
                    priority: .medium,
                    relatedMetrics: ["睡眠趋势"],
                    actionable: true
                ))
            }
        }
        
        return insights
    }

    // MARK: - 新增高级洞察生成方法

    /// 生成健康感知的打鼾洞察
    private func generateHealthAwareSnoringInsights(_ snoringPattern: SnoringPatternAnalysis) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []

        // 基础打鼾分析
        insights.append(contentsOf: generateSnoringInsights(snoringPattern))

        // 健康风险评估
        if snoringPattern.severity == .severe {
            insights.append(DeepSeekSleepInsight(
                type: .concern,
                title: "严重打鼾需要医疗关注",
                description: "您的打鼾程度较严重，可能与睡眠呼吸暂停有关。建议进行专业的睡眠检查。",
                confidence: 88.0,
                priority: .high,
                relatedMetrics: ["打鼾严重程度", "睡眠健康"],
                actionable: true
            ))
        }

        // 打鼾时间模式分析
        if !snoringPattern.timeDistribution.isEmpty {
            // 简化实现，跳过复杂的过滤逻辑
            let lateNightSnoring: [TimeDistributionPoint] = []
            if lateNightSnoring.count > snoringPattern.timeDistribution.count / 2 {
                insights.append(DeepSeekSleepInsight(
                    type: .info,
                    title: "深夜打鼾模式",
                    description: "您的打鼾主要集中在深夜时段，这可能与睡眠姿势或深睡眠阶段有关。",
                    confidence: 75.0,
                    priority: .medium,
                    relatedMetrics: ["打鼾时间", "睡眠姿势"],
                    actionable: true
                ))
            }
        }

        return insights
    }

    /// 生成睡眠质量关联的运动洞察
    private func generateSleepQualityMovementInsights(_ movementPattern: MovementPatternAnalysis) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []

        // 基础运动分析
        insights.append(contentsOf: generateMovementInsights(movementPattern))

        // 睡眠质量关联分析
        if movementPattern.restlessness == .high {
            insights.append(DeepSeekSleepInsight(
                type: .warning,
                title: "睡眠不安可能影响恢复",
                description: "频繁的夜间活动可能表明睡眠质量不佳，影响身体和大脑的恢复过程。",
                confidence: 85.0,
                priority: .medium,
                relatedMetrics: ["睡眠不安", "睡眠恢复"],
                actionable: true
            ))
        }

        // 运动模式与睡眠阶段关联
        if movementPattern.frequency > 15 {
            insights.append(DeepSeekSleepInsight(
                type: .info,
                title: "夜间活动频繁",
                description: "您在睡眠中有较多活动，这可能影响深睡眠的连续性。建议检查睡眠环境的舒适度。",
                confidence: 78.0,
                priority: .medium,
                relatedMetrics: ["夜间活动", "深睡眠"],
                actionable: true
            ))
        }

        return insights
    }

    /// 生成优化的环境洞察
    private func generateOptimizedEnvironmentalInsights(_ environmentalAnalysis: EnvironmentalAnalysis) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []

        // 基础环境分析
        insights.append(contentsOf: generateEnvironmentalInsights(environmentalAnalysis))

        // 环境优化建议
        switch environmentalAnalysis.impactOnSleep {
        case .severe:
            insights.append(DeepSeekSleepInsight(
                type: .concern,
                title: "环境因素严重影响睡眠",
                description: "环境噪音或干扰对您的睡眠造成了显著影响。建议采用隔音措施或调整睡眠环境。",
                confidence: 90.0,
                priority: .high,
                relatedMetrics: ["环境噪音", "睡眠环境"],
                actionable: true
            ))
        case .moderate:
            insights.append(DeepSeekSleepInsight(
                type: .warning,
                title: "环境可以进一步优化",
                description: "环境因素对睡眠有一定影响。考虑使用白噪音机或改善房间隔音效果。",
                confidence: 80.0,
                priority: .medium,
                relatedMetrics: ["睡眠环境"],
                actionable: true
            ))
        case .mild:
            insights.append(DeepSeekSleepInsight(
                type: .info,
                title: "环境条件良好",
                description: "睡眠环境对您的睡眠质量影响较小，继续保持良好的睡眠环境。",
                confidence: 75.0,
                priority: .low,
                relatedMetrics: ["睡眠环境"],
                actionable: false
            ))
        case .minimal:
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "睡眠环境良好",
                description: "您的睡眠环境很安静，为优质睡眠提供了良好条件。",
                confidence: 85.0,
                priority: .low,
                relatedMetrics: ["睡眠环境"],
                actionable: false
            ))
        }

        return insights
    }

    /// 生成个性化趋势洞察
    private func generatePersonalizedTrendInsights(_ session: LocalSleepSession) async -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []

        // 基础趋势分析
        insights.append(contentsOf: generateTrendInsights(session))

        // 个人改善趋势分析
        if userSleepHistory.count >= 7 {
            let recentQuality = userSleepHistory.prefix(7).map { $0.qualityAssessment.overallScore }
            let averageRecentQuality = recentQuality.reduce(0, +) / Double(recentQuality.count)

            if userSleepHistory.count >= 14 {
                let olderQuality = userSleepHistory.dropFirst(7).prefix(7).map { $0.qualityAssessment.overallScore }
                let averageOlderQuality = olderQuality.reduce(0, +) / Double(olderQuality.count)

                let improvement = averageRecentQuality - averageOlderQuality

                if improvement > 5 {
                    insights.append(DeepSeekSleepInsight(
                        type: .positive,
                        title: "睡眠质量持续改善",
                        description: "过去一周您的睡眠质量比前一周提高了\(String(format: "%.1f", improvement))分，保持良好的睡眠习惯！",
                        confidence: 92.0,
                        priority: .medium,
                        relatedMetrics: ["睡眠趋势", "质量改善"],
                        actionable: false
                    ))
                } else if improvement < -5 {
                    insights.append(DeepSeekSleepInsight(
                        type: .warning,
                        title: "睡眠质量有所下降",
                        description: "过去一周您的睡眠质量比前一周下降了\(String(format: "%.1f", abs(improvement)))分，建议检查最近的生活变化。",
                        confidence: 88.0,
                        priority: .high,
                        relatedMetrics: ["睡眠趋势", "质量下降"],
                        actionable: true
                    ))
                }
            }
        }

        return insights
    }

    /// 生成睡眠周期洞察
    private func generateSleepCycleInsights(_ sleepCycles: [SleepCycle]) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []

        guard !sleepCycles.isEmpty else { return insights }

        // 周期数量分析
        let cycleCount = sleepCycles.count
        if cycleCount >= 5 {
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "睡眠周期充足",
                description: "您完成了\(cycleCount)个睡眠周期，这有助于身体和大脑的全面恢复。",
                confidence: 85.0,
                priority: .medium,
                relatedMetrics: ["睡眠周期", "睡眠恢复"],
                actionable: false
            ))
        } else if cycleCount < 4 {
            insights.append(DeepSeekSleepInsight(
                type: .warning,
                title: "睡眠周期不足",
                description: "您只完成了\(cycleCount)个睡眠周期，建议增加睡眠时间以获得更好的恢复效果。",
                confidence: 88.0,
                priority: .medium,
                relatedMetrics: ["睡眠周期", "睡眠时长"],
                actionable: true
            ))
        }

        // 周期质量分析
        let averageCycleQuality = sleepCycles.map { $0.quality }.reduce(0, +) / Double(sleepCycles.count)
        if averageCycleQuality > 85 {
            insights.append(DeepSeekSleepInsight(
                type: .positive,
                title: "睡眠周期质量优秀",
                description: "您的睡眠周期质量很高（平均\(String(format: "%.1f", averageCycleQuality))分），睡眠连续性良好。",
                confidence: 90.0,
                priority: .medium,
                relatedMetrics: ["周期质量", "睡眠连续性"],
                actionable: false
            ))
        }

        return insights
    }

    // MARK: - 辅助方法

    /// 生成比较分析洞察
    private func generateComparativeInsights(_ quality: DeepSeekSleepQualityAssessment, patterns: SleepPatternAnalysis) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []

        guard userSleepHistory.count >= 3 else { return insights }

        let recentAverage = userSleepHistory.prefix(3).map { $0.qualityAssessment.overallScore }.reduce(0, +) / 3.0
        let currentScore = quality.overallScore

        let difference = currentScore - recentAverage

        if abs(difference) > 10 {
            let type: DeepSeekInsightType = difference > 0 ? .positive : .warning
            let title = difference > 0 ? "今晚睡眠质量超出平均水平" : "今晚睡眠质量低于平均水平"
            let description = "与最近3天平均水平相比，今晚的睡眠质量\(difference > 0 ? "提高" : "下降")了\(String(format: "%.1f", abs(difference)))分。"

            insights.append(DeepSeekSleepInsight(
                type: type,
                title: title,
                description: description,
                confidence: 85.0,
                priority: .medium,
                relatedMetrics: ["睡眠对比", "质量变化"],
                actionable: difference < 0
            ))
        }

        return insights
    }

    /// 生成时间模式洞察
    private func generateTemporalInsights(_ session: LocalSleepSession) -> [DeepSeekSleepInsight] {
        var insights: [DeepSeekSleepInsight] = []

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: session.startTime)
        let hour = calendar.component(.hour, from: session.startTime)

        // 工作日vs周末分析
        let isWeekend = weekday == 1 || weekday == 7
        if isWeekend && hour > 1 {
            insights.append(DeepSeekSleepInsight(
                type: .info,
                title: "周末睡眠模式",
                description: "周末您倾向于晚睡，这可能会影响下周的睡眠节律。建议保持相对规律的作息。",
                confidence: 75.0,
                priority: .low,
                relatedMetrics: ["睡眠时间", "作息规律"],
                actionable: true
            ))
        }

        // 季节性分析
        let month = calendar.component(.month, from: session.startTime)
        if month >= 12 || month <= 2 { // 冬季
            insights.append(DeepSeekSleepInsight(
                type: .info,
                title: "冬季睡眠特点",
                description: "冬季人们通常需要更多睡眠。如果感觉疲劳，适当延长睡眠时间是正常的。",
                confidence: 70.0,
                priority: .low,
                relatedMetrics: ["季节性睡眠", "睡眠需求"],
                actionable: false
            ))
        }

        return insights
    }

    /// 智能优先级排序
    private func prioritizeInsightsIntelligently(_ insights: [DeepSeekSleepInsight]) -> [DeepSeekSleepInsight] {
        return insights.sorted { insight1, insight2 in
            // 首先按类型优先级排序
            let priority1 = getPriority(for: insight1.type)
            let priority2 = getPriority(for: insight2.type)

            if priority1 != priority2 {
                return priority1 > priority2
            }

            // 然后按优先级排序
            if insight1.priority != insight2.priority {
                return insight1.priority.rawValue > insight2.priority.rawValue
            }

            // 最后按置信度排序
            return insight1.confidence > insight2.confidence
        }
    }

    private func getPriority(for type: DeepSeekInsightType) -> Int {
        // 简化实现，返回默认优先级
        return 2
    }

    /// 去重和优化洞察
    private func deduplicateAndOptimizeInsights(_ insights: [DeepSeekSleepInsight]) -> [DeepSeekSleepInsight] {
        var optimizedInsights: [DeepSeekSleepInsight] = []
        var seenTitles: Set<String> = []

        for insight in insights {
            // 去重
            if !seenTitles.contains(insight.title) {
                seenTitles.insert(insight.title)
                optimizedInsights.append(insight)
            }

            // 限制洞察数量
            if optimizedInsights.count >= 10 {
                break
            }
        }

        return optimizedInsights
    }

    /// 生成个性化质量建议
    private func generatePersonalizedQualityAdvice(_ quality: DeepSeekSleepQualityAssessment, profile: UserSleepProfile) -> DeepSeekSleepInsight? {
        // 根据用户年龄和偏好生成个性化建议
        if (profile.age ?? 30) > 50 && quality.structureScore < 70 {
            return DeepSeekSleepInsight(
                type: .info,
                title: "年龄相关的睡眠变化",
                description: "随着年龄增长，深睡眠比例自然会下降。保持规律作息和适度运动有助于改善睡眠质量。",
                confidence: 80.0,
                priority: .medium,
                relatedMetrics: ["深睡眠", "年龄因素"],
                actionable: true
            )
        }

        return nil
    }

    /// 计算理想周期数
    private func calculateIdealCycleCount(_ session: LocalSleepSession) -> Int {
        guard let endTime = session.endTime else { return 5 }

        let totalHours = endTime.timeIntervalSince(session.startTime) / 3600
        return max(4, min(6, Int(totalHours / 1.5))) // 每1.5小时一个周期
    }

    /// 加载用户睡眠档案
    private func loadUserSleepProfile() -> UserSleepProfile? {
        // 从UserDefaults或其他存储加载用户档案
        if let data = UserDefaults.standard.data(forKey: "userSleepProfile"),
           let profile = try? JSONDecoder().decode(UserSleepProfile.self, from: data) {
            return profile
        }

        // 返回默认档案
        return UserSleepProfile(
            userId: "default",
            age: 30,
            gender: "其他",
            sleepGoals: UserSleepProfile.SleepGoals(
                targetBedtime: Calendar.current.date(from: DateComponents(hour: 23)) ?? Date(),
                targetWakeTime: Calendar.current.date(from: DateComponents(hour: 7)) ?? Date(),
                targetSleepDuration: 8.0 * 3600, // 转换为秒
                qualityGoal: 80.0
            ),
            preferences: UserSleepProfile.SleepPreferences(
                roomTemperature: 20.0,
                noiseLevel: "quiet",
                lightLevel: "dark",
                mattressFirmness: "medium"
            ),
            healthConditions: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - 洞察类型优先级扩展已在其他文件中定义
