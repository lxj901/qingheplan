# 青禾计划通知系统 API 文档

## 📋 概述
青禾计划通知系统为用户提供实时通知功能，包括点赞、评论、收藏、关注等社交互动通知。本文档专为前端 iOS 开发设计，提供完整的 API 接口说明和实现示例。

## 🌐 基础信息
**基础URL**: `https://api.qinghejihua.com.cn/api/v1`  
**协议**: HTTPS  
**认证方式**: Bearer Token  
**数据格式**: JSON  

## 🔐 认证说明
所有API请求都需要在请求头中包含有效的JWT令牌：
```http
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

## 📱 iOS 集成说明

### 网络请求基础配置
```swift
// 基础URL配置
let baseURL = "https://api.qinghejihua.com.cn/api/v1"

// 请求头配置示例
func createRequest(for endpoint: String, method: String = "GET") -> URLRequest {
    let url = URL(string: "\(baseURL)\(endpoint)")!
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    return request
}
```

## 📋 API 端点详细说明

### 1. 获取通知列表
**端点**: `GET /notifications`  
**描述**: 获取用户的通知列表，支持分页和筛选

#### 请求参数
| 参数名 | 类型 | 必填 | 默认值 | 描述 |
|--------|------|------|--------|------|
| page | integer | 否 | 1 | 页码，从1开始 |
| limit | integer | 否 | 20 | 每页数量，最大100 |
| type | string | 否 | - | 通知类型筛选 |
| is_read | boolean | 否 | - | 是否已读筛选 |

#### 通知类型说明
- `like` - 点赞通知
- `comment` - 评论通知  
- `bookmark` - 收藏通知
- `follow` - 关注通知
- `system` - 系统通知

#### 请求示例
```http
GET /notifications?page=1&limit=20&type=like&is_read=false
#### 响应示例
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 1,
        "type": "like",
        "title": "新的点赞",
        "content": "用户张三点赞了您的帖子《我的健身日记》",
        "data": {
          "user_id": 123,
          "user_name": "张三",
          "user_avatar": "https://api.qinghejihua.com.cn/uploads/avatars/123.jpg",
          "post_id": 456,
          "post_title": "我的健身日记"
        },
        "is_read": false,
        "created_at": "2025-08-27T21:30:00Z",
        "updated_at": "2025-08-27T21:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 50,
      "totalPages": 3
    }
  }
}
```

#### iOS 实现示例
```swift
func fetchNotifications(page: Int = 1, limit: Int = 20, type: String? = nil, isRead: Bool? = nil) {
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
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data else { return }
        
        do {
            let result = try JSONDecoder().decode(NotificationResponse.self, from: data)
            DispatchQueue.main.async {
                self.notifications = result.data.items
                self.pagination = result.data.pagination
            }
        } catch {
            print("解析错误: \(error)")
        }
    }.resume()
}
```

### 2. 获取未读通知数量
**端点**: `GET /notifications/unread-count`  
**描述**: 获取用户未读通知的总数量，用于显示角标

#### 响应示例
```json
{
  "success": true,
  "data": {
    "unreadCount": 5
  }
}
```

#### iOS 实现示例
```swift
func fetchUnreadCount(completion: @escaping (Int) -> Void) {
    let url = URL(string: "\(baseURL)/notifications/unread-count")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data else { 
            completion(0)
            return 
        }
        
        do {
            let result = try JSONDecoder().decode(UnreadCountResponse.self, from: data)
            DispatchQueue.main.async {
                completion(result.data.unreadCount)
                // 更新应用角标
                UIApplication.shared.applicationIconBadgeNumber = result.data.unreadCount
            }
        } catch {
            print("解析错误: \(error)")
            completion(0)
        }
    }.resume()
}

struct UnreadCountResponse: Codable {
    let success: Bool
    let data: UnreadCountData
}

struct UnreadCountData: Codable {
    let unreadCount: Int
}
```

### 3. 标记单个通知为已读
**端点**: `PUT /notifications/{id}/read`  
**描述**: 将指定ID的通知标记为已读

#### 路径参数
| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| id | integer | 是 | 通知ID |

#### 请求示例
```http
PUT /notifications/123/read
```

#### 响应示例
```json
{
  "success": true,
  "message": "通知已标记为已读"
}
```

#### iOS 实现示例
```swift
func markNotificationAsRead(notificationId: Int, completion: @escaping (Bool) -> Void) {
    let url = URL(string: "\(baseURL)/notifications/\(notificationId)/read")!
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(false)
            return
        }

        DispatchQueue.main.async {
            completion(httpResponse.statusCode == 200)
        }
    }.resume()
}
```

### 4. 标记所有通知为已读
**端点**: `PUT /notifications/mark-all-read`
**描述**: 将用户的所有未读通知标记为已读

#### 请求示例
```http
PUT /notifications/mark-all-read
```

#### 响应示例
```json
{
  "success": true,
  "data": {
    "updatedCount": 5
  },
  "message": "所有通知已标记为已读"
}
```

#### iOS 实现示例
```swift
func markAllNotificationsAsRead(completion: @escaping (Bool, Int) -> Void) {
    let url = URL(string: "\(baseURL)/notifications/mark-all-read")!
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    URLSession.shared.dataTask(with: request) { data, response, error in
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
                completion(true, result.data.updatedCount)
                // 清除应用角标
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        } catch {
            DispatchQueue.main.async {
                completion(false, 0)
            }
        }
    }.resume()
}

struct MarkAllReadResponse: Codable {
    let success: Bool
    let data: MarkAllReadData
    let message: String
}

struct MarkAllReadData: Codable {
    let updatedCount: Int
}
```

### 5. 删除单个通知
**端点**: `DELETE /notifications/{id}`
**描述**: 删除指定ID的通知

#### 路径参数
| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| id | integer | 是 | 通知ID |

#### 请求示例
```http
DELETE /notifications/123
```

#### 响应示例
```json
{
  "success": true,
  "message": "通知已删除"
}
```

#### iOS 实现示例
```swift
func deleteNotification(notificationId: Int, completion: @escaping (Bool) -> Void) {
    let url = URL(string: "\(baseURL)/notifications/\(notificationId)")!
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(false)
            return
        }

        DispatchQueue.main.async {
            completion(httpResponse.statusCode == 200)
        }
    }.resume()
}
```

### 6. 批量删除通知
**端点**: `DELETE /notifications`
**描述**: 批量删除指定ID的通知

#### 请求体
```json
{
  "ids": [1, 2, 3, 4, 5]
}
```

#### 响应示例
```json
{
  "success": true,
  "data": {
    "deletedCount": 5
  },
  "message": "通知已批量删除"
}
```

#### iOS 实现示例
```swift
func deleteNotifications(ids: [Int], completion: @escaping (Bool, Int) -> Void) {
    let url = URL(string: "\(baseURL)/notifications")!
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let requestBody = ["ids": ids]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
    } catch {
        completion(false, 0)
        return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            DispatchQueue.main.async {
                completion(false, 0)
            }
            return
        }

        do {
            let result = try JSONDecoder().decode(BatchDeleteResponse.self, from: data)
            DispatchQueue.main.async {
                completion(true, result.data.deletedCount)
            }
        } catch {
            DispatchQueue.main.async {
                completion(false, 0)
            }
        }
    }.resume()
}

struct BatchDeleteResponse: Codable {
    let success: Bool
    let data: BatchDeleteData
    let message: String
}

struct BatchDeleteData: Codable {
    let deletedCount: Int
}
```

### 7. 清空所有通知
**端点**: `DELETE /notifications/clear-all`
**描述**: 删除用户的所有通知

#### 请求示例
```http
DELETE /notifications/clear-all
```

#### 响应示例
```json
{
  "success": true,
  "data": {
    "deletedCount": 10
  },
  "message": "所有通知已清空"
}
```

#### iOS 实现示例
```swift
func clearAllNotifications(completion: @escaping (Bool, Int) -> Void) {
    let url = URL(string: "\(baseURL)/notifications/clear-all")!
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    URLSession.shared.dataTask(with: request) { data, response, error in
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
                completion(true, result.data.deletedCount)
                // 清除应用角标
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        } catch {
            DispatchQueue.main.async {
                completion(false, 0)
            }
        }
    }.resume()
}

struct ClearAllResponse: Codable {
    let success: Bool
    let data: ClearAllData
    let message: String
}

struct ClearAllData: Codable {
    let deletedCount: Int
}
```

## 📱 iOS 数据模型定义

### 通知模型
```swift
struct Notification: Codable, Identifiable {
    let id: Int
    let type: NotificationType
    let title: String
    let content: String
    let data: NotificationData?
    let isRead: Bool
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, type, title, content, data
        case isRead = "is_read"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case like = "like"
    case comment = "comment"
    case bookmark = "bookmark"
    case follow = "follow"
    case system = "system"

    var displayName: String {
        switch self {
        case .like: return "点赞"
        case .comment: return "评论"
        case .bookmark: return "收藏"
        case .follow: return "关注"
        case .system: return "系统"
        }
    }

    var iconName: String {
        switch self {
        case .like: return "heart.fill"
        case .comment: return "message.fill"
        case .bookmark: return "bookmark.fill"
        case .follow: return "person.badge.plus"
        case .system: return "bell.fill"
        }
    }

    var color: Color {
        switch self {
        case .like: return .red
        case .comment: return .blue
        case .bookmark: return .orange
        case .follow: return .green
        case .system: return .purple
        }
    }
}

struct NotificationData: Codable {
    let userId: Int?
    let userName: String?
    let userAvatar: String?
    let postId: Int?
    let postTitle: String?
    let commentId: Int?
    let commentContent: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case userAvatar = "user_avatar"
        case postId = "post_id"
        case postTitle = "post_title"
        case commentId = "comment_id"
        case commentContent = "comment_content"
    }
}

struct NotificationResponse: Codable {
    let success: Bool
    let data: NotificationListData
}

struct NotificationListData: Codable {
    let items: [Notification]
    let pagination: Pagination
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}
```

## 🔄 网络管理器封装

### NotificationManager 类
```swift
import Foundation
import Combine

class NotificationManager: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let baseURL = "https://api.qinghejihua.com.cn/api/v1"
    private var userToken: String {
        // 从 Keychain 或 UserDefaults 获取用户令牌
        return UserDefaults.standard.string(forKey: "userToken") ?? ""
    }

    // MARK: - 获取通知列表
    func fetchNotifications(page: Int = 1, limit: Int = 20, type: String? = nil, isRead: Bool? = nil) {
        isLoading = true
        errorMessage = nil

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

            guard let data = data else {
                DispatchQueue.main.async {
                    self?.errorMessage = "网络请求失败"
                }
                return
            }

            do {
                let result = try JSONDecoder().decode(NotificationResponse.self, from: data)
                DispatchQueue.main.async {
                    if page == 1 {
                        self?.notifications = result.data.items
                    } else {
                        self?.notifications.append(contentsOf: result.data.items)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "数据解析失败"
                }
            }
        }.resume()
    }

    // MARK: - 获取未读数量
    func fetchUnreadCount() {
        let url = URL(string: "\(baseURL)/notifications/unread-count")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data else { return }

            do {
                let result = try JSONDecoder().decode(UnreadCountResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.unreadCount = result.data.unreadCount
                    UIApplication.shared.applicationIconBadgeNumber = result.data.unreadCount
                }
            } catch {
                print("获取未读数量失败: \(error)")
            }
        }.resume()
    }

    // MARK: - 标记为已读
    func markAsRead(notificationId: Int) {
        let url = URL(string: "\(baseURL)/notifications/\(notificationId)/read")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            DispatchQueue.main.async {
                // 更新本地数据
                if let index = self?.notifications.firstIndex(where: { $0.id == notificationId }) {
                    self?.notifications[index] = Notification(
                        id: self?.notifications[index].id ?? 0,
                        type: self?.notifications[index].type ?? .system,
                        title: self?.notifications[index].title ?? "",
                        content: self?.notifications[index].content ?? "",
                        data: self?.notifications[index].data,
                        isRead: true,
                        createdAt: self?.notifications[index].createdAt ?? "",
                        updatedAt: self?.notifications[index].updatedAt ?? ""
                    )
                }
                // 更新未读数量
                self?.fetchUnreadCount()
            }
        }.resume()
    }

    // MARK: - 标记所有为已读
    func markAllAsRead() {
        let url = URL(string: "\(baseURL)/notifications/mark-all-read")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            DispatchQueue.main.async {
                // 更新所有通知为已读
                self?.notifications = self?.notifications.map { notification in
                    Notification(
                        id: notification.id,
                        type: notification.type,
                        title: notification.title,
                        content: notification.content,
                        data: notification.data,
                        isRead: true,
                        createdAt: notification.createdAt,
                        updatedAt: notification.updatedAt
                    )
                } ?? []

                self?.unreadCount = 0
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }.resume()
    }
}
```

## 🎨 SwiftUI 界面组件

### 通知列表视图
```swift
import SwiftUI

struct NotificationListView: View {
    @StateObject private var notificationManager = NotificationManager()
    @State private var selectedType: NotificationType? = nil
    @State private var showingFilterSheet = false

    var body: some View {
        NavigationView {
            VStack {
                if notificationManager.isLoading && notificationManager.notifications.isEmpty {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notificationManager.notifications.isEmpty {
                    EmptyNotificationView()
                } else {
                    List {
                        ForEach(notificationManager.notifications) { notification in
                            NotificationRowView(notification: notification) {
                                notificationManager.markAsRead(notificationId: notification.id)
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("通知")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("筛选") {
                        showingFilterSheet = true
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("全部已读") {
                            notificationManager.markAllAsRead()
                        }

                        Button("清空所有", role: .destructive) {
                            // 显示确认对话框
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                notificationManager.fetchNotifications()
                notificationManager.fetchUnreadCount()
            }
            .refreshable {
                notificationManager.fetchNotifications()
            }
            .sheet(isPresented: $showingFilterSheet) {
                NotificationFilterView(selectedType: $selectedType) { type in
                    notificationManager.fetchNotifications(type: type?.rawValue)
                }
            }
        }
    }
}

struct NotificationRowView: View {
    let notification: Notification
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 通知类型图标
            Image(systemName: notification.type.iconName)
                .foregroundColor(notification.type.color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(notification.type.color.opacity(0.1))
                        .frame(width: 40, height: 40)
                )

            VStack(alignment: .leading, spacing: 4) {
                // 标题
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(notification.isRead ? .secondary : .primary)

                // 内容
                Text(notification.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // 时间
                Text(notification.createdAt.timeAgoDisplay)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack {
                // 未读标记
                if !notification.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }

                Spacer()

                // 箭头
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
            // 处理通知点击事件
            handleNotificationTap(notification)
        }
    }

    private func handleNotificationTap(_ notification: Notification) {
        // 根据通知类型跳转到相应页面
        switch notification.type {
        case .like, .comment, .bookmark:
            if let postId = notification.data?.postId {
                // 跳转到帖子详情页
                NavigationManager.shared.navigateToPost(id: postId)
            }
        case .follow:
            if let userId = notification.data?.userId {
                // 跳转到用户资料页
                NavigationManager.shared.navigateToProfile(userId: userId)
            }
        case .system:
            // 处理系统通知
            break
        }
    }
}

struct EmptyNotificationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("暂无通知")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("当有新的互动时，您会在这里看到通知")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NotificationFilterView: View {
    @Binding var selectedType: NotificationType?
    let onFilter: (NotificationType?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("通知类型") {
                    ForEach([nil] + NotificationType.allCases, id: \.self) { type in
                        HStack {
                            if let type = type {
                                Image(systemName: type.iconName)
                                    .foregroundColor(type.color)
                                Text(type.displayName)
                            } else {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.primary)
                                Text("全部")
                            }

                            Spacer()

                            if selectedType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedType = type
                            onFilter(type)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("筛选通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
```

## 🔧 错误处理

### API错误定义
```swift
enum NotificationAPIError: Error, LocalizedError {
    case invalidToken
    case notificationNotFound
    case serverError
    case networkError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "登录已过期，请重新登录"
        case .notificationNotFound:
            return "通知不存在或已被删除"
        case .serverError:
            return "服务器错误，请稍后重试"
        case .networkError:
            return "网络连接失败，请检查网络设置"
        case .decodingError:
            return "数据格式错误"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidToken:
            return "请重新登录您的账户"
        case .notificationNotFound:
            return "刷新页面查看最新通知"
        case .serverError:
            return "请稍后重试或联系客服"
        case .networkError:
            return "请检查网络连接后重试"
        case .decodingError:
            return "请更新应用到最新版本"
        }
    }
}

// 错误处理扩展
extension NotificationManager {
    private func handleAPIError(_ error: Error, response: HTTPURLResponse?) {
        DispatchQueue.main.async {
            if let httpResponse = response {
                switch httpResponse.statusCode {
                case 401:
                    self.errorMessage = NotificationAPIError.invalidToken.localizedDescription
                case 404:
                    self.errorMessage = NotificationAPIError.notificationNotFound.localizedDescription
                case 500...599:
                    self.errorMessage = NotificationAPIError.serverError.localizedDescription
                default:
                    self.errorMessage = error.localizedDescription
                }
            } else {
                self.errorMessage = NotificationAPIError.networkError.localizedDescription
            }
        }
    }
}
```

## 📱 推送通知集成

### 推送通知管理器
```swift
import UserNotifications

class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    func handleDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        // 将设备令牌发送到服务器
        uploadDeviceToken(tokenString)
    }

    private func uploadDeviceToken(_ token: String) {
        // 实现设备令牌上传逻辑
        let url = URL(string: "https://api.qinghejihua.com.cn/api/v1/push/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["device_token": token, "platform": "ios"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request).resume()
    }
}

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // 处理通知点击
        if let notificationId = userInfo["notification_id"] as? Int {
            handleNotificationTap(notificationId: notificationId)
        }

        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 应用在前台时显示通知
        completionHandler([.banner, .sound, .badge])
    }

    private func handleNotificationTap(notificationId: Int) {
        // 跳转到通知详情或相关页面
        NotificationCenter.default.post(name: .notificationTapped, object: notificationId)
    }
}

extension Notification.Name {
    static let notificationTapped = Notification.Name("notificationTapped")
}
```

## 📊 性能优化建议

### 1. 数据缓存策略
```swift
class NotificationCache {
    private let cache = NSCache<NSString, NSArray>()
    private let userDefaults = UserDefaults.standard

    func cacheNotifications(_ notifications: [Notification], for key: String) {
        let data = try? JSONEncoder().encode(notifications)
        userDefaults.set(data, forKey: "cached_\(key)")

        let nsArray = notifications as NSArray
        cache.setObject(nsArray, forKey: key as NSString)
    }

    func getCachedNotifications(for key: String) -> [Notification]? {
        // 先从内存缓存获取
        if let cached = cache.object(forKey: key as NSString) as? [Notification] {
            return cached
        }

        // 再从本地存储获取
        if let data = userDefaults.data(forKey: "cached_\(key)"),
           let notifications = try? JSONDecoder().decode([Notification].self, from: data) {
            return notifications
        }

        return nil
    }
}
```

### 2. 图片缓存
```swift
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    func loadImage(from url: String, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = cache.object(forKey: url as NSString) {
            completion(cachedImage)
            return
        }

        guard let imageURL = URL(string: url) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: imageURL) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }

            self.cache.setObject(image, forKey: url as NSString)
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
```

## 🔒 安全注意事项

1. **HTTPS强制**: 所有API请求必须使用HTTPS协议
2. **Token安全存储**: 使用Keychain存储JWT令牌
3. **证书验证**: 验证服务器SSL证书
4. **数据验证**: 验证服务器返回的数据格式和内容
5. **错误信息**: 不在错误信息中暴露敏感信息

### Keychain存储示例
```swift
import Security

class KeychainManager {
    static let shared = KeychainManager()

    func save(token: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userToken",
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userToken",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }
}
```

## 📋 常见错误码

| 状态码 | 错误信息 | 描述 | 处理建议 |
|--------|----------|------|----------|
| 401 | 访问被拒绝，请提供有效令牌 | 未提供或令牌无效 | 重新登录 |
| 404 | 通知不存在 | 指定的通知ID不存在 | 刷新列表 |
| 429 | 请求过于频繁 | 超出API调用限制 | 稍后重试 |
| 500 | 服务器内部错误 | 服务器处理请求时发生错误 | 稍后重试 |

---

**文档版本**: v1.0
**最后更新**: 2025-08-27
**维护团队**: 青禾计划开发团队
**技术支持**: 如有问题请联系开发团队
