import Foundation
import UserNotifications

/// 计划提醒管理器 - 负责管理计划的提醒时间和本地通知
class PlanReminderManager {
    static let shared = PlanReminderManager()
    
    private let userDefaults = UserDefaults.standard
    private let reminderKey = "plan_reminders"
    
    private init() {}
    
    // MARK: - 提醒时间存储结构
    
    private struct PlanReminder: Codable {
        let planTitle: String
        let reminderTime: Date
        let createdAt: Date
    }
    
    // MARK: - 公共方法
    
    /// 保存计划的提醒时间
    /// - Parameters:
    ///   - planTitle: 计划标题
    ///   - reminderTime: 提醒时间
    func saveReminderTime(for planTitle: String, reminderTime: Date) {
        var reminders = loadReminders()
        
        // 移除同名计划的旧提醒
        reminders.removeAll { $0.planTitle == planTitle }
        
        // 添加新提醒
        let newReminder = PlanReminder(
            planTitle: planTitle,
            reminderTime: reminderTime,
            createdAt: Date()
        )
        reminders.append(newReminder)
        
        // 保存到 UserDefaults
        saveReminders(reminders)
        
        // 安排本地通知
        scheduleNotification(for: newReminder)
        
        print("✅ 已保存计划提醒: \(planTitle) at \(reminderTime)")
    }
    
    /// 获取计划的提醒时间
    /// - Parameter planTitle: 计划标题
    /// - Returns: 提醒时间，如果没有设置则返回 nil
    func getReminderTime(for planTitle: String) -> Date? {
        let reminders = loadReminders()
        return reminders.first { $0.planTitle == planTitle }?.reminderTime
    }
    
    /// 删除计划的提醒时间
    /// - Parameter planTitle: 计划标题
    func removeReminderTime(for planTitle: String) {
        var reminders = loadReminders()
        reminders.removeAll { $0.planTitle == planTitle }
        saveReminders(reminders)
        
        // 取消本地通知
        cancelNotification(for: planTitle)
        
        print("✅ 已删除计划提醒: \(planTitle)")
    }
    
    /// 清理过期的提醒（超过30天的）
    func cleanupExpiredReminders() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        var reminders = loadReminders()
        
        let originalCount = reminders.count
        reminders.removeAll { $0.createdAt < thirtyDaysAgo }
        
        if reminders.count < originalCount {
            saveReminders(reminders)
            print("✅ 已清理 \(originalCount - reminders.count) 个过期提醒")
        }
    }
    
    // MARK: - 私有方法
    
    private func loadReminders() -> [PlanReminder] {
        guard let data = userDefaults.data(forKey: reminderKey),
              let reminders = try? JSONDecoder().decode([PlanReminder].self, from: data) else {
            return []
        }
        return reminders
    }
    
    private func saveReminders(_ reminders: [PlanReminder]) {
        if let data = try? JSONEncoder().encode(reminders) {
            userDefaults.set(data, forKey: reminderKey)
        }
    }
    
    private func scheduleNotification(for reminder: PlanReminder) {
        // 只为未来的时间安排通知
        guard reminder.reminderTime > Date() else {
            print("⚠️ 计划提醒时间已过期，跳过通知安排: \(reminder.planTitle)")
            return
        }

        // 检查通知权限
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("❌ 通知权限未授权，无法安排通知: \(reminder.planTitle)")
                // 如果权限未授权，尝试请求权限
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        print("✅ 通知权限已获取，重新安排通知: \(reminder.planTitle)")
                        // 递归调用，重新安排通知
                        self.scheduleNotification(for: reminder)
                    } else {
                        print("❌ 通知权限被拒绝: \(error?.localizedDescription ?? "未知错误")")
                    }
                }
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "计划提醒"
            content.body = "该开始执行计划：\(reminder.planTitle)"
            content.sound = .default
            content.userInfo = [
                "planTitle": reminder.planTitle,
                "type": "plan_reminder"
            ]

            // 创建触发器
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.reminderTime)

            // 验证触发器日期组件
            guard triggerDate.year != nil, triggerDate.month != nil, triggerDate.day != nil,
                  triggerDate.hour != nil, triggerDate.minute != nil else {
                print("❌ 无效的提醒时间组件: \(reminder.planTitle)")
                return
            }

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

            // 创建请求
            let identifier = "plan_reminder_\(reminder.planTitle)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            // 安排通知
            center.add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ 安排计划通知失败: \(reminder.planTitle) - \(error.localizedDescription)")
                    } else {
                        print("✅ 已安排计划通知: \(reminder.planTitle) at \(reminder.reminderTime)")
                    }
                }
            }
        }
    }
    
    private func cancelNotification(for planTitle: String) {
        let identifier = "plan_reminder_\(planTitle)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("✅ 已取消计划通知: \(planTitle)")
    }
}
