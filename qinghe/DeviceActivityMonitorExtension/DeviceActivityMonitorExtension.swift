import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

/// DeviceActivityMonitor 扩展：系统级监控自律时间并在后台触发应用拦截
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    private let managedSettingsStore = ManagedSettingsStore()
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        print("📱 [扩展] 监控区间开始: \(activity)")
        
        // 如果是自律时间拦截活动，立即执行拦截
        if activity == DeviceActivityName("selfdiscipline_block_once") {
            executeApplicationBlocking()
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        print("📱 [扩展] 监控区间结束: \(activity)")
        
        // 自律时间结束，解除拦截
        if activity == DeviceActivityName("selfdiscipline_block_once") {
            clearApplicationBlocking()
        }
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        print("📱 [扩展] 事件阈值触发: \(event) for \(activity)")
        
        // 可用于基于使用时长的拦截（暂不实现）
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        
        print("📱 [扩展] 监控区间即将开始警告: \(activity)")
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        
        print("📱 [扩展] 监控区间即将结束警告: \(activity)")
    }
    
    // MARK: - 私有方法
    
    /// 执行应用拦截：从 App Group 读取已选择的应用并进行屏蔽
    private func executeApplicationBlocking() {
        print("📱 [扩展] 开始执行应用拦截")
        
        guard let suite = UserDefaults(suiteName: "group.com.qinghe.qinghe") else {
            print("📱 [扩展] 错误：无法访问 App Group")
            return
        }
        
        guard let savedAppsData = suite.data(forKey: "selected_applications_for_restriction") else {
            print("📱 [扩展] 警告：App Group 中没有找到已选择的应用数据")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let savedApps = try decoder.decode([SavedApplication].self, from: savedAppsData)
            
            print("📱 [扩展] 从 App Group 读取到 \(savedApps.count) 个应用")
            
            // 将 SavedApplication 转换为 Application 对象
            var applicationsToBlock: Set<Application> = []
            
            for savedApp in savedApps {
                if let tokenData = savedApp.applicationToken {
                    do {
                        let application = try Application(token: ApplicationToken(from: tokenData))
                        applicationsToBlock.insert(application)
                        print("📱 [扩展] 准备拦截应用: \(savedApp.displayName ?? "未知应用")")
                    } catch {
                        print("📱 [扩展] 无法从 token 创建应用对象: \(error)")
                    }
                }
            }
            
            if !applicationsToBlock.isEmpty {
                // 执行拦截
                managedSettingsStore.application.blockedApplications = applicationsToBlock
                print("📱 [扩展] 已拦截 \(applicationsToBlock.count) 个应用")
            } else {
                print("📱 [扩展] 警告：没有有效的应用可以拦截")
            }
            
        } catch {
            print("📱 [扩展] 解析应用数据失败: \(error)")
        }
    }
    
    /// 清除应用拦截
    private func clearApplicationBlocking() {
        print("📱 [扩展] 清除应用拦截")
        managedSettingsStore.application.blockedApplications = Set<Application>()
    }
}

// MARK: - 数据模型（与主 App 保持一致）

/// 保存的应用信息（用于 App Group 共享）
struct SavedApplication: Codable {
    let displayName: String?
    let bundleIdentifier: String?
    let applicationToken: Data?
    
    init(displayName: String?, bundleIdentifier: String?, applicationToken: Data?) {
        self.displayName = displayName
        self.bundleIdentifier = bundleIdentifier
        self.applicationToken = applicationToken
    }
}
