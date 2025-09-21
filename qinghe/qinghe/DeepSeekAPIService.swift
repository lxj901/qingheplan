import Foundation
import SwiftUI

/// DeepSeek API 服务类
/// 负责与 DeepSeek API 进行通信，提供睡眠分析服务
@MainActor
class DeepSeekAPIService: ObservableObject {
    static let shared = DeepSeekAPIService()
    
    // MARK: - 发布属性
    @Published var isConnected = false
    @Published var isAnalyzing = false
    @Published var lastError: String?
    
    // MARK: - 私有属性
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.API.DeepSeek.timeoutInterval
        config.timeoutIntervalForResource = AppConstants.API.DeepSeek.resourceTimeout
        config.waitsForConnectivity = true

        self.session = URLSession(configuration: config)

        // 测试连接
        Task {
            await testConnection()
        }
    }
    
    // MARK: - 公共方法
    
    /// 测试 API 连接
    func testConnection() async {
        print("🔗 测试 DeepSeek API 连接...")
        
        do {
            let response = try await makeSimpleRequest()
            isConnected = response != nil
            lastError = nil
            print("✅ DeepSeek API 连接成功")
        } catch {
            isConnected = false
            lastError = error.localizedDescription
            print("❌ DeepSeek API 连接失败: \(error.localizedDescription)")
        }
    }
    
    /// 分析睡眠数据
    /// - Parameters:
    ///   - sleepData: 睡眠数据
    ///   - audioEvents: 音频事件
    /// - Returns: 分析结果
    func analyzeSleepData(
        sleepData: SleepAnalysisRequest,
        audioEvents: [SleepAudioEvent]
    ) async throws -> DeepSeekSleepAnalysisResponse {
        print("🧠 开始 DeepSeek API 睡眠分析...")
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // 构建请求
        let request = try await buildAnalysisRequest(sleepData: sleepData, audioEvents: audioEvents)
        
        // 发送请求
        let response = try await sendAnalysisRequest(request)
        
        print("✅ DeepSeek API 睡眠分析完成")
        return response
    }
    
    /// 获取睡眠建议
    /// - Parameter analysisResult: 分析结果
    /// - Returns: 个性化建议
    func getSleepRecommendations(
        analysisResult: DeepSeekSleepAnalysisResponse,
        userProfile: UserSleepProfile?
    ) async throws -> [DeepSeekSleepRecommendation] {
        print("💡 获取 DeepSeek 睡眠建议...")
        
        let request = try buildRecommendationRequest(
            analysisResult: analysisResult,
            userProfile: userProfile
        )
        
        let response = try await sendRecommendationRequest(request)
        
        print("✅ DeepSeek 睡眠建议获取完成")
        return response.recommendations
    }
    
    // MARK: - 私有方法
    
    /// 构建通用请求
    private func buildRequest(
        endpoint: String,
        method: String = "POST",
        body: [String: Any]
    ) throws -> URLRequest {
        guard let url = URL(string: "\(AppConstants.API.DeepSeek.baseURL)/\(endpoint)") else {
            throw DeepSeekAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AppConstants.API.DeepSeek.apiKey)", forHTTPHeaderField: "Authorization")

        if !body.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return request
    }
    
    /// 发送请求并处理响应
    private func sendRequest<T: Codable>(
        _ request: URLRequest,
        responseType: T.Type
    ) async throws -> T {
        var responseData: Data?

        do {
            let (data, response) = try await session.data(for: request)
            responseData = data // 保存数据以便在 catch 块中使用

            // 检查 HTTP 状态码
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 DeepSeek API 响应状态码: \(httpResponse.statusCode)")

                switch httpResponse.statusCode {
                case 200...299:
                    break // 成功
                case 401:
                    throw DeepSeekAPIError.unauthorized
                case 429:
                    throw DeepSeekAPIError.rateLimited
                case 400...499:
                    throw DeepSeekAPIError.clientError(httpResponse.statusCode)
                case 500...599:
                    throw DeepSeekAPIError.serverError(httpResponse.statusCode)
                default:
                    throw DeepSeekAPIError.unknownError(httpResponse.statusCode)
                }
            }

            // 解析响应
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            return try decoder.decode(responseType, from: data)

        } catch let error as DeepSeekAPIError {
            throw error
        } catch let error as DecodingError {
            print("❌ DeepSeek API 响应解析失败: \(error)")

            // 打印更详细的解析错误信息
            switch error {
            case .dataCorrupted(let context):
                print("数据损坏: \(context.debugDescription)")
                print("编码路径: \(context.codingPath)")
            case .keyNotFound(let key, let context):
                print("缺少键: \(key.stringValue)")
                print("编码路径: \(context.codingPath)")
                print("调试描述: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("类型不匹配: 期望 \(type)")
                print("编码路径: \(context.codingPath)")
                print("调试描述: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("值未找到: 期望 \(type)")
                print("编码路径: \(context.codingPath)")
                print("调试描述: \(context.debugDescription)")
            @unknown default:
                print("未知解析错误: \(error)")
            }

            // 打印原始数据以便调试
            if let data = responseData, let dataString = String(data: data, encoding: .utf8) {
                print("原始响应数据: \(dataString.prefix(500))...")
            }

            throw DeepSeekAPIError.decodingError(error)
        } catch {
            print("❌ DeepSeek API 网络错误: \(error)")
            throw DeepSeekAPIError.networkError(error)
        }
    }
    
    /// 简单连接测试
    private func makeSimpleRequest() async throws -> [String: Any]? {
        let request = try buildRequest(
            endpoint: "models",
            method: "GET",
            body: [:]
        )
        
        let (data, _) = try await session.data(for: request)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    
    /// 构建睡眠分析请求
    private func buildAnalysisRequest(
        sleepData: SleepAnalysisRequest,
        audioEvents: [SleepAudioEvent]
    ) async throws -> URLRequest {
        let body: [String: Any] = [
            "model": AppConstants.API.DeepSeek.model,
            "messages": [
                [
                    "role": "system",
                    "content": buildSystemPrompt()
                ],
                [
                    "role": "user",
                    "content": buildAnalysisPrompt(sleepData: sleepData, audioEvents: audioEvents)
                ]
            ],
            "temperature": AppConstants.API.DeepSeek.temperature,
            "max_tokens": AppConstants.API.DeepSeek.maxTokens
        ]
        
        return try buildRequest(endpoint: "chat/completions", body: body)
    }
    
    /// 发送睡眠分析请求
    private func sendAnalysisRequest(_ request: URLRequest) async throws -> DeepSeekSleepAnalysisResponse {
        let response = try await sendRequest(request, responseType: DeepSeekChatResponse.self)
        return try parseAnalysisResponse(response)
    }
    
    /// 构建建议请求
    private func buildRecommendationRequest(
        analysisResult: DeepSeekSleepAnalysisResponse,
        userProfile: UserSleepProfile?
    ) throws -> URLRequest {
        let body: [String: Any] = [
            "model": AppConstants.API.DeepSeek.model,
            "messages": [
                [
                    "role": "system",
                    "content": buildRecommendationSystemPrompt()
                ],
                [
                    "role": "user",
                    "content": buildRecommendationPrompt(analysisResult: analysisResult, userProfile: userProfile)
                ]
            ],
            "temperature": 0.4,
            "max_tokens": 1500
        ]
        
        return try buildRequest(endpoint: "chat/completions", body: body)
    }
    
    /// 发送建议请求
    private func sendRecommendationRequest(_ request: URLRequest) async throws -> DeepSeekRecommendationResponse {
        let response = try await sendRequest(request, responseType: DeepSeekChatResponse.self)
        return try parseRecommendationResponse(response)
    }
}

// MARK: - 错误类型
enum DeepSeekAPIError: LocalizedError {
    case invalidURL
    case unauthorized
    case rateLimited
    case clientError(Int)
    case serverError(Int)
    case unknownError(Int)
    case decodingError(Error)
    case networkError(Error)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 API URL"
        case .unauthorized:
            return "API 密钥无效或未授权"
        case .rateLimited:
            return "API 请求频率限制"
        case .clientError(let code):
            return "客户端错误: \(code)"
        case .serverError(let code):
            return "服务器错误: \(code)"
        case .unknownError(let code):
            return "未知错误: \(code)"
        case .decodingError(let error):
            return "响应解析失败: \(error.localizedDescription)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的 API 响应"
        }
    }
}

// MARK: - 请求和响应模型
struct SleepAnalysisRequest: Codable {
    let sessionId: String
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval
    let audioEventCount: Int

    enum CodingKeys: String, CodingKey {
        case sessionId, startTime, endTime, duration, audioEventCount
    }
}

struct DeepSeekChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [ChatChoice]
    let usage: Usage?
    
    struct ChatChoice: Codable {
        let index: Int
        let message: ChatMessage
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

struct DeepSeekSleepAnalysisResponse: Codable {
    let qualityScore: Double
    let sleepStages: [SleepStageInfo]
    let insights: [String]
    let patterns: SleepPatternSummary
    let confidence: Double
}

struct DeepSeekRecommendationResponse: Codable {
    let recommendations: [DeepSeekSleepRecommendation]
    let priority: String
    let timeframe: String
}

struct SleepStageInfo: Codable {
    let stage: String
    let startTime: Date
    let duration: TimeInterval
    let quality: Double

    // 自定义初始化器，支持字符串时间
    init(stage: String, startTime: Date, duration: TimeInterval, quality: Double) {
        self.stage = stage
        self.startTime = startTime
        self.duration = duration
        self.quality = quality
    }

    // 支持从字符串创建
    init(stage: String, startTimeString: String, duration: TimeInterval, quality: Double) {
        self.stage = stage
        self.duration = duration
        self.quality = quality

        // 尝试多种日期格式解析
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "HH:mm:ss"
        ]

        var parsedDate: Date?
        for formatString in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = formatString
            if let date = formatter.date(from: startTimeString) {
                parsedDate = date
                break
            }
        }

        self.startTime = parsedDate ?? Date()
    }

    // 自定义编码
    enum CodingKeys: String, CodingKey {
        case stage, startTime, duration, quality
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stage = try container.decode(String.self, forKey: .stage)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        quality = try container.decode(Double.self, forKey: .quality)

        // 尝试解析日期，如果失败则使用当前时间
        do {
            startTime = try container.decode(Date.self, forKey: .startTime)
        } catch {
            print("⚠️ 日期解析失败，使用当前时间: \(error)")
            startTime = Date()
        }
    }
}

struct SleepPatternSummary: Codable {
    let movementLevel: String
    let breathingPattern: String
    let environmentalFactors: [String]
    let disturbances: Int
}

// MARK: - DeepSeekAPIService 扩展 - 提示词构建
extension DeepSeekAPIService {

    /// 构建系统提示词
    private func buildSystemPrompt() -> String {
        return """
        你是一个专业的睡眠分析专家，具有深度学习和医学背景。你的任务是分析用户的睡眠数据，包括音频事件、睡眠时长、环境因素等，并提供专业的睡眠质量评估和个性化建议。

        请按照以下 JSON 格式返回分析结果：
        {
            "qualityScore": 0-100的睡眠质量评分,
            "sleepStages": [
                {
                    "stage": "深度睡眠/浅度睡眠/REM睡眠/清醒",
                    "startTime": "ISO8601时间格式",
                    "duration": 持续时间(秒),
                    "quality": 0-100的质量评分
                }
            ],
            "insights": [
                "关键洞察1",
                "关键洞察2",
                "关键洞察3"
            ],
            "patterns": {
                "movementLevel": "低/中/高",
                "breathingPattern": "规律/不规律/异常",
                "environmentalFactors": ["噪音", "温度变化", "光线"],
                "disturbances": 干扰次数
            },
            "confidence": 0-100的分析置信度
        }

        分析时请考虑：
        1. 音频事件的类型、频率和强度
        2. 睡眠时长和连续性
        3. 环境因素对睡眠的影响
        4. 睡眠阶段的自然转换
        5. 个体差异和健康状况
        """
    }

    /// 构建睡眠分析提示词
    private func buildAnalysisPrompt(
        sleepData: SleepAnalysisRequest,
        audioEvents: [SleepAudioEvent]
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var prompt = """
        请分析以下睡眠数据：

        基本信息：
        - 会话ID: \(sleepData.sessionId)
        - 开始时间: \(formatter.string(from: sleepData.startTime))
        """

        if let endTime = sleepData.endTime {
            prompt += "\n- 结束时间: \(formatter.string(from: endTime))"
        }

        prompt += """

        - 睡眠时长: \(formatDuration(sleepData.duration))
        - 音频事件总数: \(sleepData.audioEventCount)

        音频事件详情：
        """

        // 添加音频事件信息
        for (index, event) in audioEvents.prefix(20).enumerated() {
            prompt += """

            事件\(index + 1):
            - 类型: \(event.type.rawValue)
            - 时间: \(formatter.string(from: event.startTime))
            - 强度: \(String(format: "%.2f", event.intensity))
            - 持续时间: \(String(format: "%.1f", event.duration))秒
            - 置信度: \(String(format: "%.2f", event.confidence))
            """
        }

        if audioEvents.count > 20 {
            prompt += "\n\n... 还有 \(audioEvents.count - 20) 个音频事件"
        }

        prompt += """


        请基于以上数据进行专业的睡眠分析，并严格按照指定的 JSON 格式返回结果。
        """

        return prompt
    }

    /// 构建建议系统提示词
    private func buildRecommendationSystemPrompt() -> String {
        return """
        你是一个专业的睡眠健康顾问，基于睡眠分析结果为用户提供个性化的改善建议。

        请按照以下 JSON 格式返回建议：
        {
            "recommendations": [
                {
                    "type": "lifestyle/environment/health/schedule",
                    "title": "建议标题",
                    "description": "详细描述",
                    "priority": "high/medium/low",
                    "category": "睡眠环境/作息调整/健康习惯/其他",
                    "estimatedImpact": "high/medium/low",
                    "implementationDifficulty": "easy/medium/hard",
                    "timeToSeeResults": "预期见效时间",
                    "relatedInsights": ["相关洞察"]
                }
            ],
            "priority": "整体优先级",
            "timeframe": "建议执行时间框架"
        }

        建议应该：
        1. 基于具体的睡眠分析结果
        2. 考虑用户的个人情况
        3. 提供可操作的具体步骤
        4. 按重要性排序
        5. 包含预期效果和时间框架
        """
    }

    /// 构建建议提示词
    private func buildRecommendationPrompt(
        analysisResult: DeepSeekSleepAnalysisResponse,
        userProfile: UserSleepProfile?
    ) -> String {
        var prompt = """
        基于以下睡眠分析结果，请提供个性化的改善建议：

        睡眠质量评分: \(String(format: "%.1f", analysisResult.qualityScore))/100
        分析置信度: \(String(format: "%.1f", analysisResult.confidence))%

        关键洞察:
        """

        for (index, insight) in analysisResult.insights.enumerated() {
            prompt += "\n\(index + 1). \(insight)"
        }

        prompt += """


        睡眠模式:
        - 活动水平: \(analysisResult.patterns.movementLevel)
        - 呼吸模式: \(analysisResult.patterns.breathingPattern)
        - 干扰次数: \(analysisResult.patterns.disturbances)
        - 环境因素: \(analysisResult.patterns.environmentalFactors.joined(separator: ", "))
        """

        if let profile = userProfile {
            prompt += """


            用户档案:
            - 年龄: \(profile.age ?? 0)岁
            - 理想睡眠时长: \(String(format: "%.1f", profile.sleepGoals.targetSleepDuration / 3600))小时
            - 睡眠质量目标: \(String(format: "%.1f", profile.sleepGoals.qualityGoal))分
            """

            if !profile.healthConditions.isEmpty {
                prompt += "\n- 健康状况: \(profile.healthConditions.joined(separator: ", "))"
            }

            if let gender = profile.gender {
                prompt += "\n- 性别: \(gender)"
            }
        }

        prompt += """


        请基于以上信息提供3-5个具体的、可操作的改善建议，并严格按照指定的 JSON 格式返回。
        """

        return prompt
    }

    /// 解析分析响应
    private func parseAnalysisResponse(_ response: DeepSeekChatResponse) throws -> DeepSeekSleepAnalysisResponse {
        guard let choice = response.choices.first else {
            print("❌ DeepSeek API 响应中没有选择项")
            throw DeepSeekAPIError.invalidResponse
        }

        let content = choice.message.content
        print("📝 DeepSeek API 原始响应内容: \(content.prefix(200))...")

        // 尝试提取 JSON 部分
        let jsonString = extractJSON(from: content)
        print("🔍 提取的 JSON 字符串: \(jsonString.prefix(200))...")

        guard let jsonData = jsonString.data(using: .utf8) else {
            print("❌ 无法将 JSON 字符串转换为 Data")
            throw DeepSeekAPIError.invalidResponse
        }

        // 尝试多种日期解析策略
        let decoder = JSONDecoder()

        // 首先尝试 ISO8601 格式
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(DeepSeekSleepAnalysisResponse.self, from: jsonData)
        } catch let decodingError as DecodingError {
            print("❌ ISO8601 日期格式解析失败，尝试其他格式...")
            print("解析错误详情: \(decodingError)")

            // 尝试自定义日期格式
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            decoder.dateDecodingStrategy = .formatted(formatter)

            do {
                return try decoder.decode(DeepSeekSleepAnalysisResponse.self, from: jsonData)
            } catch {
                print("❌ 自定义日期格式也失败，尝试创建默认响应...")

                // 如果解析完全失败，创建一个默认的响应
                return createFallbackAnalysisResponse(from: content)
            }
        }
    }

    /// 解析建议响应
    private func parseRecommendationResponse(_ response: DeepSeekChatResponse) throws -> DeepSeekRecommendationResponse {
        guard let choice = response.choices.first else {
            print("❌ DeepSeek API 建议响应中没有选择项")
            throw DeepSeekAPIError.invalidResponse
        }

        let content = choice.message.content
        print("📝 DeepSeek API 建议原始响应内容: \(content.prefix(200))...")

        // 尝试提取 JSON 部分
        let jsonString = extractJSON(from: content)
        print("🔍 提取的建议 JSON 字符串: \(jsonString.prefix(200))...")

        guard let jsonData = jsonString.data(using: .utf8) else {
            print("❌ 无法将建议 JSON 字符串转换为 Data")
            throw DeepSeekAPIError.invalidResponse
        }

        let decoder = JSONDecoder()

        do {
            return try decoder.decode(DeepSeekRecommendationResponse.self, from: jsonData)
        } catch let decodingError as DecodingError {
            print("❌ 建议响应解析失败，尝试创建默认响应...")
            print("解析错误详情: \(decodingError)")

            // 如果解析完全失败，创建一个默认的建议响应
            return createFallbackRecommendationResponse(from: content)
        }
    }

    /// 从文本中提取 JSON
    private func extractJSON(from text: String) -> String {
        // 🔥 修复：安全地提取 JSON，避免索引越界
        guard !text.isEmpty else {
            print("⚠️ extractJSON: 输入文本为空")
            return text
        }

        // 查找 JSON 开始和结束位置
        guard let startRange = text.range(of: "{"),
              let endRange = text.range(of: "}", options: .backwards) else {
            print("⚠️ extractJSON: 未找到完整的 JSON 结构")
            return text
        }

        // 🔥 修复：验证索引有效性，确保 endRange 在 startRange 之后
        guard startRange.lowerBound <= endRange.upperBound else {
            print("⚠️ extractJSON: JSON 结构无效，开始位置在结束位置之后")
            return text
        }

        // 🔥 修复：安全地创建范围，避免索引越界
        let safeStartIndex = startRange.lowerBound
        let safeEndIndex = min(endRange.upperBound, text.endIndex)

        guard safeStartIndex < safeEndIndex else {
            print("⚠️ extractJSON: 无效的索引范围")
            return text
        }

        let extractedJSON = String(text[safeStartIndex..<safeEndIndex])
        print("✅ extractJSON: 成功提取 JSON，长度: \(extractedJSON.count)")
        return extractedJSON
    }

    /// 创建默认的分析响应（当解析失败时使用）
    private func createFallbackAnalysisResponse(from content: String) -> DeepSeekSleepAnalysisResponse {
        print("🔄 创建默认分析响应...")

        // 尝试从内容中提取一些基本信息
        let qualityScore = extractQualityScore(from: content) ?? 75.0
        let insights = extractInsights(from: content)

        return DeepSeekSleepAnalysisResponse(
            qualityScore: qualityScore,
            sleepStages: createDefaultSleepStages(),
            insights: insights.isEmpty ? ["睡眠质量分析完成", "建议保持规律的睡眠时间"] : insights,
            patterns: SleepPatternSummary(
                movementLevel: "正常",
                breathingPattern: "稳定",
                environmentalFactors: ["环境因素分析"],
                disturbances: 0
            ),
            confidence: 70.0
        )
    }

    /// 创建默认的建议响应（当解析失败时使用）
    private func createFallbackRecommendationResponse(from content: String) -> DeepSeekRecommendationResponse {
        print("🔄 创建默认建议响应...")

        // 尝试从内容中提取建议文本
        let extractedRecommendations = extractRecommendationsFromText(content)

        return DeepSeekRecommendationResponse(
            recommendations: extractedRecommendations.isEmpty ? createDefaultRecommendations() : extractedRecommendations,
            priority: "medium",
            timeframe: "1-2周"
        )
    }

    /// 从文本中提取质量评分
    private func extractQualityScore(from text: String) -> Double? {
        // 使用正则表达式查找质量评分
        let patterns = [
            #"质量.*?(\d+\.?\d*)"#,
            #"评分.*?(\d+\.?\d*)"#,
            #"分数.*?(\d+\.?\d*)"#,
            #"score.*?(\d+\.?\d*)"#
        ]

        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression),
               let scoreString = text[range].components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap({ Double($0) }).first {
                return min(100.0, max(0.0, scoreString))
            }
        }

        return nil
    }

    /// 从文本中提取洞察
    private func extractInsights(from text: String) -> [String] {
        var insights: [String] = []

        // 按行分割文本，查找可能的洞察
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.count > 10 && trimmedLine.count < 200 {
                // 过滤掉可能的 JSON 标记和过短/过长的行
                if !trimmedLine.contains("{") && !trimmedLine.contains("}") &&
                   !trimmedLine.contains("[") && !trimmedLine.contains("]") {
                    insights.append(trimmedLine)
                }
            }
        }

        return Array(insights.prefix(5)) // 最多返回5个洞察
    }

    /// 创建默认的睡眠阶段
    private func createDefaultSleepStages() -> [SleepStageInfo] {
        let now = Date()
        return [
            SleepStageInfo(
                stage: "浅睡眠",
                startTime: now.addingTimeInterval(-28800), // 8小时前
                duration: 3600, // 1小时
                quality: 75.0
            ),
            SleepStageInfo(
                stage: "深睡眠",
                startTime: now.addingTimeInterval(-25200), // 7小时前
                duration: 7200, // 2小时
                quality: 85.0
            ),
            SleepStageInfo(
                stage: "REM睡眠",
                startTime: now.addingTimeInterval(-18000), // 5小时前
                duration: 5400, // 1.5小时
                quality: 80.0
            )
        ]
    }

    /// 格式化时长
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }

    /// 从文本中提取建议
    private func extractRecommendationsFromText(_ content: String) -> [DeepSeekSleepRecommendation] {
        var recommendations: [DeepSeekSleepRecommendation] = []

        // 简单的文本解析，查找建议相关的内容
        let lines = content.components(separatedBy: .newlines)
        let recommendationLines = lines.filter { line in
            line.contains("建议") || line.contains("改善") || line.contains("优化") || line.contains("调整")
        }

        for (index, line) in recommendationLines.prefix(3).enumerated() {
            recommendations.append(DeepSeekSleepRecommendation(
                type: .schedule,
                title: "睡眠改善建议 \(index + 1)",
                description: String(line.trimmingCharacters(in: .whitespacesAndNewlines)),
                priority: index == 0 ? .high : .medium,
                category: .habit,
                estimatedImpact: .medium,
                implementationDifficulty: .medium,
                timeToSeeResults: "1-2周",
                relatedInsights: []
            ))
        }

        return recommendations
    }

    /// 创建默认建议
    private func createDefaultRecommendations() -> [DeepSeekSleepRecommendation] {
        return [
            DeepSeekSleepRecommendation(
                type: .schedule,
                title: "保持规律作息",
                description: "建议每天在相同时间上床睡觉和起床，有助于调节生物钟。",
                priority: .high,
                category: .schedule,
                estimatedImpact: .high,
                implementationDifficulty: .medium,
                timeToSeeResults: "1-2周",
                relatedInsights: []
            ),
            DeepSeekSleepRecommendation(
                type: .environment,
                title: "优化睡眠环境",
                description: "保持卧室安静、黑暗和凉爽，创造良好的睡眠环境。",
                priority: .medium,
                category: .environment,
                estimatedImpact: .medium,
                implementationDifficulty: .easy,
                timeToSeeResults: "立即见效",
                relatedInsights: []
            ),
            DeepSeekSleepRecommendation(
                type: .lifestyle,
                title: "睡前放松",
                description: "睡前1小时避免使用电子设备，可以尝试阅读或冥想来放松身心。",
                priority: .medium,
                category: .lifestyle,
                estimatedImpact: .medium,
                implementationDifficulty: .easy,
                timeToSeeResults: "3-7天",
                relatedInsights: []
            )
        ]
    }
}
