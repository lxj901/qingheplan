import Foundation
import UIKit
import AppTrackingTransparency
import AdSupport

/// App Tracking Transparency (ATT) 权限管理器
/// 用于请求和管理广告追踪权限（IDFA）
class ATTrackingPermissionManager: ObservableObject {
    static let shared = ATTrackingPermissionManager()
    
    @Published var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    @Published var hasRequestedPermission = false

    private let userDefaults = UserDefaults.standard
    private let hasRequestedKey = "ATT_HasRequested"

    private init() {
        // 检查当前追踪状态
        checkTrackingStatus()

        // 检查是否已经请求过权限
        hasRequestedPermission = userDefaults.bool(forKey: hasRequestedKey)
    }
    
    /// 检查当前追踪授权状态
    func checkTrackingStatus() {
        trackingStatus = ATTrackingManager.trackingAuthorizationStatus
        print("📊 ATT 当前状态: \(statusDescription)")
    }
    
    /// 请求追踪权限
    /// - Returns: 是否授权
    @MainActor
    func requestTrackingPermission() async -> Bool {
        print("📊 ========== ATT 权限诊断 ==========")
        print("📊 设备信息: \(UIDevice.current.model)")
        print("📊 iOS 版本: \(UIDevice.current.systemVersion)")
        print("📊 当前状态: \(trackingStatus.rawValue) - \(statusDescription)")
        print("📊 是否已请求过: \(hasRequestedPermission)")

        // 检查 Info.plist 配置
        if let usageDescription = Bundle.main.object(forInfoDictionaryKey: "NSUserTrackingUsageDescription") as? String {
            print("📊 Info.plist 配置: ✅ 已配置")
            print("📊 描述文本: \(usageDescription)")
        } else {
            print("📊 Info.plist 配置: ❌ 未配置 NSUserTrackingUsageDescription")
        }

        // iOS 14.5+ 才需要请求 ATT 权限
        guard #available(iOS 14.5, *) else {
            print("📊 ⚠️ iOS 版本低于 14.5，无需请求权限")
            return true
        }

        // 检查状态
        switch trackingStatus {
        case .notDetermined:
            print("📊 ✅ 状态为未确定，可以请求权限")
        case .restricted:
            print("📊 ⚠️ 状态为受限制 - 可能是设备管理策略、儿童账户或地区限制")
            markAsRequested()
            return false
        case .denied:
            print("📊 ⚠️ 状态为已拒绝 - 用户之前拒绝了权限")
            markAsRequested()
            return false
        case .authorized:
            print("📊 ✅ 状态为已授权")
            markAsRequested()
            return true
        @unknown default:
            print("📊 ❓ 未知状态")
            return false
        }

        print("📊 🚀 准备显示 ATT 权限弹窗...")

        // 确保在 App 处于前台活跃状态时再请求，避免系统忽略弹窗
        var waitLoops = 0
        while UIApplication.shared.applicationState != .active && waitLoops < 25 {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            waitLoops += 1
        }

        print("📊 开始调用 ATTrackingManager.requestTrackingAuthorization()...")
        // 请求权限
        let status = await ATTrackingManager.requestTrackingAuthorization()
        print("📊 ATTrackingManager.requestTrackingAuthorization() 返回: \(status.rawValue)")

        // 更新状态
        trackingStatus = status
        // 仅当状态不为 notDetermined 时才标记为已请求，避免误判
        if status != .notDetermined { markAsRequested() }

        print("📊 ========================================")
        print("📊 权限请求完成!")
        print("📊 最终状态: \(status.rawValue) - \(statusDescription)")
        print("📊 IDFA: \(idfaString)")
        print("📊 ========================================")

        return status == .authorized
    }
    
    /// 标记为已请求
    private func markAsRequested() {
        hasRequestedPermission = true
        userDefaults.set(true, forKey: hasRequestedKey)
    }
    
    /// 获取 IDFA（广告标识符）
    var idfaString: String {
        guard trackingStatus == .authorized else {
            return "00000000-0000-0000-0000-000000000000"
        }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    /// 是否已授权追踪
    var isAuthorized: Bool {
        return trackingStatus == .authorized
    }
    
    /// 状态描述
    var statusDescription: String {
        switch trackingStatus {
        case .notDetermined:
            return "未确定"
        case .restricted:
            return "受限制"
        case .denied:
            return "已拒绝"
        case .authorized:
            return "已授权"
        @unknown default:
            return "未知状态"
        }
    }
    
    /// 打开系统设置页面
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    /// 重置请求状态（仅用于测试）
    func resetRequestStatus() {
        hasRequestedPermission = false
        userDefaults.removeObject(forKey: hasRequestedKey)
        checkTrackingStatus()
        print("📊 ATT 已重置请求状态")
    }
}

