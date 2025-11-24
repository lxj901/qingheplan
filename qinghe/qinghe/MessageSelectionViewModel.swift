import Foundation
import Combine

/// 消息选择 ViewModel
@MainActor
class MessageSelectionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 消息列表
    @Published var messages: [HealthChatMessage] = []
    
    /// 已选择的消息ID集合
    @Published var selectedMessageIds: Set<String> = []
    
    /// 是否正在加载消息
    @Published var isLoading = false
    
    /// 是否正在生成海报
    @Published var isGenerating = false
    
    /// 是否显示提示弹窗
    @Published var showAlert = false
    
    /// 提示信息
    @Published var alertMessage = ""
    
    /// 是否显示海报预览
    @Published var showPosterPreview = false
    
    /// 生成的海报URL
    @Published var generatedPosterUrl: String?
    
    /// 生成的分享URL
    @Published var generatedShareUrl: String?
    
    // MARK: - Constants
    
    /// 最大选择数量
    private let maxSelectionCount = 10
    
    // MARK: - Dependencies
    
    private let apiService = HealthChatAPIService.shared
    
    // MARK: - Public Methods
    
    /// 加载对话消息列表
    func loadMessages(conversationId: String) {
        isLoading = true

        Task {
            do {
                let response = try await apiService.getConversationMessages(conversationId: conversationId)

                if let messagesData = response.data?.messages {
                    // 直接使用 API 返回的消息
                    messages = messagesData
                    print("✅ 加载了 \(messages.count) 条消息")
                } else {
                    messages = []
                    print("⚠️ 没有消息数据")
                }

                isLoading = false
            } catch {
                isLoading = false
                alertMessage = "加载消息失败：\(error.localizedDescription)"
                showAlert = true
                print("❌ 加载消息失败: \(error)")
            }
        }
    }
    
    /// 切换消息选择状态
    func toggleSelection(_ messageId: String) {
        if selectedMessageIds.contains(messageId) {
            selectedMessageIds.remove(messageId)
        } else {
            if selectedMessageIds.count >= maxSelectionCount {
                alertMessage = "最多只能选择 \(maxSelectionCount) 条消息"
                showAlert = true
                return
            }
            selectedMessageIds.insert(messageId)
        }
    }
    
    /// 全选消息
    func selectAll() {
        let allIds = messages.prefix(maxSelectionCount).map { $0.id }
        selectedMessageIds = Set(allIds)
    }
    
    /// 清空选择
    func clearSelection() {
        selectedMessageIds.removeAll()
    }
    
    /// 生成海报
    func generatePoster() {
        guard !selectedMessageIds.isEmpty else {
            alertMessage = "请至少选择一条消息"
            showAlert = true
            return
        }
        
        isGenerating = true
        
        Task {
            do {
                // 将选中的消息ID转换为数组并排序（保持时间顺序）
                let messageIdsArray = Array(selectedMessageIds).sorted()
                
                print("🎨 开始生成海报，消息数量: \(messageIdsArray.count)")
                print("📝 消息IDs: \(messageIdsArray)")
                
                let response = try await apiService.generatePoster(messageIds: messageIdsArray)
                
                if let data = response.data {
                    generatedPosterUrl = data.posterUrl
                    generatedShareUrl = data.shareUrl
                    isGenerating = false
                    showPosterPreview = true
                    
                    print("✅ 海报生成成功")
                    print("🖼️ 海报URL: \(data.posterUrl)")
                    print("🔗 分享URL: \(data.shareUrl ?? "无")")
                } else {
                    throw NSError(domain: "PosterGeneration", code: -1, userInfo: [NSLocalizedDescriptionKey: "海报数据为空"])
                }
                
            } catch {
                isGenerating = false
                alertMessage = "生成海报失败：\(error.localizedDescription)"
                showAlert = true
                print("❌ 生成海报失败: \(error)")
            }
        }
    }
    
}

// MARK: - 注意：HealthChatMessage 和 ConversationMessagesResponse 已在 HealthChatAPIService.swift 中定义

