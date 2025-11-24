import SwiftUI

/// 应用程序常量
struct AppConstants {

    // MARK: - 颜色常量
    struct Colors {
        static let primaryGreen = Color(red: 0.2, green: 0.7, blue: 0.4)
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color.secondary.opacity(0.6)
        static let background = Color(.systemBackground)
        static let backgroundGray = Color(.systemGray6)
        static let cardBackground = Color(.systemBackground)
        static let borderColor = Color(.systemGray4)
        static let separatorGray = Color(.systemGray4)
        static let systemRed = Color(.systemRed)
    }

    // MARK: - 字体常量
    struct Fonts {
        static let title = Font.title
        static let headline = Font.headline
        static let body = Font.body
        static let caption = Font.caption
    }

    // MARK: - 间距常量
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }

    // MARK: - 圆角常量
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }

    // MARK: - 动画常量
    struct Animation {
        static let defaultDuration: Double = 0.3
        static let fastDuration: Double = 0.15
        static let slowDuration: Double = 0.5
    }

    // MARK: - API 配置常量
    struct API {
        // 青禾计划主 API
        static let baseURL = "https://api.qinghejihua.com.cn/api/v1"

        // DeepSeek API 配置
        struct DeepSeek {
            static let baseURL = "https://api.deepseek.com/v1"
            static let model = "deepseek-chat"
            static let maxTokens = 1200  // 🚀 减少输出长度以提高速度
            static let temperature = 0.2  // 🚀 降低温度以提高响应速度

            // API 密钥管理
            static var apiKey: String {
                return DeepSeekKeyManager.shared.getAPIKey()
            }

            // 请求配置 - 优化超时设置
            static let timeoutInterval: TimeInterval = 45  // 🚀 减少请求超时
            static let resourceTimeout: TimeInterval = 120  // 🚀 减少资源超时

            // 缓存配置
            static let cacheExpirationTime: TimeInterval = 3600  // 1小时缓存
            static let maxAudioEventsInPrompt = 10  // 🚀 限制音频事件数量
        }
    }

    // MARK: - App Group（供扩展共享）
    struct AppGroup {
        // 注意：请在 Xcode 中创建对应的 App Group，并将主 App 与扩展都勾选同一 Group
        static let identifier = "group.com.qinghe.qinghe"
        // 扩展和主 App 共享的 key
        static let selectedApplicationsKey = "selected_applications_for_restriction"
    }


    // MARK: - 睡眠分析配置
    struct SleepAnalysis {
        static let maxAudioEvents = 1000
        static let analysisTimeout: TimeInterval = 300
        static let minSleepDuration: TimeInterval = 3600 // 1小时
        static let maxSleepDuration: TimeInterval = 43200 // 12小时

        // 质量评分阈值
        static let excellentThreshold = 85.0
        static let goodThreshold = 70.0
        static let fairThreshold = 50.0
    }
}

// MARK: - DeepSeek API 密钥管理器
class DeepSeekKeyManager {
    static let shared = DeepSeekKeyManager()

    private let keychainKey = "DeepSeekAPIKey"
    private let defaultKey = "sk-ae39254f41f44659a6d317142cd337a5"

    private init() {}

    /// 获取 API 密钥
    func getAPIKey() -> String {
        // 首先尝试从 Keychain 获取
        if let storedKey = getKeyFromKeychain() {
            return storedKey
        }

        // 如果 Keychain 中没有，使用默认密钥并保存到 Keychain
        saveKeyToKeychain(defaultKey)
        return defaultKey
    }

    /// 设置新的 API 密钥
    func setAPIKey(_ key: String) {
        saveKeyToKeychain(key)
    }

    /// 验证 API 密钥格式
    func validateAPIKey(_ key: String) -> Bool {
        return key.hasPrefix("sk-") && key.count > 10
    }

    // MARK: - Keychain 操作

    private func saveKeyToKeychain(_ key: String) {
        let data = key.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // 删除现有的条目
        SecItemDelete(query as CFDictionary)

        // 添加新的条目
        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            print("✅ DeepSeek API 密钥已安全保存到 Keychain")
        } else {
            print("❌ 保存 DeepSeek API 密钥到 Keychain 失败: \(status)")
        }
    }

    private func getKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    /// 删除存储的 API 密钥
    func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            print("✅ DeepSeek API 密钥已从 Keychain 删除")
        } else {
            print("❌ 从 Keychain 删除 DeepSeek API 密钥失败: \(status)")
        }
    }
}
