import Foundation
import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

/// 屏幕使用时间管理器 - 使用真实的Screen Time API
@MainActor
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var appUsageData: [AppUsageData] = []
    @Published var totalScreenTime: TimeInterval = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldShowAppPicker = false
    
    private let authorizationCenter = AuthorizationCenter.shared
    private let deviceActivityCenter = DeviceActivityCenter()
    private let managedSettingsStore = ManagedSettingsStore()
    
    private init() {
        checkAuthorizationStatus()

        // 如果已经授权，自动加载数据
        if isAuthorized {
            Task {
                await loadScreenTimeData()
            }
        }
    }
    
    // MARK: - 权限管理
    
    /// 检查当前授权状态
    func checkAuthorizationStatus() {
        authorizationStatus = authorizationCenter.authorizationStatus
        isAuthorized = authorizationStatus == .approved
        
        print("📱 Screen Time 授权状态: \(authorizationStatus)")
    }
    
    /// 请求Screen Time权限
    func requestAuthorization() async {
        do {
            isLoading = true
            errorMessage = nil
            
            try await authorizationCenter.requestAuthorization(for: .individual)
            
            await MainActor.run {
                checkAuthorizationStatus()
                if isAuthorized {
                    print("📱 Screen Time 权限获取成功")
                    // 权限获取成功后，提示用户选择应用
                    shouldShowAppPicker = true
                    Task {
                        await loadScreenTimeData()
                    }
                } else {
                    errorMessage = "需要Screen Time权限才能使用应用管理功能"
                    print("📱 Screen Time 权限被拒绝")
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "请求权限失败: \(error.localizedDescription)"
                isLoading = false
                print("📱 Screen Time 权限请求失败: \(error)")
            }
        }
    }
    
    // MARK: - 数据获取
    
    /// 加载屏幕使用时间数据
    func loadScreenTimeData() async {
        guard isAuthorized else {
            print("📱 未授权，无法加载Screen Time数据")
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // 创建设备活动监控
            let activityName = DeviceActivityName("com.qinghe.screentime.daily")
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0, minute: 0),
                intervalEnd: DateComponents(hour: 23, minute: 59),
                repeats: true
            )

            // 开始监控设备活动
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)

            // 注意：DeviceActivity 框架不直接提供使用时间数据，需要通过 DeviceActivityReport 扩展来获取
            // 当前项目尚未实现报告扩展，等待真实数据实现
            await MainActor.run {
                self.appUsageData = []
                self.totalScreenTime = 0
                print("📱 Screen Time：已启动监控，等待 DeviceActivityReport 扩展提供真实数据")
            }

        } catch {
            await MainActor.run {
                errorMessage = "加载数据失败: \(error.localizedDescription)"
                print("📱 加载Screen Time数据失败: \(error)")
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    

    
    // MARK: - 应用限制管理
    
    /// 设置应用使用限制
    func setAppRestriction(for application: Application, timeLimit: TimeInterval) {
        guard isAuthorized else {
            print("📱 未授权，无法设置应用限制")
            return
        }

        // 设置应用限制
        managedSettingsStore.application.blockedApplications = Set([application])

        print("📱 已设置应用限制，时间限制: \(Int(timeLimit/60))分钟")
    }
    
    /// 移除应用限制
    func removeAppRestriction(for application: Application) {
        guard isAuthorized else {
            print("📱 未授权，无法移除应用限制")
            return
        }

        var blockedApps = managedSettingsStore.application.blockedApplications ?? Set()
        blockedApps.remove(application)
        managedSettingsStore.application.blockedApplications = blockedApps

        print("📱 已移除应用限制")
    }
    
    /// 清除所有限制
    func clearAllRestrictions() {
        guard isAuthorized else {
            print("📱 未授权，无法清除限制")
            return
        }
        
        managedSettingsStore.clearAllSettings()
        print("📱 已清除所有应用限制")
    }
    
    // MARK: - 辅助方法
    
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
    
    /// 获取应用今日使用时间
    func getAppUsageTime(for appName: String) -> TimeInterval {
        return TimeInterval(appUsageData.first { $0.appName == appName }?.usageTime ?? 0)
    }
    
    /// 刷新数据
    func refreshData() {
        Task {
            await loadScreenTimeData()
        }
    }
}

// MARK: - 扩展：错误处理

extension ScreenTimeManager {
    enum ScreenTimeError: LocalizedError {
        case notAuthorized
        case dataLoadFailed(String)
        case restrictionFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "需要Screen Time权限"
            case .dataLoadFailed(let message):
                return "数据加载失败: \(message)"
            case .restrictionFailed(let message):
                return "设置限制失败: \(message)"
            }
        }
    }
}
