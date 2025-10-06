import SwiftUI

/// 对话历史详情页面 - 显示选中对话的完整历史记录
struct ConversationHistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let conversationId: String
    
    @StateObject private var viewModel = ConversationHistoryViewModel()
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    var body: some View {
        ZStack {
            // 背景色
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 自定义导航栏
                customNavigationBar
                
                // 部分消息提示横幅
                if viewModel.showingPartialMessages {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("当前仅显示最后一轮对话")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("此对话共有 \(viewModel.totalMessageCount) 条消息")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.1))
                    .overlay(
                        Rectangle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(height: 0.5),
                        alignment: .bottom
                    )
                }
                
                // 消息列表
                if viewModel.isLoading && viewModel.messages.isEmpty {
                    // 首次加载中
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("加载中...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.messages.isEmpty {
                    // 空状态
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("暂无消息记录")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 消息列表
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModel.messages) { message in
                                    HistoryMessageBubble(
                                        content: message.content,
                                        isUser: message.role == "user",
                                        timestamp: message.timestamp
                                    )
                                    .id(message.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                        }
                        .onAppear {
                            scrollProxy = proxy
                            // 滚动到最后一条消息
                            if let lastMessage = viewModel.messages.last {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadMessages(conversationId: conversationId)
            }
        }
    }
    
    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack(spacing: 12) {
            // 返回按钮
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            
            // 标题
            VStack(alignment: .leading, spacing: 2) {
                Text("对话记录")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                if viewModel.isLoading && !viewModel.messages.isEmpty {
                    Text("加载中...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    Text("共 \(viewModel.messages.count) 条消息")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

// MARK: - 历史消息气泡视图
struct HistoryMessageBubble: View {
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // 消息内容
                if isUser {
                    // 用户消息 - 简单文本
                    Text(content)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(hex: "1F774E"))
                        )
                } else {
                    // AI 消息 - Markdown 渲染
                    VStack(alignment: .leading, spacing: 8) {
                        MarkdownTextView(text: content)
                        
                        // AI 生成提示
                        Text("内容由 AI 生成")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.85))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: "E0E0E0").opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                
                // 时间戳
                Text(formatTimestamp(timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !isUser {
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 6)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - ViewModel
@MainActor
class ConversationHistoryViewModel: ObservableObject {
    @Published var messages: [HistoryMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var totalMessageCount: Int = 0  // 对话的总消息数
    @Published var showingPartialMessages: Bool = false  // 是否只显示部分消息
    
    func loadMessages(conversationId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 正在加载对话 \(conversationId) 的历史消息...")
            let response = try await HealthChatAPIService.shared.getConversationMessages(
                conversationId: conversationId,
                page: 1,
                limit: 100
            )
            
            if let data = response.data {
                // 检查是否有消息列表
                if let messagesData = data.messages, !messagesData.isEmpty {
                    print("📋 收到 \(messagesData.count) 条原始消息")
                    
                    // 转换消息格式
                    messages = messagesData.enumerated().map { (index, msg) in
                        // 优先使用 timestamp，如果没有则使用 createdAt
                        let dateString = msg.timestamp ?? msg.createdAt ?? ""
                        print("🔍 消息 ID: \(msg.id), 角色: \(msg.role), 内容前30字: \(String(msg.content.prefix(30)))")
                        
                        // 生成唯一ID：使用原始ID + 索引 + 时间戳
                        let uniqueId = "\(msg.id)_\(index)_\(dateString.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ":", with: "-"))"
                        
                        return HistoryMessage(
                            id: uniqueId,
                            content: msg.content,
                            role: msg.role,
                            timestamp: parseDate(dateString)
                        )
                    }
                    .sorted { $0.timestamp < $1.timestamp } // 按时间排序
                    
                    print("✅ 成功加载 \(messages.count) 条历史消息")
                    // 打印每条消息的详细信息
                    for (index, message) in messages.enumerated() {
                        print("📨 消息 \(index + 1): ID=\(message.id), Role=\(message.role), Content=\(String(message.content.prefix(50)))")
                    }
                } 
                // 兼容服务器返回对话列表的情况
                else if let conversations = data.conversations, let conversation = conversations.first {
                    print("⚠️ 服务器返回的是对话列表而不是消息列表，尝试从对话中提取消息...")
                    
                    // 记录总消息数（解包可选类型）
                    totalMessageCount = conversation.messageCount ?? 0
                    
                    // 从对话对象中提取用户消息和 AI 回复
                    var extractedMessages: [HistoryMessage] = []
                    
                    if let userMsg = conversation.lastUserMessage {
                        extractedMessages.append(HistoryMessage(
                            id: "\(conversation.conversationId)_user",
                            content: userMsg,
                            role: "user",
                            timestamp: parseDate(conversation.lastMessageAt)
                        ))
                    }
                    
                    if let aiReply = conversation.lastAiReply {
                        extractedMessages.append(HistoryMessage(
                            id: "\(conversation.conversationId)_ai",
                            content: aiReply,
                            role: "assistant",
                            timestamp: parseDate(conversation.lastMessageAt)
                        ))
                    }
                    
                    messages = extractedMessages.sorted { $0.timestamp < $1.timestamp }
                    
                    // 标记是否只显示部分消息
                    showingPartialMessages = totalMessageCount > messages.count
                    
                    print("✅ 从对话对象中提取了 \(messages.count) 条消息（总共 \(totalMessageCount) 条）")
                } else {
                    print("⚠️ 响应数据中没有消息或对话信息")
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ 加载历史消息失败: \(error)")
        }
        
        isLoading = false
    }
    
    private func parseDate(_ dateString: String) -> Date {
        // 尝试多种日期格式
        
        // 1. ISO8601 格式（带时区）
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // 2. 标准 ISO8601（不带毫秒）
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // 3. 常见格式："yyyy-MM-dd HH:mm:ss"
        let standardFormatter = DateFormatter()
        standardFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        standardFormatter.locale = Locale(identifier: "en_US_POSIX")
        standardFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        if let date = standardFormatter.date(from: dateString) {
            return date
        }
        
        // 4. 带 T 的格式："yyyy-MM-dd'T'HH:mm:ss"
        standardFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = standardFormatter.date(from: dateString) {
            return date
        }
        
        // 5. 时间戳（毫秒）
        if let timestamp = Double(dateString) {
            return Date(timeIntervalSince1970: timestamp / 1000)
        }
        
        // 默认返回当前时间
        print("⚠️ 无法解析日期字符串: \(dateString)")
        return Date()
    }
}

// MARK: - 历史消息模型
struct HistoryMessage: Identifiable {
    let id: String
    let content: String
    let role: String  // "user" 或 "assistant"
    let timestamp: Date
}


