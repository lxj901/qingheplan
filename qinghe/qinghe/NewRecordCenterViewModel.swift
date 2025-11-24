import Foundation
import SwiftUI
import Combine

@MainActor
class NewRecordCenterViewModel: ObservableObject {
    // MARK: - 发布的属性
    @Published var emotionRecords: [EmotionNew] = []
    @Published var temptationRecords: [TemptationNew] = []
    @Published var checkinStats: ActualCheckinStatsData?
    @Published var todayCheckinStatus: TodayCheckinStatus?
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    @Published var plans: [Plan] = []
    @Published var hasCheckedInToday: Bool = false
    @Published var consecutiveDays: Int = 0
    @Published var monthlyCompletionRate: Int = 0
    @Published var totalCheckinDays: Int = 0
    
    @Published var planCompletionRate: Int = 0
    @Published var mainEmotion: String = "平静"
    @Published var temptationResistanceRate: Int = 0
    
    // MARK: - 私有属性
    private let emotionService = EmotionService.shared
    private let temptationService = TemptationService.shared
    private let checkinService = CheckinService.shared
    private let planService = PlanService.shared
    private let planStatusManager = PlanStatusManager.shared
    private var statusUpdateCancellable: AnyCancellable?
    
    // MARK: - 初始化
    init() {
        initializeData()
        updateStatistics()
        setupStatusUpdateListener()
    }
    
    deinit {
        statusUpdateCancellable?.cancel()
    }
    
    // MARK: - 状态监听设置
    private func setupStatusUpdateListener() {
        statusUpdateCancellable = NotificationCenter.default
            .publisher(for: .planStatusDidUpdate)
            .sink { [weak self] notification in
                Task { @MainActor in
                    if let updatedPlans = notification.object as? [Plan] {
                        await self?.handlePlanStatusUpdate(updatedPlans)
                    }
                }
            }
    }
    
    // MARK: - 处理计划状态更新
    private func handlePlanStatusUpdate(_ updatedPlans: [Plan]) async {
        // 过滤今日计划
        let today = getCurrentDateString()
        let todayUpdatedPlans = updatedPlans.filter { plan in
            if let startTime = plan.reminderTime {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let startTimeString = dateFormatter.string(from: startTime)
                return startTimeString == today
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let createdAtString = dateFormatter.string(from: plan.startDate)
            return createdAtString == today
        }
        
        // 更新本地计划列表
        self.plans = todayUpdatedPlans
        
        // 重新计算统计数据
        updateStatistics()
        
        print("✅ 计划状态已更新，今日计划数量: \(todayUpdatedPlans.count)")
    }
    
    // MARK: - 数据加载
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            // 并行加载所有数据
            group.addTask { await self.loadEmotionRecords() }
            group.addTask { await self.loadTemptationRecords() }
            group.addTask { await self.loadTodayPlans() }
            group.addTask { await self.loadTodayCheckinStatus() }
        }
        
        // 加载完成后更新统计
        updateStatistics()
        isLoading = false
    }
    
    // MARK: - 情绪记录加载
    private func loadEmotionRecords() async {
        do {
            let emotionResponse = try await emotionService.getEmotions(page: 1, limit: 10)
            // 过滤今日记录
            let today = getCurrentDateString()
            emotionRecords = emotionResponse.emotions.filter { emotion in
                emotion.createdAt.starts(with: today)
            }
            print("✅ 成功加载情绪记录: \(emotionRecords.count) 条")
        } catch {
            print("❌ 加载情绪记录失败: \(error.localizedDescription)")
            emotionRecords = []
        }
    }
    
    // MARK: - 诱惑记录加载
    private func loadTemptationRecords() async {
        do {
            let todayTemptations = try await temptationService.getRecentTemptations(limit: 10)
            // 过滤今日记录
            let today = getCurrentDateString()
            temptationRecords = todayTemptations.filter { temptation in
                temptation.createdAt.starts(with: today)
            }
            print("✅ 成功加载诱惑记录: \(temptationRecords.count) 条")
        } catch {
            print("❌ 加载诱惑记录失败: \(error.localizedDescription)")
            temptationRecords = []
        }
    }
    
    // MARK: - 今日计划加载
    private func loadTodayPlans() async {
        do {
            // 获取今日计划
            let planList = try await planService.getPlans(page: 1, limit: 20)
            
            // 过滤今日计划（根据startTime或createdAt）
            let today = getCurrentDateString()
            var todayPlans = planList.plans.compactMap { planNew in
                // 从本地存储获取提醒时间
                let reminderTime = PlanReminderManager.shared.getReminderTime(for: planNew.title)
                // 将PlanNew转换为Plan
                return Plan(
                    title: planNew.title,
                    description: planNew.description,
                    category: planNew.category,
                    startDate: planNew.startDate,
                    endDate: planNew.endDate,
                    isActive: planNew.isActive,
                    progress: planNew.progress,
                    reminderTime: reminderTime
                )
            }.filter { plan in
                // 过滤今日计划
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let startDateString = dateFormatter.string(from: plan.startDate)
                return startDateString == today
            }
            
            // 使用状态管理器更新计划状态
            todayPlans = await planStatusManager.updatePlansStatus(todayPlans)
            
            // 为今日计划安排通知
            planStatusManager.scheduleNotificationsForPlans(todayPlans)
            
            // 更新UI
            plans = todayPlans
            
            print("✅ 成功加载今日计划: \(plans.count) 条")
        } catch {
            print("❌ 加载今日计划失败: \(error.localizedDescription)")
            plans = []
        }
    }
    
    // MARK: - 今日打卡状态加载
    private func loadTodayCheckinStatus() async {
        do {
            let todayStatusResponse = try await checkinService.getTodayStatus()
            if todayStatusResponse.success, let statusData = todayStatusResponse.data {
                hasCheckedInToday = true  // 如果有数据说明已经打卡
            } else {
                hasCheckedInToday = false
            }

            // 加载打卡统计
            let statsResponse = try await checkinService.getStatistics()
            if statsResponse.success, let statsData = statsResponse.data {
                consecutiveDays = statsData.currentStreak
                totalCheckinDays = statsData.totalDays
                monthlyCompletionRate = statsData.thisMonthDays
            }
            
            print("✅ 成功加载打卡状态: 已打卡=\(hasCheckedInToday), 连续天数=\(consecutiveDays)")
        } catch {
            print("❌ 加载打卡状态失败: \(error.localizedDescription)")
            hasCheckedInToday = false
            consecutiveDays = 0
            totalCheckinDays = 0
            monthlyCompletionRate = 0
        }
    }
    

    
    // MARK: - 辅助方法
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // MARK: - 打卡功能
    func performCheckin() async -> Bool {
        do {
            let response = try await checkinService.checkin()
            if response.data != nil {
                hasCheckedInToday = true
            }
            
            // 重新加载统计数据
            await loadData()
            return true
        } catch {
            showErrorMessage("打卡失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 数据初始化
    /// 初始化数据状态
    private func initializeData() {
        // 初始化为真实的空状态，等待API加载
        hasCheckedInToday = false
        consecutiveDays = 0
        monthlyCompletionRate = 0
        totalCheckinDays = 0
        
        // 初始化空数组，等待API数据
        plans = []
        emotionRecords = []
        temptationRecords = []
    }
    
    /// 刷新数据
    func refreshData() async {
        // 清空现有数据
        emotionRecords.removeAll()
        temptationRecords.removeAll()
        plans.removeAll()
        
        // 重新加载所有数据
        await loadData()
    }
    
    // MARK: - 错误处理
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - 辅助方法
    var todayRecordsCount: Int {
        return emotionRecords.count + temptationRecords.count
    }
    
    // 更新统计数据
    private func updateStatistics() {
        // 更新其他计算属性
        updateDerivedProperties()
        
        // 更新计划统计
        updatePlanStatistics()
    }
    
    private func updateDerivedProperties() {
        // 更新主要情绪
        if let emotion = emotionRecords.first {
            mainEmotion = emotion.type
        } else {
            mainEmotion = "平静"
        }
        
        // 更新诱惑抵抗率
        if temptationRecords.isEmpty {
            temptationResistanceRate = 0
        } else {
            let resistedCount = temptationRecords.filter { $0.resisted }.count
            temptationResistanceRate = Int((Double(resistedCount) / Double(temptationRecords.count)) * 100)
        }
    }
    
    // MARK: - 计划统计计算属性
    var completedPlans: Int {
        return plans.filter { $0.progress >= 1.0 }.count
    }
    
    var totalPlans: Int {
        return plans.count
    }
    
    private func updatePlanStatistics() {
        let completedCount = max(0, completedPlans)
        let totalCount = max(0, totalPlans)
        
        // 安全计算计划完成率
        if totalCount > 0 && completedCount >= 0 {
            let ratio = Double(completedCount) / Double(totalCount)
            let percentage = ratio * 100
            
            // 确保结果在合理范围内
            if percentage.isFinite {
                planCompletionRate = max(0, min(100, Int(percentage)))
            } else {
                planCompletionRate = 0
            }
        } else {
            planCompletionRate = 0
        }
    }
    
}