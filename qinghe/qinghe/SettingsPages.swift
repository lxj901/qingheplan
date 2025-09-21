import SwiftUI

// MARK: - 清理缓存页面
struct ClearCacheView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @State private var cacheInfo: CacheInfo?
    @State private var isLoading = true
    @State private var isClearing = false
    @State private var showingClearAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            if isLoading {
                // 加载状态
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("正在计算缓存大小...")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    // 总缓存信息
                    if let cacheInfo = cacheInfo {
                        Section("缓存概览") {
                            cacheOverviewRow(cacheInfo)
                        }

                        // 详细缓存信息
                        Section("缓存详情") {
                            cacheDetailRow(
                                icon: "photo.fill",
                                iconColor: .green,
                                title: "图片缓存",
                                subtitle: "头像、帖子图片等",
                                size: cacheInfo.formattedImageCacheSize
                            )

                            cacheDetailRow(
                                icon: "waveform.circle.fill",
                                iconColor: .orange,
                                title: "音频缓存",
                                subtitle: "语音消息等",
                                size: cacheInfo.formattedAudioCacheSize
                            )

                            cacheDetailRow(
                                icon: "doc.fill",
                                iconColor: .blue,
                                title: "数据缓存",
                                subtitle: "用户信息、帖子数据等",
                                size: cacheInfo.formattedDiskCacheSize
                            )

                            cacheDetailRow(
                                icon: "memorychip.fill",
                                iconColor: .purple,
                                title: "内存缓存",
                                subtitle: "\(cacheInfo.memoryCacheCount) 个项目",
                                size: "临时数据"
                            )
                        }

                        // 清理选项
                        Section("清理选项") {
                            Button(action: {
                                showingClearAlert = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.red)
                                        .frame(width: 24, height: 24)

                                    Text("清理所有缓存")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)

                                    Spacer()

                                    if isClearing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .disabled(isClearing || cacheInfo.totalSize == 0)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .alert("清理缓存", isPresented: $showingClearAlert) {
            Button("取消", role: .cancel) { }
            Button("确认清理", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("将清理所有应用缓存，包括图片、音频、数据等临时文件。清理后可能需要重新加载部分内容。")
        }
        .onAppear {
            print("🧭 ClearCacheView onAppear - navigationPath.count = \(navigationPath.count)")
            loadCacheInfo()
        }
        .refreshable {
            loadCacheInfo()
        }
    }
    
    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("清理缓存")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 加载缓存信息
    private func loadCacheInfo() {
        isLoading = true

        Task {
            let info = await CacheManager.shared.getDetailedCacheInfo()

            await MainActor.run {
                self.cacheInfo = info
                self.isLoading = false
            }
        }
    }

    // MARK: - 清理缓存
    private func clearCache() {
        isClearing = true

        Task {
            await CacheManager.shared.clearAllCaches()

            // 清理完成后重新加载缓存信息
            let newInfo = await CacheManager.shared.getDetailedCacheInfo()

            await MainActor.run {
                self.isClearing = false
                self.cacheInfo = newInfo
                print("🗑️ 缓存清理完成")
            }
        }
    }

    // MARK: - 缓存概览行
    private func cacheOverviewRow(_ cacheInfo: CacheInfo) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "externaldrive.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("总缓存大小")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Text("包含 \(cacheInfo.diskCacheFileCount) 个文件")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(cacheInfo.formattedTotalSize)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - 缓存详情行
    private func cacheDetailRow(icon: String, iconColor: Color, title: String, subtitle: String, size: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(size)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 系统权限页面
struct SystemPermissionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar
            
            List {
                // 权限说明
                Section(footer: Text("这些权限由系统管理，需要在系统设置中修改")) {
                    ForEach(SystemPermission.allCases, id: \.self) { permission in
                        HStack(spacing: 12) {
                            Image(systemName: permission.iconName)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(permission.iconColor)
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(permission.title)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                
                                Text(permission.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(permission.status)
                                .font(.system(size: 12))
                                .foregroundColor(permission.statusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(permission.statusColor.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // 跳转到系统设置
                Section {
                    Button(action: {
                        openSystemSettings()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "gear")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            
                            Text("打开系统设置")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .onAppear {
            print("🧭 SystemPermissionsView onAppear - navigationPath.count = \(navigationPath.count)")
        }
    }
    
    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("系统权限")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 打开系统设置
    private func openSystemSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - 系统权限枚举
enum SystemPermission: CaseIterable {
    case camera
    case microphone
    case photos
    case location
    case notifications
    
    var title: String {
        switch self {
        case .camera: return "相机权限"
        case .microphone: return "麦克风权限"
        case .photos: return "相册权限"
        case .location: return "位置权限"
        case .notifications: return "通知权限"
        }
    }
    
    var description: String {
        switch self {
        case .camera: return "用于拍照和录制视频"
        case .microphone: return "用于录制语音消息"
        case .photos: return "用于选择和保存图片"
        case .location: return "用于位置分享功能"
        case .notifications: return "用于接收消息通知"
        }
    }
    
    var iconName: String {
        switch self {
        case .camera: return "camera.fill"
        case .microphone: return "mic.fill"
        case .photos: return "photo.fill"
        case .location: return "location.fill"
        case .notifications: return "bell.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .camera: return .blue
        case .microphone: return .red
        case .photos: return .green
        case .location: return .orange
        case .notifications: return .purple
        }
    }
    
    var status: String {
        // 这里可以根据实际权限状态返回
        return "已授权"
    }
    
    var statusColor: Color {
        return .green
    }
}

// MARK: - 应用权限页面
struct AppPermissionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath
    @State private var allowAnalytics = true
    @State private var allowCrashReports = true
    @State private var allowPersonalizedAds = false

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            List {
                // 数据收集
                Section("数据收集") {
                    Toggle("使用分析", isOn: $allowAnalytics)
                    Toggle("崩溃报告", isOn: $allowCrashReports)
                    Toggle("个性化广告", isOn: $allowPersonalizedAds)
                }

                // 权限说明
                Section(footer: Text("这些设置控制应用如何收集和使用您的数据")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("权限说明")
                            .font(.system(size: 16, weight: .semibold))

                        Text("• 使用分析：帮助我们改进应用性能")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Text("• 崩溃报告：帮助我们修复应用问题")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Text("• 个性化广告：根据您的兴趣显示相关广告")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            print("🧭 AppPermissionsView onAppear - navigationPath.count = \(navigationPath.count)")
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("应用权限")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - 关于应用页面
struct AboutAppView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            List {
                // 应用信息
                Section {
                    VStack(spacing: 16) {
                        // 应用图标
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        VStack(spacing: 4) {
                            Text("青禾计划")
                                .font(.system(size: 24, weight: .bold))

                            Text("版本 1.0.1 (Build 100)")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                // 应用详情
                Section("应用信息") {
                    InfoRow(title: "开发者", value: "青禾团队")
                    InfoRow(title: "发布日期", value: "2024年12月")
                    InfoRow(title: "应用大小", value: "45.2 MB")
                    InfoRow(title: "兼容性", value: "iOS 18.0 或更高版本")
                }

                // 联系方式
                Section("联系我们") {
                    InfoRow(title: "官方网站", value: "www.qinghe.com")
                    InfoRow(title: "客服邮箱", value: "support@qinghe.com")
                    InfoRow(title: "客服电话", value: "400-123-4567")
                }
            }
        }
        .onAppear {
            print("🧭 AboutAppView onAppear - navigationPath.count = \(navigationPath.count)")
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                if navigationPath.count > 0 {
                    navigationPath.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("关于青禾计划")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - 信息行组件
struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}
