import Foundation
import SwiftUI

/// 用户反馈管理器，处理用户界面反馈（如Toast、Alert等）
class UserFeedbackManager: ObservableObject {
    static let shared = UserFeedbackManager()
    
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .info
    
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var alertActions: [AlertAction] = []

    @Published var isLoading = false
    @Published var loadingMessage = ""
    private var loadingTasks: [String: String] = [:]

    private init() {}
    
    // MARK: - Toast 相关方法
    
    /// 显示成功Toast
    func showSuccess(_ message: String) {
        DispatchQueue.main.async {
            self.toastMessage = message
            self.toastType = .success
            self.showToast = true
        }
    }
    
    /// 显示错误Toast
    func showError(_ message: String) {
        DispatchQueue.main.async {
            self.toastMessage = message
            self.toastType = .error
            self.showToast = true
        }
    }
    
    /// 显示信息Toast
    func showInfo(_ message: String) {
        DispatchQueue.main.async {
            self.toastMessage = message
            self.toastType = .info
            self.showToast = true
        }
    }
    
    /// 显示警告Toast
    func showWarning(_ message: String) {
        DispatchQueue.main.async {
            self.toastMessage = message
            self.toastType = .warning
            self.showToast = true
        }
    }
    
    /// 隐藏Toast
    func hideToast() {
        DispatchQueue.main.async {
            self.showToast = false
        }
    }

    // MARK: - Loading 相关方法

    /// 开始加载
    func startLoading(_ message: String, taskId: String = UUID().uuidString) {
        DispatchQueue.main.async {
            self.loadingTasks[taskId] = message
            self.loadingMessage = message
            self.isLoading = true
        }
    }

    /// 停止加载
    func stopLoading(taskId: String) {
        DispatchQueue.main.async {
            self.loadingTasks.removeValue(forKey: taskId)
            if self.loadingTasks.isEmpty {
                self.isLoading = false
                self.loadingMessage = ""
            } else {
                // 如果还有其他加载任务，显示最新的
                self.loadingMessage = Array(self.loadingTasks.values).last ?? ""
            }
        }
    }

    /// 停止所有加载
    func stopAllLoading() {
        DispatchQueue.main.async {
            self.loadingTasks.removeAll()
            self.isLoading = false
            self.loadingMessage = ""
        }
    }
    
    // MARK: - Alert 相关方法
    
    /// 显示确认对话框
    func showConfirmation(
        title: String,
        message: String,
        confirmText: String = "确认",
        cancelText: String = "取消",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.alertActions = [
                AlertAction(title: cancelText, style: .cancel) {
                    onCancel?()
                },
                AlertAction(title: confirmText, style: .default) {
                    onConfirm()
                }
            ]
            self.showAlert = true
        }
    }
    
    /// 显示信息对话框
    func showInfoAlert(
        title: String,
        message: String,
        buttonText: String = "确定",
        onDismiss: (() -> Void)? = nil
    ) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.alertActions = [
                AlertAction(title: buttonText, style: .default) {
                    onDismiss?()
                }
            ]
            self.showAlert = true
        }
    }
    
    /// 显示错误对话框
    func showErrorAlert(
        title: String = "错误",
        message: String,
        buttonText: String = "确定",
        onDismiss: (() -> Void)? = nil
    ) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.alertActions = [
                AlertAction(title: buttonText, style: .default) {
                    onDismiss?()
                }
            ]
            self.showAlert = true
        }
    }
    
    /// 隐藏Alert
    func hideAlert() {
        DispatchQueue.main.async {
            self.showAlert = false
            self.alertActions.removeAll()
        }
    }
}

// MARK: - 支持类型

enum ToastType {
    case success
    case error
    case warning
    case info
    
    var color: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .warning:
            return .orange
        case .info:
            return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}

struct AlertAction {
    let title: String
    let style: AlertActionStyle
    let action: () -> Void
    
    init(title: String, style: AlertActionStyle = .default, action: @escaping () -> Void = {}) {
        self.title = title
        self.style = style
        self.action = action
    }
}

enum AlertActionStyle {
    case `default`
    case cancel
    case destructive
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.title2)
            
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
        .onTapGesture {
            onDismiss()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onDismiss()
            }
        }
    }
}


