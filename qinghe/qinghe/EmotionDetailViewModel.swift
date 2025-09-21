import SwiftUI

@MainActor
class EmotionDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var showDeleteAlert: Bool = false
    @Published var deleteSuccess: Bool = false

    // MARK: - Private Properties
    private let emotionService = EmotionService.shared

    // MARK: - Public Methods

    /// 删除情绪记录
    /// - Parameter emotionId: 情绪记录ID
    func deleteEmotion(_ emotionId: Int) async {
        isLoading = true
        deleteSuccess = false

        do {
            try await emotionService.deleteEmotion(id: emotionId)
            deleteSuccess = true
        } catch {
            showErrorMessage("删除失败: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// 更新情绪记录
    /// - Parameters:
    ///   - emotionId: 情绪记录ID
    ///   - type: 情绪类型
    ///   - intensity: 强度
    ///   - trigger: 触发因素
    ///   - note: 备注
    ///   - tags: 标签
    func updateEmotion(
        emotionId: Int,
        type: String,
        intensity: Int,
        trigger: String? = nil,
        note: String? = nil,
        tags: [String]? = nil
    ) async -> Bool {
        isLoading = true

        do {
            let _ = try await emotionService.updateEmotion(
                emotionId: emotionId,
                type: type,
                intensity: intensity,
                trigger: trigger,
                note: note,
                strategies: tags
            )
            isLoading = false
            return true
        } catch {
            showErrorMessage("更新失败: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
    
    /// 编辑情绪记录
    /// - Parameters:
    ///   - emotionId: 情绪记录ID
    ///   - type: 新的情绪类型
    ///   - intensity: 新的强度
    ///   - note: 新的备注
    ///   - tags: 新的标签
    ///   - trigger: 新的触发因素
    func editEmotion(
        emotionId: Int,
        type: String,
        intensity: Int,
        note: String? = nil,
        tags: [String]? = nil,
        trigger: String? = nil
    ) async -> Bool {
        isLoading = true
        
        do {
            // TODO: 实现编辑功能，需要后端API支持
            // let updatedEmotion = try await emotionService.updateEmotion(...)
            isLoading = false
            return true
        } catch {
            showErrorMessage("编辑失败: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
    
    /// 基于现有记录创建新记录
    /// - Parameter emotion: 现有的情绪记录
    func createSimilarEmotion(basedOn emotion: EmotionNew) async -> Bool {
        isLoading = true
        
        do {
            let request = EmotionRequestNew(
                type: emotion.type,
                intensity: emotion.intensity,
                note: emotion.note,
                tags: emotion.tags,
                trigger: emotion.trigger,
                recordTime: nil
            )
            let _ = try await emotionService.createEmotion(request)
            isLoading = false
            return true
        } catch {
            showErrorMessage("创建记录失败: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
