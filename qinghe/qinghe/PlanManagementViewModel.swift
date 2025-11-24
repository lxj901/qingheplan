import SwiftUI

@MainActor
class PlanManagementViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var plans: [Plan] = []
    @Published var planStats: PlanStats?
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "全部"
    @Published var selectedStatus: String = "全部"
    
    // MARK: - Constants
    let categories = ["全部", "个人", "工作", "学习", "健康", "家庭", "财务", "兴趣", "其他"]
    let statuses = ["全部", "进行中", "已完成", "已暂停", "已取消"]
    
    // MARK: - Private Properties
    private let planService = PlanService.shared
    
    // MARK: - Computed Properties
    
    var filteredPlans: [Plan] {
        var filtered = plans

        // 按分类筛选
        if selectedCategory != "全部" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }

        // 按状态筛选（基于 isActive 属性）
        if selectedStatus != "全部" {
            switch selectedStatus {
            case "进行中":
                filtered = filtered.filter { $0.isActive }
            case "已暂停", "已取消":
                filtered = filtered.filter { !$0.isActive }
            case "已完成":
                filtered = filtered.filter { $0.progress >= 1.0 }
            default:
                break
            }
        }

        // 按搜索文本筛选
        if !searchText.isEmpty {
            filtered = filtered.filter { plan in
                plan.title.localizedCaseInsensitiveContains(searchText) ||
                plan.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }
    
    // MARK: - Public Methods
    
    /// 加载计划列表
    func loadPlans() async {
        isLoading = true
        
        do {
            let planList = try await planService.getPlans(page: 1, limit: 100)
            
            // 将 PlanNew 转换为 Plan
            plans = planList.plans.map { planNew in
                Plan(
                    title: planNew.title,
                    description: planNew.description,
                    category: planNew.category,
                    startDate: planNew.startDate,
                    endDate: planNew.endDate,
                    isActive: planNew.isActive,
                    progress: planNew.progress,
                    status: planNew.status,
                    reminderTime: nil
                )
            }
            
        } catch {
            showErrorMessage("加载计划失败: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// 加载计划统计
    func loadPlanStats() async {
        // 计算统计数据
        let totalPlans = plans.count
        let completedPlans = plans.filter { $0.progress >= 1.0 }.count
        let activePlans = plans.filter { $0.isActive }.count
        let pausedPlans = plans.filter { !$0.isActive && $0.progress < 1.0 }.count

        let completionRate = totalPlans > 0 ? Double(completedPlans) / Double(totalPlans) : 0.0

        planStats = PlanStats(
            totalPlans: totalPlans,
            completedPlans: completedPlans,
            activePlans: activePlans,
            pausedPlans: pausedPlans,
            completionRate: completionRate
        )
    }
    
    /// 添加计划
    func addPlan(_ planNew: PlanNew) async {
        let plan = Plan(
            title: planNew.title,
            description: planNew.description,
            category: planNew.category,
            startDate: planNew.startDate,
            endDate: planNew.endDate,
            isActive: planNew.isActive,
            progress: planNew.progress,
            status: planNew.status,
            reminderTime: nil
        )

        plans.insert(plan, at: 0)
        await loadPlanStats()
    }
    
    /// 更新计划
    func updatePlan(_ planNew: PlanNew) async {
        if let index = plans.firstIndex(where: { $0.id.uuidString == planNew.id.uuidString }) {
            let updatedPlan = Plan(
                title: planNew.title,
                description: planNew.description,
                category: planNew.category,
                startDate: planNew.startDate,
                endDate: planNew.endDate,
                isActive: planNew.isActive,
                progress: planNew.progress,
                status: planNew.status,
                reminderTime: plans[index].reminderTime
            )

            plans[index] = updatedPlan
            await loadPlanStats()
        }
    }
    
    /// 删除计划
    func deletePlan(_ plan: Plan) async {
        // 由于 Plan 的 id 是 UUID，我们无法直接删除服务器上的计划
        // 这里只是从本地列表中移除
        plans.removeAll { $0.id == plan.id }
        await loadPlanStats()
        UserFeedbackManager.shared.showSuccess("计划已删除")
    }
    
    /// 刷新数据
    func refresh() async {
        await loadPlans()
        await loadPlanStats()
    }
    
    // MARK: - Private Methods
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Data Models

struct PlanStats {
    let totalPlans: Int
    let completedPlans: Int
    let activePlans: Int
    let pausedPlans: Int
    let completionRate: Double
}

// MARK: - Plan Extension

extension Plan {
    func toPlanNew() -> PlanNew {
        return PlanNew(
            title: title,
            description: description,
            category: category,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            progress: progress
        )
    }
}
