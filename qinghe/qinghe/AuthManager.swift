import Foundation

/// 认证管理器，处理用户认证状态和Token管理
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    // UserDefaults 键
    private let tokenKey = "auth_token"
    private let userKey = "auth_user"
    private let expirationKey = "auth_expiration"
    private let userIdKey = "auth_user_id"
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: AuthUser?
    
    private init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - 认证状态管理
    
    /// 检查认证状态
    func checkAuthenticationStatus() {
        if let _ = getToken(), !isTokenExpired() {
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.currentUser = self.getUserInfo()
            }
            print("🔐 用户已认证")
        } else {
            logout()
            print("🔐 用户未认证或Token已过期")
        }
    }
    
    /// 验证认证状态
    func validateAuthState() -> Bool {
        return isAuthenticated && getToken() != nil && !isTokenExpired()
    }
    
    /// 检查是否已登录
    func isLoggedIn() -> Bool {
        return isAuthenticated && getToken() != nil
    }
    
    // MARK: - Token管理
    
    /// 保存认证信息
    /// - Parameters:
    ///   - token: 认证Token
    ///   - user: 用户信息
    ///   - expiresIn: 过期时间（可选）
    func saveAuthInfo(token: String, user: AuthUser, expiresIn: String? = nil) {
        // 保存Token
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        // 保存用户信息
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
        
        // 保存用户ID
        UserDefaults.standard.set(user.id, forKey: userIdKey)
        
        // 计算并保存过期时间
        if let expiresIn = expiresIn {
            let expirationDate = calculateExpirationDate(from: expiresIn)
            UserDefaults.standard.set(expirationDate, forKey: expirationKey)
        } else {
            // 默认7天后过期
            let expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
            UserDefaults.standard.set(expirationDate, forKey: expirationKey)
        }
        
        // 更新状态 - 确保在主线程更新 UI
        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.currentUser = user

            // 登录成功后自动连接WebSocket并更新角标
            Task {
                await WebSocketManager.shared.connect()
                await PushNotificationManager.shared.updateBadgeCount()
            }
        }

        print("🔐 认证信息已保存，用户ID: \(user.id)")
    }
    
    /// 获取Token
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    /// 获取用户信息
    func getUserInfo() -> AuthUser? {
        guard let userData = UserDefaults.standard.data(forKey: userKey) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(AuthUser.self, from: userData)
        } catch {
            print("❌ 用户信息解析失败: \(error)")
            return nil
        }
    }
    
    /// 获取当前用户ID
    func getCurrentUserId() -> Int? {
        return UserDefaults.standard.object(forKey: userIdKey) as? Int
    }
    
    /// 用户登出
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: expirationKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)

        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil

            // 登出时断开WebSocket连接
            Task {
                await WebSocketManager.shared.disconnect()
            }
        }

        print("🔐 用户已登出，认证信息已清除")
    }
    
    // MARK: - Token过期检查
    
    /// 检查Token是否过期
    private func isTokenExpired() -> Bool {
        guard let expirationDate = UserDefaults.standard.object(forKey: expirationKey) as? Date else {
            // 如果没有过期时间信息，假设已过期
            return true
        }
        
        return Date() > expirationDate
    }
    
    /// 根据过期时间字符串计算过期日期
    private func calculateExpirationDate(from expiresIn: String) -> Date {
        // 支持格式：
        // "7d" (7天)
        // "24h" (24小时)
        // "3600s" (3600秒)
        // "30m" (30分钟)

        // 🔥 修复：检查字符串长度，避免索引越界
        guard !expiresIn.isEmpty, expiresIn.count >= 2 else {
            // 如果字符串为空或长度不足，默认7天后过期
            print("⚠️ 过期时间字符串无效: '\(expiresIn)'，使用默认7天")
            return Date().addingTimeInterval(7 * 24 * 60 * 60)
        }

        let timeValue = String(expiresIn.dropLast())
        let timeUnit = String(expiresIn.suffix(1))

        guard let value = Double(timeValue) else {
            // 如果解析失败，默认7天后过期
            print("⚠️ 无法解析时间值: '\(timeValue)'，使用默认7天")
            return Date().addingTimeInterval(7 * 24 * 60 * 60)
        }
        
        var timeInterval: TimeInterval
        switch timeUnit.lowercased() {
        case "s": // 秒
            timeInterval = value
        case "m": // 分钟
            timeInterval = value * 60
        case "h": // 小时
            timeInterval = value * 60 * 60
        case "d": // 天
            timeInterval = value * 24 * 60 * 60
        default:
            // 默认按秒处理
            timeInterval = value
        }
        
        return Date().addingTimeInterval(timeInterval)
    }
    
    // MARK: - 便捷方法
    
    /// 更新用户信息
    func updateUserInfo(_ user: AuthUser) {
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
            DispatchQueue.main.async {
                self.currentUser = user
            }
            print("🔐 用户信息已更新")
        }
    }
    
    /// 获取认证头
    func getAuthHeader() -> [String: String]? {
        guard let token = getToken() else {
            return nil
        }
        return ["Authorization": "Bearer \(token)"]
    }
    
    /// 检查Token是否即将过期（1小时内）
    func isTokenExpiringSoon() -> Bool {
        guard let expirationDate = UserDefaults.standard.object(forKey: expirationKey) as? Date else {
            return true
        }
        
        let oneHourFromNow = Date().addingTimeInterval(60 * 60)
        return expirationDate <= oneHourFromNow
    }
}
