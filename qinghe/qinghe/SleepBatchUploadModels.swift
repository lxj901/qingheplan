import Foundation
import UIKit

// MARK: - 睡眠批量上传请求模型（新接口 - AI分析）

/// 睡眠会话批量上传请求
struct SleepBatchUploadRequest: Codable {
    let sleepSession: SleepSessionData
    let audioSegments: [AudioSegmentData]?
    let sensorData: [SensorDataPoint]?
    let sleepEvents: [SleepEventData]?
    let wakeupData: WakeupData?
    
    /// 睡眠会话基本信息
    struct SleepSessionData: Codable {
        let localSessionId: String
        let startTime: String  // ISO 8601 格式
        let endTime: String    // ISO 8601 格式
        let targetWakeTime: String?
        let targetDuration: Int?  // 分钟
        let deviceInfo: DeviceInfo?
        let environmentData: EnvironmentData?
        let userNotes: String?
        
        struct DeviceInfo: Codable {
            let deviceType: String
            let appVersion: String
            let osVersion: String
            let deviceId: String?
        }
        
        struct EnvironmentData: Codable {
            let temperature: Double?
            let humidity: Int?
            let noiseLevel: Int?
            let lightLevel: Int?
        }
    }
    
    /// 音频片段信息
    struct AudioSegmentData: Codable {
        let localFileId: String
        let fileName: String
        let fileSize: Int
        let duration: Int
        let timestamp: String  // ISO 8601 格式
        let checksum: String?
        let audioType: String?  // "snoring", "sleep_talk", "movement", "other" (可选，服务器端分析)
        let confidence: Double?
        let intensity: Double?
    }
    
    /// 传感器数据点
    struct SensorDataPoint: Codable {
        let timestamp: String  // ISO 8601 格式
        let heartRate: Int?
        let movement: Double?
        let soundLevel: Double?
        let deviceOrientation: String?
    }
    
    /// 睡眠事件
    struct SleepEventData: Codable {
        let eventType: String  // "snoring", "sleep_talk", "movement", "wakeup"
        let timestamp: String  // ISO 8601 格式
        let duration: Int?
        let intensity: Double?
        let audioFileId: String?
    }
    
    /// 醒来数据
    struct WakeupData: Codable {
        let wakeupMethod: String  // "natural", "alarm", "external"
        let sleepQualityRating: Int?  // 1-10
        let mood: String?  // "refreshed", "tired", "groggy", "normal"
        let dreamRecall: Bool?
        let notes: String?
    }
}

// MARK: - 睡眠批量上传响应模型

/// 睡眠批量上传响应
struct SleepBatchUploadResponse: Codable {
    let status: String
    let message: String?
    let data: SleepBatchUploadData
    
    var success: Bool {
        return status == "success"
    }
    
    struct SleepBatchUploadData: Codable {
        let sessionId: Int
        let uploadId: String
        let processingStatus: String  // "queued", "processing", "completed", "failed"
        let estimatedProcessingTime: Int?  // 秒
        let audioUploadUrls: [AudioUploadUrl]?
        
        struct AudioUploadUrl: Codable {
            let localFileId: String
            let uploadUrl: String
            let expiresAt: String?
            let ossKey: String
        }
    }
}

// MARK: - 处理状态查询响应

/// 处理状态查询响应
struct ProcessingStatusResponse: Codable {
    let status: String
    let data: ProcessingStatusData

    var success: Bool {
        return status == "success"
    }

    struct ProcessingStatusData: Codable {
        let uploadId: String
        let sessionId: Int?  // 修复：改为可选，因为服务器可能不返回此字段
        let processingStatus: String  // "pending", "queued", "processing", "completed", "failed"
        let progress: Int  // 0-100
        let currentStep: String?
        let message: String?
        let completedAt: String?
        let estimatedTimeRemaining: Int?
        let reportAvailable: Bool?  // 新增：报告是否可用
        let stages: ProcessingStages?  // 新增：处理阶段信息

        struct ProcessingStages: Codable {
            let dataValidation: String?  // "pending", "processing", "completed", "failed"
            let audioProcessing: String?
            let aiAnalysis: String?
            let reportGeneration: String?
        }
    }
}

// MARK: - 辅助扩展

extension SleepBatchUploadRequest {
    /// 从本地睡眠会话创建批量上传请求
    static func from(localSession: LocalSleepSession, audioFiles: [LocalAudioFile] = []) -> SleepBatchUploadRequest {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // 创建睡眠会话数据
        let sleepSession = SleepSessionData(
            localSessionId: localSession.sessionId,
            startTime: dateFormatter.string(from: localSession.startTime),
            endTime: localSession.endTime.map { dateFormatter.string(from: $0) } ?? dateFormatter.string(from: Date()),
            targetWakeTime: nil,
            targetDuration: localSession.endTime.map { Int(($0.timeIntervalSince(localSession.startTime)) / 60) },
            deviceInfo: SleepSessionData.DeviceInfo(
                deviceType: UIDevice.current.model,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
                osVersion: UIDevice.current.systemVersion,
                deviceId: UIDevice.current.identifierForVendor?.uuidString
            ),
            environmentData: nil,
            userNotes: localSession.userNotes
        )
        
        // 创建音频片段数据
        // 注意：LocalAudioFile 只包含基本的音频文件信息，不包含事件类型等分析结果
        // 这些信息会在服务器端通过AI分析生成
        let audioSegments: [AudioSegmentData]? = audioFiles.isEmpty ? nil : audioFiles.map { audioFile in
            AudioSegmentData(
                localFileId: audioFile.id.uuidString,
                fileName: audioFile.fileName,
                fileSize: Int(audioFile.fileSize),  // Int64 转 Int
                duration: Int(audioFile.duration),
                timestamp: dateFormatter.string(from: audioFile.recordingDate),
                checksum: nil,
                audioType: nil,  // 服务器端分析
                confidence: nil,  // 服务器端分析
                intensity: nil   // 服务器端分析
            )
        }
        
        return SleepBatchUploadRequest(
            sleepSession: sleepSession,
            audioSegments: audioSegments,
            sensorData: nil,
            sleepEvents: nil,
            wakeupData: nil
        )
    }
}

// MARK: - LocalAudioFile 扩展

extension LocalAudioFile {
    /// 获取音频文件的实际数据
    func getFileData() throws -> Data {
        let fileURL = URL(fileURLWithPath: filePath)
        return try Data(contentsOf: fileURL)
    }
}

