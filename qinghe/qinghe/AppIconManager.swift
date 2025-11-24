//
//  AppIconManager.swift
//  qinghe
//
//  Created by Augment Agent on 2025-01-14.
//

import Foundation
import UIKit
import SwiftUI

/// 真实应用图标管理器
/// 使用私有 API 获取设备上已安装应用的真实图标和信息
@MainActor
class AppIconManager: ObservableObject {
    static let shared = AppIconManager()
    
    @Published var installedApps: [InstalledApp] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - 已安装应用数据模型
    
    /// 已安装应用信息
    struct InstalledApp: Identifiable, Hashable {
        let id = UUID()
        let bundleIdentifier: String
        let displayName: String
        let icon: UIImage?
        let version: String?
        let isSystemApp: Bool
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(bundleIdentifier)
        }
        
        static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
            return lhs.bundleIdentifier == rhs.bundleIdentifier
        }
    }
    
    // MARK: - 公共方法
    
    /// 获取所有已安装的应用
    func loadInstalledApps() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let apps = try await fetchInstalledApps()
                await MainActor.run {
                    self.installedApps = apps
                    self.isLoading = false
                    print("📱 [AppIconManager] 成功加载 \(apps.count) 个已安装应用（用于图标显示）")
                    if apps.isEmpty {
                        print("📱 [AppIconManager] 注意：当前无法获取已安装应用列表，将使用FamilyControls的ApplicationToken显示应用信息")
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载应用列表失败: \(error.localizedDescription)"
                    self.isLoading = false
                    print("📱 加载应用列表失败: \(error)")
                }
            }
        }
    }
    
    /// 根据 Bundle ID 获取应用图标
    func getAppIcon(for bundleIdentifier: String) -> UIImage? {
        return installedApps.first { $0.bundleIdentifier == bundleIdentifier }?.icon
    }
    
    /// 根据 Bundle ID 获取应用名称
    func getAppName(for bundleIdentifier: String) -> String? {
        return installedApps.first { $0.bundleIdentifier == bundleIdentifier }?.displayName
    }
    
    /// 检查应用是否已安装
    func isAppInstalled(_ bundleIdentifier: String) -> Bool {
        return installedApps.contains { $0.bundleIdentifier == bundleIdentifier }
    }
    
    // MARK: - 私有方法
    
    /// 获取已安装应用列表（需要实现真实的应用获取逻辑）
    private func fetchInstalledApps() async throws -> [InstalledApp] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // 当前无法获取真实的已安装应用列表
                // 需要实现真实的应用获取逻辑或使用其他方案
                let apps: [InstalledApp] = []

                continuation.resume(returning: apps)
            }
        }
    }
    

    
    /// 获取应用图标（暂时返回 nil，使用降级方案）
    private func getApplicationIcon(bundleIdentifier: String) -> UIImage? {
        // 暂时禁用私有 API 调用，因为在 Swift 中实现比较复杂
        // 在实际部署时，可以考虑使用 Objective-C 桥接或其他方案
        print("📱 暂时无法获取 \(bundleIdentifier) 的真实图标，将使用降级方案")
        return nil
    }
    

}

// MARK: - 错误类型

enum AppIconError: Error, LocalizedError {
    case privateAPINotAvailable
    case workspaceNotAvailable
    case applicationListNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .privateAPINotAvailable:
            return "私有 API 不可用"
        case .workspaceNotAvailable:
            return "无法获取应用工作空间"
        case .applicationListNotAvailable:
            return "无法获取应用列表"
        }
    }
}

// MARK: - SwiftUI 扩展

extension AppIconManager.InstalledApp {
    /// 转换为 SwiftUI Image
    var swiftUIImage: Image? {
        guard let icon = icon else { return nil }
        return Image(uiImage: icon)
    }
}
