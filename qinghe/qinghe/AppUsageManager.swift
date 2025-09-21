import Foundation
import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings
import Combine

// MARK: - 应用管理数据模型

/// 应用解锁规则
struct AppUnlockRule: Codable, Identifiable {
    let id = UUID()
    let appName: String
    let unlockRatio: Double // 已废弃：解锁比例，保留用于兼容旧数据
    let maxDailyTime: TimeInterval // 每日最大使用时间（秒）
    let isEnabled: Bool
    // 旧：尝试存储应用 token（二进制），现已不再使用
    let applicationTokenData: Data?
    // 新：直接存储可展示信息，避免对非 NSCoding 类型做归档
    let bundleIdentifier: String?
    let displayName: String?
    // iOS 18 新增：存储 ApplicationToken 用于显示真实应用名称和图标
    let applicationToken: Data?
    // 已废弃：基础时间，保留用于兼容旧数据
    let baseTimeMinutes: Int

    // 已废弃：为了兼容旧数据保留
    var baseTime: TimeInterval {
        return TimeInterval(baseTimeMinutes * 60)
    }

    init(
        appName: String,
        unlockRatio: Double = 0.5,
        maxDailyTime: TimeInterval = 3600,
        isEnabled: Bool = true,
        applicationTokenData: Data? = nil,
        bundleIdentifier: String? = nil,
        displayName: String? = nil,
        applicationToken: Data? = nil,
        baseTimeMinutes: Int = 10
    ) {
        self.appName = appName
        self.unlockRatio = max(0.0, min(1.0, unlockRatio))
        self.maxDailyTime = maxDailyTime
        self.isEnabled = isEnabled
        self.applicationTokenData = applicationTokenData
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.applicationToken = applicationToken
        self.baseTimeMinutes = max(10, min(60, baseTimeMinutes)) // 限制在10-60分钟范围内
    }

    // 为了兼容旧数据，添加自定义解码器
    enum CodingKeys: String, CodingKey {
        case appName, unlockRatio, maxDailyTime, isEnabled
        case applicationTokenData, bundleIdentifier, displayName, applicationToken
        case baseTimeMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        appName = try container.decode(String.self, forKey: .appName)
        unlockRatio = try container.decode(Double.self, forKey: .unlockRatio)
        maxDailyTime = try container.decode(TimeInterval.self, forKey: .maxDailyTime)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        applicationTokenData = try container.decodeIfPresent(Data.self, forKey: .applicationTokenData)
        bundleIdentifier = try container.decodeIfPresent(String.self, forKey: .bundleIdentifier)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        applicationToken = try container.decodeIfPresent(Data.self, forKey: .applicationToken)

        // 兼容旧数据：如果没有 baseTimeMinutes 字段，使用默认值10分钟
        baseTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .baseTimeMinutes) ?? 10
    }
}

/// 自律时间记录
struct SelfDisciplineRecord: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let activityType: SelfDisciplineActivity
    let duration: TimeInterval // 持续时间（秒）
    let quality: Double // 质量评分 (0.0-1.0)

    init(date: Date = Date(), activityType: SelfDisciplineActivity, duration: TimeInterval, quality: Double = 1.0) {
        self.date = date
        self.activityType = activityType
        self.duration = duration
        self.quality = max(0.0, min(1.0, quality))
    }
}

/// 自律活动类型
enum SelfDisciplineActivity: String, CaseIterable, Codable {
    case sleep = "sleep"
    case exercise = "exercise"
    case study = "study"
    case meditation = "meditation"
    case reading = "reading"
    case work = "work"

    var displayName: String {
        switch self {
        case .sleep: return "睡眠"
        case .exercise: return "运动"
        case .study: return "学习"
        case .meditation: return "冥想"
        case .reading: return "阅读"
        case .work: return "工作"
        }
    }

    var icon: String {
        switch self {
        case .sleep: return "moon.zzz.fill"
        case .exercise: return "figure.run"
        case .study: return "book.fill"
        case .meditation: return "leaf.fill"
        case .reading: return "text.book.closed.fill"
        case .work: return "briefcase.fill"
        }
    }

    var color: Color {
        switch self {
        case .sleep: return .purple
        case .exercise: return .orange
        case .study: return .blue
        case .meditation: return .green
        case .reading: return .brown
        case .work: return .gray
        }
    }
}

/// 应用解锁状态
struct AppUnlockStatus: Identifiable {
    let id = UUID()
    let appName: String
    let isUnlocked: Bool
    let remainingTime: TimeInterval // 剩余可用时间（秒）
    let totalUnlockedTime: TimeInterval // 今日总解锁时间
    let usedTime: TimeInterval // 今日已使用时间
    // 新增：直接携带真实识别信息，避免通过名称再次查找导致错配
    let applicationToken: Data?
    let bundleIdentifier: String?
    let displayName: String?

    var usageProgress: Double {
        guard totalUnlockedTime > 0 else { return 0 }
        return min(1.0, usedTime / totalUnlockedTime)
    }

    var isTimeUp: Bool {
        return remainingTime <= 0
    }
}

/// 每日自律时间统计
struct DailySelfDisciplineStats: Codable {
    let date: Date
    let totalTime: TimeInterval // 总自律时间
    let activityBreakdown: [SelfDisciplineActivity: TimeInterval] // 各活动时间分解
    let qualityScore: Double // 平均质量评分

    var formattedTotalTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

/// 应用使用管理器
@MainActor
class AppUsageManager: ObservableObject {
    static let shared = AppUsageManager()

    // 使用新的ScreenTimeManager和AppRestrictionManager
    private let screenTimeManager = ScreenTimeManager.shared
    private let appRestrictionManager = AppRestrictionManager.shared

    // 自律时间倒计时管理器
    private let countdownManager = SelfDisciplineCountdownManager.shared

    @Published var isAuthorized = false
    @Published var appUsageData: [AppUsageData] = []
    @Published var totalScreenTime: TimeInterval = 0

    // 新增：应用管理相关属性
    @Published var appUnlockRules: [AppUnlockRule] = []
    @Published var selfDisciplineRecords: [SelfDisciplineRecord] = []
    @Published var appUnlockStatuses: [AppUnlockStatus] = []
    @Published var todayStats: DailySelfDisciplineStats?
    @Published var savedApplications: [[String: Any]] = []



    private let userDefaults = UserDefaults.standard
    private let unlockRulesKey = "app_unlock_rules"
    private let disciplineRecordsKey = "self_discipline_records"

    // 缓存 Label 视图，减少重复创建
    private var labelCache: [String: AnyView] = [:]

    private init() {
        loadSavedData()
        setupInitialData()
        calculateTodayStats()
        updateAppUnlockStatuses()

        // 监听ScreenTimeManager的数据变化
        setupScreenTimeObserver()

        // 设置倒计时管理器回调
        setupCountdownManagerCallbacks()

        // 启动应用使用监控
        startMonitoringAppUsage()
    }

    /// 请求权限
    func requestAuthorization() {
        Task {
            await screenTimeManager.requestAuthorization()
            await MainActor.run {
                isAuthorized = screenTimeManager.isAuthorized
                if isAuthorized {
                    syncWithScreenTimeData()
                }
            }
        }
    }

    private func setupInitialData() {
        // 检查Screen Time授权状态
        isAuthorized = screenTimeManager.isAuthorized

        // 如果已授权，同步数据；否则使用默认数据
        if isAuthorized {
            syncWithScreenTimeData()
        } else {
            setupDefaultData()
        }

        // 如果没有保存的解锁规则，创建默认规则
        if appUnlockRules.isEmpty {
            setupDefaultUnlockRules()
        }
    }

    private func setupDefaultData() {
        // 不再使用模拟数据，只有在获得Screen Time权限后才显示真实数据
        appUsageData = []
        totalScreenTime = 0
        print("📱 应用管理器：等待Screen Time权限授权以获取真实数据")
    }

    private func syncWithScreenTimeData() {
        appUsageData = screenTimeManager.appUsageData
        totalScreenTime = screenTimeManager.totalScreenTime
        print("📱 应用管理器：已同步Screen Time数据")
    }

    private func setupScreenTimeObserver() {
        // 监听ScreenTimeManager的授权状态变化
        Task {
            for await _ in screenTimeManager.$isAuthorized.values {
                await MainActor.run {
                    self.isAuthorized = screenTimeManager.isAuthorized
                    if self.isAuthorized {
                        self.syncWithScreenTimeData()
                        self.updateAppUnlockStatuses()
                    }
                }
            }
        }

        // 监听ScreenTimeManager的数据变化
        Task {
            for await _ in screenTimeManager.$appUsageData.values {
                await MainActor.run {
                    if self.isAuthorized {
                        self.syncWithScreenTimeData()
                        self.updateAppUnlockStatuses()
                    }
                }
            }
        }
    }

    // MARK: - 数据持久化

    private func loadSavedData() {
        loadUnlockRules()
        loadSelfDisciplineRecords()
        loadSavedApplications()
    }

    private func loadSavedApplications() {
        savedApplications = UserDefaults.standard.array(forKey: "selected_applications") as? [[String: Any]] ?? []
        print("📱 加载了 \(savedApplications.count) 个保存的应用信息")
    }

    private func loadUnlockRules() {
        if let data = userDefaults.data(forKey: unlockRulesKey),
           let rules = try? JSONDecoder().decode([AppUnlockRule].self, from: data) {
            // 过滤掉模拟数据应用和旧的测试规则
            let mockAppNames = ["微信", "抖音", "QQ音乐", "Safari", "支付宝", "美团"]
            let filteredRules = rules.filter { rule in
                // 过滤掉模拟应用
                if mockAppNames.contains(rule.appName) {
                    return false
                }
                // 过滤掉旧的"选择的应用"规则（如果没有有效的 applicationToken）
                if rule.appName.hasPrefix("选择的应用") && (rule.applicationToken?.isEmpty ?? true) {
                    return false
                }
                return true
            }
            appUnlockRules = filteredRules

            if rules.count != filteredRules.count {
                print("📱 已过滤掉 \(rules.count - filteredRules.count) 个无效应用规则")
                // 保存过滤后的规则
                saveUnlockRules()
            }
        }
    }

    private func saveUnlockRules() {
        if let data = try? JSONEncoder().encode(appUnlockRules) {
            userDefaults.set(data, forKey: unlockRulesKey)
        }
    }

    private func loadSelfDisciplineRecords() {
        if let data = userDefaults.data(forKey: disciplineRecordsKey),
           let records = try? JSONDecoder().decode([SelfDisciplineRecord].self, from: data) {
            selfDisciplineRecords = records
        }
    }

    private func saveSelfDisciplineRecords() {
        if let data = try? JSONEncoder().encode(selfDisciplineRecords) {
            userDefaults.set(data, forKey: disciplineRecordsKey)
        }
    }

    private func setupDefaultUnlockRules() {
        // 清除所有保存的模拟数据
        clearAllSavedData()

        // 不再创建默认解锁规则，用户需要手动添加
        appUnlockRules = []
        print("📱 应用管理器：已清除模拟数据，等待用户手动配置应用解锁规则")
    }

    /// 清除所有保存的模拟数据
    private func clearAllSavedData() {
        userDefaults.removeObject(forKey: unlockRulesKey)
        userDefaults.removeObject(forKey: disciplineRecordsKey)
        userDefaults.removeObject(forKey: "AppUsageManager_TodayUsedTime")
        userDefaults.synchronize()
        print("📱 已清除所有保存的应用管理模拟数据")
    }

    // MARK: - 自律时间管理

    // MARK: - 自律时间获取

    /// 当前自律时间（分钟）- 由外部设置
    @Published var currentSelfDisciplineMinutes: Int = 0

    /// 自律时间来源分解
    @Published var planCompletionTime: Int = 0
    @Published var sleepTime: Int = 0
    @Published var exerciseTime: Int = 0

    /// 设置今日自律时间（供外部调用）
    /// 注意：这里与倒计时同步时，使用“原始预算”对比，而不是按“剩余时间”回补，避免反复重置为初始值。
    func updateSelfDisciplineTime(_ minutes: Int) {
        let newTotal = max(0, minutes)
        // 以倒计时的初始总时长作为“上次预算”，如果还未开始倒计时，则使用当前记录值
        let previousBudget = countdownManager.initialTimeInSeconds > 0
            ? (countdownManager.initialTimeInSeconds / 60)
            : currentSelfDisciplineMinutes

        // 如果今天已经耗尽，则保持为0，且不再重启倒计时
        if countdownManager.hasExhaustedForToday() {
            currentSelfDisciplineMinutes = 0
            updateAppUnlockStatuses()
            print("📱 应用管理器：今日已耗尽，忽略自律时间更新（请求 \(newTotal) 分钟）")
            return
        }

        currentSelfDisciplineMinutes = newTotal
        updateAppUnlockStatuses()

        // 如果有选择的应用且自律时间大于0，开始或更新倒计时
        if newTotal > 0 && !getSelectedApplications().isEmpty {
            if countdownManager.isCountingDown {
                // 只在“新预算”增加时追加时间，避免因前后台刷新导致的回补
                let delta = newTotal - previousBudget
                if delta > 0 {
                    countdownManager.addTime(additionalMinutes: delta)
                }
            } else {
                // 尚未倒计时则以“新预算”开启
                countdownManager.startCountdown(totalMinutes: newTotal)
            }
        }

        print("📱 应用管理器：自律时间更新为 \(newTotal) 分钟（上次预算: \(previousBudget) 分钟）")
    }

    /// 更新综合自律时间（包含计划、睡眠、运动）
    func updateComprehensiveSelfDisciplineTime(planTime: Int, sleepTime: Int, exerciseTime: Int) {
        self.planCompletionTime = planTime
        self.sleepTime = sleepTime
        self.exerciseTime = exerciseTime

        // 计算总自律时间并统一走 updateSelfDisciplineTime，避免重复回补
        let totalTime = max(0, planTime + sleepTime + exerciseTime)
        updateSelfDisciplineTime(totalTime)

        print("📱 应用管理器：综合自律时间更新 - 计划:\(planTime)分钟, 睡眠:\(sleepTime)分钟, 运动:\(exerciseTime)分钟, 总计:\(totalTime)分钟")
    }

    /// 获取今日自律时间（分钟）
    func getTodaySelfDisciplineTime() -> Int {
        // 若今日已耗尽，那么对外暴露 0（用于 UI 和共享时间池计算）
        if countdownManager.hasExhaustedForToday() {
            return 0
        }
        return currentSelfDisciplineMinutes
    }

    /// 获取自律时间来源分解
    func getSelfDisciplineBreakdown() -> (planTime: Int, sleepTime: Int, exerciseTime: Int, totalTime: Int) {
        return (planCompletionTime, sleepTime, exerciseTime, currentSelfDisciplineMinutes)
    }

    /// 计算今日统计
    private func calculateTodayStats() {
        let today = Calendar.current.startOfDay(for: Date())
        let todayRecords = selfDisciplineRecords.filter {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }

        let totalTime = TimeInterval(getTodaySelfDisciplineTime() * 60) // 转换为秒
        var activityBreakdown: [SelfDisciplineActivity: TimeInterval] = [:]
        var totalQuality = 0.0

        for record in todayRecords {
            activityBreakdown[record.activityType, default: 0] += record.duration
            totalQuality += record.quality
        }

        let averageQuality = todayRecords.isEmpty ? 1.0 : totalQuality / Double(todayRecords.count)

        todayStats = DailySelfDisciplineStats(
            date: today,
            totalTime: totalTime,
            activityBreakdown: activityBreakdown,
            qualityScore: averageQuality
        )
    }

    /// 更新应用解锁状态
    private func updateAppUnlockStatuses() {
        let todaySelfDisciplineMinutes = getTodaySelfDisciplineTime()
        let todaySelfDisciplineSeconds = TimeInterval(todaySelfDisciplineMinutes * 60)

        print("📱 更新应用解锁状态：自律时间 \(todaySelfDisciplineMinutes) 分钟")

        // 清理重复规则（只在第一次调用时执行）
        cleanupDuplicateRules()

        // 调试：打印所有规则的应用名称
        print("📱 [调试] 当前规则列表：")
        for (index, rule) in appUnlockRules.enumerated() {
            print("📱 [调试] 规则 \(index): \(rule.appName)")
        }

        // 计算所有应用的总使用时间
        let totalUsedTime = appUnlockRules.filter { $0.isEnabled }.reduce(0) { total, rule in
            return total + getAppUsedTime(rule.appName)
        }

        // 计算剩余的共享时间池
        let remainingSharedTime = max(0, todaySelfDisciplineSeconds - totalUsedTime)

        print("📱 共享时间池：总时间 \(todaySelfDisciplineMinutes)分钟, 已用 \(Int(totalUsedTime/60))分钟, 剩余 \(Int(remainingSharedTime/60))分钟")

        // 新的计算逻辑：所有应用共享同一个时间池
        appUnlockStatuses = appUnlockRules
            .filter { $0.isEnabled }
            .map { rule in
                let usedTime = getAppUsedTime(rule.appName)

                // 如果没有自律时间，所有应用都不可用
                if todaySelfDisciplineSeconds <= 0 {
                    let status = AppUnlockStatus(
                        appName: rule.appName,
                        isUnlocked: false,
                        remainingTime: 0,
                        totalUnlockedTime: 0,
                        usedTime: usedTime,
                        applicationToken: rule.applicationToken,
                        bundleIdentifier: rule.bundleIdentifier,
                        displayName: rule.displayName
                    )
                    print("📱 \(rule.appName): 无自律时间，应用不可用")
                    return status
                }

                // 应用可用时间 = 共享时间池总时间，但不超过每日最大时间
                let maxAvailableTime = min(todaySelfDisciplineSeconds, rule.maxDailyTime)

                // 该应用剩余时间 = 共享时间池剩余时间（如果该应用还没用完的话）
                let appRemainingTime = max(0, min(maxAvailableTime - usedTime, remainingSharedTime))

                let isUnlocked = remainingSharedTime > 0 && usedTime < maxAvailableTime

                let status = AppUnlockStatus(
                    appName: rule.appName,
                    isUnlocked: isUnlocked,
                    remainingTime: appRemainingTime,
                    totalUnlockedTime: maxAvailableTime,
                    usedTime: usedTime,
                    applicationToken: rule.applicationToken,
                    bundleIdentifier: rule.bundleIdentifier,
                    displayName: rule.displayName
                )

                print("📱 \(rule.appName): 最大可用 \(Int(maxAvailableTime/60))分钟, 已用 \(Int(usedTime/60))分钟, 剩余 \(Int(appRemainingTime/60))分钟, 可用: \(isUnlocked)")

                return status
            }

        print("📱 ✅ 共享时间池状态更新完成")
    }

    /// 清理重复的应用规则
    private func cleanupDuplicateRules() {
        // 使用静态变量确保只执行一次
        struct CleanupState {
            static var hasCleanedUp = false
        }

        guard !CleanupState.hasCleanedUp else { return }
        CleanupState.hasCleanedUp = true

        let originalCount = appUnlockRules.count

        // 按 ApplicationToken 去重，保留最新的规则
        var uniqueRules: [AppUnlockRule] = []
        var seenTokens: Set<Data> = []

        // 从后往前遍历，保留最新的规则
        for rule in appUnlockRules.reversed() {
            if let tokenData = rule.applicationToken {
                if !seenTokens.contains(tokenData) {
                    seenTokens.insert(tokenData)
                    uniqueRules.insert(rule, at: 0)
                }
            } else {
                // 对于没有 token 的规则，按名称去重
                if !uniqueRules.contains(where: { $0.appName == rule.appName && $0.applicationToken == nil }) {
                    uniqueRules.insert(rule, at: 0)
                }
            }
        }

        appUnlockRules = uniqueRules

        if originalCount != uniqueRules.count {
            print("📱 [清理] 清理重复规则：从 \(originalCount) 个减少到 \(uniqueRules.count) 个")
            saveUnlockRules()
        }
    }

    /// 获取应用已使用时间
    private func getAppUsedTime(_ appName: String) -> TimeInterval {
        // 首先尝试从Screen Time数据中获取
        if isAuthorized {
            let screenTimeUsage = screenTimeManager.getAppUsageTime(for: appName)
            if screenTimeUsage > 0 {
                return TimeInterval(screenTimeUsage * 60) // 转换为秒
            }
        }

        // 从今日使用记录中获取
        if let savedUsedTime = getTodayUsedTime(for: appName) {
            return savedUsedTime
        }

        // 否则从默认数据获取
        let usageMinutes = appUsageData.first { $0.appName == appName }?.usageTime ?? 0
        return TimeInterval(usageMinutes * 60)
    }

    /// 记录应用使用时间并从自律时间中扣除
    func recordAppUsage(appName: String, usageTime: TimeInterval) {
        // 保存应用使用时间
        let currentUsedTime = getTodayUsedTime(for: appName) ?? 0
        let newUsedTime = currentUsedTime + usageTime
        saveTodayUsedTime(for: appName, usedTime: newUsedTime)

        // 从倒计时中扣除时间
        if countdownManager.isCountingDown {
            let usageSeconds = Int(usageTime)
            if countdownManager.remainingTimeInSeconds > usageSeconds {
                countdownManager.remainingTimeInSeconds -= usageSeconds
                print("📱 应用使用管理器：\(appName) 使用了 \(Int(usageTime/60)) 分钟，剩余自律时间 \(countdownManager.remainingTimeInSeconds/60) 分钟")
            } else {
                // 时间耗尽，触发锁定
                countdownManager.remainingTimeInSeconds = 0
                print("📱 应用使用管理器：\(appName) 使用时间导致自律时间耗尽")
            }
        }

        // 更新解锁状态
        updateAppUnlockStatuses()
    }

    /// 获取今日应用使用时间（从本地存储）
    private func getTodayUsedTime(for appName: String) -> TimeInterval? {
        let today = Calendar.current.startOfDay(for: Date())
        let key = "app_used_time_\(appName)_\(today.timeIntervalSince1970)"
        return userDefaults.object(forKey: key) as? TimeInterval
    }

    /// 保存今日应用使用时间
    func saveTodayUsedTime(for appName: String, usedTime: TimeInterval) {
        let today = Calendar.current.startOfDay(for: Date())
        let key = "app_used_time_\(appName)_\(today.timeIntervalSince1970)"
        userDefaults.set(usedTime, forKey: key)

        // 更新解锁状态
        updateAppUnlockStatuses()
    }

    /// 开始监控应用使用情况
    func startMonitoringAppUsage() {
        // 设置定时器，每分钟检查一次应用使用情况
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAndUpdateAppUsage()
            }
        }
    }

    /// 检查并更新应用使用情况
    @MainActor
    private func checkAndUpdateAppUsage() async {
        guard isAuthorized else { return }

        // 刷新Screen Time数据
        screenTimeManager.refreshData()

        // 检查选择的应用的使用时间变化
        let savedApps = getSavedApplications()
        for appInfo in savedApps {
            if let appName = appInfo["displayName"] as? String {
                let currentUsage = getAppUsedTime(appName)
                let lastRecordedUsage = getTodayUsedTime(for: appName) ?? 0

                if currentUsage > lastRecordedUsage {
                    let additionalUsage = currentUsage - lastRecordedUsage
                    recordAppUsage(appName: appName, usageTime: additionalUsage)
                }
            }
        }
    }

    // MARK: - 公共方法

    /// 刷新数据
    func refreshData() {
        // 刷新Screen Time数据
        if isAuthorized {
            screenTimeManager.refreshData()
            // 等待数据更新后同步
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.syncWithScreenTimeData()
                self.calculateTodayStats()
                self.updateAppUnlockStatuses()
            }
        } else {
            calculateTodayStats()
            updateAppUnlockStatuses()
        }
    }

    /// 添加自律时间记录
    func addSelfDisciplineRecord(_ record: SelfDisciplineRecord) {
        selfDisciplineRecords.append(record)
        saveSelfDisciplineRecords()
        refreshData()
    }



    /// 从用户选择的应用保存应用信息（不自动创建解锁规则）
    func saveSelectedApplications(_ applications: Set<Application>) {
        print("📱 [FamilyActivityPicker] 用户通过系统选择器选择了 \(applications.count) 个应用，保存应用信息")

        // 保存选择的应用信息到UserDefaults，用于后续创建规则时使用
        var savedApps: [[String: Any]] = []



        // 为每个选择的应用保存信息
        for (index, application) in applications.enumerated() {
            // 调试：打印 Application 对象的所有可用信息
            print("📱 Application \(index + 1) 详细信息:")
            print("  - bundleIdentifier: \(application.bundleIdentifier ?? "nil")")
            print("  - localizedDisplayName: \(application.localizedDisplayName ?? "nil")")
            print("  - token: \(application.token)")

            // 序列化 ApplicationToken 用于后续显示和重复检查
            var tokenData: Data? = nil
            do {
                tokenData = try PropertyListEncoder().encode(application.token)
                print("  - 成功序列化 ApplicationToken")
            } catch {
                print("  - ApplicationToken 序列化失败: \(error)")
                continue // 如果序列化失败，跳过这个应用
            }

            // 生成唯一的应用标识符
            let appId = "app_\(UUID().uuidString.prefix(8))"

            // 优先使用 localizedDisplayName，如果为空则使用 bundleIdentifier 的最后部分，最后才使用索引
            let displayName: String
            if let localizedName = application.localizedDisplayName, !localizedName.isEmpty {
                displayName = localizedName
            } else if let bundleId = application.bundleIdentifier, !bundleId.isEmpty {
                // 从 bundle identifier 中提取应用名称（如 com.tencent.xin -> xin）
                let components = bundleId.components(separatedBy: ".")
                displayName = components.last?.capitalized ?? "应用 \(index + 1)"
            } else {
                displayName = "应用 \(index + 1)"
            }

            // 保存应用信息
            let appInfo: [String: Any] = [
                "appId": appId, // 使用唯一ID作为标识符
                "bundleIdentifier": application.bundleIdentifier ?? "",
                "displayName": displayName,
                "applicationToken": tokenData ?? Data()
            ]
            savedApps.append(appInfo)
            print("  - 保存应用信息: \(displayName) (ID: \(appId))")
        }

        // 保存到UserDefaults
        UserDefaults.standard.set(savedApps, forKey: "selected_applications")
        UserDefaults.standard.set(applications.count, forKey: "saved_app_selection_count")
        UserDefaults.standard.synchronize()

        // 更新 @Published 属性以触发 UI 更新
        savedApplications = savedApps

        print("📱 已保存 \(applications.count) 个应用信息")
        print("📱 💡 提示：您可以在应用管理页面为这些应用设置基础时间和限制")

        // 如果有自律时间且用户选择了应用，自动开始倒计时
        if !countdownManager.hasExhaustedForToday() && getTodaySelfDisciplineTime() > 0 && !applications.isEmpty {
            startSelfDisciplineCountdown()
        }
    }

    /// 获取保存的应用信息
    func getSavedApplications() -> [[String: Any]] {
        return savedApplications
    }

    /// 为应用创建解锁规则
    func createUnlockRule(for appInfo: [String: Any]) {
        guard let displayName = appInfo["displayName"] as? String,
              let tokenData = appInfo["applicationToken"] as? Data else {
            print("📱 应用信息不完整，无法创建规则")
            return
        }

        let appId = appInfo["appId"] as? String ?? UUID().uuidString
        let bundleIdentifier = appInfo["bundleIdentifier"] as? String ?? ""

        // 检查是否已存在规则（使用 applicationToken 作为唯一标识）
        if let existingIndex = appUnlockRules.firstIndex(where: {
            $0.applicationToken == tokenData
        }) {
            print("📱 应用 \(displayName) 已存在规则，跳过创建")
            return
        }

        // 使用应用的显示名称作为规则名称，确保每个规则都有唯一的名称
        let appName: String
        if !displayName.isEmpty {
            appName = displayName
        } else if !bundleIdentifier.isEmpty {
            // 从 bundle identifier 中提取应用名称
            let components = bundleIdentifier.components(separatedBy: ".")
            appName = components.last?.capitalized ?? "应用 \(appUnlockRules.count + 1)"
        } else {
            // 使用 ApplicationToken 的哈希值确保唯一性
            let tokenHash = tokenData.hashValue
            appName = "应用 \(abs(tokenHash) % 10000)"
        }

        // 创建规则（保留旧字段用于兼容性，但不再使用）
        let rule = AppUnlockRule(
            appName: appName,
            unlockRatio: 0.0, // 已废弃，保留用于兼容
            maxDailyTime: 3600, // 默认最大1小时
            isEnabled: true,
            applicationTokenData: nil,
            bundleIdentifier: bundleIdentifier,
            displayName: displayName,
            applicationToken: tokenData,
            baseTimeMinutes: 0 // 已废弃，保留用于兼容
        )

        appUnlockRules.append(rule)
        saveUnlockRules()
        updateAppUnlockStatuses()

        // 从保存的应用列表中移除已创建规则的应用（使用 applicationToken 匹配）
        savedApplications.removeAll { savedApp in
            guard let savedTokenData = savedApp["applicationToken"] as? Data else { return false }
            return savedTokenData == tokenData
        }

        // 更新 UserDefaults
        UserDefaults.standard.set(savedApplications, forKey: "selected_applications")
        UserDefaults.standard.synchronize()

        print("📱 为 \(displayName) 创建了解锁规则，使用共享时间池")
    }



    /// 取消应用限制并扣除5分钟自律时长；如果不足则提示增时方式
    @MainActor
    func cancelAppRestrictionWithPenalty(appName: String) {
        let penaltyMinutes = 5

        // 当前剩余自律时长（分钟）
        let remainingMinutes = max(0, countdownManager.remainingTimeInSeconds / 60)

        if remainingMinutes >= penaltyMinutes {
            // 先执行取消限制
            Task {
                await appRestrictionManager.removeRestriction(for: appName)
            }
            // 再扣除5分钟
            countdownManager.deductTime(minutes: penaltyMinutes)
            print("📱 取消 \(appName) 限制，已扣除 \(penaltyMinutes) 分钟，自律剩余 \(countdownManager.remainingTimeInSeconds/60) 分钟")
        } else {
            // 不足以扣减：给出友好提示
            showIncreaseTimeTips()
        }
    }

    /// 友好提示：如何增加自律时长
    @MainActor
    private func showIncreaseTimeTips() {
        // 这里仅打印提示，UI层可根据需要绑定到 Alert/Toast
        print("💡 自律时长不足：可以通过以下方式增加：1) 完成今日计划 2) 进行运动 3) 昨夜充足睡眠 4) 在首页刷新后会自动汇总新增自律时间")
    }

    /// 根据应用数量和索引获取默认参数
    private func getDefaultParameters(for totalCount: Int, at index: Int) -> (ratio: Double, time: TimeInterval) {
        // 根据应用数量调整默认参数，确保总体合理
        let baseRatio: Double
        let baseTime: TimeInterval

        switch totalCount {
        case 1:
            // 只选择一个应用，给予较高的比例和时间
            baseRatio = 0.6
            baseTime = 7200 // 2小时
        case 2...3:
            // 选择2-3个应用，平均分配
            baseRatio = 0.4
            baseTime = 3600 // 1小时
        case 4...6:
            // 选择4-6个应用，降低单个应用的比例
            baseRatio = 0.3
            baseTime = 2400 // 40分钟
        default:
            // 选择更多应用，进一步降低
            baseRatio = 0.2
            baseTime = 1800 // 30分钟
        }

        return (baseRatio, baseTime)
    }



    /// 获取应用的解锁状态
    func getUnlockStatus(for appName: String) -> AppUnlockStatus? {
        return appUnlockStatuses.first { $0.appName == appName }
    }

    /// 检查应用是否可以使用
    func canUseApp(_ appName: String) -> Bool {
        guard let status = getUnlockStatus(for: appName) else { return true }
        return status.isUnlocked && status.remainingTime > 0
    }

    /// 获取应用剩余使用时间（分钟）
    func getRemainingTime(for appName: String) -> Int {
        guard let status = getUnlockStatus(for: appName) else { return 0 }
        return Int(status.remainingTime / 60)
    }

    /// 格式化时间显示
    func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// 获取今日自律时间的格式化字符串
    func getFormattedTodaySelfDisciplineTime() -> String {
        let minutes = getTodaySelfDisciplineTime()
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - 高级解锁功能

    /// 临时解锁应用（紧急使用）
    func temporaryUnlock(appName: String, duration: TimeInterval) {
        // 使用新的应用限制管理器
        Task {
            await appRestrictionManager.temporaryUnlock(for: appName, duration: duration)
        }

        // 保留原有的本地记录逻辑
        let key = "temp_unlock_\(appName)"
        let unlockUntil = Date().addingTimeInterval(duration)
        userDefaults.set(unlockUntil.timeIntervalSince1970, forKey: key)

        updateAppUnlockStatuses()
        print("📱 临时解锁 \(appName)，持续 \(Int(duration/60)) 分钟")
    }

    /// 检查应用是否临时解锁
    private func isTemporaryUnlocked(_ appName: String) -> Bool {
        let key = "temp_unlock_\(appName)"
        guard let unlockUntilTimestamp = userDefaults.object(forKey: key) as? TimeInterval else {
            return false
        }

        let unlockUntil = Date(timeIntervalSince1970: unlockUntilTimestamp)
        return Date() < unlockUntil
    }

    /// 获取应用解锁进度（0.0-1.0）
    func getUnlockProgress(for appName: String) -> Double {
        guard let status = getUnlockStatus(for: appName) else { return 0.0 }
        guard status.totalUnlockedTime > 0 else { return 0.0 }

        return min(1.0, status.usedTime / status.totalUnlockedTime)
    }

    /// 获取解锁状态描述
    func getUnlockStatusDescription(for appName: String) -> String {
        guard let status = getUnlockStatus(for: appName) else {
            return "无限制"
        }

        if isTemporaryUnlocked(appName) {
            return "临时解锁中"
        }

        // 检查是否有自律时间
        let todaySelfDisciplineMinutes = getTodaySelfDisciplineTime()
        if todaySelfDisciplineMinutes <= 0 {
            return "需要自律时间才能使用"
        }

        if !status.isUnlocked {
            return "需要更多自律时间"
        }

        if status.remainingTime <= 0 {
            return "今日分配时间已用完"
        }

        let remainingMinutes = Int(status.remainingTime / 60)
        return "剩余 \(remainingMinutes) 分钟"
    }

    /// 获取解锁建议
    func getUnlockSuggestion(for appName: String) -> String {
        guard let rule = appUnlockRules.first(where: { $0.appName == appName }),
              let status = getUnlockStatus(for: appName) else {
            return ""
        }

        if status.isUnlocked && status.remainingTime > 0 {
            return "可以使用"
        }

        let currentSelfDiscipline = getTodaySelfDisciplineTime()
        let neededSelfDiscipline = Int(rule.maxDailyTime / 60 / rule.unlockRatio)
        let additionalNeeded = max(0, neededSelfDiscipline - currentSelfDiscipline)

        if additionalNeeded > 0 {
            return "再完成 \(additionalNeeded) 分钟自律活动即可解锁"
        } else {
            return "今日使用时间已达上限"
        }
    }
    // MARK: - 解析规则中的应用信息（用于名称与图标显示）
    /// 获取用于展示的应用名称（优先规则里的 displayName -> 规则里的 bundleId -> 占位名）
    func getResolvedDisplayName(for appName: String) -> String {
        if let rule = appUnlockRules.first(where: { $0.appName == appName }) {
            if let name = rule.displayName, !name.isEmpty {
                return name
            }
            if let bundleId = rule.bundleIdentifier, !bundleId.isEmpty {
                return bundleId
            }
        }
        return appName
    }

    /// 获取用于图标查找的 bundleIdentifier（优先规则里的 bundleId）
    func getResolvedBundleIdentifier(for appName: String) -> String? {
        if let rule = appUnlockRules.first(where: { $0.appName == appName }) {
            return rule.bundleIdentifier
        }
        return nil
    }

    /// 获取应用的 ApplicationToken（用于 SwiftUI Label 显示）
    func getApplicationToken(for appName: String) -> ApplicationToken? {
        guard let rule = appUnlockRules.first(where: { $0.appName == appName }),
              let tokenData = rule.applicationToken else {
            return nil
        }

        do {
            return try PropertyListDecoder().decode(ApplicationToken.self, from: tokenData)
        } catch {
            print("📱 ApplicationToken 反序列化失败: \(error)")
            return nil
        }
    }

    /// 生成基于 ApplicationToken 的 Label 视图，避免在 View 中直接依赖类型
    func makeApplicationLabel(from tokenData: Data, titleOnly: Bool) -> AnyView? {
        guard let token = try? PropertyListDecoder().decode(ApplicationToken.self, from: tokenData) else {
            return nil
        }

        let tokenHash = abs(tokenData.hashValue)
        let cacheKey = "\(tokenHash)_\(titleOnly ? "title" : "icon")"

        // 检查缓存
        if let cachedView = labelCache[cacheKey] {
            return cachedView
        }

        // 创建新的 Label 视图
        let newView: AnyView
        if titleOnly {
            newView = AnyView(
                Group {
                    Label(token)
                        .labelStyle(.titleOnly)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .id("app_label_\(tokenHash)")
            )
        } else {
            newView = AnyView(
                Group {
                    Label(token)
                        .labelStyle(.iconOnly)
                }
                .id("app_icon_\(tokenHash)")
            )
        }

        // 缓存视图（限制缓存大小）
        if labelCache.count < 100 {
            labelCache[cacheKey] = newView
        }

        return newView
    }



    /// 通过ApplicationToken查找规则索引
    private func findRuleIndexByApplicationToken(_ tokenData: Data?) -> Int? {
        guard let tokenData = tokenData else { return nil }

        return appUnlockRules.firstIndex { rule in
            guard let ruleTokenData = rule.applicationToken else { return false }
            return ruleTokenData == tokenData
        }
    }

    // MARK: - 系统应用图标获取尝试
    /// 尝试通过系统 API 获取应用图标
    private func getAppIconFromSystem(bundleId: String) -> UIImage? {
        // 方法1: 尝试使用 UIApplication.shared.canOpenURL 检查应用是否存在
        if let url = URL(string: "\(bundleId)://") {
            if UIApplication.shared.canOpenURL(url) {
                print("📱 应用 \(bundleId) 可以打开，说明已安装")
            }
        }

        // 方法2: 尝试通过 URL scheme 获取应用信息
        // 大多数应用都有自己的 URL scheme，但这不能直接获取图标

        // 暂时无法在沙盒环境下安全获取其他应用的图标
        // 需要等待 iOS 提供公开的 API 或使用其他方案
        print("📱 暂时无法获取 \(bundleId) 的真实图标")
        return nil
    }



    // MARK: - 应用限制管理

    /// 设置应用时间限制
    func setAppTimeLimit(appName: String, timeLimit: TimeInterval) {
        Task {
            await appRestrictionManager.setTimeLimit(for: appName, timeLimit: timeLimit)
            // 更新解锁状态
            updateAppUnlockStatuses()
        }
    }

    /// 移除应用限制
    func removeAppRestriction(appName: String) {
        Task {
            await appRestrictionManager.removeRestriction(for: appName)
            // 更新解锁状态
            updateAppUnlockStatuses()
        }
    }

    /// 清除所有应用限制
    func clearAllAppRestrictions() {
        Task {
            await appRestrictionManager.clearAllRestrictions()
            // 更新解锁状态
            updateAppUnlockStatuses()
        }
    }

    /// 检查应用是否被限制
    func isAppRestricted(_ appName: String) -> Bool {
        return appRestrictionManager.isAppRestricted(appName)
    }

    /// 获取应用剩余限制时间
    func getAppRemainingTime(_ appName: String) -> TimeInterval {
        return appRestrictionManager.getRemainingTime(for: appName)
    }

    // MARK: - 倒计时管理器集成

    /// 设置倒计时管理器回调
    private func setupCountdownManagerCallbacks() {
        // 当自律时间耗尽时，锁定所有选择的应用
        countdownManager.onTimeExpired = { [weak self] in
            Task { @MainActor in
                await self?.lockSelectedApps()
            }
        }

        // 当倒计时更新时，可以在这里添加其他逻辑
        countdownManager.onTimeUpdated = { [weak self] remainingSeconds in
            // 可以在这里添加警告逻辑，比如剩余5分钟时提醒用户
            if remainingSeconds == 300 { // 5分钟
                self?.showTimeWarning(minutes: 5)
            } else if remainingSeconds == 60 { // 1分钟
                self?.showTimeWarning(minutes: 1)
            }
        }

        // 监听自律时间添加通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SelfDisciplineTimeAdded"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.unlockSelectedApps()
            }
        }
    }

    /// 锁定所有选择的应用
    private func lockSelectedApps() async {
        print("📱 自律时间耗尽，开始锁定选择的应用")

        // 使用应用限制管理器锁定选择的应用
        await appRestrictionManager.lockSelectedApplications()

        // 获取用户选择的应用数量用于通知
        let selectedApps = getSelectedApplications()

        if !selectedApps.isEmpty {
            print("📱 已锁定 \(selectedApps.count) 个应用")

            // 发送通知
            NotificationCenter.default.post(
                name: NSNotification.Name("AppsLockedDueToTimeExpired"),
                object: nil,
                userInfo: ["lockedAppsCount": selectedApps.count]
            )
        } else {
            print("📱 没有选择的应用需要锁定")
        }
    }

    /// 显示时间警告
    private func showTimeWarning(minutes: Int) {
        print("⚠️ 自律时间警告：剩余 \(minutes) 分钟")

        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("SelfDisciplineTimeWarning"),
            object: nil,
            userInfo: ["remainingMinutes": minutes]
        )
    }

    /// 开始自律时间倒计时
    func startSelfDisciplineCountdown() {
        // 如果今天已经耗尽，直接返回，不要重启
        if countdownManager.hasExhaustedForToday() {
            print("📱 今日已耗尽，不重启自律倒计时")
            return
        }

        let totalMinutes = getTodaySelfDisciplineTime()

        guard totalMinutes > 0 else {
            print("📱 没有自律时间，无法开始倒计时")
            return
        }

        // 检查是否有选择的应用
        let selectedApps = getSelectedApplications()
        guard !selectedApps.isEmpty else {
            print("📱 没有选择要限制的应用，无法开始倒计时")
            return
        }

        countdownManager.startCountdown(totalMinutes: totalMinutes)
        print("📱 开始自律时间倒计时：\(totalMinutes) 分钟，将监控 \(selectedApps.count) 个应用")

        // 配置系统级一次性拦截：在倒计时结束时由系统扩展在后台触发
        let endDate = Date().addingTimeInterval(TimeInterval(totalMinutes * 60))
        Task { @MainActor in
            await self.appRestrictionManager.scheduleOneOffBlocking(at: endDate)
        }
    }

    /// 停止自律时间倒计时
    func stopSelfDisciplineCountdown() {
        countdownManager.stopCountdown()
        print("📱 停止自律时间倒计时")
    }

    /// 获取倒计时管理器（供UI使用）
    func getCountdownManager() -> SelfDisciplineCountdownManager {
        return countdownManager
    }

    /// 解锁所有应用（当获得新的自律时间时）
    func unlockSelectedApps() async {
        print("📱 解锁选择的应用")

        // 解锁所有应用
        await appRestrictionManager.unlockAllApplications()

        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("AppsUnlocked"),
            object: nil
        )
    }

    // MARK: - 辅助方法

    /// 获取选择的应用
    private func getSelectedApplications() -> [Application] {
        let savedApps = getSavedApplications()
        var applications: [Application] = []

        for appInfo in savedApps {
            if let tokenData = appInfo["applicationToken"] as? Data {
                do {
                    let token = try PropertyListDecoder().decode(ApplicationToken.self, from: tokenData)
                    let application = Application(token: token)
                    applications.append(application)
                } catch {
                    print("📱 反序列化ApplicationToken失败: \(error)")
                }
            }
        }

        return applications
    }

    /// 从应用数组创建FamilyActivitySelection
    private func createFamilyActivitySelection(from applications: [Application]) -> FamilyActivitySelection {
        // FamilyActivitySelection 的 applications 属性是只读的，需要通过其他方式设置
        // 这里我们直接返回一个包含应用的 Set，在调用处直接使用
        return FamilyActivitySelection()
    }
}
