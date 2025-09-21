import Foundation
import SwiftUI

// MARK: - 睡眠阶段推断和质量评估扩展

extension EnhancedDeepSeekSleepAnalysisEngine {
    
    // MARK: - 睡眠阶段推断
    
    func inferSleepStages(from patterns: SleepPatternAnalysis, session: LocalSleepSession) async -> SleepStageAnalysis {
        print("🔍 开始推断睡眠阶段...")
        
        let cycles = patterns.sleepCycles
        let totalDuration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
        
        // 计算各阶段时长
        let lightSleepDuration = calculateStageDuration(cycles, stage: .light)
        let deepSleepDuration = calculateStageDuration(cycles, stage: .deep)
        let remSleepDuration = calculateStageDuration(cycles, stage: .rem)
        let awakeDuration = calculateStageDuration(cycles, stage: .awake)
        
        // 计算睡眠效率
        let actualSleepDuration = lightSleepDuration + deepSleepDuration + remSleepDuration
        let sleepEfficiency = totalDuration > 0 ? (actualSleepDuration / totalDuration) * 100 : 0
        
        // 计算各阶段占比
        let lightSleepPercentage = actualSleepDuration > 0 ? (lightSleepDuration / actualSleepDuration) * 100 : 0
        let deepSleepPercentage = actualSleepDuration > 0 ? (deepSleepDuration / actualSleepDuration) * 100 : 0
        let remSleepPercentage = actualSleepDuration > 0 ? (remSleepDuration / actualSleepDuration) * 100 : 0
        
        // 分析睡眠连续性
        let sleepContinuity = analyzeSleepContinuity(cycles)
        
        // 检测睡眠片段化
        let fragmentationIndex = calculateFragmentationIndex(cycles)
        
        return SleepStageAnalysis(
            sleepEfficiency: sleepEfficiency,
            lightSleepDuration: lightSleepDuration,
            deepSleepDuration: deepSleepDuration,
            remSleepDuration: remSleepDuration,
            awakeDuration: awakeDuration,
            lightSleepPercentage: lightSleepPercentage,
            deepSleepPercentage: deepSleepPercentage,
            remSleepPercentage: remSleepPercentage,
            sleepContinuity: sleepContinuity,
            fragmentationIndex: fragmentationIndex,
            cycleCount: cycles.count,
            averageCycleLength: cycles.isEmpty ? 0 : cycles.map { $0.endTime.timeIntervalSince($0.startTime) }.reduce(0, +) / Double(cycles.count)
        )
    }
    
    private func calculateStageDuration(_ cycles: [SleepCycle], stage: DeepSeekSleepStage) -> TimeInterval {
        return cycles
            .filter { $0.stage == stage }
            .map { $0.endTime.timeIntervalSince($0.startTime) }
            .reduce(0, +)
    }
    
    private func analyzeSleepContinuity(_ cycles: [SleepCycle]) -> Double {
        guard cycles.count > 1 else { return 100.0 }
        
        let awakeInterruptions = cycles.filter { $0.stage == .awake }.count
        let totalCycles = cycles.count
        
        // 连续性评分：清醒中断越少，连续性越好
        let continuity = max(0, 100 - Double(awakeInterruptions) / Double(totalCycles) * 100)
        return continuity
    }
    
    private func calculateFragmentationIndex(_ cycles: [SleepCycle]) -> Double {
        guard cycles.count > 2 else { return 0.0 }
        
        var stageChanges = 0
        for i in 1..<cycles.count {
            if cycles[i].stage != cycles[i-1].stage {
                stageChanges += 1
            }
        }
        
        // 片段化指数：阶段变化越频繁，片段化越严重
        return Double(stageChanges) / Double(cycles.count - 1) * 100
    }
    
    // MARK: - 睡眠质量评估
    
    func assessSleepQuality(patterns: SleepPatternAnalysis, stages: SleepStageAnalysis, session: LocalSleepSession) async -> DeepSeekSleepQualityAssessment {
        print("📊 开始评估睡眠质量...")
        
        // 基础质量评分
        var qualityScore = 100.0
        
        // 睡眠效率评分 (30%)
        let efficiencyScore = calculateEfficiencyScore(stages.sleepEfficiency)
        qualityScore = qualityScore * 0.3 + efficiencyScore * 0.3
        
        // 睡眠结构评分 (25%)
        let structureScore = calculateStructureScore(stages)
        qualityScore = qualityScore * 0.75 + structureScore * 0.25
        
        // 干扰因素评分 (25%)
        let disruptionScore = calculateDisruptionScore(patterns)
        qualityScore = qualityScore * 0.75 + disruptionScore * 0.25
        
        // 连续性评分 (20%)
        let continuityScore = stages.sleepContinuity
        qualityScore = qualityScore * 0.8 + continuityScore * 0.2
        
        // 确保评分在合理范围内
        qualityScore = max(0, min(100, qualityScore))
        
        let qualityLevel = getQualityLevel(from: qualityScore)
        let improvementPotential = calculateImprovementPotential(qualityScore, patterns, stages)
        
        return DeepSeekSleepQualityAssessment(
            overallScore: qualityScore,
            qualityLevel: qualityLevel,
            improvementPotential: improvementPotential,
            efficiencyScore: efficiencyScore,
            structureScore: structureScore,
            disruptionScore: disruptionScore,
            continuityScore: continuityScore
        )
    }
    
    private func calculateEfficiencyScore(_ efficiency: Double) -> Double {
        // 睡眠效率评分曲线
        switch efficiency {
        case 90...100: return 100
        case 85..<90: return 90
        case 80..<85: return 80
        case 75..<80: return 70
        case 70..<75: return 60
        default: return max(0, efficiency - 20)
        }
    }
    
    private func calculateStructureScore(_ stages: SleepStageAnalysis) -> Double {
        var score = 100.0
        
        // 理想的睡眠结构比例
        let idealDeepSleep = 20.0 // 20%
        let idealRemSleep = 25.0  // 25%
        let idealLightSleep = 55.0 // 55%
        
        // 计算与理想比例的偏差
        let deepSleepDeviation = abs(stages.deepSleepPercentage - idealDeepSleep)
        let remSleepDeviation = abs(stages.remSleepPercentage - idealRemSleep)
        let lightSleepDeviation = abs(stages.lightSleepPercentage - idealLightSleep)
        
        // 根据偏差扣分
        score -= deepSleepDeviation * 2
        score -= remSleepDeviation * 1.5
        score -= lightSleepDeviation * 1
        
        return max(0, min(100, score))
    }
    
    private func calculateDisruptionScore(_ patterns: SleepPatternAnalysis) -> Double {
        var score = 100.0
        
        // 打鼾干扰
        switch patterns.snoringPattern.severity {
        case .none: break
        case .mild: score -= 10
        case .moderate: score -= 20
        case .severe: score -= 35
        }
        
        // 环境干扰
        switch patterns.environmentalAnalysis.impactOnSleep {
        case .minimal: break
        case .mild: score -= 5
        case .moderate: score -= 15
        case .severe: score -= 25
        }
        
        // 动作干扰
        switch patterns.movementPattern.restlessness {
        case .minimal: break
        case .low: score -= 5
        case .moderate: score -= 10
        case .high: score -= 20
        }
        
        return max(0, min(100, score))
    }
    
    private func calculateImprovementPotential(_ currentScore: Double, _ patterns: SleepPatternAnalysis, _ stages: SleepStageAnalysis) -> Double {
        var potential = 100 - currentScore
        
        // 根据具体问题调整改善潜力
        if patterns.snoringPattern.severity != .none {
            potential += 15 // 打鼾问题有较大改善空间
        }
        
        if stages.sleepEfficiency < 85 {
            potential += 10 // 睡眠效率低有改善空间
        }
        
        if patterns.environmentalAnalysis.impactOnSleep != .minimal {
            potential += 10 // 环境问题容易改善
        }
        
        return min(100, potential)
    }
    
    private func getQualityLevel(from score: Double) -> DeepSeekSleepQualityLevel {
        switch score {
        case 90...100: return .excellent
        case 75..<90: return .good
        case 60..<75: return .fair
        default: return .poor
        }
    }
}

// MARK: - 扩展的睡眠阶段分析模型（已在主文件中定义）

// 注意：SleepStageAnalysis 已经在 DeepSeekSleepAnalysisModels.swift 中定义了扩展版本

// MARK: - 扩展的睡眠阶段分析模型（已在主文件中定义）

// 注意：SleepStageAnalysis 的扩展版本已经在 DeepSeekSleepAnalysisModels.swift 中定义
// DeepSeekSleepQualityAssessment 的扩展版本也已经在主文件中定义
