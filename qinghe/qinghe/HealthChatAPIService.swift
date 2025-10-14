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

    /// 发送消息
    func sendMessage(message: String, conversationId: String?) async throws -> ChatResponse {
        print("🌐 API请求: POST /health/chat")
        var parameters: [String: Any] = ["message": message]
        if let conversationId = conversationId {
            parameters["conversationId"] = conversationId
        }

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
        let response: String?
        let jobId: String?
        let status: String // "processing", "completed", "failed"
        let userMessage: String?
        let estimatedTime: String?
        let useQueue: Bool?
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
            let aiReply: String?
            let tokenUsage: TokenUsage?

            struct TokenUsage: Codable {
                let prompt: Int?
                let completion: Int?
                let total: Int?
            }
        }
    }
}
