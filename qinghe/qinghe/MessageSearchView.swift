import SwiftUI

/// 消息搜索视图
struct MessageSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MessageSearchViewModel()
    @State private var searchText = ""
    @State private var selectedConversation: ChatConversation?
    @State private var showingConversationPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            searchBar
            
            // 搜索范围选择
            searchScopeSection
            
            Divider()
            
            // 搜索结果列表
            searchResultsList
        }
        .navigationTitle("搜索消息")
        .navigationBarTitleDisplayMode(.inline)
        .asSubView()
        .navigationDestination(isPresented: $showingConversationPicker) {
            ConversationPickerView(
                selectedConversation: $selectedConversation
            )
        }
    }
    
    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                    .font(.system(size: 16))
                
                TextField("搜索消息内容", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        viewModel.clearResults()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.md)
            .padding(.vertical, ModernDesignSystem.Spacing.sm)
            .background(ModernDesignSystem.Colors.backgroundSecondary)
            .cornerRadius(ModernDesignSystem.CornerRadius.md)
            
            Button("搜索") {
                performSearch()
            }
            .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .foregroundColor(
                searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                    ? ModernDesignSystem.Colors.textTertiary 
                    : ModernDesignSystem.Colors.primaryGreen
            )
        }
        .padding(ModernDesignSystem.Spacing.md)
    }
    
    // MARK: - 搜索范围选择
    private var searchScopeSection: some View {
        VStack(spacing: ModernDesignSystem.Spacing.sm) {
            HStack {
                Text("搜索范围")
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                
                Spacer()
            }
            
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                // 全部对话
                Button {
                    selectedConversation = nil
                } label: {
                    HStack(spacing: ModernDesignSystem.Spacing.xs) {
                        Image(systemName: selectedConversation == nil ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedConversation == nil ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.textTertiary)
                        
                        Text("全部对话")
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                    }
                }
                
                Spacer()
                
                // 指定对话
                Button {
                    showingConversationPicker = true
                } label: {
                    HStack(spacing: ModernDesignSystem.Spacing.xs) {
                        Image(systemName: selectedConversation != nil ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedConversation != nil ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.textTertiary)
                        
                        Text(selectedConversation?.title ?? "选择对话")
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                    }
                }
            }
        }
        .padding(ModernDesignSystem.Spacing.md)
    }
    
    // MARK: - 搜索结果列表
    private var searchResultsList: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.searchResults.isEmpty {
                emptyStateView
            } else {
                resultsList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("搜索中...")
                .font(ModernDesignSystem.Typography.caption1)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            
            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                Text(searchText.isEmpty ? "输入关键词开始搜索" : "没有找到相关消息")
                    .font(ModernDesignSystem.Typography.headline)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                
                if !searchText.isEmpty {
                    Text("尝试使用其他关键词或调整搜索范围")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(ModernDesignSystem.Spacing.xl)
    }
    
    private var resultsList: some View {
        List {
            ForEach(viewModel.searchResults, id: \.id) { result in
                MessageSearchResultCard(
                    result: result,
                    searchKeyword: searchText,
                    onTap: {
                        // 跳转到消息所在的对话
                        navigateToMessage(result)
                    }
                )
                .listRowInsets(EdgeInsets(
                    top: ModernDesignSystem.Spacing.sm,
                    leading: ModernDesignSystem.Spacing.md,
                    bottom: ModernDesignSystem.Spacing.sm,
                    trailing: ModernDesignSystem.Spacing.md
                ))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            
            // 加载更多
            if viewModel.hasMore {
                loadMoreView
                    .onAppear {
                        loadMoreResults()
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var loadMoreView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text("加载更多...")
                .font(ModernDesignSystem.Typography.caption1)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            Spacer()
        }
        .padding(ModernDesignSystem.Spacing.md)
    }
    
    // MARK: - 私有方法
    
    private func performSearch() {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return }
        
        Task {
            await viewModel.searchMessages(
                keyword: keyword,
                conversationId: selectedConversation?.id
            )
        }
    }
    
    private func loadMoreResults() {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return }
        
        Task {
            await viewModel.loadMoreResults(
                keyword: keyword,
                conversationId: selectedConversation?.id
            )
        }
    }
    
    private func navigateToMessage(_ result: MessageSearchResult) {
        // TODO: 实现跳转到具体消息的逻辑
        dismiss()
    }
}

// MARK: - 消息搜索结果卡片
struct MessageSearchResultCard: View {
    let result: MessageSearchResult
    let searchKeyword: String
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
            // 对话信息
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                // 对话头像
                AsyncImage(url: URL(string: result.conversation.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(ModernDesignSystem.Colors.backgroundSecondary)
                        .overlay(
                            Text(String(result.conversation.title?.prefix(1) ?? "?"))
                                .font(ModernDesignSystem.Typography.caption1)
                                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                // 对话标题
                Text(result.conversation.title ?? "未知对话")
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // 发送时间
                Text(formatTime(result.message.createdAt))
                    .font(ModernDesignSystem.Typography.caption2)
                    .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            }
            
            // 发送者信息
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                // 发送者头像
                AsyncImage(url: URL(string: result.message.sender.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(ModernDesignSystem.Colors.backgroundSecondary)
                        .overlay(
                            Text(String(result.message.sender.nickname.prefix(1)))
                                .font(ModernDesignSystem.Typography.caption2)
                                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        )
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
                
                // 发送者昵称
                Text(result.message.sender.nickname)
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }
            
            // 消息内容（高亮关键词）
            highlightedMessageContent
        }
        .padding(ModernDesignSystem.Spacing.md)
        .background(ModernDesignSystem.Colors.backgroundPrimary)
        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
        .onTapGesture {
            onTap()
        }
    }
    
    private var highlightedMessageContent: some View {
        // TODO: 实现关键词高亮显示
        Text(result.message.content)
            .font(ModernDesignSystem.Typography.body)
            .foregroundColor(ModernDesignSystem.Colors.textPrimary)
            .lineLimit(3)
    }
    
    private func formatTime(_ dateString: String) -> String {
        // TODO: 实现时间格式化
        return dateString
    }
}

// MARK: - 对话选择器视图
struct ConversationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedConversation: ChatConversation?
    @StateObject private var viewModel = ChatListViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.conversations) { conversation in
                ConversationPickerRow(
                    conversation: conversation,
                    isSelected: selectedConversation?.id == conversation.id,
                    onSelect: {
                        selectedConversation = conversation
                        dismiss()
                    }
                )
            }
        }
        .navigationTitle("选择对话")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadConversations()
            }
        }
    }
}

// MARK: - 对话选择行
struct ConversationPickerRow: View {
    let conversation: ChatConversation
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // 对话头像
            AsyncImage(url: URL(string: conversation.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(ModernDesignSystem.Colors.backgroundSecondary)
                    .overlay(
                        Text(String(conversation.title?.prefix(1) ?? "?"))
                            .font(ModernDesignSystem.Typography.caption1)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // 对话信息
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.title ?? "未知对话")
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage.content)
                        .font(ModernDesignSystem.Typography.caption1)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 选择状态
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.textTertiary)
                .font(.system(size: 20))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - 预览
#Preview {
    MessageSearchView()
}