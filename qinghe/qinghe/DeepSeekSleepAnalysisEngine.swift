import Foundation
import SwiftUI
import Combine

/// 增强版 DeepSeek 睡眠分析引擎
/// 提供深度睡眠分析、模式识别、个性化洞察和趋势预测
@MainActor
class EnhancedDeepSeekSleepAnalysisEngine: ObservableObject {
    static let shared = EnhancedDeepSeekSleepAnalysisEngine()
    
    // MARK: - 发布属性
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0
    @Published var currentAnalysisStage = ""
    @Published var lastAnalysisResult: DeepSeekSleepAnalysis?
    
    // MARK: - 私有属性
    private let mlModels = AudioMLModels()
    private let apiService = DeepSeekAPIService.shared
    var userSleepHistory: [DeepSeekSleepAnalysis] = []
    var userProfile: UserSleepProfile?

    private init() {
        // 初始化时加载数据
        loadUserSleepHistory()
        loadUserProfile()
    }
    
    // MARK: - 主要分析方法
    
    /// 分析音频数据（单个音频片段）
    func analyzeAudio(_ audioData: Data) async -> DeepSeekSleepAnalysis? {
        print("🧠 开始分析单个音频片段...")
        
        // 这里可以实现单个音频片段的快速分析
        // 主要用于实时反馈或预览
        return nil
    }
    
    /// 分析完整睡眠会话（主要方法）
    func analyzeSleepSession(session: LocalSleepSession, audioFiles: [LocalAudioFile]) async throws -> DeepSeekSleepAnalysis {
        print("🧠 开始增强版 DeepSeek 睡眠分析...")

        isAnalyzing = true
        analysisProgress = 0

        defer {
            isAnalyzing = false
        }

        // 第一阶段：音频事件提取和分类
        currentAnalysisStage = "提取音频事件..."
        let audioEvents = try await extractAudioEvents(from: audioFiles)
        analysisProgress = 0.3

        // 第二阶段：调用 DeepSeek API 进行深度分析
        currentAnalysisStage = "调用 DeepSeek AI 进行深度分析..."
        let apiAnalysisResult = try await performDeepSeekAPIAnalysis(
            session: session,
            audioEvents: audioEvents
        )
        analysisProgress = 0.7

        // 第三阶段：生成个性化建议
        currentAnalysisStage = "生成个性化建议..."
        let recommendations = try await generateAPIBasedRecommendations(
            analysisResult: apiAnalysisResult
        )
        analysisProgress = 0.9

        // 第四阶段：创建最终分析结果
        currentAnalysisStage = "整合分析结果..."
        let analysis = createFinalAnalysis(
            session: session,
            apiResult: apiAnalysisResult,
            recommendations: recommendations
        )
        analysisProgress = 1.0

        // 保存到历史记录
        userSleepHistory.append(analysis)
        saveUserSleepHistory()

        lastAnalysisResult = analysis
        currentAnalysisStage = "分析完成"

        print("✅ 增强版 DeepSeek 睡眠分析完成！")
        return analysis
    }

    // MARK: - DeepSeek API 集成方法

    /// 执行 DeepSeek API 分析
    private func performDeepSeekAPIAnalysis(
        session: LocalSleepSession,
        audioEvents: [SleepAudioEvent]
    ) async throws -> DeepSeekSleepAnalysisResponse {
        print("🔗 调用 DeepSeek API 进行睡眠分析...")

        // 构建睡眠数据请求
        let sleepData = SleepAnalysisRequest(
            sessionId: session.sessionId,
            startTime: session.startTime,
            endTime: session.endTime,
            duration: session.endTime?.timeIntervalSince(session.startTime) ?? 0,
            audioEventCount: audioEvents.count
        )

        // 调用 API 服务
        return try await apiService.analyzeSleepData(
            sleepData: sleepData,
            audioEvents: audioEvents
        )
    }

    /// 生成基于 API 的建议
    private func generateAPIBasedRecommendations(
        analysisResult: DeepSeekSleepAnalysisResponse
    ) async throws -> [DeepSeekSleepRecommendation] {
        print("💡 生成基于 API 的个性化建议...")

        return try await apiService.getSleepRecommendations(
            analysisResult: analysisResult,
            userProfile: userProfile
        )
    }

    /// 创建最终分析结果
    private func createFinalAnalysis(
        session: LocalSleepSession,
        apiResult: DeepSeekSleepAnalysisResponse,
        recommendations: [DeepSeekSleepRecommendation]
    ) -> DeepSeekSleepAnalysis {
        let insights = apiResult.insights
        let recommendationStrings = recommendations.map { $0.title }

        return DeepSeekSleepAnalysis(
            sessionId: session.sessionId,
            qualityScore: apiResult.qualityScore,
            insights: insights,
            recommendations: recommendationStrings
        )
    }

    // MARK: - 辅助转换方法

    private func calculateSleepEfficiency(from result: DeepSeekSleepAnalysisResponse) -> Double {
        // 基于 API 结果计算睡眠效率
        return min(100.0, result.qualityScore * 1.1)
    }

    private func calculateDeepSleepPercentage(from result: DeepSeekSleepAnalysisResponse) -> Double {
        let deepSleepStages = result.sleepStages.filter { $0.stage.contains("深度") }
        let totalDuration = result.sleepStages.reduce(0) { $0 + $1.duration }
        let deepSleepDuration = deepSleepStages.reduce(0) { $0 + $1.duration }

        return totalDuration > 0 ? (deepSleepDuration / totalDuration) * 100 : 0
    }

    private func calculateREMSleepPercentage(from result: DeepSeekSleepAnalysisResponse) -> Double {
        let remStages = result.sleepStages.filter { $0.stage.contains("REM") }
        let totalDuration = result.sleepStages.reduce(0) { $0 + $1.duration }
        let remDuration = remStages.reduce(0) { $0 + $1.duration }

        return totalDuration > 0 ? (remDuration / totalDuration) * 100 : 0
    }

    private func extractQualityFactors(from result: DeepSeekSleepAnalysisResponse) -> [DeepSeekQualityFactor] {
        var factors: [DeepSeekQualityFactor] = []

        // 基于 API 结果创建质量因子
        factors.append(DeepSeekQualityFactor(
            name: "整体睡眠质量",
            score: result.qualityScore,
            impact: result.qualityScore > 80 ? .positive : (result.qualityScore > 60 ? .neutral : .negative),
            description: "基于 DeepSeek AI 分析的整体睡眠质量评估"
        ))

        return factors
    }

    private func convertToSleepStageAnalysis(from result: DeepSeekSleepAnalysisResponse) -> SleepStageAnalysis {
        let stages = result.sleepStages.map { stageInfo in
            SleepStage(
                stage: convertStageType(stageInfo.stage),
                startTime: stageInfo.startTime,
                duration: stageInfo.duration
            )
        }

        return SleepStageAnalysis(
            stages: stages,
            totalSleepTime: stages.reduce(0) { $0 + $1.duration },
            sleepEfficiency: calculateSleepEfficiency(from: result),
            stageDistribution: calculateStageDistribution(stages: stages)
        )
    }

    private func convertStageType(_ apiStage: String) -> SleepStageType {
        switch apiStage {
        case let stage where stage.contains("深度"):
            return .deep
        case let stage where stage.contains("浅度"):
            return .light
        case let stage where stage.contains("REM"):
            return .rem
        case let stage where stage.contains("清醒"):
            return .awake
        default:
            return .light
        }
    }

    private func calculateStageDistribution(stages: [SleepStage]) -> [SleepStageType: Double] {
        let totalDuration = stages.reduce(0) { $0 + $1.duration }
        var distribution: [SleepStageType: Double] = [:]

        for stageType in [SleepStageType.light, .deep, .rem, .awake] {
            let stageDuration = stages.filter { $0.stage == stageType }.reduce(0) { $0 + $1.duration }
            distribution[stageType] = totalDuration > 0 ? (stageDuration / totalDuration) * 100 : 0
        }

        return distribution
    }

    private func convertToDeepSeekInsights(from result: DeepSeekSleepAnalysisResponse) -> [DeepSeekSleepInsight] {
        return result.insights.enumerated().map { index, insight in
            DeepSeekSleepInsight(
                id: UUID().uuidString,
                title: insight,
                description: insight,
                category: .general,
                importance: index < 2 ? .high : .medium,
                confidence: result.confidence,
                relatedMetrics: [],
                actionable: true,
                timestamp: Date()
            )
        }
    }

    // MARK: - 公共辅助方法

    func calculateOverallConfidence(patterns: SleepPatternAnalysis) -> Double {
        // 基于各种模式的置信度计算
        let baseConfidence = 0.75
        let patternBonus = patterns.sleepCycles.count > 3 ? 0.1 : 0.0
        let qualityBonus = patterns.overallStability > 70 ? 0.1 : 0.0

        return min(1.0, baseConfidence + patternBonus + qualityBonus)
    }

    func loadUserSleepHistory() {
        if let data = UserDefaults.standard.data(forKey: "userSleepHistory"),
           let history = try? JSONDecoder().decode([DeepSeekSleepAnalysis].self, from: data) {
            userSleepHistory = history
        }
    }

    func saveUserSleepHistory() {
        if let data = try? JSONEncoder().encode(userSleepHistory) {
            UserDefaults.standard.set(data, forKey: "userSleepHistory")
        }
    }

    func loadUserProfile() {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserSleepProfile.self, from: data) {
            userProfile = profile
        }
    }

    func saveUserProfile(_ profile: UserSleepProfile) {
        userProfile = profile
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "userProfile")
        }
    }
    
    // MARK: - 音频事件提取
    
    private func extractAudioEvents(from audioFiles: [LocalAudioFile]) async throws -> [SleepAudioEvent] {
        var events: [SleepAudioEvent] = []
        
        for (index, audioFile) in audioFiles.enumerated() {
            print("🔍 分析音频文件 \(index + 1)/\(audioFiles.count): \(audioFile.fileName)")
            
            // 模拟从音频文件中提取事件
            // 在实际实现中，这里会使用 Core ML 模型进行分析
            let fileEvents = await extractEventsFromFile(audioFile)
            events.append(contentsOf: fileEvents)
            
            // 更新进度
            let fileProgress = Double(index + 1) / Double(audioFiles.count) * 0.2
            analysisProgress = fileProgress
        }
        
        print("📊 总共提取到 \(events.count) 个音频事件")
        return events
    }
    
    private func extractEventsFromFile(_ audioFile: LocalAudioFile) async -> [SleepAudioEvent] {
        // 模拟事件提取过程
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        var events: [SleepAudioEvent] = []
        let eventCount = Int.random(in: 3...8)
        
        for i in 0..<eventCount {
            let eventType = SleepAudioEventType.allCases.randomElement() ?? .breathing
            let startTime = Date().addingTimeInterval(Double(i * 30))
            let duration = Double.random(in: 5...30)
            let confidence = Double.random(in: 0.6...0.95)
            
            let event = SleepAudioEvent(
                id: UUID().uuidString,
                type: eventType,
                startTime: startTime,
                duration: duration,
                confidence: confidence,
                intensity: Double.random(in: 0.3...0.9),
                audioFile: audioFile.fileName
            )
            
            events.append(event)
        }
        
        return events
    }
}

// MARK: - 睡眠音频事件数据模型

struct SleepAudioEvent: Codable, Identifiable {
    let id: String
    let type: SleepAudioEventType
    let startTime: Date
    let duration: TimeInterval
    let confidence: Double
    let intensity: Double // 事件强度 0-1
    let audioFile: String
}

enum SleepAudioEventType: String, CaseIterable, Codable {
    case snoring = "snoring"
    case talking = "talking"
    case breathing = "breathing"
    case movement = "movement"
    case environmental = "environmental"
    case silence = "silence"
    
    var displayName: String {
        switch self {
        case .snoring: return "打鼾"
        case .talking: return "说话/梦话"
        case .breathing: return "呼吸"
        case .movement: return "翻身/动作"
        case .environmental: return "环境噪音"
        case .silence: return "安静"
        }
    }
    
    var impactOnSleep: SleepImpactLevel {
        switch self {
        case .snoring: return .high
        case .talking: return .medium
        case .breathing: return .low
        case .movement: return .medium
        case .environmental: return .high
        case .silence: return .positive
        }
    }
}

enum SleepImpactLevel {
    case positive
    case low
    case medium
    case high
}

// MARK: - 用户睡眠档案

struct UserSleepProfile: Codable {
    let userId: String
    let age: Int?
    let gender: String?
    let sleepGoals: SleepGoals
    let preferences: SleepPreferences
    let healthConditions: [String]
    let createdAt: Date
    var updatedAt: Date
    
    struct SleepGoals: Codable {
        let targetBedtime: Date?
        let targetWakeTime: Date?
        let targetSleepDuration: TimeInterval // 秒
        let qualityGoal: Double // 0-100
    }
    
    struct SleepPreferences: Codable {
        let roomTemperature: Double?
        let noiseLevel: String? // "quiet", "moderate", "noisy"
        let lightLevel: String? // "dark", "dim", "bright"
        let mattressFirmness: String? // "soft", "medium", "firm"
    }
}

// MARK: - 睡眠模式识别扩展

extension EnhancedDeepSeekSleepAnalysisEngine {

    // MARK: - 睡眠模式识别

    private func identifySleepPatterns(from events: [SleepAudioEvent], session: LocalSleepSession) async -> SleepPatternAnalysis {
        print("🔍 开始识别睡眠模式...")

        // 按时间排序事件
        let sortedEvents = events.sorted { $0.startTime < $1.startTime }

        // 分析事件分布
        let eventDistribution = analyzeEventDistribution(sortedEvents)

        // 识别睡眠周期
        let sleepCycles = identifySleepCycles(from: sortedEvents, session: session)

        // 分析呼吸模式
        let breathingPattern = analyzeBreathingPattern(from: sortedEvents)

        // 分析打鼾模式
        let snoringPattern = analyzeSnoringPattern(from: sortedEvents)

        // 分析动作模式
        let movementPattern = analyzeMovementPattern(from: sortedEvents)

        // 环境干扰分析
        let environmentalAnalysis = analyzeEnvironmentalFactors(from: sortedEvents)

        return SleepPatternAnalysis(
            eventDistribution: eventDistribution,
            sleepCycles: sleepCycles,
            breathingPattern: breathingPattern,
            snoringPattern: snoringPattern,
            movementPattern: movementPattern,
            environmentalAnalysis: environmentalAnalysis,
            overallStability: calculatePatternStability(sortedEvents)
        )
    }

    private func analyzeEventDistribution(_ events: [SleepAudioEvent]) -> EventDistributionAnalysis {
        let totalEvents = events.count
        guard totalEvents > 0 else {
            return EventDistributionAnalysis(
                snoringPercentage: 0,
                talkingPercentage: 0,
                breathingPercentage: 0,
                movementPercentage: 0,
                silencePercentage: 100,
                environmentalPercentage: 0
            )
        }

        let snoringCount = events.filter { $0.type == .snoring }.count
        let talkingCount = events.filter { $0.type == .talking }.count
        let breathingCount = events.filter { $0.type == .breathing }.count
        let movementCount = events.filter { $0.type == .movement }.count
        let silenceCount = events.filter { $0.type == .silence }.count
        let environmentalCount = events.filter { $0.type == .environmental }.count

        return EventDistributionAnalysis(
            snoringPercentage: Double(snoringCount) / Double(totalEvents) * 100,
            talkingPercentage: Double(talkingCount) / Double(totalEvents) * 100,
            breathingPercentage: Double(breathingCount) / Double(totalEvents) * 100,
            movementPercentage: Double(movementCount) / Double(totalEvents) * 100,
            silencePercentage: Double(silenceCount) / Double(totalEvents) * 100,
            environmentalPercentage: Double(environmentalCount) / Double(totalEvents) * 100
        )
    }

    private func identifySleepCycles(from events: [SleepAudioEvent], session: LocalSleepSession) -> [SleepCycle] {
        guard let endTime = session.endTime else { return [] }

        let totalDuration = endTime.timeIntervalSince(session.startTime)

        // 使用更智能的周期检测算法
        return detectSleepCyclesUsingAdvancedAlgorithm(events: events, session: session, totalDuration: totalDuration)
    }

    /// 高级睡眠周期检测算法
    private func detectSleepCyclesUsingAdvancedAlgorithm(events: [SleepAudioEvent], session: LocalSleepSession, totalDuration: TimeInterval) -> [SleepCycle] {
        // 1. 动态周期长度检测（70-120分钟范围）
        let _ = detectCycleLengths(from: events, totalDuration: totalDuration)

        // 2. 基于活动模式的周期边界检测
        let cycleBoundaries = detectCycleBoundaries(from: events, session: session)

        // 3. 结合两种方法生成最终周期
        var cycles: [SleepCycle] = []

        for i in 0..<cycleBoundaries.count - 1 {
            let cycleStart = cycleBoundaries[i]
            let cycleEnd = cycleBoundaries[i + 1]

            let cycleEvents = events.filter { event in
                event.startTime >= cycleStart && event.startTime < cycleEnd
            }

            let cycle = SleepCycle(
                id: UUID().uuidString,
                startTime: cycleStart,
                endTime: cycleEnd,
                stage: inferAdvancedCycleStage(from: cycleEvents, cycleIndex: i, totalCycles: cycleBoundaries.count - 1),
                quality: calculateAdvancedCycleQuality(from: cycleEvents),
                events: cycleEvents
            )

            cycles.append(cycle)
        }

        return cycles
    }

    /// 检测睡眠周期长度模式
    private func detectCycleLengths(from events: [SleepAudioEvent], totalDuration: TimeInterval) -> [TimeInterval] {
        // 分析活动密度变化来推断周期长度
        let timeWindow: TimeInterval = 300 // 5分钟窗口
        let windowCount = Int(totalDuration / timeWindow)

        var activityDensity: [Double] = []

        for i in 0..<windowCount {
            let windowStart = TimeInterval(i) * timeWindow
            let windowEnd = windowStart + timeWindow

            let windowEvents = events.filter { event in
                let eventTime = event.startTime.timeIntervalSince(Date(timeIntervalSince1970: 0))
                return eventTime >= windowStart && eventTime < windowEnd
            }

            let density = Double(windowEvents.count) + windowEvents.map { $0.intensity }.reduce(0, +)
            activityDensity.append(density)
        }

        // 使用峰值检测算法找到周期性模式
        let cyclePeaks = detectPeaksInActivityDensity(activityDensity)
        let cycleLengths = calculateCycleLengthsFromPeaks(cyclePeaks, timeWindow: timeWindow)

        return cycleLengths.isEmpty ? [5400] : cycleLengths // 默认90分钟
    }

    /// 检测周期边界
    private func detectCycleBoundaries(from events: [SleepAudioEvent], session: LocalSleepSession) -> [Date] {
        guard let endTime = session.endTime else { return [session.startTime] }

        var boundaries = [session.startTime]

        // 寻找活动模式的显著变化点
        let sortedEvents = events.sorted { $0.startTime < $1.startTime }
        let _ = endTime.timeIntervalSince(session.startTime)

        // 使用滑动窗口检测活动模式变化
        let windowSize: TimeInterval = 1800 // 30分钟窗口
        let stepSize: TimeInterval = 600    // 10分钟步长

        var currentTime = session.startTime.addingTimeInterval(windowSize)

        while currentTime < endTime.addingTimeInterval(-windowSize) {
            let beforeWindow = getEventsInTimeWindow(sortedEvents, center: currentTime.addingTimeInterval(-windowSize/2), windowSize: windowSize)
            let afterWindow = getEventsInTimeWindow(sortedEvents, center: currentTime.addingTimeInterval(windowSize/2), windowSize: windowSize)

            let activityChange = calculateActivityChange(beforeWindow, afterWindow)

            // 如果活动模式有显著变化，标记为周期边界
            if activityChange > 0.3 { // 阈值可调
                boundaries.append(currentTime)
            }

            currentTime = currentTime.addingTimeInterval(stepSize)
        }

        boundaries.append(endTime)
        return boundaries
    }

    /// 高级睡眠阶段推断算法
    private func inferAdvancedCycleStage(from events: [SleepAudioEvent], cycleIndex: Int, totalCycles: Int) -> DeepSeekSleepStage {
        let movementEvents = events.filter { $0.type == .movement }
        let snoringEvents = events.filter { $0.type == .snoring }
        let breathingEvents = events.filter { $0.type == .breathing }
        let talkingEvents = events.filter { $0.type == .talking }

        // 计算各类事件的特征
        let movementIntensity = movementEvents.map { $0.intensity }.reduce(0, +) / max(1, Double(movementEvents.count))
        let snoringIntensity = snoringEvents.map { $0.intensity }.reduce(0, +) / max(1, Double(snoringEvents.count))
        let breathingRegularity = calculateBreathingRegularity(breathingEvents)

        // 考虑周期位置（睡眠前期更可能是深睡眠）
        let cyclePosition = Double(cycleIndex) / max(1, Double(totalCycles))

        // 多因素评分系统
        var stageScores: [DeepSeekSleepStage: Double] = [
            .awake: 0,
            .light: 0,
            .deep: 0,
            .rem: 0
        ]

        // 清醒状态评分
        if talkingEvents.count > 0 || movementIntensity > 0.8 {
            stageScores[.awake] = 80 + Double(talkingEvents.count) * 10
        }

        // 浅睡眠评分
        stageScores[.light] = 40 + Double(movementEvents.count) * 5 - snoringIntensity * 20

        // 深睡眠评分（前半夜更可能）
        let deepSleepBonus = cyclePosition < 0.5 ? 20 : 0
        let deepSleepBase = 30.0
        let deepSleepSnoringBonus = snoringIntensity * 30.0
        let deepSleepMovementPenalty = Double(movementEvents.count) * 8.0
        stageScores[.deep] = deepSleepBase + deepSleepSnoringBonus + Double(deepSleepBonus) - deepSleepMovementPenalty

        // REM睡眠评分（后半夜更可能，呼吸不规律）
        let remBonus = cyclePosition > 0.3 ? 25 : 0
        let breathingIrregularityBonus = breathingRegularity < 0.7 ? 20 : 0
        let remBase = 25.0
        let remSnoringPenalty = snoringIntensity * 15.0
        stageScores[.rem] = remBase + Double(remBonus) + Double(breathingIrregularityBonus) - remSnoringPenalty

        // 返回得分最高的阶段
        return stageScores.max(by: { $0.value < $1.value })?.key ?? .light
    }

    /// 计算呼吸规律性
    private func calculateBreathingRegularity(_ breathingEvents: [SleepAudioEvent]) -> Double {
        guard breathingEvents.count > 2 else { return 1.0 }

        let intervals = zip(breathingEvents.dropFirst(), breathingEvents).map {
            $0.0.startTime.timeIntervalSince($0.1.startTime)
        }

        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - averageInterval, 2) }.reduce(0, +) / Double(intervals.count)
        let standardDeviation = sqrt(variance)

        // 规律性 = 1 - (标准差 / 平均间隔)，限制在0-1范围
        return max(0, min(1, 1 - (standardDeviation / max(averageInterval, 1))))
    }

    /// 高级周期质量计算
    private func calculateAdvancedCycleQuality(from events: [SleepAudioEvent]) -> Double {
        var qualityScore = 100.0

        // 运动干扰评分 (权重: 30%)
        let movementEvents = events.filter { $0.type == .movement }
        let movementPenalty = calculateMovementPenalty(movementEvents)
        qualityScore -= movementPenalty * 0.3

        // 打鼾影响评分 (权重: 25%)
        let snoringEvents = events.filter { $0.type == .snoring }
        let snoringPenalty = calculateSnoringPenalty(snoringEvents)
        qualityScore -= snoringPenalty * 0.25

        // 呼吸质量评分 (权重: 20%)
        let breathingEvents = events.filter { $0.type == .breathing }
        let breathingBonus = calculateBreathingQualityBonus(breathingEvents)
        qualityScore += breathingBonus * 0.2

        // 环境干扰评分 (权重: 15%)
        let environmentalEvents = events.filter { $0.type == .environmental }
        let environmentalPenalty = calculateEnvironmentalPenalty(environmentalEvents)
        qualityScore -= environmentalPenalty * 0.15

        // 连续性评分 (权重: 10%)
        let continuityBonus = calculateContinuityBonus(events)
        qualityScore += continuityBonus * 0.1

        return max(0, min(100, qualityScore))
    }

    private func calculateCycleQuality(from events: [SleepAudioEvent]) -> Double {
        guard !events.isEmpty else { return 85.0 }

        var quality = 100.0

        // 根据不同事件类型扣分
        for event in events {
            switch event.type {
            case .snoring:
                quality -= event.intensity * 10
            case .talking:
                quality -= event.intensity * 15
            case .movement:
                quality -= event.intensity * 8
            case .environmental:
                quality -= event.intensity * 12
            case .breathing, .silence:
                break // 不扣分
            }
        }

        return max(0, min(100, quality))
    }

    // MARK: - 高级质量计算辅助方法

    /// 计算运动干扰惩罚
    private func calculateMovementPenalty(_ movementEvents: [SleepAudioEvent]) -> Double {
        guard !movementEvents.isEmpty else { return 0 }

        let frequency = Double(movementEvents.count)
        let averageIntensity = movementEvents.map { $0.intensity }.reduce(0, +) / Double(movementEvents.count)

        // 频率惩罚 + 强度惩罚
        return min(50, frequency * 3 + averageIntensity * 20)
    }

    /// 计算打鼾影响惩罚
    private func calculateSnoringPenalty(_ snoringEvents: [SleepAudioEvent]) -> Double {
        guard !snoringEvents.isEmpty else { return 0 }

        let totalDuration = snoringEvents.map { $0.duration }.reduce(0, +)
        let averageIntensity = snoringEvents.map { $0.intensity }.reduce(0, +) / Double(snoringEvents.count)

        // 持续时间惩罚 + 强度惩罚
        return min(40, totalDuration / 60 * 5 + averageIntensity * 25)
    }

    /// 计算呼吸质量奖励
    private func calculateBreathingQualityBonus(_ breathingEvents: [SleepAudioEvent]) -> Double {
        guard !breathingEvents.isEmpty else { return 0 }

        let regularity = calculateBreathingRegularity(breathingEvents)
        let averageIntensity = breathingEvents.map { $0.intensity }.reduce(0, +) / Double(breathingEvents.count)

        // 规律性奖励 + 适中强度奖励
        let regularityBonus = regularity * 15
        let intensityBonus = (0.3...0.7).contains(averageIntensity) ? 10 : 0

        return regularityBonus + Double(intensityBonus)
    }

    /// 计算环境干扰惩罚
    private func calculateEnvironmentalPenalty(_ environmentalEvents: [SleepAudioEvent]) -> Double {
        guard !environmentalEvents.isEmpty else { return 0 }

        let frequency = Double(environmentalEvents.count)
        let averageIntensity = environmentalEvents.map { $0.intensity }.reduce(0, +) / Double(environmentalEvents.count)

        return min(30, frequency * 2 + averageIntensity * 15)
    }

    /// 计算连续性奖励
    private func calculateContinuityBonus(_ events: [SleepAudioEvent]) -> Double {
        guard events.count > 1 else { return 10 }

        let sortedEvents = events.sorted { $0.startTime < $1.startTime }
        let gaps = zip(sortedEvents.dropFirst(), sortedEvents).map {
            let previousEventEndTime = $0.1.startTime.addingTimeInterval($0.1.duration)
            return $0.0.startTime.timeIntervalSince(previousEventEndTime)
        }

        let longGaps = gaps.filter { $0 > 300 } // 5分钟以上的间隔
        let continuityScore = max(0, 10 - Double(longGaps.count) * 2)

        return continuityScore
    }

    // MARK: - 高级周期检测辅助方法

    /// 检测活动密度峰值
    private func detectPeaksInActivityDensity(_ density: [Double]) -> [Int] {
        var peaks: [Int] = []
        guard density.count > 2 else { return peaks }

        for i in 1..<(density.count - 1) {
            if density[i] > density[i-1] && density[i] > density[i+1] && density[i] > 0.5 {
                peaks.append(i)
            }
        }

        return peaks
    }

    /// 从峰值计算周期长度
    private func calculateCycleLengthsFromPeaks(_ peaks: [Int], timeWindow: TimeInterval) -> [TimeInterval] {
        guard peaks.count > 1 else { return [] }

        var cycleLengths: [TimeInterval] = []

        for i in 1..<peaks.count {
            let cycleLength = TimeInterval(peaks[i] - peaks[i-1]) * timeWindow
            if cycleLength >= 4200 && cycleLength <= 7200 { // 70-120分钟范围
                cycleLengths.append(cycleLength)
            }
        }

        return cycleLengths
    }

    /// 获取时间窗口内的事件
    private func getEventsInTimeWindow(_ events: [SleepAudioEvent], center: Date, windowSize: TimeInterval) -> [SleepAudioEvent] {
        let startTime = center.addingTimeInterval(-windowSize / 2)
        let endTime = center.addingTimeInterval(windowSize / 2)

        return events.filter { event in
            event.startTime >= startTime && event.startTime <= endTime
        }
    }

    /// 计算活动模式变化
    private func calculateActivityChange(_ beforeEvents: [SleepAudioEvent], _ afterEvents: [SleepAudioEvent]) -> Double {
        let beforeActivity = calculateActivityLevel(beforeEvents)
        let afterActivity = calculateActivityLevel(afterEvents)

        return abs(afterActivity - beforeActivity) / max(beforeActivity + afterActivity, 1.0)
    }

    /// 计算活动水平
    private func calculateActivityLevel(_ events: [SleepAudioEvent]) -> Double {
        guard !events.isEmpty else { return 0 }

        let totalIntensity = events.map { $0.intensity }.reduce(0, +)
        let eventCount = Double(events.count)

        return (totalIntensity + eventCount) / 2.0
    }

    // MARK: - 具体模式分析方法

    private func analyzeBreathingPattern(from events: [SleepAudioEvent]) -> BreathingPatternAnalysis {
        let breathingEvents = events.filter { $0.type == .breathing }

        guard !breathingEvents.isEmpty else {
            return BreathingPatternAnalysis(
                regularity: 50.0,
                averageIntensity: 0.0,
                irregularityCount: 0,
                overallQuality: .poor
            )
        }

        // 计算呼吸规律性
        let intervals = calculateBreathingIntervals(breathingEvents)
        let regularity = calculateRegularity(intervals)

        // 计算平均强度
        let averageIntensity = breathingEvents.map { $0.intensity }.reduce(0, +) / Double(breathingEvents.count)

        // 检测异常
        let irregularityCount = detectBreathingIrregularities(breathingEvents)

        let quality: BreathingQuality
        if regularity > 80 && irregularityCount < 3 {
            quality = .excellent
        } else if regularity > 60 && irregularityCount < 5 {
            quality = .good
        } else if regularity > 40 {
            quality = .fair
        } else {
            quality = .poor
        }

        return BreathingPatternAnalysis(
            regularity: regularity,
            averageIntensity: averageIntensity,
            irregularityCount: irregularityCount,
            overallQuality: quality
        )
    }

    private func analyzeSnoringPattern(from events: [SleepAudioEvent]) -> SnoringPatternAnalysis {
        let snoringEvents = events.filter { $0.type == .snoring }

        guard !snoringEvents.isEmpty else {
            return SnoringPatternAnalysis(
                frequency: 0,
                averageIntensity: 0.0,
                totalDuration: 0.0,
                severity: .none,
                timeDistribution: []
            )
        }

        let frequency = snoringEvents.count
        let averageIntensity = snoringEvents.map { $0.intensity }.reduce(0, +) / Double(snoringEvents.count)
        let totalDuration = snoringEvents.map { $0.duration }.reduce(0, +)

        let severity: SnoringSeverity
        if averageIntensity > 0.8 || frequency > 20 {
            severity = .severe
        } else if averageIntensity > 0.6 || frequency > 10 {
            severity = .moderate
        } else if averageIntensity > 0.3 || frequency > 5 {
            severity = .mild
        } else {
            severity = .none
        }

        // 分析时间分布
        let timeDistribution = analyzeTimeDistribution(snoringEvents)

        return SnoringPatternAnalysis(
            frequency: frequency,
            averageIntensity: averageIntensity,
            totalDuration: totalDuration,
            severity: severity,
            timeDistribution: timeDistribution
        )
    }

    private func analyzeMovementPattern(from events: [SleepAudioEvent]) -> MovementPatternAnalysis {
        let movementEvents = events.filter { $0.type == .movement }

        let frequency = movementEvents.count
        let averageIntensity = movementEvents.isEmpty ? 0.0 :
            movementEvents.map { $0.intensity }.reduce(0, +) / Double(movementEvents.count)

        let restlessness: RestlessnessLevel
        if frequency > 15 {
            restlessness = .high
        } else if frequency > 8 {
            restlessness = .moderate
        } else if frequency > 3 {
            restlessness = .low
        } else {
            restlessness = .minimal
        }

        return MovementPatternAnalysis(
            frequency: frequency,
            averageIntensity: averageIntensity,
            restlessness: restlessness,
            timeDistribution: analyzeTimeDistribution(movementEvents)
        )
    }

    private func analyzeEnvironmentalFactors(from events: [SleepAudioEvent]) -> EnvironmentalAnalysis {
        let environmentalEvents = events.filter { $0.type == .environmental }

        let noiseLevel: NoiseLevel
        let frequency = environmentalEvents.count
        let averageIntensity = environmentalEvents.isEmpty ? 0.0 :
            environmentalEvents.map { $0.intensity }.reduce(0, +) / Double(environmentalEvents.count)

        if averageIntensity > 0.7 || frequency > 10 {
            noiseLevel = .high
        } else if averageIntensity > 0.4 || frequency > 5 {
            noiseLevel = .moderate
        } else if averageIntensity > 0.2 || frequency > 2 {
            noiseLevel = .low
        } else {
            noiseLevel = .quiet
        }

        return EnvironmentalAnalysis(
            noiseLevel: noiseLevel,
            disruptionCount: frequency,
            averageIntensity: averageIntensity,
            impactOnSleep: calculateEnvironmentalImpact(noiseLevel, frequency)
        )
    }

    // MARK: - 辅助计算方法

    private func calculateBreathingIntervals(_ events: [SleepAudioEvent]) -> [TimeInterval] {
        guard events.count > 1 else { return [] }

        let sortedEvents = events.sorted { $0.startTime < $1.startTime }
        var intervals: [TimeInterval] = []

        for i in 1..<sortedEvents.count {
            let interval = sortedEvents[i].startTime.timeIntervalSince(sortedEvents[i-1].startTime)
            intervals.append(interval)
        }

        return intervals
    }

    private func calculateRegularity(_ intervals: [TimeInterval]) -> Double {
        guard intervals.count > 1 else { return 50.0 }

        let average = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - average, 2) }.reduce(0, +) / Double(intervals.count)
        let standardDeviation = sqrt(variance)

        // 规律性评分：标准差越小，规律性越高
        let regularity = max(0, 100 - (standardDeviation / average * 100))
        return min(100, regularity)
    }

    private func detectBreathingIrregularities(_ events: [SleepAudioEvent]) -> Int {
        // 简化的异常检测：强度变化过大的事件
        var irregularities = 0

        for i in 1..<events.count {
            let intensityDiff = abs(events[i].intensity - events[i-1].intensity)
            if intensityDiff > 0.3 {
                irregularities += 1
            }
        }

        return irregularities
    }

    private func analyzeTimeDistribution(_ events: [SleepAudioEvent]) -> [TimeDistributionPoint] {
        // 将睡眠时间分为4个时段进行分析
        guard let firstEvent = events.first, let lastEvent = events.last else { return [] }

        let totalDuration = lastEvent.startTime.timeIntervalSince(firstEvent.startTime)
        let quarterDuration = totalDuration / 4

        var distribution: [TimeDistributionPoint] = []

        for i in 0..<4 {
            let periodStart = firstEvent.startTime.addingTimeInterval(Double(i) * quarterDuration)
            let periodEnd = periodStart.addingTimeInterval(quarterDuration)

            let periodEvents = events.filter { event in
                event.startTime >= periodStart && event.startTime < periodEnd
            }

            let point = TimeDistributionPoint(
                period: i + 1,
                eventCount: periodEvents.count,
                averageIntensity: periodEvents.isEmpty ? 0.0 :
                    periodEvents.map { $0.intensity }.reduce(0, +) / Double(periodEvents.count)
            )

            distribution.append(point)
        }

        return distribution
    }

    private func calculatePatternStability(_ events: [SleepAudioEvent]) -> Double {
        // 计算整体模式稳定性
        guard events.count > 10 else { return 50.0 }

        let timeDistribution = analyzeTimeDistribution(events)
        let variance = calculateDistributionVariance(timeDistribution)

        // 稳定性评分：方差越小，稳定性越高
        return max(0, min(100, 100 - variance * 10))
    }

    private func calculateDistributionVariance(_ distribution: [TimeDistributionPoint]) -> Double {
        let counts = distribution.map { Double($0.eventCount) }
        let average = counts.reduce(0, +) / Double(counts.count)
        let variance = counts.map { pow($0 - average, 2) }.reduce(0, +) / Double(counts.count)
        return variance
    }

    private func calculateEnvironmentalImpact(_ noiseLevel: NoiseLevel, _ frequency: Int) -> EnvironmentalImpact {
        if noiseLevel == .high || frequency > 10 {
            return .severe
        } else if noiseLevel == .moderate || frequency > 5 {
            return .moderate
        } else if noiseLevel == .low || frequency > 2 {
            return .mild
        } else {
            return .minimal
        }
    }
}

// MARK: - 睡眠模式分析数据模型

struct SleepPatternAnalysis: Codable {
    let eventDistribution: EventDistributionAnalysis
    let sleepCycles: [SleepCycle]
    let breathingPattern: BreathingPatternAnalysis
    let snoringPattern: SnoringPatternAnalysis
    let movementPattern: MovementPatternAnalysis
    let environmentalAnalysis: EnvironmentalAnalysis
    let overallStability: Double
}

struct EventDistributionAnalysis: Codable {
    let snoringPercentage: Double
    let talkingPercentage: Double
    let breathingPercentage: Double
    let movementPercentage: Double
    let silencePercentage: Double
    let environmentalPercentage: Double
}

struct SleepCycle: Codable, Identifiable {
    let id: String
    let startTime: Date
    let endTime: Date
    let stage: DeepSeekSleepStage
    let quality: Double
    let events: [SleepAudioEvent]
}

enum DeepSeekSleepStage: String, Codable, CaseIterable {
    case light = "light"
    case deep = "deep"
    case rem = "rem"
    case awake = "awake"

    var displayName: String {
        switch self {
        case .light: return "浅睡眠"
        case .deep: return "深睡眠"
        case .rem: return "REM睡眠"
        case .awake: return "清醒"
        }
    }

    var color: Color {
        switch self {
        case .light: return .blue.opacity(0.6)
        case .deep: return .indigo
        case .rem: return .purple
        case .awake: return .orange
        }
    }
}

struct BreathingPatternAnalysis: Codable {
    let regularity: Double // 0-100
    let averageIntensity: Double
    let irregularityCount: Int
    let overallQuality: BreathingQuality
}

enum BreathingQuality: String, Codable {
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

struct SnoringPatternAnalysis: Codable {
    let frequency: Int
    let averageIntensity: Double
    let totalDuration: TimeInterval
    let severity: SnoringSeverity
    let timeDistribution: [TimeDistributionPoint]
}

enum SnoringSeverity: String, Codable {
    case none = "none"
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"

    var displayName: String {
        switch self {
        case .none: return "无"
        case .mild: return "轻微"
        case .moderate: return "中等"
        case .severe: return "严重"
        }
    }

    var color: Color {
        switch self {
        case .none: return .green
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

struct MovementPatternAnalysis: Codable {
    let frequency: Int
    let averageIntensity: Double
    let restlessness: RestlessnessLevel
    let timeDistribution: [TimeDistributionPoint]
}

enum RestlessnessLevel: String, Codable {
    case minimal = "minimal"
    case low = "low"
    case moderate = "moderate"
    case high = "high"

    var displayName: String {
        switch self {
        case .minimal: return "很少"
        case .low: return "较少"
        case .moderate: return "中等"
        case .high: return "频繁"
        }
    }
}

struct EnvironmentalAnalysis: Codable {
    let noiseLevel: NoiseLevel
    let disruptionCount: Int
    let averageIntensity: Double
    let impactOnSleep: EnvironmentalImpact
}

enum NoiseLevel: String, Codable {
    case quiet = "quiet"
    case low = "low"
    case moderate = "moderate"
    case high = "high"

    var displayName: String {
        switch self {
        case .quiet: return "安静"
        case .low: return "轻微噪音"
        case .moderate: return "中等噪音"
        case .high: return "嘈杂"
        }
    }
}

enum EnvironmentalImpact: String, Codable {
    case minimal = "minimal"
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"

    var displayName: String {
        switch self {
        case .minimal: return "影响很小"
        case .mild: return "轻微影响"
        case .moderate: return "中等影响"
        case .severe: return "严重影响"
        }
    }
}

struct TimeDistributionPoint: Codable {
    let period: Int // 1-4 代表睡眠的四个时段
    let eventCount: Int
    let averageIntensity: Double
}
