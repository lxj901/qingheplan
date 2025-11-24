import Foundation
import Combine
import UIKit

/// 聊天API服务
class ChatAPIService: ObservableObject {
    static let shared = ChatAPIService()
    
    private let networkManager = NetworkManager.shared
    private let authManager = AuthManager.shared
    
    private init() {}
    
    // MARK: - API端点
    private enum Endpoint {
        static let conversations = "/messages/conversations"
        static let privateChat = "/messages/conversations/private"
        static let groupChat = "/messages/conversations/group"
        static let messages = "/messages/messages"
        static let groups = "/messages/groups"
        static let search = "/messages/messages/search"
        static let export = "/messages/conversations"
        static let statistics = "/messages/conversations"
        static let deviceToken = "/push/device-token"
        static let markAsRead = "/messages/conversations"
    }
    
    // MARK: - 会话管理
    
    /// 获取聊天列表
    /// - Parameters:
    ///   - tab: 筛选类型：all(全部)、unread(未读)
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 聊天列表响应
    func getChatList(
        tab: String = "all",
        page: Int = 1,
        limit: Int = 20
    ) async throws -> ChatListResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let parameters: [String: Any] = [
            "tab": tab,
            "page": page,
            "limit": limit
        ]

        let response: ChatAPIResponse<ChatListResponse> = try await networkManager.get(
            endpoint: Endpoint.conversations,
            parameters: parameters,
            headers: authHeaders,
            responseType: ChatAPIResponse<ChatListResponse>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取聊天列表失败")
        }

        return data
    }

    /// 兼容旧版本的获取聊天列表方法
    func getChatList(
        page: Int = 1,
        limit: Int = 20,
        type: ConversationType? = nil,
        keyword: String? = nil
    ) async throws -> ChatListResponse {
        var tab = "all"
        if let type = type {
            switch type {
            case .privateChat:
                tab = "private"
            case .group:
                tab = "group"
            default:
                tab = "all"
            }
        }

        return try await getChatList(tab: tab, page: page, limit: limit)
    }
    
    /// 创建私聊对话
    /// - Parameters:
    ///   - recipientId: 接收者ID
    ///   - initialMessage: 初始消息
    /// - Returns: 新创建的会话
    func createPrivateChat(
        recipientId: Int,
        initialMessage: String? = nil
    ) async throws -> ChatConversation {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let request = CreatePrivateChatRequest(
            recipientId: recipientId,
            initialMessage: initialMessage
        )

        let response: ChatAPIResponse<ChatConversation> = try await networkManager.post(
            endpoint: Endpoint.privateChat,
            parameters: try request.toDictionary(),
            headers: authHeaders,
            responseType: ChatAPIResponse<ChatConversation>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "创建私聊失败")
        }

        return data
    }

    /// 创建群聊
    /// - Parameters:
    ///   - name: 群聊名称
    ///   - description: 群聊描述
    ///   - avatar: 群聊头像URL
    ///   - memberIds: 成员ID列表
    /// - Returns: 新创建的群聊
    func createGroupChat(
        name: String,
        description: String? = nil,
        avatar: String? = nil,
        memberIds: [Int]
    ) async throws -> ChatConversation {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let request = CreateGroupChatRequest(
            name: name,
            description: description,
            avatar: avatar,
            memberIds: memberIds
        )

        let response: ChatAPIResponse<ChatConversation> = try await networkManager.post(
            endpoint: Endpoint.groupChat,
            parameters: try request.toDictionary(),
            headers: authHeaders,
            responseType: ChatAPIResponse<ChatConversation>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "创建群聊失败")
        }

        return data
    }

    /// 兼容旧版本的创建会话方法
    func createConversation(
        type: ConversationType,
        participantIds: [Int],
        title: String? = nil
    ) async throws -> ChatConversation {
        switch type {
        case .privateChat:
            guard let recipientId = participantIds.first else {
                throw NetworkManager.NetworkError.networkError("私聊需要指定接收者")
            }
            return try await createPrivateChat(recipientId: recipientId)
        case .group:
            let groupName = title ?? "新群聊"
            return try await createGroupChat(name: groupName, memberIds: participantIds)
        case .system:
            throw NetworkManager.NetworkError.networkError("不支持创建系统会话")
        }
    }

    /// 获取对话详情
    /// - Parameter conversationId: 对话ID
    /// - Returns: 对话详情
    func getConversationDetail(conversationId: String) async throws -> ChatConversation {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: ChatAPIResponse<ChatConversation> = try await networkManager.get(
            endpoint: "\(Endpoint.conversations)/\(conversationId)",
            headers: authHeaders,
            responseType: ChatAPIResponse<ChatConversation>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取对话详情失败")
        }

        return data
    }
    
    // MARK: - 消息管理
    
    /// 获取消息历史
    /// - Parameters:
    ///   - conversationId: 会话ID
    ///   - before: 获取此消息ID之前的消息
    ///   - limit: 每页数量
    /// - Returns: 消息列表响应
    func getMessages(
        conversationId: String,
        before: String? = nil,
        limit: Int = 20
    ) async throws -> MessageListResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        var parameters: [String: Any] = [
            "limit": limit
        ]

        if let before = before {
            parameters["before"] = before
        }

        let response: ChatAPIResponse<MessageListResponse> = try await networkManager.get(
            endpoint: "\(Endpoint.conversations)/\(conversationId)/messages",
            parameters: parameters,
            headers: authHeaders,
            responseType: ChatAPIResponse<MessageListResponse>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取消息列表失败")
        }

        return data
    }

    /// 兼容旧版本的获取消息方法
    func getMessages(
        conversationId: String,
        page: Int = 1,
        limit: Int = 50,
        beforeMessageId: String? = nil
    ) async throws -> MessageListResponse {
        return try await getMessages(
            conversationId: conversationId,
            before: beforeMessageId,
            limit: limit
        )
    }
    
    /// 发送消息
    /// - Parameters:
    ///   - conversationId: 会话ID
    ///   - content: 消息内容
    ///   - type: 消息类型
    ///   - mediaUrl: 媒体文件URL
    ///   - mediaDuration: 媒体时长
    ///   - thumbnailUrl: 缩略图URL
    ///   - replyToMessageId: 回复的消息ID
    /// - Returns: 发送的消息
    func sendMessage(
        conversationId: String,
        content: String,
        type: MessageType = .text,
        mediaUrl: String? = nil,
        mediaDuration: Int? = nil,
        thumbnailUrl: String? = nil,
        replyToMessageId: String? = nil
    ) async throws -> ChatMessage {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let request = SendMessageRequest(
            content: content,
            type: type,
            mediaUrl: mediaUrl,
            mediaDuration: mediaDuration,
            thumbnailUrl: thumbnailUrl,
            replyToMessageId: replyToMessageId
        )

        let response: ChatAPIResponse<ChatMessage> = try await networkManager.post(
            endpoint: "\(Endpoint.conversations)/\(conversationId)/messages",
            parameters: try request.toDictionary(),
            headers: authHeaders,
            responseType: ChatAPIResponse<ChatMessage>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "发送消息失败")
        }

        return data
    }

    /// 兼容旧版本的发送消息方法
    func sendMessage(
        conversationId: String,
        content: String,
        type: MessageType = .text,
        replyToMessageId: String? = nil,
        attachments: [String]? = nil
    ) async throws -> ChatMessage {
        let mediaUrl = attachments?.first
        return try await sendMessage(
            conversationId: conversationId,
            content: content,
            type: type,
            mediaUrl: mediaUrl,
            replyToMessageId: replyToMessageId
        )
    }
    
    /// 标记消息为已读
    /// - Parameters:
    ///   - conversationId: 会话ID
    ///   - lastReadMessageId: 最后读取的消息ID
    func markAsRead(conversationId: String, lastReadMessageId: String) async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let request = MarkAsReadRequest(lastReadMessageId: lastReadMessageId)

        // 使用 PUT 方法标记已读
        let response: ChatAPIResponse<EmptyResponse> = try await networkManager.put(
            endpoint: "\(Endpoint.conversations)/\(conversationId)/read",
            parameters: try request.toDictionary(),
            headers: authHeaders,
            responseType: ChatAPIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "标记已读失败")
        }

        print("✅ 标记已读成功 - conversationId: \(conversationId), messageId: \(lastReadMessageId)")
    }

    /// 兼容旧版本的标记已读方法
    func markAsRead(conversationId: String, messageId: String? = nil) async throws {
        guard let messageId = messageId else {
            throw NetworkManager.NetworkError.networkError("需要指定消息ID")
        }
        try await markAsRead(conversationId: conversationId, lastReadMessageId: messageId)
    }

    /// 标记会话为未读
    /// - Parameter conversationId: 会话ID
    func markAsUnread(conversationId: String) async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: ChatAPIResponse<EmptyResponse> = try await networkManager.post(
            endpoint: "\(Endpoint.conversations)/\(conversationId)/unread",
            parameters: [:],
            headers: authHeaders,
            responseType: ChatAPIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "标记未读失败")
        }
    }
    


    /// 转发消息到单个会话
    /// - Parameters:
    ///   - messageId: 消息ID
    ///   - toConversationId: 目标对话ID
    func forwardMessage(messageId: String, toConversationId: String) async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let request = ForwardMessageRequest(conversationIds: [toConversationId])

        let response: ChatAPIResponse<ForwardMessageResponse> = try await networkManager.post(
            endpoint: "\(Endpoint.messages)/\(messageId)/forward",
            parameters: try request.toDictionary(),
            headers: authHeaders,
            responseType: ChatAPIResponse<ForwardMessageResponse>.self
        )

        guard response.isSuccess else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "转发消息失败")
        }
    }

    /// 转发消息到多个会话
    /// - Parameters:
    ///   - messageId: 消息ID
    ///   - conversationIds: 目标对话ID列表
    /// - Returns: 转发成功的数量
    func forwardMessage(messageId: String, conversationIds: [String]) async throws -> Int {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let request = ForwardMessageRequest(conversationIds: conversationIds)

        let response: ChatAPIResponse<ForwardMessageResponse> = try await networkManager.post(
            endpoint: "\(Endpoint.messages)/\(messageId)/forward",
            parameters: try request.toDictionary(),
            headers: authHeaders,
            responseType: ChatAPIResponse<ForwardMessageResponse>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "转发消息失败")
        }

        return data.forwardedCount
    }

    // MARK: - 附件管理

    /// 上传附件
    /// - Parameters:
    ///   - data: 文件数据
    ///   - fileName: 文件名
    ///   - mimeType: MIME类型
    /// - Returns: 附件URL
    func uploadAttachment(
        data: Data,
        fileName: String,
        mimeType: String
    ) async throws -> String {
        guard authManager.getAuthHeader() != nil else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        // 这里需要实现文件上传逻辑
        // 由于NetworkManager可能需要扩展支持multipart/form-data
        // 暂时返回模拟URL

        // TODO: 实现真实的文件上传
        throw NetworkManager.NetworkError.networkError("文件上传功能待实现")
    }

    /// 上传图片
    /// - Parameter image: UIImage对象
    /// - Returns: 图片上传响应
    func uploadImage(_ image: UIImage) async throws -> ImageUploadResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        // 压缩图片
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkManager.NetworkError.networkError("图片处理失败")
        }

        // 使用URLSession进行multipart上传
        let url = URL(string: "\(networkManager.baseURL)/upload/image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // 添加认证头
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // 创建multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkManager.NetworkError.networkError("图片上传失败")
        }

        let apiResponse = try JSONDecoder().decode(ChatAPIResponse<ImageUploadResponse>.self, from: data)

        guard apiResponse.isSuccess, let uploadResponse = apiResponse.data else {
            throw NetworkManager.NetworkError.networkError(apiResponse.message ?? "图片上传失败")
        }

        return uploadResponse
    }

    /// 上传语音文件
    /// - Parameter url: 语音文件URL
    /// - Returns: 语音上传响应
    func uploadAudio(_ url: URL) async throws -> AudioUploadResponse {
        print("🎵 开始上传语音文件: \(url.lastPathComponent)")

        guard let authHeaders = authManager.getAuthHeader() else {
            print("❌ 语音上传失败: 未授权")
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        // 读取文件数据
        let audioData = try Data(contentsOf: url)
        let fileName = url.lastPathComponent
        print("🎵 音频文件大小: \(audioData.count) 字节")

        // 使用URLSession进行multipart上传
        let uploadURL = URL(string: "\(networkManager.baseURL)/upload/audio")!
        print("🎵 上传URL: \(uploadURL.absoluteString)")

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30.0

        // 添加认证头
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // 创建multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        print("🎵 请求体大小: \(body.count) 字节")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("🎵 上传响应状态码: \(httpResponse.statusCode)")

                if httpResponse.statusCode != 200 {
                    let responseString = String(data: data, encoding: .utf8) ?? "无响应内容"
                    print("❌ 语音上传失败，响应: \(responseString)")
                    throw NetworkManager.NetworkError.networkError("语音上传失败，状态码: \(httpResponse.statusCode)")
                }
            }

            let responseString = String(data: data, encoding: .utf8) ?? "无法解析响应"
            print("🎵 上传响应内容: \(responseString)")

            // 先尝试解析为文档上传响应
            let docApiResponse = try JSONDecoder().decode(ChatAPIResponse<DocumentUploadResponse>.self, from: data)

            guard docApiResponse.isSuccess, let docUploadResponse = docApiResponse.data else {
                print("❌ 语音上传API响应失败: \(docApiResponse.message ?? "未知错误")")
                throw NetworkManager.NetworkError.networkError(docApiResponse.message ?? "语音上传失败")
            }

            // 转换为语音上传响应格式
            let audioUploadResponse = AudioUploadResponse(
                url: docUploadResponse.url,
                filename: docUploadResponse.filename,
                originalName: docUploadResponse.originalName,
                size: docUploadResponse.size,
                duration: nil, // 服务器可能不返回时长，客户端计算
                mimetype: docUploadResponse.mimetype,
                provider: docUploadResponse.provider
            )

            print("✅ 语音上传成功: \(audioUploadResponse.url)")
            return audioUploadResponse

        } catch {
            print("❌ 语音上传网络错误: \(error)")
            throw NetworkManager.NetworkError.networkError("语音上传失败: \(error.localizedDescription)")
        }
    }

    /// 上传文档
    /// - Parameter url: 文档文件URL
    /// - Returns: 文档上传响应
    func uploadDocument(_ url: URL) async throws -> DocumentUploadResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        // 检查文件访问权限
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw NetworkManager.NetworkError.networkError("文件不可读或不存在")
        }

        // 读取文件数据
        let fileData: Data
        do {
            fileData = try Data(contentsOf: url)
        } catch {
            throw NetworkManager.NetworkError.networkError("读取文件失败: \(error.localizedDescription)")
        }

        let fileName = url.lastPathComponent
        let mimeType = getMimeType(for: url.pathExtension)

        print("📁 文档上传开始")
        print("📁 文件名: \(fileName)")
        print("📁 文件类型: \(mimeType)")
        print("📁 文件大小: \(fileData.count) 字节")

        // 检查文件大小（限制为50MB）
        let maxFileSize = 50 * 1024 * 1024 // 50MB
        guard fileData.count <= maxFileSize else {
            throw NetworkManager.NetworkError.networkError("文件大小超过限制（最大50MB）")
        }

        // 根据文件类型选择合适的上传端点
        let uploadEndpoint = getUploadEndpoint(for: url.pathExtension)
        let fieldName = getFieldName(for: url.pathExtension)

        print("📁 选择的端点: \(uploadEndpoint)")
        print("📁 字段名: \(fieldName)")

        // 对于已知的媒体类型，直接使用对应端点
        let fileExtension = url.pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "gif", "webp", "mp3", "m4a", "wav", "aac", "mp4", "mov", "avi"].contains(fileExtension) {
            // 使用标准的单端点上传
            return try await uploadToSingleEndpoint(
                endpoint: uploadEndpoint,
                fieldName: fieldName,
                fileData: fileData,
                fileName: fileName,
                mimeType: mimeType,
                authHeaders: authHeaders
            )
        } else {
            // 对于文档类型，使用备用方案
            return try await uploadDocumentWithFallback(
                fileData: fileData,
                fileName: fileName,
                mimeType: mimeType,
                authHeaders: authHeaders
            )
        }
    }

    /// 获取文件MIME类型
    private func getMimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls":
            return "application/vnd.ms-excel"
        case "xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "ppt":
            return "application/vnd.ms-powerpoint"
        case "pptx":
            return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "txt":
            return "text/plain"
        case "zip":
            return "application/zip"
        case "rar":
            return "application/x-rar-compressed"
        // 图片类型
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        // 音频类型
        case "mp3":
            return "audio/mpeg"
        case "m4a":
            return "audio/m4a"
        case "wav":
            return "audio/wav"
        case "aac":
            return "audio/aac"
        // 视频类型
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        default:
            return "application/octet-stream"
        }
    }

    /// 根据文件扩展名获取上传端点
    private func getUploadEndpoint(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "webp":
            return "/upload/image"
        case "mp3", "m4a", "wav", "aac":
            return "/upload/audio"
        case "mp4", "mov", "avi":
            return "/upload/video"
        default:
            // 对于文档类型，先尝试使用图片端点
            // 如果后端支持通用文件上传，可能会接受
            return "/upload/image"
        }
    }

    /// 根据文件扩展名获取表单字段名
    private func getFieldName(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "webp":
            return "image"
        case "mp3", "m4a", "wav", "aac":
            return "audio"
        case "mp4", "mov", "avi":
            return "video"
        default:
            // 对于文档类型，使用file字段名
            // 如果后端不支持，会返回错误
            return "file"
        }
    }

    /// 尝试多个端点上传文档
    private func uploadDocumentWithFallback(
        fileData: Data,
        fileName: String,
        mimeType: String,
        authHeaders: [String: String]
    ) async throws -> DocumentUploadResponse {

        // 尝试的端点列表（按优先级排序）
        let endpoints = [
            ("/upload/image", "image"),  // 很多后端的图片端点支持任意文件
            ("/upload/audio", "audio"),  // 音频端点可能也支持
            ("/upload/video", "video")   // 视频端点作为最后尝试
        ]

        var lastError: Error?

        for (endpoint, fieldName) in endpoints {
            do {
                print("📁 尝试端点: \(endpoint) 字段名: \(fieldName)")

                let uploadURL = URL(string: "\(networkManager.baseURL)\(endpoint)")!
                var request = URLRequest(url: uploadURL)
                request.httpMethod = "POST"
                request.timeoutInterval = 60.0

                // 添加认证头
                for (key, value) in authHeaders {
                    request.setValue(value, forHTTPHeaderField: key)
                }

                // 创建multipart form data
                let boundary = UUID().uuidString
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

                var body = Data()
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                body.append(fileData)
                body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

                request.httpBody = body

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkManager.NetworkError.networkError("无效的服务器响应")
                }

                print("📁 端点 \(endpoint) 响应状态码: \(httpResponse.statusCode)")

                if httpResponse.statusCode == 200 {
                    // 成功，解析响应
                    let apiResponse = try JSONDecoder().decode(ChatAPIResponse<DocumentUploadResponse>.self, from: data)

                    guard apiResponse.isSuccess, let uploadResponse = apiResponse.data else {
                        throw NetworkManager.NetworkError.networkError(apiResponse.message ?? "文档上传失败")
                    }

                    print("✅ 文档上传成功，使用端点: \(endpoint)")
                    return uploadResponse
                } else {
                    // 这个端点失败，尝试下一个
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("⚠️ 端点 \(endpoint) 失败: \(responseString)")
                    }
                    lastError = NetworkManager.NetworkError.networkError("端点 \(endpoint) 返回状态码: \(httpResponse.statusCode)")
                }

            } catch {
                print("⚠️ 端点 \(endpoint) 出错: \(error.localizedDescription)")
                lastError = error
                continue
            }
        }

        // 所有端点都失败了
        throw lastError ?? NetworkManager.NetworkError.networkError("所有上传端点都失败了")
    }

    /// 上传到单个端点
    private func uploadToSingleEndpoint(
        endpoint: String,
        fieldName: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        authHeaders: [String: String]
    ) async throws -> DocumentUploadResponse {

        print("📁 使用单端点上传: \(endpoint)")

        let uploadURL = URL(string: "\(networkManager.baseURL)\(endpoint)")!
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 60.0

        // 添加认证头
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // 创建multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkManager.NetworkError.networkError("无效的服务器响应")
        }

        print("📁 HTTP状态码: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("📁 服务器响应: \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            // 尝试解析错误信息
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorResponse["message"] as? String {
                throw NetworkManager.NetworkError.networkError("文件上传失败: \(message)")
            }
            throw NetworkManager.NetworkError.networkError("文件上传失败，状态码: \(httpResponse.statusCode)")
        }

        let apiResponse = try JSONDecoder().decode(ChatAPIResponse<DocumentUploadResponse>.self, from: data)

        guard apiResponse.isSuccess, let uploadResponse = apiResponse.data else {
            throw NetworkManager.NetworkError.networkError(apiResponse.message ?? "文件上传失败")
        }

        return uploadResponse
    }
    
    // MARK: - 群聊管理

    /// 添加群成员
    /// - Parameters:
    ///   - groupId: 群ID
    ///   - memberIds: 成员ID列表
    /// - Returns: 添加成功的用户信息
    func addGroupMembers(groupId: String, memberIds: [Int]) async throws -> [ChatUser] {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let request = AddGroupMembersRequest(memberIds: memberIds)

        let response: ChatAPIResponse<AddGroupMembersResponse> = try await networkManager.post(
            endpoint: "\(Endpoint.groups)/\(groupId)/members",
            parameters: try request.toDictionary(),
            headers: authHeaders,
            responseType: ChatAPIResponse<AddGroupMembersResponse>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "添加群成员失败")
        }

        return data.addedUsers
    }

    /// 移除群成员
    /// - Parameters:
    ///   - groupId: 群ID
    ///   - memberId: 成员ID
    func removeGroupMember(groupId: String, memberId: String) async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: ChatAPIResponse<EmptyResponse> = try await networkManager.delete(
            endpoint: "\(Endpoint.groups)/\(groupId)/members/\(memberId)",
            headers: authHeaders,
            responseType: ChatAPIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "移除群成员失败")
        }
    }

    /// 更新群信息
    /// - Parameters:
    ///   - groupId: 群ID
    ///   - name: 群名称
    ///   - description: 群描述
    ///   - avatar: 群头像URL
    func updateGroupInfo(
        groupId: String,
        name: String? = nil,
        description: String? = nil,
        avatar: String? = nil
    ) async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let request = UpdateGroupInfoRequest(
            name: name,
            description: description,
            avatar: avatar
        )

        let response: ChatAPIResponse<EmptyResponse> = try await networkManager.put(
            endpoint: "\(Endpoint.groups)/\(groupId)",
            parameters: try request.toDictionary(),
            headers: authHeaders,
            responseType: ChatAPIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "更新群信息失败")
        }
    }

    /// 退出群聊
    /// - Parameter groupId: 群ID
    func leaveGroup(groupId: String) async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: ChatAPIResponse<EmptyResponse> = try await networkManager.post(
            endpoint: "\(Endpoint.groups)/\(groupId)/leave",
            parameters: [:],
            headers: authHeaders,
            responseType: ChatAPIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "退出群聊失败")
        }
    }

    // MARK: - 会话操作

    /// 删除会话
    /// - Parameter conversationId: 会话ID
    func deleteConversation(conversationId: String) async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: ChatAPIResponse<EmptyResponse> = try await networkManager.delete(
            endpoint: "\(Endpoint.conversations)/\(conversationId)",
            headers: authHeaders,
            responseType: ChatAPIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "删除会话失败")
        }
    }
    
    /// 置顶/取消置顶会话
    /// - Parameters:
    ///   - conversationId: 会话ID
    ///   - isPinned: 是否置顶
    func pinConversation(conversationId: String, isPinned: Bool) async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        let parameters = ["isPinned": isPinned]
        
        let response: ChatAPIResponse<EmptyResponse> = try await networkManager.put(
            endpoint: "\(Endpoint.conversations)/\(conversationId)/pin",
            parameters: parameters,
            headers: authHeaders,
            responseType: ChatAPIResponse<EmptyResponse>.self
        )
        
        guard response.isSuccess else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "操作失败")
        }
    }
    
    /// 静音/取消静音会话
    /// - Parameters:
    ///   - conversationId: 会话ID
    ///   - isMuted: 是否静音
    func muteConversation(conversationId: String, isMuted: Bool) async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let parameters = ["isMuted": isMuted]

        let response: ChatAPIResponse<EmptyResponse> = try await networkManager.put(
            endpoint: "\(Endpoint.conversations)/\(conversationId)/mute",
            parameters: parameters,
            headers: authHeaders,
            responseType: ChatAPIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "操作失败")
        }
    }

    // MARK: - 高级功能

    /// 搜索消息
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - conversationId: 限制在指定对话中搜索（可选）
    ///   - page: 页码
    /// - Returns: 搜索结果
    func searchMessages(
        query: String,
        conversationId: String? = nil,
        page: Int = 1
    ) async throws -> MessageListResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        var parameters: [String: Any] = [
            "q": query,
            "page": page
        ]

        if let conversationId = conversationId {
            parameters["conversationId"] = conversationId
        }

        let response: ChatAPIResponse<MessageListResponse> = try await networkManager.get(
            endpoint: Endpoint.search,
            parameters: parameters,
            headers: authHeaders,
            responseType: ChatAPIResponse<MessageListResponse>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "搜索失败")
        }

        return data
    }

    /// 导出聊天记录
    /// - Parameters:
    ///   - conversationId: 对话ID
    ///   - format: 导出格式：json、txt、download
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 导出结果URL或数据
    func exportChatHistory(
        conversationId: String,
        format: String = "json",
        startDate: String? = nil,
        endDate: String? = nil
    ) async throws -> String {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        var parameters: [String: Any] = [
            "format": format
        ]

        if let startDate = startDate {
            parameters["startDate"] = startDate
        }

        if let endDate = endDate {
            parameters["endDate"] = endDate
        }

        let response: ChatAPIResponse<ExportChatHistoryResponse> = try await networkManager.get(
            endpoint: "\(Endpoint.export)/\(conversationId)/export",
            parameters: parameters,
            headers: authHeaders,
            responseType: ChatAPIResponse<ExportChatHistoryResponse>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "导出失败")
        }

        return data.url ?? data.data ?? ""
    }

    /// 获取聊天统计
    /// - Parameter conversationId: 对话ID
    /// - Returns: 统计信息
    func getChatStatistics(conversationId: String) async throws -> ChatStatisticsResponse {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: ChatAPIResponse<ChatStatisticsResponse> = try await networkManager.get(
            endpoint: "\(Endpoint.statistics)/\(conversationId)/statistics",
            headers: authHeaders,
            responseType: ChatAPIResponse<ChatStatisticsResponse>.self
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取统计信息失败")
        }

        return data
    }



    // MARK: - 推送通知相关

    /// 上传设备Token
    /// - Parameter deviceToken: 设备Token
    func uploadDeviceToken(_ deviceToken: String) async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let systemVersion = await UIDevice.current.systemVersion
        let parameters: [String: Any] = [
            "deviceToken": deviceToken,
            "platform": "ios",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            "systemVersion": systemVersion
        ]

        let response: ChatAPIResponse<EmptyResponse> = try await networkManager.post(
            endpoint: Endpoint.deviceToken,
            parameters: parameters,
            headers: authHeaders,
            responseType: ChatAPIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "设备Token上传失败")
        }
    }

    /// 标记对话为已读（已废弃，请使用 markAsRead(conversationId:lastReadMessageId:)）
    /// - Parameter conversationId: 对话ID
    @available(*, deprecated, message: "请使用 markAsRead(conversationId:lastReadMessageId:) 方法")
    func markConversationAsRead(conversationId: String) async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let endpoint = "\(Endpoint.markAsRead)/\(conversationId)/read"
        let parameters: [String: Any] = [
            "readAt": ISO8601DateFormatter().string(from: Date())
        ]

        // 使用 PUT 方法
        let response: ChatAPIResponse<EmptyResponse> = try await networkManager.put(
            endpoint: endpoint,
            parameters: parameters,
            headers: authHeaders,
            responseType: ChatAPIResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "标记已读失败")
        }
    }

    /// 获取对话列表（用于角标计算）
    /// - Parameters:
    ///   - tab: 筛选类型
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 对话列表
    func getConversations(tab: String = "all", page: Int = 1, limit: Int = 100) async throws -> ChatListResponse {
        return try await getChatList(tab: tab, page: page, limit: limit)
    }
}
