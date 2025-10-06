import Foundation
import SwiftUI

// MARK: - 聊天数据模型

/// 聊天会话
struct ChatConversation: Codable, Identifiable, Equatable {
    let id: String
    let title: String?
    let type: ConversationType
    let avatar: String?
    let lastMessage: LastMessage?
    let lastMessageAt: String?
    let unreadCount: Int?
    let isTop: Bool?
    let isMuted: Bool?
    let membersCount: Int?
    private let _creatorId: Int?
    let creator: ChatUser?
    let memberRecords: [MemberRecord]?
    let description: String?
    let maxMembers: Int?
    let createdAt: String?

    // 兼容旧字段
    var participants: [ChatUser] {
        return memberRecords?.compactMap { $0.user } ?? []
    }

    var isPinned: Bool { return isTop ?? false }
    var lastActiveAt: String { return lastMessageAt ?? "" }
    
    /// 群主ID - 从 creatorId 或 creator.id 获取
    var creatorId: Int? {
        // 优先使用直接的 creatorId 字段
        if let id = _creatorId {
            return id
        }
        // 如果没有，从 creator 对象中获取
        return creator?.id
    }
    
    // 自定义解码键
    enum CodingKeys: String, CodingKey {
        case id, title, type, avatar, lastMessage, lastMessageAt
        case unreadCount, isTop, isMuted, membersCount
        case _creatorId = "creatorId"
        case creator, memberRecords, description, maxMembers, createdAt
    }
    
    /// 自定义初始化器 - 用于手动创建实例
    init(
        id: String,
        title: String?,
        type: ConversationType,
        avatar: String?,
        lastMessage: LastMessage?,
        lastMessageAt: String?,
        unreadCount: Int?,
        isTop: Bool?,
        isMuted: Bool?,
        membersCount: Int?,
        creatorId: Int?,
        creator: ChatUser?,
        memberRecords: [MemberRecord]?,
        description: String?,
        maxMembers: Int?,
        createdAt: String?
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.avatar = avatar
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
        self.isTop = isTop
        self.isMuted = isMuted
        self.membersCount = membersCount
        self._creatorId = creatorId
        self.creator = creator
        self.memberRecords = memberRecords
        self.description = description
        self.maxMembers = maxMembers
        self.createdAt = createdAt
    }
    
    /// 显示名称
    var displayName: String {
        // 如果是私聊，需要特殊处理
        if type == .privateChat {
            // 获取当前用户ID
            let currentUserId = AuthManager.shared.getCurrentUserId() ?? 0

            // 方法1: 从 memberRecords 中找到对方用户（排除当前用户）
            if let memberRecords = memberRecords {
                let otherMembers = memberRecords.filter { $0.user.id != currentUserId }
                if let otherMember = otherMembers.first {
                    return otherMember.user.nickname
                }
            }

            // 方法2: 从参与者中找到对方用户（排除当前用户）
            let otherUsers = participants.filter { $0.id != currentUserId }
            if let otherUser = otherUsers.first {
                return otherUser.nickname
            }

            // 方法3: 从最后一条消息的发送者中获取对方用户信息
            if let lastMessage = lastMessage,
               lastMessage.sender.id != currentUserId {
                return lastMessage.sender.nickname
            }

            // 方法4: 如果最后一条消息是当前用户发送的，尝试从创建者信息获取
            if let creator = creator, creator.id != currentUserId {
                return creator.nickname
            }

            // 方法5: 如果没有其他信息，但有title，使用title（作为最后备选）
            if let title = title, !title.isEmpty {
                return title
            }

            // 最后的备选方案
            return "未知用户"
        }

        // 群聊优先使用title
        if let title = title, !title.isEmpty {
            return title
        }

        // 群聊显示参与者列表
        let names = participants.prefix(3).map { $0.nickname }
        if names.isEmpty {
            return "群聊"
        }
        return names.joined(separator: ", ")
    }


    
    /// 显示头像URL
    var displayAvatar: String? {
        if type == .privateChat {
            // 获取当前用户ID
            let currentUserId = AuthManager.shared.getCurrentUserId() ?? 0

            // 方法1: 从 memberRecords 中找到对方用户（排除当前用户）
            if let memberRecords = memberRecords {
                let otherMembers = memberRecords.filter { $0.user.id != currentUserId }
                if let otherMember = otherMembers.first {
                    return otherMember.user.avatar
                }
            }

            // 方法2: 从参与者中找到对方用户（排除当前用户）
            let otherUsers = participants.filter { $0.id != currentUserId }
            if let otherUser = otherUsers.first {
                return otherUser.avatar
            }

            // 方法3: 从最后一条消息的发送者中获取对方用户头像
            if let lastMessage = lastMessage,
               lastMessage.sender.id != currentUserId {
                return lastMessage.sender.avatar
            }

            // 方法4: 如果最后一条消息是当前用户发送的，尝试从创建者信息获取
            if let creator = creator, creator.id != currentUserId {
                return creator.avatar
            }
        }

        // 群聊返回群头像或nil
        return avatar
    }
    
    /// 最后消息时间显示
    var lastMessageTimeDisplay: String {
        guard let lastMessage = lastMessage else { return "" }
        return lastMessage.timeDisplay
    }
    
    /// 最后消息预览
    var lastMessagePreview: String {
        guard let lastMessage = lastMessage else { return "暂无消息" }

        // 在群聊中显示发送者昵称
        if type == .group {
            let currentUserId = AuthManager.shared.getCurrentUserId() ?? 0
            if lastMessage.sender.id == currentUserId {
                // 如果是自己发送的消息，显示"我："
                return "我: \(lastMessage.preview)"
            } else {
                // 如果是其他人发送的消息，显示昵称
                return "\(lastMessage.sender.nickname): \(lastMessage.preview)"
            }
        } else {
            // 私聊中不显示发送者昵称
            return lastMessage.preview
        }
    }
}

/// 聊天消息
struct ChatMessage: Codable, Identifiable {
    let id: String
    let conversationId: String
    let senderId: Int
    let content: String
    let type: MessageType
    let status: MessageStatus
    let isRecalled: Bool?
    let createdAt: String
    let sender: ChatUser
    let replyToMessageId: String?
    let mediaUrl: String?
    let mediaDuration: Int?
    let thumbnailUrl: String?

    // 兼容旧字段
    var senderInfo: ChatUser { return sender }
    var updatedAt: String { return createdAt }
    var replyToMessageContent: String? { return nil } // 简化处理
    var attachments: [MessageAttachment]? { return nil } // 暂时保持兼容
    var isDeleted: Bool { return isRecalled ?? false }
    var deletedAt: String? { return isRecalled == true ? createdAt : nil }

    // 自定义解码器来处理服务器返回的数据结构
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        content = try container.decode(String.self, forKey: .content)
        type = try container.decode(MessageType.self, forKey: .type)
        status = try container.decode(MessageStatus.self, forKey: .status)
        isRecalled = try container.decodeIfPresent(Bool.self, forKey: .isRecalled)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        sender = try container.decode(ChatUser.self, forKey: .sender)
        replyToMessageId = try container.decodeIfPresent(String.self, forKey: .replyToMessageId)
        mediaUrl = try container.decodeIfPresent(String.self, forKey: .mediaUrl)
        mediaDuration = try container.decodeIfPresent(Int.self, forKey: .mediaDuration)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)

        // 从 sender.id 提取 senderId，如果没有 senderId 字段的话
        if let explicitSenderId = try? container.decodeIfPresent(Int.self, forKey: .senderId) {
            senderId = explicitSenderId
        } else {
            senderId = sender.id
        }
    }

    // 自定义编码器
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(conversationId, forKey: .conversationId)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(content, forKey: .content)
        try container.encode(type, forKey: .type)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(isRecalled, forKey: .isRecalled)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(sender, forKey: .sender)
        try container.encodeIfPresent(replyToMessageId, forKey: .replyToMessageId)
        try container.encodeIfPresent(mediaUrl, forKey: .mediaUrl)
        try container.encodeIfPresent(mediaDuration, forKey: .mediaDuration)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
    }

    // 定义编码键
    private enum CodingKeys: String, CodingKey {
        case id, conversationId, senderId, content, type, status, isRecalled, createdAt, sender, replyToMessageId, mediaUrl, mediaDuration, thumbnailUrl
    }

    // 便利初始化方法
    init(
        id: String,
        conversationId: String,
        senderId: Int,
        content: String,
        type: MessageType,
        status: MessageStatus,
        isRecalled: Bool? = nil,
        createdAt: String,
        sender: ChatUser,
        replyToMessageId: String? = nil,
        mediaUrl: String? = nil,
        mediaDuration: Int? = nil,
        thumbnailUrl: String? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.type = type
        self.status = status
        self.isRecalled = isRecalled
        self.createdAt = createdAt
        self.sender = sender
        self.replyToMessageId = replyToMessageId
        self.mediaUrl = mediaUrl
        self.mediaDuration = mediaDuration
        self.thumbnailUrl = thumbnailUrl
    }
    
    /// 是否是自己发送的消息
    var isFromCurrentUser: Bool {
        // 这里需要从AuthManager获取当前用户ID进行比较
        return AuthManager.shared.currentUser?.id == senderId
    }
    
    /// 时间显示格式
    var timeDisplay: String {
        guard let date = parseDate(createdAt) else {
            return "刚刚"
        }

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

        // 24小时内显示"X小时前"
        if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)小时前"
        }

        // 昨天显示"昨天"
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "昨天"
        }

        // 一周内显示"星期X"
        if timeInterval < 604800 { // 7天
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.dateFormat = "EEEE"
            weekdayFormatter.locale = Locale(identifier: "zh_CN")
            return weekdayFormatter.string(from: date)
        }

        // 超过一周显示"MM月dd日"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.timeZone = TimeZone.current // 使用当前时区（北京时间）
        return dateFormatter.string(from: date)
    }

    /// 解析时间字符串，支持多种格式
    /// 后端返回的是北京时间，解析后直接使用
    private func parseDate(_ dateString: String) -> Date? {
        // 优先使用 ISO8601 格式解析（推荐）
        if #available(iOS 10.0, *) {
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // 尝试不带毫秒的格式
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
        }

        // 备用格式解析
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",     // 2025-08-22T13:30:00.000Z
            "yyyy-MM-dd'T'HH:mm:ss'Z'",       // 2025-08-22T13:30:00Z
            "yyyy-MM-dd'T'HH:mm:ssZ",         // 2025-08-22T13:30:00+0000
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",   // 2025-08-22T13:30:00.000Z
            "yyyy-MM-dd HH:mm:ss",            // 2025-08-22 13:30:00 (北京时间)
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            // 对于带时区信息的格式，让系统自动处理时区
            // 对于不带时区信息的格式，假设为北京时间（因为服务器已修改为北京时间）
            if !format.contains("Z") && !format.contains("z") {
                formatter.timeZone = TimeZone(identifier: "Asia/Shanghai") // 北京时间
            }

            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }
    
    /// 消息预览（用于聊天列表）
    var preview: String {
        switch type {
        case .text:
            return content
        case .image:
            return "[图片]"
        case .video:
            return "[视频]"
        case .audio:
            return "[语音]"
        case .file:
            return "[文件]"
        case .system:
            return content
        }
    }
}

/// 最后一条消息信息（用于对话列表）
struct LastMessage: Codable, Identifiable, Equatable {
    let id: String
    let content: String
    let type: MessageType
    let createdAt: String
    let sender: ChatUser

    /// 时间显示格式
    var timeDisplay: String {
        guard let date = parseDate(createdAt) else {
            return "刚刚"
        }

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

        // 24小时内显示"X小时前"
        if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)小时前"
        }

        // 昨天显示"昨天"
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "昨天"
        }

        // 一周内显示"星期X"
        if timeInterval < 604800 { // 7天
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.dateFormat = "EEEE"
            weekdayFormatter.locale = Locale(identifier: "zh_CN")
            weekdayFormatter.timeZone = TimeZone.current // 使用当前时区（北京时间）
            return weekdayFormatter.string(from: date)
        }

        // 超过一周显示"MM月dd日"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.timeZone = TimeZone.current // 使用当前时区（北京时间）
        return dateFormatter.string(from: date)
    }

    /// 消息预览（用于聊天列表）
    var preview: String {
        switch type {
        case .text:
            return content
        case .image:
            return "[图片]"
        case .video:
            return "[视频]"
        case .audio:
            return "[语音]"
        case .file:
            return "[文件]"
        case .system:
            return content
        }
    }

    /// 解析时间字符串，支持多种格式
    /// 后端返回的是北京时间，解析后直接使用
    private func parseDate(_ dateString: String) -> Date? {
        // 优先使用 ISO8601 格式解析（推荐）
        if #available(iOS 10.0, *) {
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // 尝试不带毫秒的格式
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
        }

        // 备用格式解析
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",     // 2025-08-22T13:30:00.000Z
            "yyyy-MM-dd'T'HH:mm:ss'Z'",       // 2025-08-22T13:30:00Z
            "yyyy-MM-dd'T'HH:mm:ssZ",         // 2025-08-22T13:30:00+0000
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",   // 2025-08-22T13:30:00.000Z
            "yyyy-MM-dd HH:mm:ss",            // 2025-08-22 13:30:00 (北京时间)
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            // 对于带时区信息的格式，让系统自动处理时区
            // 对于不带时区信息的格式，假设为北京时间（因为服务器已修改为北京时间）
            if !format.contains("Z") && !format.contains("z") {
                formatter.timeZone = TimeZone(identifier: "Asia/Shanghai") // 北京时间
            }

            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }
}

/// 群成员记录
struct MemberRecord: Codable, Identifiable, Equatable {
    let id: String
    let role: MemberRole
    let status: MemberStatus
    let joinedAt: String
    let user: ChatUser
}

/// 成员角色
enum MemberRole: String, Codable, CaseIterable {
    case owner = "owner"
    case admin = "admin"
    case member = "member"
}

/// 成员状态
enum MemberStatus: String, Codable, CaseIterable {
    case active = "active"
    case left = "left"
    case kicked = "kicked"
    case banned = "banned"
}

/// 聊天用户信息
struct ChatUser: Codable, Identifiable, Equatable {
    let id: Int
    let nickname: String
    let avatar: String?
    let isVerified: Bool?
    let isOnline: Bool?
    let lastSeenAt: String?

    // 标准初始化方法
    init(id: Int, nickname: String, avatar: String? = nil, isVerified: Bool? = nil, isOnline: Bool? = nil, lastSeenAt: String? = nil) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
        self.isVerified = isVerified
        self.isOnline = isOnline
        self.lastSeenAt = lastSeenAt
    }

    // 自定义解码器来处理服务器返回的数字格式布尔值
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        nickname = try container.decode(String.self, forKey: .nickname)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        lastSeenAt = try container.decodeIfPresent(String.self, forKey: .lastSeenAt)

        // 处理 isVerified 字段：可能是数字或布尔值
        if let verifiedInt = try? container.decodeIfPresent(Int.self, forKey: .isVerified) {
            isVerified = verifiedInt != 0
        } else {
            isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified)
        }

        // 处理 isOnline 字段：可能是数字或布尔值
        if let onlineInt = try? container.decodeIfPresent(Int.self, forKey: .isOnline) {
            isOnline = onlineInt != 0
        } else {
            isOnline = try container.decodeIfPresent(Bool.self, forKey: .isOnline)
        }
    }
    
    /// 在线状态显示
    var onlineStatusDisplay: String {
        guard let isOnline = isOnline else { return "未知" }

        if isOnline {
            return "在线"
        }

        guard let lastSeenAt = lastSeenAt else {
            return "离线"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        guard let date = formatter.date(from: lastSeenAt) else {
            return "离线"
        }

        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "刚刚在线"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前在线"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)小时前在线"
        } else {
            let days = Int(interval / 86400)
            return "\(days)天前在线"
        }
    }

    /// 从字典创建 ChatUser 实例
    static func fromDictionary(_ dict: [String: Any]) throws -> ChatUser {
        guard let id = dict["id"] as? Int,
              let nickname = dict["nickname"] as? String else {
            throw NetworkManager.NetworkError.decodingError
        }

        let avatar = dict["avatar"] as? String
        let lastSeenAt = dict["lastSeenAt"] as? String

        // 处理 isVerified 字段：可能是数字或布尔值
        var isVerified: Bool?
        if let verifiedInt = dict["isVerified"] as? Int {
            isVerified = verifiedInt != 0
        } else if let verifiedBool = dict["isVerified"] as? Bool {
            isVerified = verifiedBool
        }

        // 处理 isOnline 字段：可能是数字或布尔值
        var isOnline: Bool?
        if let onlineInt = dict["isOnline"] as? Int {
            isOnline = onlineInt != 0
        } else if let onlineBool = dict["isOnline"] as? Bool {
            isOnline = onlineBool
        }

        return ChatUser(
            id: id,
            nickname: nickname,
            avatar: avatar,
            isVerified: isVerified,
            isOnline: isOnline,
            lastSeenAt: lastSeenAt
        )
    }
}

/// 消息附件
struct MessageAttachment: Codable, Identifiable {
    let id: String
    let type: AttachmentType
    let url: String
    let thumbnailUrl: String?
    let fileName: String?
    let fileSize: Int?
    let duration: Int? // 音频/视频时长（秒）
    let width: Int?
    let height: Int?
}

// MARK: - 枚举定义

/// 会话类型
enum ConversationType: String, Codable, CaseIterable {
    case privateChat = "private"    // 私聊
    case group = "group"        // 群聊
    case system = "system"      // 系统消息
}



/// 消息类型
enum MessageType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case video = "video"
    case audio = "audio"
    case file = "file"
    case system = "system"
}

/// 消息状态
enum MessageStatus: String, Codable, CaseIterable {
    case sending = "sending"    // 发送中
    case sent = "sent"          // 已发送
    case delivered = "delivered" // 已送达
    case read = "read"          // 已读
    case failed = "failed"      // 发送失败
}

/// 附件类型
enum AttachmentType: String, Codable, CaseIterable {
    case image = "image"
    case video = "video"
    case audio = "audio"
    case file = "file"
}

// MARK: - API请求和响应模型

/// 聊天列表请求
struct ChatListRequest: Codable {
    let page: Int
    let limit: Int
    let type: ConversationType?
    let keyword: String?
}

/// 聊天列表响应
struct ChatListResponse: Codable {
    let items: [ChatConversation]
    let pagination: PaginationInfo

    // 兼容旧字段
    var conversations: [ChatConversation] { return items }
    var total: Int { return pagination.totalItems }
    var page: Int { return pagination.currentPage }
    var limit: Int { return pagination.totalItems > 0 ? pagination.totalItems / max(1, pagination.totalPages) : 20 }

    // 自定义解码器来处理服务器返回的数据结构
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 尝试解码items数组，如果失败则尝试conversations字段
        if let itemsArray = try? container.decode([ChatConversation].self, forKey: .items) {
            items = itemsArray
        } else if let conversationsArray = try? container.decode([ChatConversation].self, forKey: .conversations) {
            items = conversationsArray
        } else {
            items = []
        }

        // 尝试解码pagination对象，如果失败则从其他字段构建
        if let paginationObj = try? container.decode(PaginationInfo.self, forKey: .pagination) {
            pagination = paginationObj
        } else {
            // 从服务器返回的字段构建分页信息
            let total = try container.decodeIfPresent(Int.self, forKey: .total) ?? 0
            let page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
            let limit = try container.decodeIfPresent(Int.self, forKey: .limit) ?? 20

            let totalPages = limit > 0 ? (total + limit - 1) / limit : 1
            let hasNextPage = page < totalPages
            let hasPrevPage = page > 1

            pagination = PaginationInfo(
                currentPage: page,
                totalPages: totalPages,
                totalItems: total,
                hasNext: hasNextPage,
                hasPrevious: hasPrevPage
            )
        }
    }

    // 编码器
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(pagination, forKey: .pagination)
    }

    private enum CodingKeys: String, CodingKey {
        case items, pagination, conversations, total, page, limit
    }
}

/// 消息列表请求
struct MessageListRequest: Codable {
    let conversationId: String
    let page: Int
    let limit: Int
    let beforeMessageId: String?
}

/// 消息列表响应
struct MessageListResponse: Codable {
    let items: [ChatMessage]
    let hasMore: Bool

    // 兼容旧字段
    var messages: [ChatMessage] { return items }

    // 创建一个简化的分页信息
    var pagination: SimplePaginationInfo {
        return SimplePaginationInfo(
            page: 1,
            limit: items.count,
            total: items.count,
            totalPages: 1,
            hasNextPage: hasMore,
            hasPreviousPage: false
        )
    }
}

/// 简化的分页信息（用于聊天消息）
struct SimplePaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasNextPage: Bool
    let hasPreviousPage: Bool
}

/// 发送消息请求
struct SendMessageRequest: Codable {
    let content: String
    let type: MessageType
    let mediaUrl: String?
    let mediaDuration: Int?
    let thumbnailUrl: String?
    let replyToMessageId: String?

    // 兼容旧字段
    var attachments: [String]? {
        if let mediaUrl = mediaUrl {
            return [mediaUrl]
        }
        return nil
    }
}

/// 发送消息响应
struct SendMessageResponse: Codable {
    let message: ChatMessage
}

/// 创建私聊请求
struct CreatePrivateChatRequest: Codable {
    let recipientId: Int
    let initialMessage: String?
}

/// 创建群聊请求
struct CreateGroupChatRequest: Codable {
    let name: String
    let description: String?
    let avatar: String?
    let memberIds: [Int]
}

/// 创建会话请求（兼容旧版本）
struct CreateConversationRequest: Codable {
    let type: ConversationType
    let participantIds: [Int]
    let title: String?
}

/// 创建会话响应
struct CreateConversationResponse: Codable {
    let conversation: ChatConversation
}

/// 标记消息已读请求
struct MarkAsReadRequest: Codable {
    let lastReadMessageId: String
}

/// 转发消息请求
struct ForwardMessageRequest: Codable {
    let conversationIds: [String]
}

/// 转发消息响应
struct ForwardMessageResponse: Codable {
    let forwardedCount: Int
}

/// 添加群成员请求
struct AddGroupMembersRequest: Codable {
    let memberIds: [Int]
}

/// 更新群信息请求
struct UpdateGroupInfoRequest: Codable {
    let name: String?
    let description: String?
    let avatar: String?
}

/// 清空聊天记录请求
struct ClearChatHistoryRequest: Codable {
    let clearType: String // "soft" 或 "hard"
}

/// 添加群成员响应
struct AddGroupMembersResponse: Codable {
    let addedCount: Int
    let addedUsers: [ChatUser]
}

/// 聊天统计响应
struct ChatStatisticsResponse: Codable {
    let messageCount: Int
    let memberCount: Int
    let createdAt: String
    let lastActiveAt: String
}

/// 导出聊天记录响应
struct ExportChatHistoryResponse: Codable {
    let url: String?
    let data: String?
}

// MARK: - API响应包装器

/// 聊天API响应基础结构
struct ChatAPIResponse<T: Codable>: Codable {
    let status: String?     // 可选，兼容不同响应格式
    let success: Bool?      // 布尔值格式的成功标识
    let data: T?
    let message: String?

    // 自定义解码器来处理不同的响应格式
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 尝试解码status字段（字符串格式）
        status = try container.decodeIfPresent(String.self, forKey: .status)
        
        // 尝试解码success字段（布尔值格式）
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        
        // 解码data和message字段
        data = try container.decodeIfPresent(T.self, forKey: .data)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }
    
    // 编码器
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(success, forKey: .success)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(message, forKey: .message)
    }
    
    private enum CodingKeys: String, CodingKey {
        case status, success, data, message
    }

    var isSuccess: Bool {
        // 优先检查布尔值格式的success字段
        if let success = success {
            return success
        }
        // 然后检查字符串格式的status字段
        if let status = status {
            return status == "success"
        }
        // 如果都没有，默认为false
        return false
    }
}

/// 分页信息（复用现有的）
// PaginationInfo 已在 CommunityModels.swift 中定义，这里不重复定义

// MARK: - 本地存储模型

/// 草稿消息
struct DraftMessage: Codable {
    let conversationId: String
    let content: String
    let createdAt: Date
}

/// 聊天设置
struct ChatSettings: Codable {
    let enableNotifications: Bool
    let enableSounds: Bool
    let enableVibration: Bool
    let fontSize: ChatFontSize
    let theme: ChatTheme
}

enum ChatFontSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var displayName: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
}

enum ChatTheme: String, Codable, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

// MARK: - 聊天分类

/// 聊天分类
enum ChatCategory: String, CaseIterable {
    case all = "all"
    case unread = "unread"
    case privateChat = "private"
    case group = "group"
    case notification = "notification"

    var displayName: String {
        switch self {
        case .all: return "全部"
        case .unread: return "未读"
        case .privateChat: return "私聊"
        case .group: return "群聊"
        case .notification: return "通知"
        }
    }

    var iconName: String {
        switch self {
        case .all: return "bubble.left.and.bubble.right"
        case .unread: return "circle.fill"
        case .privateChat: return "person"
        case .group: return "person.2"
        case .notification: return "bell.fill"
        }
    }
}

// MARK: - 上传响应模型

/// 图片上传响应
struct ImageUploadResponse: Codable {
    let url: String
    let thumbnails: ImageThumbnails?
    let filename: String
    let originalName: String
    let size: Int
    let mimetype: String
    let provider: String
    let metadata: ImageMetadata?
}

/// 图片缩略图
struct ImageThumbnails: Codable {
    let small: String?
    let medium: String?
    let large: String?
}

/// 图片元数据
struct ImageMetadata: Codable {
    let width: Int?
    let height: Int?
    let format: String?
}

/// 文档上传响应
struct DocumentUploadResponse: Codable {
    let url: String
    let filename: String
    let originalName: String
    let size: Int
    let mimetype: String
    let provider: String
}

/// 语音上传响应
struct AudioUploadResponse: Codable {
    let url: String
    let filename: String
    let originalName: String
    let size: Int
    let duration: Int?
    let mimetype: String
    let provider: String
}

/// 附件上传响应
struct AttachmentUploadResponse: Codable {
    let url: String
    let filename: String
    let originalName: String
    let size: Int
    let mimetype: String
}
