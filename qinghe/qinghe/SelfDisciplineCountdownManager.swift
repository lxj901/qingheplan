import Foundation
import SwiftUI
import Combine

/// 自律时间倒计时管理器
/// 负责监控自律时间的消耗，当用户选择要限制的应用后自动开始倒计时，时间到达0时触发应用锁定
class SelfDisciplineCountdownManager: ObservableObject {
    static let shared = SelfDisciplineCountdownManager()
    
    // MARK: - Published Properties
    
    /// 当前剩余自律时间（秒）
    @Published var remainingTimeInSeconds: Int = 0
    
    /// 是否正在倒计时
    @Published var isCountingDown: Bool = false
    
    /// 是否已经锁定应用
    @Published var isAppsLocked: Bool = false
    
    /// 倒计时开始时的总时间（秒）
    @Published var initialTimeInSeconds: Int = 0
    
    /// 倒计时进度（0.0 - 1.0）
    var progress: Double {
        guard initialTimeInSeconds > 0 else { return 0.0 }
        return Double(remainingTimeInSeconds) / Double(initialTimeInSeconds)
    }
    
    /// 格式化的剩余时间字符串
    var formattedRemainingTime: String {
        let hours = remainingTimeInSeconds / 3600
        let minutes = (remainingTimeInSeconds % 3600) / 60
        let seconds = remainingTimeInSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // 存储键
    private let remainingTimeKey = "SelfDisciplineCountdown_RemainingTime"
    private let initialTimeKey = "SelfDisciplineCountdown_InitialTime"
    private let isCountingDownKey = "SelfDisciplineCountdown_IsCountingDown"
    private let startTimeKey = "SelfDisciplineCountdown_StartTime"
    private let exhaustedDateKey = "SelfDisciplineCountdown_ExhaustedDate"
    
    // MARK: - Callbacks

    /// 时间耗尽时的回调
    var onTimeExpired: (() -> Void)?

    /// 倒计时更新时的回调
    var onTimeUpdated: ((Int) -> Void)?

    // MARK: - Initialization

    private init() {
        // 跨天清理“已耗尽”标记
        clearExhaustedFlagIfCrossDay()
        loadSavedState()
        setupNotifications()
    }

    // MARK: - Exhaust Flag

    /// 今日是否已经耗尽自律时间
    func hasExhaustedForToday() -> Bool {
        guard let ts = userDefaults.object(forKey: exhaustedDateKey) as? TimeInterval else { return false }
        let savedDate = Date(timeIntervalSince1970: ts)
        return Calendar.current.isDate(savedDate, inSameDayAs: Date())
    }

    private func markExhaustedToday() {
        let now = Date().timeIntervalSince1970
        userDefaults.set(now, forKey: exhaustedDateKey)
        userDefaults.synchronize()
    }

    private func clearExhaustedFlag() {
        userDefaults.removeObject(forKey: exhaustedDateKey)
        userDefaults.synchronize()
    }

    private func clearExhaustedFlagIfCrossDay() {
        guard let ts = userDefaults.object(forKey: exhaustedDateKey) as? TimeInterval else { return }
        let savedDate = Date(timeIntervalSince1970: ts)
        if !Calendar.current.isDate(savedDate, inSameDayAs: Date()) {
            clearExhaustedFlag()
        }
    }
    
    // MARK: - Public Methods
    
    /// 开始倒计时
    /// - Parameter totalMinutes: 总的自律时间（分钟）
    func startCountdown(totalMinutes: Int) {
        guard totalMinutes > 0 else {
            print("⏰ 倒计时管理器：无效的时间参数 \(totalMinutes) 分钟")
            return
        }
        
        let totalSeconds = totalMinutes * 60
        
        // 如果已经在倒计时且时间相同，不重复开始
        if isCountingDown && initialTimeInSeconds == totalSeconds {
            print("⏰ 倒计时管理器：已在进行相同时间的倒计时，跳过")
            return
        }
        
        // 停止当前倒计时
        stopCountdown()
        
        // 设置新的倒计时
        initialTimeInSeconds = totalSeconds
        remainingTimeInSeconds = totalSeconds
        isCountingDown = true
        isAppsLocked = false
        
        // 保存状态
        saveCurrentState()
        
        // 开始定时器
        startTimer()
        
        print("⏰ 倒计时管理器：开始倒计时 \(totalMinutes) 分钟（\(totalSeconds) 秒）")
    }
    
    /// 停止倒计时
    func stopCountdown() {
        timer?.invalidate()
        timer = nil
        isCountingDown = false
        
        // 清除保存的状态
        clearSavedState()
        
        print("⏰ 倒计时管理器：停止倒计时")
    }
    
    /// 暂停倒计时
    func pauseCountdown() {
        guard isCountingDown else { return }
        
        timer?.invalidate()
        timer = nil
        
        // 保存当前状态
        saveCurrentState()
        
        print("⏰ 倒计时管理器：暂停倒计时，剩余 \(remainingTimeInSeconds) 秒")
    }
    
    /// 恢复倒计时
    func resumeCountdown() {
        guard !isCountingDown && remainingTimeInSeconds > 0 else { return }
        
        isCountingDown = true
        startTimer()
        
        print("⏰ 倒计时管理器：恢复倒计时，剩余 \(remainingTimeInSeconds) 秒")
    }
    
    /// 重置倒计时
    func resetCountdown() {
        stopCountdown()
        remainingTimeInSeconds = 0
        initialTimeInSeconds = 0
        isAppsLocked = false

        print("⏰ 倒计时管理器：重置倒计时")
    }

    /// 重置每日倒计时状态（在新的一天开始时调用）
    func resetDailyCountdown() {
        stopCountdown()
        remainingTimeInSeconds = 0
        initialTimeInSeconds = 0
        isAppsLocked = false
        clearSavedState()

        print("⏰ 倒计时管理器：重置每日倒计时状态")
    }
    
    /// 添加额外的自律时间
    /// - Parameter additionalMinutes: 要添加的分钟数
    func addTime(additionalMinutes: Int) {
        guard additionalMinutes > 0 else { return }

        let additionalSeconds = additionalMinutes * 60
        remainingTimeInSeconds += additionalSeconds
        initialTimeInSeconds += additionalSeconds

        // 如果应用已锁定，解锁应用
        if isAppsLocked {
            isAppsLocked = false
            print("⏰ 倒计时管理器：添加时间后解锁应用")

            // 发送解锁通知
            NotificationCenter.default.post(name: NSNotification.Name("SelfDisciplineTimeAdded"), object: nil)
        }

        // 如果没有在倒计时，重新开始
        if !isCountingDown && remainingTimeInSeconds > 0 {
            isCountingDown = true
            startTimer()
        }

        saveCurrentState()

        print("⏰ 倒计时管理器：添加 \(additionalMinutes) 分钟，剩余 \(remainingTimeInSeconds) 秒")
    }

    /// 扣减自律时间（如用户取消限制时的惩罚）
    /// - Parameter minutes: 扣减分钟数
    func deductTime(minutes: Int) {
        guard minutes > 0 else { return }
        let deductSeconds = minutes * 60
        let before = remainingTimeInSeconds
        remainingTimeInSeconds = max(0, remainingTimeInSeconds - deductSeconds)
        let actualDeducted = before - remainingTimeInSeconds
        initialTimeInSeconds = max(0, initialTimeInSeconds - actualDeducted)

        if remainingTimeInSeconds == 0 {
            isCountingDown = false
            isAppsLocked = true
        }

        saveCurrentState()
        print("⏰ 倒计时管理器：扣减 \(minutes) 分钟，剩余 \(remainingTimeInSeconds) 秒")
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
        
        // 确保定时器在后台也能运行
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func updateCountdown() {
        guard remainingTimeInSeconds > 0 else {
            handleTimeExpired()
            return
        }
        
        remainingTimeInSeconds -= 1
        
        // 保存状态（每分钟保存一次以减少I/O）
        if remainingTimeInSeconds % 60 == 0 {
            saveCurrentState()
        }
        
        // 调用更新回调
        onTimeUpdated?(remainingTimeInSeconds)
        
        // 在最后10秒发出警告
        if remainingTimeInSeconds <= 10 && remainingTimeInSeconds > 0 {
            print("⏰ 倒计时管理器：警告 - 剩余 \(remainingTimeInSeconds) 秒")
        }
    }
    
    private func handleTimeExpired() {
        print("⏰ 倒计时管理器：时间耗尽，触发应用锁定")

        // 停止定时器
        timer?.invalidate()
        timer = nil

        // 更新状态
        remainingTimeInSeconds = 0
        isCountingDown = false
        isAppsLocked = true

        // 标记今日已耗尽
        markExhaustedToday()

        // 保存状态
        saveCurrentState()

        // 调用时间耗尽回调
        onTimeExpired?()

        // 发送通知
        NotificationCenter.default.post(name: NSNotification.Name("SelfDisciplineTimeExpired"), object: nil)
    }
    
    // MARK: - State Persistence
    
    private func saveCurrentState() {
        let currentTime = Date().timeIntervalSince1970
        userDefaults.set(remainingTimeInSeconds, forKey: remainingTimeKey)
        userDefaults.set(initialTimeInSeconds, forKey: initialTimeKey)
        userDefaults.set(isCountingDown, forKey: isCountingDownKey)
        userDefaults.set(currentTime, forKey: startTimeKey)
        userDefaults.synchronize()

        print("⏰ 保存状态 - 剩余时间=\(remainingTimeInSeconds)秒, 初始时间=\(initialTimeInSeconds)秒, 倒计时中=\(isCountingDown), 保存时间=\(currentTime)")
    }
    
    private func loadSavedState() {
        let savedRemainingTime = userDefaults.integer(forKey: remainingTimeKey)
        let savedInitialTime = userDefaults.integer(forKey: initialTimeKey)
        let savedIsCountingDown = userDefaults.bool(forKey: isCountingDownKey)
        let savedStartTime = userDefaults.double(forKey: startTimeKey)

        // 如果有保存的状态且在倒计时中
        if savedIsCountingDown && savedRemainingTime > 0 && savedStartTime > 0 {
            // 检查是否是同一天，如果不是同一天则清除状态
            let savedDate = Date(timeIntervalSince1970: savedStartTime)
            let today = Date()
            let calendar = Calendar.current

            if !calendar.isDate(savedDate, inSameDayAs: today) {
                print("⏰ 倒计时管理器：检测到跨天，清除旧的倒计时状态")
                clearSavedState()
                return
            }

            // 计算经过的时间
            let elapsedTime = Int(Date().timeIntervalSince1970 - savedStartTime)
            let adjustedRemainingTime = max(0, savedRemainingTime - elapsedTime)

            if adjustedRemainingTime > 0 {
                // 恢复倒计时状态
                initialTimeInSeconds = savedInitialTime
                remainingTimeInSeconds = adjustedRemainingTime
                isCountingDown = true
                isAppsLocked = false

                // 重新开始定时器
                startTimer()

                print("⏰ 倒计时管理器：恢复倒计时状态，剩余 \(adjustedRemainingTime) 秒")
            } else {
                // 时间已经耗尽
                handleTimeExpired()
            }
        }
    }
    
    private func clearSavedState() {
        userDefaults.removeObject(forKey: remainingTimeKey)
        userDefaults.removeObject(forKey: initialTimeKey)
        userDefaults.removeObject(forKey: isCountingDownKey)
        userDefaults.removeObject(forKey: startTimeKey)
        userDefaults.synchronize()
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        // 监听应用进入后台和前台
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.saveCurrentState()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                print("⏰ 倒计时管理器：应用进入前台，检查并恢复状态")
                self?.handleForegroundRestore()
            }
            .store(in: &cancellables)
    }

    /// 处理应用进入前台时的状态恢复
    private func handleForegroundRestore() {
        let savedRemainingTime = userDefaults.integer(forKey: remainingTimeKey)
        let savedInitialTime = userDefaults.integer(forKey: initialTimeKey)
        let savedIsCountingDown = userDefaults.bool(forKey: isCountingDownKey)
        let savedStartTime = userDefaults.double(forKey: startTimeKey)

        print("⏰ 前台恢复 - 保存的状态：剩余时间=\(savedRemainingTime)秒, 初始时间=\(savedInitialTime)秒, 倒计时中=\(savedIsCountingDown), 开始时间=\(savedStartTime)")

        // 如果没有保存的倒计时状态，直接返回
        guard savedIsCountingDown && savedRemainingTime > 0 && savedStartTime > 0 else {
            print("⏰ 前台恢复 - 没有有效的倒计时状态")
            return
        }

        // 检查是否是同一天
        let savedDate = Date(timeIntervalSince1970: savedStartTime)
        let today = Date()
        let calendar = Calendar.current

        if !calendar.isDate(savedDate, inSameDayAs: today) {
            print("⏰ 前台恢复 - 检测到跨天，清除旧的倒计时状态")
            clearSavedState()
            return
        }

        // 计算经过的时间
        let currentTime = Date().timeIntervalSince1970
        let elapsedTime = Int(currentTime - savedStartTime)
        let adjustedRemainingTime = max(0, savedRemainingTime - elapsedTime)

        print("⏰ 前台恢复 - 经过时间=\(elapsedTime)秒, 调整后剩余时间=\(adjustedRemainingTime)秒")

        if adjustedRemainingTime > 0 {
            // 恢复倒计时状态，但不重置为初始值
            initialTimeInSeconds = savedInitialTime
            remainingTimeInSeconds = adjustedRemainingTime
            isCountingDown = true
            isAppsLocked = false

            // 重新开始定时器
            startTimer()

            print("⏰ 前台恢复 - 成功恢复倒计时状态，剩余 \(adjustedRemainingTime) 秒")
        } else {
            // 时间已经耗尽
            print("⏰ 前台恢复 - 时间已耗尽，触发应用锁定")
            handleTimeExpired()
        }
    }
}
