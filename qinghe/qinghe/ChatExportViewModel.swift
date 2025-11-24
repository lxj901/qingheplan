import Foundation

/// 聊天记录导出视图模型
@MainActor
class ChatExportViewModel: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var exportCompleted = false
    @Published var exportInfo: ExportInfo?
    @Published var estimatedMessageCount = 0
    @Published var estimatedFileSize = ""
    @Published var errorMessage: String?
    
    private let conversationId: String
    private let chatService = ChatAPIService.shared
    private var exportTask: Task<Void, Never>?
    
    init(conversationId: String) {
        self.conversationId = conversationId
        
        // 启动时获取预估信息
        Task {
            await loadEstimatedInfo()
        }
    }
    
    /// 开始导出
    func startExport(format: ExportFormat, startDate: Date, endDate: Date) async {
        guard !isExporting else { return }
        
        isExporting = true
        exportProgress = 0.0
        exportCompleted = false
        exportInfo = nil
        errorMessage = nil
        
        exportTask = Task {
            do {
                // 模拟导出进度
                await updateProgress(0.1)
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                
                let response = try await chatService.exportChatHistory(
                    conversationId: conversationId,
                    format: format,
                    startDate: startDate,
                    endDate: endDate
                )
                
                await updateProgress(0.8)
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                
                // 处理导出结果
                await handleExportResponse(response, format: format)
                
                await updateProgress(1.0)
                
                exportCompleted = true
                isExporting = false
                
            } catch {
                if !Task.isCancelled {
                    errorMessage = "导出失败: \(error.localizedDescription)"
                }
                isExporting = false
                exportProgress = 0.0
            }
        }
    }
    
    /// 取消导出
    func cancelExport() {
        exportTask?.cancel()
        exportTask = nil
        isExporting = false
        exportProgress = 0.0
    }
    
    /// 重置导出状态
    func resetExport() {
        exportCompleted = false
        exportInfo = nil
        exportProgress = 0.0
        errorMessage = nil
    }
    
    /// 加载预估信息
    private func loadEstimatedInfo() async {
        do {
            let stats = try await chatService.getChatStatistics(conversationId: conversationId)
            estimatedMessageCount = stats.messageCount
            // 估算文件大小（每条消息约100字节）
            let estimatedBytes = Int64(stats.messageCount * 100)
            estimatedFileSize = formatFileSize(estimatedBytes)
        } catch {
            print("加载预估信息失败: \(error)")
        }
    }
    
    /// 更新进度
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            exportProgress = progress
        }
    }
    
    /// 处理导出响应
    private func handleExportResponse(_ response: ChatExportResponse, format: ExportFormat) async {
        let info = ExportInfo(
            fileName: response.fileName ?? generateFileName(format: format),
            fileSize: formatFileSize(response.fileSize ?? 0),
            downloadUrl: response.downloadUrl,
            format: format
        )
        
        exportInfo = info
    }
    
    /// 生成文件名
    private func generateFileName(format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        return "chat_export_\(dateString).\(format.rawValue)"
    }
    
    /// 格式化文件大小
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

/// 导出信息数据模型
struct ExportInfo {
    let fileName: String
    let fileSize: String
    let downloadUrl: String?
    let format: ExportFormat
}

/// 导出响应数据模型
struct ExportResponse: Codable {
    let fileName: String?
    let fileSize: Int64?
    let downloadUrl: String?
    let exportId: String?
}

/// 聊天导出响应数据模型
struct ChatExportResponse: Codable {
    let fileName: String?
    let fileSize: Int64?
    let downloadUrl: String?
    let exportId: String?
}

// MARK: - ChatAPIService 扩展 (聊天记录导出)
extension ChatAPIService {
    /// 导出聊天记录
    func exportChatHistory(
        conversationId: String,
        format: ExportFormat,
        startDate: Date,
        endDate: Date
    ) async throws -> ChatExportResponse {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let parameters: [String: Any] = [
            "format": format.rawValue,
            "startDate": dateFormatter.string(from: startDate),
            "endDate": dateFormatter.string(from: endDate)
        ]
        
        let response = try await NetworkManager.shared.request(
            endpoint: "/messages/conversations/\(conversationId)/export",
            method: .GET,
            parameters: parameters,
            responseType: ExportResponse.self
        )
        
        return ChatExportResponse(
            fileName: response.fileName,
            fileSize: response.fileSize,
            downloadUrl: response.downloadUrl,
            exportId: response.exportId
        )
    }
}