import SwiftUI
import UniformTypeIdentifiers
import AVFoundation





/// 聊天详情页面
struct ChatDetailView: View {
    @State private var conversation: ChatConversation
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChatDetailViewModel
    @State private var messageText = ""

    @State private var selectedMessage: ChatMessage?
    @State private var replyToMessage: ChatMessage?
    @State private var highlightedMessageId: String?

    @State private var messageToForward: ChatMessage?

    // 高级功能状态
    @State private var isConversationDetailLoaded = false

    @State private var submitLabel: SubmitLabel = .return
    @State private var keyboardUpdateTask: Task<Void, Never>?
    // 统一的 Sheet 管理
    @State private var activeSheet: ActiveSheet?

    enum ActiveSheet: Identifiable {
        case groupAction
        case editGroup
        case memberList
        case addMember
        case forward(ChatMessage)
        case chatExport
        case messageAction(ChatMessage)
        case userProfile(String) // 用户个人中心

        var id: String {
            switch self {
            case .groupAction: return "groupAction"
            case .editGroup: return "editGroup"
            case .memberList: return "memberList"
            case .addMember: return "addMember"
            case .forward: return "forward"
            case .chatExport: return "chatExport"
            case .messageAction: return "messageAction"
            case .userProfile(let userId): return "userProfile_\(userId)"
            }
        }
    }



    @FocusState private var isInputFocused: Bool
    
    init(conversation: ChatConversation) {
        self._conversation = State(initialValue: conversation)
        self._viewModel = StateObject(wrappedValue: ChatDetailViewModel(conversationId: conversation.id))
    }

    // MARK: - 生命周期方法
    private func loadConversationDetail() {
        Task {
            do {
                let detailedConversation = try await ChatAPIService.shared.getConversationDetail(conversationId: conversation.id)
                await MainActor.run {
                    self.conversation = detailedConversation
                    self.isConversationDetailLoaded = true
                    print("🔍 ChatDetailView: 已更新会话详情")
                    print("🔍 ChatDetailView: 更新后参与者数量: \(detailedConversation.participants.count)")
                    print("🔍 ChatDetailView: 更新后创建者: \(detailedConversation.creator?.id ?? -1)")
                    print("🔍 ChatDetailView: 更新后成员记录数量: \(detailedConversation.memberRecords?.count ?? 0)")

                    // 会话详情加载完成后，再次尝试获取对方用户ID
                    if let otherUserId = getOtherUserId() {
                        print("✅ ChatDetailView: 会话详情加载完成后成功获取对方用户ID: \(otherUserId)")
                    }
                }
            } catch {
                print("❌ ChatDetailView: 获取会话详情失败: \(error)")
                await MainActor.run {
                    self.isConversationDetailLoaded = true // 即使失败也标记为已加载，避免无限等待
                }
            }
        }
    }

    // MARK: - 计算属性

    /// 聊天标题（群聊显示成员数量）
    private var chatTitle: String {
        if conversation.type == .group {
            let memberCount = conversation.membersCount ?? 0
            return "\(conversation.displayName)（\(memberCount)）"
        } else {
            return conversation.displayName
        }
    }

    /// 自定义导航栏标题视图
    private var navigationTitleView: some View {
        VStack(spacing: 2) {
            // 主标题
            Text(chatTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                .lineLimit(1)

            // 群聊描述（仅群聊显示）
            if conversation.type == .group,
               let description = conversation.description,
               !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                    .frame(height: 16)
            }
        }
    }

    // MARK: - 主视图

    var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            messagesList

            // 输入区域
            messageInputArea
        }
        .background(ModernDesignSystem.Colors.chatBackground)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .asSubView()
        .toolbar {
            // 自定义导航栏标题
            ToolbarItem(placement: .principal) {
                navigationTitleView
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                // 显示底部菜单栏或用户详情
                if conversation.type == .group {
                    Button(action: {
                        activeSheet = .groupAction
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18))
                            .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                    }
                } else if conversation.type == .privateChat && isConversationDetailLoaded {
                    if let otherUserId = getOtherUserId() {
                        Button(action: {
                            activeSheet = .userProfile(otherUserId)
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18))
                                .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                        }
                    } else {
                        // 如果仍然无法获取用户ID，显示一个不可点击的按钮
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18))
                            .foregroundColor(ModernDesignSystem.Colors.primaryGreen.opacity(0.5))
                    }
                } else {
                    // 加载中或默认情况下显示一个不可点击的按钮
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen.opacity(0.5))
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadMessages()

                // 用户进入聊天页面时，标记消息为已读并更新角标
                await markMessagesAsReadAndUpdateBadge()
            }

            // 加载会话详情以获取参与者信息
            loadConversationDetail()
        }
        .onTapGesture {
            isInputFocused = false
            viewModel.stopTyping()
        }

        .onDisappear {
            // 清理键盘更新任务
            keyboardUpdateTask?.cancel()

            // 用户离开聊天页面时，更新角标以确保状态正确
            Task {
                await PushNotificationManager.shared.updateBadgeCount()
            }
        }

        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .userProfile(let userId):
                UserProfileView(userId: userId)
                    .ignoresSafeArea(.all, edges: .top)
                    .presentationDragIndicator(.hidden)
            
            case .groupAction:
                GroupDetailManagementView(conversation: conversation)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)

            case .editGroup:
                NavigationView {
                    EditGroupInfoView(conversation: conversation) { updatedConversation in
                        // 更新回调 - 更新本地会话信息
                        self.conversation = updatedConversation
                    }
                    .asSubView()
                }

            case .memberList:
                NavigationView {
                    GroupMemberListView(conversation: conversation)
                        .asSubView()
                }

            case .addMember:
                NavigationView {
                    AddGroupMemberView(conversation: conversation) { _ in
                        // 添加成员回调
                    }
                    .asSubView()
                }

            case .forward(let message):
                NavigationView {
                    ForwardMessageView(message: message) { conversationIds in
                        Task {
                            await forwardMessage(message: message, conversationIds: conversationIds)
                        }
                    }
                }

            case .chatExport:
                NavigationView {
                    ChatExportView(
                        conversationId: conversation.id,
                        conversationTitle: conversation.displayName
                    )
                }

            case .messageAction(let message):
                MessageActionBottomSheet(
                    message: message,
                    onReply: {
                        replyToMessage = message
                        isInputFocused = true
                        activeSheet = nil
                    },
                    onForward: {
                        activeSheet = .forward(message)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
            }
        }



        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }


    }
    

    
    // MARK: - 消息列表
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        loadingView
                    } else if viewModel.messages.isEmpty {
                        emptyMessagesView
                    } else {
                        // 历史消息加载指示器（在顶部）
                        if viewModel.isLoading && !viewModel.messages.isEmpty {
                            ProgressView()
                                .padding()
                        }

                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(
                                message: message,
                                isHighlighted: highlightedMessageId == message.id,
                                onLongPress: {
                                    selectedMessage = message
                                    activeSheet = .messageAction(message)
                                },
                                onReplyTap: { replyToMessageId in
                                    // 点击回复消息时跳转到原消息并高亮
                                    if let targetMessage = viewModel.findMessage(by: replyToMessageId) {
                                        print("🔍 ChatDetailView: 找到目标消息: \(targetMessage.content)")

                                        // 先滚动到目标消息
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            proxy.scrollTo(replyToMessageId, anchor: .center)
                                        }

                                        // 延迟一点时间后开始高亮动画
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                            highlightedMessageId = replyToMessageId

                                            // 3秒后取消高亮
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                withAnimation(.easeOut(duration: 0.5)) {
                                                    highlightedMessageId = nil
                                                }
                                            }
                                        }
                                    } else {
                                        print("❌ ChatDetailView: 未找到目标消息: \(replyToMessageId)")
                                    }
                                },
                                findMessage: { messageId in
                                    return viewModel.findMessage(by: messageId)
                                }
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding(.vertical, ModernDesignSystem.Spacing.md)
            }
            .refreshable {
                // 下拉刷新加载更多历史消息
                if viewModel.hasMoreMessages {
                    await viewModel.loadMoreMessages()
                }
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // 自动滚动到最新消息
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("加载消息中...")
                .font(ModernDesignSystem.Typography.body)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 空消息视图
    private var emptyMessagesView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            
            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                Text("开始聊天吧")
                    .font(ModernDesignSystem.Typography.headline)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                
                Text("发送第一条消息开始对话")
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 消息输入区域
    private var messageInputArea: some View {
        VStack(spacing: 0) {
            // 输入状态提示
            if !viewModel.typingUsers.isEmpty {
                typingIndicator
            }
            
            // 回复消息预览
            if let replyMessage = replyToMessage {
                replyPreviewView(replyMessage)
            }

            // 分隔线
            Rectangle()
                .fill(ModernDesignSystem.Colors.borderLight)
                .frame(height: 0.5)

            HStack(spacing: ModernDesignSystem.Spacing.md) {
                // 文本输入框
                textInputArea
                    .padding(.horizontal, ModernDesignSystem.Spacing.md)
                    .padding(.vertical, ModernDesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ModernDesignSystem.Colors.backgroundSecondary)
                            .stroke(ModernDesignSystem.Colors.borderLight, lineWidth: 0.5)
                    )

                // 发送按钮
                sendButton
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            .padding(.vertical, ModernDesignSystem.Spacing.md)
            .background(ModernDesignSystem.Colors.backgroundCard)
        }
    }
    
    // MARK: - 输入状态提示
    private var typingIndicator: some View {
        HStack(spacing: ModernDesignSystem.Spacing.sm) {
            Image(systemName: "ellipsis")
                .font(.caption)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                .scaleEffect(1.2)
                .opacity(0.8)
                .animation(.easeInOut(duration: 1.0).repeatForever(), value: UUID())
            
            Text(typingText)
                .font(ModernDesignSystem.Typography.caption1)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            
            Spacer()
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
        .background(ModernDesignSystem.Colors.backgroundCard)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: viewModel.typingUsers)
    }
    
    private var typingText: String {
        let typingCount = viewModel.typingUsers.count
        
        if typingCount == 0 {
            return ""
        } else if typingCount == 1 {
            return "正在输入..."
        } else if typingCount <= 3 {
            return "\(typingCount)人正在输入..."
        } else {
            return "多人正在输入..."
        }
    }
    
    // MARK: - 辅助方法

    /// 标记消息为已读并更新角标
    private func markMessagesAsReadAndUpdateBadge() async {
        // 获取最后一条不是当前用户发送的消息
        guard let lastMessage = viewModel.messages.last(where: { $0.senderId != viewModel.currentUserId }) else {
            print("ChatDetailView: 没有需要标记为已读的消息")
            return
        }

        do {
            // 标记消息为已读
            try await ChatAPIService.shared.markAsRead(
                conversationId: conversation.id,
                lastReadMessageId: lastMessage.id
            )

            print("ChatDetailView: 已标记消息为已读 - 消息ID: \(lastMessage.id)")

            // 等待一小段时间，让后端有时间更新数据库
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

            // 更新应用角标
            await PushNotificationManager.shared.updateBadgeCount()

            print("ChatDetailView: 已更新角标")
        } catch {
            print("ChatDetailView: 标记消息为已读失败: \(error)")
        }
    }

    /// 处理文本变化
    private func handleTextChange(_ newValue: String) {
        if newValue.isEmpty {
            // 停止输入状态
            viewModel.stopTyping()
        } else {
            // 开始输入状态
            viewModel.startTyping()
        }
    }

    /// 检查WebSocket连接状态
    private func checkWebSocketStatus() {
        let status = WebSocketManager.shared.getDetailedConnectionStatus()
        print("=== WebSocket状态检查 ===")
        print(status)
        print("========================")

        // 如果连接断开，尝试重连
        if !WebSocketManager.shared.isConnected {
            print("WebSocket未连接，尝试重新连接...")
            WebSocketManager.shared.forceReconnect()
        } else {
            // 检查连接健康状态
            WebSocketManager.shared.checkConnectionHealth()
        }
    }

    /// 获取私聊中对方用户的ID
    private func getOtherUserId() -> String? {
        guard conversation.type == .privateChat else { return nil }

        // 从当前用户管理器获取当前用户ID
        guard let currentUserId = AuthManager.shared.getCurrentUserId() else {
            print("❌ ChatDetailView: 无法获取当前用户ID")
            return nil
        }

        print("🔍 ChatDetailView: 当前用户ID: \(currentUserId)")
        print("🔍 ChatDetailView: 会话参与者数量: \(conversation.participants.count)")
        print("🔍 ChatDetailView: 会话创建者: \(conversation.creator?.id ?? -1)")
        print("🔍 ChatDetailView: 会话成员记录数量: \(conversation.memberRecords?.count ?? 0)")

        // 方法1: 从会话成员记录中找到不是当前用户的用户
        if let memberRecords = conversation.memberRecords {
            let otherMember = memberRecords.first { record in
                record.user.id != currentUserId
            }

            if let otherUserId = otherMember?.user.id {
                print("🔍 ChatDetailView: 从成员记录中找到对方用户ID: \(otherUserId)")
                return String(otherUserId)
            }
        }

        // 方法2: 从会话参与者中找到不是当前用户的用户
        let otherUser = conversation.participants.first { user in
            user.id != currentUserId
        }

        if let otherUserId = otherUser?.id {
            print("🔍 ChatDetailView: 从参与者中找到对方用户ID: \(otherUserId)")
            return String(otherUserId)
        }

        // 方法3: 如果参与者列表为空，尝试从创建者信息获取
        if let creator = conversation.creator, creator.id != currentUserId {
            print("🔍 ChatDetailView: 从创建者中找到对方用户ID: \(creator.id)")
            return String(creator.id)
        }

        // 方法4: 从最后一条消息的发送者获取
        if let lastMessage = conversation.lastMessage, lastMessage.sender.id != currentUserId {
            print("🔍 ChatDetailView: 从最后消息发送者中找到对方用户ID: \(lastMessage.sender.id)")
            return String(lastMessage.sender.id)
        }

        // 方法5: 从消息列表中的发送者获取
        let otherSender = viewModel.messages.first { message in
            message.senderId != currentUserId
        }

        if let otherSenderId = otherSender?.senderId {
            print("🔍 ChatDetailView: 从消息发送者中找到对方用户ID: \(otherSenderId)")
            return String(otherSenderId)
        }

        // 方法6: 尝试从会话ID中解析（如果会话ID包含用户ID信息）
        let conversationIdComponents = conversation.id.components(separatedBy: "_")
        if conversationIdComponents.count >= 2 {
            for component in conversationIdComponents {
                if let userId = Int(component), userId != currentUserId {
                    print("🔍 ChatDetailView: 从会话ID中解析出对方用户ID: \(userId)")
                    return String(userId)
                }
            }
        }

        print("❌ ChatDetailView: 所有方法都无法获取对方用户ID")
        print("🔍 ChatDetailView: 会话ID: \(conversation.id)")
        print("🔍 ChatDetailView: 会话标题: \(conversation.title ?? "无标题")")
        return nil
    }
    

    


    /// 检查是否可以撤回消息
    private func canRecallMessage(_ message: ChatMessage) -> Bool {
        let formatter = ISO8601DateFormatter()
        guard let messageDate = formatter.date(from: message.createdAt) else { return false }
        let timeInterval = Date().timeIntervalSince(messageDate)
        return timeInterval <= 120 // 2分钟内可撤回
    }
    
    // MARK: - 私有方法

    /// 回复预览视图
    private func replyPreviewView(_ message: ChatMessage) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("回复 \(message.sender.nickname)")
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)

                Text(message.content)
                    .font(ModernDesignSystem.Typography.footnote)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: {
                replyToMessage = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
        .background(ModernDesignSystem.Colors.backgroundSecondary)
    }

    /// 发送消息
    private func sendMessage() {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        Task {
            await viewModel.sendMessage(
                content: content,
                replyToMessageId: replyToMessage?.id
            )
            messageText = ""
            replyToMessage = nil
        }
    }

    /// 转发消息
    private func forwardMessage(message: ChatMessage, conversationIds: [String]) async {
        for conversationId in conversationIds {
            await viewModel.forwardMessage(message, to: conversationId)
        }

        messageToForward = nil
        selectedMessage = nil
    }







    // MARK: - 文本输入区域
    private var textInputArea: some View {
        TextField("发消息...", text: $messageText, axis: .vertical)
            .focused($isInputFocused)
            .textFieldStyle(PlainTextFieldStyle())
            .font(ModernDesignSystem.Typography.body)
            .lineLimit(1...5)
            .submitLabel(submitLabel)
            .onSubmit {
                if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sendMessage()
                }
            }
            .onChange(of: messageText) { _, newValue in
                handleTextChange(newValue)

                // 取消之前的键盘更新任务
                keyboardUpdateTask?.cancel()

                // 延迟更新键盘按钮以避免RTI错误
                keyboardUpdateTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms延迟

                    guard !Task.isCancelled else { return }

                    let trimmedText = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    let newSubmitLabel: SubmitLabel = trimmedText.isEmpty ? .return : .send

                    // 直接更新，避免比较操作
                    submitLabel = newSubmitLabel
                }
            }
    }

    // MARK: - 发送按钮
    private var sendButton: some View {
        Button(action: sendMessage) {
            Image(systemName: "paperplane.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? ModernDesignSystem.Colors.textSecondary
                    : ModernDesignSystem.Colors.primaryGreen
                )
        }
        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .animation(.easeInOut(duration: 0.2), value: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }








}

