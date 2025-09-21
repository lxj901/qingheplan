import Foundation
import Combine
import UIKit

/// 通知管理器
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var notifications: [SystemNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // 分页状态管理
    @Published var currentPage: Int = 1
    @Published var hasMoreData: Bool = true
    @Published var isLoadingMore: Bool = false

    private let baseURL = "https://api.qinghejihua.com.cn/api/v1"
    private var userToken: String {
        // 从 AuthManager 获取用户令牌
        return AuthManager.shared.getToken() ?? ""
    }

    // 防抖机制
    private var lastFetchTime: Date = Date.distantPast
    private let fetchDebounceInterval: TimeInterval = 10.0 // 10秒内不重复请求
    private var fetchTask: Task<Void, Never>?

    private init() {}

    // MARK: - 获取通知列表
    func fetchNotifications(page: Int = 1, limit: Int = 20, type: String? = nil, isRead: Bool? = nil) {
        DispatchQueue.main.async {
            if page == 1 {
                self.isLoading = true
                self.currentPage = 1
                self.hasMoreData = true
            } else {
                self.isLoadingMore = true
            }
            self.errorMessage = nil
        }

        var urlComponents = URLComponents(string: "\(baseURL)/notifications")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }

        if let isRead = isRead {
            queryItems.append(URLQueryItem(name: "is_read", value: "\(isRead)"))
        }

        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }

            if let error = error {
                print("🔔 通知请求失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.errorMessage = "网络请求失败: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                print("🔔 通知请求未收到数据")
                DispatchQueue.main.async {
                    self?.errorMessage = "未收到数据"
                }
                return
            }

            // 打印响应状态码
            if let httpResponse = response as? HTTPURLResponse {
                print("🔔 通知请求响应状态码: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("🔔 通知请求失败，状态码: \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        self?.errorMessage = "服务器错误: HTTP \(httpResponse.statusCode)"
                    }
                    return
                }
            }

            // 打印原始响应数据
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔔 通知响应数据: \(jsonString)")
            }

            do {
                let result = try JSONDecoder().decode(SystemNotificationResponse.self, from: data)
                print("🔔 成功解析通知数据，共 \(result.data.items.count) 条通知")
                DispatchQueue.main.async {
                    if page == 1 {
                        self?.notifications = result.data.items
                    } else {
                        self?.notifications.append(contentsOf: result.data.items)
                        self?.currentPage = page
                    }

                    // 更新分页状态
                    self?.hasMoreData = result.data.items.count == limit
                    self?.isLoading = false
                    self?.isLoadingMore = false
                    self?.errorMessage = nil // 清除错误信息
                    print("🔔 通知数据已更新，当前共 \(self?.notifications.count ?? 0) 条通知，hasMoreData: \(self?.hasMoreData ?? false)")
                }
            } catch {
                print("🔔 通知数据解析失败: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔔 原始数据: \(jsonString)")
                }
                DispatchQueue.main.async {
                    self?.errorMessage = "数据解析失败: \(error.localizedDescription)"
                    self?.isLoading = false
                    self?.isLoadingMore = false
                }
            }
        }.resume()
    }

    // MARK: - 加载更多通知
    func loadMoreNotifications(type: String? = nil) {
        guard hasMoreData && !isLoadingMore else {
            print("🔔 无法加载更多：hasMoreData=\(hasMoreData), isLoadingMore=\(isLoadingMore)")
            return
        }

        let nextPage = currentPage + 1
        print("🔔 开始加载第 \(nextPage) 页通知")
        fetchNotifications(page: nextPage, type: type)
    }

    // MARK: - 获取未读数量（带防抖机制）
    func fetchUnreadCount(force: Bool = false) {
        // 防抖检查：如果不是强制刷新且距离上次请求时间小于防抖间隔，则跳过
        let now = Date()
        if !force && now.timeIntervalSince(lastFetchTime) < fetchDebounceInterval {
            print("🔔 防抖跳过未读数量请求，距离上次请求仅 \(Int(now.timeIntervalSince(lastFetchTime))) 秒")
            return
        }

        // 取消之前的请求
        fetchTask?.cancel()

        // 更新最后请求时间
        lastFetchTime = now

        fetchTask = Task { [weak self] in
            guard let self = self else { return }

            let url = URL(string: "\(self.baseURL)/notifications/unread-count")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(self.userToken)", forHTTPHeaderField: "Authorization")

            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let result = try JSONDecoder().decode(UnreadCountResponse.self, from: data)

                await MainActor.run {
                    self.unreadCount = result.data.unreadCount
                    // 更新应用角标
                    UIApplication.shared.applicationIconBadgeNumber = result.data.unreadCount
                    print("🔔 成功获取未读数量: \(result.data.unreadCount)")
                }
            } catch {
                if !Task.isCancelled {
                    print("🔔 获取未读数量失败: \(error)")
                }
            }
        }
    }

    // MARK: - 标记单个通知为已读
    func markAsRead(notificationId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        let url = URL(string: "\(baseURL)/notifications/\(notificationId)/read")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            let success = httpResponse.statusCode == 200
            DispatchQueue.main.async {
                if success {
                    // 更新本地数据
                    if let index = self?.notifications.firstIndex(where: { $0.id == notificationId }) {
                        var updatedNotification = self?.notifications[index]
                        updatedNotification = SystemNotification(
                            id: updatedNotification?.id ?? "",
                            type: updatedNotification?.type ?? .system,
                            title: updatedNotification?.title ?? "",
                            content: updatedNotification?.content ?? "",
                            data: updatedNotification?.data,
                            isRead: true,
                            readAt: updatedNotification?.readAt,
                            priority: updatedNotification?.priority,
                            relatedId: updatedNotification?.relatedId,
                            relatedType: updatedNotification?.relatedType,
                            fromUser: updatedNotification?.fromUser,
                            createdAt: updatedNotification?.createdAt ?? "",
                            updatedAt: updatedNotification?.updatedAt ?? ""
                        )
                        if let updatedNotification = updatedNotification {
                            self?.notifications[index] = updatedNotification
                        }
                    }
                    // 更新未读数量（强制刷新，因为用户刚标记已读）
                    self?.fetchUnreadCount(force: true)
                }
                completion(success)
            }
        }.resume()
    }

    // MARK: - 标记所有通知为已读
    func markAllAsRead(completion: @escaping (Bool, Int) -> Void = { _, _ in }) {
        let url = URL(string: "\(baseURL)/notifications/mark-all-read")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    completion(false, 0)
                }
                return
            }

            do {
                let result = try JSONDecoder().decode(MarkAllReadResponse.self, from: data)
                DispatchQueue.main.async {
                    // 更新所有通知为已读
                    self?.notifications = self?.notifications.map { notification in
                        SystemNotification(
                            id: notification.id,
                            type: notification.type,
                            title: notification.title,
                            content: notification.content,
                            data: notification.data,
                            isRead: true,
                            readAt: notification.readAt,
                            priority: notification.priority,
                            relatedId: notification.relatedId,
                            relatedType: notification.relatedType,
                            fromUser: notification.fromUser,
                            createdAt: notification.createdAt,
                            updatedAt: notification.updatedAt
                        )
                    } ?? []

                    self?.unreadCount = 0
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    completion(true, result.data.updatedCount)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, 0)
                }
            }
        }.resume()
    }

    // MARK: - 删除单个通知
    func deleteNotification(notificationId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        let url = URL(string: "\(baseURL)/notifications/\(notificationId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            let success = httpResponse.statusCode == 200
            DispatchQueue.main.async {
                if success {
                    // 从本地数据中移除
                    self?.notifications.removeAll { $0.id == notificationId }
                    // 更新未读数量（强制刷新，因为用户刚删除通知）
                    self?.fetchUnreadCount(force: true)
                }
                completion(success)
            }
        }.resume()
    }

    // MARK: - 清空所有通知
    func clearAllNotifications(completion: @escaping (Bool, Int) -> Void = { _, _ in }) {
        let url = URL(string: "\(baseURL)/notifications/clear-all")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    completion(false, 0)
                }
                return
            }

            do {
                let result = try JSONDecoder().decode(ClearAllResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.notifications.removeAll()
                    self?.unreadCount = 0
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    completion(true, result.data.deletedCount)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, 0)
                }
            }
        }.resume()
    }

    // MARK: - 刷新通知（带防抖机制）
    func refreshNotifications(force: Bool = false) {
        DispatchQueue.main.async {
            // 重置分页状态
            self.currentPage = 1
            self.hasMoreData = true
            self.fetchNotifications(page: 1)
            self.fetchUnreadCount(force: force)
        }
    }
}
