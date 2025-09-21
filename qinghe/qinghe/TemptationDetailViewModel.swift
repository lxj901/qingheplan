import SwiftUI

@MainActor
class TemptationDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var showDeleteAlert: Bool = false
    @Published var deleteSuccess: Bool = false
    
    // MARK: - Private Properties
    private let temptationService = TemptationService.shared
    
    // MARK: - Public Methods
    
    /// 删除诱惑记录
    /// - Parameter temptationId: 诱惑记录ID
    func deleteTemptation(_ temptationId: Int) async {
        isLoading = true
        deleteSuccess = false
        
        do {
            try await temptationService.deleteTemptation(temptationId: temptationId)
            deleteSuccess = true
        } catch {
            showErrorMessage("删除失败: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// 编辑诱惑记录
    /// - Parameters:
    ///   - temptationId: 诱惑记录ID
    ///   - type: 新的诱惑类型
    ///   - intensity: 新的强度
    ///   - result: 新的结果
    ///   - note: 新的备注
    ///   - strategies: 新的策略
    func editTemptation(
        temptationId: Int,
        type: String,
        intensity: Int,
        result: String,
        note: String? = nil,
        strategies: [String]? = nil
    ) async -> Bool {
        isLoading = true

        do {
            let _ = try await temptationService.updateTemptation(
                temptationId: temptationId,
                type: type,
                intensity: intensity,
                result: result,
                note: note,
                strategies: strategies
            )
            isLoading = false
            return true
        } catch {
            showErrorMessage("编辑失败: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
    
    /// 基于现有记录创建新记录
    /// - Parameter temptation: 现有的诱惑记录
    func createSimilarTemptation(basedOn temptation: TemptationNew) async -> Bool {
        isLoading = true
        
        do {
            let _ = try await temptationService.createTemptation(
                type: temptation.type,
                intensity: temptation.intensity,
                result: temptation.resisted ? "已抵抗" : "未抵抗",
                note: temptation.note,
                strategies: temptation.strategy != nil ? [temptation.strategy!] : ["无策略"]
            )
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
