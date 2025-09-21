import SwiftUI

// MARK: - 多语言测试页面
struct LocalizationTestView: View {
    @StateObject private var localizationManager = LocalizationManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("多语言测试页面")
                    .font(.title)
                    .padding()
                
                // 语言选择器
                Picker("选择语言", selection: $localizationManager.currentLanguage) {
                    Text("简体中文").tag("zh-Hans")
                    Text("繁體中文").tag("zh-Hant")
                    Text("English").tag("en")
                    Text("日本語").tag("ja")
                    Text("한국어").tag("ko")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 测试文本
                VStack(alignment: .leading, spacing: 10) {
                    Text("测试文本:")
                        .font(.headline)
                    
                    Group {
                        Text("设置: \(localizationManager.localizedString(key: "settings"))")
                        Text("账户与安全: \(localizationManager.localizedString(key: "account_security"))")
                        Text("多语言: \(localizationManager.localizedString(key: "multi_language"))")
                        Text("清理缓存: \(localizationManager.localizedString(key: "clear_cache"))")
                        Text("退出登录: \(localizationManager.localizedString(key: "logout"))")
                        Text("加载中: \(localizationManager.localizedString(key: "loading"))")
                        Text("未登录: \(localizationManager.localizedString(key: "not_logged_in"))")
                    }
                    .font(.body)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("多语言测试")
            .onChange(of: localizationManager.currentLanguage) { newLanguage in
                localizationManager.setLanguage(newLanguage)
            }
        }
    }
}

// MARK: - 预览
#Preview {
    LocalizationTestView()
}
