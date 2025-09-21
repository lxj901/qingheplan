import Foundation

/// 消息搜索视图模型
@MainActor
class MessageSearchViewModel: ObservableObject {
    @Published var searchResults: [MessageSearchResult] = []
    @Published var isLoading = false
    @Published var hasMore = false
    @Published var errorMessage: String?
    
    private var currentPage = 1
    private let chatService = ChatAPIService.shared
    
    /// 搜索消息
    func searchMessages(keyword: String, conversationId: String? = nil) async {
        isLoading = true
        currentPage = 1
        
        do {
            let response = try await chatService.searchMessages(
                query: keyword,
                conversationId: conversationId,
                page: currentPage
            )
            
            // 转换为搜索结果格式
            searchResults = response.messages.map { message in
                MessageSearchResult(
                    id: message.id,
                    message: message,
                    conversation: MessageSearchResult.ConversationInfo(
                        id: conversationId ?? "",
                        title: nil,
                        avatar: nil,
                        type: .privateChat
                    ),
                    matchedText: nil
                )
            }
            hasMore = response.pagination.hasNextPage
            currentPage += 1
        } catch {
            errorMessage = "搜索失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 加载更多搜索结果
    func loadMoreResults(keyword: String, conversationId: String? = nil) async {
        guard hasMore && !isLoading else { return }
        
        isLoading = true
        
        do {
            let response = try await chatService.searchMessages(
                query: keyword,
                conversationId: conversationId,
                page: currentPage
            )
            
            // 转换为搜索结果格式并添加到现有结果
            let newResults = response.messages.map { message in
                MessageSearchResult(
                    id: message.id,
                    message: message,
                    conversation: MessageSearchResult.ConversationInfo(
                        id: conversationId ?? "",
                        title: nil,
                        avatar: nil,
                        type: .privateChat
                    ),
                    matchedText: nil
                )
            }
            searchResults.append(contentsOf: newResults)
            hasMore = response.pagination.hasNextPage
            currentPage += 1
        } catch {
            errorMessage = "加载更多失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 清空搜索结果
    func clearResults() {
        searchResults = []
        hasMore = false
        currentPage = 1
        errorMessage = nil
    }
}

/// 消息搜索结果数据模型
struct MessageSearchResult: Identifiable, Codable {
    let id: String
    let message: ChatMessage
    let conversation: ConversationInfo
    let matchedText: String?
    
    struct ConversationInfo: Codable {
        let id: String
        let title: String?
        let avatar: String?
        let type: ConversationType
    }
}