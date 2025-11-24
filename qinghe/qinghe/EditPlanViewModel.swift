import SwiftUI

@MainActor
class EditPlanViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @Published var hasEndDate: Bool = true
    @Published var selectedPriority: String = "中等"
    @Published var selectedCategory: String = "个人"
    @Published var startTime: String = "09:00"
    @Published var endTime: String = "18:00"

    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Constants
    let priorities = ["低", "中等", "高", "紧急"]
    let categories = ["个人", "工作", "学习", "健康", "家庭", "财务", "兴趣", "其他"]
    
    // MARK: - Private Properties
    private let planService = PlanService.shared
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Public Methods
    
    /// 从现有计划加载数据
    /// - Parameter plan: 现有计划
    func loadPlanData(from plan: PlanNew) {
        title = plan.title
        description = plan.description ?? ""
        selectedPriority = "中等" // PlanNew没有priority属性，使用默认值
        selectedCategory = plan.category ?? "个人"
        
        // 解析日期
        let formatter = ISO8601DateFormatter()
        // PlanNew使用startDate而不是startTime
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        startTime = dateFormatter.string(from: plan.startDate)

        // 设置开始日期
        startDate = plan.startDate
        
        endTime = dateFormatter.string(from: plan.endDate)

        // 设置结束日期
        endDate = plan.endDate
        hasEndDate = true
    }
    
    /// 更新计划
    /// - Parameter planId: 计划ID
    func updatePlan(_ planId: Int) async -> Bool {
        guard isFormValid else {
            UserFeedbackManager.shared.showWarning("请填写必要信息")
            return false
        }
        
        let taskId = "update_plan"
        // UserFeedbackManager.shared.startLoading("保存计划中...", taskId: taskId) // 暂时注释掉
        isLoading = true
        
        do {
            // TODO: 实现更新计划的API调用
            /*
            let response = try await planService.updatePlan(
                planId: planId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                startDate: ISO8601DateFormatter().string(from: startDate),
                endDate: hasEndDate ? ISO8601DateFormatter().string(from: endDate) : nil,
                priority: selectedPriority,
                category: selectedCategory
            )
            
            if !response.success {
                showErrorMessage(response.message ?? "更新计划失败")
                // UserFeedbackManager.shared.stopLoading(taskId: taskId) // 暂时注释掉
                isLoading = false
                return false
            }
            */
            
            // 临时模拟成功
            UserFeedbackManager.shared.showSuccess("计划已更新")
            // UserFeedbackManager.shared.stopLoading(taskId: taskId) // 暂时注释掉
            isLoading = false
            return true
        } catch {
            NetworkErrorHandler.shared.handleError(error)
            // UserFeedbackManager.shared.stopLoading(taskId: taskId) // 暂时注释掉
            isLoading = false
            return false
        }
    }
    
    /// 验证表单
    func validateForm() -> Bool {
        // 检查标题
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showErrorMessage("请输入计划标题")
            return false
        }
        
        // 检查时间
        if hasEndDate && endDate <= startDate {
            showErrorMessage("结束时间必须晚于开始时间")
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
