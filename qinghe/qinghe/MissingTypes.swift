import Foundation
import SwiftUI
import AVFoundation
import UIKit
import CoreLocation
import CoreML

// MARK: - Plan Related Types
struct Plan: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let progress: Double
    let status: String
    let reminderTime: Date?

    init(title: String, description: String, category: String, startDate: Date, endDate: Date, isActive: Bool = true, progress: Double = 0.0, status: String = "active", reminderTime: Date? = nil) {
        self.title = title
        self.description = description
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.progress = progress
        self.status = status
        self.reminderTime = reminderTime
    }
}

struct PlanNew: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    let progress: Double
    let status: String
    let goals: [String]
    let reminderTime: Date?

    init(title: String, description: String, category: String, startDate: Date, endDate: Date, isActive: Bool = true, progress: Double = 0.0, status: String = "active", goals: [String] = [], reminderTime: Date? = nil) {
        self.title = title
        self.description = description
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.progress = progress
        self.status = status
        self.goals = goals
        self.reminderTime = reminderTime
    }

    // MARK: - Codable Implementation

    private enum CodingKeys: String, CodingKey {
        case id, title, description, category, progress, status, goals, reminderTime
        case startDate = "startTime"  // 服务器使用 startTime，客户端使用 startDate
        case endDate = "endTime"      // 服务器使用 endTime，客户端使用 endDate
        case priority, userId, createdAt, updatedAt, completedAt  // 服务器额外字段
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 基本字段
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? "其他"
        self.progress = try container.decodeIfPresent(Double.self, forKey: .progress) ?? 0.0
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "待开始"
        self.goals = try container.decodeIfPresent([String].self, forKey: .goals) ?? []
        self.reminderTime = try container.decodeIfPresent(Date.self, forKey: .reminderTime)

        // 日期字段处理 - 支持多种格式
        let iso8601Formatter = ISO8601DateFormatter()
        let fallbackFormatter1 = DateFormatter()
        fallbackFormatter1.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let fallbackFormatter2 = DateFormatter()
        fallbackFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let fallbackFormatter3 = DateFormatter()
        fallbackFormatter3.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        // 解析开始时间
        if let startTimeString = try? container.decode(String.self, forKey: .startDate) {
            if let date = iso8601Formatter.date(from: startTimeString) {
                self.startDate = date
            } else if let date = fallbackFormatter1.date(from: startTimeString) {
                self.startDate = date
            } else if let date = fallbackFormatter2.date(from: startTimeString) {
                self.startDate = date
            } else if let date = fallbackFormatter3.date(from: startTimeString) {
                self.startDate = date
            } else {
                print("⚠️ 无法解析开始时间: \(startTimeString)")
                self.startDate = Date()
            }
        } else {
            self.startDate = Date()
        }

        // 解析结束时间
        if let endTimeString = try? container.decode(String.self, forKey: .endDate) {
            if let date = iso8601Formatter.date(from: endTimeString) {
                self.endDate = date
            } else if let date = fallbackFormatter1.date(from: endTimeString) {
                self.endDate = date
            } else if let date = fallbackFormatter2.date(from: endTimeString) {
                self.endDate = date
            } else if let date = fallbackFormatter3.date(from: endTimeString) {
                self.endDate = date
            } else {
                print("⚠️ 无法解析结束时间: \(endTimeString)")
                self.endDate = Calendar.current.date(byAdding: .month, value: 1, to: self.startDate) ?? Date()
            }
        } else {
            self.endDate = Calendar.current.date(byAdding: .month, value: 1, to: self.startDate) ?? Date()
        }

        // 计算 isActive 状态
        self.isActive = self.status == "进行中" || self.status == "待开始"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(progress, forKey: .progress)
        try container.encode(status, forKey: .status)
        try container.encode(goals, forKey: .goals)
        try container.encodeIfPresent(reminderTime, forKey: .reminderTime)

        // 编码日期为 ISO8601 格式
        let dateFormatter = ISO8601DateFormatter()
        try container.encode(dateFormatter.string(from: startDate), forKey: .startDate)
        try container.encode(dateFormatter.string(from: endDate), forKey: .endDate)
    }
}

struct PlanRequestNew: Codable {
    let title: String
    let description: String
    let category: String
    let startDate: Date
    let endDate: Date
    let goals: [String]
    let reminderTime: Date?

    init(title: String, description: String, category: String, startDate: Date, endDate: Date, goals: [String] = [], reminderTime: Date? = nil) {
        self.title = title
        self.description = description
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.goals = goals
        self.reminderTime = reminderTime
    }
}

// MARK: - Audio File Types
struct AudioFileInfo: Identifiable, Codable {
    let id = UUID()
    let fileName: String
    let filePath: String
    let duration: TimeInterval
    let fileSize: Int64
    let uploadTime: Date
    let processingStatus: String
    let analysisStatus: String
    let downloadUrl: String?
    let metadata: AudioMetadata?
    let sessionId: Int

    init(fileName: String, filePath: String, duration: TimeInterval, fileSize: Int64, uploadTime: Date, processingStatus: String, analysisStatus: String, downloadUrl: String? = nil, metadata: AudioMetadata? = nil, sessionId: Int) {
        self.fileName = fileName
        self.filePath = filePath
        self.duration = duration
        self.fileSize = fileSize
        self.uploadTime = uploadTime
        self.processingStatus = processingStatus
        self.analysisStatus = analysisStatus
        self.downloadUrl = downloadUrl
        self.metadata = metadata
        self.sessionId = sessionId
    }
}

struct AudioMetadata: Codable {
    let sampleRate: Int
    let bitRate: Int
    let channels: Int
    let format: String

    init(sampleRate: Int = 44100, bitRate: Int = 128000, channels: Int = 2, format: String = "m4a") {
        self.sampleRate = sampleRate
        self.bitRate = bitRate
        self.channels = channels
        self.format = format
    }
}

// MARK: - Workout Photo Types
struct WorkoutPhotoData: Identifiable, Codable {
    let id = UUID()
    let imageData: Data
    let timestamp: Date
    let location: CodableLocationCoordinate?
    let workoutId: String?

    init(imageData: Data, timestamp: Date, location: CodableLocationCoordinate? = nil, workoutId: String? = nil) {
        self.imageData = imageData
        self.timestamp = timestamp
        self.location = location
        self.workoutId = workoutId
    }
}

// MARK: - Location Types
struct CodableLocationCoordinate: Codable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// 注意：PlanPaginationInfo 已在 PlanService.swift 中定义

// MARK: - Sleep Related Types (已移至 SleepModels.swift)

// SleepReport 已移至 SleepModels.swift

// MARK: - Sleep Audio and Background Types
class SleepAudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0

    // 输出回调：当检测到"事件段"结束时回调返回完整 WAV 数据与类型
    var onEventFinalized: ((Data, String, Double) -> Void)?

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFormat: AVAudioFormat?
    
    // 后台任务管理
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var statusCheckTimer: Timer?
    private var isObservingLifecycle = false
    private var lastEngineCheckTime: AVAudioTime?

    // ML 模型管理器
    private let mlModels = AudioMLModels()

    // 目标采样率 16k
    private let targetSampleRate: Double = 16_000

    // 当前事件缓冲（使用16k浮点累积，便于直接写WAV与分类）
    private var eventFloatBuffer: [Float] = []
    private var eventStartTime: Date?

    // 1分钟超时落盘（即使仍有低概率语音），二选一策略：1分钟或静音超时
    private let maxEventDurationSec: TimeInterval = 60

    // "每分钟至少一段"需求：单独维护分钟缓冲（不受事件状态机影响）
    private var minuteFloatBuffer: [Float] = []

    // VAD 判决平滑
    private var speechProbEMA: Double = 0
    private let emaAlpha: Double = 0.2
    private let enterThresh: Double = 0.35  // 显著降低进入阈值，提高检测灵敏度
    private let exitThresh: Double = 0.30   // 显著降低退出阈值，提高检测灵敏度
    private let minEventSec: TimeInterval = 0.2  // 减少最小事件时长，更容易触发事件

    private var lastSpeechTime: Date?
    private var inSpeech: Bool = false

    // 音频处理缓冲区（用于 VAD 推理，16k）
    private var vadBuffer: [Float] = []
    private let vadFrameSize = 512 // Silero VAD 期望的帧大小（32ms @ 16kHz）
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        setupLifecycleObservers()
    }
    
    deinit {
        removeLifecycleObservers()
    }

    // MARK: - Public API
    func startRecording() async throws {
        if isRecording { return }

        let session = AVAudioSession.sharedInstance()
        // 🔧 使用 .playAndRecord 支持后台录音，允许蓝牙设备
        // 🚀 添加 .interruptSpokenAudioAndMixWithOthers 确保后台录制优先级
        try session.setCategory(.playAndRecord, mode: .measurement, options: [
            .mixWithOthers, 
            .allowBluetooth, 
            .defaultToSpeaker, 
            .duckOthers,
            .interruptSpokenAudioAndMixWithOthers
        ])
        try session.setPreferredSampleRate(targetSampleRate)
        // 🔥 设置为高优先级，确保后台保持活跃
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let engine = AVAudioEngine()
        self.audioEngine = engine
        let input = engine.inputNode
        self.inputNode = input

        // 以输入格式为准，后续可做重采样到16k
        let inputFormat = input.outputFormat(forBus: 0)
        self.audioFormat = inputFormat

        resetEvent()

        input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.process(buffer: buffer)
        }

        try engine.start()
        await MainActor.run {
            self.isRecording = true
            self.recordingDuration = 0
        }
        
        // 启动后台保护
        beginBackgroundTask()
        startStatusCheckTimer()

        Task.detached { [weak self] in
            while let self, self.isRecording {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { self.recordingDuration += 1 }
            }
        }
        
        print("🎤 睡眠录音已启动（支持后台）")
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil

        resetEvent()
        
        // 停止后台保护
        stopStatusCheckTimer()
        endBackgroundTask()
        
        // 🔧 停用音频会话，释放音频资源
        do {
            if WhiteNoisePlayer.shared.isPlaying {
                print("ℹ️ MissingTypes: 保留音频会话（白噪音正在播放）")
            } else {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
            print("✅ 睡眠录制音频会话已停用")
        } catch {
            print("⚠️ 停用音频会话失败: \(error)")
        }
    }

    func checkRecordingStatus() -> Bool { isRecording }

    func attemptRecovery() async throws {
        print("🔄 开始恢复录制...")
        
        // 保存当前状态
        let wasRecording = isRecording
        guard wasRecording else { return }
        
        // 🔥 关键修复：不调用 stopRecording()，只重置音频引擎
        // 保持 isRecording=true 和后台任务/定时器继续运行
        
        // 清理音频引擎但保持录制状态
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        
        // 等待一小段时间让系统释放资源
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 重新初始化音频引擎（不改变 isRecording 状态）
        try await setupAudioEngine()
        
        print("✅ 音频引擎恢复成功（保持后台任务）")
    }
    
    // MARK: - Audio Engine Setup
    
    private func setupAudioEngine() async throws {
        // 重新配置音频会话
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [
            .mixWithOthers, 
            .allowBluetooth, 
            .defaultToSpeaker, 
            .duckOthers,
            .interruptSpokenAudioAndMixWithOthers
        ])
        try session.setPreferredSampleRate(targetSampleRate)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        // 创建新的音频引擎
        let engine = AVAudioEngine()
        self.audioEngine = engine
        let input = engine.inputNode
        self.inputNode = input

        // 设置音频格式
        let inputFormat = input.outputFormat(forBus: 0)
        self.audioFormat = inputFormat

        // 安装音频处理tap
        input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.process(buffer: buffer)
        }

        // 启动音频引擎
        try engine.start()
    }

    // 供 SleepDataManager 定时保存（1分钟固定段）
    func getCurrentAudioData() async -> Data? {
        guard isRecording else { return nil }
        let floats = eventFloatBuffer
        guard !floats.isEmpty else { return nil }
        let pcm16 = float32toPCM16(data: floats)
        let wav = makeWav(pcmData: pcm16, sampleRate: Int(targetSampleRate), channels: 1, bitsPerSample: 16)
        return wav
    }

    // 分钟缓冲导出并清空（保证每分钟至少一段）
    func drainMinuteWavData() async -> Data? {
        guard isRecording else { return nil }
        guard !minuteFloatBuffer.isEmpty else { return nil }
        let floats = minuteFloatBuffer
        minuteFloatBuffer.removeAll(keepingCapacity: true)
        let pcm16 = float32toPCM16(data: floats)
        let wav = makeWav(pcmData: pcm16, sampleRate: Int(targetSampleRate), channels: 1, bitsPerSample: 16)
        return wav
    }

    func startNewSegment() async throws {
        // 对于按事件落盘，显式切段不一定需要；先实现为重置事件
        resetEvent()
    }

    /// 强制将当前事件缓冲与残余VAD数据落盘（无视阈值），并重置事件缓冲
    /// - Parameter reason: 触发原因（用于日志）
    func forceFinalizeCurrentEvent(reason: String = "manual") {
        // 将残余的 VAD 帧也并入缓冲，避免数据丢失
        if !vadBuffer.isEmpty {
            minuteFloatBuffer.append(contentsOf: vadBuffer)
            if inSpeech {
                eventFloatBuffer.append(contentsOf: vadBuffer)
            }
            vadBuffer.removeAll()
        }

        // 若当前存在事件数据，则强制完成
        if inSpeech || !eventFloatBuffer.isEmpty {
            print("🧹 强制完成当前事件 (reason=\(reason))，样本数: \(eventFloatBuffer.count)")
            finalizeEvent()
            resetEvent()
        } else {
            // 即使没有事件数据，也记录日志，方便调试
            if !minuteFloatBuffer.isEmpty {
                print("ℹ️ 无事件数据可强制完成，但分钟缓冲存在样本: \(minuteFloatBuffer.count)")
            } else {
                print("ℹ️ 无事件或分钟缓冲可强制完成 (reason=\(reason))")
            }
        }
    }

    // MARK: - Processing
    private func process(buffer: AVAudioPCMBuffer) {
        let now = Date()

        // 1) 使用 AVAudioConverter（占位）或简易重采样统一到 16kHz Float 单声道
        let resampledData = bufferTo16kFloats(buffer)

        // 2) 累积到 VAD 缓冲区 & 分钟缓冲
        vadBuffer.append(contentsOf: resampledData)
        minuteFloatBuffer.append(contentsOf: resampledData)

        // 3) 当缓冲区达到 VAD 帧大小时进行推理
        while vadBuffer.count >= vadFrameSize {
            let vadFrame = Array(vadBuffer.prefix(vadFrameSize))
            vadBuffer.removeFirst(vadFrameSize)

            // 使用 ML 模型进行 VAD 推理
            let speechProb = Double(mlModels.detectVoiceActivity(audioBuffer: vadFrame))
            speechProbEMA = emaAlpha * speechProb + (1 - emaAlpha) * speechProbEMA

            // 4) 状态机：进入/退出语音
            if !inSpeech, speechProbEMA >= enterThresh {
                inSpeech = true
                eventStartTime = now
                lastSpeechTime = now
                // 首帧不要丢失
                eventFloatBuffer.append(contentsOf: vadFrame)
                print("🎤 检测到语音开始，概率: \(String(format: "%.3f", speechProbEMA)) (阈值: \(enterThresh))")
            } else if inSpeech {
                lastSpeechTime = (speechProbEMA >= exitThresh) ? now : lastSpeechTime
                // 将有声数据缓存（16k 浮点）
                eventFloatBuffer.append(contentsOf: vadFrame)

                // 退出条件：静音超过 minEventSec 或 超过 maxEventDurationSec
                let silentLongEnough = (now.timeIntervalSince(lastSpeechTime ?? now) >= minEventSec) && (speechProbEMA < exitThresh)
                let exceedMax = (now.timeIntervalSince(eventStartTime ?? now) >= maxEventDurationSec)
                if silentLongEnough || exceedMax {
                    let reason = exceedMax ? "超时" : "静音"
                    print("🎤 语音事件结束(\(reason))，时长: \(String(format: "%.1f", now.timeIntervalSince(eventStartTime ?? now)))s，概率: \(String(format: "%.3f", speechProbEMA))")
                    finalizeEvent()
                    resetEvent()
                }
            } else {
                // 添加调试信息：显示为什么没有进入语音状态
                if speechProbEMA > 0.25 { // 调整显示阈值，适应新的触发阈值
                    print("🔍 VAD 概率: \(String(format: "%.3f", speechProbEMA)) (需要 ≥ \(enterThresh) 才能触发)")
                }
            }
        }
    }

    private func finalizeEvent() {
        guard !eventFloatBuffer.isEmpty else { return }
        let floats = eventFloatBuffer
        let pcm16 = float32toPCM16(data: floats)
        let wav = makeWav(pcmData: pcm16, sampleRate: Int(targetSampleRate), channels: 1, bitsPerSample: 16)

        // 使用 ML 模型进行音频分类（SnoreTalking.mlmodel 若存在）
        let (label, confidence) = mlModels.classifyAudioEvent(audioBuffer: floats)

        print("🔍 音频事件分类: \(label), 置信度: \(String(format: "%.2f", confidence))")
        print("💾 事件音频数据大小: \(wav.count) bytes, 时长: \(String(format: "%.1f", Double(floats.count) / 16000.0))s")
        onEventFinalized?(wav, label, Double(confidence))
    }

    private func resetEvent() {
        eventFloatBuffer.removeAll()
        eventStartTime = nil
        lastSpeechTime = nil
        inSpeech = false
        vadBuffer.removeAll() // 清空 VAD 缓冲区
    }

    // MARK: - Heuristic Classifier (占位，后续替换为 CoreML 模型)
    private func basicSnoreOrTalkingHeuristic(from data: [Float]) -> String {
        // 非严格：估计低频能量占比作为“呼噜”指示，否则“talking”
        return "talking"
    }

    // MARK: - Resample helper
    // 公开为 public 以便单元测试直接调用
    public func bufferTo16kFloats(_ buffer: AVAudioPCMBuffer) -> [Float] {
        // 若输入采样率已是16k且单声道float，直接取出
        let fmt = buffer.format
        let sr = fmt.sampleRate
        if Int(sr) == Int(targetSampleRate), fmt.channelCount == 1, let ptr = buffer.floatChannelData?.pointee {
            let n = Int(buffer.frameLength)
            return Array(UnsafeBufferPointer(start: ptr, count: n))
        }
        // 使用 AVAudioConverter 做采样率转换与下混为单声道
        if let out = convertWithAVAudioConverter(buffer, toSampleRate: targetSampleRate, channels: 1) {
            return out
        }
        // 兜底：退回到线性插值（极端情况下）
        let floats = mlModels.convertBufferToFloatArray(buffer)
        return resampleLinear(floats, from: sr, to: targetSampleRate)
    }

    private func convertWithAVAudioConverter(_ buffer: AVAudioPCMBuffer, toSampleRate: Double, channels: AVAudioChannelCount) -> [Float]? {
        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: toSampleRate, channels: channels, interleaved: false) else { return nil }
        let srcFormat = buffer.format
        guard srcFormat.sampleRate > 0 else { return nil }

        guard let converter = AVAudioConverter(from: srcFormat, to: targetFormat) else { return nil }

        // 估算输出帧数
        let ratio = toSampleRate / srcFormat.sampleRate
        let inFrames = Int(buffer.frameLength)
        let outFramesEst = max(1, Int(Double(inFrames) * ratio) + 8) // 留些余量

        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: AVAudioFrameCount(outFramesEst)) else { return nil }

        var inputConsumed = false
        let status = converter.convert(to: outBuffer, error: nil) { inNumPackets, outStatus in
            if inputConsumed {
                outStatus.pointee = .endOfStream
                return nil
            }
            outStatus.pointee = .haveData
            inputConsumed = true
            return buffer
        }
        guard status != .error, let ptr = outBuffer.floatChannelData?.pointee else { return nil }
        let n = Int(outBuffer.frameLength)
        return Array(UnsafeBufferPointer(start: ptr, count: n))
    }

    private func resampleLinear(_ audioData: [Float], from originalSampleRate: Double, to targetSampleRate: Double) -> [Float] {
        if originalSampleRate == targetSampleRate { return audioData }
        guard !audioData.isEmpty, originalSampleRate > 0, targetSampleRate > 0 else { return [] }
        let ratio = targetSampleRate / originalSampleRate
        let newLength = max(1, Int(Double(audioData.count) * ratio))
        var resampled = [Float](repeating: 0, count: newLength)
        for i in 0..<newLength {
            let origIndex = Double(i) / ratio
            let li = Int(floor(origIndex))
            let ui = min(li + 1, audioData.count - 1)
            let frac = Float(origIndex - Double(li))
            let a = audioData[li]
            let b = audioData[ui]
            resampled[i] = a * (1 - frac) + b * frac
        }
        return resampled
    }

    // MARK: - Utilities
    private func concatenate(buffers: [AVAudioPCMBuffer]) -> [Float] {
        let totalFrames = buffers.reduce(0) { $0 + Int($1.frameLength) }
        var out: [Float] = Array(repeating: 0, count: totalFrames)
        var offset = 0
        for b in buffers {
            let len = Int(b.frameLength)
            if let src = b.floatChannelData?.pointee {
                out.withUnsafeMutableBufferPointer { dst in
                    memcpy(dst.baseAddress!.advanced(by: offset), src, len * MemoryLayout<Float>.size)
                }
            }
            offset += len
        }
        return out
    }

    private func float32toPCM16(data: [Float]) -> Data {
        guard !data.isEmpty else {
            print("❌ float32toPCM16: 输入数据为空")
            return Data()
        }

        var pcm16 = Data(capacity: data.count * 2)
        var validSamples = 0
        var clampedSamples = 0

        for x in data {
            // 检查是否为有效数值
            guard x.isFinite else {
                print("⚠️ 发现无效音频样本: \(x)")
                continue
            }

            // 限制在 [-1.0, 1.0] 范围内
            let clamped = max(-1.0, min(1.0, Double(x)))
            if abs(clamped - Double(x)) > 0.001 {
                clampedSamples += 1
            }

            // 转换为16位整数
            let s = Int16(clamped * Double(Int16.max))
            var le = s.littleEndian
            withUnsafeBytes(of: &le) { pcm16.append(contentsOf: $0) }
            validSamples += 1
        }

        if clampedSamples > 0 {
            print("⚠️ 有 \(clampedSamples) 个音频样本被限幅")
        }

        print("🎵 音频转换完成 - 输入: \(data.count) 个float32样本, 输出: \(validSamples) 个PCM16样本, 数据大小: \(pcm16.count) bytes")

        return pcm16
    }

    private func makeWav(pcmData: Data, sampleRate: Int, channels: Int, bitsPerSample: Int) -> Data {
        // 确保参数有效
        guard sampleRate > 0, channels > 0, bitsPerSample > 0, !pcmData.isEmpty else {
            print("❌ makeWav: 无效参数 - sampleRate: \(sampleRate), channels: \(channels), bitsPerSample: \(bitsPerSample), dataSize: \(pcmData.count)")
            return Data()
        }

        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8
        let dataSize = pcmData.count
        let fileSize = 36 + dataSize

        print("🎵 生成WAV文件 - 采样率: \(sampleRate)Hz, 声道: \(channels), 位深: \(bitsPerSample)bit, 数据大小: \(dataSize) bytes")

        var data = Data()
        data.reserveCapacity(fileSize + 8)

        // RIFF header
        data.append("RIFF".data(using: .ascii)!)
        var fileSizeLE = UInt32(fileSize).littleEndian
        withUnsafeBytes(of: &fileSizeLE) { data.append(contentsOf: $0) }

        // WAVE format
        data.append("WAVE".data(using: .ascii)!)

        // fmt subchunk
        data.append("fmt ".data(using: .ascii)!)
        var subchunk1Size: UInt32 = 16
        var sc1 = subchunk1Size.littleEndian
        withUnsafeBytes(of: &sc1) { data.append(contentsOf: $0) }

        // Audio format (PCM = 1)
        var audioFormatPCM: UInt16 = 1
        var af = audioFormatPCM.littleEndian
        withUnsafeBytes(of: &af) { data.append(contentsOf: $0) }

        // Number of channels
        var numChannels = UInt16(channels).littleEndian
        withUnsafeBytes(of: &numChannels) { data.append(contentsOf: $0) }

        // Sample rate
        var sr = UInt32(sampleRate).littleEndian
        withUnsafeBytes(of: &sr) { data.append(contentsOf: $0) }

        // Byte rate
        var br = UInt32(byteRate).littleEndian
        withUnsafeBytes(of: &br) { data.append(contentsOf: $0) }

        // Block align
        var ba = UInt16(blockAlign).littleEndian
        withUnsafeBytes(of: &ba) { data.append(contentsOf: $0) }

        // Bits per sample
        var bps = UInt16(bitsPerSample).littleEndian
        withUnsafeBytes(of: &bps) { data.append(contentsOf: $0) }

        // data subchunk
        data.append("data".data(using: .ascii)!)
        var dataSizeLE = UInt32(dataSize).littleEndian
        withUnsafeBytes(of: &dataSizeLE) { data.append(contentsOf: $0) }

        // PCM data
        data.append(pcmData)

        print("✅ WAV文件生成完成 - 总大小: \(data.count) bytes, 头部: 44 bytes, 数据: \(dataSize) bytes")

        // 验证生成的WAV文件
        if data.count >= 44 {
            let header = data.prefix(4)
            if String(data: header, encoding: .ascii) == "RIFF" {
                print("✅ WAV文件头验证通过")
            } else {
                print("❌ WAV文件头验证失败")
            }
        } else {
            print("❌ WAV文件太小")
        }

        return data
    }
    
    // MARK: - Background Task Management
    
    private func beginBackgroundTask() {
        // 🔥 关键修复：即使已有后台任务也要续期，确保不中断
        if backgroundTask != .invalid {
            renewBackgroundTask()
            return
        }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SleepAudioRecording") { [weak self] in
            print("⚠️ 录音后台任务即将到期，立即续期...")
            self?.renewBackgroundTask()
        }
        
        if backgroundTask != .invalid {
            print("✅ 录音后台任务已启动: \(backgroundTask)")
        } else {
            print("❌ 录音后台任务启动失败")
        }
    }
    
    private func renewBackgroundTask() {
        // 🔥 关键修复：确保任务正确清理和续期
        let oldTask = backgroundTask
        
        // 立即申请新的后台任务
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SleepAudioRecording") { [weak self] in
            print("⚠️ 录音后台任务即将到期，立即续期...")
            self?.renewBackgroundTask()
        }
        
        if backgroundTask != .invalid {
            print("✅ 录音后台任务续期成功: \(backgroundTask)")
            
            // 🔥 关键：只有在新任务成功创建后才结束旧任务
            if oldTask != .invalid && oldTask != backgroundTask {
                UIApplication.shared.endBackgroundTask(oldTask)
                print("🔚 旧录音后台任务已结束: \(oldTask)")
            }
        } else {
            print("❌ 录音后台任务续期失败")
            // 如果新任务创建失败，保持旧任务（如果有的话）
            backgroundTask = oldTask
        }
    }
    
    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
        print("🔚 录音后台任务已结束")
    }
    
    // MARK: - Status Check Timer (定期检查录制状态)
    
    private func startStatusCheckTimer() {
        stopStatusCheckTimer()
        
        // 每10秒检查一次录制状态（更频繁，以便快速发现问题）
        statusCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            
            // 🔥 在后台时，积极续期后台任务和维护音频会话
            let isBackground = UIApplication.shared.applicationState == .background
            if isBackground {
                self.beginBackgroundTask()
                // 后台时更频繁地重新配置音频会话
                self.reassertAudioSession()
            }
            
            // 检查音频会话状态
            let session = AVAudioSession.sharedInstance()
            let isActive = session.category == .playAndRecord
            
            if !isActive {
                print("⚠️ 音频会话已失效，重新激活...")
                self.reassertAudioSession()
            }
            
            // 🔥 增强的音频引擎状态检查
            guard let engine = self.audioEngine else {
                print("❌ 音频引擎为空，立即重新初始化...")
                Task {
                    try? await self.attemptRecovery()
                }
                return
            }
            
            if !engine.isRunning {
                print("⚠️ 音频引擎已停止，尝试恢复...")
                Task {
                    try? await self.attemptRecovery()
                }
                return
            }
            
            // 🔥 检查音频引擎输入节点状态
            let inputNode = engine.inputNode
            if inputNode.numberOfInputs == 0 {
                print("⚠️ 音频引擎输入节点无效，重新配置...")
                Task {
                    try? await self.attemptRecovery()
                }
                return
            }
            
            // 主动维持音频会话（心跳）- 后台时更强力
            if isBackground {
                // 后台时使用更强的激活选项
                try? session.setActive(true, options: [.notifyOthersOnDeactivation])
                // 额外的音频会话保活
                try? session.setPreferredSampleRate(self.targetSampleRate)
                
                // 🔥 后台时额外检查：确保音频引擎真的在工作
                if let lastCheckTime = self.lastEngineCheckTime {
                    // 使用系统时间来检测是否卡住（简化版本）
                    let currentSystemTime = AVAudioTime(hostTime: mach_absolute_time())
                    if currentSystemTime.hostTime - lastCheckTime.hostTime > 30_000_000_000 { // 30秒无更新
                        print("⚠️ 检测到音频引擎可能长时间无响应，强制重启...")
                        Task {
                            try? await self.attemptRecovery()
                        }
                        return
                    }
                }
                self.lastEngineCheckTime = AVAudioTime(hostTime: mach_absolute_time())
            } else {
                try? session.setActive(true, options: .notifyOthersOnDeactivation)
            }
            
            let statusMsg = isBackground ? "✅ 录制状态检查正常 (后台模式)" : "✅ 录制状态检查正常 (前台模式)"
            print(statusMsg)
        }
        
        // 确保定时器在所有 RunLoop 模式下运行（包括滚动时）
        if let timer = statusCheckTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        print("⏱️ 状态检查定时器已启动（15秒间隔，包含保活心跳）")
    }
    
    private func stopStatusCheckTimer() {
        statusCheckTimer?.invalidate()
        statusCheckTimer = nil
        print("⏹️ 状态检查定时器已停止")
    }
    
    // MARK: - Lifecycle Observers
    
    private func setupLifecycleObservers() {
        guard !isObservingLifecycle else { return }
        isObservingLifecycle = true
        
        let nc = NotificationCenter.default
        
        // 监听应用进入后台
        nc.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 监听应用进入前台
        nc.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // 监听音频会话中断
        nc.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        // 监听音频路由变化
        nc.addObserver(
            self,
            selector: #selector(handleAudioSessionRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        // 监听音频引擎配置变化
        nc.addObserver(
            self,
            selector: #selector(handleEngineConfigurationChange),
            name: .AVAudioEngineConfigurationChange,
            object: nil
        )
        
        // 🔐 监听屏幕锁定/解锁（关键！）
        nc.addObserver(
            self,
            selector: #selector(handleScreenLocked),
            name: UIApplication.protectedDataWillBecomeUnavailableNotification,
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(handleScreenUnlocked),
            name: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil
        )
        
        print("👂 生命周期监听已启动（包含屏幕锁定检测）")
    }
    
    private func removeLifecycleObservers() {
        guard isObservingLifecycle else { return }
        isObservingLifecycle = false
        
        NotificationCenter.default.removeObserver(self)
        print("🔇 生命周期监听已移除")
    }
    
    // MARK: - Lifecycle Event Handlers
    
    @objc private func handleAppDidEnterBackground() {
        guard isRecording else { return }
        
        print("📱 应用进入后台，保护录制...")
        
        // 重新申请后台任务
        beginBackgroundTask()
        
        // 确保音频会话仍然活跃
        reassertAudioSession()
    }
    
    @objc private func handleAppWillEnterForeground() {
        guard isRecording else { return }
        
        print("📱 应用进入前台，检查录制状态...")
        
        // 检查并恢复录制
        Task {
            await checkAndRestoreRecording()
        }
    }
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("🔇 音频会话中断开始")
            // 不立即停止，等待中断结束
            
        case .ended:
            print("🔊 音频会话中断结束，尝试恢复...")
            
            // 检查是否应该恢复
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    Task {
                        try? await attemptRecovery()
                    }
                }
            }
            
        @unknown default:
            break
        }
    }
    
    @objc private func handleAudioSessionRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        print("🎚️ 音频路由变化: \(reason.rawValue)")
        
        // 对于某些路由变化，可能需要重新配置
        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable:
            print("🔄 音频设备变化，重新配置...")
            reassertAudioSession()
            
        default:
            break
        }
    }
    
    @objc private func handleEngineConfigurationChange() {
        guard isRecording else { return }
        
        print("⚙️ 音频引擎配置变化，重新配置...")
        
        Task {
            try? await attemptRecovery()
        }
    }
    
    // 🔐 屏幕锁定处理（关键！保持音频会话活跃）
    @objc private func handleScreenLocked() {
        guard isRecording else { return }
        
        print("🔒 屏幕已锁定，保持音频会话活跃...")
        
        // 强化后台任务
        beginBackgroundTask()
        
        // 重新激活音频会话，确保锁屏后继续录音
        reassertAudioSession()
        
        // 检查引擎状态
        if let engine = audioEngine, !engine.isRunning {
            print("⚠️ 锁屏时音频引擎已停止，立即恢复...")
            Task {
                try? await attemptRecovery()
            }
        }
    }
    
    // 🔓 屏幕解锁处理
    @objc private func handleScreenUnlocked() {
        guard isRecording else { return }
        
        print("🔓 屏幕已解锁，检查录制状态...")
        
        // 检查并恢复录制
        Task {
            await checkAndRestoreRecording()
        }
    }
    
    // MARK: - Auto Recovery
    
    private func reassertAudioSession() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            // 检查权限
            switch session.recordPermission {
            case .denied:
                print("⚠️ 录音权限被拒绝")
                return
            case .undetermined:
                print("ℹ️ 录音权限未确定")
                return
            case .granted:
                break
            @unknown default:
                break
            }
            
            // 🔥 智能音频会话管理 - 避免不必要的重新配置
            let currentCategory = session.category
            let isCurrentlyActive = session.isOtherAudioPlaying == false
            
            // 如果会话已经正确配置且活跃，只需要重新激活
            if currentCategory == .playAndRecord && isCurrentlyActive {
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                print("✅ 音频会话重新激活成功（轻量模式）")
                return
            }
            
            // 需要完整重新配置的情况
            print("🔄 执行音频会话完整重新配置...")
            
            // 🔧 分步骤重新配置，减少失败概率
            
            // 步骤1: 温和停用当前会话
            if isCurrentlyActive {
                do {
                    if WhiteNoisePlayer.shared.isPlaying {
                        print("ℹ️ MissingTypes: 保留音频会话（白噪音正在播放）")
                    } else {
                        try session.setActive(false, options: .notifyOthersOnDeactivation)
                    }
                    // 给系统时间处理
                    Thread.sleep(forTimeInterval: 0.05)
                } catch {
                    print("⚠️ 停用音频会话时出现警告: \(error)")
                    // 继续执行，不要因为停用失败而中断
                }
            }
            
            // 步骤2: 重新配置类别和选项
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [
                    .mixWithOthers,           // 混合其他音频
                    .allowBluetooth,          // 允许蓝牙
                    .defaultToSpeaker,        // 默认扬声器（避免听筒）
                    .duckOthers              // 降低其他音频音量
                ]
            )
            
            // 步骤3: 设置首选参数
            try session.setPreferredSampleRate(targetSampleRate)
            try session.setPreferredIOBufferDuration(0.02) // 20ms缓冲
            
            // 步骤4: 重新激活会话
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            print("✅ 音频会话重新配置成功（完整模式）")
            
        } catch let error as NSError {
            print("❌ 音频会话重新配置失败: \(error)")
            
            // 🚨 错误恢复策略
            if error.code == 561015905 { // Session activation failed
                print("🔄 检测到会话激活失败，尝试恢复性重启...")
                attemptAudioSessionRecovery()
            }
        }
    }
    
    private func attemptAudioSessionRecovery() {
        print("🔄 开始音频会话恢复性重启...")
        
        // 在后台队列执行恢复，避免阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let session = AVAudioSession.sharedInstance()
            
            do {
                // 完全重置音频会话
                print("🔄 步骤1: 强制停用音频会话...")
                if WhiteNoisePlayer.shared.isPlaying {
                    print("ℹ️ MissingTypes: 保留音频会话（白噪音正在播放）")
                } else {
                    try? session.setActive(false, options: [])
                }
                
                // 等待更长时间让系统完全清理
                Thread.sleep(forTimeInterval: 0.3)
                
                print("🔄 步骤2: 重新配置音频会话...")
                // 使用最基本的配置
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                
                print("🔄 步骤3: 重新激活音频会话...")
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                
                print("✅ 音频会话恢复性重启成功")
                
                // 在主线程更新状态
                DispatchQueue.main.async {
                    // 如果音频引擎停止了，尝试重启
                    if let engine = self.audioEngine, !engine.isRunning {
                        Task {
                            try? await self.attemptRecovery()
                        }
                    }
                }
                
            } catch {
                print("❌ 音频会话恢复性重启失败: \(error)")
            }
        }
    }
    
    private func checkAndRestoreRecording() async {
        guard isRecording else { return }
        
        // 检查引擎是否还在运行
        guard let engine = audioEngine else {
            print("⚠️ 音频引擎丢失，尝试恢复...")
            try? await attemptRecovery()
            return
        }
        
        if !engine.isRunning {
            print("⚠️ 音频引擎未运行，尝试恢复...")
            try? await attemptRecovery()
            return
        }
        
        print("✅ 录制状态正常")
    }
}

private extension AVAudioPCMBuffer {
    func copyToNewBuffer() -> AVAudioPCMBuffer {
        let format = self.format
        let newBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: self.frameCapacity)!
        newBuffer.frameLength = self.frameLength
        if let src = self.floatChannelData?.pointee, let dst = newBuffer.floatChannelData?.pointee {
            memcpy(dst, src, Int(self.frameLength) * MemoryLayout<Float>.size)
        }
        return newBuffer
    }
}

// MARK: - 智能后台任务管理器
class SleepBackgroundManager: ObservableObject {
    static let shared = SleepBackgroundManager()
    @Published var currentTheme = "starry"
    @Published var isBackgroundTaskActive = false

    private var activeSessionId: String?
    private var alarmTime: Date?
    private var startTime: Date?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var renewalTimer: Timer?
    
    // UserDefaults keys for state persistence
    private let kActiveSessionId = "SleepTracking.ActiveSessionId"
    private let kAlarmTime = "SleepTracking.AlarmTime"
    private let kStartTime = "SleepTracking.StartTime"
    private let kIsTracking = "SleepTracking.IsTracking"

    private init() {
        // 启动时恢复状态
        restoreState()
    }

    // MARK: - Public Methods
    
    func startBackgroundTracking(sessionId: String, alarmTime: Date?) {
        self.activeSessionId = sessionId
        self.alarmTime = alarmTime
        self.startTime = Date()
        
        // 持久化状态
        saveState()
        
        // 启动后台任务
        beginBackgroundTask()
        
        // 启动智能续期定时器（每25秒续期）
        startRenewalTimer()
        
        print("🌙 后台追踪已启动，会话ID: \(sessionId)")
        print("📱 后台任务已激活，智能续期已启动")
    }

    func stopBackgroundTracking() {
        self.activeSessionId = nil
        self.alarmTime = nil
        self.startTime = nil
        
        // 清除持久化状态
        clearState()
        
        // 停止后台任务
        endBackgroundTask()
        
        // 停止续期定时器
        stopRenewalTimer()
        
        print("☀️ 后台追踪已停止")
    }

    func hasActiveBackgroundTracking() -> Bool {
        return activeSessionId != nil
    }

    func getCurrentSessionInfo() -> (sessionId: String?, alarmTime: Date?, startTime: Date?) {
        return (activeSessionId, alarmTime, startTime)
    }
    
    // MARK: - Background Task Management (智能续期)
    
    private func beginBackgroundTask() {
        guard backgroundTask == .invalid else { return }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SleepTracking") { [weak self] in
            print("⚠️ 后台任务即将到期，准备续期...")
            self?.renewBackgroundTask()
        }
        
        isBackgroundTaskActive = true
        print("✅ 后台任务已启动: \(backgroundTask)")
    }
    
    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
        isBackgroundTaskActive = false
        print("🔚 后台任务已结束")
    }
    
    /// 智能续期：结束当前任务并立即启动新任务
    private func renewBackgroundTask() {
        print("🔄 执行后台任务续期...")
        
        let oldTask = backgroundTask
        
        // 🔥 关键修复：先创建新任务，再结束旧任务
        let newTask = UIApplication.shared.beginBackgroundTask(withName: "SleepTracking") { [weak self] in
            print("⚠️ 后台任务即将到期，准备续期...")
            self?.renewBackgroundTask()
        }
        
        if newTask != .invalid {
            // 新任务创建成功，更新引用
            backgroundTask = newTask
            isBackgroundTaskActive = true
            print("✅ 后台任务续期成功: \(newTask)")
            
            // 结束旧任务
            if oldTask != .invalid && oldTask != newTask {
                UIApplication.shared.endBackgroundTask(oldTask)
                print("🔚 旧后台任务已结束: \(oldTask)")
            }
        } else {
            print("❌ 后台任务续期失败，保持旧任务")
            // 如果新任务创建失败，保持旧任务
            // backgroundTask 保持不变
        }
    }
    
    // MARK: - Renewal Timer (每25秒自动续期)
    
    private func startRenewalTimer() {
        stopRenewalTimer()
        
        // 每25秒续期一次，避免30秒限制
        renewalTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
            guard let self = self, self.hasActiveBackgroundTracking() else { return }
            
            print("⏰ 定时续期触发")
            self.renewBackgroundTask()
        }
        
        print("⏱️ 续期定时器已启动（25秒间隔）")
    }
    
    private func stopRenewalTimer() {
        renewalTimer?.invalidate()
        renewalTimer = nil
        print("⏹️ 续期定时器已停止")
    }
    
    // MARK: - State Persistence
    
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(activeSessionId, forKey: kActiveSessionId)
        defaults.set(alarmTime, forKey: kAlarmTime)
        defaults.set(startTime, forKey: kStartTime)
        defaults.set(true, forKey: kIsTracking)
        defaults.synchronize()
        print("💾 后台追踪状态已保存")
    }
    
    private func restoreState() {
        let defaults = UserDefaults.standard
        
        guard defaults.bool(forKey: kIsTracking) else { return }
        
        self.activeSessionId = defaults.string(forKey: kActiveSessionId)
        self.alarmTime = defaults.object(forKey: kAlarmTime) as? Date
        self.startTime = defaults.object(forKey: kStartTime) as? Date
        
        if activeSessionId != nil {
            print("🔄 恢复后台追踪状态：\(activeSessionId ?? "unknown")")
            
            // 重新启动后台任务和续期
            beginBackgroundTask()
            startRenewalTimer()
        }
    }
    
    private func clearState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: kActiveSessionId)
        defaults.removeObject(forKey: kAlarmTime)
        defaults.removeObject(forKey: kStartTime)
        defaults.removeObject(forKey: kIsTracking)
        defaults.synchronize()
        print("🗑️ 后台追踪状态已清除")
    }
}

// 这个类已被移动到 DeepSeekSleepAnalysisEngine.swift 文件中
// 保留这里作为向后兼容的引用
class DeepSeekSleepAnalysisEngine {
    static let shared = EnhancedDeepSeekSleepAnalysisEngine.shared

    private init() {}

    func analyzeAudio(_ audioData: Data) async -> DeepSeekSleepAnalysis? {
        return await EnhancedDeepSeekSleepAnalysisEngine.shared.analyzeAudio(audioData)
    }

    func analyzeSleepSession(session: LocalSleepSession, audioFiles: [LocalAudioFile]) async throws -> DeepSeekSleepAnalysis {
        return try await EnhancedDeepSeekSleepAnalysisEngine.shared.analyzeSleepSession(session: session, audioFiles: audioFiles)
    }
}

struct LocalSleepSession: Codable {
    let sessionId: String
    let startTime: Date
    var endTime: Date?
    let audioFiles: [String]
    let notes: String?
    let sleepScore: Int?
    let sleepEfficiency: Double?
    let userNotes: String?

    init(sessionId: String = UUID().uuidString, startTime: Date = Date(), endTime: Date? = nil, audioFiles: [String] = [], notes: String? = nil, sleepScore: Int? = nil, sleepEfficiency: Double? = nil, userNotes: String? = nil) {
        self.sessionId = sessionId
        self.startTime = startTime
        self.endTime = endTime
        self.audioFiles = audioFiles
        self.notes = notes
        self.sleepScore = sleepScore
        self.sleepEfficiency = sleepEfficiency
        self.userNotes = userNotes
    }
}

// MARK: - Basic Emotion Type (基础情绪类型)
enum EmotionType: String, CaseIterable, Codable {
    case happy = "happy"
    case sad = "sad"
    case angry = "angry"
    case anxious = "anxious"
    case excited = "excited"
    case calm = "calm"
    case frustrated = "frustrated"
    case content = "content"

    var displayName: String {
        switch self {
        case .happy: return "开心"
        case .sad: return "难过"
        case .angry: return "愤怒"
        case .anxious: return "焦虑"
        case .excited: return "兴奋"
        case .calm: return "平静"
        case .frustrated: return "沮丧"
        case .content: return "满足"
        }
    }
}

enum SleepStatisticsPeriod: String, CaseIterable {
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

// MARK: - Plan Statistics Types
struct PlanStatisticsNew: Codable {
    let totalPlans: Int
    let activePlans: Int
    let completedPlans: Int
    let completionRate: Double
    let averageProgress: Double
    let monthlyStats: [MonthlyPlanStats]

    init(totalPlans: Int = 0, activePlans: Int = 0, completedPlans: Int = 0, completionRate: Double = 0.0, averageProgress: Double = 0.0, monthlyStats: [MonthlyPlanStats] = []) {
        self.totalPlans = totalPlans
        self.activePlans = activePlans
        self.completedPlans = completedPlans
        self.completionRate = completionRate
        self.averageProgress = averageProgress
        self.monthlyStats = monthlyStats
    }
}

struct MonthlyPlanStats: Codable {
    let month: String
    let plansCreated: Int
    let plansCompleted: Int
    let completionRate: Double

    init(month: String, plansCreated: Int = 0, plansCompleted: Int = 0, completionRate: Double = 0.0) {
        self.month = month
        self.plansCreated = plansCreated
        self.plansCompleted = plansCompleted
        self.completionRate = completionRate
    }
}

// MARK: - Sleep Insight Types (已移至 SleepModels.swift)

// MARK: - Route Point Types
struct RoutePoint: Identifiable, Codable {
    let id = UUID()
    let latitude: Double      // 纬度
    let longitude: Double     // 经度
    let altitude: Double?     // 海拔
    let timestamp: Date       // 时间戳
    let speed: Double?        // 速度 (m/s)
    let course: Double        // 方向角 (度)
    let horizontalAccuracy: Double  // 水平精度
    let verticalAccuracy: Double?   // 垂直精度

    init(latitude: Double, longitude: Double, altitude: Double? = nil, timestamp: Date = Date(), speed: Double? = nil, course: Double = 0, horizontalAccuracy: Double = 0, verticalAccuracy: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
        self.speed = speed
        self.course = course
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
    }

    /// 从CLLocation创建RoutePoint
    init(from location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude >= 0 ? location.altitude : nil
        self.timestamp = location.timestamp
        self.speed = location.speed >= 0 ? location.speed : nil
        self.course = location.course >= 0 ? location.course : 0
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy >= 0 ? location.verticalAccuracy : nil
    }

    /// 获取坐标
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// 转换为CLLocation
    var location: CLLocation {
        return CLLocation(
            coordinate: coordinate,
            altitude: altitude ?? -1,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy ?? -1,
            course: course,
            speed: speed ?? -1,
            timestamp: timestamp
        )
    }

    /// 计算与另一点的距离
    /// - Parameter point: 另一个轨迹点
    /// - Returns: 距离（米）
    func distance(to point: RoutePoint) -> Double {
        let location1 = CLLocation(latitude: latitude, longitude: longitude)
        let location2 = CLLocation(latitude: point.latitude, longitude: point.longitude)
        return location1.distance(from: location2)
    }

    /// 计算与另一点的时间间隔
    /// - Parameter point: 另一个轨迹点
    /// - Returns: 时间间隔（秒）
    func timeInterval(to point: RoutePoint) -> TimeInterval {
        return point.timestamp.timeIntervalSince(timestamp)
    }

    /// 计算到另一点的速度
    /// - Parameter point: 另一个轨迹点
    /// - Returns: 速度（m/s），如果时间间隔为0则返回nil
    func speed(to point: RoutePoint) -> Double? {
        let distance = distance(to: point)
        let timeInterval = timeInterval(to: point)

        guard timeInterval > 0 else { return nil }
        return distance / timeInterval
    }

    /// 获取格式化的速度字符串
    var formattedSpeed: String {
        guard let speed = speed, speed >= 0 else { return "0.0 km/h" }
        return String(format: "%.1f km/h", speed * 3.6)
    }

    /// 获取格式化的海拔字符串
    var formattedAltitude: String {
        guard let altitude = altitude else { return "未知" }
        return String(format: "%.0f m", altitude)
    }

    /// 获取格式化的精度字符串
    var formattedAccuracy: String {
        return String(format: "±%.0f m", horizontalAccuracy)
    }
}

// MARK: - 轨迹数据集合
struct WorkoutRoute: Codable {
    let id = UUID()
    let workoutType: WorkoutType
    let startTime: Date
    let endTime: Date
    let routePoints: [RoutePoint]
    let totalDistance: Double
    let averageSpeed: Double
    let maxSpeed: Double

    init(workoutType: WorkoutType, startTime: Date, endTime: Date, routePoints: [RoutePoint]) {
        self.workoutType = workoutType
        self.startTime = startTime
        self.endTime = endTime
        self.routePoints = routePoints

        // 计算统计数据
        self.totalDistance = Self.calculateTotalDistance(from: routePoints)
        self.averageSpeed = Self.calculateAverageSpeed(from: routePoints, duration: endTime.timeIntervalSince(startTime))
        self.maxSpeed = Self.calculateMaxSpeed(from: routePoints)
    }

    /// 计算轨迹统计信息
    var statistics: RouteStatistics {
        return RouteStatistics(from: routePoints, duration: duration)
    }

    /// 运动持续时间
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }

    /// 计算总距离
    private static func calculateTotalDistance(from points: [RoutePoint]) -> Double {
        guard points.count >= 2 else { return 0 }

        var totalDistance: Double = 0
        for i in 1..<points.count {
            totalDistance += points[i-1].distance(to: points[i])
        }
        return totalDistance / 1000.0  // 转换为公里
    }

    /// 计算平均速度
    private static func calculateAverageSpeed(from points: [RoutePoint], duration: TimeInterval) -> Double {
        let totalDistance = calculateTotalDistance(from: points) * 1000  // 转换为米
        guard duration > 0 else { return 0 }
        return totalDistance / duration  // m/s
    }

    /// 计算最大速度
    private static func calculateMaxSpeed(from points: [RoutePoint]) -> Double {
        return points.compactMap { $0.speed }.max() ?? 0
    }
}

// MARK: - 轨迹统计信息
struct RouteStatistics: Codable {
    let totalDistance: Double      // 总距离（公里）
    let duration: TimeInterval     // 持续时间（秒）
    let averageSpeed: Double       // 平均速度（m/s）
    let maxSpeed: Double          // 最大速度（m/s）
    let averagePace: Double       // 平均配速（分钟/公里）
    let bestPace: Double          // 最佳配速（分钟/公里）
    let elevationGain: Double     // 累计爬升（米）
    let elevationLoss: Double     // 累计下降（米）
    let pointCount: Int           // 轨迹点数量

    init(from routePoints: [RoutePoint], duration: TimeInterval) {
        self.duration = duration
        self.pointCount = routePoints.count

        // 计算距离
        self.totalDistance = Self.calculateTotalDistance(from: routePoints)

        // 计算速度
        let speeds = routePoints.compactMap { $0.speed }
        self.averageSpeed = speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count)
        self.maxSpeed = speeds.max() ?? 0

        // 计算配速
        self.averagePace = averageSpeed > 0 ? 1000 / (averageSpeed * 60) : 0
        self.bestPace = maxSpeed > 0 ? 1000 / (maxSpeed * 60) : 0

        // 计算海拔变化
        let elevationData = Self.calculateElevationChanges(from: routePoints)
        self.elevationGain = elevationData.gain
        self.elevationLoss = elevationData.loss
    }

    /// 计算总距离
    private static func calculateTotalDistance(from points: [RoutePoint]) -> Double {
        guard points.count >= 2 else { return 0 }

        var totalDistance: Double = 0
        for i in 1..<points.count {
            totalDistance += points[i-1].distance(to: points[i])
        }
        return totalDistance / 1000.0  // 转换为公里
    }

    /// 计算海拔变化
    private static func calculateElevationChanges(from points: [RoutePoint]) -> (gain: Double, loss: Double) {
        let altitudes = points.compactMap { $0.altitude }
        guard altitudes.count >= 2 else { return (0, 0) }

        var gain: Double = 0
        var loss: Double = 0

        for i in 1..<altitudes.count {
            let diff = altitudes[i] - altitudes[i-1]
            if diff > 0 {
                gain += diff
            } else {
                loss += abs(diff)
            }
        }

        return (gain, loss)
    }

    /// 格式化的总距离
    var formattedDistance: String {
        return String(format: "%.2f km", totalDistance)
    }

    /// 格式化的持续时间
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// 格式化的平均配速
    var formattedAveragePace: String {
        guard averagePace > 0 && averagePace.isFinite else { return "--'--\"" }
        let minutes = Int(averagePace)
        let seconds = Int((averagePace - Double(minutes)) * 60)
        return String(format: "%d'%02d\"", minutes, seconds)
    }
}

// MARK: - Simple Plan List Data
struct SimplePlanListData: Codable {
    let plans: [Plan]
    let totalCount: Int
    let currentPage: Int
    let totalPages: Int

    init(plans: [Plan] = [], totalCount: Int = 0, currentPage: Int = 1, totalPages: Int = 1) {
        self.plans = plans
        self.totalCount = totalCount
        self.currentPage = currentPage
        self.totalPages = totalPages
    }
}

// MARK: - Plan List Response (Server Format)
struct PlanListServerResponse: Codable {
    let status: String
    let message: String?
    let data: PlanListServerData

    var success: Bool {
        return status == "success"
    }

    var displayMessage: String {
        return message ?? (success ? "获取成功" : "获取失败")
    }
}

struct PlanListServerData: Codable {
    let plans: [PlanNew]
    let pagination: PlanPaginationServerInfo
}

struct PlanPaginationServerInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalPlans: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
}
