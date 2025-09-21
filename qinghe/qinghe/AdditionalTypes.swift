import Foundation
import SwiftUI
import CoreLocation
import AVFoundation
import Combine

// MARK: - Checkin Related Types

struct CheckinResponseNew: Codable {
    let success: Bool
    let message: String
    let data: CheckinDataNew?
}

struct CheckinDataNew: Codable {
    let id: Int
    let userId: Int
    let timestamp: Date
    let location: String?
    let mood: String?
    let notes: String?

    // 添加date字段作为timestamp的别名
    var date: Date {
        return timestamp
    }
}

struct TodayCheckinResponseNew: Codable {
    let success: Bool
    let hasCheckedIn: Bool
    let checkinTime: Date?
    let streak: Int
}

struct SimpleTodayStatusData: Codable {
    let hasCheckedIn: Bool
    let checkinTime: Date?
    let streak: Int
    let mood: String?
}

struct CheckinStatisticsResponseNew: Codable {
    let success: Bool
    let data: CheckinStatisticsDataNew
}

struct CheckinStatisticsDataNew: Codable {
    let totalCheckins: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageCheckinTime: String
    let weeklyStats: [WeeklyCheckinData]
    let monthlyStats: [MonthlyCheckinStats]
}

struct WeeklyCheckinData: Identifiable, Codable {
    let id = UUID()
    let week: String
    let checkinCount: Int
    let averageTime: String
    
    // 添加兼容字段
    var dayName: String {
        return week
    }
    
    var count: Int {
        return checkinCount
    }
}

struct MonthlyCheckinStats: Codable {
    let month: String
    let checkinCount: Int
    let streakDays: Int
}

struct NewCheckinStatsResponse: Codable {
    let totalCheckins: Int
    let currentStreak: Int
    let longestStreak: Int
    let weeklyData: [WeeklyCheckinData]
    
    // 添加data属性以兼容API访问
    var data: ActualCheckinStatsData? {
        return ActualCheckinStatsData(
            totalCheckins: totalCheckins,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            averageTime: "09:00",
            weeklyData: weeklyData,
            heatmapData: [],
            totalDays: totalCheckins,
            consecutiveDays: currentStreak,
            thisMonthDays: 0
        )
    }
}

struct CheckinListResponseNew: Codable {
    let success: Bool
    let data: [CheckinDataNew]
    let totalCount: Int
    let currentPage: Int
}

struct SimpleCheckinHistoryData: Codable {
    let checkins: [CheckinDataNew]
    let totalCount: Int
    let hasMore: Bool
    let pagination: CheckinPaginationInfo
}

struct CheckinPaginationInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalCheckins: Int
    
    init(currentPage: Int, totalPages: Int, totalCheckins: Int) {
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.totalCheckins = totalCheckins
    }
}

struct CheckinHeatmapData: Codable {
    let date: String
    let count: Int
    let intensity: Double
}

struct HourlyCheckinData: Identifiable, Codable {
    let id = UUID()
    let hour: Int
    let count: Int
    let percentage: Double
    
    init(hour: Int, count: Int, percentage: Double = 0.0) {
        self.hour = hour
        self.count = count
        self.percentage = percentage
    }
}

struct ActualCheckinStatsData: Codable {
    let totalCheckins: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageTime: String
    let weeklyData: [WeeklyCheckinData]
    let heatmapData: [CheckinHeatmapData]
    
    // 添加缺少的字段
    let totalDays: Int
    let consecutiveDays: Int
    let thisMonthDays: Int
    let monthlyDays: Int
    let timeAnalysis: ActualTimeAnalysisData?
    
    init(totalCheckins: Int, currentStreak: Int, longestStreak: Int, averageTime: String, weeklyData: [WeeklyCheckinData], heatmapData: [CheckinHeatmapData], totalDays: Int, consecutiveDays: Int, thisMonthDays: Int, monthlyDays: Int = 0, timeAnalysis: ActualTimeAnalysisData? = nil) {
        self.totalCheckins = totalCheckins
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.averageTime = averageTime
        self.weeklyData = weeklyData
        self.heatmapData = heatmapData
        self.totalDays = totalDays
        self.consecutiveDays = consecutiveDays
        self.thisMonthDays = thisMonthDays
        self.monthlyDays = monthlyDays
        self.timeAnalysis = timeAnalysis
    }
}

// MARK: - Audio Analysis Types
struct AudioAnalysisResponse: Codable {
    let id: Int
    let fileName: String
    let status: String
    let progress: Double
    let segments: [AudioAnalysisSegment]?
    let summary: AudioSegmentsSummary?
}

struct AudioAnalysisSegment: Identifiable, Codable {
    let id = UUID()
    let startTime: TimeInterval
    let endTime: TimeInterval
    let type: String
    let confidence: Double
    let intensity: Double?
    
    init(startTime: TimeInterval, endTime: TimeInterval, type: String, confidence: Double, intensity: Double? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.confidence = confidence
        self.intensity = intensity
    }
}

struct AudioSegmentsSummary: Codable {
    let totalSegments: Int
    let totalDuration: TimeInterval
    let segmentTypes: [String: Int]
    let averageConfidence: Double
}

struct AudioFilesResponse: Codable {
    let success: Bool
    let message: String
    let data: [AudioFileInfo]
    let totalCount: Int
    let currentPage: Int
    let totalPages: Int

    // 为了兼容性，添加一个计算属性
    var files: [AudioFileInfo] {
        return data
    }
}

// MARK: - 音频片段相关模型
// 注意：AudioSegmentInfo, AudioSegmentsResponse, SegmentSummary, Pagination 已在 SleepAPIComplexTypes.swift 中定义

// AudioFileInfo is already defined in SleepDataModels.swift, so we don't redefine it here

// MARK: - Audio API Types
struct AudioFileReference: Codable {
    let fileId: Int
    let fileName: String
    let duration: Double

    init(fileId: Int, fileName: String, duration: Double) {
        self.fileId = fileId
        self.fileName = fileName
        self.duration = duration
    }
}

struct AudioSegmentInfoAPI: Identifiable, Codable {
    let id = UUID()
    let segmentId: Int
    let type: String
    let typeName: String
    let description: String
    let color: String
    let startTime: String
    let endTime: String
    let duration: Double
    let confidence: Double
    let intensity: Double
    let priority: Int
    let isHighlighted: Bool
    let playCount: Int
    let accessUrl: String
    let fileSize: Int64
    let metadata: [String: String]
    let audioFile: AudioFileReference
    let createdAt: String
    let sessionId: Int
    let timestamp: String
    let fileName: String

    init(
        segmentId: Int,
        type: String,
        typeName: String,
        description: String,
        color: String,
        startTime: String,
        endTime: String,
        duration: Double,
        confidence: Double,
        intensity: Double,
        priority: Int,
        isHighlighted: Bool,
        playCount: Int,
        accessUrl: String,
        fileSize: Int64,
        metadata: [String: String],
        audioFile: AudioFileReference,
        createdAt: String,
        sessionId: Int,
        timestamp: String,
        fileName: String
    ) {
        self.segmentId = segmentId
        self.type = type
        self.typeName = typeName
        self.description = description
        self.color = color
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.confidence = confidence
        self.intensity = intensity
        self.priority = priority
        self.isHighlighted = isHighlighted
        self.playCount = playCount
        self.accessUrl = accessUrl
        self.fileSize = fileSize
        self.metadata = metadata
        self.audioFile = audioFile
        self.createdAt = createdAt
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.fileName = fileName
    }
}

// MARK: - Network and API Types
struct ServerAPIResponse<T: Codable>: Codable {
    let status: String
    let message: String?
    let data: T?
    let error: String?

    var success: Bool {
        return status == "success"
    }

    // 添加displayMessage作为message的别名
    var displayMessage: String {
        return message ?? (success ? "操作成功" : "操作失败")
    }

    init(status: String, message: String? = nil, data: T? = nil, error: String? = nil) {
        self.status = status
        self.message = message
        self.data = data
        self.error = error
    }

    // 为了向后兼容，添加一个使用 success 参数的初始化器
    init(success: Bool, message: String? = nil, data: T? = nil, error: String? = nil) {
        self.status = success ? "success" : "error"
        self.message = message
        self.data = data
        self.error = error
    }
}

// APIError is already defined in another file, so we don't redefine it here

enum NetworkError: Error {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case decodingError
    case networkFailure(String)
    
    var localizedDescription: String {
        switch self {
        case .noConnection:
            return "无网络连接"
        case .timeout:
            return "请求超时"
        case .serverError(let code):
            return "服务器错误 (\(code))"
        case .invalidResponse:
            return "无效响应"
        case .decodingError:
            return "数据解析错误"
        case .networkFailure(let message):
            return "网络错误: \(message)"
        }
    }
}

// MARK: - Location Types
struct AddressSearchResult {
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let address: String

    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D, address: String) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.address = address
    }
}

// MARK: - Manager Classes
// MARK: - 数据源和质量枚举
enum DataSource: String {
    case healthKit = "HealthKit"
    case appleWatch = "Apple Watch"
    case simulation = "Simulation"
    case gps = "GPS"

    var icon: String {
        switch self {
        case .healthKit:
            return "heart.fill"
        case .appleWatch:
            return "applewatch"
        case .simulation:
            return "cpu"
        case .gps:
            return "location.fill"
        }
    }
}

enum DataQuality: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .poor:
            return .red
        }
    }
}




class WorkoutCameraManager: ObservableObject {
    static let shared = WorkoutCameraManager()
    
    @Published var isRecording = false
    @Published var photos: [WorkoutPhotoData] = []
    @Published var isFlashOn = false
    @Published var isSessionActive = false
    
    private init() {}
    
    func startSession() {
        isSessionActive = true
        print("📸 相机会话已启动")
    }
    
    func stopSession() {
        isSessionActive = false
        print("📸 相机会话已停止")
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
        print("📸 闪光灯状态: \(isFlashOn ? "开" : "关")")
    }
    
    func switchCamera() {
        print("📸 切换前后摄像头")
        // Mock implementation
    }
    
    func takePhoto() -> WorkoutPhotoData? {
        // Mock implementation
        guard let imageData = UIImage(systemName: "camera")?.pngData() else { return nil }
        let photo = WorkoutPhotoData(
            imageData: imageData,
            timestamp: Date(),
            location: nil,
            workoutId: nil
        )
        photos.append(photo)
        return photo
    }
}

class BluetoothDeviceManager: ObservableObject {
    static let shared = BluetoothDeviceManager()

    @Published var isConnected = false
    @Published var connectedDevices: [String] = []
    @Published var isBluetoothEnabled = true
    @Published var discoveredDevices: [WearableDevice] = []

    private init() {}

    func scanForDevices() {
        // Mock implementation
        connectedDevices = ["Apple Watch", "Heart Rate Monitor"]
        isConnected = true
    }

    func startScanning() {
        // Mock implementation for scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.discoveredDevices = [
                WearableDevice(id: "1", name: "Apple Watch", type: .watch, isConnected: true),
                WearableDevice(id: "2", name: "Heart Rate Monitor", type: .heartRate, isConnected: false)
            ]
        }
    }
}

// MARK: - Watch Connectivity Manager
class WatchConnectivityManager: ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isWatchConnected = false
    @Published var watchInfo: WatchInfo?

    private init() {}

    func checkWatchConnection() {
        // Mock implementation
        isWatchConnected = true
        watchInfo = WatchInfo(name: "Apple Watch", batteryLevel: 85, isCharging: false)
    }
}

// MARK: - Wearable Device Types
struct WearableDevice: Identifiable {
    let id: String
    let name: String
    let type: DeviceType
    var isConnected: Bool
    var batteryLevel: Int?

    enum DeviceType {
        case watch
        case heartRate
        case fitness

        var displayName: String {
            switch self {
            case .watch: return "智能手表"
            case .heartRate: return "心率监测器"
            case .fitness: return "健身设备"
            }
        }
    }
}

struct WatchInfo {
    let name: String
    let batteryLevel: Int
    let isCharging: Bool
}

// MARK: - Emotion Types
struct EmotionListData: Codable {
    let emotions: [EmotionRecord]
    let pagination: EmotionPagination
}

struct EmotionRecord: Codable, Identifiable {
    let id: Int
    let userId: Int
    let type: String
    let intensity: Int
    let note: String?
    let tags: [String]?
    let trigger: String?
    let recordedAt: String
    let createdAt: String
    let updatedAt: String
}

struct EmotionPagination: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalEmotions: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
}

struct EmotionStatistics: Codable {
    let totalRecords: Int
    let averageIntensity: Double
    let emotionDistribution: [String: Int]
    let intensityDistribution: [String: Int]
    let weeklyTrend: [EmotionWeeklyTrend]
    let healthScore: Int
}

struct EmotionWeeklyTrend: Codable {
    let week: String
    let averageIntensity: Double
    let recordCount: Int
    let totalRecords: Int
    let dominantEmotion: String

    // 为了兼容性，提供默认值
    init(week: String, averageIntensity: Double = 0.0, recordCount: Int = 0, totalRecords: Int = 0, dominantEmotion: String = "") {
        self.week = week
        self.averageIntensity = averageIntensity
        self.recordCount = recordCount
        self.totalRecords = totalRecords
        self.dominantEmotion = dominantEmotion
    }
}

struct EmotionListResponse: Codable {
    let success: Bool
    let message: String?
    let data: EmotionListData
}

struct EmotionStatisticsResponse: Codable {
    let success: Bool
    let message: String?
    let data: EmotionStatistics
}

// MARK: - Request Models
struct EmotionRequestNew: Codable {
    let type: String
    let intensity: Int
    let note: String?
    let tags: [String]?
    let trigger: String?
    let recordTime: String?
}

struct TemptationRequestNew: Codable {
    let type: String
    let intensity: Int
    let result: String
    let note: String?
    let strategies: [String]?
    let recordTime: String?

    enum CodingKeys: String, CodingKey {
        case type, intensity, result, note, strategies, recordTime
    }
}

// MARK: - Response Models
struct EmotionNew: Codable, Identifiable {
    let id: Int
    let userId: Int
    let type: String
    let intensity: Int
    let note: String?
    let tags: [String]?
    let trigger: String?
    let recordedAt: String
    let createdAt: String
    let updatedAt: String
}

struct TemptationNew: Codable, Identifiable {
    let id: Int
    let userId: Int
    let type: String
    let intensity: Int
    let resisted: Bool
    let strategy: String?
    let environment: String?
    let duration: Int
    let note: String?
    let recordedAt: String
    let createdAt: String
    let updatedAt: String
}

// MARK: - Temptation Data Models
struct TemptationListData: Codable {
    let temptations: [TemptationNew]
    let pagination: TemptationPagination
}

struct TemptationPagination: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalTemptations: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
}

struct TemptationStatistics: Codable {
    let totalCount: Int
    let resistedCount: Int
    let resistanceRate: Double
    let commonTypes: [String]
    let effectiveStrategies: [String]
    let weeklyTrend: [WeeklyTrendData]
}

struct WeeklyTrendData: Codable {
    let week: String
    let totalCount: Int
    let resistedCount: Int
}

// MARK: - Pagination Info
// PaginationInfo 已在 CommunityModels.swift 中定义，这里不重复定义

// MARK: - Standard API Response (deprecated)
@available(*, deprecated, message: "请使用ServerAPIResponse<T>以匹配后端API规范")
struct StandardAPIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String
    let data: T?
    let timestamp: String?
    let code: Int?

    enum CodingKeys: String, CodingKey {
        case success, message, data, timestamp, code
    }
}

// MARK: - API Services
class QingheAPIService {
    static let shared = QingheAPIService()

    private init() {}

    func uploadWorkout(_ workout: QingheWorkout) async throws {
        // Mock implementation
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    // 添加缺失的API方法
    func sendSMSCode(phone: String) async throws -> ServerAPIResponse<EmptyData> {
        // Mock implementation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return ServerAPIResponse(success: true, message: "验证码已发送", data: EmptyData(), error: nil)
    }
    
    func loginWithSMS(phone: String, code: String) async throws -> ServerAPIResponse<EmptyData> {
        // Mock implementation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return ServerAPIResponse(success: true, message: "登录成功", data: EmptyData(), error: nil)
    }
    
    func getWorkouts(page: Int = 1, limit: Int = 20) async throws -> ServerAPIResponse<[QingheWorkout]> {
        // Mock implementation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return ServerAPIResponse(success: true, message: "获取成功", data: [], error: nil)
    }
    
    func getWorkoutStatistics() async throws -> ServerAPIResponse<EmptyData> {
        // Mock implementation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return ServerAPIResponse(success: true, message: "获取成功", data: EmptyData(), error: nil)
    }
}

class SleepAPIManager {
    static let shared = SleepAPIManager()

    private init() {}

    func uploadAudioFile(_ fileData: Data) async throws -> AudioAnalysisResponse {
        // Mock implementation
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return AudioAnalysisResponse(
            id: 1,
            fileName: "sleep_audio.m4a",
            status: "completed",
            progress: 1.0,
            segments: [],
            summary: nil
        )
    }
    
    // 添加缺失的方法
    func getAudioUploadCredentialsAsync(_ request: Any) async throws -> Any {
        // Mock implementation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return ["status": "success", "credentials": ["accessKey": "mock"]]
    }

    // MARK: - 音频文件获取方法

    /// 获取指定会话的音频文件
    /// - Parameters:
    ///   - sessionId: 会话ID
    ///   - limit: 限制数量
    ///   - offset: 偏移量
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 音频文件响应的Publisher
    func getSessionAudioFiles(
        sessionId: Int64,
        limit: Int = 20,
        offset: Int = 0,
        startDate: String? = nil,
        endDate: String? = nil
    ) -> AnyPublisher<AudioFilesResponse, Error> {
        // Mock implementation - 返回模拟数据
        let mockFiles = generateMockAudioFiles(for: Int(sessionId), count: min(limit, 5))
        let response = AudioFilesResponse(
            success: true,
            message: "获取音频文件成功",
            data: mockFiles,
            totalCount: mockFiles.count,
            currentPage: offset / limit + 1,
            totalPages: 1
        )

        return Just(response)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// 获取所有音频文件
    /// - Parameters:
    ///   - limit: 限制数量
    ///   - offset: 偏移量
    /// - Returns: 音频文件响应的Publisher
    func getAudioFiles(limit: Int = 20, offset: Int = 0) -> AnyPublisher<AudioFilesResponse, Error> {
        // Mock implementation - 返回模拟数据
        let mockFiles = generateMockAudioFiles(for: nil, count: min(limit, 10))
        let response = AudioFilesResponse(
            success: true,
            message: "获取音频文件成功",
            data: mockFiles,
            totalCount: mockFiles.count,
            currentPage: offset / limit + 1,
            totalPages: 1
        )

        return Just(response)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// 获取音频片段
    /// - Parameter sessionId: 会话ID
    /// - Returns: 音频片段响应的Publisher
    func getAudioSegments(sessionId: Int) -> AnyPublisher<Result<[AudioSegmentInfoAPI], Error>, Never> {
        // Mock implementation
        let mockSegments = generateMockAudioSegments(for: sessionId)
        
        let result = Result<[AudioSegmentInfoAPI], Error>.success(mockSegments)
        return Just(result)
            .delay(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - 私有辅助方法

    private func generateMockAudioFiles(for sessionId: Int?, count: Int) -> [AudioFileInfo] {
        var files: [AudioFileInfo] = []

        for i in 0..<count {
            let targetSessionId = sessionId ?? Int.random(in: 1...10)
            let file = AudioFileInfo(
                fileName: "sleep_audio_session_\(targetSessionId)_\(i + 1).m4a",
                filePath: "/mock/path/audio_\(i + 1).m4a",
                duration: TimeInterval.random(in: 1800...7200), // 30分钟到2小时
                fileSize: Int64.random(in: 1024000...10240000), // 1MB到10MB
                uploadTime: Date().addingTimeInterval(-TimeInterval.random(in: 0...86400)), // 过去24小时内
                processingStatus: "completed",
                analysisStatus: "completed",
                downloadUrl: "https://mock.api.com/audio/\(i + 1).m4a",
                sessionId: targetSessionId
            )
            files.append(file)
        }

        return files
    }

    private func generateMockAudioSegments(for sessionId: Int) -> [AudioSegmentInfoAPI] {
        var segments: [AudioSegmentInfoAPI] = []
        let segmentTypes = ["呼吸声", "翻身声", "环境音", "静音"]
        let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA726"]

        for i in 0..<5 {
            let startTime = i * 600 // 每10分钟一个片段
            let endTime = startTime + Int.random(in: 300...600)
            let segmentType = segmentTypes.randomElement() ?? "未知"
            
            let audioFileRef = AudioFileReference(
                fileId: sessionId,
                fileName: "sleep_audio_session_\(sessionId).m4a",
                duration: Double(endTime - startTime)
            )

            let segment = AudioSegmentInfoAPI(
                segmentId: i + 1,
                type: segmentType,
                typeName: segmentType,
                description: "模拟音频片段 \(i + 1)",
                color: colors[i % colors.count],
                startTime: String(startTime),
                endTime: String(endTime),
                duration: Double(endTime - startTime),
                confidence: Double.random(in: 0.7...0.95),
                intensity: Double.random(in: 0.1...1.0),
                priority: i + 1,
                isHighlighted: i < 2,
                playCount: Int.random(in: 0...5),
                accessUrl: "https://mock.api.com/segment/\(i + 1).m4a",
                fileSize: Int64.random(in: 100000...1000000),
                metadata: ["quality": "high", "channel": "mono"],
                audioFile: audioFileRef,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                sessionId: sessionId,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                fileName: "segment_\(i + 1).m4a"
            )
            segments.append(segment)
        }

        return segments
    }
}

// MARK: - Workout Screen Lock Manager
class WorkoutScreenLockManager: ObservableObject {
    static let shared = WorkoutScreenLockManager()

    @Published var isScreenLocked = false
    @Published var autoLockEnabled = true
    @Published var autoLockDelay: TimeInterval = 300 // 5 minutes
    @Published var showDataInLockScreen = true
    @Published var allowCameraInLockScreen = false

    private var lockTimer: Timer?

    private init() {}

    func lockScreen() {
        isScreenLocked = true
        print("🔒 屏幕已锁定")
    }

    func unlockScreen() {
        isScreenLocked = false
        resetAutoLockTimer()
        print("🔓 屏幕已解锁")
    }

    func resetAutoLockTimer() {
        lockTimer?.invalidate()
        if autoLockEnabled {
            lockTimer = Timer.scheduledTimer(withTimeInterval: autoLockDelay, repeats: false) { _ in
                self.lockScreen()
            }
        }
    }
    
    func updateLastInteractionTime() {
        resetAutoLockTimer()
    }
}



struct LockScreenData {
    let elapsedTime: TimeInterval
    let distance: Double
    let pace: String
    let heartRate: Int
    let calories: Int
    let workoutType: String
}

// MARK: - Extended Workout Photo Data (for KeepStyleWorkoutLiveView)
struct ExtendedWorkoutPhotoData: Codable {
    let workoutType: String
    let distance: Double
    let duration: TimeInterval
    let pace: String
    let heartRate: Int
    let calories: Int
    let location: CodableLocationCoordinate?
    let timestamp: Date

    init(workoutType: String, distance: Double, duration: TimeInterval, pace: String, heartRate: Int, calories: Int, location: CLLocationCoordinate2D?, timestamp: Date) {
        self.workoutType = workoutType
        self.distance = distance
        self.duration = duration
        self.pace = pace
        self.heartRate = heartRate
        self.calories = calories
        self.location = location.map { CodableLocationCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
        self.timestamp = timestamp
    }
}

// MARK: - Codable Location Coordinate (using the one from SleepDataModels.swift)

// MARK: - Navigation Managers
class NavigationLevelTracker: ObservableObject {
    static let shared = NavigationLevelTracker()

    @Published var currentLevel = 0
    @Published var navigationStack: [String] = []

    init() {}

    func pushLevel(_ identifier: String) {
        currentLevel += 1
        navigationStack.append(identifier)
    }

    func popLevel() {
        if currentLevel > 0 {
            currentLevel -= 1
            navigationStack.removeLast()
        }
    }

    func resetToRoot() {
        currentLevel = 0
        navigationStack.removeAll()
    }
}



// MARK: - Audio Session Manager
class AudioSessionManager: ObservableObject {
    static let shared = AudioSessionManager()

    @Published var isActive = false
    @Published var currentCategory: String = "playback"

    private var activeComponents: Set<String> = []

    private init() {}

    func configureForPlayback() {
        currentCategory = "playback"
        isActive = true
        print("🔊 音频会话配置为播放模式")
    }

    func configureForRecording() {
        currentCategory = "record"
        isActive = true
        print("🎤 音频会话配置为录音模式")
    }

    func deactivate() {
        isActive = false
        activeComponents.removeAll()
        print("🔇 音频会话已停用")
    }

    // MARK: - 新增方法以修复编译错误

    /// 请求音频会话
    /// - Parameters:
    ///   - componentId: 组件ID
    ///   - category: 音频会话类别
    ///   - mode: 音频会话模式
    ///   - options: 音频会话选项
    func requestAudioSession(
        componentId: String,
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) async throws {
        print("🔊 [AudioSessionManager] 请求音频会话: \(componentId)")

        do {
            let audioSession = AVAudioSession.sharedInstance()

            // 设置音频会话类别和选项
            try audioSession.setCategory(category, mode: mode, options: options)
            try audioSession.setActive(true)

            // 记录活跃组件
            activeComponents.insert(componentId)
            isActive = true
            currentCategory = category.rawValue

            print("✅ [AudioSessionManager] 音频会话配置成功: \(componentId)")
        } catch {
            print("❌ [AudioSessionManager] 音频会话配置失败: \(error)")
            throw error
        }
    }

    /// 检查音频会话状态
    /// - Returns: 音频会话状态
    func checkAudioSessionStatus() -> (isActive: Bool, category: String) {
        let audioSession = AVAudioSession.sharedInstance()
        return (isActive: isActive, category: audioSession.category.rawValue)
    }

    /// 释放音频会话
    /// - Parameter componentId: 组件ID
    func releaseAudioSession(componentId: String) async {
        print("🔇 [AudioSessionManager] 释放音频会话: \(componentId)")

        activeComponents.remove(componentId)

        // 如果没有其他组件使用音频会话，则停用
        if activeComponents.isEmpty {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                isActive = false
                print("✅ [AudioSessionManager] 音频会话已停用")
            } catch {
                print("⚠️ [AudioSessionManager] 停用音频会话时出错: \(error)")
            }
        }
    }

    /// 检查指定组件的会话是否活跃
    /// - Parameter componentId: 组件ID
    /// - Returns: 是否活跃
    func isSessionActive(componentId: String) -> Bool {
        return activeComponents.contains(componentId) && isActive
    }
}

// MARK: - Checkin Data Models

struct WeeklyCheckinStat: Codable {
    let week: String
    let checkedDays: Int
    let totalDays: Int
}

struct TodayCheckinStatus: Codable {
    let hasCheckedIn: Bool
    let checkinTime: String?
    let planId: Int?
    let note: String?
}

struct ActualTimeAnalysisData: Codable {
    let averageCheckinTime: String
    let mostActiveHour: Int
    let checkinPattern: [HourlyCheckinData]
    let consistencyScore: Double
    
    // 添加缺少的时段统计字段
    let morningCount: Int
    let afternoonCount: Int
    let eveningCount: Int
    let nightCount: Int
    
    init(averageCheckinTime: String, mostActiveHour: Int, checkinPattern: [HourlyCheckinData], consistencyScore: Double, morningCount: Int = 0, afternoonCount: Int = 0, eveningCount: Int = 0, nightCount: Int = 0) {
        self.averageCheckinTime = averageCheckinTime
        self.mostActiveHour = mostActiveHour
        self.checkinPattern = checkinPattern
        self.consistencyScore = consistencyScore
        self.morningCount = morningCount
        self.afternoonCount = afternoonCount
        self.eveningCount = eveningCount
        self.nightCount = nightCount
    }
}

// HourlyCheckinData is already defined above at line 101-105

struct CheckinHistoryItem: Codable, Identifiable {
    let id: Int
    let date: String
    let status: String
    let note: String?
    let checkinTime: String
    let planName: String
}

// MARK: - API Request Manager
class APIRequestManager: ObservableObject {
    static let shared = APIRequestManager()

    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    func makeRequest<T: Codable>(url: String, method: String = "GET", body: Data? = nil) async throws -> T {
        // Mock implementation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        throw APIError.networkError("Mock implementation")
    }
}

// MARK: - Community Post Types
struct LocalCommunityPost: Identifiable, Codable {
    let id = UUID()
    let userId: String
    let username: String
    let userAvatar: String?
    let content: String
    let images: [String]
    let createdAt: Date
    let likesCount: Int
    let commentsCount: Int
    let isLiked: Bool
    let location: String?
    let tags: [String]

    init(userId: String, username: String, content: String, userAvatar: String? = nil, images: [String] = [], likesCount: Int = 0, commentsCount: Int = 0, isLiked: Bool = false, location: String? = nil, tags: [String] = []) {
        self.userId = userId
        self.username = username
        self.userAvatar = userAvatar
        self.content = content
        self.images = images
        self.createdAt = Date()
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.isLiked = isLiked
        self.location = location
        self.tags = tags
    }
}

// MARK: - Focus and Plan Types
struct FocusStats: Codable {
    let totalFocusTime: TimeInterval
    let averageFocusTime: TimeInterval
    let focusSessionsCount: Int
    let longestFocusSession: TimeInterval
    let focusStreak: Int
    let weeklyFocusTime: TimeInterval
    let monthlyFocusTime: TimeInterval

    init(totalFocusTime: TimeInterval = 0, averageFocusTime: TimeInterval = 0, focusSessionsCount: Int = 0, longestFocusSession: TimeInterval = 0, focusStreak: Int = 0, weeklyFocusTime: TimeInterval = 0, monthlyFocusTime: TimeInterval = 0) {
        self.totalFocusTime = totalFocusTime
        self.averageFocusTime = averageFocusTime
        self.focusSessionsCount = focusSessionsCount
        self.longestFocusSession = longestFocusSession
        self.focusStreak = focusStreak
        self.weeklyFocusTime = weeklyFocusTime
        self.monthlyFocusTime = monthlyFocusTime
    }
}

struct TodayPlan: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let priority: String
    let isCompleted: Bool
    let completedAt: Date?
    let dueTime: Date?
    let estimatedDuration: TimeInterval?

    init(title: String, description: String, category: String, priority: String = "medium", isCompleted: Bool = false, completedAt: Date? = nil, dueTime: Date? = nil, estimatedDuration: TimeInterval? = nil) {
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.dueTime = dueTime
        self.estimatedDuration = estimatedDuration
    }
}

struct SimplePlan: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let status: String
    let progress: Double
    let startDate: Date
    let endDate: Date
    let isActive: Bool

    init(title: String, description: String, category: String, status: String = "active", progress: Double = 0.0, startDate: Date = Date(), endDate: Date, isActive: Bool = true) {
        self.title = title
        self.description = description
        self.category = category
        self.status = status
        self.progress = progress
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
    }
}



// MARK: - API Response Types
struct APIErrorResponse: Codable {
    let status: String
    let message: String
    let details: [String]?
    
    init(status: String, message: String, details: [String]? = nil) {
        self.status = status
        self.message = message
        self.details = details
    }
}

struct HealthCheckResponse: Codable {
    let status: String
    let message: String
    let timestamp: String
    let uptime: Double
    let environment: String
    let version: String
    
    init(status: String, message: String, timestamp: String, uptime: Double, environment: String, version: String) {
        self.status = status
        self.message = message
        self.timestamp = timestamp
        self.uptime = uptime
        self.environment = environment
        self.version = version
    }
}

struct EmptyData: Codable {
    // 空数据结构，用于不需要返回数据的API响应
}

/// 账户注销申请响应数据
struct DeletionRequestData: Codable {
    let requestedAt: String
    let scheduledAt: String
    let remainingDays: Int
}

/// 账户注销状态响应数据
struct DeletionStatusData: Codable {
    let status: String
}

// MARK: - App Theme
struct AppTheme {
    static let primaryGradientStart = Color.blue
    static let primaryGradientEnd = Color.purple
    static let primaryColor = Color.blue
    static let secondaryColor = Color.gray
    static let accentColor = Color.green
    static let accentBlue = Color.blue
    static let accentOrange = Color.orange
    static let backgroundColor = Color(.systemBackground)
    static let surfaceColor = Color(.secondarySystemBackground)
    
    // 文本颜色
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    
    // 卡片阴影
    static let cardShadow = Color.black.opacity(0.1)
    
    // 私有初始化，防止实例化
    private init() {}
}



// MARK: - Temptation Response Types
struct TemptationResponseNew: Codable {
    let status: String
    let message: String
    let data: TemptationCreateDataNew?

    var success: Bool {
        return status == "success"
    }

    init(status: String, message: String, data: TemptationCreateDataNew? = nil) {
        self.status = status
        self.message = message
        self.data = data
    }
}

struct TemptationCreateDataNew: Codable {
    let temptation: TemptationNew
}

struct TemptationPaginationInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalTemptations: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
}

struct TemptationListResponse: Codable {
    let status: String
    let message: String?
    let data: TemptationListDataResponse

    var success: Bool {
        return status == "success"
    }

    init(status: String, message: String? = nil, data: TemptationListDataResponse) {
        self.status = status
        self.message = message
        self.data = data
    }
}

struct TemptationListDataResponse: Codable {
    let temptations: [TemptationNew]
    let pagination: TemptationPaginationInfo
}

struct TemptationStatisticsResponse: Codable {
    let status: String
    let message: String
    let data: TemptationStatistics

    var success: Bool {
        return status == "success"
    }

    init(status: String, message: String, data: TemptationStatistics) {
        self.status = status
        self.message = message
        self.data = data
    }
}

struct TemptationUpdateResponseNew: Codable {
    let status: String
    let message: String
    let data: TemptationCreateDataNew?

    var success: Bool {
        return status == "success"
    }

    init(status: String, message: String, data: TemptationCreateDataNew? = nil) {
        self.status = status
        self.message = message
        self.data = data
    }
}



// MARK: - Emotion Response Types
struct EmotionResponseNew: Codable {
    let success: Bool
    let message: String
    let data: EmotionNew?
    
    init(success: Bool, message: String, data: EmotionNew? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
}

// MARK: - Focus Statistics Types
struct FocusDataPoint: Identifiable, Codable {
    let id = UUID()
    let day: String
    let minutes: Int
    
    init(day: String, minutes: Int) {
        self.day = day
        self.minutes = minutes
    }
}
