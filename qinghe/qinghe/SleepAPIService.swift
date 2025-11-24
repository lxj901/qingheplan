import Foundation

// MARK: - 睡眠上传响应模型
struct SleepUploadResponse: Codable {
    let status: String
    let data: SleepUploadData?
    let message: String?
    let error: String?
    
    // 计算属性：判断是否成功
    var success: Bool {
        return status == "success"
    }
    
    struct SleepUploadData: Codable {
        let sleepDate: String
        let sleepSummary: SleepSummary?
        let sleepId: Int?
        let userId: Int?
        let createdAt: String?
        
        struct SleepSummary: Codable {
            let totalRecords: Int
            let averageSleepDuration: Double
            let averageSleepQuality: Double
            let sleepPattern: String
        }
    }
}

// MARK: - 睡眠历史记录响应模型
struct SleepHistoryResponse: Codable {
    let success: Bool
    let data: SleepHistoryData?
    let message: String?
    let error: String?
    
    struct SleepHistoryData: Codable {
        let records: [SleepHistoryRecord]
        let page: Int?
        let limit: Int?
        let total: Int?
    }
}

struct SleepHistoryRecord: Codable {
    let sleepId: Int
    let sleepDate: String
    let startTime: String
    let endTime: String
    let duration: Int
    let quality: Double
    let deepSleepDuration: Int?
    let lightSleepDuration: Int?
    let remSleepDuration: Int?
    let awakeDuration: Int?
    let createdAt: String
}

// MARK: - 体质分析模型（用于睡眠详情视图）
struct ConstitutionAnalysis: Codable {
    let hasAnalysis: Bool?
    let primaryConstitution: String?
    let confidence: Double?
}

// MARK: - 睡眠API服务
final class SleepAPIService {
    static let shared = SleepAPIService()
    
    private init() {}
    
    // MARK: - 上传单条睡眠记录
    
    /// 上传单条睡眠记录到服务器
    /// - Parameter record: 本地睡眠记录
    /// - Returns: 服务器返回的睡眠ID
    func uploadSleepRecord(_ record: SleepRecord) async throws -> Int {
        print("📤 准备上传睡眠记录...")
        
        // 转换为API格式
        let parameters = record.toAPIUploadFormat()
        
        print("📊 睡眠数据: \(parameters)")
        print("🔍 字段检查:")
        print("   - sleepDate: \(parameters["sleepDate"] ?? "❌ 缺失")")
        print("   - startTime: \(parameters["startTime"] ?? "❌ 缺失")")
        print("   - endTime: \(parameters["endTime"] ?? "❌ 缺失")")
        print("   - duration: \(parameters["duration"] ?? "❌ 缺失")")
        print("   - quality: \(parameters["quality"] ?? "❌ 缺失")")
        
        // 发送POST请求
        let response: SleepUploadResponse = try await NetworkManager.shared.post(
            endpoint: "/health/sleep/upload",
            parameters: parameters,
            headers: nil,
            responseType: SleepUploadResponse.self
        )
        
        // 检查响应
        guard response.success else {
            let errorMessage = response.error ?? response.message ?? "上传睡眠记录失败"
            print("❌ 上传失败: \(errorMessage)")
            throw NSError(domain: "SleepAPIService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ])
        }
        
        // 打印上传成功信息
        if let data = response.data {
            print("✅ 睡眠记录上传成功")
            print("   - 睡眠日期: \(data.sleepDate)")
            if let summary = data.sleepSummary {
                print("   - 总记录数: \(summary.totalRecords)")
                print("   - 平均睡眠时长: \(String(format: "%.2f", summary.averageSleepDuration))小时")
                print("   - 平均睡眠质量: \(String(format: "%.2f", summary.averageSleepQuality))")
                print("   - 睡眠模式: \(summary.sleepPattern)")
            }
            // 如果有sleepId则返回，否则返回0表示成功但没有具体ID
            return data.sleepId ?? 0
        } else {
            print("✅ 睡眠记录上传成功")
            return 0
        }
    }
    
    // MARK: - 批量上传睡眠记录
    
    /// 批量上传多条睡眠记录
    /// - Parameter records: 本地睡眠记录数组
    /// - Returns: 成功上传的记录数量
    func uploadSleepRecordsBatch(_ records: [SleepRecord]) async throws -> Int {
        print("📤 开始批量上传 \(records.count) 条睡眠记录...")
        
        var successCount = 0
        var failedCount = 0
        
        for (index, record) in records.enumerated() {
            do {
                let sleepId = try await uploadSleepRecord(record)
                successCount += 1
                print("✅ [\(index + 1)/\(records.count)] 上传成功，sleepId: \(sleepId)")
            } catch {
                failedCount += 1
                print("❌ [\(index + 1)/\(records.count)] 上传失败: \(error.localizedDescription)")
            }
            
            // 添加小延迟避免请求过于频繁
            if index < records.count - 1 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            }
        }
        
        print("📊 批量上传完成: 成功 \(successCount) 条，失败 \(failedCount) 条")
        return successCount
    }
    
    // MARK: - 获取睡眠历史记录
    
    /// 获取用户的睡眠历史记录
    /// - Parameters:
    ///   - startDate: 开始日期（可选）
    ///   - endDate: 结束日期（可选）
    ///   - page: 页码（可选）
    ///   - limit: 每页数量（可选）
    /// - Returns: 睡眠历史记录数组
    func getSleepHistory(
        startDate: String? = nil,
        endDate: String? = nil,
        page: Int? = nil,
        limit: Int? = nil
    ) async throws -> [SleepHistoryRecord] {
        print("📥 获取睡眠历史记录...")
        
        // 构建查询参数
        var parameters: [String: Any] = [:]
        if let startDate = startDate {
            parameters["startDate"] = startDate
        }
        if let endDate = endDate {
            parameters["endDate"] = endDate
        }
        if let page = page {
            parameters["page"] = page
        }
        if let limit = limit {
            parameters["limit"] = limit
        }
        
        // 发送GET请求
        let response: SleepHistoryResponse = try await NetworkManager.shared.get(
            endpoint: "/health/sleep/history",
            parameters: parameters.isEmpty ? nil : parameters,
            headers: nil,
            responseType: SleepHistoryResponse.self
        )
        
        // 检查响应
        guard response.success, let data = response.data else {
            let errorMessage = response.error ?? response.message ?? "获取睡眠历史失败"
            print("❌ 获取失败: \(errorMessage)")
            throw NSError(domain: "SleepAPIService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ])
        }
        
        print("✅ 获取睡眠历史成功，共 \(data.records.count) 条记录")
        return data.records
    }
    
    // MARK: - 获取特定日期的睡眠记录
    
    /// 获取特定日期的睡眠记录
    /// - Parameter date: 睡眠日期
    /// - Returns: 睡眠记录（如果存在）
    func getSleepRecordForDate(_ date: Date) async throws -> SleepHistoryRecord? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        
        let records = try await getSleepHistory(
            startDate: dateString,
            endDate: dateString,
            page: 1,
            limit: 1
        )
        
        return records.first
    }
    
    // MARK: - 删除睡眠记录
    
    /// 删除指定的睡眠记录
    /// - Parameter sleepId: 睡眠记录ID
    func deleteSleepRecord(_ sleepId: Int) async throws {
        print("🗑️ 删除睡眠记录 ID: \(sleepId)...")
        
        let response: SleepUploadResponse = try await NetworkManager.shared.delete(
            endpoint: "/health/sleep/\(sleepId)",
            parameters: nil,
            headers: nil,
            responseType: SleepUploadResponse.self
        )
        
        guard response.success else {
            let errorMessage = response.error ?? response.message ?? "删除睡眠记录失败"
            print("❌ 删除失败: \(errorMessage)")
            throw NSError(domain: "SleepAPIService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ])
        }
        
        print("✅ 睡眠记录删除成功")
    }
    
    // MARK: - 获取健康报告
    
    /// 获取指定日期的健康报告（包含睡眠分析）
    /// - Parameter date: 报告日期
    /// - Returns: 健康报告数据
    func getHealthReportForDate(_ date: Date) async throws -> HealthReportData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        
        print("📥 获取健康报告，日期: \(dateString)...")
        
        // 发送GET请求
        let response: HealthReportResponse = try await NetworkManager.shared.get(
            endpoint: "/health/report/date/\(dateString)",
            parameters: nil,
            headers: nil,
            responseType: HealthReportResponse.self
        )
        
        // 检查响应
        guard response.success, let data = response.data else {
            let errorMessage = response.msg
            print("❌ 获取健康报告失败: \(errorMessage)")
            throw NSError(domain: "SleepAPIService", code: response.code, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ])
        }
        
        print("✅ 获取健康报告成功")
        return data
    }
    
    /// 生成最新的健康报告
    /// - Returns: 生成的健康报告数据
    func generateHealthReport() async throws -> HealthReportData {
        print("📊 生成最新健康报告...")
        
        let parameters: [String: Any] = [
            "reportType": "comprehensive"
        ]
        
        // 发送POST请求
        let response: HealthReportResponse = try await NetworkManager.shared.post(
            endpoint: "/health/report/generate",
            parameters: parameters,
            headers: nil,
            responseType: HealthReportResponse.self
        )
        
        // 检查响应
        guard response.success, let data = response.data else {
            let errorMessage = response.msg
            print("❌ 生成健康报告失败: \(errorMessage)")
            throw NSError(domain: "SleepAPIService", code: response.code, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ])
        }
        
        print("✅ 生成健康报告成功")
        return data
    }
    
    // MARK: - 睡眠分析 API
    
    /// 获取单次睡眠会话的质量分析
    /// - Parameter sessionId: 睡眠会话ID
    /// - Returns: 单次会话质量分析数据
    func getSingleSessionQualityAnalysis(sessionId: String) async throws -> SingleSessionQualityData {
        print("🔍 获取单次睡眠会话分析，sessionId: \(sessionId)...")

        // 构建查询参数
        let parameters: [String: Any] = [
            "sessionId": sessionId
        ]

        // 发送GET请求
        let response: SingleSessionQualityResponse = try await NetworkManager.shared.get(
            endpoint: "/sleep/quality-analysis",
            parameters: parameters,
            headers: nil,
            responseType: SingleSessionQualityResponse.self
        )

        // 检查响应
        guard response.status == "success" else {
            let errorMessage = "获取睡眠会话分析失败"
            print("❌ \(errorMessage)")
            throw NSError(domain: "SleepAPIService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ])
        }

        print("✅ 单次睡眠会话分析获取成功")
        print("   - 会话ID: \(response.data.sessionId)")
        print("   - 整体评分: \(response.data.qualityAnalysis.overallScore)")
        print("   - 质量等级: \(response.data.qualityAnalysis.qualityLevel)")
        print("   - 睡眠效率: \(response.data.qualityAnalysis.keyMetrics.sleepEfficiency)%")

        return response.data
    }

    // MARK: - 睡眠 AI 分析报告 API

    /// 获取睡眠 AI 分析报告（包含 DeepSeek AI 生成的洞察和建议）
    /// - Parameter sessionId: 睡眠会话ID
    /// - Returns: 睡眠 AI 分析报告数据
    func getSleepAIReport(sessionId: String) async throws -> SleepAIReportData {
        print("🤖 获取睡眠 AI 分析报告，sessionId: \(sessionId)...")

        // 发送GET请求
        let response: SleepAIReportResponse = try await NetworkManager.shared.get(
            endpoint: "/sleep/report/\(sessionId)",
            parameters: nil,
            headers: nil,
            responseType: SleepAIReportResponse.self
        )

        // 检查响应
        guard response.status == "success" else {
            let errorMessage = "获取睡眠 AI 分析报告失败"
            print("❌ \(errorMessage)")
            throw NSError(domain: "SleepAPIService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ])
        }

        print("✅ 睡眠 AI 分析报告获取成功")
        print("   - 会话ID: \(response.data.sessionId)")
        print("   - 报告ID: \(response.data.reportId)")
        print("   - 生成时间: \(response.data.generatedAt)")
        print("   - 整体质量: \(response.data.sleepSummary.overallQuality)")
        print("   - 睡眠效率: \(response.data.sleepSummary.sleepEfficiency)%")
        print("   - 睡眠阶段数: \(response.data.sleepStages.count)")
        print("   - AI 洞察数: \(response.data.insights.count)")
        print("   - AI 建议数: \(response.data.aiAnalysis.recommendations.count)")

        return response.data
    }

    // MARK: - 睡眠批量上传（新接口 - AI分析）

    /// 批量上传睡眠会话数据（创建睡眠会话，触发AI分析）
    /// - Parameter request: 批量上传请求
    /// - Returns: 批量上传响应（包含sessionId和音频上传凭证）
    func uploadSleepSessionBatch(_ request: SleepBatchUploadRequest) async throws -> SleepBatchUploadResponse {
        print("📤 准备批量上传睡眠会话数据...")
        print("   - Local Session ID: \(request.sleepSession.localSessionId)")
        print("   - 开始时间: \(request.sleepSession.startTime)")
        print("   - 结束时间: \(request.sleepSession.endTime)")
        print("   - 音频片段数: \(request.audioSegments?.count ?? 0)")
        print("   - 传感器数据点数: \(request.sensorData?.count ?? 0)")
        
        // 发送POST请求到新的批量上传接口
        let response: SleepBatchUploadResponse = try await NetworkManager.shared.post(
            endpoint: "/sleep/batch-upload",
            parameters: try request.toDictionary(),
            headers: nil,
            responseType: SleepBatchUploadResponse.self
        )
        
        // 检查响应
        guard response.success else {
            let errorMessage = response.message ?? "批量上传睡眠会话失败"
            print("❌ 上传失败: \(errorMessage)")
            throw NSError(domain: "SleepAPIService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: errorMessage
            ])
        }
        
        print("✅ 睡眠会话批量上传成功")
        print("   - Session ID: \(response.data.sessionId)")
        print("   - Upload ID: \(response.data.uploadId)")
        print("   - 处理状态: \(response.data.processingStatus)")
        print("   - 预计处理时间: \(response.data.estimatedProcessingTime ?? 0)秒")
        print("   - 音频上传URL数: \(response.data.audioUploadUrls?.count ?? 0)")
        
        return response
    }
    
    /// 上传音频文件到OSS
    /// - Parameters:
    ///   - fileData: 音频文件数据
    ///   - uploadUrl: OSS预签名上传URL
    func uploadAudioToOSS(fileData: Data, uploadUrl: String) async throws {
        print("📤 上传音频文件到OSS...")
        print("   - 文件大小: \(fileData.count) 字节")
        print("   - 上传URL: \(uploadUrl)")

        guard let url = URL(string: uploadUrl) else {
            throw NSError(domain: "SleepAPIService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "无效的上传URL"
            ])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        // 修复：使用正确的 Content-Type，支持 wav 格式
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.httpBody = fileData
        request.timeoutInterval = 60.0  // 增加超时时间

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ OSS上传失败: 无效的响应")
                throw NSError(domain: "SleepAPIService", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "OSS上传失败: 无效的响应"
                ])
            }

            print("🔍 OSS响应状态码: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "未知错误"
                print("❌ OSS上传失败 - 状态码: \(httpResponse.statusCode)")
                print("❌ 错误信息: \(errorMessage)")
                throw NSError(domain: "SleepAPIService", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "OSS上传失败 (状态码: \(httpResponse.statusCode))"
                ])
            }

            print("✅ 音频文件上传到OSS成功")
        } catch let error as NSError {
            print("❌ OSS上传异常: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 查询处理状态
    /// - Parameter uploadId: 上传任务ID
    /// - Returns: 处理状态响应
    func getProcessingStatus(uploadId: String) async throws -> ProcessingStatusResponse {
        print("🔍 查询处理状态...")
        print("   - Upload ID: \(uploadId)")
        
        let response: ProcessingStatusResponse = try await NetworkManager.shared.get(
            endpoint: "/sleep/processing-status/\(uploadId)",
            parameters: nil,
            headers: nil,
            responseType: ProcessingStatusResponse.self
        )
        
        guard response.success else {
            print("❌ 查询处理状态失败")
            throw NSError(domain: "SleepAPIService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "查询处理状态失败"
            ])
        }
        
        print("✅ 处理状态查询成功")
        print("   - 状态: \(response.data.processingStatus)")
        print("   - 进度: \(response.data.progress)%")
        if let step = response.data.currentStep {
            print("   - 当前步骤: \(step)")
        }
        
        return response
    }
}
