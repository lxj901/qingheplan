import SwiftUI

@MainActor
class CreatePlanViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @Published var hasEndDate: Bool = true
    @Published var selectedPriority: String = "中等"
    @Published var selectedCategory: String = "个人"
    @Published var estimatedTime: Int = 60 // 分钟
    @Published var reminderTime: Date = {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
    }()
    @Published var hasReminderTime: Bool = false
    @Published var goals: [String] = []
    @Published var newGoal: String = ""

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
    
    /// 创建计划
    func createPlan() async -> Bool {
        guard isFormValid else {
            UserFeedbackManager.shared.showWarning("请填写必要信息")
            return false
        }
        
        isLoading = true
        
        do {
            let planRequest = PlanRequestNew(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "无描述" : description.trimmingCharacters(in: .whitespacesAndNewlines),
                category: selectedCategory,
                startDate: startDate,
                endDate: hasEndDate ? endDate : calculateEndDateFromEstimatedTime(),
                goals: goals,
                reminderTime: hasReminderTime ? reminderTime : nil
            )
            
            let createdPlan = try await planService.createPlan(planRequest)

            // 如果设置了提醒时间，保存到本地存储
            if hasReminderTime {
                PlanReminderManager.shared.saveReminderTime(for: createdPlan.title, reminderTime: reminderTime)
            }

            UserFeedbackManager.shared.showSuccess("计划创建成功")
            isLoading = false
            return true
            
        } catch {
            NetworkErrorHandler.shared.handleError(error)
            isLoading = false
            return false
        }
    }
    
    /// 添加目标
    func addGoal() {
        let trimmedGoal = newGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedGoal.isEmpty && !goals.contains(trimmedGoal) {
            goals.append(trimmedGoal)
            newGoal = ""
        }
    }
    
    /// 删除目标
    func removeGoal(at index: Int) {
        if index < goals.count {
            goals.remove(at: index)
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
        
        // 检查预估时间
        if estimatedTime <= 0 {
            showErrorMessage("预估时间必须大于0")
            return false
        }
        
        return true
    }
    
    /// 重置表单
    func resetForm() {
        title = ""
        description = ""
        startDate = Date()
        endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        hasEndDate = true
        selectedPriority = "中等"
        selectedCategory = "个人"
        estimatedTime = 60
        let calendar = Calendar.current
        let now = Date()
        reminderTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        hasReminderTime = false
        goals = []
        newGoal = ""
        isLoading = false
        showError = false
        errorMessage = nil
    }
    
    // MARK: - Private Methods

    /// 根据预估时间计算结束时间
    private func calculateEndDateFromEstimatedTime() -> Date {
        // 如果设置了提醒时间，从提醒时间开始计算
        let baseTime = hasReminderTime ? reminderTime : startDate

        // 将预估时间（分钟）转换为秒并添加到基础时间
        let estimatedTimeInSeconds = TimeInterval(estimatedTime * 60)
        return baseTime.addingTimeInterval(estimatedTimeInSeconds)
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
