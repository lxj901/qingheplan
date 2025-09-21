import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // 检查是否是我们的自律拦截活动
        if activity == DeviceActivityName("selfdiscipline_block_once") {
            executeApplicationBlocking()
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // 自律时间结束，清除拦截
        if activity == DeviceActivityName("selfdiscipline_block_once") {
            clearApplicationBlocking()
        }
    }

    private func executeApplicationBlocking() {
        // 从 App Group 读取已选择的应用 tokens
        guard let suite = UserDefaults(suiteName: "group.com.qinghe.qinghe"),
              let savedAppsData = suite.data(forKey: "selected_applications_for_restriction") else {
            return
        }

        do {
            // 反序列化应用 tokens
            let applicationsToBlock = try NSKeyedUnarchiver.unarchivedObject(ofClass: FamilyActivitySelection.self, from: savedAppsData)

            if let selection = applicationsToBlock {
                // 使用 ManagedSettings 屏蔽应用
                let managedSettingsStore = ManagedSettingsStore()
                managedSettingsStore.application.blockedApplications = selection.applicationTokens
                managedSettingsStore.applicationCategory.blockedApplicationCategories = selection.categoryTokens
            }
        } catch {
            // 处理反序列化错误
            print("Failed to unarchive applications: \(error)")
        }
    }

    private func clearApplicationBlocking() {
        // 清除所有应用拦截
        let managedSettingsStore = ManagedSettingsStore()
        managedSettingsStore.application.blockedApplications = Set()
        managedSettingsStore.applicationCategory.blockedApplicationCategories = Set()
    }
}