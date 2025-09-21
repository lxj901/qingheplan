import Foundation
import AVFoundation

// MARK: - AI运动教练服务
@MainActor
class WorkoutAICoachService: NSObject, ObservableObject {
    static let shared = WorkoutAICoachService()

    // 发布的属性
    @Published var isAnalyzing = false
    @Published var isPlayingAudio = false
    @Published var isAudioPlaying = false  // 兼容性别名
    @Published var lastGuidance: String?
    @Published var lastAnalysis: WorkoutAIAnalysisResponse.AnalysisData.Analysis?
    @Published var lastAnalysisResult: WorkoutAnalysisResult?
    @Published var connectionStatus: String = "未连接"
    @Published var serviceStatus: AIServiceStatus = .disconnected

    // 私有属性
    private let baseURL = "https://api.qinghejihua.com.cn"
    private let networkManager = NetworkManager.shared
    private let audioPlayer = WorkoutAudioPlayer.shared
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var currentAudioId: String?

    override private init() {
        super.init()
        // 同步音频播放状态
        updateAudioPlayingStatus()
        speechSynthesizer.delegate = self
    }

    // MARK: - 启动AI教练
    func startAICoaching(for workoutType: WorkoutType, userId: String? = nil) {
        Task {
            do {
                serviceStatus = .analyzing
                let response = try await startWorkout(workoutType: workoutType, userId: userId)

                if response.success, let data = response.data {
                    // 转换为 WorkoutAnalysisResult 格式
                    let guidance = WorkoutGuidance(
                        message: data.guidance.message,
                        priorityText: data.guidance.priority,
                        priorityColor: priorityColorForPriority(data.guidance.priority),
                        priorityIcon: priorityIconForPriority(data.guidance.priority)
                    )

                    let analysisItems = convertAnalysisToItems(data.analysis)

                    lastAnalysisResult = WorkoutAnalysisResult(
                        guidance: guidance,
                        analysisItems: analysisItems,
                        timestamp: Date()
                    )

                    serviceStatus = .connected
                } else {
                    serviceStatus = .error
                }
            } catch {
                print("❌ 启动AI教练失败: \(error)")
                serviceStatus = .error
            }
        }
    }

    // MARK: - 停止AI教练
    func stopAICoaching() {
        serviceStatus = .disconnected
        lastAnalysisResult = nil
        lastGuidance = nil
        lastAnalysis = nil
        isAnalyzing = false
        isPlayingAudio = false
        isAudioPlaying = false

        // 停止音频播放
        audioPlayer.stopAudio()

        print("⏹️ AI教练已停止")
    }

    // MARK: - 分析运动数据（兼容性方法）
    func analyzeWorkoutData(
        workoutType: WorkoutType,
        heartRate: Int? = nil,
        cadence: Int? = nil,
        pace: Double? = nil,
        distance: Double? = nil,
        duration: Int? = nil,
        userId: String? = nil
    ) async throws {
        let response = try await analyzeWorkout(
            workoutType: workoutType,
            heartRate: heartRate,
            cadence: cadence,
            pace: pace,
            distance: distance,
            duration: duration,
            userId: userId
        )

        if response.success, let data = response.data {
            // 转换为 WorkoutAnalysisResult 格式
            let guidance = WorkoutGuidance(
                message: data.guidance.message,
                priorityText: data.guidance.priority,
                priorityColor: priorityColorForPriority(data.guidance.priority),
                priorityIcon: priorityIconForPriority(data.guidance.priority)
            )

            let analysisItems = convertAnalysisToItems(data.analysis)

            lastAnalysisResult = WorkoutAnalysisResult(
                guidance: guidance,
                analysisItems: analysisItems,
                timestamp: Date()
            )

            serviceStatus = .connected
        } else {
            serviceStatus = .error
        }
    }

    // MARK: - 辅助方法
    private func updateAudioPlayingStatus() {
        // 定期同步音频播放状态
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.isAudioPlaying = self.isPlayingAudio
            }
        }
    }

    private func priorityColorForPriority(_ priority: String) -> String {
        switch priority.lowercased() {
        case "high": return "#FF5722"
        case "medium": return "#FF9800"
        case "low": return "#4CAF50"
        default: return "#4CAF50"
        }
    }

    private func priorityIconForPriority(_ priority: String) -> String {
        switch priority.lowercased() {
        case "high": return "exclamationmark.triangle.fill"
        case "medium": return "info.circle.fill"
        case "low": return "lightbulb.fill"
        default: return "lightbulb.fill"
        }
    }

    private func convertAnalysisToItems(_ analysis: WorkoutAIAnalysisResponse.AnalysisData.Analysis) -> [AnalysisItem] {
        var items: [AnalysisItem] = []

        if let heartRate = analysis.heartRate {
            items.append(AnalysisItem(
                message: heartRate.message,
                statusText: heartRate.status,
                statusColor: statusColorForStatus(heartRate.status)
            ))
        }

        if let cadence = analysis.cadence {
            items.append(AnalysisItem(
                message: cadence.message,
                statusText: cadence.status,
                statusColor: statusColorForStatus(cadence.status)
            ))
        }

        if let pace = analysis.pace {
            items.append(AnalysisItem(
                message: pace.message,
                statusText: pace.status,
                statusColor: statusColorForStatus(pace.status)
            ))
        }

        return items
    }

    private func statusColorForStatus(_ status: String) -> String {
        switch status.lowercased() {
        case "danger": return "#FF5722"
        case "warning": return "#FF9800"
        case "normal": return "#4CAF50"
        default: return "#4CAF50"
        }
    }

    // MARK: - 运动开始首问
    func startWorkout(workoutType: WorkoutType, userId: String? = nil) async throws -> WorkoutAIAnalysisResponse {
        let request = WorkoutStartRequest(
            workoutType: workoutType.chineseName,
            userId: userId ?? String(UserManager.shared.currentUser?.id ?? 0)
        )

        print("🎯 发送运动开始请求 - 类型: \(workoutType.chineseName)")

        let response: WorkoutAIAnalysisResponse = try await networkManager.request(
            endpoint: "/workout-ai-coach/start-workout",
            method: .POST,
            parameters: try request.toDictionary(),
            responseType: WorkoutAIAnalysisResponse.self
        )

        if response.success, let data = response.data {
            lastGuidance = data.guidance.message

            // 播放欢迎语音
            if let audioInfo = data.audio, audioInfo.success, let audioUrl = audioInfo.audioUrl {
                await playGuidanceAudio(audioUrl: audioUrl, audioId: audioInfo.audioId)
            } else {
                // 后端TTS不可用时，本地系统TTS兜底
                speakLocalTTS(data.guidance.message)
            }

            print("✅ 运动开始响应成功 - 欢迎语音: \(data.guidance.message)")
        }

        return response
    }

    // MARK: - 完整运动分析 (包含语音指导)
    func analyzeWorkout(
        workoutType: WorkoutType,
        heartRate: Int? = nil,
        cadence: Int? = nil,
        pace: Double? = nil,
        distance: Double? = nil,
        duration: Int? = nil,
        userId: String? = nil
    ) async throws -> WorkoutAIAnalysisResponse {


        isAnalyzing = true
        defer { isAnalyzing = false }

        let workoutData = WorkoutAIAnalysisRequest.WorkoutDataForAI(
            workoutType: workoutType.chineseName,
            heartRate: heartRate,
            cadence: cadence,
            pace: pace,
            distance: distance,
            duration: duration,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        let request = WorkoutAIAnalysisRequest(
            workoutData: workoutData,
            userId: userId ?? String(UserManager.shared.currentUser?.id ?? 0),
            options: WorkoutAIAnalysisRequest.AnalysisOptions(generateAudio: true)
        )

        print("📊 发送运动分析请求 - 心率: \(heartRate ?? 0), 配速: \(pace ?? 0.0)")

        let response: WorkoutAIAnalysisResponse = try await networkManager.request(
            endpoint: "/workout-ai-coach/analyze",
            method: .POST,
            parameters: try request.toDictionary(),
            responseType: WorkoutAIAnalysisResponse.self
        )

        if response.success, let data = response.data {
            lastGuidance = data.guidance.message
            lastAnalysis = data.analysis

            // 更新 lastAnalysisResult 以便 UI 显示最新的推荐内容
            let guidance = WorkoutGuidance(
                message: data.guidance.message,
                priorityText: data.guidance.priority,
                priorityColor: priorityColorForPriority(data.guidance.priority),
                priorityIcon: priorityIconForPriority(data.guidance.priority)
            )

            let analysisItems = convertAnalysisToItems(data.analysis)

            lastAnalysisResult = WorkoutAnalysisResult(
                guidance: guidance,
                analysisItems: analysisItems,
                timestamp: Date()
            )

            serviceStatus = .connected

            // 播放指导语音（后端TTS失败则本地兜底）
            if let audioInfo = data.audio, audioInfo.success, let audioUrl = audioInfo.audioUrl {
                await playGuidanceAudio(audioUrl: audioUrl, audioId: audioInfo.audioId)
            } else {
                speakLocalTTS(data.guidance.message)
            }

            print("✅ 运动分析响应成功 - 指导: \(data.guidance.message)")
        }

        return response
    }

    // MARK: - 实时运动分析 (轻量版)
    func realTimeAnalysis(
        workoutType: WorkoutType,
        heartRate: Int? = nil,
        cadence: Int? = nil,
        pace: Double? = nil
    ) async throws -> WorkoutAIAnalysisResponse {

        let workoutData = WorkoutAIAnalysisRequest.WorkoutDataForAI(
            workoutType: workoutType.chineseName,
            heartRate: heartRate,
            cadence: cadence,
            pace: pace,
            distance: nil,
            duration: nil,
            timestamp: nil
        )

        let request = WorkoutAIAnalysisRequest(
            workoutData: workoutData,
            userId: nil,
            options: nil
        )

        let response: WorkoutAIAnalysisResponse = try await networkManager.request(
            endpoint: "/workout-ai-coach/real-time",
            method: .POST,
            parameters: try request.toDictionary(),
            responseType: WorkoutAIAnalysisResponse.self
        )

        if response.success, let data = response.data {
            // 实时分析也更新 UI 显示的推荐内容，但不更新 lastGuidance
            let guidance = WorkoutGuidance(
                message: data.guidance.message,
                priorityText: data.guidance.priority,
                priorityColor: priorityColorForPriority(data.guidance.priority),
                priorityIcon: priorityIconForPriority(data.guidance.priority)
            )

            let analysisItems = convertAnalysisToItems(data.analysis)

            lastAnalysisResult = WorkoutAnalysisResult(
                guidance: guidance,
                analysisItems: analysisItems,
                timestamp: Date()
            )

            serviceStatus = .connected

            // 播放轻量级语音指导（后端TTS失败则本地兜底）
            if let audioInfo = data.audio, audioInfo.success, let audioUrl = audioInfo.audioUrl {
                await playGuidanceAudio(audioUrl: audioUrl, audioId: audioInfo.audioId)
            } else {
                speakLocalTTS(data.guidance.message)
            }

            print("✅ 实时分析响应成功 - 指导: \(data.guidance.message)")
        }

        return response
    }

    // MARK: - 单独生成语音指导
    func generateAudioGuidance(message: String, userId: String? = nil) async throws -> String? {
        let request: [String: Any] = [
            "message": message,
            "userId": userId ?? String(UserManager.shared.currentUser?.id ?? 0)
        ]

        struct AudioResponse: Codable {
            let success: Bool
            let audioUrl: String?
            let audioId: String?
            let processingTime: Double?
        }

        let response: AudioResponse = try await networkManager.request(
            endpoint: "/workout-ai-coach/audio-guidance",
            method: .POST,
            parameters: request,
            responseType: AudioResponse.self
        )

        if response.success, let audioUrl = response.audioUrl {
            await playGuidanceAudio(audioUrl: audioUrl, audioId: response.audioId)
            return audioUrl
        }

        return nil
    }

    // MARK: - 服务健康检查
    func checkServiceHealth() async throws -> Bool {
        struct HealthResponse: Codable {
            let success: Bool
            let service: String?
            let message: String?
            let timestamp: String?
            let features: [String]?
        }

        do {
            let response: HealthResponse = try await networkManager.request(
                endpoint: "/workout-ai-coach/health",
                method: .GET,
                responseType: HealthResponse.self
            )

            connectionStatus = response.success ? "已连接" : "连接异常"
            return response.success
        } catch {
            connectionStatus = "连接失败"
            throw error
        }
    }

    // MARK: - 私有方法

    private func speakLocalTTS(_ text: String) {
        // 停止可能存在的音频播放，避免重叠
        audioPlayer.stopAudio()
        do {
            let session = AVAudioSession.sharedInstance()
            // 使用口语音频模式，压低其它音频，支持蓝牙
            try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .allowBluetooth])
            try? session.setActive(true)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.0
        utterance.postUtteranceDelay = 0.0
        speechSynthesizer.speak(utterance)
        // isPlayingAudio 状态通过 delegate 同步
    }

    private func playGuidanceAudio(audioUrl: String, audioId: String?) async {
        guard let url = URL(string: audioUrl) else {
            print("❌ 无效的音频URL: \(audioUrl)")
            return
        }

        currentAudioId = audioId

        // 通知音频播放开始
        if let audioId = audioId {
            await notifyAudioPlaybackStarted(audioId: audioId, audioUrl: audioUrl)
        }

        // 更新播放状态
        isPlayingAudio = true
        isAudioPlaying = true

        // 播放音频
        await audioPlayer.playAudio(from: url) { [weak self] success in
            Task { @MainActor in
                // 更新播放状态
                self?.isPlayingAudio = false
                self?.isAudioPlaying = false

                if let audioId = self?.currentAudioId {
                    if success {
                        await self?.notifyAudioPlaybackCompleted(audioId: audioId)
                    } else {
                        await self?.notifyAudioPlaybackError(audioId: audioId, error: "播放失败")
                    }
                }
                self?.currentAudioId = nil
            }
        }
    }

    // MARK: - 音频生命周期管理

    private func notifyAudioPlaybackStarted(audioId: String, audioUrl: String) async {
        let request = AudioLifecycleRequest(
            audioId: audioId,
            audioUrl: audioUrl,
            error: nil
        )

        struct EmptyResponse: Codable {}

        do {
            let _: EmptyResponse = try await networkManager.request(
                endpoint: "/audio-lifecycle/playback-started",
                method: .POST,
                parameters: try request.toDictionary(),
                responseType: EmptyResponse.self
            )
            print("📢 音频播放开始通知已发送 - ID: \(audioId)")
        } catch {
            print("❌ 发送音频播放开始通知失败: \(error)")
        }
    }

    private func notifyAudioPlaybackCompleted(audioId: String) async {
        let request = ["audioId": audioId]

        struct EmptyResponse: Codable {}

        do {
            let _: EmptyResponse = try await networkManager.request(
                endpoint: "/audio-lifecycle/playback-completed",
                method: .POST,
                parameters: request,
                responseType: EmptyResponse.self
            )
            print("✅ 音频播放完成通知已发送 - ID: \(audioId)")
        } catch {
            print("❌ 发送音频播放完成通知失败: \(error)")
        }
    }

    private func notifyAudioPlaybackError(audioId: String, error: String) async {
        let request = AudioLifecycleRequest(
            audioId: audioId,
            audioUrl: nil,
            error: error
        )

        struct EmptyResponse: Codable {}

        do {
            let _: EmptyResponse = try await networkManager.request(
                endpoint: "/audio-lifecycle/playback-error",
                method: .POST,
                parameters: try request.toDictionary(),
                responseType: EmptyResponse.self
            )
            print("⚠️ 音频播放错误通知已发送 - ID: \(audioId), 错误: \(error)")
        } catch {
            print("❌ 发送音频播放错误通知失败: \(error)")
        }
    }
}

// MARK: - Codable 扩展 (已在 CheckinAPIService.swift 中定义)


extension WorkoutAICoachService: @preconcurrency AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlayingAudio = true
            isAudioPlaying = true
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlayingAudio = false
            isAudioPlaying = false
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlayingAudio = false
            isAudioPlaying = false
        }
    }
}
