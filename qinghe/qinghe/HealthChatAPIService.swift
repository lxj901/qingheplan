import Foundation

/// AI 健康对话 API 服务
class HealthChatAPIService {
    static let shared = HealthChatAPIService()

    private init() {}

    // MARK: - 对话管理

    /// 开始新对话
    func createNewConversation() async throws -> ConversationResponse {
        print("🌐 API请求: POST /health/chat/new")
        let response: ConversationResponse = try await NetworkManager.shared.post(
            endpoint: "/health/chat/new",
            parameters: nil,
            headers: nil,
            responseType: ConversationResponse.self
        )

        guard response.success else {
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message ?? "创建对话失败"])
        }

        return response
    }

    /// 获取对话历史列表
    func getConversationHistory(page: Int = 1, limit: Int = 20) async throws -> ConversationHistoryResponse {
        print("🌐 API请求: GET /health/chat/history?page=\(page)&limit=\(limit)")
        let response: ConversationHistoryResponse = try await NetworkManager.shared.get(
            endpoint: "/health/chat/history",
            parameters: ["page": page, "limit": limit],
            headers: nil,
            responseType: ConversationHistoryResponse.self
        )

        guard response.success else {
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message ?? "获取对话历史失败"])
        }

        return response
    }

    /// 获取指定对话的消息记录
    func getConversationMessages(conversationId: String, page: Int = 1, limit: Int = 50) async throws -> ConversationMessagesResponse {
        print("🌐 API请求: GET /health/chat/history?conversationId=\(conversationId)")
        let response: ConversationMessagesResponse = try await NetworkManager.shared.get(
            endpoint: "/health/chat/history",
            parameters: ["conversationId": conversationId, "page": page, "limit": limit],
            headers: nil,
            responseType: ConversationMessagesResponse.self
        )

        guard response.success else {
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message ?? "获取消息记录失败"])
        }

        return response
    }

    /// 发送消息（直接解析JSON响应）
    func sendMessage(message: String, conversationId: String?) async throws -> ChatResponse {
        print("🌐 API请求: POST /health/chat")
        var parameters: [String: Any] = ["message": message]
        if let conversationId = conversationId {
            parameters["conversationId"] = conversationId
        }

        // 使用 NetworkManager 发送请求
        let response: ChatResponse = try await NetworkManager.shared.post(
            endpoint: "/health/chat",
            parameters: parameters,
            headers: nil,
            responseType: ChatResponse.self
        )

        guard response.success else {
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message ?? "发送消息失败"])
        }

        return response
    }

    /// 查询对话任务状态
    func getJobStatus(jobId: String) async throws -> JobStatusResponse {
        print("🌐 API请求: GET /health/chat/job/\(jobId)")
        let response: JobStatusResponse = try await NetworkManager.shared.get(
            endpoint: "/health/chat/job/\(jobId)",
            parameters: nil,
            headers: nil,
            responseType: JobStatusResponse.self
        )

        guard response.success else {
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message ?? "获取任务状态失败"])
        }

        return response
    }

    /// 删除对话
    func deleteConversation(conversationId: String) async throws {
        print("🌐 API请求: DELETE /health/chat/conversation/\(conversationId)")
        let response: BaseResponse = try await NetworkManager.shared.delete(
            endpoint: "/health/chat/conversation/\(conversationId)",
            parameters: nil,
            headers: nil,
            responseType: BaseResponse.self
        )

        guard response.success else {
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message ?? "删除对话失败"])
        }
    }

    // MARK: - 问卷管理

    /// 获取舌诊/面诊问卷
    func getQuestionnaire() async throws -> QuestionnaireResponse {
        print("🌐 API请求: GET /health/tongue-diagnosis/questionnaire")
        let response: QuestionnaireResponse = try await NetworkManager.shared.get(
            endpoint: "/health/tongue-diagnosis/questionnaire",
            parameters: nil,
            headers: nil,
            responseType: QuestionnaireResponse.self
        )

        guard response.isSuccess else {
            let errorMessage = response.message ?? response.msg ?? "获取问卷失败"
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        return response
    }

    /// 保存问卷答案
    func saveQuestionnaireAnswers(conversationId: String, answers: [String: String]) async throws -> SaveQuestionnaireResponse {
        print("🌐 API请求: POST /health/tongue-diagnosis/save-questionnaire")
        let parameters: [String: Any] = [
            "conversationId": conversationId,
            "answers": answers
        ]

        let response: SaveQuestionnaireResponse = try await NetworkManager.shared.post(
            endpoint: "/health/tongue-diagnosis/save-questionnaire",
            parameters: parameters,
            headers: nil,
            responseType: SaveQuestionnaireResponse.self
        )

        guard response.isSuccess else {
            let errorMessage = response.message ?? response.msg ?? "保存问卷失败"
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        return response
    }

    /// 问卷完成后获取拍照动作卡片
    func questionnaireCompleted(conversationId: String, diagnosisType: String) async throws -> QuestionnaireCompletedResponse {
        print("🌐 API请求: POST /health/chat/questionnaire-completed")
        let parameters: [String: Any] = [
            "conversationId": conversationId,
            "diagnosisType": diagnosisType
        ]

        let response: QuestionnaireCompletedResponse = try await NetworkManager.shared.post(
            endpoint: "/health/chat/questionnaire-completed",
            parameters: parameters,
            headers: nil,
            responseType: QuestionnaireCompletedResponse.self
        )

        guard response.isSuccess else {
            let errorMessage = response.message ?? response.msg ?? "获取拍照卡片失败"
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        return response
    }

    /// 发送诊断结果到对话
    func sendDiagnosisResult(conversationId: String, diagnosisType: String, imageUrl: String, result: ActualAnalysisResponse.AnalysisData) async throws -> DiagnosisResultResponse {
        print("🌐 API请求: POST /health/chat/diagnosis-result")

        // 构建分析结果字典
        let analysisResult: [String: Any] = [
            "score": result.score,
            "physiqueName": result.physiqueName,
            "physiqueAnalysis": result.physiqueAnalysis,
            "typicalSymptom": result.typicalSymptom,
            "riskWarning": result.riskWarning,
            "syndromeName": result.syndromeName,
            "syndromeIntroduction": result.syndromeIntroduction,
            "imageUrl": imageUrl,
            "analyzedAt": result.analyzedAt
        ]

        let parameters: [String: Any] = [
            "conversationId": conversationId,
            "diagnosisType": diagnosisType,
            "analysisResult": analysisResult
        ]

        let response: DiagnosisResultResponse = try await NetworkManager.shared.post(
            endpoint: "/health/chat/diagnosis-result",
            parameters: parameters,
            headers: nil,
            responseType: DiagnosisResultResponse.self
        )

        guard response.isSuccess else {
            let errorMessage = response.message ?? response.msg ?? "发送诊断结果失败"
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        return response
    }

    // MARK: - 海报生成

    /// 生成健康助手对话海报（单消息，向后兼容）
    func generatePoster(messageId: String) async throws -> PosterResponse {
        print("🌐 API请求: POST /health/chat/generate-poster (单消息)")
        let parameters: [String: Any] = [
            "messageId": messageId
        ]

        let response: PosterResponse = try await NetworkManager.shared.post(
            endpoint: "/health/chat/generate-poster",
            parameters: parameters,
            headers: nil,
            responseType: PosterResponse.self
        )

        guard response.isSuccess else {
            let errorMessage = response.message ?? "生成海报失败"
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        return response
    }

    /// 生成健康助手对话海报（多消息）
    func generatePoster(messageIds: [String], theme: String? = nil, style: String? = "中国风") async throws -> PosterResponse {
        print("🌐 API请求: POST /health/chat/generate-poster (多消息)")
        print("📝 消息数量: \(messageIds.count)")

        var parameters: [String: Any] = [
            "messageIds": messageIds
        ]

        if let theme = theme {
            parameters["theme"] = theme
        }

        if let style = style {
            parameters["style"] = style
        }

        let response: PosterResponse = try await NetworkManager.shared.post(
            endpoint: "/health/chat/generate-poster",
            parameters: parameters,
            headers: nil,
            responseType: PosterResponse.self
        )

        guard response.isSuccess else {
            let errorMessage = response.message ?? "生成海报失败"
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        return response
    }

    // MARK: - 快捷提示语

    /// 获取快捷提示语列表
    /// - Parameters:
    ///   - category: 分类筛选 (可选)
    ///   - limit: 返回数量限制 (默认15)
    /// - Returns: 快捷提示语响应
    func getQuickPrompts(category: String? = nil, limit: Int = 15) async throws -> QuickPromptsResponse {
        print("🌐 API请求: GET /health/chat/quick-prompts")

        var parameters: [String: Any] = ["limit": limit]
        if let category = category {
            parameters["category"] = category
        }

        let response: QuickPromptsResponse = try await NetworkManager.shared.get(
            endpoint: "/health/chat/quick-prompts",
            parameters: parameters,
            headers: nil,
            responseType: QuickPromptsResponse.self
        )

        guard response.status == "success" else {
            throw NSError(domain: "HealthChatAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message ?? "获取快捷提示语失败"])
        }

        return response
    }

}

// MARK: - 响应模型

/// 基础响应
struct BaseResponse: Codable {
    let success: Bool
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success, status, message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try? container.decode(String.self, forKey: .message)
        
        // 处理 success 可能是 Bool 或者 status 是 "success" 字符串的情况
        if let successBool = try? container.decode(Bool.self, forKey: .success) {
            success = successBool
        } else if let statusString = try? container.decode(String.self, forKey: .status) {
            success = (statusString == "success")
        } else {
            success = false
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(message, forKey: .message)
    }
}

/// 创建对话响应
struct ConversationResponse: Codable {
    let status: String
    let message: String?
    let data: ConversationData?

    var success: Bool {
        return status.lowercased() == "success"
    }

    struct ConversationData: Codable {
        let conversationId: String
        let createdAt: String
        let welcomeMessage: String?
    }
}

/// 对话历史响应
struct ConversationHistoryResponse: Codable {
    let status: String
    let message: String?
    let data: ConversationHistoryData?

    var success: Bool {
        return status.lowercased() == "success"
    }

    struct ConversationHistoryData: Codable {
        let conversations: [ConversationItem]
        let pagination: Pagination
    }

    struct Pagination: Codable {
        let currentPage: Int
        let totalPages: Int
        let totalRecords: Int
        let hasMore: Bool
    }

    struct ConversationItem: Codable {
        let conversationId: String
        let title: String?
        let lastUserMessage: String?
        let lastAiReply: String?
        let messageCount: Int?
        let startedAt: String
        let lastMessageAt: String
        let status: String?

        // 为了兼容性，提供计算属性
        var createdAt: String { startedAt }
        var updatedAt: String { lastMessageAt }
        
        // 生成消息摘要（优先显示 AI 回复的前 50 个字符）
        var lastMessage: String? {
            if let aiReply = lastAiReply, !aiReply.isEmpty {
                // 截取前 50 个字符
                let maxLength = 50
                if aiReply.count > maxLength {
                    let index = aiReply.index(aiReply.startIndex, offsetBy: maxLength)
                    return String(aiReply[..<index]) + "..."
                }
                return aiReply
            }
            return lastUserMessage
        }
    }
}

/// 对话消息响应
struct ConversationMessagesResponse: Codable {
    let status: String
    let message: String?
    let data: ConversationMessagesData?
    
    var success: Bool {
        return status.lowercased() == "success"
    }

    struct ConversationMessagesData: Codable {
        let conversationId: String?
        let messages: [HealthChatMessage]?
        let total: Int?
        let page: Int?
        let limit: Int?
        
        // 兼容服务器返回对话列表而不是消息列表的情况
        let conversations: [ConversationHistoryResponse.ConversationItem]?
        let pagination: ConversationHistoryResponse.Pagination?
    }
}

/// 健康对话消息
struct HealthChatMessage: Codable, Identifiable {
    let id: String
    let conversationId: String?
    let role: String // "user" 或 "assistant"
    let content: String
    let createdAt: String?
    let timestamp: String?  // 兼容后端返回的 timestamp 字段
    let supplementaryMaterials: SupplementaryMaterials?  // 补充资料

    var isUser: Bool {
        return role == "user"
    }

    // 自定义解码，兼容 messageId 和 id 两种字段名
    enum CodingKeys: String, CodingKey {
        case conversationId
        case role
        case content
        case createdAt
        case timestamp
        case supplementaryMaterials
        case id
        case messageId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 优先使用 id，如果没有则使用 messageId
        if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else if let messageIdValue = try? container.decode(String.self, forKey: .messageId) {
            id = messageIdValue
        } else {
            // 如果都没有，生成一个默认 ID
            id = "msg_\(UUID().uuidString)"
        }
        
        conversationId = try? container.decode(String.self, forKey: .conversationId)
        role = try container.decode(String.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)

        // createdAt 和 timestamp 都可能存在
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        timestamp = try? container.decode(String.self, forKey: .timestamp)

        // 补充资料（可选）
        supplementaryMaterials = try? container.decode(SupplementaryMaterials.self, forKey: .supplementaryMaterials)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // 编码时使用 id 字段
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(conversationId, forKey: .conversationId)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(supplementaryMaterials, forKey: .supplementaryMaterials)
    }
}

/// 聊天响应
struct ChatResponse: Codable {
    let status: String
    let message: String?
    let data: ChatData?

    var success: Bool {
        return status.lowercased() == "success"
    }

    struct ChatData: Codable {
        let conversationId: String
        let messageId: String?
        let aiReply: String?  // AI回复内容
        let userMessage: String?
        let actionCard: ActionCard?
        let supplementaryMaterials: SupplementaryMaterials?
        let recommendedPosts: [RecommendedPost]?
        let timestamp: String?
        let tokenUsage: TokenUsage?

        // 兼容旧版本的字段
        let response: String?  // 兼容旧版本
        let jobId: String?
        let status: String?  // "processing", "completed", "failed"
        let estimatedTime: String?
        let useQueue: Bool?

        // 计算属性：优先使用 aiReply，否则使用 response
        var reply: String? {
            return aiReply ?? response
        }

        struct TokenUsage: Codable {
            let prompt: Int?
            let completion: Int?
            let total: Int?
        }
    }
}

/// 任务状态响应
struct JobStatusResponse: Codable {
    let status: String
    let message: String?
    let data: JobStatusData?

    var success: Bool {
        return status.lowercased() == "success"
    }

    struct JobStatusData: Codable {
        let jobId: String?
        let status: String // "processing", "completed", "failed"
        let response: String?
        let error: String?
        let result: JobResult?

        struct JobResult: Codable {
            let success: Bool?
            let conversationId: String?
            let messageId: String?  // 消息ID，用于生成海报
            let aiReply: String?
            let supplementaryMaterials: SupplementaryMaterials?
            let actionCard: ActionCard?  // 新增：动作卡片
            let tokenUsage: TokenUsage?

            struct TokenUsage: Codable {
                let prompt: Int?
                let completion: Int?
                let total: Int?
            }
        }
    }
}

// MARK: - 推荐帖子模型

/// 推荐帖子
struct RecommendedPost: Codable {
    let postId: String
    let content: String
    let tags: [String]
}

// MARK: - 动作卡片模型

/// 动作卡片（用于引导用户进行舌诊、面诊等操作）
struct ActionCard: Codable {
    let type: String  // "questionnaire" | "tongue_diagnosis" | "face_diagnosis"
    let diagnosisType: String?  // "tongue" | "face"（仅问卷卡片有此字段）
    let title: String
    let description: String
    let reason: String?
    let icon: String
    let action: ActionCardAction?
    let buttons: [ActionCardButton]
    let tips: [String]
    var isCompleted: Bool?  // 是否已完成（用于前端状态管理）

    // 便捷初始化器（用于手动创建）
    init(type: String, diagnosisType: String? = nil, title: String, description: String, reason: String? = nil, icon: String, action: ActionCardAction? = nil, buttons: [ActionCardButton], tips: [String], isCompleted: Bool? = nil) {
        self.type = type
        self.diagnosisType = diagnosisType
        self.title = title
        self.description = description
        self.reason = reason
        self.icon = icon
        self.action = action
        self.buttons = buttons
        self.tips = tips
        self.isCompleted = isCompleted
    }
}

/// 动作卡片的操作
struct ActionCardAction: Codable {
    let type: String  // "navigate" | "show_questionnaire"
    let route: String?  // "TongueDiagnosis" | "FaceDiagnosis" (仅 navigate 类型需要)
    let diagnosisType: String?  // "tongue" | "face" (仅 show_questionnaire 类型需要)
    let params: [String: ActionParamValue]?  // 支持混合类型的参数

    // 便捷初始化器（用于手动创建）
    init(type: String, route: String? = nil, diagnosisType: String? = nil, params: [String: ActionParamValue]? = nil) {
        self.type = type
        self.route = route
        self.diagnosisType = diagnosisType
        self.params = params
    }

    // 自定义解码器来处理混合类型的params
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        route = try container.decodeIfPresent(String.self, forKey: .route)
        diagnosisType = try container.decodeIfPresent(String.self, forKey: .diagnosisType)

        // 尝试解码params，支持混合类型
        if let paramsContainer = try? container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .params) {
            var decodedParams: [String: ActionParamValue] = [:]
            for key in paramsContainer.allKeys {
                if let value = try? paramsContainer.decode(ActionParamValue.self, forKey: key) {
                    decodedParams[key.stringValue] = value
                }
            }
            params = decodedParams.isEmpty ? nil : decodedParams
        } else {
            params = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(route, forKey: .route)
        try container.encodeIfPresent(diagnosisType, forKey: .diagnosisType)
        try container.encodeIfPresent(params, forKey: .params)
    }

    enum CodingKeys: String, CodingKey {
        case type, route, diagnosisType, params
    }
}

/// 动态编码键（用于解码未知键名的字典）
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

/// 动作参数值（支持字符串、布尔值、整数）
enum ActionParamValue: Codable {
    case string(String)
    case bool(Bool)
    case int(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                ActionParamValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String, Bool, or Int"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }

    // 便捷访问器
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }
}

/// 动作卡片的按钮
struct ActionCardButton: Codable {
    let text: String
    let type: String  // "primary" | "secondary" | "completed"
    let action: String  // "start_tongue_diagnosis" | "start_face_diagnosis" | "dismiss" | "start_questionnaire"
    var isDisabled: Bool?  // 是否禁用（用于前端状态管理）

    // 便捷初始化器（用于手动创建）
    init(text: String, type: String, action: String, isDisabled: Bool? = nil) {
        self.text = text
        self.type = type
        self.action = action
        self.isDisabled = isDisabled
    }
}

// MARK: - 问卷相关响应模型

/// 问卷响应
struct QuestionnaireResponse: Codable {
    let status: String?
    let code: Int?
    let success: Bool?
    let msg: String?
    let message: String?
    let data: QuestionnaireData?

    // 计算属性：兼容多种格式
    var isSuccess: Bool {
        // 优先使用 success 字段
        if let success = success {
            return success
        }
        // 其次检查 status 字段
        if let status = status {
            return status == "success"
        }
        // 最后检查 code 字段（200 或 0 都表示成功）
        if let code = code {
            return code == 0 || code == 200
        }
        return false
    }

    struct QuestionnaireData: Codable {
        let title: String?
        let description: String?
        let questions: [Question]
    }
}

/// 问卷问题
struct Question: Codable, Identifiable {
    let id: String
    let question: String
    let type: String  // "single_choice" | "multiple_choice" | "text"
    let options: [QuestionOption]?
    let required: Bool
}

/// 问题选项
struct QuestionOption: Codable, Identifiable {
    let value: String
    let label: String

    var id: String { value }
}

/// 保存问卷响应
struct SaveQuestionnaireResponse: Codable {
    let status: String?
    let code: Int?
    let success: Bool?
    let msg: String?
    let message: String?
    let data: SaveQuestionnaireData?

    // 计算属性：兼容多种格式
    var isSuccess: Bool {
        // 优先使用 success 字段
        if let success = success {
            return success
        }
        // 其次检查 status 字段
        if let status = status {
            return status == "success"
        }
        // 最后检查 code 字段（200 或 0 都表示成功）
        if let code = code {
            return code == 0 || code == 200
        }
        return false
    }

    struct SaveQuestionnaireData: Codable {
        let conversationId: String
        let messageId: String
        let diagnosisType: String?
        let message: String
        let timestamp: String
    }
}

/// 问卷完成响应
struct QuestionnaireCompletedResponse: Codable {
    let status: String?
    let code: Int?
    let success: Bool?
    let msg: String?
    let message: String?
    let data: QuestionnaireCompletedData?

    // 计算属性：兼容多种格式
    var isSuccess: Bool {
        // 优先使用 success 字段
        if let success = success {
            return success
        }
        // 其次检查 status 字段
        if let status = status {
            return status == "success"
        }
        // 最后检查 code 字段（200 或 0 都表示成功）
        if let code = code {
            return code == 0 || code == 200
        }
        return false
    }

    struct QuestionnaireCompletedData: Codable {
        let conversationId: String
        let diagnosisType: String
        let actionCard: ActionCard
        let message: String
        let timestamp: String
    }
}

/// 诊断结果响应
struct DiagnosisResultResponse: Codable {
    let status: String?
    let code: Int?
    let success: Bool?
    let msg: String?
    let message: String?
    let data: DiagnosisResultData?

    // 计算属性：兼容多种格式
    var isSuccess: Bool {
        // 优先使用 success 字段
        if let success = success {
            return success
        }
        // 其次检查 status 字段
        if let status = status {
            return status == "success"
        }
        // 最后检查 code 字段（200 或 0 都表示成功）
        if let code = code {
            return code == 0 || code == 200
        }
        return false
    }

    struct DiagnosisResultData: Codable {
        let conversationId: String
        let messageId: String
        let diagnosisMessage: String
        let aiReply: String
        let supplementaryMaterials: SupplementaryMaterials?
        let actionCard: ActionCard?
        let timestamp: String
    }
}

// MARK: - 博查搜索补充资料模型

/// 补充资料
struct SupplementaryMaterials: Codable {
    let webPages: [WebPage]?
    let images: [ImageResult]?
    let videos: [VideoResult]?
    let modalCards: [ModalCard]?
}

/// 网页文献
struct WebPage: Codable, Identifiable {
    let title: String
    let url: String
    let snippet: String
    let source: String
    let publishDate: String?
    let siteName: String?

    var id: String { url }
}

/// 图片资料
struct ImageResult: Codable, Identifiable {
    let thumbnailUrl: String
    let contentUrl: String
    let hostPageUrl: String
    let hostPageDisplayUrl: String?  // 改为可选,服务器可能不返回
    let width: Int?
    let height: Int?
    let name: String?
    let type: String?  // 改为可选,服务器可能不返回
    let encodingFormat: String?  // 新增字段,服务器可能返回

    var id: String { contentUrl }

    // 提供默认的 displayUrl,如果服务器没有返回
    var displayUrl: String {
        if let hostPageDisplayUrl = hostPageDisplayUrl {
            return hostPageDisplayUrl
        }
        // 从 hostPageUrl 提取域名作为 displayUrl
        if let url = URL(string: hostPageUrl) {
            return url.host ?? hostPageUrl
        }
        return hostPageUrl
    }
}

/// 视频资料
struct VideoResult: Codable, Identifiable {
    let name: String
    let description: String?
    let thumbnailUrl: String
    let contentUrl: String?
    let hostPageUrl: String
    let duration: String?
    let publisher: String?
    let viewCount: Int?
    let type: String

    var id: String { hostPageUrl }
}

/// 多模态卡
struct ModalCard: Codable, Identifiable {
    let type: String
    // content 可能是复杂的嵌套结构，暂时用字典处理
    // 如果需要更详细的解析，可以根据 type 创建不同的子结构

    var id: String { type + UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case type
    }
}

// MARK: - 海报生成响应

/// 海报生成响应
struct PosterResponse: Codable {
    let status: String?
    let success: Bool?
    let message: String?
    let data: PosterData?

    // 计算属性：兼容多种格式
    var isSuccess: Bool {
        // 优先使用 success 字段
        if let success = success {
            return success
        }
        // 其次检查 status 字段
        if let status = status {
            return status == "success"
        }
        return false
    }
}

/// 海报数据
struct PosterData: Codable {
    let posterUrl: String
    let shareUrl: String?
    let theme: String?
    let style: String?
    let timestamp: String?
    let messageCount: Int?
}

// MARK: - 快捷提示语响应

/// 快捷提示语响应
struct QuickPromptsResponse: Codable {
    let status: String
    let message: String
    let data: QuickPromptsData?
}

/// 快捷提示语数据
struct QuickPromptsData: Codable {
    let prompts: [QuickPrompt]
    let total: Int
}

/// 快捷提示语模型
struct QuickPrompt: Codable, Identifiable {
    let promptId: String
    let promptText: String
    let icon: String
    let category: String
    let priority: Int
    let isSystemPreset: Bool
    let sortOrder: Int

    var id: String { promptId }
}

/// 提示语分类枚举
enum PromptCategory: String, CaseIterable {
    case constitution = "constitution"  // 体质
    case diet = "diet"                  // 饮食
    case exercise = "exercise"          // 运动
    case sleep = "sleep"                // 睡眠
    case diagnosis = "diagnosis"        // 诊断
    case seasonal = "seasonal"          // 时令
    case emotion = "emotion"            // 情绪
    case general = "general"            // 通用

    var displayName: String {
        switch self {
        case .constitution: return "体质调理"
        case .diet: return "饮食养生"
        case .exercise: return "运动健身"
        case .sleep: return "睡眠改善"
        case .diagnosis: return "健康诊断"
        case .seasonal: return "时令养生"
        case .emotion: return "情绪调节"
        case .general: return "通用咨询"
        }
    }
}
