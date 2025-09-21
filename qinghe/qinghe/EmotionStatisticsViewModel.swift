import SwiftUI

@MainActor
class EmotionStatisticsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var statistics: EmotionStatisticsData?
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let emotionService = EmotionService.shared
    
    // MARK: - Public Methods
    
    /// 加载情绪统计数据
    func loadStatistics() async {
        isLoading = true
        
        do {
            let data = try await emotionService.getEmotionStatistics()

            statistics = data
        } catch {
            showErrorMessage("加载统计数据失败: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    /// 创建强度分布数据
    private func createIntensityDistribution(from distribution: [String: Int]) -> [String: Int] {
        var result: [String: Int] = [:]
        
        // 将强度分组
        var lowCount = 0
        var mediumCount = 0
        var highCount = 0
        
        for (intensityStr, count) in distribution {
            if let intensity = Int(intensityStr) {
                switch intensity {
                case 1...3:
                    lowCount += count
                case 4...6:
                    mediumCount += count
                case 7...10:
                    highCount += count
                default:
                    break
                }
            }
        }
        
        result["1-3"] = lowCount
        result["4-6"] = mediumCount
        result["7-10"] = highCount
        
        return result
    }
    
    /// 计算健康评分
    private func calculateHealthScore(averageIntensity: Double, emotionDistribution: [String: Int]) -> Int {
        let totalRecords = emotionDistribution.values.reduce(0, +)
        guard totalRecords > 0 else { return 50 }
        
        // 基础分数从平均强度计算
        var score = 100 - Int(averageIntensity * 5)
        
        // 根据积极情绪比例调整
        let positiveEmotions = ["开心", "平静", "兴奋"]
        let positiveCount = positiveEmotions.compactMap { emotionDistribution[$0] }.reduce(0, +)
        let positiveRatio = Double(positiveCount) / Double(totalRecords)
        
        // 积极情绪比例高则加分
        score += Int(positiveRatio * 20)
        
        // 根据消极情绪比例调整
        let negativeEmotions = ["难过", "愤怒", "焦虑", "疲惫"]
        let negativeCount = negativeEmotions.compactMap { emotionDistribution[$0] }.reduce(0, +)
        let negativeRatio = Double(negativeCount) / Double(totalRecords)
        
        // 消极情绪比例高则减分
        score -= Int(negativeRatio * 15)
        
        // 确保分数在合理范围内
        return max(0, min(100, score))
    }
}

// MARK: - Data Models

struct EmotionStatisticsData {
    let totalEmotions: Int
    let averageIntensity: Double
    let mostCommonEmotion: String
    let typeStats: [EmotionTypeStats]
    let weeklyTrend: [Int]
    let monthlyAverage: Double

    // 兼容旧版本的属性
    var totalRecords: Int { totalEmotions }
    var emotionDistribution: [String: Int] {
        Dictionary(uniqueKeysWithValues: typeStats.map { ($0.id, $0.total) })
    }
    var intensityDistribution: [String: Int] { [:] }
    var healthScore: Int { Int(averageIntensity * 10) }
}

struct EmotionTypeStats {
    let id: String
    let name: String
    let total: Int
    let percentage: Double
}

// EmotionWeeklyTrend is defined in AdditionalTypes.swift
