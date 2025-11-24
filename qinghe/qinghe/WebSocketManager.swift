import Foundation
import Network
import Combine
import UIKit

/// WebSocket实时通信管理器
@MainActor
class WebSocketManager: NSObject, ObservableObject {
    static let shared = WebSocketManager()
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var receivedMessages: [WebSocketMessage] = []
    @Published var userStatuses: [Int: UserStatus] = [:]
    @Published var typingUsers: [String: Set<Int>] = [:] // conversationId -> Set of userIds
    
    // MARK: - Private Properties
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var heartbeatTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let heartbeatInterval: TimeInterval = 30
    private let reconnectInterval: TimeInterval = 5
    
    // Network monitoring
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    // Configuration
    private let baseURL = "wss://api.qinghejihua.com.cn/ws"
    
    private override init() {
        super.init()
        setupNetworkMonitoring()
    }
    
    deinit {
        Task { @MainActor in
            disconnect()
        }
        monitor.cancel()
    }
    
    // MARK: - Public Methods
    
    /// 连接WebSocket
    func connect() {
        guard !isConnected else {
            print("WebSocket: 已经连接，跳过重复连接")
            return
        }

        guard let token = AuthManager.shared.getToken() else {
            print("WebSocket连接失败：缺少认证token")
            connectionStatus = .failed("缺少认证token")
            return
        }

        // 使用 URLComponents 确保查询参数正确编码
        var components = URLComponents(string: baseURL)
        components?.queryItems = [URLQueryItem(name: "token", value: token)]
        guard let url = components?.url else {
            print("WebSocket连接失败：无效的URL")
            connectionStatus = .failed("无效的URL")
            return
        }

        print("WebSocket: 开始连接到 \(url)")
        connectionStatus = .connecting

        // 先断开现有连接
        disconnect()

        // 创建URLSession配置
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true

        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        // 创建WebSocket连接
        webSocketTask = urlSession?.webSocketTask(with: url)
        webSocketTask?.resume()

        // 开始监听消息
        startListening()

        print("WebSocket: 正在连接到: \(url)")
    }
    
    /// 断开WebSocket连接
    func disconnect() {
        stopHeartbeat()
        stopReconnectTimer()
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        
        isConnected = false
        connectionStatus = .disconnected
        reconnectAttempts = 0
        
        print("WebSocket连接已断开")
    }
    
    /// 重新连接
    func reconnect() {
        disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.connect()
        }
    }
    
    /// 发送消息
    func sendMessage(_ message: WebSocketMessage) {
        guard isConnected else {
            print("WebSocket未连接，无法发送消息")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let message = URLSessionWebSocketTask.Message.data(data)
            
            webSocketTask?.send(message) { [weak self] error in
                if let error = error {
                    print("发送WebSocket消息失败: \(error)")
                    Task {
                        await self?.handleConnectionError()
                    }
                }
            }
        } catch {
            print("编码WebSocket消息失败: \(error)")
        }
    }
    
    /// 发送心跳
    func sendHeartbeat() {
        let heartbeat = WebSocketMessage(type: .ping, data: nil)
        sendMessage(heartbeat)
    }
    
    /// 加入对话
    func joinConversation(_ conversationId: String) {
        let data = ["conversationId": conversationId]
        let message = WebSocketMessage(type: .joinConversation, data: data)
        sendMessage(message)
    }
    
    /// 离开对话
    func leaveConversation(_ conversationId: String) {
        let data = ["conversationId": conversationId]
        let message = WebSocketMessage(type: .leaveConversation, data: data)
        sendMessage(message)
    }
    
    /// 发送输入状态
    func sendTypingStatus(conversationId: String, isTyping: Bool) {
        let data: [String: Any] = [
            "conversationId": conversationId,
            "userId": AuthManager.shared.currentUser?.id ?? 0,
            "isTyping": isTyping
        ]
        let message = WebSocketMessage(type: .typing, data: data)
        sendMessage(message)
    }
    
    /// 获取对话中正在输入的用户
    func getTypingUsers(for conversationId: String) -> Set<Int> {
        return typingUsers[conversationId] ?? Set()
    }

    /// 获取连接状态描述
    func getConnectionStatusDescription() -> String {
        return connectionStatus.description
    }

    /// 手动重连
    func manualReconnect() {
        print("WebSocket: 手动重连")
        reconnectAttempts = 0 // 重置重连次数
        disconnect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task {
                await self.connect()
            }
        }
    }

    /// 检查连接健康状态
    func checkConnectionHealth() {
        guard isConnected else {
            print("WebSocket: 连接未建立，尝试重新连接")
            Task {
                await connect()
            }
            return
        }

        // 发送心跳检查连接
        sendHeartbeat()
        print("WebSocket: 发送心跳检查连接健康状态")
    }

    /// 强制重新连接（用于调试）
    func forceReconnect() {
        print("WebSocket: 强制重新连接")
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task {
                await self.connect()
            }
        }
    }

    /// 获取详细的连接状态信息
    func getDetailedConnectionStatus() -> String {
        var status = "WebSocket连接状态:\n"
        status += "- 连接状态: \(isConnected ? "已连接" : "未连接")\n"
        status += "- 连接状态描述: \(connectionStatus.description)\n"
        status += "- 重连次数: \(reconnectAttempts)/\(maxReconnectAttempts)\n"
        status += "- WebSocket任务状态: \(webSocketTask?.state.description ?? "无")\n"
        return status
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.handleNetworkChange(path)
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    @MainActor
    private func handleNetworkChange(_ path: NWPath) {
        print("WebSocket: 网络状态变化 - \(path.status)")

        if path.status == .satisfied && !isConnected {
            // 网络恢复，尝试重连
            print("WebSocket: 网络恢复，尝试重连")
            // 重置重连次数
            reconnectAttempts = 0
            // 延迟2秒后重连，确保网络完全稳定
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                Task {
                    await self.connect()
                }
            }
        } else if path.status != .satisfied && isConnected {
            // 网络断开
            print("WebSocket: 网络连接丢失")
            isConnected = false
            connectionStatus = .failed("网络连接丢失")
            stopHeartbeat()
        }
    }
    
    private func startListening() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                Task {
                    await self?.handleReceivedMessage(message)
                    // 继续监听下一条消息
                    await self?.startListening()
                }
            case .failure(let error):
                print("接收WebSocket消息失败: \(error)")
                Task {
                    await self?.handleConnectionError()
                }
            }
        }
    }
    
    @MainActor
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            handleDataMessage(data)
        case .string(let text):
            if let data = text.data(using: .utf8) {
                handleDataMessage(data)
            }
        @unknown default:
            print("收到未知类型的WebSocket消息")
        }
    }
    
    private func handleDataMessage(_ data: Data) {
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)

            // 更新接收消息列表
            receivedMessages.append(message)

            print("WebSocket收到消息: \(message.type)")
            print("WebSocket消息详情: \(message)")

            // 处理不同类型的消息
            switch message.type {
            case .pong:
                // 心跳响应，不需要特殊处理
                print("WebSocket: 收到心跳响应")
                break

            case .connection:
                // 连接确认消息
                if let connectionData = extractConnectionData(from: message.data) {
                    handleConnectionConfirmation(connectionData)
                } else {
                    print("WebSocket: 无法解析连接确认数据")
                }

            case .newMessage:
                print("WebSocket: 处理新消息")
                if let messageData = extractNewMessageData(from: message.data) {
                    handleNewMessage(messageData)
                } else {
                    print("WebSocket: 无法解析新消息数据")
                }

            case .userStatus:
                if let statusData = extractUserStatusData(from: message.data) {
                    handleUserStatus(statusData)
                } else {
                    print("WebSocket: 无法解析用户状态数据")
                }

            case .typing:
                if let typingData = extractTypingData(from: message.data) {
                    handleTypingStatus(typingData)
                } else {
                    print("WebSocket: 无法解析输入状态数据")
                }

            case .messageUpdated:
                if let updateData = extractMessageUpdateData(from: message.data) {
                    handleMessageUpdate(updateData)
                } else {
                    print("WebSocket: 无法解析消息更新数据")
                }

            case .conversationUpdated:
                if let conversationData = extractConversationUpdateData(from: message.data) {
                    handleConversationUpdate(conversationData)
                } else {
                    print("WebSocket: 无法解析会话更新数据")
                }

            case .readReceipt:
                if let readReceiptData = extractReadReceiptData(from: message.data) {
                    handleReadReceipt(readReceiptData)
                } else {
                    print("WebSocket: 无法解析已读回执数据")
                }

            case .conversationUnreadUpdated:
                if let unreadUpdateData = extractConversationUnreadUpdateData(from: message.data) {
                    handleConversationUnreadUpdate(unreadUpdateData)
                } else {
                    print("WebSocket: 无法解析会话未读数更新数据")
                }

            case .messageRead:
                if let messageReadData = extractMessageReadData(from: message.data) {
                    handleMessageRead(messageReadData)
                } else {
                    print("WebSocket: 无法解析消息已读数据")
                }

            default:
                print("WebSocket: 收到未处理的消息类型: \(message.type)")
                print("WebSocket: 未处理消息的完整内容: \(message)")

                // 注意：不再在这里重复处理新消息，避免重复调用
                // 所有新消息应该通过 case .newMessage 分支处理
            }

        } catch {
            print("WebSocket: 解析消息失败: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("WebSocket: 原始消息内容: \(jsonString)")
            }
        }
    }
    
    // MARK: - 数据提取方法

    private func extractConnectionData(from data: [String: AnyCodable]?) -> ConnectionData? {
        guard let data = data,
              let userId = data["userId"]?.value as? Int,
              let status = data["status"]?.value as? String,
              let timestamp = data["timestamp"]?.value as? String else {
            return nil
        }

        return ConnectionData(userId: userId, status: status, timestamp: timestamp)
    }

    private func extractNewMessageData(from data: [String: AnyCodable]?) -> NewMessageData? {
        guard let data = data else {
            print("WebSocket: 消息数据为空")
            return nil
        }

        // 检查数据结构类型
        if let conversationId = data["conversationId"]?.value as? String,
           let messageData = data["message"]?.value as? [String: Any] {
            // 旧格式：{ "conversationId": "...", "message": { ... } }
            print("WebSocket: 使用旧格式解析新消息")
            return parseMessageFromNestedData(messageData: messageData, conversationId: conversationId)
        } else if let conversationId = data["conversationId"]?.value as? String,
                  let messageId = data["id"]?.value as? String {
            // 新格式：直接包含消息字段
            print("WebSocket: 使用新格式解析新消息")
            return parseMessageFromDirectData(data: data, conversationId: conversationId)
        } else {
            print("WebSocket: 无法识别消息数据格式")
            print("WebSocket: 数据内容: \(data)")
            return nil
        }
    }

    /// 解析嵌套格式的消息数据
    private func parseMessageFromNestedData(messageData: [String: Any], conversationId: String) -> NewMessageData? {
        do {
            // 将消息数据转换为JSON Data
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)

            // 解析为ChatMessage对象
            let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)

            return NewMessageData(message: message, conversationId: conversationId)

        } catch {
            print("WebSocket: 解析嵌套格式消息失败: \(error)")
            return extractNewMessageDataFallback(from: ["conversationId": AnyCodable(conversationId), "message": AnyCodable(messageData)], conversationId: conversationId)
        }
    }

    /// 解析直接格式的消息数据
    private func parseMessageFromDirectData(data: [String: AnyCodable], conversationId: String) -> NewMessageData? {
        // 将 AnyCodable 数据转换为普通字典
        var messageData: [String: Any] = [:]
        for (key, value) in data {
            messageData[key] = value.value
        }

        do {
            // 将消息数据转换为JSON Data
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)

            // 解析为ChatMessage对象
            let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)

            return NewMessageData(message: message, conversationId: conversationId)

        } catch {
            print("WebSocket: 解析直接格式消息失败: \(error)")
            print("WebSocket: 错误详情: \(error)")

            // 如果解析失败，尝试手动构建消息对象
            return extractNewMessageDataFallback(from: data, conversationId: conversationId)
        }
    }

    /// 消息解析失败时的备用方法
    private func extractNewMessageDataFallback(from data: [String: AnyCodable], conversationId: String) -> NewMessageData? {
        // 尝试从嵌套结构解析
        if let messageData = data["message"]?.value as? [String: Any] {
            return parseMessageDataFallback(messageData: messageData, conversationId: conversationId)
        }

        // 尝试从直接结构解析
        var messageData: [String: Any] = [:]
        for (key, value) in data {
            messageData[key] = value.value
        }

        return parseMessageDataFallback(messageData: messageData, conversationId: conversationId)
    }

    /// 解析消息数据的备用方法
    private func parseMessageDataFallback(messageData: [String: Any], conversationId: String) -> NewMessageData? {
        guard let messageId = messageData["id"] as? String,
              let senderId = messageData["senderId"] as? Int,
              let content = messageData["content"] as? String,
              let createdAt = messageData["createdAt"] as? String else {
            print("WebSocket: 备用解析失败 - 缺少必要字段")
            print("WebSocket: 消息数据: \(messageData)")
            return nil
        }

        // 解析消息类型
        let messageType: MessageType
        if let typeString = messageData["type"] as? String {
            messageType = MessageType(rawValue: typeString) ?? .text
        } else {
            messageType = .text
        }

        // 解析消息状态
        let messageStatus: MessageStatus
        if let statusString = messageData["status"] as? String {
            messageStatus = MessageStatus(rawValue: statusString) ?? .delivered
        } else {
            messageStatus = .delivered
        }

        // 解析发送者信息
        let sender: ChatUser
        if let senderData = messageData["sender"] as? [String: Any],
           let senderNickname = senderData["nickname"] as? String {
            // 服务器发送的是用户对象格式
            sender = ChatUser(
                id: senderId,
                nickname: senderNickname,
                avatar: senderData["avatar"] as? String,
                isVerified: senderData["isVerified"] as? Bool ?? false,
                isOnline: senderData["isOnline"] as? Bool ?? false,
                lastSeenAt: senderData["lastSeenAt"] as? String
            )
        } else if let senderNickname = messageData["sender"] as? String {
            // 服务器发送的是用户昵称字符串格式
            sender = ChatUser(
                id: senderId,
                nickname: senderNickname,
                avatar: nil,
                isVerified: false,
                isOnline: false,
                lastSeenAt: nil
            )
            print("WebSocket: 使用服务器提供的昵称: \(senderNickname)")
        } else {
            // 如果没有发送者信息，尝试从当前用户信息获取
            let currentUser = AuthManager.shared.currentUser
            if senderId == currentUser?.id {
                // 如果是当前用户发送的消息，使用当前用户信息
                sender = ChatUser(
                    id: senderId,
                    nickname: currentUser?.nickname ?? "我",
                    avatar: currentUser?.avatar,
                    isVerified: false,
                    isOnline: true,
                    lastSeenAt: nil
                )
            } else {
                // 如果是其他用户，创建一个默认的（这种情况应该很少发生）
                sender = ChatUser(
                    id: senderId,
                    nickname: "用户\(senderId)",
                    avatar: nil,
                    isVerified: false,
                    isOnline: false,
                    lastSeenAt: nil
                )
                print("WebSocket: 警告 - 无法获取用户\(senderId)的昵称信息，使用默认昵称")
            }
        }

        // 解析 replyToMessageId，过滤空字符串
        let replyToMessageId: String?
        if let replyId = messageData["replyToMessageId"] as? String, !replyId.isEmpty {
            replyToMessageId = replyId
        } else {
            replyToMessageId = nil
        }

        let message = ChatMessage(
            id: messageId,
            conversationId: conversationId,
            senderId: senderId,
            content: content,
            type: messageType,
            status: messageStatus,
            isRecalled: messageData["isRecalled"] as? Bool ?? false,
            createdAt: createdAt,
            sender: sender,
            replyToMessageId: replyToMessageId,
            mediaUrl: messageData["mediaUrl"] as? String,
            mediaDuration: messageData["mediaDuration"] as? Int,
            thumbnailUrl: messageData["thumbnailUrl"] as? String
        )

        print("WebSocket: 备用解析成功创建消息: \(messageId)")
        return NewMessageData(message: message, conversationId: conversationId)
    }
    
    private func extractUserStatusData(from data: [String: AnyCodable]?) -> UserStatusData? {
        guard let data = data,
              let userId = data["userId"]?.value as? Int,
              let statusString = data["status"]?.value as? String,
              let status = UserStatus(rawValue: statusString) else {
            return nil
        }
        
        return UserStatusData(userId: userId, status: status)
    }
    
    private func extractTypingData(from data: [String: AnyCodable]?) -> TypingData? {
        guard let data = data,
              let conversationId = data["conversationId"]?.value as? String,
              let userId = data["userId"]?.value as? Int,
              let isTyping = data["isTyping"]?.value as? Bool else {
            return nil
        }
        
        return TypingData(conversationId: conversationId, userId: userId, isTyping: isTyping)
    }
    
    private func extractMessageUpdateData(from data: [String: AnyCodable]?) -> MessageUpdateData? {
        guard let data = data,
              let messageId = data["messageId"]?.value as? String,
              let conversationId = data["conversationId"]?.value as? String,
              let updateType = data["updateType"]?.value as? String else {
            return nil
        }

        let newContent = data["newContent"]?.value as? String
        let newStatus = data["newStatus"]?.value as? String

        return MessageUpdateData(
            messageId: messageId,
            conversationId: conversationId,
            updateType: updateType,
            newContent: newContent,
            newStatus: newStatus
        )
    }
    
    private func extractConversationUpdateData(from data: [String: AnyCodable]?) -> ConversationUpdateData? {
        guard let data = data,
              let conversationId = data["conversationId"]?.value as? String,
              let updateType = data["updateType"]?.value as? String else {
            return nil
        }
        
        var dataDict: [String: String]? = nil
        if let rawData = data["data"]?.value as? [String: Any] {
            dataDict = rawData.compactMapValues { $0 as? String }
        }
        
        return ConversationUpdateData(
            conversationId: conversationId,
            updateType: updateType,
            data: dataDict
        )
    }

    private func extractReadReceiptData(from data: [String: AnyCodable]?) -> ReadReceiptData? {
        guard let data = data,
              let conversationId = data["conversationId"]?.value as? String,
              let messageId = data["messageId"]?.value as? String,
              let userId = data["userId"]?.value as? Int,
              let readAt = data["readAt"]?.value as? String else {
            return nil
        }

        return ReadReceiptData(
            conversationId: conversationId,
            messageId: messageId,
            userId: userId,
            readAt: readAt
        )
    }

    private func extractMessageReadData(from data: [String: AnyCodable]?) -> ReadReceiptData? {
        // message_read 消息的数据结构和 read_receipt 相同
        return extractReadReceiptData(from: data)
    }

    private func extractConversationUnreadUpdateData(from data: [String: AnyCodable]?) -> ConversationUnreadUpdateData? {
        guard let data = data,
              let conversationId = data["conversationId"]?.value as? String,
              let unreadCount = data["unreadCount"]?.value as? Int,
              let lastMessageAt = data["lastMessageAt"]?.value as? String else {
            return nil
        }

        // 解析lastMessage（可选）
        var lastMessage: ChatMessage? = nil
        if let lastMessageData = data["lastMessage"]?.value as? [String: Any] {
            lastMessage = parseLastMessageFromData(lastMessageData)
        }

        return ConversationUnreadUpdateData(
            conversationId: conversationId,
            unreadCount: unreadCount,
            lastMessage: lastMessage,
            lastMessageAt: lastMessageAt
        )
    }



    /// 解析lastMessage数据
    private func parseLastMessageFromData(_ data: [String: Any]) -> ChatMessage? {
        guard let id = data["id"] as? String,
              let senderId = data["senderId"] as? Int,
              let content = data["content"] as? String,
              let createdAt = data["createdAt"] as? String else {
            return nil
        }

        // 解析消息类型
        let messageType: MessageType
        if let typeString = data["type"] as? String {
            messageType = MessageType(rawValue: typeString) ?? .text
        } else {
            messageType = .text
        }

        // 解析消息状态
        let status: MessageStatus
        if let statusString = data["status"] as? String {
            status = MessageStatus(rawValue: statusString) ?? .sent
        } else {
            status = .sent
        }

        // 解析其他可选字段
        let mediaUrl = data["mediaUrl"] as? String
        let mediaDuration = data["mediaDuration"] as? Int
        let isRecalled = data["isRecalled"] as? Bool ?? false

        // 解析 replyToMessageId，过滤空字符串
        let replyToMessageId: String?
        if let replyId = data["replyToMessageId"] as? String, !replyId.isEmpty {
            replyToMessageId = replyId
        } else {
            replyToMessageId = nil
        }

        let thumbnailUrl = data["thumbnailUrl"] as? String

        // 创建一个临时的sender对象
        let currentUser = AuthManager.shared.currentUser
        let tempSender: ChatUser
        if senderId == currentUser?.id {
            // 如果是当前用户，使用当前用户信息
            tempSender = ChatUser(
                id: senderId,
                nickname: currentUser?.nickname ?? "我",
                avatar: currentUser?.avatar,
                isVerified: false,
                isOnline: true,
                lastSeenAt: nil
            )
        } else {
            // 如果是其他用户，使用默认信息
            tempSender = ChatUser(
                id: senderId,
                nickname: "用户\(senderId)",
                avatar: nil,
                isVerified: false,
                isOnline: false,
                lastSeenAt: nil
            )
        }

        return ChatMessage(
            id: id,
            conversationId: "", // 这里会在使用时设置
            senderId: senderId,
            content: content,
            type: messageType,
            status: status,
            isRecalled: isRecalled,
            createdAt: createdAt,
            sender: tempSender,
            replyToMessageId: replyToMessageId,
            mediaUrl: mediaUrl,
            mediaDuration: mediaDuration,
            thumbnailUrl: thumbnailUrl
        )
    }

    private func handleConnectionConfirmation(_ data: ConnectionData) {
        print("WebSocket连接确认: 用户ID \(data.userId), 状态: \(data.status), 时间: \(data.timestamp)")

        // 更新连接状态
        if data.status == "connected" {
            isConnected = true
            connectionStatus = .connected

            // 开始心跳
            startHeartbeat()
        }

        // 通知连接确认
        NotificationCenter.default.post(
            name: .webSocketConnectionConfirmed,
            object: data
        )
    }

    private func handleNewMessage(_ data: NewMessageData) {
        print("WebSocketManager: 处理新消息 - \(data.message.id) 在对话 \(data.conversationId)")

        // 通知相关的ChatDetailViewModel
        NotificationCenter.default.post(
            name: .webSocketNewMessage,
            object: data
        )

        // 如果应用在后台或者不在当前对话中，发送本地推送通知
        Task { @MainActor in
            let currentConversationId = PushNotificationManager.shared.getCurrentConversationId()
            let isInCurrentConversation = currentConversationId == data.conversationId

            // 检查应用状态
            let appState = UIApplication.shared.applicationState
            let shouldShowNotification = appState != .active || !isInCurrentConversation

            if shouldShowNotification {
                // 创建本地推送通知
                let title = data.message.sender.nickname ?? "新消息"
                let body = data.message.content ?? "您收到了一条新消息"

                let userInfo: [String: Any] = [
                    "type": "new_message",
                    "conversationId": data.conversationId,
                    "messageId": data.message.id,
                    "senderId": data.message.senderId
                ]

                PushNotificationManager.shared.scheduleLocalNotification(
                    title: title,
                    body: body,
                    userInfo: userInfo
                )

                print("WebSocketManager: 已发送本地推送通知")
            }
        }

        print("WebSocketManager: 新消息通知已发送")
    }
    
    private func handleUserStatus(_ data: UserStatusData) {
        userStatuses[data.userId] = data.status
        
        // 通知用户状态变化
        NotificationCenter.default.post(
            name: .webSocketUserStatusChanged,
            object: data
        )
    }
    
    private func handleTypingStatus(_ data: TypingData) {
        if data.isTyping {
            typingUsers[data.conversationId, default: Set()].insert(data.userId)
        } else {
            typingUsers[data.conversationId]?.remove(data.userId)
        }
        
        // 通知输入状态变化
        NotificationCenter.default.post(
            name: .webSocketTypingStatusChanged,
            object: data
        )
    }
    
    private func handleMessageUpdate(_ data: MessageUpdateData) {
        // 通知消息更新
        NotificationCenter.default.post(
            name: .webSocketMessageUpdated,
            object: data
        )
    }
    
    private func handleConversationUpdate(_ data: ConversationUpdateData) {
        // 通知对话更新
        NotificationCenter.default.post(
            name: .webSocketConversationUpdated,
            object: data
        )
    }

    private func handleReadReceipt(_ data: ReadReceiptData) {
        // 通知已读回执
        NotificationCenter.default.post(
            name: .webSocketReadReceipt,
            object: data
        )
    }

    private func handleMessageRead(_ data: ReadReceiptData) {
        print("WebSocket: 处理消息已读状态 - 消息ID: \(data.messageId), 用户ID: \(data.userId)")

        // 通知消息已读状态更新
        NotificationCenter.default.post(
            name: .webSocketMessageRead,
            object: data
        )
    }

    private func handleConversationUnreadUpdate(_ data: ConversationUnreadUpdateData) {
        // 通知会话未读数更新
        NotificationCenter.default.post(
            name: .webSocketConversationUnreadUpdated,
            object: data
        )
    }


    
    @MainActor
    private func handleConnectionError() {
        print("WebSocket: 连接错误，当前状态: \(connectionStatus)")
        isConnected = false
        connectionStatus = .failed("连接错误")

        // 停止心跳
        stopHeartbeat()

        // 尝试重连
        attemptReconnect()
    }

    private func attemptReconnect() {
        // 检查是否有有效的认证token
        guard AuthManager.shared.getToken() != nil else {
            print("WebSocket: 无认证token，停止重连")
            connectionStatus = .failed("无认证token")
            return
        }

        guard reconnectAttempts < maxReconnectAttempts else {
            print("WebSocket: 重连次数超过限制(\(maxReconnectAttempts)次)")
            connectionStatus = .failed("重连失败")
            return
        }

        reconnectAttempts += 1
        let delay = min(reconnectInterval * Double(reconnectAttempts), 30.0) // 最大延迟30秒
        print("WebSocket: 重连尝试 \(reconnectAttempts)/\(maxReconnectAttempts)，延迟\(delay)秒")

        connectionStatus = .connecting

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task {
                await self?.connect()
            }
        }
    }
    
    private func startHeartbeat() {
        stopHeartbeat()
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendHeartbeat()
            }
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketManager: URLSessionWebSocketDelegate {
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task {
            await MainActor.run {
                isConnected = true
                connectionStatus = .connected
                reconnectAttempts = 0
                
                // 开始心跳
                startHeartbeat()
                
                print("WebSocket连接成功")
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task {
            await MainActor.run {
                isConnected = false
                connectionStatus = .disconnected
                
                let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "未知原因"
                print("WebSocket连接关闭: \(closeCode), 原因: \(reasonString)")
                
                // 尝试重连（除非是正常关闭）
                if closeCode != .normalClosure {
                    attemptReconnect()
                }
            }
        }
    }
}

// MARK: - 数据模型

/// 连接状态
enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)
    
    var description: String {
        switch self {
        case .disconnected:
            return "已断开"
        case .connecting:
            return "连接中"
        case .connected:
            return "已连接"
        case .failed(let reason):
            return "连接失败: \(reason)"
        }
    }

    /// 从会话成员信息中获取用户信息
    private func getUserInfoFromConversation(userId: Int, conversationId: String) -> ChatUser? {
        // 由于ChatListViewModel没有shared单例，我们暂时返回nil
        // 这个功能可以在后续版本中通过其他方式实现，比如缓存用户信息
        return nil
    }
}

/// 用户状态
enum UserStatus: String, Codable {
    case online = "online"
    case offline = "offline"
    case away = "away"
}

/// WebSocket消息类型
enum WebSocketMessageType: String, Codable {
    case ping = "ping"
    case pong = "pong"
    case connection = "connection"  // 连接确认消息
    case joinConversation = "join_conversation"
    case leaveConversation = "leave_conversation"
    case typing = "typing"
    case newMessage = "newMessage"  // 修改为与服务器一致的格式
    case userStatus = "user_status"
    case messageUpdated = "message_updated"
    case conversationUpdated = "conversation_updated"
    case conversationUnreadUpdated = "conversationUnreadUpdated" // 修改为与服务器一致的格式
    case readReceipt = "read_receipt" // 已读回执
    case messageRead = "message_read" // 消息已读状态
}

/// WebSocket消息
struct WebSocketMessage: Codable {
    let type: WebSocketMessageType
    let data: [String: AnyCodable]?
    
    init(type: WebSocketMessageType, data: [String: Any]? = nil) {
        self.type = type
        self.data = data?.mapValues { AnyCodable($0) }
    }
}

/// 类型擦除的Codable包装器
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        default:
            try container.encode("")
        }
    }
}

/// 连接确认数据
struct ConnectionData: Codable {
    let userId: Int
    let status: String
    let timestamp: String
}

/// 加入对话数据
struct JoinConversationData: Codable {
    let conversationId: String
}

/// 离开对话数据
struct LeaveConversationData: Codable {
    let conversationId: String
}

/// 输入状态数据
struct TypingData: Codable {
    let conversationId: String
    let userId: Int
    let isTyping: Bool
}

/// 新消息数据
struct NewMessageData: Codable {
    let message: ChatMessage
    let conversationId: String
}

/// 用户状态数据
struct UserStatusData: Codable {
    let userId: Int
    let status: UserStatus
}

/// 消息更新数据
struct MessageUpdateData: Codable {
    let messageId: String
    let conversationId: String
    let updateType: String // "recalled", "deleted", "edited", "status_updated"
    let newContent: String?
    let newStatus: String? // 新的消息状态
}

/// 对话更新数据
struct ConversationUpdateData: Codable {
    let conversationId: String
    let updateType: String // "member_added", "member_removed", "info_updated"
    let data: [String: String]?
}

/// 已读回执数据
struct ReadReceiptData: Codable {
    let conversationId: String
    let messageId: String
    let userId: Int
    let readAt: String
}



/// 会话未读数更新数据
struct ConversationUnreadUpdateData: Codable {
    let conversationId: String
    let unreadCount: Int
    let lastMessage: ChatMessage?
    let lastMessageAt: String
}

// MARK: - Notification扩展

extension Notification.Name {
    static let webSocketConnectionConfirmed = Notification.Name("WebSocketConnectionConfirmed")
    static let webSocketNewMessage = Notification.Name("WebSocketNewMessage")
    static let webSocketUserStatusChanged = Notification.Name("WebSocketUserStatusChanged")
    static let webSocketTypingStatusChanged = Notification.Name("WebSocketTypingStatusChanged")
    static let webSocketMessageUpdated = Notification.Name("WebSocketMessageUpdated")
    static let webSocketConversationUpdated = Notification.Name("WebSocketConversationUpdated")
    static let webSocketConversationUnreadUpdated = Notification.Name("WebSocketConversationUnreadUpdated")
    static let webSocketReadReceipt = Notification.Name("WebSocketReadReceipt")
    static let webSocketMessageRead = Notification.Name("WebSocketMessageRead")
}

// MARK: - URLSessionWebSocketTask.State扩展

extension URLSessionWebSocketTask.State {
    var description: String {
        switch self {
        case .running:
            return "运行中"
        case .suspended:
            return "已暂停"
        case .canceling:
            return "取消中"
        case .completed:
            return "已完成"
        @unknown default:
            return "未知状态"
        }
    }
}
