import Foundation
import SwiftUI

/// 网络错误处理器，统一处理网络请求错误
class NetworkErrorHandler {
    static let shared = NetworkErrorHandler()
    
    private let feedbackManager = UserFeedbackManager.shared
    
    private init() {}
    
    // MARK: - 错误处理方法
    
    /// 处理网络错误并显示用户友好的错误信息
    /// - Parameters:
    ///   - error: 错误对象
    ///   - context: 错误上下文（可选）
    ///   - showToast: 是否显示Toast提示，默认为true
    ///   - showAlert: 是否显示Alert对话框，默认为false
    func handleError(
        _ error: Error,
        context: String? = nil,
        showToast: Bool = true,
        showAlert: Bool = false
    ) {
        let errorInfo = parseError(error)
        let message = formatErrorMessage(errorInfo, context: context)
        
        // 记录错误日志
        logError(error, context: context, errorInfo: errorInfo)
        
        // 显示用户反馈
        if showAlert {
            feedbackManager.showErrorAlert(
                title: "操作失败",
                message: message
            )
        } else if showToast {
            feedbackManager.showError(message)
        }
    }
    
    /// 处理API错误
    /// - Parameters:
    ///   - apiError: API错误
    ///   - operation: 操作名称
    ///   - showUserFeedback: 是否显示用户反馈
    func handleAPIError(
        _ apiError: APIError,
        operation: String,
        showUserFeedback: Bool = true
    ) {
        let message = getAPIErrorMessage(apiError, operation: operation)
        
        // 记录API错误
        print("🚨 API错误 - 操作: \(operation), 错误: \(message)")
        
        if showUserFeedback {
            feedbackManager.showError(message)
        }
    }
    
    /// 处理网络连接错误
    /// - Parameter showUserFeedback: 是否显示用户反馈
    func handleNetworkConnectionError(showUserFeedback: Bool = true) {
        let message = "网络连接失败，请检查网络设置"
        
        print("🚨 网络连接错误: \(message)")
        
        if showUserFeedback {
            feedbackManager.showError(message)
        }
    }
    
    /// 处理超时错误
    /// - Parameter showUserFeedback: 是否显示用户反馈
    func handleTimeoutError(showUserFeedback: Bool = true) {
        let message = "请求超时，请稍后重试"
        
        print("🚨 请求超时: \(message)")
        
        if showUserFeedback {
            feedbackManager.showError(message)
        }
    }
    
    // MARK: - 私有方法
    
    /// 解析错误信息
    private func parseError(_ error: Error) -> ErrorInfo {
        if let apiError = error as? APIError {
            return ErrorInfo(
                type: .api,
                code: getAPIErrorCode(apiError),
                message: getAPIErrorMessage(apiError),
                originalError: error
            )
        } else if let urlError = error as? URLError {
            return ErrorInfo(
                type: .network,
                code: urlError.code.rawValue,
                message: getURLErrorMessage(urlError),
                originalError: error
            )
        } else {
            return ErrorInfo(
                type: .unknown,
                code: -1,
                message: error.localizedDescription,
                originalError: error
            )
        }
    }
    
    /// 格式化错误消息
    private func formatErrorMessage(_ errorInfo: ErrorInfo, context: String?) -> String {
        var message = errorInfo.message
        
        if let context = context {
            message = "\(context): \(message)"
        }
        
        return message
    }
    
    /// 记录错误日志
    private func logError(_ error: Error, context: String?, errorInfo: ErrorInfo) {
        let contextStr = context ?? "未知操作"
        print("🚨 错误处理 - 上下文: \(contextStr)")
        print("   错误类型: \(errorInfo.type)")
        print("   错误代码: \(errorInfo.code)")
        print("   错误消息: \(errorInfo.message)")
        print("   原始错误: \(error)")
    }
    
    /// 获取API错误消息
    private func getAPIErrorMessage(_ apiError: APIError, operation: String = "") -> String {
        switch apiError {
        case .invalidData(let message):
            return message.isEmpty ? "数据无效" : message
        case .networkError(let message):
            return message.isEmpty ? "网络错误" : message
        case .serverError(let message):
            return message.isEmpty ? "服务器错误" : message
        }
    }
    
    /// 获取API错误代码
    private func getAPIErrorCode(_ apiError: APIError) -> Int {
        switch apiError {
        case .invalidData:
            return -1001
        case .networkError:
            return -1002
        case .serverError:
            return -1003
        }
    }
    
    /// 获取URL错误消息
    private func getURLErrorMessage(_ urlError: URLError) -> String {
        switch urlError.code {
        case .notConnectedToInternet:
            return "网络连接不可用"
        case .timedOut:
            return "请求超时"
        case .cannotFindHost:
            return "无法找到服务器"
        case .cannotConnectToHost:
            return "无法连接到服务器"
        case .networkConnectionLost:
            return "网络连接已断开"
        case .dnsLookupFailed:
            return "DNS解析失败"
        case .badServerResponse:
            return "服务器响应异常"
        default:
            return "网络错误: \(urlError.localizedDescription)"
        }
    }
}

// MARK: - 支持类型

struct ErrorInfo {
    let type: ErrorType
    let code: Int
    let message: String
    let originalError: Error
}

enum ErrorType {
    case api
    case network
    case unknown
}

// MARK: - 便捷方法扩展

extension NetworkErrorHandler {
    /// 处理异步操作中的错误
    /// - Parameters:
    ///   - operation: 异步操作
    ///   - context: 错误上下文
    ///   - showUserFeedback: 是否显示用户反馈
    /// - Returns: 操作结果
    func handleAsyncOperation<T>(
        _ operation: () async throws -> T,
        context: String,
        showUserFeedback: Bool = true
    ) async -> T? {
        do {
            return try await operation()
        } catch {
            handleError(error, context: context, showToast: showUserFeedback)
            return nil
        }
    }
    
    /// 处理带有重试机制的异步操作
    /// - Parameters:
    ///   - operation: 异步操作
    ///   - context: 错误上下文
    ///   - maxRetries: 最大重试次数
    ///   - retryDelay: 重试延迟（秒）
    ///   - showUserFeedback: 是否显示用户反馈
    /// - Returns: 操作结果
    func handleAsyncOperationWithRetry<T>(
        _ operation: @escaping () async throws -> T,
        context: String,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0,
        showUserFeedback: Bool = true
    ) async -> T? {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < maxRetries {
                    print("🔄 重试操作: \(context) (第\(attempt + 1)次)")
                    try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }
        
        if let error = lastError {
            handleError(error, context: "\(context) (重试\(maxRetries)次后失败)", showToast: showUserFeedback)
        }
        
        return nil
    }
}
