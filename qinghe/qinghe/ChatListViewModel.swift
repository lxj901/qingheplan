import Foundation
import SwiftUI
import Combine

/// 聊天列表视图模型
@MainActor
class ChatListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var conversations: [ChatConversation] = []
    @Published var filteredConversations: [ChatConversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var hasMoreConversations = true
    @Published var currentPage = 1
    @Published var searchKeyword = ""
    @Published var selectedCategory: ChatCategory = .all

    // MARK: - Computed Properties

    /// 总未读消息数量
    var totalUnreadCount: Int {
        return conversations.reduce(0) { total, conversation in
            total + (conversation.unreadCount ?? 0)
        }
    }

    // MARK: - Private Properties
    private let chatService = ChatAPIService.shared
    private let webSocketManager = WebSocketManager.shared
    private var currentLoadTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 初始化
    init() {
        // 监听实时消息更新
        setupRealtimeUpdates()
    }
    
    // MARK: - 公共方法
    
    /// 加载会话列表
    func loadConversations(refresh: Bool = false) async {
        // 取消之前的请求
        currentLoadTask?.cancel()
        
        if refresh {
            currentPage = 1
            hasMoreConversations = true
            conversations.removeAll()
        }
        
        guard !isLoading && hasMoreConversations else { return }
        
        isLoading = true
        errorMessage = nil
        
        currentLoadTask = Task {
            do {
                let tab = selectedCategory == .all ? "all" :
                         selectedCategory == .unread ? "unread" : "all"

                let response = try await chatService.getChatList(
                    tab: tab,
                    page: currentPage,
                    limit: 20
                )

                guard !Task.isCancelled else { return }

                if refresh {
                    // 刷新时保留已有的 lastMessage 信息，避免被后端的 null 值覆盖
                    conversations = mergeConversationsWithExistingData(newConversations: response.items)
                } else {
                    conversations.append(contentsOf: response.items)
                }

                hasMoreConversations = response.pagination.hasNextPage
                currentPage += 1

                // 应用筛选
                applyFilters()

            } catch {
                guard !Task.isCancelled else { return }

                errorMessage = error.localizedDescription
                showError = true

                // 如果是首次加载失败，保持空状态
                // conversations 保持为空数组
            }

            isLoading = false
        }
    }
    
    /// 刷新会话列表
    func refreshConversations() async {
        await loadConversations(refresh: true)
    }
    
    /// 加载更多会话
    func loadMoreConversations() async {
        await loadConversations(refresh: false)
    }
    
    /// 搜索会话
    func searchConversations(keyword: String) {
        searchKeyword = keyword
        Task {
            await loadConversations(refresh: true)
        }
    }
    
    /// 清除搜索
    func clearSearch() {
        searchKeyword = ""
        Task {
            await loadConversations(refresh: true)
        }
    }
    
    /// 按分类筛选会话
    func filterConversations(by category: ChatCategory) {
        selectedCategory = category
        Task {
            await loadConversations(refresh: true)
        }
    }
    
    /// 置顶/取消置顶会话
    func togglePin(conversationId: String) async {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }

        let conversation = conversations[index]
        let newPinStatus = !conversation.isPinned

        do {
            try await chatService.pinConversation(conversationId: conversationId, isPinned: newPinStatus)

            // 重新加载数据以获取最新状态
            await refreshConversations()

        } catch {
            errorMessage = "操作失败: \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// 静音/取消静音会话
    func toggleMute(conversationId: String) async {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }

        let conversation = conversations[index]
        let newMuteStatus = !(conversation.isMuted ?? false)

        do {
            try await chatService.muteConversation(conversationId: conversationId, isMuted: newMuteStatus)

            // 重新加载数据以获取最新状态
            await refreshConversations()

        } catch {
            errorMessage = "操作失败: \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// 标记会话为已读
    func markAsRead(conversationId: String, lastMessageId: String? = nil) async {
        do {
            if let lastMessageId = lastMessageId {
                try await chatService.markAsRead(conversationId: conversationId, lastReadMessageId: lastMessageId)
            }

            // 重新加载数据以获取最新状态
            await refreshConversations()

        } catch {
            errorMessage = "标记已读失败: \(error.localizedDescription)"
            showError = true
        }
    }

    /// 标记会话为未读
    func markAsUnread(conversationId: String) async {
        do {
            try await chatService.markAsUnread(conversationId: conversationId)

            // 重新加载数据以获取最新状态
            await refreshConversations()

        } catch {
            errorMessage = "标记未读失败: \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// 删除会话
    func deleteConversation(conversationId: String) async {
        do {
            try await chatService.deleteConversation(conversationId: conversationId)
            
            // 从本地数据中移除
            conversations.removeAll { $0.id == conversationId }
            applyFilters()
            
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - 私有方法
    
    /// 应用筛选条件
    private func applyFilters() {
        var filtered = conversations

        // 按分类筛选
        switch selectedCategory {
        case .all:
            break
        case .privateChat:
            filtered = filtered.filter { $0.type == .privateChat }
        case .group:
            filtered = filtered.filter { $0.type == .group }
        case .unread:
            filtered = filtered.filter { ($0.unreadCount ?? 0) > 0 }
        case .notification:
            // 筛选通知类型的会话（系统通知、官方公告等）
            filtered = filtered.filter { conversation in
                // 判断是否为通知类型的会话
                return isNotificationConversation(conversation)
            }
        }

        // 排序：置顶的在前，然后按最后活跃时间排序
        filtered.sort { conversation1, conversation2 in
            if conversation1.isPinned != conversation2.isPinned {
                return conversation1.isPinned
            }
            let time1 = conversation1.lastMessageAt ?? conversation1.lastActiveAt
            let time2 = conversation2.lastMessageAt ?? conversation2.lastActiveAt
            return time1 > time2
        }

        filteredConversations = filtered
    }

    /// 判断是否为通知类型的会话
    private func isNotificationConversation(_ conversation: ChatConversation) -> Bool {
        // 通知类型的会话判断逻辑：
        // 1. 系统官方账号的会话（可以通过特定的用户ID或标识判断）
        // 2. 群聊中包含"通知"、"公告"等关键词的
        // 3. 特殊标记的通知会话

        // 检查是否为系统通知账号
        if let creator = conversation.creator {
            // 假设系统通知账号的ID为特定值，或者有特殊标识
            if creator.id == 0 || creator.nickname.contains("系统") || creator.nickname.contains("官方") {
                return true
            }
        }

        // 检查会话标题是否包含通知相关关键词
        if let title = conversation.title {
            let notificationKeywords = ["通知", "公告", "系统消息", "官方", "提醒"]
            for keyword in notificationKeywords {
                if title.contains(keyword) {
                    return true
                }
            }
        }

        // 检查最后一条消息是否为系统消息类型
        if let lastMessage = conversation.lastMessage {
            // 如果消息类型为系统消息，则认为是通知
            if lastMessage.type == .system {
                return true
            }

            // 检查消息内容是否包含通知相关内容
            let content = lastMessage.content
            if content.contains("点赞了你的") || content.contains("评论了你的") || content.contains("关注了你") {
                return true
            }
        }

        return false
    }
    
    /// 设置实时更新
    private func setupRealtimeUpdates() {
        // 监听新消息
        NotificationCenter.default
            .publisher(for: .webSocketNewMessage)
            .compactMap { $0.object as? NewMessageData }
            .sink { [weak self] data in
                self?.handleNewMessage(data)
            }
            .store(in: &cancellables)

        // 监听会话更新
        NotificationCenter.default
            .publisher(for: .webSocketConversationUpdated)
            .compactMap { $0.object as? ConversationUpdateData }
            .sink { [weak self] data in
                self?.handleConversationUpdate(data)
            }
            .store(in: &cancellables)

        // 监听用户状态变化
        NotificationCenter.default
            .publisher(for: .webSocketUserStatusChanged)
            .compactMap { $0.object as? UserStatusData }
            .sink { [weak self] data in
                self?.handleUserStatusChange(data)
            }
            .store(in: &cancellables)

        // 监听已读回执
        NotificationCenter.default
            .publisher(for: .webSocketReadReceipt)
            .compactMap { $0.object as? ReadReceiptData }
            .sink { [weak self] data in
                self?.handleReadReceipt(data)
            }
            .store(in: &cancellables)

        // 监听会话未读数更新
        NotificationCenter.default
            .publisher(for: .webSocketConversationUnreadUpdated)
            .compactMap { $0.object as? ConversationUnreadUpdateData }
            .sink { [weak self] data in
                self?.handleConversationUnreadUpdate(data)
            }
            .store(in: &cancellables)
    }

    // MARK: - WebSocket事件处理

    /// 处理新消息
    private func handleNewMessage(_ data: NewMessageData) {
        // 查找对应的会话
        if let index = conversations.firstIndex(where: { $0.id == data.conversationId }) {
            let conversation = conversations[index]

            // 创建新的LastMessage对象
            let newLastMessage = LastMessage(
                id: data.message.id,
                content: data.message.content,
                type: data.message.type,
                createdAt: data.message.createdAt,
                sender: data.message.sender
            )

            // 计算新的未读数
            let newUnreadCount: Int
            if data.message.senderId != AuthManager.shared.currentUser?.id {
                newUnreadCount = (conversation.unreadCount ?? 0) + 1
            } else {
                newUnreadCount = conversation.unreadCount ?? 0
            }

            // 创建更新后的会话对象
            let updatedConversation = ChatConversation(
                id: conversation.id,
                title: conversation.title,
                type: conversation.type,
                avatar: conversation.avatar,
                lastMessage: newLastMessage,
                lastMessageAt: data.message.createdAt,
                unreadCount: newUnreadCount,
                isTop: conversation.isTop,
                isMuted: conversation.isMuted,
                membersCount: conversation.membersCount,
                creatorId: conversation.creatorId,
                creator: conversation.creator,
                memberRecords: conversation.memberRecords,
                description: conversation.description,
                maxMembers: conversation.maxMembers,
                createdAt: conversation.createdAt
            )

            // 更新会话
            conversations[index] = updatedConversation

            // 将会话移到顶部
            conversations.move(fromOffsets: IndexSet(integer: index), toOffset: 0)

            // 更新过滤后的会话列表
            applyFilters()

            // 更新应用角标
            Task {
                await PushNotificationManager.shared.updateBadgeCount()
            }

        } else {
            // 如果会话不存在，重新加载会话列表
            Task {
                await refreshConversations()
            }
        }
    }

    /// 处理会话更新
    private func handleConversationUpdate(_ data: ConversationUpdateData) {
        if let index = conversations.firstIndex(where: { $0.id == data.conversationId }) {
            // 重新加载该会话的详细信息
            Task {
                await loadConversationDetails(conversationId: data.conversationId, index: index)
            }
        }
    }

    /// 处理用户状态变化
    private func handleUserStatusChange(_ data: UserStatusData) {
        // 更新相关会话中用户的在线状态
        for conversation in conversations {
            if conversation.type == .privateChat {
                // 对于私聊，更新对方用户的在线状态
                if let otherUserId = conversation.participants.first(where: { $0.id != AuthManager.shared.currentUser?.id })?.id,
                   otherUserId == data.userId {
                    // 这里可以更新用户的在线状态显示
                    // 由于ChatConversation是不可变的，我们暂时不做修改
                    // 在实际应用中，可能需要重新构建会话对象
                }
            }
        }
        applyFilters()
    }

    /// 处理已读回执
    private func handleReadReceipt(_ data: ReadReceiptData) {
        if conversations.firstIndex(where: { $0.id == data.conversationId }) != nil {
            // 如果是当前用户发送的消息被读取，可以更新显示状态
            if data.userId != AuthManager.shared.currentUser?.id {
                // 对方已读，可以在这里更新UI显示
                // 由于ChatConversation是不可变的，我们暂时不做修改
                applyFilters()
            }
        }
    }

    /// 处理会话未读数更新
    private func handleConversationUnreadUpdate(_ data: ConversationUnreadUpdateData) {
        // 查找对应的会话
        if let index = conversations.firstIndex(where: { $0.id == data.conversationId }) {
            let conversation = conversations[index]

            // 创建新的LastMessage对象（如果有）
            var newLastMessage: LastMessage? = nil
            if let lastMessage = data.lastMessage {
                newLastMessage = LastMessage(
                    id: lastMessage.id,
                    content: lastMessage.content,
                    type: lastMessage.type,
                    createdAt: lastMessage.createdAt,
                    sender: lastMessage.sender
                )
            }

            // 创建更新后的会话对象
            let updatedConversation = ChatConversation(
                id: conversation.id,
                title: conversation.title,
                type: conversation.type,
                avatar: conversation.avatar,
                lastMessage: newLastMessage ?? conversation.lastMessage,
                lastMessageAt: data.lastMessageAt,
                unreadCount: data.unreadCount,
                isTop: conversation.isTop,
                isMuted: conversation.isMuted,
                membersCount: conversation.membersCount,
                creatorId: conversation.creatorId,
                creator: conversation.creator,
                memberRecords: conversation.memberRecords,
                description: conversation.description,
                maxMembers: conversation.maxMembers,
                createdAt: conversation.createdAt
            )

            // 更新会话
            conversations[index] = updatedConversation

            // 如果有新消息，将会话移到顶部
            if newLastMessage != nil && index > 0 {
                conversations.move(fromOffsets: IndexSet(integer: index), toOffset: 0)
            }

            // 更新过滤后的会话列表
            applyFilters()

            // 更新应用角标
            Task {
                await PushNotificationManager.shared.updateBadgeCount()
            }

        } else {
            // 如果会话不存在，重新加载会话列表
            Task {
                await refreshConversations()
            }
        }
    }

    /// 加载会话详细信息
    private func loadConversationDetails(conversationId: String, index: Int) async {
        // 这里可以调用API获取会话的最新信息
        // 暂时保持现有逻辑
    }

    /// 合并新的对话数据与已有数据，保留重要的本地状态
    private func mergeConversationsWithExistingData(newConversations: [ChatConversation]) -> [ChatConversation] {
        var mergedConversations: [ChatConversation] = []

        for newConversation in newConversations {
            // 查找是否已存在相同的对话
            if let existingConversation = conversations.first(where: { $0.id == newConversation.id }) {
                // 如果新数据的 lastMessage 为空，但已有数据有 lastMessage，则保留已有的
                let finalLastMessage: LastMessage?
                if newConversation.lastMessage == nil && existingConversation.lastMessage != nil {
                    finalLastMessage = existingConversation.lastMessage
                    print("ChatListViewModel: 保留对话 \(newConversation.id) 的已有 lastMessage")
                } else {
                    finalLastMessage = newConversation.lastMessage
                }

                // 创建合并后的对话对象
                let mergedConversation = ChatConversation(
                    id: newConversation.id,
                    title: newConversation.title,
                    type: newConversation.type,
                    avatar: newConversation.avatar,
                    lastMessage: finalLastMessage,
                    lastMessageAt: newConversation.lastMessageAt,
                    unreadCount: newConversation.unreadCount,
                    isTop: newConversation.isTop,
                    isMuted: newConversation.isMuted,
                    membersCount: newConversation.membersCount,
                    creatorId: newConversation.creatorId,
                    creator: newConversation.creator,
                    memberRecords: newConversation.memberRecords,
                    description: newConversation.description,
                    maxMembers: newConversation.maxMembers,
                    createdAt: newConversation.createdAt
                )

                mergedConversations.append(mergedConversation)
            } else {
                // 新对话，直接添加
                mergedConversations.append(newConversation)
            }
        }

        return mergedConversations
    }

}
