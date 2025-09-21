import Foundation
import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

/// 应用限制管理器 - 使用ManagedSettings实现真正的应用限制
@MainActor
class AppRestrictionManager: ObservableObject {
    static let shared = AppRestrictionManager()

    @Published var isAuthorized = false
    @Published var activeRestrictions: [String: AppRestriction] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    // 存储用户选择的应用
    private var selectedApplications: Set<Application> = []

    private let managedSettingsStore = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()
    private let authorizationCenter = AuthorizationCenter.shared

    private init() {
        print("📱 [调试] AppRestrictionManager 初始化开始")
        checkAuthorizationStatus()
        print("📱 [调试] 权限检查完成，isAuthorized: \(isAuthorized)")
        loadRestrictions() // 启动时加载保存的限制状态
        loadSelectedApplications() // 🔥 新增：加载保存的选择应用
        setupNotifications() // 设置应用生命周期通知
        print("📱 [调试] AppRestrictionManager 初始化完成")
    }

    // MARK: - 权限管理

    func checkAuthorizationStatus() {
        isAuthorized = authorizationCenter.authorizationStatus == .approved
    }

    // MARK: - 选择应用/类别并应用限制

    /// 将 FamilyActivityPicker 的选择应用到 ManagedSettings（即时生效）
    func applySelection(appsAndCategories selection: FamilyActivitySelection) async {
        guard isAuthorized else {
            errorMessage = "需要Screen Time权限才能应用选择"
            return
        }

        isLoading = true
        errorMessage = nil

        // 保存选择的应用，用于后续限制
        selectedApplications = selection.applications
        saveSelectedApplications() // 🔥 新增：持久化选择的应用

        // 暂时不直接阻止应用，而是等待自律时间耗尽时再阻止
        // 这样可以让用户在有自律时间的情况下正常使用应用
        print("📱 已保存 FamilyActivity 选择：应用 \(selection.applications.count) 个，类别 \(selection.categories.count) 个")
        print("📱 [调试] selectedApplications 详情:")
        for (index, app) in selectedApplications.enumerated() {
            print("📱 [调试]   选择的应用 \(index + 1): \(app)")
        }
        print("📱 应用将在自律时间耗尽时被限制")

        isLoading = false
    }

    /// 立即锁定指定的应用（用于自律时间耗尽时）
    func lockApplications(_ applications: Set<Application>) async {
        print("📱 [调试] lockApplications() 被调用，应用数量: \(applications.count)")

        guard isAuthorized else {
            errorMessage = "需要Screen Time权限才能锁定应用"
            print("📱 [调试] ❌ 未授权，无法锁定应用")
            return
        }

        isLoading = true
        errorMessage = nil

        // 直接锁定应用（使用 ManagedSettings.application.blockedApplications）
        managedSettingsStore.application.blockedApplications = applications
        print("📱 [调试] ✅ 已设置 ManagedSettings.application.blockedApplications")
        print("📱 [调试] 锁定的应用详情:")
        for (index, app) in applications.enumerated() {
            print("📱 [调试]   应用 \(index + 1): \(app)")
        }

        print("📱 已锁定 \(applications.count) 个应用（自律时间耗尽）")
        isLoading = false
    }

    /// 锁定用户选择的应用
    func lockSelectedApplications() async {
        print("📱 [调试] lockSelectedApplications() 被调用")
        print("📱 [调试] selectedApplications 数量: \(selectedApplications.count)")
        print("📱 [调试] isAuthorized: \(isAuthorized)")

        if selectedApplications.isEmpty {
            print("📱 [调试] ❌ selectedApplications 为空，无法锁定应用")
            return
        }

        await lockApplications(selectedApplications)
    }

    /// 解锁所有应用
    func unlockAllApplications() async {
        guard isAuthorized else {
            errorMessage = "需要Screen Time权限才能解锁应用"
            return
        }

        isLoading = true
        errorMessage = nil

        // 清除所有应用限制
        managedSettingsStore.application.blockedApplications = nil

        print("📱 已解锁所有应用")
        isLoading = false
    }

    // MARK: - 应用限制功能

    /// 设置应用时间限制
    func setTimeLimit(for appName: String, timeLimit: TimeInterval) async {
        guard isAuthorized else {
            errorMessage = "需要Screen Time权限才能设置应用限制"
            return
        }

        do {
            isLoading = true
            errorMessage = nil

            // 创建限制配置
            let restriction = AppRestriction(
                appName: appName,
                timeLimit: timeLimit,
                isActive: true,
                startTime: Date()
            )

            // 设置应用限制
            await setManagedSettings(for: restriction)

            // 保存到本地
            activeRestrictions[appName] = restriction
            saveRestrictions()

            print("📱 已设置应用限制: \(appName), 时间限制: \(Int(timeLimit/60))分钟")

        } catch {
            errorMessage = "设置限制失败: \(error.localizedDescription)"
            print("📱 设置应用限制失败: \(error)")
        }

        isLoading = false
    }

    /// 移除应用限制
    func removeRestriction(for appName: String) async {
        guard isAuthorized else {
            errorMessage = "需要Screen Time权限才能移除应用限制"
            return
        }

        do {
            isLoading = true
            errorMessage = nil

            // 移除ManagedSettings中的限制
            await removeManagedSettings(for: appName)

            // 从本地移除
            activeRestrictions.removeValue(forKey: appName)
            saveRestrictions()

            print("📱 已移除应用限制: \(appName)")

        } catch {
            errorMessage = "移除限制失败: \(error.localizedDescription)"
            print("📱 移除应用限制失败: \(error)")
        }

        isLoading = false
    }

    /// 临时解锁应用
    func temporaryUnlock(for appName: String, duration: TimeInterval) async {
        guard isAuthorized else {
            errorMessage = "需要Screen Time权限才能临时解锁应用"
            return
        }

        do {
            isLoading = true
            errorMessage = nil

            // 临时移除限制
            await removeManagedSettings(for: appName)

            // 设置定时器重新启用限制
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                Task {
                    if let restriction = self.activeRestrictions[appName] {
                        await self.setManagedSettings(for: restriction)
                    }
                }
            }

            print("📱 临时解锁应用: \(appName), 持续: \(Int(duration/60))分钟")

        } catch {
            errorMessage = "临时解锁失败: \(error.localizedDescription)"
            print("📱 临时解锁失败: \(error)")
        }

        isLoading = false
    }

    /// 清除所有限制
    func clearAllRestrictions() async {
        guard isAuthorized else {
            errorMessage = "需要Screen Time权限才能清除所有限制"
            return
        }

        do {
            isLoading = true
            errorMessage = nil

            // 清除所有ManagedSettings
            managedSettingsStore.clearAllSettings()

            // 停止所有设备活动监控
            deviceActivityCenter.stopMonitoring()

            // 清除本地数据
            activeRestrictions.removeAll()
            saveRestrictions()

            print("📱 已清除所有应用限制")

        } catch {
            errorMessage = "清除限制失败: \(error.localizedDescription)"
            print("📱 清除所有限制失败: \(error)")
        }

        isLoading = false
    }


    // MARK: - 一次性系统级拦截日程（由扩展在后台触发）

    /// 在指定时间安排一次性系统级拦截（需要 DeviceActivityMonitor 扩展配合）
    func scheduleOneOffBlocking(at date: Date) async {
        guard isAuthorized else {
            print("📱 [调试] 未授权，无法安排系统级拦截")
            return
        }
        let now = Date()
        if date <= now {
            print("📱 [调试] 目标时间已过，立即执行应用锁定")
            await lockSelectedApplications()
            return
        }
        let calendar = Calendar.current
        let start = calendar.dateComponents([.hour, .minute], from: date)
        // 计划到当天 23:59 结束
        let end = DateComponents(hour: 23, minute: 59)
        let schedule = DeviceActivitySchedule(
            intervalStart: start,
            intervalEnd: end,
            repeats: false
        )
        let activityName = DeviceActivityName("selfdiscipline_block_once")
        do {
            // 先停止已存在的同名监控，避免重复
            deviceActivityCenter.stopMonitoring([activityName])
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
            print("📱 已安排一次性系统级拦截：于 \(date) 触发（本地时区）")
        } catch {
            print("📱 安排系统级拦截失败: \(error)")
        }
    }

    /// 取消一次性系统级拦截
    func cancelScheduledBlocking() {
        let activityName = DeviceActivityName("selfdiscipline_block_once")
        deviceActivityCenter.stopMonitoring([activityName])
        print("📱 已取消一次性系统级拦截")


    }

    // MARK: - ManagedSettings操作

    private func setManagedSettings(for restriction: AppRestriction) async {
        // 注意：由于无法直接通过应用名称获取ApplicationToken，
        // 需要通过FamilyActivityPicker获取ApplicationToken来实现真实的应用限制

        // 设置时间限制（通过DeviceActivity实现）
        let activityName = DeviceActivityName("restriction_\(restriction.appName)")
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
        } catch {
            print("📱 启动监控失败: \(error)")
        }
    }

    private func removeManagedSettings(for appName: String) async {
        // 移除特定应用的限制
        let activityName = DeviceActivityName("restriction_\(appName)")

        deviceActivityCenter.stopMonitoring([activityName])
    }

    // MARK: - 数据持久化

    private func saveRestrictions() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(Array(activeRestrictions.values)) {
            UserDefaults.standard.set(data, forKey: "active_app_restrictions")
        }
    }

    private func loadRestrictions() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "active_app_restrictions"),
           let restrictions = try? decoder.decode([AppRestriction].self, from: data) {
            activeRestrictions = Dictionary(uniqueKeysWithValues: restrictions.map { ($0.appName, $0) })
        }
    }

    // MARK: - 选择应用持久化

    /// 保存选择的应用
    private func saveSelectedApplications() {
        let encoder = PropertyListEncoder()
        var savedApps: [[String: Data]] = []

        for application in selectedApplications {
            if let tokenData = try? encoder.encode(application.token) {
                savedApps.append(["token": tokenData])
            }
        }

        // 本地存储
        UserDefaults.standard.set(savedApps, forKey: "selected_applications_for_restriction")
        // App Group 共享存储（供扩展读取）
        if let suite = UserDefaults(suiteName: AppConstants.AppGroup.identifier) {
            suite.set(savedApps, forKey: AppConstants.AppGroup.selectedApplicationsKey)
            suite.synchronize()
            print("📱 已同步选择的应用到 App Group: \(AppConstants.AppGroup.identifier)")
        } else {
            print("⚠️ 未能初始化 App Group UserDefaults: \(AppConstants.AppGroup.identifier)")
        }
        print("📱 已保存 \(selectedApplications.count) 个选择的应用到本地存储")
    }

    /// 加载选择的应用
    private func loadSelectedApplications() {
        print("📱 [调试] loadSelectedApplications() 被调用")

        guard let savedApps = UserDefaults.standard.array(forKey: "selected_applications_for_restriction") as? [[String: Data]] else {
            print("📱 [调试] 没有找到保存的选择应用")
            return
        }

        print("📱 [调试] 找到 \(savedApps.count) 个保存的应用数据")

        let decoder = PropertyListDecoder()
        var applications: Set<Application> = []

        for (index, appData) in savedApps.enumerated() {
            if let tokenData = appData["token"],
               let token = try? decoder.decode(ApplicationToken.self, from: tokenData) {
                let application = Application(token: token)
                applications.insert(application)
                print("📱 [调试] 成功加载应用 \(index + 1): \(application)")
            } else {
                print("📱 [调试] ❌ 无法解码应用 \(index + 1)")
            }
        }

        selectedApplications = applications
        print("📱 [调试] ✅ 已加载 \(selectedApplications.count) 个选择的应用")
    }

    // MARK: - 辅助方法

    /// 检查应用是否被限制
    func isAppRestricted(_ appName: String) -> Bool {
        return activeRestrictions[appName]?.isActive ?? false
    }

    /// 获取应用剩余时间
    func getRemainingTime(for appName: String) -> TimeInterval {
        guard let restriction = activeRestrictions[appName],
              restriction.isActive else {
            return 0
        }

        let elapsed = Date().timeIntervalSince(restriction.startTime)
        return max(0, restriction.timeLimit - elapsed)
    }

    /// 格式化时间显示
    func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }

    // MARK: - 应用生命周期通知

    private func setupNotifications() {
        // 监听应用进入后台
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.saveRestrictions()
                self?.saveSelectedApplications() // 🔥 新增：保存选择的应用
                print("📱 AppRestrictionManager: 应用进入后台，保存限制状态和选择应用")
            }
        }

        // 监听应用进入前台
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadRestrictions()
                self?.loadSelectedApplications() // 🔥 新增：加载选择的应用
                print("📱 AppRestrictionManager: 应用进入前台，加载限制状态和选择应用")
            }
        }
    }
}

// MARK: - 数据模型

struct AppRestriction: Codable, Identifiable {
    var id = UUID()
    let appName: String
    let timeLimit: TimeInterval
    let isActive: Bool
    let startTime: Date

    var remainingTime: TimeInterval {
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, timeLimit - elapsed)
    }

    var isExpired: Bool {
        return remainingTime <= 0
    }
}
