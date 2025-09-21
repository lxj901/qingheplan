import Foundation
import CoreData

/// 运动数据同步管理器 - 负责协调本地缓存和远程API之间的数据同步（已移除HealthKit依赖）
class WorkoutSyncManager: ObservableObject {
    static let shared = WorkoutSyncManager()

    // MARK: - 依赖项
    private let apiService = NewWorkoutAPIService.shared
    private let coreDataManager = CoreDataManager.shared
    private let notificationManager = WorkoutNotificationManager.shared
    
    // MARK: - 发布的属性
    @Published var isSyncing = false
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    // MARK: - 私有属性
    private let userDefaults = UserDefaults.standard
    private let syncQueue = DispatchQueue(label: "workout.sync.queue", qos: .background)
    
    private enum UserDefaultsKeys {
        static let lastSyncDate = "workout_last_sync_date"
        static let autoSyncEnabled = "workout_auto_sync_enabled"
        static let wifiOnlySync = "workout_wifi_only_sync"
    }
    
    private init() {
        loadLastSyncDate()
    }
    
    // MARK: - 同步控制
    
    /// 开始完整同步（仅API数据）
    /// - Parameter force: 是否强制同步（忽略上次同步时间）
    func startFullSync(force: Bool = false) async {
        guard !isSyncing else {
            print("⚠️ 同步已在进行中，跳过")
            return
        }

        await MainActor.run {
            isSyncing = true
            syncProgress = 0.0
            syncError = nil
        }

        do {
            print("🔄 开始运动数据API同步")

            // 步骤1: 从服务器下载最新数据 (80%)
            await updateProgress(0.1, "正在下载最新数据...")
            try await downloadLatestDataFromServer()
            await updateProgress(0.8, "数据下载完成")

            // 步骤2: 清理和完成 (20%)
            await updateProgress(0.9, "正在清理...")
            cleanupSyncData()

            await updateProgress(1.0, "同步完成")
            await saveSyncDate()

            // 发送同步完成通知
            notificationManager.postWorkoutSyncCompletedNotification()
            notificationManager.postWorkoutDataUpdatedNotification()

            print("✅ 运动数据同步完成")

        } catch {
            print("❌ 运动数据同步失败: \(error.localizedDescription)")
            await MainActor.run {
                self.syncError = error
            }
        }

        await MainActor.run {
            self.isSyncing = false
        }
    }
    
    /// 同步单个运动记录（已移除HealthKit支持）
    /// 现在只支持API数据同步
    func syncAPIWorkout(_ workoutId: Int) async throws {
        print("🔄 同步API运动记录: \(workoutId)")

        // 从API获取运动记录详情
        // 这里可以添加具体的API调用逻辑
        print("✅ API运动记录同步完成: \(workoutId)")
    }
    
    /// 快速同步最近的运动数据（仅API）
    func quickSync() async {
        guard !isSyncing else { return }

        await MainActor.run {
            isSyncing = true
            syncProgress = 0.0
        }

        do {
            await updateProgress(0.3, "正在获取最近运动数据...")

            // 从API获取最近的运动数据
            try await downloadLatestDataFromServer()

            await updateProgress(1.0, "快速同步完成")
            await saveSyncDate()

            // 发送同步完成通知
            notificationManager.postWorkoutSyncCompletedNotification()
            notificationManager.postWorkoutDataUpdatedNotification()

        } catch {
            await MainActor.run {
                self.syncError = error
            }
        }

        await MainActor.run {
            self.isSyncing = false
        }
    }
    
    // MARK: - 私有同步方法（仅API数据）
    
    /// 从服务器下载最新数据
    private func downloadLatestDataFromServer() async throws {
        let lastSync = lastSyncDate ?? Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var page = 1
        var hasMore = true
        
        while hasMore {
            let workouts = try await apiService.getWorkouts(
                page: page,
                limit: 50
            )

            // 如果没有更多数据，停止循环
            if workouts.isEmpty {
                hasMore = false
                break
            }

            for workout in workouts {
                // 保存或更新本地缓存
                coreDataManager.saveOrUpdateServerWorkout(workout)
            }

            // 如果返回的数据少于请求的限制，说明没有更多数据了
            hasMore = workouts.count >= 50
            page += 1

            print("📥 已下载第 \(page - 1) 页数据，共 \(workouts.count) 条记录")
        }
    }
    
    /// 清理同步数据
    private func cleanupSyncData() {
        // 清理过期的缓存数据（超过6个月）
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        coreDataManager.cleanupOldWorkouts(before: sixMonthsAgo)
        
        // 清理失败的同步记录（超过7天）
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        coreDataManager.cleanupFailedSyncs(before: sevenDaysAgo)
    }
    
    // MARK: - 辅助方法
    
    private func updateProgress(_ progress: Double, _ message: String) async {
        await MainActor.run {
            self.syncProgress = progress
            print("📊 同步进度: \(Int(progress * 100))% - \(message)")
        }
    }
    
    private func saveSyncDate() async {
        let now = Date()
        userDefaults.set(now, forKey: UserDefaultsKeys.lastSyncDate)
        await MainActor.run {
            self.lastSyncDate = now
        }
    }
    
    private func loadLastSyncDate() {
        lastSyncDate = userDefaults.object(forKey: UserDefaultsKeys.lastSyncDate) as? Date
    }
    

    
    // MARK: - 自动同步设置
    
    var isAutoSyncEnabled: Bool {
        get { userDefaults.bool(forKey: UserDefaultsKeys.autoSyncEnabled) }
        set { userDefaults.set(newValue, forKey: UserDefaultsKeys.autoSyncEnabled) }
    }
    
    var isWiFiOnlySyncEnabled: Bool {
        get { userDefaults.bool(forKey: UserDefaultsKeys.wifiOnlySync) }
        set { userDefaults.set(newValue, forKey: UserDefaultsKeys.wifiOnlySync) }
    }
    
    /// 检查是否应该进行自动同步
    func shouldAutoSync() -> Bool {
        guard isAutoSyncEnabled else { return false }
        
        // 检查网络条件
        if isWiFiOnlySyncEnabled {
            // TODO: 实现WiFi检查逻辑
            return true // 暂时返回true
        }
        
        // 检查上次同步时间（至少间隔1小时）
        if let lastSync = lastSyncDate {
            let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
            return lastSync < oneHourAgo
        }
        
        return true
    }
    
    /// 启动自动同步（如果满足条件）
    func triggerAutoSyncIfNeeded() {
        guard shouldAutoSync() else { return }
        
        Task {
            await quickSync()
        }
    }
}

// MARK: - 错误定义

enum SyncError: Error, LocalizedError {
    case networkNotAvailable
    case uploadFailed(String)
    case downloadFailed(String)
    case dataConversionFailed
    case coreDataError

    var errorDescription: String? {
        switch self {
        case .networkNotAvailable:
            return "网络不可用"
        case .uploadFailed(let message):
            return "上传失败: \(message)"
        case .downloadFailed(let message):
            return "下载失败: \(message)"
        case .dataConversionFailed:
            return "数据转换失败"
        case .coreDataError:
            return "本地数据库错误"
        }
    }
}

// MARK: - CoreData管理器（简化版本）

/// 简化的CoreData管理器，实际项目中应该有完整的实现
class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - 占位符方法（需要根据实际CoreData模型实现）
    
    func workoutExists(workoutId: Int) -> Bool {
        // TODO: 实现实际的CoreData查询
        return false
    }

    func saveWorkout(_ workout: QingheWorkout) {
        // TODO: 实现实际的CoreData保存
        print("💾 保存运动记录到本地: \(workout.workoutId)")
    }
    
    func getUnsyncedWorkouts() -> [CachedWorkout] {
        // TODO: 返回未同步的运动记录
        return []
    }
    
    func updateWorkoutServerID(_ workout: CachedWorkout, serverID: Int) {
        // TODO: 更新本地记录的服务器ID
        print("🔄 更新运动记录服务器ID: \(serverID)")
    }
    
    func markWorkoutSyncFailed(_ workout: CachedWorkout, error: Error) {
        // TODO: 标记同步失败的记录
        print("❌ 标记运动记录同步失败: \(error.localizedDescription)")
    }
    
    func saveOrUpdateServerWorkout(_ workout: QingheWorkout) {
        // TODO: 保存或更新来自服务器的运动记录
        print("💾 保存服务器运动记录: \(workout.workoutId)")
    }
    
    func cleanupOldWorkouts(before date: Date) {
        // TODO: 清理过期的运动记录
        print("🧹 清理过期运动记录")
    }
    
    func cleanupFailedSyncs(before date: Date) {
        // TODO: 清理失败的同步记录
        print("🧹 清理失败同步记录")
    }
}

// MARK: - 缓存运动记录模型（占位符）

struct CachedWorkout {
    let id: UUID
    let serverID: Int?
    let localData: Data
    var syncStatus: SyncStatus
    let createdAt: Date
    var lastSyncAttempt: Date?
    var syncError: String?
}

enum SyncStatus: String, CaseIterable {
    case pending = "pending"
    case syncing = "syncing"
    case synced = "synced"
    case failed = "failed"
}