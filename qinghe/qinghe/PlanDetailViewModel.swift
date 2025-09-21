import SwiftUI

@MainActor
class PlanDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var showDeleteAlert: Bool = false
    @Published var deleteSuccess: Bool = false
    @Published var currentProgress: Double = 0.0
    @Published var goals: [String] = []
    
    // MARK: - Private Properties
    private let planService = PlanService.shared
    
    // MARK: - Public Methods
    
    /// 加载计划详情
    /// - Parameter planId: 计划ID
    func loadPlanDetails(_ planId: UUID) async {
        isLoading = true
        
        do {
            // 这里可以加载更多详细信息，如子任务、目标等
            // let planDetails = try await planService.getPlanDetails(planId: planId)
            // goals = planDetails.goals ?? []
            isLoading = false
        } catch {
            showErrorMessage("加载计划详情失败: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    /// 删除计划
    /// - Parameter planId: 计划ID
    func deletePlan(_ planId: Int) async {
        isLoading = true
        deleteSuccess = false
        
        do {
            try await planService.deletePlan(planId: planId)
            deleteSuccess = true
        } catch {
            showErrorMessage("删除失败: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// 完成计划
    /// - Parameter planId: 计划ID
    func completePlan(_ planId: Int) async {
        isLoading = true
        
        do {
            let _ = try await planService.completePlan(planId: planId)
            isLoading = false
        } catch {
            showErrorMessage("标记完成失败: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    /// 更新计划进度
    /// - Parameters:
    ///   - planId: 计划ID
    ///   - progress: 进度值 (0.0-1.0)
    func updateProgress(_ planId: Int, progress: Double) async {
        isLoading = true
        
        do {
            let progressPercentage = Int(progress * 100)
            let _ = try await planService.updatePlan(
                planId: planId,
                title: nil,
                description: nil,
                category: nil,
                priority: nil,
                status: nil
            )
            isLoading = false
        } catch {
            showErrorMessage("更新进度失败: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    /// 更新计划信息
    /// - Parameters:
    ///   - planId: 计划ID
    ///   - title: 标题
    ///   - description: 描述
    ///   - category: 分类
    ///   - priority: 优先级
    ///   - status: 状态
    func updatePlan(
        planId: Int,
        title: String? = nil,
        description: String? = nil,
        category: String? = nil,
        priority: String? = nil,
        status: String? = nil
    ) async -> Bool {
        isLoading = true
        
        do {
            let _ = try await planService.updatePlan(
                planId: planId,
                title: title,
                description: description,
                category: category,
                priority: priority,
                status: status
            )
            isLoading = false
            return true
        } catch {
            showErrorMessage("更新计划失败: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
    
    /// 开始计划
    /// - Parameter planId: 计划ID
    func startPlan(_ planId: Int) async {
        isLoading = true
        
        do {
            let _ = try await planService.startPlan(planId: planId)
            isLoading = false
        } catch {
            showErrorMessage("开始计划失败: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    // MARK: - Private Methods
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
