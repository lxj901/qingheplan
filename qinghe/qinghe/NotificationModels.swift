import Foundation
import SwiftUI

// MARK: - 通知数据模型

/// 系统通知模型
struct SystemNotification: Codable, Identifiable {
    let id: String  // API实际返回的是字符串类型
    let type: SystemNotificationType
    let title: String
    let content: String
    let data: SystemNotificationData?
    let isRead: Bool
    let readAt: String?
    let priority: String?
    let relatedId: String?
    let relatedType: String?
    let fromUser: NotificationFromUser?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, type, title, content, data
        case isRead = "isRead"
        case readAt = "readAt"
        case priority = "priority"
        case relatedId = "relatedId"
        case relatedType = "relatedType"
        case fromUser = "fromUser"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
    }
}

/// 系统通知类型枚举
enum SystemNotificationType: String, Codable, CaseIterable {
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

/// 通知发送者信息
struct NotificationFromUser: Codable {
    let id: Int
    let nickname: String
    let avatar: String
    let isVerified: Bool

    // 自定义解码器来处理服务器返回的不同格式
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        nickname = try container.decode(String.self, forKey: .nickname)
        avatar = try container.decode(String.self, forKey: .avatar)

        // 处理 isVerified 字段：可能是数字或布尔值
        if let verifiedInt = try? container.decodeIfPresent(Int.self, forKey: .isVerified) {
            isVerified = verifiedInt != 0
        } else {
            isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified) ?? false
        }
    }

    // 自定义编码器
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(nickname, forKey: .nickname)
        try container.encode(avatar, forKey: .avatar)
        try container.encode(isVerified, forKey: .isVerified)
    }

    // 便利初始化器，用于测试和手动创建
    init(id: Int, nickname: String, avatar: String, isVerified: Bool) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
        self.isVerified = isVerified
    }

    // 兼容旧的数字格式的便利初始化器
    init(id: Int, nickname: String, avatar: String, isVerified: Int) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
        self.isVerified = isVerified != 0
    }

    private enum CodingKeys: String, CodingKey {
        case id, nickname, avatar, isVerified
    }
}

/// 系统通知数据详情
struct SystemNotificationData: Codable {
    let liker: NotificationUser?
    let follower: NotificationUser?
    let commenter: NotificationUser?
    let postId: String?
    let postTitle: String?
    let commentId: String?
    let commentContent: String?

    // 兼容旧的字段名
    let userId: Int?
    let userName: String?
    let userAvatar: String?

    enum CodingKeys: String, CodingKey {
        case liker, follower, commenter
        case postId = "post_id"
        case postTitle = "post_title"
        case commentId = "comment_id"
        case commentContent = "comment_content"
        case userId = "user_id"
        case userName = "user_name"
        case userAvatar = "user_avatar"
    }
}

/// 通知中的用户信息
struct NotificationUser: Codable {
    let id: Int
    let nickname: String
    let avatar: String
}

/// 系统通知响应模型
struct SystemNotificationResponse: Codable {
    let success: Bool
    let data: SystemNotificationListData
}

/// 系统通知列表数据
struct SystemNotificationListData: Codable {
    let items: [SystemNotification]
    let pagination: Pagination
}

/// 分页信息
struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

/// 未读数量响应
struct UnreadCountResponse: Codable {
    let success: Bool
    let data: UnreadCountData
}

/// 未读数量数据
struct UnreadCountData: Codable {
    let unreadCount: Int
}

/// 标记所有已读响应
struct MarkAllReadResponse: Codable {
    let success: Bool
    let data: MarkAllReadData
    let message: String
}

/// 标记所有已读数据
struct MarkAllReadData: Codable {
    let updatedCount: Int
}

/// 批量删除响应
struct BatchDeleteResponse: Codable {
    let success: Bool
    let data: BatchDeleteData
    let message: String
}

/// 批量删除数据
struct BatchDeleteData: Codable {
    let deletedCount: Int
}

/// 清空所有响应
struct ClearAllResponse: Codable {
    let success: Bool
    let data: ClearAllData
    let message: String
}

/// 清空所有数据
struct ClearAllData: Codable {
    let deletedCount: Int
}

// MARK: - 扩展方法

extension String {
    /// 时间显示格式化
    var timeAgoDisplay: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: self) else {
            // 如果ISO8601解析失败，尝试其他格式
            let fallbackFormatter = DateFormatter()

            // 尝试 "yyyy-MM-dd HH:mm:ss" 格式（API实际返回的格式）
            fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let fallbackDate = fallbackFormatter.date(from: self) {
                return formatTimeDisplay(for: fallbackDate)
            }

            // 尝试带微秒的ISO8601格式
            fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            if let fallbackDate = fallbackFormatter.date(from: self) {
                return formatTimeDisplay(for: fallbackDate)
            }

            // 尝试标准ISO8601格式
            fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            if let fallbackDate = fallbackFormatter.date(from: self) {
                return formatTimeDisplay(for: fallbackDate)
            }

            print("⚠️ 无法解析时间格式: \(self)")
            return "刚刚"
        }

        return formatTimeDisplay(for: date)
    }

    /// 格式化时间显示
    private func formatTimeDisplay(for date: Date) -> String {

        let now = Date()
        let calendar = Calendar.current
        let timeInterval = now.timeIntervalSince(date)

        // 1分钟内显示"刚刚"
        if timeInterval < 60 {
            return "刚刚"
        }

        // 1小时内显示"X分钟前"
        if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分钟前"
        }

        // 今天显示具体时间 "HH:mm"
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }

        // 昨天显示 "昨天 HH:mm"
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return "昨天 \(timeFormatter.string(from: date))"
        }

        // 本周内显示 "周X HH:mm"
        if timeInterval < 604800 {
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.locale = Locale(identifier: "zh_CN")
            weekdayFormatter.dateFormat = "EEEE"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            let weekdayString = weekdayFormatter.string(from: date)
            // 将"星期一"转换为"周一"
            let chineseWeekday = weekdayString.replacingOccurrences(of: "星期", with: "周")
            return "\(chineseWeekday) \(timeFormatter.string(from: date))"
        }

        // 本年内显示 "MM-dd HH:mm"
        if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd HH:mm"
            return dateFormatter.string(from: date)
        }

        // 跨年显示 "yyyy-MM-dd HH:mm"
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return yearFormatter.string(from: date)
    }
}
