import SwiftUI
import AppTrackingTransparency

/// ATT 调试视图 - 用于测试广告追踪权限
struct ATTDebugView: View {
    @StateObject private var attManager = ATTrackingPermissionManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("ATT 权限调试")
                .font(.title)
                .padding()

            VStack(alignment: .leading, spacing: 10) {
                Text("iOS 版本: \(UIDevice.current.systemVersion)")
                Text("当前状态: \(attManager.statusDescription)")
                Text("已请求过: \(attManager.hasRequestedPermission ? "是" : "否")")
                Text("IDFA: \(attManager.idfaString)")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            Button(action: {
                Task {
                    print("📊 手动请求 ATT 权限...")
                    let authorized = await attManager.requestTrackingPermission()
                    print("📊 请求结果: \(authorized ? "已授权" : "未授权")")
                }
            }) {
                Text("请求 ATT 权限")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            Button(action: {
                attManager.resetRequestStatus()
            }) {
                Text("重置请求状态")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(10)
            }

            Button(action: {
                attManager.openSettings()
            }) {
                Text("打开系统设置")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ATTDebugView()
}
