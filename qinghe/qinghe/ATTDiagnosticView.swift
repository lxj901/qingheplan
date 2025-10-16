import SwiftUI
import AppTrackingTransparency
import AdSupport

/// ATT 诊断视图 - 用于诊断为什么 ATT 弹窗不显示
struct ATTDiagnosticView: View {
    @StateObject private var attManager = ATTrackingPermissionManager.shared
    @State private var diagnosticInfo: [String] = []
    @State private var isRunningDiagnostic = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 当前状态
                    statusSection
                    
                    // 诊断按钮
                    Button(action: runDiagnostic) {
                        HStack {
                            Image(systemName: "stethoscope")
                            Text(isRunningDiagnostic ? "诊断中..." : "运行完整诊断")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isRunningDiagnostic)
                    
                    // 请求权限按钮
                    Button(action: requestPermission) {
                        HStack {
                            Image(systemName: "hand.raised")
                            Text("请求 ATT 权限")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // 重置状态按钮
                    Button(action: resetStatus) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重置请求状态")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // 打开设置按钮
                    Button(action: openSettings) {
                        HStack {
                            Image(systemName: "gear")
                            Text("打开系统设置")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // 诊断信息
                    if !diagnosticInfo.isEmpty {
                        diagnosticSection
                    }
                }
                .padding()
            }
            .navigationTitle("ATT 权限诊断")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Views
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("当前状态")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ATTInfoRow(title: "iOS 版本", value: UIDevice.current.systemVersion)
                ATTInfoRow(title: "设备型号", value: UIDevice.current.model)
                ATTInfoRow(title: "授权状态", value: attManager.statusDescription)
                ATTInfoRow(title: "状态码", value: "\(attManager.trackingStatus.rawValue)")
                ATTInfoRow(title: "已请求过", value: attManager.hasRequestedPermission ? "是" : "否")
                ATTInfoRow(title: "IDFA", value: attManager.idfaString)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private var diagnosticSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("诊断结果")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 5) {
                ForEach(diagnosticInfo, id: \.self) { info in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(info)
                            .font(.system(.body, design: .monospaced))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Actions
    
    private func runDiagnostic() {
        isRunningDiagnostic = true
        diagnosticInfo.removeAll()
        
        Task {
            await performDiagnostic()
            await MainActor.run {
                isRunningDiagnostic = false
            }
        }
    }
    
    private func performDiagnostic() async {
        var info: [String] = []
        
        // 1. 检查 iOS 版本
        let version = UIDevice.current.systemVersion
        let versionComponents = version.split(separator: ".").compactMap { Int($0) }
        if let major = versionComponents.first, let minor = versionComponents.dropFirst().first {
            if major > 14 || (major == 14 && minor >= 5) {
                info.append("✅ iOS 版本 \(version) 支持 ATT")
            } else {
                info.append("❌ iOS 版本 \(version) 不支持 ATT（需要 14.5+）")
            }
        }
        
        // 2. 检查 Info.plist 配置
        if let usageDescription = Bundle.main.object(forInfoDictionaryKey: "NSUserTrackingUsageDescription") as? String {
            info.append("✅ Info.plist 已配置 NSUserTrackingUsageDescription")
            info.append("   描述: \(usageDescription)")
        } else {
            info.append("❌ Info.plist 未配置 NSUserTrackingUsageDescription")
        }
        
        // 3. 检查当前授权状态
        let status = ATTrackingManager.trackingAuthorizationStatus
        info.append("📊 当前授权状态: \(status.rawValue)")
        switch status {
        case .notDetermined:
            info.append("   ✅ 未确定 - 可以请求权限")
        case .restricted:
            info.append("   ⚠️ 受限制 - 可能原因:")
            info.append("      • 设备管理策略限制")
            info.append("      • 儿童账户限制")
            info.append("      • 地区限制")
            info.append("      • 企业设备管理")
        case .denied:
            info.append("   ⚠️ 已拒绝 - 用户之前拒绝了权限")
            info.append("      需要在设置中手动开启")
        case .authorized:
            info.append("   ✅ 已授权")
        @unknown default:
            info.append("   ❓ 未知状态")
        }
        
        // 4. 检查是否在模拟器上
        #if targetEnvironment(simulator)
        info.append("⚠️ 当前在模拟器上运行")
        info.append("   模拟器可能不会显示 ATT 弹窗")
        info.append("   建议在真机上测试")
        #else
        info.append("✅ 当前在真机上运行")
        #endif
        
        // 5. 检查设备限制
        info.append("📱 检查设备限制:")
        info.append("   请在设置中检查:")
        info.append("   设置 > 隐私与安全性 > 跟踪")
        info.append("   确保「允许 App 请求跟踪」已开启")
        
        // 6. 检查是否已请求过
        if attManager.hasRequestedPermission {
            info.append("⚠️ 已经请求过权限")
            info.append("   如需重新测试，请:")
            info.append("   1. 点击「重置请求状态」按钮")
            info.append("   2. 删除应用并重新安装")
            info.append("   3. 或在设置中重置隐私设置")
        } else {
            info.append("✅ 尚未请求过权限")
        }
        
        // 7. 检查 IDFA
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        if idfa == "00000000-0000-0000-0000-000000000000" {
            info.append("⚠️ IDFA 为全零")
            info.append("   这通常表示:")
            info.append("   • 用户拒绝了跟踪")
            info.append("   • 设备限制了跟踪")
            info.append("   • 在模拟器上运行")
        } else {
            info.append("✅ IDFA: \(idfa)")
        }
        
        // 8. 建议
        info.append("")
        info.append("💡 建议:")
        if status == .notDetermined {
            info.append("   • 点击「请求 ATT 权限」按钮")
            info.append("   • 如果弹窗不显示，检查设备设置")
        } else if status == .restricted {
            info.append("   • 检查设备管理策略")
            info.append("   • 检查是否为儿童账户")
            info.append("   • 尝试在其他设备上测试")
        } else if status == .denied {
            info.append("   • 点击「打开系统设置」")
            info.append("   • 在设置中手动开启跟踪权限")
        }
        
        await MainActor.run {
            diagnosticInfo = info
        }
    }
    
    private func requestPermission() {
        Task {
            print("📊 手动请求 ATT 权限...")
            let authorized = await attManager.requestTrackingPermission()
            print("📊 请求结果: \(authorized ? "已授权" : "未授权")")
            
            // 重新运行诊断
            await performDiagnostic()
        }
    }
    
    private func resetStatus() {
        attManager.resetRequestStatus()
        diagnosticInfo.removeAll()
        print("📊 已重置请求状态")
    }
    
    private func openSettings() {
        attManager.openSettings()
    }
}

// MARK: - Helper Views

struct ATTInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ATTDiagnosticView()
}

