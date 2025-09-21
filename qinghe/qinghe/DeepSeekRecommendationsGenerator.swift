import Foundation
import SwiftUI

// MARK: - 个性化建议生成扩展

extension EnhancedDeepSeekSleepAnalysisEngine {
    
    // MARK: - 个性化建议生成
    
    func generatePersonalizedRecommendations(insights: [DeepSeekSleepInsight], patterns: SleepPatternAnalysis, session: LocalSleepSession) async -> [DeepSeekSleepRecommendation] {
        print("💡 开始生成个性化建议...")
        
        var recommendations: [DeepSeekSleepRecommendation] = []
        
        // 基于洞察生成建议
        recommendations.append(contentsOf: generateInsightBasedRecommendations(insights))
        
        // 基于睡眠模式生成建议
        recommendations.append(contentsOf: generatePatternBasedRecommendations(patterns))
        
        // 基于用户档案生成建议
        recommendations.append(contentsOf: generateProfileBasedRecommendations())
        
        // 基于历史趋势生成建议
        recommendations.append(contentsOf: generateTrendBasedRecommendations())
        
        // 通用健康建议
        recommendations.append(contentsOf: generateGeneralHealthRecommendations())
        
        // 去重和排序
        recommendations = deduplicateRecommendations(recommendations)
        recommendations.sort { $0.priority.rawValue > $1.priority.rawValue }
        
        // 限制建议数量
        return Array(recommendations.prefix(8))
    }
    
    private func generateInsightBasedRecommendations(_ insights: [DeepSeekSleepInsight]) -> [DeepSeekSleepRecommendation] {
        var recommendations: [DeepSeekSleepRecommendation] = []
        
        for insight in insights {
            switch insight.type {
            case .concern, .warning:
                if insight.relatedMetrics.contains("打鼾频率") {
                    recommendations.append(DeepSeekSleepRecommendation(
                        type: .health,
                        title: "改善打鼾问题",
                        description: "尝试侧睡姿势，保持鼻腔通畅，必要时咨询医生。",
                        priority: .high,
                        category: .sleepPosition,
                        estimatedImpact: .high,
                        implementationDifficulty: .medium,
                        timeToSeeResults: "1-2周",
                        relatedInsights: [insight.id.uuidString]
                    ))
                }
                
                if insight.relatedMetrics.contains("环境噪音") {
                    recommendations.append(DeepSeekSleepRecommendation(
                        type: .environment,
                        title: "优化睡眠环境",
                        description: "使用耳塞或白噪音机，关闭不必要的电子设备，保持卧室安静。",
                        priority: .high,
                        category: .environment,
                        estimatedImpact: .high,
                        implementationDifficulty: .easy,
                        timeToSeeResults: "立即见效",
                        relatedInsights: [insight.id.uuidString]
                    ))
                }
                
                if insight.relatedMetrics.contains("翻身频率") {
                    recommendations.append(DeepSeekSleepRecommendation(
                        type: .comfort,
                        title: "改善睡眠舒适度",
                        description: "检查床垫和枕头是否合适，调整室温到18-22度之间。",
                        priority: .medium,
                        category: .comfort,
                        estimatedImpact: .medium,
                        implementationDifficulty: .medium,
                        timeToSeeResults: "3-7天",
                        relatedInsights: [insight.id.uuidString]
                    ))
                }
                
                if insight.relatedMetrics.contains("睡眠周期") {
                    recommendations.append(DeepSeekSleepRecommendation(
                        type: .schedule,
                        title: "调整睡眠时长",
                        description: "尝试延长睡眠时间30-60分钟，确保完成4-6个完整的睡眠周期。",
                        priority: .high,
                        category: .schedule,
                        estimatedImpact: .high,
                        implementationDifficulty: .medium,
                        timeToSeeResults: "1-2周",
                        relatedInsights: [insight.id.uuidString]
                    ))
                }
                
            case .neutral:
                if insight.relatedMetrics.contains("作息规律") {
                    recommendations.append(DeepSeekSleepRecommendation(
                        type: .schedule,
                        title: "保持规律作息",
                        description: "每天在相同时间上床和起床，包括周末，建立稳定的生物钟。",
                        priority: .medium,
                        category: .schedule,
                        estimatedImpact: .high,
                        implementationDifficulty: .medium,
                        timeToSeeResults: "2-3周",
                        relatedInsights: [insight.id.uuidString]
                    ))
                }
                
            case .positive:
                // 对于积极的洞察，生成维持现状的建议
                recommendations.append(DeepSeekSleepRecommendation(
                    type: .habit,
                    title: "保持良好习惯",
                    description: "您的\(insight.title.lowercased())表现很好，请继续保持当前的睡眠习惯。",
                    priority: .low,
                    category: .habit,
                    estimatedImpact: .medium,
                    implementationDifficulty: .easy,
                    timeToSeeResults: "持续保持",
                    relatedInsights: [insight.id.uuidString]
                ))
            case .info:
                // 信息性洞察的建议
                recommendations.append(DeepSeekSleepRecommendation(
                    type: .technology,
                    title: "了解睡眠数据",
                    description: "根据您的睡眠数据分析：\(insight.description)",
                    priority: .low,
                    category: .technology,
                    estimatedImpact: .low,
                    implementationDifficulty: .easy,
                    timeToSeeResults: "即时",
                    relatedInsights: [insight.id.uuidString]
                ))
            }
        }
        
        return recommendations
    }
    
    private func generatePatternBasedRecommendations(_ patterns: SleepPatternAnalysis) -> [DeepSeekSleepRecommendation] {
        var recommendations: [DeepSeekSleepRecommendation] = []
        
        // 基于呼吸模式的建议
        if patterns.breathingPattern.overallQuality == .poor {
            recommendations.append(DeepSeekSleepRecommendation(
                type: .health,
                title: "改善睡眠呼吸",
                description: "睡前进行深呼吸练习，保持鼻腔通畅，考虑使用加湿器。",
                priority: .high,
                category: .health,
                estimatedImpact: .high,
                implementationDifficulty: .easy,
                timeToSeeResults: "1-2周",
                relatedInsights: []
            ))
        }
        
        // 基于睡眠稳定性的建议
        if patterns.overallStability < 60 {
            recommendations.append(DeepSeekSleepRecommendation(
                type: .schedule,
                title: "建立睡前仪式",
                description: "创建固定的睡前例行程序，如洗澡、阅读或冥想，帮助身体准备睡眠。",
                priority: .medium,
                category: .routine,
                estimatedImpact: .high,
                implementationDifficulty: .medium,
                timeToSeeResults: "2-3周",
                relatedInsights: []
            ))
        }
        
        // 基于环境分析的建议
        if patterns.environmentalAnalysis.noiseLevel != .quiet {
            recommendations.append(DeepSeekSleepRecommendation(
                type: .environment,
                title: "降低环境噪音",
                description: "使用遮光窗帘、关闭电子设备、使用白噪音或耳塞来创造安静的睡眠环境。",
                priority: .medium,
                category: .environment,
                estimatedImpact: .high,
                implementationDifficulty: .easy,
                timeToSeeResults: "立即见效",
                relatedInsights: []
            ))
        }
        
        return recommendations
    }
    
    private func generateProfileBasedRecommendations() -> [DeepSeekSleepRecommendation] {
        var recommendations: [DeepSeekSleepRecommendation] = []
        
        guard let profile = userProfile else {
            return recommendations
        }
        
        // 基于年龄的建议
        if let age = profile.age {
            if age > 50 {
                recommendations.append(DeepSeekSleepRecommendation(
                    type: .health,
                    title: "关注睡眠健康",
                    description: "随着年龄增长，睡眠质量可能下降。建议定期检查睡眠呼吸问题，保持适度运动。",
                    priority: .medium,
                    category: .health,
                    estimatedImpact: .medium,
                    implementationDifficulty: .medium,
                    timeToSeeResults: "4-6周",
                    relatedInsights: []
                ))
            }
        }
        
        // 基于睡眠目标的建议
        if let targetBedtime = profile.sleepGoals.targetBedtime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            
            recommendations.append(DeepSeekSleepRecommendation(
                type: .schedule,
                title: "遵循目标就寝时间",
                description: "尽量在\(formatter.string(from: targetBedtime))前上床睡觉，保持规律的作息时间。",
                priority: .medium,
                category: .schedule,
                estimatedImpact: .high,
                implementationDifficulty: .medium,
                timeToSeeResults: "1-2周",
                relatedInsights: []
            ))
        }
        
        return recommendations
    }
    
    private func generateTrendBasedRecommendations() -> [DeepSeekSleepRecommendation] {
        var recommendations: [DeepSeekSleepRecommendation] = []
        
        if userSleepHistory.count >= 7 {
            let recentWeek = Array(userSleepHistory.suffix(7))
            let averageQuality = recentWeek.map { $0.qualityAssessment.overallScore }.reduce(0, +) / Double(recentWeek.count)
            
            if averageQuality < 70 {
                recommendations.append(DeepSeekSleepRecommendation(
                    type: .comprehensive,
                    title: "全面改善睡眠质量",
                    description: "最近一周的睡眠质量偏低，建议从作息、环境、健康等多方面进行改善。",
                    priority: .high,
                    category: .comprehensive,
                    estimatedImpact: .high,
                    implementationDifficulty: .hard,
                    timeToSeeResults: "4-6周",
                    relatedInsights: []
                ))
            }
        }
        
        return recommendations
    }
    
    private func generateGeneralHealthRecommendations() -> [DeepSeekSleepRecommendation] {
        return [
            DeepSeekSleepRecommendation(
                type: .lifestyle,
                title: "睡前避免咖啡因",
                description: "睡前6小时内避免摄入咖啡、茶或其他含咖啡因的饮品。",
                priority: .low,
                category: .lifestyle,
                estimatedImpact: .medium,
                implementationDifficulty: .easy,
                timeToSeeResults: "3-5天",
                relatedInsights: []
            ),
            DeepSeekSleepRecommendation(
                type: .lifestyle,
                title: "适度运动",
                description: "每天进行30分钟的适度运动，但避免在睡前3小时内进行剧烈运动。",
                priority: .low,
                category: .lifestyle,
                estimatedImpact: .high,
                implementationDifficulty: .medium,
                timeToSeeResults: "2-4周",
                relatedInsights: []
            ),
            DeepSeekSleepRecommendation(
                type: .environment,
                title: "控制卧室温度",
                description: "保持卧室温度在18-22度之间，这是最适合睡眠的温度范围。",
                priority: .low,
                category: .environment,
                estimatedImpact: .medium,
                implementationDifficulty: .easy,
                timeToSeeResults: "立即见效",
                relatedInsights: []
            )
        ]
    }
    
    // MARK: - 辅助方法

    private func deduplicateRecommendations(_ recommendations: [DeepSeekSleepRecommendation]) -> [DeepSeekSleepRecommendation] {
        var uniqueRecommendations: [DeepSeekSleepRecommendation] = []
        var seenTitles: Set<String> = []

        for recommendation in recommendations {
            if !seenTitles.contains(recommendation.title) {
                uniqueRecommendations.append(recommendation)
                seenTitles.insert(recommendation.title)
            }
        }

        return uniqueRecommendations
    }
}
