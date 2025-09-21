import Foundation
import SwiftUI
import Combine

/// 聊天详情视图模型
@MainActor
class ChatDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var hasMoreMessages = true
    @Published var currentPage = 1
    @Published var isSendingMessage = false
    @Published var typingUsers: Set<Int> = []
    @Published var onlineUsers: Set<Int> = []
    @Published var isUserTyping = false
    
    // MARK: - Private Properties
    private let conversationId: String
    private let chatService = ChatAPIService.shared
    private let webSocketManager = WebSocketManager.shared
    private var currentLoadTask: Task<Void, Never>?
    private var sendMessageTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var typingTimer: Timer?
    
    // MARK: - 计算属性
    var currentUserId: Int {
        return AuthManager.shared.currentUser?.id ?? 0
    }
    
    // MARK: - 初始化
    init(conversationId: String) {
        self.conversationId = conversationId
        setupRealtimeUpdates()
        setupWebSocketObservers()

        // 设置当前正在查看的对话ID（用于推送通知判断）
        PushNotificationManager.shared.setCurrentConversationId(conversationId)

        // 连接WebSocket并加入对话
        if !webSocketManager.isConnected {
            webSocketManager.connect()
        }
        webSocketManager.joinConversation(conversationId)
    }
    
    deinit {
        // 离开对话
        Task { @MainActor in
            webSocketManager.leaveConversation(conversationId)
            stopTypingTimer()

            // 清除当前正在查看的对话ID
            PushNotificationManager.shared.setCurrentConversationId(nil)
        }
        cancellables.removeAll()
    }
    
    // MARK: - 公共方法
    
    /// 加载消息列表
    func loadMessages(refresh: Bool = false) async {
        // 取消之前的请求
        currentLoadTask?.cancel()
        
        if refresh {
            currentPage = 1
            hasMoreMessages = true
            messages.removeAll()
        }
        
        guard !isLoading && hasMoreMessages else { return }
        
        isLoading = true
        errorMessage = nil
        
        currentLoadTask = Task {
            do {
                let response = try await chatService.getMessages(
                    conversationId: conversationId,
                    page: currentPage,
                    limit: 50,
                    beforeMessageId: refresh ? nil : messages.first?.id
                )
                
                guard !Task.isCancelled else { return }
                
                if refresh {
                    // 按时间排序，最新消息在底部
                    messages = response.messages.sorted { msg1, msg2 in
                        return msg1.createdAt < msg2.createdAt
                    }

                    // 调试：检查加载的消息中是否有回复消息
                    for message in messages {
                        if let replyId = message.replyToMessageId {
                            print("🔄 ChatDetailViewModel: 加载的消息 \(message.id) 有回复ID: \(replyId)")
                        }
                    }
                } else {
                    // 历史消息按时间排序后插入到顶部
                    let sortedHistoryMessages = response.messages.sorted { msg1, msg2 in
                        return msg1.createdAt < msg2.createdAt
                    }
                    messages.insert(contentsOf: sortedHistoryMessages, at: 0)

                    // 调试：检查历史消息中是否有回复消息
                    for message in sortedHistoryMessages {
                        if let replyId = message.replyToMessageId {
                            print("🔄 ChatDetailViewModel: 历史消息 \(message.id) 有回复ID: \(replyId)")
                        }
                    }
                }
                
                hasMoreMessages = response.pagination.hasNextPage
                currentPage += 1
                
            } catch {
                guard !Task.isCancelled else { return }
                
                errorMessage = error.localizedDescription
                showError = true
                
                // 如果是首次加载失败，保持空状态
                // messages 保持为空数组
            }
            
            isLoading = false
        }
    }
    
    /// 刷新消息列表
    func refreshMessages() async {
        await loadMessages(refresh: true)
    }
    
    /// 加载更多历史消息
    func loadMoreMessages() async {
        await loadMessages(refresh: false)
    }
    
    /// 发送消息
    func sendMessage(
        content: String,
        type: MessageType = .text,
        replyToMessageId: String? = nil,
        attachments: [String]? = nil,
        mediaUrl: String? = nil,
        thumbnailUrl: String? = nil,
        mediaDuration: Int? = nil
    ) async {
        // 取消之前的发送任务
        sendMessageTask?.cancel()
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSendingMessage = true
        
        // 创建临时消息显示发送状态
        let tempMessage = createTempMessage(
            content: content,
            type: type,
            replyToMessageId: replyToMessageId,
            mediaUrl: mediaUrl,
            mediaDuration: mediaDuration
        )
        messages.append(tempMessage)
        
        sendMessageTask = Task {
            do {
                let sentMessage = try await chatService.sendMessage(
                    conversationId: conversationId,
                    content: content,
                    type: type,
                    mediaUrl: mediaUrl,
                    mediaDuration: mediaDuration,
                    thumbnailUrl: thumbnailUrl,
                    replyToMessageId: replyToMessageId
                )
                
                guard !Task.isCancelled else { return }
                
                // 替换临时消息为真实消息
                if let index = messages.firstIndex(where: { $0.id == tempMessage.id }) {
                    let oldMessageId = tempMessage.id
                    let newMessageId = sentMessage.id

                    // 替换消息
                    messages[index] = sentMessage

                    // 更新所有引用了旧消息ID的回复消息
                    updateReplyReferences(from: oldMessageId, to: newMessageId)

                    print("🔄 ChatDetailViewModel: 消息ID更新 \(oldMessageId) -> \(newMessageId)")
                }
                
            } catch {
                guard !Task.isCancelled else { return }
                
                // 标记消息发送失败
                if let index = messages.firstIndex(where: { $0.id == tempMessage.id }) {
                    var failedMessage = messages[index]
                    failedMessage = ChatMessage(
                        id: failedMessage.id,
                        conversationId: failedMessage.conversationId,
                        senderId: failedMessage.senderId,
                        content: failedMessage.content,
                        type: failedMessage.type,
                        status: .failed,
                        isRecalled: false,
                        createdAt: failedMessage.createdAt,
                        sender: failedMessage.sender,
                        replyToMessageId: failedMessage.replyToMessageId,
                        mediaUrl: nil,
                        mediaDuration: nil,
                        thumbnailUrl: nil
                    )
                    messages[index] = failedMessage
                }
                
                errorMessage = "发送失败: \(error.localizedDescription)"
                showError = true
            }
            
            isSendingMessage = false
        }
    }
    
    /// 重新发送失败的消息
    func resendMessage(_ message: ChatMessage) async {
        guard message.status == .failed else { return }
        
        // 更新消息状态为发送中
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            var updatedMessage = message
            updatedMessage = ChatMessage(
                id: updatedMessage.id,
                conversationId: updatedMessage.conversationId,
                senderId: updatedMessage.senderId,
                content: updatedMessage.content,
                type: updatedMessage.type,
                status: .sending,
                isRecalled: false,
                createdAt: updatedMessage.createdAt,
                sender: updatedMessage.sender,
                replyToMessageId: updatedMessage.replyToMessageId,
                mediaUrl: nil,
                mediaDuration: nil,
                thumbnailUrl: nil
            )
            messages[index] = updatedMessage
        }
        
        // 重新发送
        await sendMessage(
            content: message.content,
            type: message.type,
            replyToMessageId: message.replyToMessageId,
            attachments: message.attachments?.map { $0.url }
        )
    }
    


    /// 转发消息
    func forwardMessage(_ message: ChatMessage, to conversationId: String) async {
        do {
            try await chatService.forwardMessage(
                messageId: message.id,
                toConversationId: conversationId
            )

        } catch {
            errorMessage = "转发失败: \(error.localizedDescription)"
            showError = true
        }
    }


    
    // MARK: - 私有方法
    
    /// 创建临时消息
    private func createTempMessage(
        content: String,
        type: MessageType,
        replyToMessageId: String? = nil,
        mediaUrl: String? = nil,
        mediaDuration: Int? = nil
    ) -> ChatMessage {
        let currentUser = AuthManager.shared.currentUser
        let tempId = UUID().uuidString
        
        let senderInfo = ChatUser(
            id: currentUser?.id ?? 0,
            nickname: currentUser?.nickname ?? "我",
            avatar: currentUser?.avatar,
            isVerified: false,
            isOnline: true,
            lastSeenAt: nil
        )

        return ChatMessage(
            id: tempId,
            conversationId: conversationId,
            senderId: currentUser?.id ?? 0,
            content: content,
            type: type,
            status: .sending,
            isRecalled: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            sender: senderInfo,
            replyToMessageId: replyToMessageId,
            mediaUrl: mediaUrl,
            mediaDuration: mediaDuration,
            thumbnailUrl: nil
        )
    }
    
    /// 设置实时更新
    private func setupRealtimeUpdates() {
        // WebSocket实时更新在setupWebSocketObservers中实现
    }
    
    /// 设置WebSocket观察者
    private func setupWebSocketObservers() {
        print("ChatDetailViewModel: 设置WebSocket观察者 for conversation: \(conversationId)")

        // 监听新消息
        NotificationCenter.default
            .publisher(for: .webSocketNewMessage)
            .compactMap { $0.object as? NewMessageData }
            .filter { data in
                let isMatch = data.conversationId == self.conversationId
                print("ChatDetailViewModel: 收到WebSocket新消息通知 - conversationId: \(data.conversationId), 匹配当前对话: \(isMatch)")
                return isMatch
            }
            .sink { [weak self] data in
                print("ChatDetailViewModel: 处理匹配的新消息")
                self?.handleNewMessage(data.message)
            }
            .store(in: &cancellables)
        
        // 监听用户状态变化
        NotificationCenter.default
            .publisher(for: .webSocketUserStatusChanged)
            .compactMap { $0.object as? UserStatusData }
            .sink { [weak self] data in
                self?.handleUserStatusChange(userId: data.userId, status: data.status)
            }
            .store(in: &cancellables)
        
        // 监听输入状态变化
        NotificationCenter.default
            .publisher(for: .webSocketTypingStatusChanged)
            .compactMap { $0.object as? TypingData }
            .filter { $0.conversationId == self.conversationId }
            .sink { [weak self] data in
                self?.handleTypingStatusChange(userId: data.userId, isTyping: data.isTyping)
            }
            .store(in: &cancellables)
        
        // 监听消息更新
        NotificationCenter.default
            .publisher(for: .webSocketMessageUpdated)
            .compactMap { $0.object as? MessageUpdateData }
            .filter { $0.conversationId == self.conversationId }
            .sink { [weak self] data in
                self?.handleMessageUpdate(data)
            }
            .store(in: &cancellables)

        // 监听已读回执
        NotificationCenter.default
            .publisher(for: .webSocketReadReceipt)
            .compactMap { $0.object as? ReadReceiptData }
            .filter { $0.conversationId == self.conversationId }
            .sink { [weak self] data in
                self?.handleReadReceipt(data)
            }
            .store(in: &cancellables)

        // 监听消息已读状态
        NotificationCenter.default
            .publisher(for: .webSocketMessageRead)
            .compactMap { $0.object as? ReadReceiptData }
            .filter { $0.conversationId == self.conversationId }
            .sink { [weak self] data in
                self?.handleMessageRead(data)
            }
            .store(in: &cancellables)

        // 监听WebSocket连接状态
        webSocketManager.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    // 重新加入对话
                    self?.webSocketManager.joinConversation(self?.conversationId ?? "")
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - WebSocket事件处理
    
    /// 处理新消息
    private func handleNewMessage(_ message: ChatMessage) {
        print("ChatDetailViewModel: 收到新消息 - \(message.id) from \(message.senderId)")

        // 避免重复添加消息
        guard !messages.contains(where: { $0.id == message.id }) else {
            print("ChatDetailViewModel: 消息已存在，跳过添加和标记已读")
            return
        }

        // 找到正确的插入位置，保持时间顺序
        let insertIndex = messages.firstIndex { existingMessage in
            return existingMessage.createdAt > message.createdAt
        } ?? messages.count

        // 将新消息插入到正确位置
        messages.insert(message, at: insertIndex)
        print("ChatDetailViewModel: 新消息已添加到位置 \(insertIndex)，当前消息总数: \(messages.count)")

        // 如果不是自己发送的消息，且应用在前台且用户正在查看当前对话，则标记为已读
        if message.senderId != currentUserId {
            Task { @MainActor in
                let appState = UIApplication.shared.applicationState
                let currentConversationId = PushNotificationManager.shared.getCurrentConversationId()
                let isViewingCurrentConversation = currentConversationId == conversationId

                // 只有当应用在前台且用户正在查看当前对话时才自动标记为已读
                if appState == .active && isViewingCurrentConversation {
                    print("ChatDetailViewModel: 用户正在查看对话，标记消息为已读")
                    try? await chatService.markAsRead(
                        conversationId: conversationId,
                        lastReadMessageId: message.id
                    )

                    // 更新应用角标
                    await PushNotificationManager.shared.updateBadgeCount()
                } else {
                    print("ChatDetailViewModel: 用户未在查看对话或应用在后台，不自动标记已读")
                    print("ChatDetailViewModel: 应用状态: \(appState), 当前对话ID: \(currentConversationId ?? "nil"), 目标对话ID: \(conversationId)")
                }
            }
        }
    }
    
    /// 处理用户状态变化
    private func handleUserStatusChange(userId: Int, status: UserStatus) {
        switch status {
        case .online:
            onlineUsers.insert(userId)
        case .offline, .away:
            onlineUsers.remove(userId)
        }
    }
    
    /// 处理输入状态变化
    private func handleTypingStatusChange(userId: Int, isTyping: Bool) {
        // 不显示自己的输入状态
        guard userId != currentUserId else { return }
        
        if isTyping {
            typingUsers.insert(userId)
        } else {
            typingUsers.remove(userId)
        }
    }
    
    /// 处理消息更新
    private func handleMessageUpdate(_ data: MessageUpdateData) {
        guard let index = messages.firstIndex(where: { $0.id == data.messageId }) else { return }
        
        var updatedMessage = messages[index]
        
        switch data.updateType {
        case "edited":
            if let newContent = data.newContent {
                updatedMessage = ChatMessage(
                    id: updatedMessage.id,
                    conversationId: updatedMessage.conversationId,
                    senderId: updatedMessage.senderId,
                    content: newContent,
                    type: updatedMessage.type,
                    status: updatedMessage.status,
                    isRecalled: updatedMessage.isRecalled,
                    createdAt: updatedMessage.createdAt,
                    sender: updatedMessage.sender,
                    replyToMessageId: updatedMessage.replyToMessageId,
                    mediaUrl: updatedMessage.mediaUrl,
                    mediaDuration: updatedMessage.mediaDuration,
                    thumbnailUrl: updatedMessage.thumbnailUrl
                )
                messages[index] = updatedMessage
            }

        case "status_updated":
            if let newStatusString = data.newStatus,
               let newStatus = MessageStatus(rawValue: newStatusString) {
                updatedMessage = ChatMessage(
                    id: updatedMessage.id,
                    conversationId: updatedMessage.conversationId,
                    senderId: updatedMessage.senderId,
                    content: updatedMessage.content,
                    type: updatedMessage.type,
                    status: newStatus,
                    isRecalled: updatedMessage.isRecalled,
                    createdAt: updatedMessage.createdAt,
                    sender: updatedMessage.sender,
                    replyToMessageId: updatedMessage.replyToMessageId,
                    mediaUrl: updatedMessage.mediaUrl,
                    mediaDuration: updatedMessage.mediaDuration,
                    thumbnailUrl: updatedMessage.thumbnailUrl
                )
                messages[index] = updatedMessage
            }

        default:
            break
        }
    }

    /// 处理已读回执
    private func handleReadReceipt(_ data: ReadReceiptData) {
        // 更新该用户发送的所有消息状态为已读
        for (index, message) in messages.enumerated() {
            // 只更新当前用户发送的消息，且消息时间早于或等于已读消息的时间
            if message.senderId == currentUserId && message.createdAt <= data.readAt {
                let updatedMessage = ChatMessage(
                    id: message.id,
                    conversationId: message.conversationId,
                    senderId: message.senderId,
                    content: message.content,
                    type: message.type,
                    status: .read, // 更新为已读状态
                    isRecalled: message.isRecalled,
                    createdAt: message.createdAt,
                    sender: message.sender,
                    replyToMessageId: message.replyToMessageId,
                    mediaUrl: message.mediaUrl,
                    mediaDuration: message.mediaDuration,
                    thumbnailUrl: message.thumbnailUrl
                )
                messages[index] = updatedMessage
            }
        }
    }

    /// 处理消息已读状态
    private func handleMessageRead(_ data: ReadReceiptData) {
        print("ChatDetailViewModel: 处理消息已读状态 - 消息ID: \(data.messageId), 用户ID: \(data.userId), 当前用户ID: \(currentUserId)")

        // 检查是否是其他用户读取了当前用户发送的消息
        if data.userId != currentUserId {
            // 更新该用户发送的所有消息状态为已读
            for (index, message) in messages.enumerated() {
                // 只更新当前用户发送的消息，且消息时间早于或等于已读消息的时间
                if message.senderId == currentUserId && message.createdAt <= data.readAt {
                    let updatedMessage = ChatMessage(
                        id: message.id,
                        conversationId: message.conversationId,
                        senderId: message.senderId,
                        content: message.content,
                        type: message.type,
                        status: .read, // 更新为已读状态
                        isRecalled: message.isRecalled,
                        createdAt: message.createdAt,
                        sender: message.sender,
                        replyToMessageId: message.replyToMessageId,
                        mediaUrl: message.mediaUrl,
                        mediaDuration: message.mediaDuration,
                        thumbnailUrl: message.thumbnailUrl
                    )
                    messages[index] = updatedMessage
                    print("ChatDetailViewModel: 消息 \(message.id) 状态更新为已读")
                }
            }
        } else {
            print("ChatDetailViewModel: 忽略自己的已读状态更新")
        }
    }



    /// 根据消息ID查找消息
    func findMessage(by messageId: String) -> ChatMessage? {
        let foundMessage = messages.first { $0.id == messageId }
        print("🔍 findMessage: 查找消息ID: \(messageId)")
        print("🔍 findMessage: 当前消息总数: \(messages.count)")
        print("🔍 findMessage: 找到消息: \(foundMessage?.content ?? "未找到")")

        // 如果没找到，打印所有消息ID用于调试
        if foundMessage == nil {
            print("🔍 findMessage: 所有消息ID列表:")
            for (index, msg) in messages.enumerated() {
                print("  [\(index)] \(msg.id) - \(msg.content.prefix(20))")
            }
        }

        return foundMessage
    }

    /// 更新回复消息的引用关系
    private func updateReplyReferences(from oldMessageId: String, to newMessageId: String) {
        for i in 0..<messages.count {
            if messages[i].replyToMessageId == oldMessageId {
                // 创建新的消息对象，更新回复引用
                let oldMessage = messages[i]
                let updatedMessage = ChatMessage(
                    id: oldMessage.id,
                    conversationId: oldMessage.conversationId,
                    senderId: oldMessage.senderId,
                    content: oldMessage.content,
                    type: oldMessage.type,
                    status: oldMessage.status,
                    isRecalled: oldMessage.isRecalled,
                    createdAt: oldMessage.createdAt,
                    sender: oldMessage.sender,
                    replyToMessageId: newMessageId, // 更新为新的消息ID
                    mediaUrl: oldMessage.mediaUrl,
                    mediaDuration: oldMessage.mediaDuration,
                    thumbnailUrl: oldMessage.thumbnailUrl
                )
                messages[i] = updatedMessage
                print("🔄 updateReplyReferences: 更新消息 \(oldMessage.id) 的回复引用 \(oldMessageId) -> \(newMessageId)")
            }
        }
    }

    // MARK: - 输入状态管理
    
    /// 开始输入
    func startTyping() {
        guard !isUserTyping else { return }
        
        isUserTyping = true
        webSocketManager.sendTypingStatus(conversationId: conversationId, isTyping: true)
        
        // 设置输入超时
        startTypingTimer()
    }
    
    /// 停止输入
    func stopTyping() {
        guard isUserTyping else { return }
        
        isUserTyping = false
        webSocketManager.sendTypingStatus(conversationId: conversationId, isTyping: false)
        
        stopTypingTimer()
    }
    
    /// 开始输入计时器
    private func startTypingTimer() {
        stopTypingTimer()
        
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopTyping()
            }
        }
    }
    
    /// 停止输入计时器
    private func stopTypingTimer() {
        typingTimer?.invalidate()
        typingTimer = nil
    }
    

}
