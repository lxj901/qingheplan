import Foundation
import UserNotifications
import Combine

/// 计划状态管理器
/// 负责计划状态的自动更新和系统通知的调度
@MainActor
class PlanStatusManager: ObservableObject {
    static let shared = PlanStatusManager()
    
    private let planService = PlanService.shared
    private var timer: Timer?
    private var statusUpdatePublisher: AnyCancellable?
    
    // MARK: - 计划状态枚举
    enum PlanStatus: String, CaseIterable {
        case pending = "pending"           // 待开始
        case inProgress = "in_progress"    // 进行中  
        case completed = "completed"       // 已完成
        case expired = "expired"           // 已过期
        case cancelled = "cancelled"       // 已取消
        
        var displayName: String {
            switch self {
            case .pending: return "待开始"
            case .inProgress: return "进行中"
            case .completed: return "已完成"
            case .expired: return "已过期"
            case .cancelled: return "已取消"
            }
        }
    }
    
    private init() {
        // 不在初始化时请求通知权限，避免与 ATT 冲突；将在登录后或实际需要时再请求
        // startStatusMonitoring() 也仅在需要时启动
    }

    /// 启动状态监控（公开方法，供外部调用）
    func startMonitoring() {
        guard timer == nil else {
            print("⚠️ 计划状态监控已在运行中")
            return
        }
        startStatusMonitoring()
    }
    
    // MARK: - 状态更新逻辑
    
    /// 计算计划的当前状态
    /// - Parameter plan: 计划对象
    /// - Returns: 计算后的状态
    func calculatePlanStatus(for plan: Plan) -> PlanStatus {
        let now = Date()
        
        // 如果计划已完成，返回完成状态
        if plan.progress >= 1.0 {
            return .completed
        }

        // 如果计划不活跃，返回取消状态
        if !plan.isActive {
            return .cancelled
        }

        // 解析提醒时间
        guard let reminderTime = plan.reminderTime else {
            return .pending
        }

        // 使用计划的结束时间作为预估结束时间
        let estimatedEndTime = plan.endDate

        // 根据时间判断状态
        if now < reminderTime {
            return .pending
        } else if now >= reminderTime && now < estimatedEndTime {
            return .inProgress
        } else {
            // 时间到了应该显示已完成，而不是已过期
            return .completed
        }
    }
    
    /// 更新单个计划的状态
    /// - Parameter plan: 需要更新的计划
    /// - Returns: 更新后的计划，如果无需更新则返回nil
    func updatePlanStatus(_ plan: Plan) async -> Plan? {
        let newStatus = calculatePlanStatus(for: plan)

        // 根据新状态判断是否需要更新
        let currentStatus: PlanStatus
        if plan.progress >= 1.0 {
            currentStatus = .completed
        } else if !plan.isActive {
            currentStatus = .cancelled
        } else {
            currentStatus = .inProgress
        }

        // 如果状态未发生变化，无需更新
        if currentStatus == newStatus {
            return nil
        }

        print("🔄 计划状态变化: ID=\(plan.id), \(currentStatus.rawValue) -> \(newStatus.rawValue)")

        // 创建更新后的计划对象
        var updatedPlan = plan
        // 根据新状态更新计划属性
        switch newStatus {
        case .completed:
            updatedPlan = Plan(
                title: plan.title,
                description: plan.description,
                category: plan.category,
                startDate: plan.startDate,
                endDate: plan.endDate,
                isActive: plan.isActive,
                progress: 1.0,
                reminderTime: plan.reminderTime
            )
        case .cancelled:
            updatedPlan = Plan(
                title: plan.title,
                description: plan.description,
                category: plan.category,
                startDate: plan.startDate,
                endDate: plan.endDate,
                isActive: false,
                progress: plan.progress,
                reminderTime: plan.reminderTime
            )
        default:
            updatedPlan = plan
        }

        // 只有在状态确实需要同步到服务器时才调用API
        // 避免频繁的API调用
        let shouldSyncToServer = shouldSyncStatusToServer(oldStatus: currentStatus.rawValue, newStatus: newStatus.rawValue)

        if shouldSyncToServer {
            do {
                // 由于Plan模型使用UUID，我们暂时跳过服务器同步
                print("✅ 计划状态已更新: ID=\(plan.id), 新状态=\(newStatus.displayName)")
                return updatedPlan
            } catch {
                print("❌ 同步计划状态失败: ID=\(plan.id), 错误=\(error.localizedDescription)")
                // 即使同步失败，也返回本地更新的计划
            }
        } else {
            print("ℹ️ 计划状态仅本地更新: ID=\(plan.id), 状态=\(newStatus.displayName)")
        }

        return updatedPlan
    }

    /// 判断是否需要将状态同步到服务器
    private func shouldSyncStatusToServer(oldStatus: String, newStatus: String) -> Bool {
        // 只有在关键状态变化时才同步到服务器
        let criticalStatusChanges = [
            "pending -> in_progress",
            "in_progress -> completed",
            "pending -> cancelled",
            "in_progress -> cancelled"
        ]

        let statusChange = "\(oldStatus) -> \(newStatus)"
        return criticalStatusChanges.contains(statusChange)
    }
    
    /// 批量更新计划状态
    /// - Parameter plans: 需要更新的计划列表
    /// - Returns: 更新后的计划列表
    func updatePlansStatus(_ plans: [Plan]) async -> [Plan] {
        var updatedPlans: [Plan] = []
        
        for plan in plans {
            if let updated = await updatePlanStatus(plan) {
                updatedPlans.append(updated)
            } else {
                updatedPlans.append(plan)
            }
        }
        
        return updatedPlans
    }
    
    // MARK: - 通知功能
    
    /// 请求通知权限
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()

        // 先检查当前权限状态
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    print("✅ 通知权限已授权")
                case .denied:
                    print("❌ 通知权限被拒绝")
                case .notDetermined:
                    // 请求权限
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        DispatchQueue.main.async {
                            if granted {
                                print("✅ 通知权限已获取")
                            } else {
                                print("❌ 通知权限被拒绝: \(error?.localizedDescription ?? "未知错误")")
                            }
                        }
                    }
                case .provisional:
                    print("⚠️ 通知权限为临时授权")
                case .ephemeral:
                    print("⚠️ 通知权限为临时授权（App Clips）")
                @unknown default:
                    print("⚠️ 未知的通知权限状态")
                }
            }
        }
    }
    
    /// 为计划安排通知
    /// - Parameter plan: 需要安排通知的计划
    func scheduleNotificationForPlan(_ plan: Plan) {
        guard let reminderTime = plan.reminderTime else {
            print("❌ 计划没有设置提醒时间: \(plan.title)")
            return
        }

        // 只为未来的计划安排通知
        guard reminderTime > Date() else {
            print("⚠️ 计划提醒时间已过期，跳过通知安排: \(plan.title)")
            return
        }

        // 检查通知权限
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("❌ 通知权限未授权，无法安排通知: \(plan.title)")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "计划提醒"
            content.body = "该开始执行计划：\(plan.title)"
            content.sound = .default
            content.userInfo = [
                "planId": plan.id.uuidString,
                "planTitle": plan.title,
                "type": "plan_reminder"
            ]

            // 创建触发器
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)

            // 验证触发器日期组件
            guard triggerDate.year != nil, triggerDate.month != nil, triggerDate.day != nil,
                  triggerDate.hour != nil, triggerDate.minute != nil else {
                print("❌ 无效的提醒时间组件: \(plan.title)")
                return
            }

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

            // 创建请求
            let identifier = "plan_reminder_\(plan.id.uuidString)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            // 安排通知
            center.add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ 安排计划通知失败: \(plan.title) - \(error.localizedDescription)")
                    } else {
                        print("✅ 已安排计划通知: \(plan.title) at \(reminderTime)")
                    }
                }
            }
        }
    }
    
    /// 取消计划通知
    /// - Parameter planId: 计划ID
    func cancelNotificationForPlan(_ planId: String) {
        let identifier = "plan_reminder_\(planId)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ 已取消计划通知: ID=\(planId)")
    }
    
    /// 为计划列表批量安排通知
    /// - Parameter plans: 计划列表
    func scheduleNotificationsForPlans(_ plans: [Plan]) {
        for plan in plans {
            scheduleNotificationForPlan(plan)
        }
    }
    
    // MARK: - 状态监控
    
    /// 开始状态监控
    private func startStatusMonitoring() {
        // 每5分钟检查一次状态，减少API请求频率
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAndUpdateAllPlanStatuses()
            }
        }

        print("✅ 计划状态监控已启动 (每5分钟检查一次)")
    }
    
    /// 停止状态监控
    func stopStatusMonitoring() {
        timer?.invalidate()
        timer = nil
        print("🛑 计划状态监控已停止")
    }
    
    /// 检查并更新所有计划状态
    private func checkAndUpdateAllPlanStatuses() async {
        do {
            print("🔄 开始检查计划状态...")

            // 获取当前所有计划
            let planList = try await planService.getPlans(page: 1, limit: 100)
            let plans = planList.plans.map { planNew in
                // 从本地存储获取提醒时间
                let reminderTime = PlanReminderManager.shared.getReminderTime(for: planNew.title)
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
            }

            print("📋 获取到 \(plans.count) 个计划，开始状态检查")

            // 只检查今天和未来的计划，过滤掉过期的计划
            let relevantPlans = plans.filter { plan in
                // 只处理今天及未来的计划
                let today = Calendar.current.startOfDay(for: Date())
                let planDay = Calendar.current.startOfDay(for: plan.startDate)
                return planDay >= today
            }

            print("📅 筛选出 \(relevantPlans.count) 个相关计划需要检查")

            // 更新状态
            let updatedPlans = await updatePlansStatus(relevantPlans)

            // 只有当有计划状态发生变化时才发送通知
            if !updatedPlans.isEmpty {
                print("✅ 有 \(updatedPlans.count) 个计划状态发生变化")
                NotificationCenter.default.post(name: .planStatusDidUpdate, object: updatedPlans)
            } else {
                print("ℹ️ 没有计划状态发生变化")
            }

        } catch {
            print("❌ 检查计划状态失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 辅助方法
    
    /// 解析日期时间字符串
    /// - Parameter dateTimeString: 日期时间字符串
    /// - Returns: Date对象，解析失败返回nil
    private func parseDateTime(_ dateTimeString: String) -> Date? {
        let formatters: [DateFormatter] = [
            // ISO8601格式
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }(),
            // 简化ISO8601格式
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }(),
            // 日期+时间格式
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return formatter
            }(),
            // 仅日期格式（默认时间为00:00:00）
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateTimeString) {
                return date
            }
        }
        
        return nil
    }
    

}

// MARK: - 通知名称扩展
extension Notification.Name {
    static let planStatusDidUpdate = Notification.Name("planStatusDidUpdate")
    static let planNotificationScheduled = Notification.Name("planNotificationScheduled")
}

// MARK: - 时间格式化辅助函数
extension PlanStatusManager {
    
    /// 格式化时间差显示
    /// - Parameters:
    ///   - from: 开始时间
    ///   - to: 结束时间
    /// - Returns: 格式化的时间差字符串
    func formatTimeDifference(from: Date, to: Date) -> String {
        let timeInterval = to.timeIntervalSince(from)
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    /// 获取计划剩余时间描述
    /// - Parameter plan: 计划对象
    /// - Returns: 剩余时间描述
    func getRemainingTimeDescription(for plan: Plan) -> String {
        guard let reminderTime = plan.reminderTime else {
            return "时间未设置"
        }
        
        let now = Date()
        let currentStatus = calculatePlanStatus(for: plan)
        
        switch currentStatus {
        case .pending:
            let timeUntilStart = reminderTime.timeIntervalSince(now)
            if timeUntilStart > 3600 {
                let hours = Int(timeUntilStart) / 3600
                return "还有\(hours)小时开始"
            } else {
                let minutes = Int(timeUntilStart) / 60
                return "还有\(minutes)分钟开始"
            }
            
        case .inProgress:
            // 由于Plan模型中没有estimatedTime属性，直接返回进行中
            return "进行中"
            
        case .completed:
            return "已完成"
            
        case .expired:
            return "已过期"
            
        case .cancelled:
            return "已取消"
        }
    }
}