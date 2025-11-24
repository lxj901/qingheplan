import Foundation
import Combine

/// 认证服务类，处理用户登录、注册和认证相关功能
class AuthService: ObservableObject {
    static let shared = AuthService()

    private let networkManager = NetworkManager.shared
    private let authManager = AuthManager.shared

    private init() {}

    // MARK: - 计算属性

    /// 检查是否已登录
    var isLoggedIn: Bool {
        return authManager.isLoggedIn()
    }

    // MARK: - 发送验证码

    /// 发送短信验证码 (async/await 版本)
    /// - Parameter phone: 手机号
    /// - Returns: 发送结果
    func sendVerificationCode(phone: String) async throws -> (success: Bool, message: String) {
        print("📱 开始发送验证码到: \(phone)")

        let parameters = ["phone": phone]

        do {
            let response = try await networkManager.request(
                endpoint: APIEndpoints.sendSMS,
                method: .POST,
                parameters: parameters,
                responseType: QingheResponse<QingheSMSData>.self
            )

            if response.success {
                print("✅ 验证码发送成功")
                return (success: true, message: response.displayMessage)
            } else {
                print("❌ 验证码发送失败: \(response.displayMessage)")
                return (success: false, message: response.displayMessage)
            }
        } catch {
            print("❌ 发送验证码网络错误: \(error.localizedDescription)")

            // 特殊处理频率限制错误
            if let networkError = error as? NetworkManager.NetworkError {
                switch networkError {
                case .rateLimitExceeded:
                    throw NSError(domain: "AuthService", code: 429, userInfo: [
                        NSLocalizedDescriptionKey: "发送过于频繁，请1分钟后再试"
                    ])
                case .serverMessage(let message):
                    throw NSError(domain: "AuthService", code: 400, userInfo: [
                        NSLocalizedDescriptionKey: message
                    ])
                default:
                    throw error
                }
            }

            throw error
        }
    }

    /// 发送短信验证码 (回调版本)
    /// - Parameters:
    ///   - phone: 手机号
    ///   - completion: 完成回调
    func sendVerificationCode(phone: String, completion: @escaping (Bool, String) -> Void) {
        Task {
            do {
                let result = try await sendVerificationCode(phone: phone)
                await MainActor.run {
                    completion(result.success, result.message)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    // MARK: - 用户登录

    /// 用户登录 (async/await 版本)
    /// - Parameters:
    ///   - phone: 手机号
    ///   - code: 验证码
    /// - Returns: 登录结果
    func login(phone: String, code: String) async throws -> (success: Bool, message: String, userData: [String: Any]?) {
        print("🔐 开始用户登录: \(phone)")

        let parameters = [
            "phone": phone,
            "code": code
        ]

        do {
            let response = try await networkManager.request(
                endpoint: APIEndpoints.loginSMS,
                method: .POST,
                parameters: parameters,
                responseType: QingheResponse<QingheLoginData>.self
            )

            if response.success, let data = response.data {
                // 保存认证信息
                authManager.saveAuthInfo(
                    token: data.token,
                    user: data.user,
                    expiresIn: data.expiresIn
                )

                print("✅ 用户登录成功，用户ID: \(data.user.id)")

                // 构建用户数据字典
                let userData: [String: Any] = [
                    "id": data.user.id,
                    "phone": data.user.phone ?? "",
                    "nickname": data.user.nickname ?? "",
                    "token": data.token
                ]

                return (success: true, message: response.displayMessage, userData: userData)
            } else {
                print("❌ 用户登录失败: \(response.displayMessage)")
                return (success: false, message: response.displayMessage, userData: nil)
            }
        } catch {
            print("❌ 登录网络错误: \(error.localizedDescription)")
            throw error
        }
    }

    /// 用户登录 (回调版本)
    /// - Parameters:
    ///   - phone: 手机号
    ///   - code: 验证码
    ///   - completion: 完成回调
    func login(phone: String, code: String, completion: @escaping (Bool, String, [String: Any]?) -> Void) {
        Task {
            do {
                let result = try await login(phone: phone, code: code)
                await MainActor.run {
                    completion(result.success, result.message, result.userData)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription, nil)
                }
            }
        }
    }

    // MARK: - Token 验证

    /// Token 验证
    /// - Parameters:
    ///   - token: 要验证的 token
    ///   - completion: 完成回调
    func verifyToken(token: String, completion: @escaping (Bool, String, [String: Any]?) -> Void) {
        Task {
            do {
                let parameters = ["token": token]

                let response = try await networkManager.request(
                    endpoint: APIEndpoints.getCurrentUser,
                    method: .POST,
                    parameters: parameters,
                    responseType: QingheResponse<QingheUserData>.self
                )

                await MainActor.run {
                    if response.success, let data = response.data {
                        let userData: [String: Any] = [
                            "id": data.user.id,
                            "phone": data.user.phone ?? "",
                            "nickname": data.user.nickname ?? ""
                        ]
                        completion(true, response.displayMessage, userData)
                    } else {
                        completion(false, response.displayMessage, nil)
                    }
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription, nil)
                }
            }
        }
    }


    // MARK: - 用户登出

    /// 用户登出
    /// - Parameters:
    ///   - token: 用户 token
    ///   - userId: 用户 ID
    ///   - completion: 完成回调
    func logout(token: String, userId: String, completion: @escaping (Bool, String) -> Void) {
        Task {
            do {
                let parameters = [
                    "token": token,
                    "userId": userId
                ]

                let response = try await networkManager.request(
                    endpoint: APIEndpoints.logout,
                    method: .POST,
                    parameters: parameters,
                    responseType: QingheResponse<QingheLogoutData>.self
                )

                // 无论服务器响应如何，都清除本地认证信息
                authManager.logout()

                await MainActor.run {
                    completion(response.success, response.displayMessage)
                }
            } catch {
                // 即使网络错误，也清除本地认证信息
                authManager.logout()

                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    /// 简单登出（只清除本地数据）
    func logout() {
        authManager.logout()
        print("🔐 用户已登出")
    }

    // MARK: - 便捷方法

    /// 获取当前用户信息
    func getCurrentUser() -> AuthUser? {
        return authManager.getUserInfo()
    }

    /// 获取当前用户 ID
    func getCurrentUserId() -> Int? {
        return authManager.getCurrentUserId()
    }

    /// 获取当前 Token
    func getCurrentToken() -> String? {
        return authManager.getToken()
    }

    /// 验证当前认证状态
    func validateAuthState() -> Bool {
        return authManager.validateAuthState()
    }

    // MARK: - 苹果登录

    /// 苹果登录
    /// - Parameters:
    ///   - identityToken: Apple Identity Token
    ///   - authorizationCode: Apple Authorization Code (可选)
    ///   - userInfo: 用户信息 (可选，首次登录时提供)
    ///   - completion: 完成回调
    func loginWithApple(
        identityToken: String,
        authorizationCode: String? = nil,
        userInfo: [String: Any]? = nil,
        completion: @escaping (Bool, String, [String: Any]?) -> Void
    ) {
        Task {
            do {
                var parameters: [String: Any] = [
                    "identityToken": identityToken
                ]

                if let authorizationCode = authorizationCode {
                    parameters["authorizationCode"] = authorizationCode
                }

                if let userInfo = userInfo {
                    parameters["user"] = userInfo
                }

                print("🍎 开始苹果登录，参数: \(parameters)")

                let response = try await networkManager.request(
                    endpoint: APIEndpoints.loginApple,
                    method: .POST,
                    parameters: parameters,
                    responseType: QingheResponse<QingheLoginData>.self
                )

                await MainActor.run {
                    if response.success, let data = response.data {
                        // 保存认证信息
                        authManager.saveAuthInfo(
                            token: data.token,
                            user: data.user,
                            expiresIn: data.expiresIn
                        )

                        print("✅ 苹果登录成功，用户ID: \(data.user.id)")

                        let userData: [String: Any] = [
                            "id": data.user.id,
                            "phone": data.user.phone ?? "",
                            "nickname": data.user.nickname ?? "",
                            "email": data.user.email ?? "",
                            "token": data.token
                        ]

                        completion(true, response.displayMessage, userData)
                    } else {
                        print("❌ 苹果登录失败: \(response.displayMessage)")
                        completion(false, response.displayMessage, nil)
                    }
                }
            } catch {
                print("❌ 苹果登录网络错误: \(error.localizedDescription)")
                await MainActor.run {
                    completion(false, error.localizedDescription, nil)
                }
            }
        }
    }

    // MARK: - 密码登录

    /// 密码登录
    /// - Parameters:
    ///   - phone: 手机号
    ///   - password: 密码
    ///   - completion: 完成回调
    func loginWithPassword(phone: String, password: String, completion: @escaping (Bool, String, [String: Any]?) -> Void) {
        Task {
            do {
                let parameters = [
                    "phone": phone,
                    "password": password
                ]

                print("🔐 开始密码登录: \(phone)")

                let response = try await networkManager.request(
                    endpoint: APIEndpoints.loginPassword,
                    method: .POST,
                    parameters: parameters,
                    responseType: QingheResponse<QingheLoginData>.self
                )

                await MainActor.run {
                    if response.success, let data = response.data {
                        // 保存认证信息
                        authManager.saveAuthInfo(
                            token: data.token,
                            user: data.user,
                            expiresIn: data.expiresIn
                        )

                        print("✅ 密码登录成功，用户ID: \(data.user.id)")

                        let userData: [String: Any] = [
                            "id": data.user.id,
                            "phone": data.user.phone ?? "",
                            "nickname": data.user.nickname ?? "",
                            "email": data.user.email ?? "",
                            "token": data.token
                        ]

                        completion(true, response.displayMessage, userData)
                    } else {
                        print("❌ 密码登录失败: \(response.displayMessage)")
                        completion(false, response.displayMessage, nil)
                    }
                }
            } catch {
                print("❌ 密码登录网络错误: \(error.localizedDescription)")
                await MainActor.run {
                    completion(false, error.localizedDescription, nil)
                }
            }
        }
    }

    // MARK: - 密码管理

    /// 设置密码
    /// - Parameters:
    ///   - password: 新密码
    ///   - completion: 完成回调
    func setPassword(password: String, completion: @escaping (Bool, String) -> Void) {
        Task {
            do {
                let parameters = [
                    "password": password
                ]

                print("🔐 开始设置密码")

                let response = try await networkManager.request(
                    endpoint: APIEndpoints.setPassword,
                    method: .POST,
                    parameters: parameters,
                    responseType: QingheResponse<EmptyData>.self
                )

                await MainActor.run {
                    if response.success {
                        print("✅ 密码设置成功")
                        completion(true, response.displayMessage)
                    } else {
                        print("❌ 密码设置失败: \(response.displayMessage)")
                        completion(false, response.displayMessage)
                    }
                }
            } catch {
                print("❌ 密码设置网络错误: \(error.localizedDescription)")
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    /// 修改密码
    /// - Parameters:
    ///   - oldPassword: 旧密码
    ///   - newPassword: 新密码
    ///   - completion: 完成回调
    func changePassword(oldPassword: String, newPassword: String, completion: @escaping (Bool, String) -> Void) {
        Task {
            do {
                let parameters = [
                    "oldPassword": oldPassword,
                    "newPassword": newPassword
                ]

                print("🔐 开始修改密码")

                let response = try await networkManager.request(
                    endpoint: APIEndpoints.changePassword,
                    method: .POST,
                    parameters: parameters,
                    responseType: QingheResponse<EmptyData>.self
                )

                await MainActor.run {
                    if response.success {
                        print("✅ 密码修改成功")
                        completion(true, response.displayMessage)
                    } else {
                        print("❌ 密码修改失败: \(response.displayMessage)")
                        completion(false, response.displayMessage)
                    }
                }
            } catch {
                print("❌ 密码修改网络错误: \(error.localizedDescription)")
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    // MARK: - 账户注销

    /// 发送注销验证码
    /// - Parameters:
    ///   - phone: 手机号
    ///   - completion: 完成回调
    func sendDeletionCode(phone: String, completion: @escaping (Bool, String) -> Void) {
        Task {
            do {
                let parameters = [
                    "phone": phone
                ]

                print("📱 开始发送注销验证码: \(phone)")

                let response = try await networkManager.request(
                    endpoint: APIEndpoints.sendDeletionCode,
                    method: .POST,
                    parameters: parameters,
                    responseType: QingheResponse<EmptyData>.self
                )

                await MainActor.run {
                    if response.success {
                        print("✅ 注销验证码发送成功")
                        completion(true, response.displayMessage)
                    } else {
                        print("❌ 注销验证码发送失败: \(response.displayMessage)")
                        completion(false, response.displayMessage)
                    }
                }
            } catch {
                print("❌ 发送注销验证码网络错误: \(error.localizedDescription)")
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    /// 申请账户注销
    /// - Parameters:
    ///   - code: 验证码
    ///   - completion: 完成回调
    func requestDeletion(code: String, completion: @escaping (Bool, String, [String: Any]?) -> Void) {
        Task {
            do {
                let parameters = [
                    "code": code
                ]

                print("🗑️ 开始申请账户注销")

                let response = try await networkManager.request(
                    endpoint: APIEndpoints.requestDeletion,
                    method: .POST,
                    parameters: parameters,
                    responseType: QingheResponse<DeletionRequestData>.self
                )

                await MainActor.run {
                    if response.success, let data = response.data {
                        print("✅ 账户注销申请成功")

                        let deletionData: [String: Any] = [
                            "requestedAt": data.requestedAt,
                            "scheduledAt": data.scheduledAt,
                            "remainingDays": data.remainingDays
                        ]

                        completion(true, response.displayMessage, deletionData)
                    } else {
                        print("❌ 账户注销申请失败: \(response.displayMessage)")
                        completion(false, response.displayMessage, nil)
                    }
                }
            } catch {
                print("❌ 账户注销申请网络错误: \(error.localizedDescription)")
                await MainActor.run {
                    completion(false, error.localizedDescription, nil)
                }
            }
        }
    }

    /// 查询注销状态
    /// - Parameter completion: 完成回调
    func getDeletionStatus(completion: @escaping (Bool, String, [String: Any]?) -> Void) {
        Task {
            do {
                print("🔍 查询账户注销状态")

                let response = try await networkManager.request(
                    endpoint: APIEndpoints.deletionStatus,
                    method: .GET,
                    parameters: nil,
                    responseType: QingheResponse<DeletionStatusData>.self
                )

                await MainActor.run {
                    if response.success, let data = response.data {
                        print("✅ 注销状态查询成功: \(data.status)")

                        let statusData: [String: Any] = [
                            "status": data.status
                        ]

                        completion(true, response.displayMessage, statusData)
                    } else {
                        print("❌ 注销状态查询失败: \(response.displayMessage)")
                        completion(false, response.displayMessage, nil)
                    }
                }
            } catch {
                print("❌ 注销状态查询网络错误: \(error.localizedDescription)")
                await MainActor.run {
                    completion(false, error.localizedDescription, nil)
                }
            }
        }
    }

    /// 撤销注销申请
    /// - Parameter completion: 完成回调
    func cancelDeletion(completion: @escaping (Bool, String) -> Void) {
        Task {
            do {
                print("↩️ 开始撤销注销申请")

                let response = try await networkManager.request(
                    endpoint: APIEndpoints.cancelDeletion,
                    method: .POST,
                    parameters: nil,
                    responseType: QingheResponse<EmptyData>.self
                )

                await MainActor.run {
                    if response.success {
                        print("✅ 注销申请撤销成功")
                        completion(true, response.displayMessage)
                    } else {
                        print("❌ 注销申请撤销失败: \(response.displayMessage)")
                        completion(false, response.displayMessage)
                    }
                }
            } catch {
                print("❌ 撤销注销申请网络错误: \(error.localizedDescription)")
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    // MARK: - 新增API接口

    /// 测试登录 (开发环境)
    /// - Parameters:
    ///   - phone: 手机号
    ///   - password: 测试密码
    ///   - completion: 完成回调
    func testLogin(phone: String, password: String, completion: @escaping (Bool, String, [String: Any]?) -> Void) {
        Task {
            do {
                let parameters = [
                    "phone": phone,
                    "password": password
                ]

                let response = try await networkManager.request(
                    endpoint: APIEndpoints.testLogin,
                    method: .POST,
                    parameters: parameters,
                    responseType: QingheResponse<QingheLoginData>.self
                )

                await MainActor.run {
                    if response.success, let data = response.data {
                        // 保存认证信息
                        authManager.saveAuthInfo(
                            token: data.token,
                            user: data.user,
                            expiresIn: data.expiresIn
                        )

                        let userData: [String: Any] = [
                            "id": data.user.id,
                            "phone": data.user.phone ?? "",
                            "nickname": data.user.nickname ?? "",
                            "token": data.token
                        ]

                        completion(true, response.displayMessage, userData)
                    } else {
                        completion(false, response.displayMessage, nil)
                    }
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription, nil)
                }
            }
        }
    }

    /// 获取当前用户信息
    /// - Parameter completion: 完成回调
    func getCurrentUserInfo(completion: @escaping (Bool, String, [String: Any]?) -> Void) {
        Task {
            do {
                let response = try await networkManager.request(
                    endpoint: APIEndpoints.getCurrentUser,
                    method: .GET,
                    responseType: QingheResponse<QingheUserData>.self
                )

                await MainActor.run {
                    if response.success, let data = response.data {
                        // 更新本地用户信息
                        authManager.updateUserInfo(data.user)

                        let userData: [String: Any] = [
                            "id": data.user.id,
                            "phone": data.user.phone ?? "",
                            "nickname": data.user.nickname ?? "",
                            "avatar": data.user.avatar ?? "",
                            "status": data.user.status ?? "",
                            "lastLoginTime": data.user.updatedAt ?? "",
                            "createdAt": data.user.createdAt ?? ""
                        ]

                        completion(true, response.displayMessage, userData)
                    } else {
                        completion(false, response.displayMessage, nil)
                    }
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription, nil)
                }
            }
        }
    }

    /// 更新用户资料
    /// - Parameters:
    ///   - nickname: 昵称
    ///   - avatar: 头像URL
    ///   - completion: 完成回调
    func updateUserProfile(nickname: String? = nil, avatar: String? = nil, completion: @escaping (Bool, String, [String: Any]?) -> Void) {
        Task {
            do {
                var parameters: [String: Any] = [:]
                if let nickname = nickname {
                    parameters["nickname"] = nickname
                }
                if let avatar = avatar {
                    parameters["avatar"] = avatar
                }

                let response = try await networkManager.request(
                    endpoint: APIEndpoints.updateProfile,
                    method: .PUT,
                    parameters: parameters,
                    responseType: QingheResponse<QingheUserData>.self
                )

                await MainActor.run {
                    if response.success, let data = response.data {
                        // 更新本地用户信息
                        authManager.updateUserInfo(data.user)

                        let userData: [String: Any] = [
                            "id": data.user.id,
                            "phone": data.user.phone ?? "",
                            "nickname": data.user.nickname ?? "",
                            "avatar": data.user.avatar ?? "",
                            "status": data.user.status ?? ""
                        ]

                        completion(true, response.displayMessage, userData)
                    } else {
                        completion(false, response.displayMessage, nil)
                    }
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription, nil)
                }
            }
        }
    }

    /// 刷新Token
    /// - Parameter completion: 完成回调
    func refreshToken(completion: @escaping (Bool, String) -> Void) {
        Task {
            do {
                let response = try await networkManager.request(
                    endpoint: APIEndpoints.refreshToken,
                    method: .POST,
                    responseType: QingheResponse<QingheTokenData>.self
                )

                await MainActor.run {
                    if response.success, let data = response.data {
                        // 更新Token
                        if let currentUser = authManager.getUserInfo() {
                            authManager.saveAuthInfo(
                                token: data.token,
                                user: currentUser,
                                expiresIn: data.expiresIn
                            )
                        }
                        completion(true, response.displayMessage)
                    } else {
                        completion(false, response.displayMessage)
                    }
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - 数据模型

/// 青禾统一响应格式 - 匹配API文档
struct QingheResponse<T: Codable>: Codable {
    let status: String?     // "success" 或 "error" - 可选，兼容不同响应格式
    let message: String?    // 响应消息 - 可选
    let data: T?           // 响应数据 - 可选

    // 兼容其他可能的字段名
    let error: String?     // 错误信息的另一种格式
    let msg: String?       // 消息的另一种格式

    // 自定义解码器来处理不同的响应格式
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 尝试解码status字段
        status = try container.decodeIfPresent(String.self, forKey: .status)

        // 尝试解码message字段（多种可能的字段名）
        message = try container.decodeIfPresent(String.self, forKey: .message)
        msg = try container.decodeIfPresent(String.self, forKey: .msg)
        error = try container.decodeIfPresent(String.self, forKey: .error)

        // 尝试解码data字段
        data = try container.decodeIfPresent(T.self, forKey: .data)
    }

    private enum CodingKeys: String, CodingKey {
        case status, message, data, error, msg
    }

    /// 是否成功
    var success: Bool {
        // 如果有status字段，以status为准
        if let status = status {
            return status == "success"
        }
        // 如果没有status字段，根据是否有错误信息判断
        return error == nil
    }

    /// 显示消息
    var displayMessage: String {
        // 优先使用message，然后是error，最后是msg
        return message ?? error ?? msg ?? "未知错误"
    }
}

/// 短信发送响应数据 - 匹配API文档
struct QingheSMSData: Codable {
    let phone: String
    let requestId: String?
    let code: String?       // 仅开发环境返回
}

/// 登录响应数据
struct QingheLoginData: Codable {
    let token: String
    let user: AuthUser
    let expiresIn: String?
}

/// Token 响应数据
struct QingheTokenData: Codable {
    let token: String
    let expiresIn: String?
}

/// 用户数据响应
struct QingheUserData: Codable {
    let user: AuthUser
}

/// 登出响应数据
struct QingheLogoutData: Codable {
    let message: String?
}



/// 认证用户数据模型
struct AuthUser: Codable, Identifiable {
    let id: Int
    let phone: String?  // 苹果登录时可能没有phone字段，改为可选
    let nickname: String?
    let email: String?
    let avatar: String?
    let status: String?
    let createdAt: String?
    let updatedAt: String?
}
