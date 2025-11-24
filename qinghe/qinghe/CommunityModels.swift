import Foundation

// MARK: - API错误类型
enum APIError: Error {
    case invalidData(String)
    case networkError(String)
    case serverError(String)

    var localizedDescription: String {
        switch self {
        case .invalidData(let message):
            return "数据错误: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .serverError(let message):
            return "服务器错误: \(message)"
        }
    }
}

// MARK: - 评论排序类型
enum CommentSortType: String, CaseIterable {
    case newest = "newest"
    case oldest = "oldest"
    case hottest = "hottest"

    var displayName: String {
        switch self {
        case .newest: return "最新"
        case .oldest: return "最早"
        case .hottest: return "最热"
        }
    }

    var icon: String {
        switch self {
        case .newest: return "clock"
        case .oldest: return "clock.arrow.circlepath"
        case .hottest: return "flame"
        }
    }
}

// MARK: - 社区Tab类型
enum CommunityTab: String, CaseIterable {
    case following = "following"
    case recommended = "recommended"
    case nearby = "nearby"

    var displayName: String {
        switch self {
        case .following: return "关注"
        case .recommended: return "推荐"
        case .nearby: return "同城"
        }
    }

    var apiValue: String {
        return self.rawValue
    }
}

// MARK: - 帖子分类
enum PostCategory: String, CaseIterable {
    case all = "all"
    case life = "life"
    case sports = "sports"
    case sleep = "sleep"
    case discipline = "discipline"
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .life: return "生活"
        case .sports: return "运动"
        case .sleep: return "睡眠"
        case .discipline: return "自律"
        }
    }
}

// MARK: - 帖子可见性
enum PostVisibility: String, CaseIterable, Codable, Hashable {
    case `public` = "public"
    case followers = "followers"
    case `private` = "private"

    var displayName: String {
        switch self {
        case .public: return "公开"
        case .followers: return "好友可见"
        case .private: return "仅自己可见"
        }
    }

    var icon: String {
        switch self {
        case .public: return "globe"
        case .followers: return "person.2"
        case .private: return "lock"
        }
    }
}

// MARK: - 帖子状态
enum PostStatus: String, Codable, Hashable {
    case active = "active"
    case hidden = "hidden"
    case deleted = "deleted"
    case reported = "reported"
}

// MARK: - 举报原因
enum ReportReason: String, CaseIterable {
    case spam = "spam"
    case inappropriate = "inappropriate"
    case harassment = "harassment"
    case violence = "violence"
    case copyright = "copyright"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .spam: return "垃圾信息"
        case .inappropriate: return "不当内容"
        case .harassment: return "骚扰"
        case .violence: return "暴力内容"
        case .copyright: return "版权问题"
        case .other: return "其他"
        }
    }
}

// MARK: - 作者信息
struct Author: Codable, Identifiable, Hashable {
    let id: Int
    let nickname: String
    let avatar: String?
    let isVerified: Bool
    let level: Int?
    let followersCount: Int?
    var isFollowing: Bool? // 我是否关注了该用户
    var isFollowedBy: Bool? // 该用户是否关注了我
    let isMember: Bool? // 是否为会员

    // 默认初始化器
    init(id: Int, nickname: String, avatar: String?, isVerified: Bool, level: Int?, followersCount: Int?, isFollowing: Bool? = nil, isFollowedBy: Bool? = nil, isMember: Bool? = nil) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
        self.isVerified = isVerified
        self.level = level
        self.followersCount = followersCount
        self.isFollowing = isFollowing
        self.isFollowedBy = isFollowedBy
        self.isMember = isMember
    }

    // 自定义解码器处理isVerified的类型转换
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        nickname = try container.decode(String.self, forKey: .nickname)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        level = try container.decodeIfPresent(Int.self, forKey: .level)
        followersCount = try container.decodeIfPresent(Int.self, forKey: .followersCount)
        isFollowing = try container.decodeIfPresent(Bool.self, forKey: .isFollowing)
        isFollowedBy = try container.decodeIfPresent(Bool.self, forKey: .isFollowedBy)

        // 处理isVerified字段，可能是Bool或Int
        if let boolValue = try? container.decode(Bool.self, forKey: .isVerified) {
            isVerified = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isVerified) {
            isVerified = intValue != 0
        } else {
            isVerified = false
        }

        // 处理isMember字段，可能是Bool或Int
        if let memberBool = try? container.decodeIfPresent(Bool.self, forKey: .isMember) {
            isMember = memberBool
        } else if let memberInt = try? container.decodeIfPresent(Int.self, forKey: .isMember) {
            isMember = memberInt != 0
        } else {
            isMember = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, nickname, avatar, isVerified, level, followersCount, isFollowing, isFollowedBy, isMember
    }

}

// MARK: - 类型别名
typealias PostAuthor = Author

// MARK: - 帖子模型
struct Post: Codable, Identifiable, Hashable {
    let id: String
    let authorId: Int
    let content: String
    let images: [String]?
    let video: String?
    let videoCover: String?  // 视频封面图
    let videoThumbnails: [String]?  // 视频缩略图数组
    let tags: [String]?
    let category: String?  // 改为可选，因为推荐接口可能不返回此字段
    let location: String?
    let latitude: String?
    let longitude: String?
    let checkinId: Int?
    let workoutId: Int?
    let dataType: String?
    var likesCount: Int
    var commentsCount: Int
    var sharesCount: Int
    var bookmarksCount: Int
    var viewsCount: Int
    var isLiked: Bool
    var isBookmarked: Bool
    let allowComments: Bool
    let allowShares: Bool
    let visibility: PostVisibility
    let status: PostStatus
    let isTop: Bool
    let hotScore: Double
    let isAIGenerated: Bool?  // AI生成内容标识
    let lastActiveAt: String
    let createdAt: String
    let updatedAt: String
    var author: Author
    let checkin: CheckinData?
    let workout: PostWorkoutData?

    // 推荐系统相关字段
    let finalScore: Double?
    let explanation: String?
    let strategy: String?
    
    // 格式化时间显示
    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: createdAt) else { return "" }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    // 格式化为具体日期时间显示（用于社区列表）
    var formattedDateTime: String {
        // 尝试服务器返回的格式：2025-08-06 10:23:42
        let serverFormatter = DateFormatter()
        serverFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if let date = serverFormatter.date(from: createdAt) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            return outputFormatter.string(from: date)
        }

        // 尝试 ISO8601 格式
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: createdAt) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            return outputFormatter.string(from: date)
        }

        // 如果解析失败，直接返回原始字符串的前16个字符（yyyy-MM-dd HH:mm）
        return String(createdAt.prefix(16))
    }


    // 帖子分类枚举
    var categoryEnum: PostCategory {
        guard let category = category else { return .life }
        return PostCategory(rawValue: category) ?? .life
    }

    // 常规初始化器（用于预览和测试）
    init(
        id: String,
        authorId: Int,
        content: String,
        images: [String]? = nil,
        video: String? = nil,
        videoCover: String? = nil,
        videoThumbnails: [String]? = nil,
        tags: [String]? = nil,
        category: String? = nil,
        location: String? = nil,
        latitude: String? = nil,
        longitude: String? = nil,
        checkinId: Int? = nil,
        workoutId: Int? = nil,
        dataType: String? = nil,
        likesCount: Int = 0,
        commentsCount: Int = 0,
        sharesCount: Int = 0,
        bookmarksCount: Int = 0,
        viewsCount: Int = 0,
        isLiked: Bool = false,
        isBookmarked: Bool = false,
        allowComments: Bool = true,
        allowShares: Bool = true,
        visibility: PostVisibility = .public,
        status: PostStatus = .active,
        isTop: Bool = false,
        hotScore: Double = 0.0,
        isAIGenerated: Bool? = nil,
        lastActiveAt: String,
        createdAt: String,
        updatedAt: String,
        author: Author,
        checkin: CheckinData? = nil,
        workout: PostWorkoutData? = nil,
        finalScore: Double? = nil,
        explanation: String? = nil,
        strategy: String? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.content = content
        self.images = images
        self.video = video
        self.videoCover = videoCover
        self.videoThumbnails = videoThumbnails
        self.tags = tags
        self.category = category
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.checkinId = checkinId
        self.workoutId = workoutId
        self.dataType = dataType
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.sharesCount = sharesCount
        self.bookmarksCount = bookmarksCount
        self.viewsCount = viewsCount
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
        self.allowComments = allowComments
        self.allowShares = allowShares
        self.visibility = visibility
        self.status = status
        self.isTop = isTop
        self.hotScore = hotScore
        self.isAIGenerated = isAIGenerated
        self.lastActiveAt = lastActiveAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.author = author
        self.checkin = checkin
        self.workout = workout
        self.finalScore = finalScore
        self.explanation = explanation
        self.strategy = strategy
    }

    // 自定义解码器，处理缺失的字段
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        authorId = try container.decode(Int.self, forKey: .authorId)
        content = try container.decode(String.self, forKey: .content)
        images = try container.decodeIfPresent([String].self, forKey: .images)
        video = try container.decodeIfPresent(String.self, forKey: .video)
        videoCover = try container.decodeIfPresent(String.self, forKey: .videoCover)
        videoThumbnails = try container.decodeIfPresent([String].self, forKey: .videoThumbnails)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        latitude = try container.decodeIfPresent(String.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(String.self, forKey: .longitude)
        checkinId = try container.decodeIfPresent(Int.self, forKey: .checkinId)
        // 处理 workoutId 字段，可能是字符串或整数
        if let workoutIdString = try? container.decodeIfPresent(String.self, forKey: .workoutId) {
            workoutId = Int(workoutIdString)
        } else {
            workoutId = try container.decodeIfPresent(Int.self, forKey: .workoutId)
        }
        dataType = try container.decodeIfPresent(String.self, forKey: .dataType)
        likesCount = try container.decode(Int.self, forKey: .likesCount)
        commentsCount = try container.decode(Int.self, forKey: .commentsCount)
        sharesCount = try container.decode(Int.self, forKey: .sharesCount)
        bookmarksCount = try container.decode(Int.self, forKey: .bookmarksCount)
        viewsCount = try container.decode(Int.self, forKey: .viewsCount)

        // 处理布尔字段，可能缺失或是Bool/Int类型
        if let boolValue = try? container.decode(Bool.self, forKey: .isLiked) {
            isLiked = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isLiked) {
            isLiked = intValue != 0
        } else {
            isLiked = false  // 默认值
        }

        if let boolValue = try? container.decode(Bool.self, forKey: .isBookmarked) {
            isBookmarked = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isBookmarked) {
            isBookmarked = intValue != 0
        } else {
            isBookmarked = false  // 默认值
        }

        // 处理allowComments字段，可能是Bool或Int
        if let boolValue = try? container.decode(Bool.self, forKey: .allowComments) {
            allowComments = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .allowComments) {
            allowComments = intValue != 0
        } else {
            allowComments = true  // 默认值
        }

        // 处理allowShares字段，可能是Bool或Int
        if let boolValue = try? container.decode(Bool.self, forKey: .allowShares) {
            allowShares = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .allowShares) {
            allowShares = intValue != 0
        } else {
            allowShares = true  // 默认值
        }

        // 处理visibility字段
        if let visibilityString = try? container.decode(String.self, forKey: .visibility) {
            visibility = PostVisibility(rawValue: visibilityString) ?? .public
        } else {
            visibility = .public  // 默认值
        }

        // 处理status字段
        if let statusString = try? container.decode(String.self, forKey: .status) {
            status = PostStatus(rawValue: statusString) ?? .active
        } else {
            status = .active  // 默认值
        }

        // 处理isTop字段，可能是Bool或Int
        if let boolValue = try? container.decode(Bool.self, forKey: .isTop) {
            isTop = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isTop) {
            isTop = intValue != 0
        } else {
            isTop = false  // 默认值
        }

        hotScore = try container.decodeIfPresent(Double.self, forKey: .hotScore) ?? 0.0

        // 处理 isAIGenerated 字段，可能是Bool或Int或不存在
        if let boolValue = try? container.decode(Bool.self, forKey: .isAIGenerated) {
            isAIGenerated = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isAIGenerated) {
            isAIGenerated = intValue != 0
        } else {
            isAIGenerated = nil  // 如果字段不存在，设为 nil
        }

        lastActiveAt = try container.decodeIfPresent(String.self, forKey: .lastActiveAt) ?? ""
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        author = try container.decode(Author.self, forKey: .author)
        checkin = try container.decodeIfPresent(CheckinData.self, forKey: .checkin)
        workout = try container.decodeIfPresent(PostWorkoutData.self, forKey: .workout)

        // 推荐系统相关字段
        finalScore = try container.decodeIfPresent(Double.self, forKey: .finalScore)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
        strategy = try container.decodeIfPresent(String.self, forKey: .strategy)
    }



    private enum CodingKeys: String, CodingKey {
        case id, authorId, content, images, video, videoCover, videoThumbnails, tags, category, location, latitude, longitude
        case checkinId, workoutId, dataType, likesCount, commentsCount, sharesCount, bookmarksCount, viewsCount
        case isLiked, isBookmarked, allowComments, allowShares, visibility, status, isTop, hotScore, isAIGenerated
        case lastActiveAt, createdAt, updatedAt, author, checkin, workout
        case finalScore, explanation, strategy
    }
}

// MARK: - 打卡数据（关联数据）
struct CheckinData: Codable, Hashable {
    let id: Int
    let date: String
    let time: String
    let locationAddress: String?
    let locationLatitude: Double?
    let locationLongitude: Double?
    let note: String?
    let consecutiveDays: Int? // 连续打卡天数
}

// MARK: - 运动数据（关联数据）
struct PostWorkoutData: Codable, Hashable {
    let id: Int?  // 改为可选，因为服务器可能不返回此字段
    let workoutId: Int
    let workoutType: String
    let startTime: String
    let endTime: String
    let duration: Int
    let totalDistance: String?
    let totalSteps: Int?
    let calories: Int?
    let averagePace: String?
    let notes: String?

    // 自定义解码器来处理 id 和 workoutId 可能是字符串的情况
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 处理 id 字段，可能是字符串、整数或不存在
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = Int(idString)
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = idInt
        } else {
            id = nil  // 如果字段不存在，设为 nil
        }

        // 处理 workoutId 字段，可能是字符串或整数
        if let workoutIdString = try? container.decode(String.self, forKey: .workoutId) {
            workoutId = Int(workoutIdString) ?? 0
        } else {
            workoutId = try container.decode(Int.self, forKey: .workoutId)
        }

        workoutType = try container.decode(String.self, forKey: .workoutType)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        duration = try container.decode(Int.self, forKey: .duration)
        totalDistance = try container.decodeIfPresent(String.self, forKey: .totalDistance)
        totalSteps = try container.decodeIfPresent(Int.self, forKey: .totalSteps)
        calories = try container.decodeIfPresent(Int.self, forKey: .calories)
        averagePace = try container.decodeIfPresent(String.self, forKey: .averagePace)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }

    private enum CodingKeys: String, CodingKey {
        case id, workoutId, workoutType, startTime, endTime, duration
        case totalDistance, totalSteps, calories, averagePace, notes
    }
}

// MARK: - 推荐信息
struct RecommendationInfo: Codable {
    let strategy: String
    let algorithm: String
    let version: String
}

// MARK: - 帖子列表响应
struct PostListResponse: Codable {
    let items: [Post]
    let pagination: PaginationInfo
    let recommendationInfo: RecommendationInfo?  // 推荐接口会返回此字段
}



// MARK: - 帖子详情响应
struct PostDetailResponse: Codable {
    let success: Bool
    let data: Post
    let message: String?
}

// MARK: - 点赞响应
struct LikeResponse: Codable {
    let success: Bool
    let data: LikeData
    let message: String
}

struct LikeData: Codable {
    let isLiked: Bool
}

// MARK: - 收藏响应
struct BookmarkResponse: Codable {
    let success: Bool
    let data: BookmarkData
    let message: String
}

struct BookmarkData: Codable {
    let isBookmarked: Bool
}

// MARK: - 分享响应
struct ShareResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - 举报请求
struct ReportRequest: Codable {
    let reason: String
    let description: String?
}

// MARK: - 举报响应
struct ReportResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - 评论模型
struct Comment: Codable, Identifiable {
    let id: String
    let postId: String
    let authorId: Int
    let content: String
    let parentCommentId: String?
    let rootCommentId: String?
    let replyToUserId: Int?
    var likesCount: Int
    var repliesCount: Int
    let level: Int
    let status: String
    let isTop: Bool
    var isLiked: Bool = false
    let createdAt: String
    let updatedAt: String?
    let author: Author
    let replyToUser: Author?

    // 新增属性用于支持无限级嵌套和状态管理
    var replies: [Comment] = []
    var isExpanded: Bool = false
    var isLoadingReplies: Bool = false

    // 格式化时间显示
    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: createdAt) else { return "" }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    // 自定义编码，排除运行时属性
    enum CodingKeys: String, CodingKey {
        case id, postId, authorId, content, parentCommentId, rootCommentId, replyToUserId
        case likesCount, repliesCount, level, status, isTop, isLiked
        case createdAt, updatedAt, author, replyToUser
    }

    // 自定义解码器，处理缺失的字段
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        postId = try container.decode(String.self, forKey: .postId)
        authorId = try container.decode(Int.self, forKey: .authorId)
        content = try container.decode(String.self, forKey: .content)
        parentCommentId = try container.decodeIfPresent(String.self, forKey: .parentCommentId)
        rootCommentId = try container.decodeIfPresent(String.self, forKey: .rootCommentId)
        replyToUserId = try container.decodeIfPresent(Int.self, forKey: .replyToUserId)
        likesCount = try container.decode(Int.self, forKey: .likesCount)
        repliesCount = try container.decode(Int.self, forKey: .repliesCount)
        level = try container.decode(Int.self, forKey: .level)
        status = try container.decode(String.self, forKey: .status)
        isTop = try container.decode(Bool.self, forKey: .isTop)
        // 如果服务器没有返回 isLiked 字段，默认为 false
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        author = try container.decode(Author.self, forKey: .author)
        replyToUser = try container.decodeIfPresent(Author.self, forKey: .replyToUser)

        // 运行时属性设置默认值
        replies = []
        isExpanded = false
        isLoadingReplies = false
    }

    // 自定义初始化器，支持所有属性
    init(id: String, postId: String = "", authorId: Int, content: String,
         parentCommentId: String? = nil, rootCommentId: String? = nil, replyToUserId: Int? = nil,
         likesCount: Int = 0, repliesCount: Int = 0, level: Int = 0,
         status: String = "active", isTop: Bool = false, isLiked: Bool = false,
         createdAt: String, updatedAt: String? = nil, author: Author, replyToUser: Author? = nil,
         replies: [Comment] = [], isExpanded: Bool = false, isLoadingReplies: Bool = false) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.content = content
        self.parentCommentId = parentCommentId
        self.rootCommentId = rootCommentId
        self.replyToUserId = replyToUserId
        self.likesCount = likesCount
        self.repliesCount = repliesCount
        self.level = level
        self.status = status
        self.isTop = isTop
        self.isLiked = isLiked
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.author = author
        self.replyToUser = replyToUser
        self.replies = replies
        self.isExpanded = isExpanded
        self.isLoadingReplies = isLoadingReplies
    }
}

// MARK: - 分页信息
struct PaginationInfo: Codable {
    // 原始字段，支持多种API格式
    private let _page: Int?
    private let _currentPage: Int?
    private let _limit: Int?
    private let _total: Int?
    private let _totalItems: Int?
    private let _totalCheckins: Int?
    private let _totalPages: Int?
    private let _hasNext: Bool?
    private let _hasNextPage: Bool?
    private let _hasPrev: Bool?
    private let _hasPrevPage: Bool?

    // 普通初始化器
    init(currentPage: Int, totalPages: Int, totalItems: Int, hasNext: Bool, hasPrevious: Bool) {
        self._currentPage = currentPage
        self._totalPages = totalPages
        self._totalItems = totalItems
        self._hasNext = hasNext
        self._hasPrev = hasPrevious

        // 其他字段设为nil
        self._page = nil
        self._limit = nil
        self._total = nil
        self._totalCheckins = nil
        self._hasNextPage = nil
        self._hasPrevPage = nil
    }

    // 自定义解码器来处理服务器返回的数字格式布尔值
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 解码数字字段
        _page = try container.decodeIfPresent(Int.self, forKey: ._page)
        _currentPage = try container.decodeIfPresent(Int.self, forKey: ._currentPage)
        _limit = try container.decodeIfPresent(Int.self, forKey: ._limit)

        // 处理 total 字段，可能是字符串或整数
        if let totalString = try? container.decodeIfPresent(String.self, forKey: ._total) {
            _total = Int(totalString)
        } else {
            _total = try container.decodeIfPresent(Int.self, forKey: ._total)
        }

        _totalItems = try container.decodeIfPresent(Int.self, forKey: ._totalItems)
        _totalCheckins = try container.decodeIfPresent(Int.self, forKey: ._totalCheckins)

        // 处理 totalPages 字段，可能是字符串或整数
        if let totalPagesString = try? container.decodeIfPresent(String.self, forKey: ._totalPages) {
            _totalPages = Int(totalPagesString)
        } else {
            _totalPages = try container.decodeIfPresent(Int.self, forKey: ._totalPages)
        }

        // 处理 hasNext 字段：可能是数字或布尔值
        if let hasNextInt = try? container.decodeIfPresent(Int.self, forKey: ._hasNext) {
            _hasNext = hasNextInt != 0
        } else {
            _hasNext = try container.decodeIfPresent(Bool.self, forKey: ._hasNext)
        }

        // 处理 hasNextPage 字段：可能是数字或布尔值
        if let hasNextPageInt = try? container.decodeIfPresent(Int.self, forKey: ._hasNextPage) {
            _hasNextPage = hasNextPageInt != 0
        } else {
            _hasNextPage = try container.decodeIfPresent(Bool.self, forKey: ._hasNextPage)
        }

        // 处理 hasPrev 字段：可能是数字或布尔值
        if let hasPrevInt = try? container.decodeIfPresent(Int.self, forKey: ._hasPrev) {
            _hasPrev = hasPrevInt != 0
        } else {
            _hasPrev = try container.decodeIfPresent(Bool.self, forKey: ._hasPrev)
        }

        // 处理 hasPrevPage 字段：可能是数字或布尔值
        if let hasPrevPageInt = try? container.decodeIfPresent(Int.self, forKey: ._hasPrevPage) {
            _hasPrevPage = hasPrevPageInt != 0
        } else {
            _hasPrevPage = try container.decodeIfPresent(Bool.self, forKey: ._hasPrevPage)
        }
    }

    // 计算属性，提供统一的访问接口
    var page: Int {
        return _currentPage ?? _page ?? 1
    }

    var currentPage: Int {
        return _currentPage ?? _page ?? 1
    }

    var limit: Int {
        return _limit ?? 10
    }

    var total: Int {
        return _totalCheckins ?? _totalItems ?? _total ?? 0
    }

    var totalItems: Int {
        return _totalCheckins ?? _totalItems ?? _total ?? 0
    }

    var totalPages: Int {
        return _totalPages ?? 1
    }

    var hasNext: Bool {
        return _hasNextPage ?? _hasNext ?? false
    }

    var hasNextPage: Bool {
        return _hasNextPage ?? _hasNext ?? false
    }

    var hasPrev: Bool {
        return _hasPrevPage ?? _hasPrev ?? false
    }

    var hasPrevPage: Bool {
        return _hasPrevPage ?? _hasPrev ?? false
    }

    // 自定义编码键，处理多种API格式
    private enum CodingKeys: String, CodingKey {
        case _page = "page"
        case _currentPage = "currentPage"
        case _limit = "limit"
        case _total = "total"
        case _totalItems = "total_items"
        case _totalCheckins = "totalCheckins"
        case _totalPages = "totalPages"
        case _hasNext = "hasNext"
        case _hasNextPage = "hasNextPage"
        case _hasPrev = "hasPrev"
        case _hasPrevPage = "hasPrevPage"
    }
}

// MARK: - 评论列表响应
struct CommentListResponse: Codable {
    let success: Bool
    let data: CommentListData
}

struct CommentListData: Codable {
    let items: [Comment]
    let pagination: PaginationInfo
}

// MARK: - 评论请求
struct CommentRequest: Codable {
    let content: String
    let parentCommentId: String?
    let replyToUserId: Int?
}

// MARK: - 评论响应
struct CommentResponse: Codable {
    let success: Bool
    let data: Comment
    let message: String
}

// MARK: - API响应基础结构
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
}

// MARK: - 社区API响应结构
struct CommunityAPIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
}

// MARK: - 创建评论请求
struct CreateCommentRequest: Codable {
    let content: String
    let parentCommentId: String?
    let replyToUserId: Int?
}

// MARK: - 关注响应
struct FollowResponse: Codable {
    let isFollowing: Bool
    let followersCount: Int?
}

// MARK: - 关注状态响应
struct FollowStatusResponse: Codable {
    let isFollowing: Bool
    let followersCount: Int?
    let followingCount: Int?
}

// MARK: - 用户列表响应
struct UserListResponse: Codable {
    var items: [UserProfile]
    let pagination: PaginationInfo
}

// MARK: - 用户API响应格式
struct UserAPIResponse<T: Codable>: Codable {
    let status: String
    let data: T?
    let message: String?

    var success: Bool {
        return status == "success"
    }
}

// MARK: - 实际用户API响应格式（匹配真实API）
struct ActualUserAPIResponse<T: Codable>: Codable {
    let success: Int
    let data: T?
    let message: String?

    var isSuccess: Bool {
        return success == 1
    }
}

// MARK: - 布尔值用户API响应格式（处理服务器返回布尔值的情况）
struct BooleanUserAPIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?

    var isSuccess: Bool {
        return success
    }
}

// MARK: - 屏蔽/取消屏蔽响应数据
struct BlockUserData: Codable {
    let isBlocked: Bool
    let canFollow: Bool?  // 屏蔽接口不返回此字段，只有取消屏蔽时返回
    let isFollowing: Bool?  // 屏蔽接口返回此字段
}

// MARK: - 屏蔽用户列表响应
struct BlockedUsersResponse: Codable {
    let items: [BlockedUser]
    let pagination: PaginationInfo
}

// MARK: - 屏蔽用户信息
struct BlockedUser: Codable, Identifiable {
    let id: Int  // API 实际返回的是数字类型的 ID
    let nickname: String
    let avatar: String?
    let bio: String?
    let isVerified: Bool?
    let blockedAt: String
    let reason: String?
}

// MARK: - 错误响应
struct ErrorResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - 搜索相关模型

/// 搜索请求
struct SearchRequest: Codable {
    let q: String           // 搜索关键词
    let type: String        // 搜索类型: all, posts, users, topics
    let sort: String        // 排序方式: latest, hot, relevant
    let page: Int           // 页码
    let limit: Int          // 每页数量
}

/// 搜索响应
struct SearchResponse: Codable {
    let success: Int
    let data: SearchData?
    let message: String?

    // 计算属性，将整数转换为布尔值
    var isSuccess: Bool {
        return success == 1
    }
}

/// 搜索数据
struct SearchData: Codable {
    let keyword: String?
    let type: String?
    let sort: String?
    let results: SearchResults
    let pagination: PaginationInfo?

    // 计算属性，从results中获取total
    var total: Int {
        return results.total
    }
}

/// 实际搜索响应数据（匹配真实API）
struct ActualSearchData: Codable {
    let keyword: String?
    let type: String?
    let sort: String?
    let results: SearchResults
    let pagination: PaginationInfo
}

/// 实际搜索响应（匹配真实API）
struct ActualSearchResponse: Codable {
    let success: Int
    let data: ActualSearchData?
    let message: String?

    // 计算属性，将整数转换为布尔值
    var isSuccess: Bool {
        return success == 1
    }
    
    // 自定义解码器，处理success字段的类型转换
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 处理success字段，可能是Bool或Int
        if let boolValue = try? container.decode(Bool.self, forKey: .success) {
            success = boolValue ? 1 : 0
        } else if let intValue = try? container.decode(Int.self, forKey: .success) {
            success = intValue
        } else {
            success = 0
        }
        
        data = try container.decodeIfPresent(ActualSearchData.self, forKey: .data)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }
    
    private enum CodingKeys: String, CodingKey {
        case success, data, message
    }
}

/// 话题搜索结果模型
struct TopicSearchResult: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let count: Int?
    let description: String?

    private enum CodingKeys: String, CodingKey {
        case name, count, description
    }

    // 实现 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(count)
        hasher.combine(description)
    }

    static func == (lhs: TopicSearchResult, rhs: TopicSearchResult) -> Bool {
        return lhs.name == rhs.name && lhs.count == rhs.count && lhs.description == rhs.description
    }
}

/// 搜索结果
struct SearchResults: Codable {
    let posts: [CommunityPost]?
    let users: [CommunityUserProfile]?
    let topics: [String]?   // 话题名数组（后端返回字符串列表）
    let total: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        posts = try container.decodeIfPresent([CommunityPost].self, forKey: .posts)
        users = try container.decodeIfPresent([CommunityUserProfile].self, forKey: .users)
        topics = try container.decodeIfPresent([String].self, forKey: .topics)
        total = try container.decodeIfPresent(Int.self, forKey: .total) ?? 0
    }

    private enum CodingKeys: String, CodingKey { case posts, users, topics, total }
}

/// 社区帖子模型（用于搜索结果）
struct CommunityPost: Codable, Identifiable {
    let id: String
    let authorId: Int
    let content: String
    let images: [String]?
    let video: String?
    let tags: [String]?
    let category: String?
    let location: String?
    let latitude: String?
    let longitude: String?
    let checkinId: Int?
    let workoutId: Int?
    let dataType: String?
    var likesCount: Int
    var commentsCount: Int
    var sharesCount: Int
    var bookmarksCount: Int
    var viewsCount: Int
    var isLiked: Bool
    var isBookmarked: Bool
    let allowComments: Bool
    let allowShares: Bool
    let visibility: String
    let status: String
    let isTop: Bool
    let hotScore: Double
    let lastActiveAt: String
    let createdAt: String
    let updatedAt: String
    let author: Author
    let checkin: CheckinData?
    let workout: PostWorkoutData?

    // 自定义解码器来处理各种字段类型转换
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)

        // authorId 可能不存在，从 author.id 获取
        if let authorIdValue = try? container.decodeIfPresent(Int.self, forKey: .authorId) {
            authorId = authorIdValue
        } else {
            // 如果没有 authorId，先解码 author 然后获取其 id
            let authorData = try container.decode(Author.self, forKey: .author)
            authorId = authorData.id
        }

        content = try container.decode(String.self, forKey: .content)
        images = try container.decodeIfPresent([String].self, forKey: .images)
        video = try container.decodeIfPresent(String.self, forKey: .video)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        latitude = try container.decodeIfPresent(String.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(String.self, forKey: .longitude)

        // 处理 checkinId 字段，可能是字符串或整数
        if let checkinIdString = try? container.decodeIfPresent(String.self, forKey: .checkinId) {
            checkinId = Int(checkinIdString)
        } else {
            checkinId = try container.decodeIfPresent(Int.self, forKey: .checkinId)
        }

        // 处理 workoutId 字段，可能是字符串或整数
        if let workoutIdString = try? container.decodeIfPresent(String.self, forKey: .workoutId) {
            workoutId = Int(workoutIdString)
        } else {
            workoutId = try container.decodeIfPresent(Int.self, forKey: .workoutId)
        }

        dataType = try container.decodeIfPresent(String.self, forKey: .dataType)
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
        commentsCount = try container.decodeIfPresent(Int.self, forKey: .commentsCount) ?? 0
        sharesCount = try container.decodeIfPresent(Int.self, forKey: .sharesCount) ?? 0
        bookmarksCount = try container.decodeIfPresent(Int.self, forKey: .bookmarksCount) ?? 0
        viewsCount = try container.decodeIfPresent(Int.self, forKey: .viewsCount) ?? 0

        // 处理布尔字段，可能缺失或是Bool/Int类型
        if let boolValue = try? container.decode(Bool.self, forKey: .isLiked) {
            isLiked = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isLiked) {
            isLiked = intValue != 0
        } else {
            isLiked = false
        }

        if let boolValue = try? container.decode(Bool.self, forKey: .isBookmarked) {
            isBookmarked = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isBookmarked) {
            isBookmarked = intValue != 0
        } else {
            isBookmarked = false
        }

        // 处理allowComments字段
        if let boolValue = try? container.decode(Bool.self, forKey: .allowComments) {
            allowComments = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .allowComments) {
            allowComments = intValue != 0
        } else {
            allowComments = true
        }

        // 处理allowShares字段
        if let boolValue = try? container.decode(Bool.self, forKey: .allowShares) {
            allowShares = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .allowShares) {
            allowShares = intValue != 0
        } else {
            allowShares = true
        }

        visibility = try container.decodeIfPresent(String.self, forKey: .visibility) ?? "public"
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"

        // 处理isTop字段
        if let boolValue = try? container.decode(Bool.self, forKey: .isTop) {
            isTop = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isTop) {
            isTop = intValue != 0
        } else {
            isTop = false
        }

        hotScore = try container.decodeIfPresent(Double.self, forKey: .hotScore) ?? 0.0

        // lastActiveAt 可能不存在，使用 createdAt 作为默认值
        createdAt = try container.decode(String.self, forKey: .createdAt)
        lastActiveAt = try container.decodeIfPresent(String.self, forKey: .lastActiveAt) ?? createdAt
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? createdAt

        author = try container.decode(Author.self, forKey: .author)
        checkin = try container.decodeIfPresent(CheckinData.self, forKey: .checkin)
        workout = try container.decodeIfPresent(PostWorkoutData.self, forKey: .workout)
    }

    private enum CodingKeys: String, CodingKey {
        case id, authorId, content, images, video, tags, category, location, latitude, longitude
        case checkinId, workoutId, dataType, likesCount, commentsCount, sharesCount, bookmarksCount, viewsCount
        case isLiked, isBookmarked, allowComments, allowShares, visibility, status, isTop, hotScore
        case lastActiveAt, createdAt, updatedAt, author, checkin, workout
    }

    // 普通初始化器
    init(id: String, authorId: Int, content: String, images: [String]?, video: String?, tags: [String]?, category: String?, location: String?, latitude: String?, longitude: String?, checkinId: Int?, workoutId: Int?, dataType: String?, likesCount: Int, commentsCount: Int, sharesCount: Int, bookmarksCount: Int, viewsCount: Int, isLiked: Bool, isBookmarked: Bool, allowComments: Bool, allowShares: Bool, visibility: String, status: String, isTop: Bool, hotScore: Double, lastActiveAt: String, createdAt: String, updatedAt: String, author: Author, checkin: CheckinData?, workout: PostWorkoutData?) {
        self.id = id
        self.authorId = authorId
        self.content = content
        self.images = images
        self.video = video
        self.tags = tags
        self.category = category
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.checkinId = checkinId
        self.workoutId = workoutId
        self.dataType = dataType
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.sharesCount = sharesCount
        self.bookmarksCount = bookmarksCount
        self.viewsCount = viewsCount
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
        self.allowComments = allowComments
        self.allowShares = allowShares
        self.visibility = visibility
        self.status = status
        self.isTop = isTop
        self.hotScore = hotScore
        self.lastActiveAt = lastActiveAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.author = author
        self.checkin = checkin
        self.workout = workout
    }



    // 格式化时间显示
    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: createdAt) else { return "" }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

/// 社区用户资料模型（用于搜索结果）
struct CommunityUserProfile: Codable, Identifiable {
    let id: Int
    let nickname: String
    let avatar: String?
    let isVerified: Bool
    let level: Int?
    let followersCount: Int?
    let followingCount: Int?
    let postsCount: Int?
    let bio: String?
    var isFollowing: Bool?
    var isFollowedBy: Bool?

    // 默认初始化器
    init(id: Int, nickname: String, avatar: String?, isVerified: Bool, level: Int?, followersCount: Int?, followingCount: Int?, postsCount: Int?, bio: String?, isFollowing: Bool?, isFollowedBy: Bool? = nil) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
        self.isVerified = isVerified
        self.level = level
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.postsCount = postsCount
        self.bio = bio
        self.isFollowing = isFollowing
        self.isFollowedBy = isFollowedBy
    }

    // 自定义解码器处理isVerified的类型转换
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        nickname = try container.decode(String.self, forKey: .nickname)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        level = try container.decodeIfPresent(Int.self, forKey: .level)
        followersCount = try container.decodeIfPresent(Int.self, forKey: .followersCount)
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount)
        postsCount = try container.decodeIfPresent(Int.self, forKey: .postsCount)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        isFollowing = try container.decodeIfPresent(Bool.self, forKey: .isFollowing)
        isFollowedBy = try container.decodeIfPresent(Bool.self, forKey: .isFollowedBy)

        // 处理isVerified字段，可能是Bool或Int
        if let boolValue = try? container.decode(Bool.self, forKey: .isVerified) {
            isVerified = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isVerified) {
            isVerified = intValue != 0
        } else {
            isVerified = false
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, nickname, avatar, isVerified, level, followersCount, followingCount, postsCount, bio, isFollowing, isFollowedBy
    }
}

/// 热门话题模型（后端实际返回的数据结构）
struct TrendingTopic: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String
    let color: String
    let icon: String
    let postCount: Int
    let userCount: Int

    // 实现 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }

    static func == (lhs: TrendingTopic, rhs: TrendingTopic) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}

/// 热门搜索关键词（用于UI显示）
struct TrendingKeyword: Codable, Identifiable, Hashable {
    let id = UUID()
    let keyword: String
    let count: Int
    let trend: String  // "up", "down", "stable"

    private enum CodingKeys: String, CodingKey {
        case keyword, count, trend
    }

    // 从TrendingTopic创建TrendingKeyword的便利初始化器
    init(from topic: TrendingTopic) {
        self.keyword = topic.name
        self.count = topic.postCount
        self.trend = topic.postCount > 10 ? "up" : (topic.postCount > 5 ? "stable" : "down")
    }

    init(keyword: String, count: Int, trend: String) {
        self.keyword = keyword
        self.count = count
        self.trend = trend
    }

    // 实现 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(keyword)
        hasher.combine(count)
        hasher.combine(trend)
    }

    static func == (lhs: TrendingKeyword, rhs: TrendingKeyword) -> Bool {
        return lhs.keyword == rhs.keyword && lhs.count == rhs.count && lhs.trend == rhs.trend
    }
}

/// 热门搜索响应（匹配后端实际返回的数据结构）
struct TrendingSearchResponse: Codable {
    let success: Bool
    let data: [TrendingTopic]?
    let message: String?
    let meta: TrendingSearchMeta?
}

/// 热门搜索元数据
struct TrendingSearchMeta: Codable {
    let limit: Int
    let days: Int
}

// MARK: - 标签相关模型

/// 标签帖子列表响应
struct TagPostsResponse: Codable {
    let success: Bool
    let data: TagPostsData?
    let message: String?
}

/// 标签帖子数据
struct TagPostsData: Codable {
    let tagName: String
    let items: [Post]
    let pagination: PaginationInfo
}



/// 标签排序方式枚举
enum TagSortType: String, CaseIterable {
    case latest = "latest"    // 按最新时间排序（默认）
    case hot = "hot"         // 按热度排序（综合点赞、评论、分享）
    case popular = "popular" // 按流行度排序（基于互动数据）

    var displayName: String {
        switch self {
        case .latest:
            return "最新"
        case .hot:
            return "热门"
        case .popular:
            return "流行"
        }
    }
}

// MARK: - 同城功能相关模型

/// 同城搜索区域信息
struct NearbySearchArea: Codable {
    let latitude: Double
    let longitude: Double
    let radius: Double
}

/// 同城帖子数据
struct NearbyPostsData: Codable {
    let items: [NearbyPost]
    let pagination: PaginationInfo
    let location: NearbySearchArea?
}

/// 同城帖子响应
struct NearbyPostsResponse: Codable {
    let success: Bool
    let data: NearbyPostsData?
    let message: String?
}

/// 同城帖子模型（扩展自Post，增加距离信息）
struct NearbyPost: Codable, Identifiable {
    let id: String
    let authorId: Int
    let content: String
    let images: [String]?
    let video: String?
    let tags: [String]?
    let location: String?
    let latitude: String?
    let longitude: String?
    var likesCount: Int
    var commentsCount: Int
    var sharesCount: Int
    var bookmarksCount: Int
    var viewsCount: Int
    var isLiked: Bool
    var isBookmarked: Bool
    let allowComments: Bool
    let allowShares: Bool
    let visibility: String
    let status: String
    let isTop: Bool
    let hotScore: Double
    let lastActiveAt: String
    let createdAt: String
    let updatedAt: String
    let author: Author
    let distance: Double  // 距离（米）
    let distanceText: String  // 距离文本，如 "1.2km"
    
    // 转换为Post模型
    func toPost() -> Post {
        return Post(
            id: id,
            authorId: authorId,
            content: content,
            images: images,
            video: video,
            tags: tags,
            category: nil,
            location: location,
            latitude: latitude,
            longitude: longitude,
            checkinId: nil,
            workoutId: nil,
            dataType: nil,
            likesCount: likesCount,
            commentsCount: commentsCount,
            sharesCount: sharesCount,
            bookmarksCount: bookmarksCount,
            viewsCount: viewsCount,
            isLiked: isLiked,
            isBookmarked: isBookmarked,
            allowComments: allowComments,
            allowShares: allowShares,
            visibility: PostVisibility(rawValue: visibility) ?? .public,
            status: PostStatus(rawValue: status) ?? .active,
            isTop: isTop,
            hotScore: hotScore,
            lastActiveAt: lastActiveAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            author: author
        )
    }
    
    // 自定义解码器
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        authorId = try container.decode(Int.self, forKey: .authorId)
        content = try container.decode(String.self, forKey: .content)
        images = try container.decodeIfPresent([String].self, forKey: .images)
        video = try container.decodeIfPresent(String.self, forKey: .video)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        latitude = try container.decodeIfPresent(String.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(String.self, forKey: .longitude)
        
        likesCount = try container.decode(Int.self, forKey: .likesCount)
        commentsCount = try container.decode(Int.self, forKey: .commentsCount)
        sharesCount = try container.decode(Int.self, forKey: .sharesCount)
        bookmarksCount = try container.decode(Int.self, forKey: .bookmarksCount)
        viewsCount = try container.decode(Int.self, forKey: .viewsCount)
        
        // 处理布尔字段
        if let boolValue = try? container.decode(Bool.self, forKey: .isLiked) {
            isLiked = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isLiked) {
            isLiked = intValue != 0
        } else {
            isLiked = false
        }
        
        if let boolValue = try? container.decode(Bool.self, forKey: .isBookmarked) {
            isBookmarked = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isBookmarked) {
            isBookmarked = intValue != 0
        } else {
            isBookmarked = false
        }
        
        if let boolValue = try? container.decode(Bool.self, forKey: .allowComments) {
            allowComments = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .allowComments) {
            allowComments = intValue != 0
        } else {
            allowComments = true
        }
        
        if let boolValue = try? container.decode(Bool.self, forKey: .allowShares) {
            allowShares = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .allowShares) {
            allowShares = intValue != 0
        } else {
            allowShares = true
        }
        
        visibility = try container.decodeIfPresent(String.self, forKey: .visibility) ?? "public"
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
        
        if let boolValue = try? container.decode(Bool.self, forKey: .isTop) {
            isTop = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isTop) {
            isTop = intValue != 0
        } else {
            isTop = false
        }
        
        hotScore = try container.decodeIfPresent(Double.self, forKey: .hotScore) ?? 0.0
        lastActiveAt = try container.decodeIfPresent(String.self, forKey: .lastActiveAt) ?? ""
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        author = try container.decode(Author.self, forKey: .author)
        distance = try container.decode(Double.self, forKey: .distance)
        distanceText = try container.decode(String.self, forKey: .distanceText)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, authorId, content, images, video, tags, location, latitude, longitude
        case likesCount, commentsCount, sharesCount, bookmarksCount, viewsCount
        case isLiked, isBookmarked, allowComments, allowShares, visibility, status, isTop, hotScore
        case lastActiveAt, createdAt, updatedAt, author, distance, distanceText
    }
}

/// 同城用户响应
struct NearbyUsersResponse: Codable {
    let success: Bool
    let data: NearbyUsersData?
    let message: String?
}

/// 同城用户数据
struct NearbyUsersData: Codable {
    let items: [NearbyUser]
    let pagination: PaginationInfo
}

/// 同城用户模型
struct NearbyUser: Codable, Identifiable {
    let id: Int
    let nickname: String
    let avatar: String?
    let isVerified: Bool
    let level: Int?
    let location: String?
    let distance: Double
    let distanceText: String
    let lastActiveAt: String?
}

// MARK: - 频道系统

/// 频道类型
enum ChannelType: String, Codable {
    case `static` = "static"     // 固定频道
    case dynamic = "dynamic"     // 动态频道（活动）
    case seasonal = "seasonal"   // 节气频道
}

/// 频道模型
struct Channel: Codable, Identifiable, Hashable {
    let id: Int
    let key: String              // 频道唯一标识
    let name: String             // 频道名称
    let icon: String             // 频道图标 emoji
    let description: String      // 频道描述
    let type: ChannelType        // 频道类型
    let parentCategory: String   // 父分类
    let sortOrder: Int           // 排序顺序
    let isOfficial: Bool         // 是否官方频道
    let coverImage: String?      // 封面图片
    let postsCount: Int          // 帖子数量
    let followersCount: Int      // 关注数量
    let solarTerm: String?       // 节气名称（仅节气频道）
    let activityTheme: String?   // 活动主题（仅活动频道）
    let startDate: String?       // 开始时间（动态频道）
    let endDate: String?         // 结束时间（动态频道）
    let createdAt: String

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Channel, rhs: Channel) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 频道列表API响应
struct ChannelsResponse: Codable {
    let success: Bool
    let data: [Channel]
    let count: Int
    let message: String?
}
