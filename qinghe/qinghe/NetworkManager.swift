import Foundation
import UIKit

/// 网络请求管理器
class NetworkManager {
    static let shared = NetworkManager()
    
    let baseURL = "https://api.qinghejihua.com.cn/api/v1" // 青禾计划API地址
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60  // 增加到60秒，因为AI分析可能需要更长时间
        config.timeoutIntervalForResource = 120 // 增加到120秒
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true

        // 添加网络诊断
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        self.session = URLSession(configuration: config)

        // 测试网络连接
        testNetworkConnectivity()
    }

    /// 测试网络连接
    private func testNetworkConnectivity() {
        Task {
            do {
                // 测试基本的网络连接
                let testURL = URL(string: "https://www.apple.com")!
                let (_, response) = try await URLSession.shared.data(from: testURL)
                if let httpResponse = response as? HTTPURLResponse {
                    print("🌐 网络连接测试成功，状态码: \(httpResponse.statusCode)")
                }
            } catch {
                print("🌐 网络连接测试失败: \(error)")
                print("🌐 错误详情: \(error.localizedDescription)")
                if let urlError = error as? URLError {
                    print("🌐 URLError代码: \(urlError.code.rawValue)")
                    print("🌐 URLError描述: \(urlError.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - HTTP方法枚举
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
        case PATCH = "PATCH"
    }
    
    // MARK: - 网络错误
    enum NetworkError: Error, LocalizedError {
        case invalidURL
        case noData
        case decodingError
        case serverError(Int)
        case networkError(String)
        case rateLimitExceeded
        case serverMessage(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "无效的URL"
            case .noData:
                return "没有数据返回"
            case .decodingError:
                return "数据解析错误"
            case .serverError(let code):
                return "服务器错误：\(code)"
            case .networkError(let message):
                return "网络错误：\(message)"
            case .rateLimitExceeded:
                return "请求过于频繁，请稍后再试"
            case .serverMessage(let message):
                return message
            }
        }
    }
    
    // MARK: - 通用请求方法
    
    /// 发送网络请求 (async/await 版本)
    /// - Parameters:
    ///   - endpoint: API端点
    ///   - method: HTTP方法
    ///   - parameters: 请求参数
    ///   - headers: 请求头
    ///   - responseType: 响应数据类型
    /// - Returns: 解析后的响应数据
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        print("========================================")
        print("🔍 NetworkManager.request 开始")
        print("🔍 baseURL: '\(baseURL)'")
        print("🔍 endpoint: '\(endpoint)'")
        print("🔍 method: \(method)")

        let fullURL = baseURL + endpoint
        print("🔍 完整请求URL: '\(fullURL)'")
        print("🔍 URL长度: \(fullURL.count)")
        print("========================================")

        guard let url = URL(string: fullURL) else {
            print("❌ 无效的URL: \(fullURL)")
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        print("🔍 HTTP方法: \(method.rawValue)")
        
        // 设置默认请求头
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("青禾iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        // 添加自定义请求头
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 添加认证头
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 处理请求参数
        if let parameters = parameters {
            if method == .GET {
                // GET请求将参数添加到URL
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.queryItems = parameters.map { key, value in
                    URLQueryItem(name: key, value: "\(value)")
                }
                if let newURL = components?.url {
                    request.url = newURL
                    print("🔍 添加查询参数后的URL: '\(newURL.absoluteString)'")
                } else {
                    print("⚠️ 无法创建带查询参数的URL")
                }
            } else {
                // 其他请求将参数添加到请求体
                do {
                    // 使用 JSONSerialization 的 .sortedKeys 和 .prettyPrinted 选项以确保正确编码
                    let jsonData = try JSONSerialization.data(
                        withJSONObject: parameters,
                        options: [.sortedKeys, .withoutEscapingSlashes]
                    )
                    request.httpBody = jsonData
                    
                    // 打印实际发送的JSON
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("📤 实际发送的JSON: \(jsonString)")
                        print("📤 JSON字节数: \(jsonData.count)")
                    }
                } catch {
                    print("❌ 参数编码失败: \(error)")
                    throw NetworkError.networkError("参数编码失败")
                }
            }
        }
        
        // 发送请求
        do {
            let (data, response) = try await session.data(for: request)

            // 打印原始响应数据用于调试
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 服务器响应: \(responseString)")
            }

            // 检查HTTP状态码
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP状态码: \(httpResponse.statusCode)")

                // 特殊处理429错误
                if httpResponse.statusCode == 429 {
                    throw NetworkError.rateLimitExceeded
                }
                
                // 特殊处理504网关超时错误
                if httpResponse.statusCode == 504 {
                    throw NetworkError.serverMessage("服务器暂时繁忙，请稍后重试")
                }
                
                // 特殊处理502错误网关错误
                if httpResponse.statusCode == 502 {
                    throw NetworkError.serverMessage("服务器网关错误，请稍后重试")
                }
                
                // 特殊处理503服务不可用错误
                if httpResponse.statusCode == 503 {
                    throw NetworkError.serverMessage("服务暂时不可用，请稍后重试")
                }

                // 对于400错误，先尝试解析响应，让业务层处理特定的错误情况
                if httpResponse.statusCode == 400 {
                    // 尝试解析响应数据，如果解析成功就继续，让业务层处理
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        return try decoder.decode(T.self, from: data)
                    } catch {
                        // 如果解析失败，尝试提取错误消息
                        if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = errorResponse["message"] as? String {
                            print("🔍 400错误消息: \(message)")
                            throw NetworkError.serverMessage(message)
                        }
                        // 如果无法提取消息，抛出服务器错误
                        throw NetworkError.serverError(httpResponse.statusCode)
                    }
                }

                guard 200...299 ~= httpResponse.statusCode else {
                    // 对于401、403、404、500等错误，尝试解析错误消息
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 || httpResponse.statusCode == 404 || httpResponse.statusCode == 500 {
                        if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = errorResponse["message"] as? String {
                            print("🔍 \(httpResponse.statusCode)错误消息: \(message)")
                            throw NetworkError.serverMessage(message)
                        }
                    }
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
            }

            // 解析响应数据
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch let decodingError {
                print("❌ 数据解析错误: \(decodingError)")

                // 尝试解析为通用错误响应
                if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("🔍 错误响应内容: \(errorResponse)")

                    // 如果是错误响应但格式不标准，尝试构造标准格式
                    if let message = errorResponse["message"] as? String {
                        throw NetworkError.serverMessage(message)
                    }
                }

                throw NetworkError.decodingError
            }

        } catch {
            if error is NetworkError {
                throw error
            } else if let urlError = error as? URLError {
                // 特殊处理取消错误
                if urlError.code == .cancelled {
                    throw CancellationError()
                }
                throw NetworkError.networkError(urlError.localizedDescription)
            } else {
                throw NetworkError.networkError(error.localizedDescription)
            }
        }
    }
    
    /// 上传图片到健康分析服务
    /// - Parameters:
    ///   - image: 要上传的图片
    ///   - compressionQuality: 图片压缩质量 (0.0-1.0)
    /// - Returns: 图片上传响应
    func uploadHealthImage(_ image: UIImage, compressionQuality: CGFloat = 0.8) async throws -> HealthImageUploadResponse {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw NetworkError.networkError("图片数据转换失败")
        }
        
        let endpoint = APIEndpoints.uploadHealth
        let fullURL = baseURL + endpoint
        
        guard let url = URL(string: fullURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 添加认证头
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 设置multipart/form-data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 构建请求体
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"healthImage\"; filename=\"health-photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("🔍 正在上传健康分析图片...")
        print("🔍 图片大小: \(imageData.count) bytes")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // 检查HTTP状态码
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 图片上传HTTP状态码: \(httpResponse.statusCode)")
                
                guard 200...299 ~= httpResponse.statusCode else {
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorResponse["message"] as? String {
                        throw NetworkError.serverMessage(message)
                    }
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
            }
            
            // 解析响应
            let decoder = JSONDecoder()
            let uploadResponse = try decoder.decode(HealthImageUploadResponse.self, from: data)
            
            if uploadResponse.success {
                print("✅ 图片上传成功: \(uploadResponse.data.url)")
                return uploadResponse
            } else {
                throw NetworkError.serverMessage(uploadResponse.message ?? "图片上传失败")
            }
            
        } catch {
            if error is NetworkError {
                throw error
            } else if let urlError = error as? URLError {
                if urlError.code == .cancelled {
                    throw CancellationError()
                }
                throw NetworkError.networkError(urlError.localizedDescription)
            } else {
                throw NetworkError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - 便捷方法
    
    /// GET请求
    func get<T: Codable>(
        endpoint: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .GET,
            parameters: parameters,
            headers: headers,
            responseType: responseType
        )
    }
    
    /// POST请求
    func post<T: Codable>(
        endpoint: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .POST,
            parameters: parameters,
            headers: headers,
            responseType: responseType
        )
    }
    
    /// PUT请求
    func put<T: Codable>(
        endpoint: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .PUT,
            parameters: parameters,
            headers: headers,
            responseType: responseType
        )
    }
    
    /// DELETE请求
    func delete<T: Codable>(
        endpoint: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .DELETE,
            parameters: parameters,
            headers: headers,
            responseType: responseType
        )
    }
}

// MARK: - API端点
struct APIEndpoints {
    // 认证相关 - 匹配API文档
    static let sendSMS = "/auth/send-sms-code"      // 发送短信验证码
    static let loginSMS = "/auth/login-sms"         // 短信验证码登录
    static let loginPassword = "/auth/login"        // 密码登录
    static let loginApple = "/auth/login-apple"     // 苹果登录
    static let testLogin = "/auth/login"            // 测试登录
    static let getCurrentUser = "/auth/me"          // 获取当前用户信息
    static let updateProfile = "/auth/profile"      // 更新用户资料
    static let refreshToken = "/auth/refresh-token" // 刷新Token
    static let logout = "/auth/logout"              // 用户登出

    // 密码管理
    static let setPassword = "/auth/set-password"       // 设置密码
    static let changePassword = "/auth/change-password" // 修改密码

    // 账户注销
    static let sendDeletionCode = "/auth/send-deletion-code" // 发送注销验证码
    static let requestDeletion = "/auth/request-deletion"    // 申请注销
    static let deletionStatus = "/auth/deletion-status"      // 查询注销状态
    static let cancelDeletion = "/auth/cancel-deletion"      // 撤销注销

    // 健康管理相关
    static let uploadHealth = "/upload/health"           // 健康分析图片上传
    static let tongueAnalyze = "/health/tongue/analyze"  // 舌诊分析
    static let faceAnalyze = "/health/face/analyze"      // 面诊分析
    
    // 打卡相关
    static let checkin = "/checkin"
    static let checkinHistory = "/checkin/history"
    static let checkinStats = "/checkin/stats"

    // 社区相关
    static let communityPosts = "/community/posts"          // 帖子管理
    static let communityComments = "/community/comments"    // 评论管理

    // 记录中心相关
    static let temptations = "/temptations"                 // 诱惑记录管理
    static let emotions = "/emotions"                       // 情绪记录管理
    static let plans = "/plans"                             // 计划管理
    
    // 功过格相关
    static let merits = "/merits"                           // 功过记录管理
    static let meritsDaily = "/merits/daily"                // 每日记录
    static let meritsMonthly = "/merits/monthly"            // 月度汇总
    static let meritsStatistics = "/merits/statistics"      // 统计数据
    static let meritsStandard = "/merits/standard-items"    // 标准条目
    static let meritsCategories = "/merits/categories"      // 分类列表
    static let meritsLeaderboard = "/merits/leaderboard"    // 排行榜

    // 会员订阅相关
    static let membershipStatus = "/membership/status"            // 获取会员状态
    static let membershipPlans = "/membership/plans"              // 获取套餐列表
    static let membershipUsage = "/membership/usage"              // 获取使用统计
    static let membershipHistory = "/membership/history"          // 获取订阅历史
    static let membershipCancelAutoRenew = "/membership/cancel-auto-renew" // 取消自动续费

    // Apple IAP 相关
    static let appleProducts = "/apple-iap/products"             // 获取产品列表（公开）
    static let appleVerify = "/apple-iap/verify"                 // 验证收据并激活
    static let appleStatus = "/apple-iap/status"                 // 获取用户会员状态
    static let appleSubscriptions = "/apple-iap/subscriptions"   // 获取用户订阅历史
    static let appleTransactions = "/apple-iap/transactions"     // 获取交易记录
    static let appleSubscription = "/apple-iap/subscription"      // 获取订阅状态（需拼接ID）
    static let appleRefresh = "/apple-iap/refresh"               // 刷新订阅
}
