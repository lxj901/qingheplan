import SwiftUI

/// 转发消息视图
struct ForwardMessageView: View {
    let message: ChatMessage?
    let onForward: ([String]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChatListViewModel()
    @State private var selectedConversations: Set<String> = []
    @State private var searchText = ""
    @State private var filteredConversations: [ChatConversation] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            searchBar
            
            // 消息预览
            if let message = message {
                messagePreview(message)
            }
            
            // 会话列表
            conversationsList
        }
        .navigationTitle("转发到")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("发送") {
                    onForward(Array(selectedConversations))
                    dismiss()
                }
                .disabled(selectedConversations.isEmpty)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadConversations()
                updateFilteredConversations()
            }
        }
        .onChange(of: searchText) {
            updateFilteredConversations()
        }
        .onChange(of: viewModel.conversations) {
            updateFilteredConversations()
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
    }
    
    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            
            TextField("搜索会话", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.md)
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
        .background(ModernDesignSystem.Colors.backgroundSecondary)
        .cornerRadius(ModernDesignSystem.CornerRadius.md)
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.md)
    }
    
    // MARK: - 消息预览
    private func messagePreview(_ message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
            Text("转发消息")
                .font(ModernDesignSystem.Typography.caption1)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                // 发送者头像
                CachedAvatarView(
                    url: URL(string: message.sender.avatar ?? ""),
                    fallbackText: message.sender.nickname,
                    size: 32
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.sender.nickname)
                        .font(ModernDesignSystem.Typography.footnote)
                        .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                    
                    Text(message.content)
                        .font(ModernDesignSystem.Typography.footnote)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.md)
        .background(ModernDesignSystem.Colors.backgroundCard)
    }
    
    // MARK: - 会话列表
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.isLoading && filteredConversations.isEmpty {
                    // 初始加载状态
                    VStack(spacing: ModernDesignSystem.Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(ModernDesignSystem.Colors.primaryGreen)

                        Text("加载会话列表...")
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else if filteredConversations.isEmpty {
                    // 空状态
                    VStack(spacing: ModernDesignSystem.Spacing.md) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)

                        Text(searchText.isEmpty ? "暂无会话" : "未找到匹配的会话")
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)

                        if !searchText.isEmpty {
                            Text("尝试使用其他关键词搜索")
                                .font(ModernDesignSystem.Typography.footnote)
                                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    // 会话列表
                    ForEach(filteredConversations) { conversation in
                        conversationRow(conversation)
                            .background(Color.clear)

                        // 分隔线
                        if conversation.id != filteredConversations.last?.id {
                            Divider()
                                .padding(.leading, 68) // 对齐头像右侧
                        }
                    }

                    // 底部加载状态指示器
                    if viewModel.isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(ModernDesignSystem.Colors.primaryGreen)

                            Text("加载更多...")
                                .font(ModernDesignSystem.Typography.footnote)
                                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        }
                        .padding(.vertical, ModernDesignSystem.Spacing.lg)
                    }
                }
            }
            .padding(.horizontal, 0)
        }
    }
    
    // MARK: - 会话行
    private func conversationRow(_ conversation: ChatConversation) -> some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // 选择状态
            Button(action: {
                if selectedConversations.contains(conversation.id) {
                    selectedConversations.remove(conversation.id)
                } else {
                    selectedConversations.insert(conversation.id)
                }
            }) {
                Image(systemName: selectedConversations.contains(conversation.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(
                        selectedConversations.contains(conversation.id) ?
                        ModernDesignSystem.Colors.primaryGreen :
                        ModernDesignSystem.Colors.textTertiary
                    )
                    .font(.system(size: 20))
            }
            
            // 会话头像
            CachedAvatarView(
                url: URL(string: conversation.avatar ?? ""),
                fallbackText: conversation.displayName,
                size: 44
            )
            
            // 会话信息
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.displayName)
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage.content)
                        .font(ModernDesignSystem.Typography.footnote)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.md)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if selectedConversations.contains(conversation.id) {
                selectedConversations.remove(conversation.id)
            } else {
                selectedConversations.insert(conversation.id)
            }
        }
    }
    
    // MARK: - 私有方法
    private func updateFilteredConversations() {
        if searchText.isEmpty {
            filteredConversations = viewModel.conversations
        } else {
            filteredConversations = viewModel.conversations.filter { conversation in
                conversation.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}


