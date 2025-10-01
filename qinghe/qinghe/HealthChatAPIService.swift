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
        let lastMessage: String?
        let messageCount: Int?
        let createdAt: String
        let updatedAt: String
    }
}

/// 对话消息响应
struct ConversationMessagesResponse: Codable {
    let success: Bool
    let message: String?
    let data: ConversationMessagesData?

    struct ConversationMessagesData: Codable {
        let conversationId: String
        let messages: [HealthChatMessage]
        let total: Int
        let page: Int
        let limit: Int
    }
}

/// 健康对话消息
struct HealthChatMessage: Codable, Identifiable {
    let id: String
    let conversationId: String
    let role: String // "user" 或 "assistant"
    let content: String
    let createdAt: String

    var isUser: Bool {
        return role == "user"
    }
}

/// 聊天响应
struct ChatResponse: Codable {
    let success: Bool
    let message: String?
    let data: ChatData?

    struct ChatData: Codable {
        let conversationId: String
        let messageId: String
        let response: String?
        let jobId: String?
        let status: String // "processing", "completed", "failed"
    }
}

/// 任务状态响应
struct JobStatusResponse: Codable {
    let success: Bool
    let message: String?
    let data: JobStatusData?

    struct JobStatusData: Codable {
        let jobId: String
        let status: String // "processing", "completed", "failed"
        let response: String?
        let error: String?
    }
}
