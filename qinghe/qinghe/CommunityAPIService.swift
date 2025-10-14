import Foundation

// MARK: - API Response Models
struct PopularTagsResponse: Codable {
    let success: Bool
    let data: [PopularTag]?
    let message: String?
}

struct CreatePostResponse: Codable {
    let success: Bool
    let message: String
    let data: CreatePostData?
    let moderationStatus: String?
    let moderationDetails: [ModerationDetail]?

    // 普通初始化器（用于模拟数据）
    init(success: Bool, message: String, data: CreatePostData? = nil, moderationStatus: String? = nil, moderationDetails: [ModerationDetail]? = nil) {
        self.success = success
        self.message = message
        self.data = data
        self.moderationStatus = moderationStatus
        self.moderationDetails = moderationDetails
    }

    // 自定义解码器来处理后端返回的数字格式success字段
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 处理success字段，支持数字和布尔值两种格式
        if let successInt = try? container.decode(Int.self, forKey: .success) {
            success = successInt == 1
        } else if let successBool = try? container.decode(Bool.self, forKey: .success) {
            success = successBool
        } else if let successString = try? container.decode(String.self, forKey: .success) {
            success = (successString == "1" || successString.lowercased() == "true")
        } else {
            success = false
        }

        message = (try? container.decode(String.self, forKey: .message)) ?? ""
        data = try container.decodeIfPresent(CreatePostData.self, forKey: .data)
        moderationStatus = try container.decodeIfPresent(String.self, forKey: .moderationStatus)
        moderationDetails = try container.decodeIfPresent([ModerationDetail].self, forKey: .moderationDetails)
    }

    enum CodingKeys: String, CodingKey {
        case success, message, data, moderationStatus, moderationDetails
    }
}

// 审核详情模型
struct ModerationDetail: Codable {
    let type: String?
    let taskId: String?
    let action: String?
    let risk: String?
    let message: String?
    let requiresReview: Bool?
    let canPublish: Bool?
    let violations: [ModerationViolation]?
    let imageUrl: String?
    let index: Int?
}

struct ModerationViolation: Codable {
    let description: String?
    let label: String?
    let confidence: Double?
    let riskLevel: String?

    enum CodingKeys: String, CodingKey {
        case description = "Description"
        case label = "Label"
        case confidence = "Confidence"
        case riskLevel = "RiskLevel"
    }
}

// MARK: - Post Interaction User Models
struct PostInteractionUser: Codable, Identifiable {
    let id: String
    let nickname: String
    let avatar: String?
    let isVerified: Bool
    let likedAt: String?
    let bookmarkedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, nickname, avatar, isVerified, likedAt, bookmarkedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as either Int or String
        if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = try container.decode(String.self, forKey: .id)
        }
        
        self.nickname = try container.decode(String.self, forKey: .nickname)
        self.avatar = try? container.decode(String.self, forKey: .avatar)
        
        // Handle isVerified as either Bool or Int (0/1)
        if let boolValue = try? container.decode(Bool.self, forKey: .isVerified) {
            self.isVerified = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isVerified) {
            self.isVerified = intValue != 0
        } else {
            self.isVerified = false
        }
        
        self.likedAt = try? container.decode(String.self, forKey: .likedAt)
        self.bookmarkedAt = try? container.decode(String.self, forKey: .bookmarkedAt)
    }
}

struct PostInteractionUsersData: Codable {
    let items: [PostInteractionUser]
    let pagination: PaginationInfo
}

// Note: PaginationInfo is already defined in CommunityModels.swift

struct PostInteractionUsersResponse: Codable {
    let success: Bool
    let data: PostInteractionUsersData?
    let message: String?
}

struct CreatePostData: Codable {
    let id: String
    let authorId: Int
    let content: String
    let images: [String]?
    let video: String?
    let tags: [String]?
    let status: String
    // 后端可能返回 Bool 或 Int，这里保持 Int，并在解码时兼容两种类型
    let allowComments: Int
    let allowShares: Int
    let visibility: String
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let bookmarksCount: Int
    let viewsCount: Int
    let hotScore: Double
    let isTop: Int
    let location: String?
    let latitude: String?
    let longitude: String?
    let checkinId: String?
    let workoutId: String?
    let createdAt: String
    let updatedAt: String
    let lastActiveAt: String
    let author: PostAuthor?

    // 简化的初始化器（用于模拟数据）
    init(postId: Int, status: String) {
        self.id = String(postId)
        self.authorId = 1
        self.content = ""
        self.images = nil
        self.video = nil
        self.tags = nil
        self.status = status
        self.allowComments = 1
        self.allowShares = 1
        self.visibility = "public"
        self.likesCount = 0
        self.commentsCount = 0
        self.sharesCount = 0
        self.bookmarksCount = 0
        self.viewsCount = 0
        self.hotScore = 0.0
        self.isTop = 0
        self.location = nil
        self.latitude = nil
        self.longitude = nil
        self.checkinId = nil
        self.workoutId = nil
        self.createdAt = ""
        self.updatedAt = ""
        self.lastActiveAt = ""
        self.author = nil
    }

    // 为了兼容性，提供一个计算属性来获取postId
    var postId: Int {
        return Int(id) ?? Int(id.hashValue)
    }

    enum CodingKeys: String, CodingKey {
        case id, authorId, content, images, video, tags, status
        case allowComments, allowShares, visibility
        case likesCount, commentsCount, sharesCount, bookmarksCount, viewsCount
        case hotScore, isTop, location, latitude, longitude
        case checkinId, workoutId, createdAt, updatedAt, lastActiveAt, author
    }

    // 自定义解码器：兼容 allowComments/allowShares 返回 Bool 或 Int；isTop 返回 Bool 或 Int；部分字段提供类型兼容
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // id 可能为字符串或数字
        if let idString = try? container.decode(String.self, forKey: .id) {
            self.id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            self.id = String(idInt)
        } else {
            // 若缺失，则置空字符串避免崩溃
            self.id = ""
        }

        // 常规必填字段
        if let authorIdVal = try? container.decode(Int.self, forKey: .authorId) {
            self.authorId = authorIdVal
        } else if let authorIdStr = try? container.decode(String.self, forKey: .authorId), let val = Int(authorIdStr) {
            self.authorId = val
        } else {
            self.authorId = 0
        }

        self.content = (try? container.decode(String.self, forKey: .content)) ?? ""
        self.images = try? container.decodeIfPresent([String].self, forKey: .images)
        self.video = try? container.decodeIfPresent(String.self, forKey: .video)
        self.tags = try? container.decodeIfPresent([String].self, forKey: .tags)
        self.status = (try? container.decode(String.self, forKey: .status)) ?? ""

        // 兼容 Bool/Int -> Int(0/1)
        if let boolVal = try? container.decode(Bool.self, forKey: .allowComments) {
            self.allowComments = boolVal ? 1 : 0
        } else if let intVal = try? container.decode(Int.self, forKey: .allowComments) {
            self.allowComments = intVal
        } else {
            self.allowComments = 1
        }

        if let boolVal = try? container.decode(Bool.self, forKey: .allowShares) {
            self.allowShares = boolVal ? 1 : 0
        } else if let intVal = try? container.decode(Int.self, forKey: .allowShares) {
            self.allowShares = intVal
        } else {
            self.allowShares = 1
        }

        self.visibility = (try? container.decode(String.self, forKey: .visibility)) ?? "public"

        self.likesCount = (try? container.decode(Int.self, forKey: .likesCount)) ?? 0
        self.commentsCount = (try? container.decode(Int.self, forKey: .commentsCount)) ?? 0
        self.sharesCount = (try? container.decode(Int.self, forKey: .sharesCount)) ?? 0
        self.bookmarksCount = (try? container.decode(Int.self, forKey: .bookmarksCount)) ?? 0
        self.viewsCount = (try? container.decode(Int.self, forKey: .viewsCount)) ?? 0

        if let d = try? container.decode(Double.self, forKey: .hotScore) {
            self.hotScore = d
        } else if let s = try? container.decode(String.self, forKey: .hotScore), let d = Double(s) {
            self.hotScore = d
        } else if let i = try? container.decode(Int.self, forKey: .hotScore) {
            self.hotScore = Double(i)
        } else {
            self.hotScore = 0
        }

        // isTop 支持 Bool 或 Int
        if let boolVal = try? container.decode(Bool.self, forKey: .isTop) {
            self.isTop = boolVal ? 1 : 0
        } else if let intVal = try? container.decode(Int.self, forKey: .isTop) {
            self.isTop = intVal
        } else {
            self.isTop = 0
        }

        self.location = try? container.decodeIfPresent(String.self, forKey: .location)
        self.latitude = try? container.decodeIfPresent(String.self, forKey: .latitude)
        self.longitude = try? container.decodeIfPresent(String.self, forKey: .longitude)

        // checkinId 可能为字符串、数字或 null
        if let cidInt = try? container.decode(Int.self, forKey: .checkinId) {
            self.checkinId = String(cidInt)
        } else if let cidStr = try? container.decode(String.self, forKey: .checkinId) {
            self.checkinId = cidStr
        } else {
            self.checkinId = nil
        }

        // workoutId 可能为字符串、数字或 null
        if let widInt = try? container.decode(Int.self, forKey: .workoutId) {
            self.workoutId = String(widInt)
        } else if let widStr = try? container.decode(String.self, forKey: .workoutId) {
            self.workoutId = widStr
        } else {
            self.workoutId = nil
        }

        self.createdAt = (try? container.decode(String.self, forKey: .createdAt)) ?? ""
        self.updatedAt = (try? container.decode(String.self, forKey: .updatedAt)) ?? ""
        self.lastActiveAt = (try? container.decode(String.self, forKey: .lastActiveAt)) ?? ""

        self.author = try? container.decodeIfPresent(PostAuthor.self, forKey: .author)
    }
}

/// 社区API服务类
class CommunityAPIService {
    static let shared = CommunityAPIService()
    
    private let networkManager = NetworkManager.shared
    private let authManager = AuthManager.shared
    
    init() {}
    
    // MARK: - API端点
    private enum Endpoint {
        static let posts = "/community/posts"
        static let postDetail = "/community/posts"
        static let postLike = "/community/posts"
        static let postBookmark = "/community/posts"
        static let postShare = "/community/posts"
        static let postReport = "/community/posts"
        static let comments = "/community/posts"
        static let commentDelete = "/community/comments"  // 新增：专门用于删除评论
        static let commentLike = "/community/comments"
        static let commentReplies = "/community/comments"
        static let search = "/community/search"
        static let trendingSearch = "/community/trending-search"
        static let tags = "/community/tags"
        static let popularTags = "/community/tags/popular"
    }
    
    // MARK: - 帖子管理
    
    /// 获取帖子列表
    /// - Parameters:
    ///   - tab: 标签页类型
    ///   - category: 分类
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 帖子列表响应
    func getPosts(
        tab: CommunityTab? = nil,
        category: PostCategory? = nil,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> PostListResponse {
        
        var parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        
        if let tab = tab {
            parameters["tab"] = tab.rawValue
        }
        
        if let category = category, category != .all {
            parameters["category"] = category.rawValue
        }
        
        let headers = authManager.getAuthHeader()
        
        let response: APIResponse<PostListResponse> = try await networkManager.get(
            endpoint: Endpoint.posts,
            parameters: parameters,
            headers: headers,
            responseType: APIResponse<PostListResponse>.self
        )
        
        guard response.success, let data = response.data else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取帖子列表失败")
        }
        
        return data
    }
    
    /// 获取帖子详情
    /// - Parameter postId: 帖子ID
    /// - Returns: 帖子详情响应
    func getPostDetail(postId: String) async throws -> CommunityAPIResponse<Post> {
        let headers = authManager.getAuthHeader()

        let response: PostDetailResponse = try await networkManager.get(
            endpoint: "\(Endpoint.postDetail)/\(postId)",
            headers: headers,
            responseType: PostDetailResponse.self
        )

        return CommunityAPIResponse(success: response.success, data: response.data, message: response.message)
    }
    
    /// 编辑帖子
    /// - Parameters:
    ///   - postId: 帖子ID
    ///   - content: 新内容
    ///   - images: 图片URLs
    ///   - tags: 标签
    ///   - category: 分类
    ///   - allowComments: 是否允许评论
    /// - Returns: 更新后的帖子
    func updatePost(
        postId: String,
        content: String? = nil,
        images: [String]? = nil,
        tags: [String]? = nil,
        category: PostCategory? = nil,
        allowComments: Bool? = nil
    ) async throws -> Post {
        
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        var parameters: [String: Any] = [:]
        
        if let content = content {
            parameters["content"] = content
        }
        if let images = images {
            parameters["images"] = images
        }
        if let tags = tags {
            parameters["tags"] = tags
        }
        if let category = category {
            parameters["category"] = category.rawValue
        }
        if let allowComments = allowComments {
            parameters["allowComments"] = allowComments
        }
        
        let response: PostDetailResponse = try await networkManager.request(
            endpoint: "\(Endpoint.postDetail)/\(postId)",
            method: .PUT,
            parameters: parameters,
            headers: authHeaders,
            responseType: PostDetailResponse.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "更新帖子失败")
        }
        
        return response.data
    }
    
    /// 删除帖子
    /// - Parameter postId: 帖子ID
    /// - Returns: 删除响应
    func deletePost(postId: String) async throws -> CommunityAPIResponse<String> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: APIResponse<String> = try await networkManager.request(
            endpoint: "\(Endpoint.postDetail)/\(postId)",
            method: .DELETE,
            headers: authHeaders,
            responseType: APIResponse<String>.self
        )

        return CommunityAPIResponse(success: response.success, data: response.data, message: response.message)
    }
    
    // MARK: - 帖子互动
    
    /// 切换点赞状态
    /// - Parameter postId: 帖子ID
    /// - Returns: 点赞结果
    func toggleLike(postId: String) async throws -> LikeData {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: LikeResponse = try await networkManager.post(
            endpoint: "\(Endpoint.postLike)/\(postId)/like",
            headers: authHeaders,
            responseType: LikeResponse.self
        )

        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message)
        }

        return response.data
    }

    /// 切换帖子点赞状态（新方法名）
    /// - Parameter postId: 帖子ID
    /// - Returns: API响应
    func toggleLikePost(postId: String) async throws -> CommunityAPIResponse<LikeData> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: LikeResponse = try await networkManager.post(
            endpoint: "\(Endpoint.postLike)/\(postId)/like",
            headers: authHeaders,
            responseType: LikeResponse.self
        )

        return CommunityAPIResponse(success: response.success, data: response.data, message: response.message)
    }
    
    /// 切换收藏状态
    /// - Parameter postId: 帖子ID
    /// - Returns: 收藏结果
    func toggleBookmark(postId: String) async throws -> BookmarkData {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: BookmarkResponse = try await networkManager.post(
            endpoint: "\(Endpoint.postBookmark)/\(postId)/bookmark",
            headers: authHeaders,
            responseType: BookmarkResponse.self
        )

        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message)
        }

        return response.data
    }

    /// 切换帖子收藏状态（新方法名）
    /// - Parameter postId: 帖子ID
    /// - Returns: API响应
    func toggleBookmarkPost(postId: String) async throws -> CommunityAPIResponse<BookmarkData> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: BookmarkResponse = try await networkManager.post(
            endpoint: "\(Endpoint.postBookmark)/\(postId)/bookmark",
            headers: authHeaders,
            responseType: BookmarkResponse.self
        )

        return CommunityAPIResponse(success: response.success, data: response.data, message: response.message)
    }
    
    /// 分享帖子
    /// - Parameters:
    ///   - postId: 帖子ID
    ///   - platform: 分享平台
    func sharePost(postId: String, platform: String = "system") async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        let parameters = ["platform": platform]
        
        let response: ShareResponse = try await networkManager.post(
            endpoint: "\(Endpoint.postShare)/\(postId)/share",
            parameters: parameters,
            headers: authHeaders,
            responseType: ShareResponse.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message)
        }
    }
    
    /// 举报帖子
    /// - Parameters:
    ///   - postId: 帖子ID
    ///   - reason: 举报原因
    ///   - description: 详细描述
    func reportPost(postId: String, reason: ReportReason, description: String?) async throws {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let request = ReportRequest(reason: reason.rawValue, description: description)

        let response: ReportResponse = try await networkManager.post(
            endpoint: "\(Endpoint.postReport)/\(postId)/report",
            parameters: try request.toDictionary(),
            headers: authHeaders,
            responseType: ReportResponse.self
        )

        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message)
        }
    }

    // MARK: - 评论系统

    /// 发表评论
    /// - Parameters:
    ///   - postId: 帖子ID
    ///   - content: 评论内容
    ///   - parentCommentId: 父评论ID（回复评论时）
    ///   - replyToUserId: 回复用户ID
    /// - Returns: 新创建的评论
    func createComment(
        postId: String,
        content: String,
        parentCommentId: String? = nil,
        replyToUserId: Int? = nil
    ) async throws -> Comment {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let request = CommentRequest(
            content: content,
            parentCommentId: parentCommentId,
            replyToUserId: replyToUserId
        )

        let response: CommentResponse = try await networkManager.post(
            endpoint: "\(Endpoint.comments)/\(postId)/comments",
            parameters: try request.toDictionary(),
            headers: authHeaders,
            responseType: CommentResponse.self
        )

        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message)
        }

        return response.data
    }

    /// 获取评论列表
    /// - Parameters:
    ///   - postId: 帖子ID
    ///   - page: 页码
    ///   - limit: 每页数量
    ///   - sortBy: 排序方式
    /// - Returns: 评论列表
    func getComments(
        postId: String,
        page: Int = 1,
        limit: Int = 20,
        sortBy: String = "time"
    ) async throws -> CommentListData {
        let parameters: [String: Any] = [
            "page": page,
            "limit": limit,
            "sortBy": sortBy
        ]

        let headers = authManager.getAuthHeader()

        let response: CommentListResponse = try await networkManager.get(
            endpoint: "\(Endpoint.comments)/\(postId)/comments",
            parameters: parameters,
            headers: headers,
            responseType: CommentListResponse.self
        )

        guard response.success else {
            throw NetworkManager.NetworkError.networkError("获取评论列表失败")
        }

        return response.data
    }



    /// 切换评论点赞状态
    /// - Parameter commentId: 评论ID
    /// - Returns: 点赞结果
    func toggleCommentLike(commentId: String) async throws -> LikeData {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: LikeResponse = try await networkManager.post(
            endpoint: "\(Endpoint.commentLike)/\(commentId)/like",
            headers: authHeaders,
            responseType: LikeResponse.self
        )

        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message)
        }

        return response.data
    }

    /// 切换评论点赞状态（返回API响应）
    /// - Parameter commentId: 评论ID
    /// - Returns: API响应
    func toggleLikeComment(commentId: String) async throws -> CommunityAPIResponse<LikeData> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: LikeResponse = try await networkManager.post(
            endpoint: "\(Endpoint.commentLike)/\(commentId)/like",
            headers: authHeaders,
            responseType: LikeResponse.self
        )

        return CommunityAPIResponse(success: response.success, data: response.data, message: response.message)
    }

    /// 获取评论的回复列表
    /// - Parameters:
    ///   - commentId: 评论ID
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 回复列表
    func getCommentReplies(
        commentId: String,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> CommentListData {
        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]

        let headers = authManager.getAuthHeader()

        let response: CommentListResponse = try await networkManager.get(
            endpoint: "\(Endpoint.commentReplies)/\(commentId)/replies",
            parameters: parameters,
            headers: headers,
            responseType: CommentListResponse.self
        )

        guard response.success else {
            throw NetworkManager.NetworkError.networkError("获取回复列表失败")
        }

        return response.data
    }

    // MARK: - 用户相关

    /// 获取用户资料
    /// - Parameter userId: 用户ID
    /// - Returns: 用户资料响应
    func getUserProfile(userId: Int) async throws -> CommunityAPIResponse<UserProfile> {
        let headers = authManager.getAuthHeader()

        let response: BooleanUserAPIResponse<UserProfile> = try await networkManager.get(
            endpoint: "/users/\(userId)/profile",
            headers: headers,
            responseType: BooleanUserAPIResponse<UserProfile>.self
        )

        // 如果服务器没有设置 isMe 字段，在客户端设置
        var userData = response.data
        if userData?.isMe == nil {
            let currentUserId = authManager.getCurrentUserId()
            print("🔍 getUserProfile - 当前用户ID: \(currentUserId ?? -1), 请求的用户ID: \(userId)")
            userData?.isMe = (currentUserId == userId)
            print("🔍 getUserProfile - 设置 isMe 为: \(userData?.isMe ?? false)")
        } else {
            print("🔍 getUserProfile - 服务器已设置 isMe: \(userData?.isMe ?? false)")
        }

        return CommunityAPIResponse(success: response.success, data: userData, message: response.message)
    }

    /// 关注用户
    /// - Parameter userId: 用户ID
    /// - Returns: 关注响应
    func followUser(userId: Int) async throws -> CommunityAPIResponse<FollowResponse> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        do {
            // 尝试使用简单的响应格式，因为服务器返回的是 {"success":true,"message":"关注成功"}
            let response: BooleanUserAPIResponse<FollowResponse> = try await networkManager.post(
                endpoint: "/users/\(userId)/follow",
                headers: authHeaders,
                responseType: BooleanUserAPIResponse<FollowResponse>.self
            )

            // 处理响应
            if response.success {
                // 根据消息内容判断最终状态
                let message = response.message ?? "关注成功"
                let isFollowing = message.contains("关注成功") || message.contains("已经关注了该用户")
                let followData = FollowResponse(isFollowing: isFollowing, followersCount: nil)
                return CommunityAPIResponse(success: true, data: followData, message: message)
            } else {
                // 处理失败情况
                let message = response.message ?? "操作失败"
                if message.contains("已经关注了该用户") {
                    // 创建一个表示已关注状态的响应
                    let followData = FollowResponse(isFollowing: true, followersCount: nil)
                    return CommunityAPIResponse(success: true, data: followData, message: message)
                } else {
                    return CommunityAPIResponse(success: false, data: response.data, message: message)
                }
            }
        } catch {
            // 特殊处理NetworkError.serverMessage的情况，这通常包含服务器返回的具体错误消息
            if let networkError = error as? NetworkManager.NetworkError,
               case .serverMessage(let message) = networkError {

                print("🔍 捕获到服务器消息: \(message)")

                if message.contains("已经关注了该用户") {
                    // 创建一个表示已关注状态的响应
                    let followData = FollowResponse(isFollowing: true, followersCount: nil)
                    return CommunityAPIResponse(success: true, data: followData, message: message)
                } else if message.contains("未关注该用户") || message.contains("没有关注该用户") {
                    // 创建一个表示未关注状态的响应
                    let followData = FollowResponse(isFollowing: false, followersCount: nil)
                    return CommunityAPIResponse(success: true, data: followData, message: message)
                } else {
                    // 其他服务器消息，作为失败处理
                    return CommunityAPIResponse(success: false, data: nil, message: message)
                }
            }

            // 特殊处理400状态码的情况
            if let networkError = error as? NetworkManager.NetworkError,
               case .serverError(let statusCode) = networkError,
               statusCode == 400 {

                print("🔍 捕获到400错误，假设用户已经关注")
                let followData = FollowResponse(isFollowing: true, followersCount: nil)
                return CommunityAPIResponse(success: true, data: followData, message: "已经关注了该用户")
            }

            // 对于其他错误，重新抛出
            throw error
        }
    }

    /// 取消关注用户
    /// - Parameter userId: 用户ID
    /// - Returns: 取消关注响应
    func unfollowUser(userId: Int) async throws -> CommunityAPIResponse<FollowResponse> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        do {
            // 尝试使用简单的响应格式，因为服务器返回的是 {"success":true,"message":"取消关注成功"}
            let response: BooleanUserAPIResponse<FollowResponse> = try await networkManager.delete(
                endpoint: "/users/\(userId)/follow",
                headers: authHeaders,
                responseType: BooleanUserAPIResponse<FollowResponse>.self
            )

            // 处理响应
            if response.success {
                // 根据消息内容判断最终状态
                let message = response.message ?? "取消关注成功"
                let isFollowing = !message.contains("取消关注成功") && !message.contains("未关注该用户")
                let followData = FollowResponse(isFollowing: isFollowing, followersCount: nil)
                return CommunityAPIResponse(success: true, data: followData, message: message)
            } else {
                // 处理失败情况
                let message = response.message ?? "操作失败"
                if message.contains("未关注该用户") || message.contains("没有关注该用户") {
                    // 创建一个表示未关注状态的响应
                    let followData = FollowResponse(isFollowing: false, followersCount: nil)
                    return CommunityAPIResponse(success: true, data: followData, message: message)
                } else {
                    return CommunityAPIResponse(success: false, data: response.data, message: message)
                }
            }
        } catch {
            // 特殊处理NetworkError.serverMessage的情况，这通常包含服务器返回的具体错误消息
            if let networkError = error as? NetworkManager.NetworkError,
               case .serverMessage(let message) = networkError {

                print("🔍 捕获到服务器消息: \(message)")

                if message.contains("未关注该用户") || message.contains("没有关注该用户") {
                    // 创建一个表示未关注状态的响应
                    let followData = FollowResponse(isFollowing: false, followersCount: nil)
                    return CommunityAPIResponse(success: true, data: followData, message: message)
                } else if message.contains("已经关注了该用户") {
                    // 创建一个表示已关注状态的响应
                    let followData = FollowResponse(isFollowing: true, followersCount: nil)
                    return CommunityAPIResponse(success: true, data: followData, message: message)
                } else {
                    // 其他服务器消息，作为失败处理
                    return CommunityAPIResponse(success: false, data: nil, message: message)
                }
            }

            // 特殊处理400状态码的情况
            if let networkError = error as? NetworkManager.NetworkError,
               case .serverError(let statusCode) = networkError,
               statusCode == 400 {

                print("🔍 捕获到400错误，假设用户未关注")
                let followData = FollowResponse(isFollowing: false, followersCount: nil)
                return CommunityAPIResponse(success: true, data: followData, message: "未关注该用户")
            }

            // 对于其他错误，重新抛出
            throw error
        }
    }

    /// 获取用户关注状态
    /// - Parameter userId: 用户ID
    /// - Returns: 关注状态响应
    func getFollowStatus(userId: Int) async throws -> CommunityAPIResponse<FollowStatusResponse> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: UserAPIResponse<FollowStatusResponse> = try await networkManager.get(
            endpoint: "/users/\(userId)/follow-status",
            headers: authHeaders,
            responseType: UserAPIResponse<FollowStatusResponse>.self
        )

        return CommunityAPIResponse(success: response.success, data: response.data, message: response.message)
    }

    /// 获取用户帖子列表
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 用户帖子列表响应
    func getUserPosts(userId: Int, page: Int = 1, limit: Int = 20) async throws -> CommunityAPIResponse<PostListResponse> {
        let headers = authManager.getAuthHeader()

        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]

        let response: BooleanUserAPIResponse<PostListResponse> = try await networkManager.get(
            endpoint: "/users/\(userId)/posts",
            parameters: parameters,
            headers: headers,
            responseType: BooleanUserAPIResponse<PostListResponse>.self
        )

        return CommunityAPIResponse(success: response.isSuccess, data: response.data, message: response.message)
    }

    /// 获取用户收藏列表
    /// - Parameters:
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 用户收藏列表响应
    func getUserBookmarks(page: Int = 1, limit: Int = 20) async throws -> CommunityAPIResponse<PostListResponse> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]

        let response: BooleanUserAPIResponse<PostListResponse> = try await networkManager.get(
            endpoint: "/users/bookmarks",
            parameters: parameters,
            headers: authHeaders,
            responseType: BooleanUserAPIResponse<PostListResponse>.self
        )

        return CommunityAPIResponse(success: response.isSuccess, data: response.data, message: response.message)
    }

    /// 获取用户关注列表
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 关注列表响应
    func getUserFollowing(userId: Int, page: Int = 1, limit: Int = 20) async throws -> CommunityAPIResponse<UserListResponse> {
        let headers = authManager.getAuthHeader()

        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]

        let response: BooleanUserAPIResponse<UserListResponse> = try await networkManager.get(
            endpoint: "/users/\(userId)/following",
            parameters: parameters,
            headers: headers,
            responseType: BooleanUserAPIResponse<UserListResponse>.self
        )

        // 设置用户列表中的 isMe 字段
        var userData = response.data
        if let currentUserId = authManager.getCurrentUserId(), let items = userData?.items {
            print("🔍 getUserFollowing - 当前用户ID: \(currentUserId), 列表用户数量: \(items.count)")
            let updatedItems = items.map { user in
                var mutableUser = user
                // 强制设置 isMe 字段，不管服务器是否已经设置
                let isCurrentUser = (currentUserId == user.id)
                mutableUser.isMe = isCurrentUser
                print("🔍 getUserFollowing - 用户ID \(user.id), 当前用户ID \(currentUserId), isMe设置为: \(isCurrentUser)")
                if isCurrentUser {
                    print("🔍 getUserFollowing - 找到自己: 用户ID \(user.id), 昵称: \(user.nickname)")
                }
                return mutableUser
            }
            userData?.items = updatedItems
        } else {
            print("🔍 getUserFollowing - 无法获取当前用户ID或列表为空")
        }

        return CommunityAPIResponse(success: response.isSuccess, data: userData, message: response.message)
    }

    /// 获取用户粉丝列表
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 粉丝列表响应
    func getUserFollowers(userId: Int, page: Int = 1, limit: Int = 20) async throws -> CommunityAPIResponse<UserListResponse> {
        let headers = authManager.getAuthHeader()

        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]

        let response: BooleanUserAPIResponse<UserListResponse> = try await networkManager.get(
            endpoint: "/users/\(userId)/followers",
            parameters: parameters,
            headers: headers,
            responseType: BooleanUserAPIResponse<UserListResponse>.self
        )

        // 设置用户列表中的 isMe 字段
        var userData = response.data
        if let currentUserId = authManager.getCurrentUserId(), let items = userData?.items {
            print("🔍 getUserFollowers - 当前用户ID: \(currentUserId), 列表用户数量: \(items.count)")
            let updatedItems = items.map { user in
                var mutableUser = user
                // 强制设置 isMe 字段，不管服务器是否已经设置
                let isCurrentUser = (currentUserId == user.id)
                mutableUser.isMe = isCurrentUser
                print("🔍 getUserFollowers - 用户ID \(user.id), 当前用户ID \(currentUserId), isMe设置为: \(isCurrentUser)")
                if isCurrentUser {
                    print("🔍 getUserFollowers - 找到自己: 用户ID \(user.id), 昵称: \(user.nickname)")
                }
                return mutableUser
            }
            userData?.items = updatedItems
        } else {
            print("🔍 getUserFollowers - 无法获取当前用户ID或列表为空")
        }

        return CommunityAPIResponse(success: response.isSuccess, data: userData, message: response.message)
    }

    /// 屏蔽用户
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - reason: 屏蔽原因
    /// - Returns: 屏蔽响应
    func blockUser(userId: Int, reason: String? = nil) async throws -> CommunityAPIResponse<BlockUserData> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        var parameters: [String: Any] = [:]
        if let reason = reason {
            parameters["reason"] = reason
        }

        let response: BooleanUserAPIResponse<BlockUserData> = try await networkManager.post(
            endpoint: "/users/\(userId)/block",
            parameters: parameters,
            headers: authHeaders,
            responseType: BooleanUserAPIResponse<BlockUserData>.self
        )

        return CommunityAPIResponse(success: response.isSuccess, data: response.data, message: response.message)
    }

    /// 取消屏蔽用户
    /// - Parameter userId: 用户ID
    /// - Returns: 取消屏蔽响应
    func unblockUser(userId: Int) async throws -> CommunityAPIResponse<BlockUserData> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: BooleanUserAPIResponse<BlockUserData> = try await networkManager.delete(
            endpoint: "/users/\(userId)/block",
            headers: authHeaders,
            responseType: BooleanUserAPIResponse<BlockUserData>.self
        )

        return CommunityAPIResponse(success: response.isSuccess, data: response.data, message: response.message)
    }

    /// 获取屏蔽列表
    /// - Parameters:
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 屏蔽用户列表响应
    func getBlockedUsers(page: Int = 1, limit: Int = 20) async throws -> CommunityAPIResponse<BlockedUsersResponse> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]

        let response: BooleanUserAPIResponse<BlockedUsersResponse> = try await networkManager.get(
            endpoint: "/users/blocked",
            parameters: parameters,
            headers: authHeaders,
            responseType: BooleanUserAPIResponse<BlockedUsersResponse>.self
        )

        return CommunityAPIResponse(success: response.isSuccess, data: response.data, message: response.message)
    }

    /// 更新用户资料
    /// - Parameters:
    ///   - nickname: 昵称
    ///   - bio: 个人简介
    ///   - location: 所在地区
    ///   - avatar: 头像URL
    ///   - backgroundImage: 背景图URL
    ///   - gender: 性别
    ///   - birthday: 生日
    ///   - hometown: 家乡
    ///   - school: 学校
    /// - Returns: 更新响应
    func updateUserProfile(nickname: String? = nil, bio: String? = nil, location: String? = nil, avatar: String? = nil, backgroundImage: String? = nil, gender: String? = nil, birthday: String? = nil, hometown: String? = nil, school: String? = nil) async throws -> CommunityAPIResponse<UserProfile> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        var parameters: [String: Any] = [:]
        if let nickname = nickname {
            parameters["nickname"] = nickname
        }
        if let bio = bio {
            parameters["bio"] = bio
        }
        if let location = location {
            parameters["location"] = location
        }
        if let avatar = avatar {
            parameters["avatar"] = avatar
        }
        if let backgroundImage = backgroundImage {
            parameters["backgroundImage"] = backgroundImage
        }
        if let gender = gender {
            parameters["gender"] = gender
        }
        if let birthday = birthday {
            parameters["birthday"] = birthday
        }
        if let hometown = hometown {
            parameters["hometown"] = hometown
        }
        if let school = school {
            parameters["school"] = school
        }

        let response: BooleanUserAPIResponse<UserProfile> = try await networkManager.put(
            endpoint: "/users/profile",
            parameters: parameters,
            headers: authHeaders,
            responseType: BooleanUserAPIResponse<UserProfile>.self
        )

        return CommunityAPIResponse(success: response.isSuccess, data: response.data, message: response.message)
    }

    /// 创建评论（使用请求对象）
    /// - Parameters:
    ///   - postId: 帖子ID
    ///   - request: 评论请求
    /// - Returns: 评论响应
    func createComment(postId: String, request: CreateCommentRequest) async throws -> CommunityAPIResponse<Comment> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let parameters: [String: Any] = [
            "content": request.content,
            "parentCommentId": request.parentCommentId as Any,
            "replyToUserId": request.replyToUserId as Any
        ]

        let response: CommentResponse = try await networkManager.post(
            endpoint: "\(Endpoint.comments)/\(postId)/comments",
            parameters: parameters,
            headers: authHeaders,
            responseType: CommentResponse.self
        )

        return CommunityAPIResponse(success: response.success, data: response.data, message: response.message)
    }

    /// 删除评论（返回API响应）
    /// - Parameter commentId: 评论ID
    /// - Returns: 删除响应
    func deleteComment(commentId: String) async throws -> CommunityAPIResponse<String> {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }

        let response: APIResponse<String> = try await networkManager.request(
            endpoint: "\(Endpoint.commentDelete)/\(commentId)",
            method: .DELETE,
            headers: authHeaders,
            responseType: APIResponse<String>.self
        )

        return CommunityAPIResponse(success: response.success, data: response.data, message: response.message)
    }

    /// 获取评论回复（返回API响应）
    /// - Parameters:
    ///   - commentId: 评论ID
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 回复列表响应
    func getCommentReplies(commentId: String, page: Int = 1, limit: Int = 20) async throws -> CommunityAPIResponse<CommentListData> {
        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]

        let headers = authManager.getAuthHeader()

        let response: CommentListResponse = try await networkManager.get(
            endpoint: "\(Endpoint.commentReplies)/\(commentId)/replies",
            parameters: parameters,
            headers: headers,
            responseType: CommentListResponse.self
        )

        return CommunityAPIResponse(success: response.success, data: response.data, message: nil)
    }
    
    /// 屏蔽帖子
    /// - Parameters:
    ///   - postId: 帖子ID
    ///   - reason: 屏蔽原因
    /// - Returns: 是否成功
    func blockPost(postId: String, reason: String) async throws -> Bool {
        guard let authHeaders = authManager.getAuthHeader() else {
            throw NetworkManager.NetworkError.networkError("未授权")
        }
        
        let parameters = ["reason": reason]
        
        let response: APIResponse<String> = try await networkManager.post(
            endpoint: "\(Endpoint.postReport)/\(postId)/block",
            parameters: parameters,
            headers: authHeaders,
            responseType: APIResponse<String>.self
        )
        
        return response.success
    }

    // MARK: - 搜索功能

    /// 搜索社区内容
    /// - Parameter request: 搜索请求
    /// - Returns: 搜索响应
    func search(_ request: SearchRequest) async throws -> ActualSearchResponse {
        let parameters: [String: Any] = [
            "q": request.q,
            "type": request.type,
            "sort": request.sort,
            "page": request.page,
            "limit": request.limit
        ]

        let headers = authManager.getAuthHeader()

        let response: ActualSearchResponse = try await networkManager.get(
            endpoint: Endpoint.search,
            parameters: parameters,
            headers: headers,
            responseType: ActualSearchResponse.self
        )

        return response
    }

    /// 获取热门搜索关键词
    /// - Returns: 热门搜索响应
    func getTrendingSearch() async throws -> TrendingSearchResponse {
        let headers = authManager.getAuthHeader()

        let response: TrendingSearchResponse = try await networkManager.get(
            endpoint: Endpoint.trendingSearch,
            headers: headers,
            responseType: TrendingSearchResponse.self
        )

        return response
    }

    // MARK: - 标签功能

    /// 根据标签获取帖子列表
    /// - Parameters:
    ///   - tagName: 标签名称（支持中文、英文、带#号标签）
    ///   - page: 页码，默认1
    ///   - limit: 每页数量，默认20，最大100
    ///   - sortBy: 排序方式，默认latest
    /// - Returns: 标签帖子列表响应
    func getPostsByTag(
        tagName: String,
        page: Int = 1,
        limit: Int = 20,
        sortBy: String = "latest"
    ) async throws -> TagPostsResponse {
        print("🏷️ CommunityAPIService.getPostsByTag 开始")
        print("🏷️ 原始标签名: '\(tagName)'")

        // URL编码标签名称
        guard let encodedTagName = tagName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            print("❌ 标签名称编码失败: '\(tagName)'")
            throw NetworkManager.NetworkError.networkError("标签名称编码失败")
        }

        print("🏷️ 编码后标签名: '\(encodedTagName)'")

        let parameters: [String: Any] = [
            "page": page,
            "limit": min(limit, 100), // 限制最大值为100
            "sortBy": sortBy
        ]

        let endpoint = "\(Endpoint.tags)/\(encodedTagName)/posts"
        print("🏷️ API 端点: '\(endpoint)'")
        print("🏷️ 请求参数: \(parameters)")

        // 标签API不需要认证
        print("🏷️ 开始调用 networkManager.get...")
        let response: TagPostsResponse = try await networkManager.get(
            endpoint: endpoint,
            parameters: parameters,
            headers: nil,
            responseType: TagPostsResponse.self
        )

        print("🏷️ CommunityAPIService.getPostsByTag 完成")
        return response
    }

    /// 获取热门标签列表
    /// - Parameter limit: 返回数量，默认10，最大50
    /// - Returns: 热门标签响应
    func createPostSmart(_ request: MinimalCreatePostRequest) async throws -> CreatePostResponse {
        // 模拟网络请求
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

        return CreatePostResponse(
            success: true,
            message: "发布成功",
            data: CreatePostData(
                postId: Int.random(in: 1000...9999),
                status: "published"
            )
        )
    }

    func createPostSmart(_ request: SimpleCreatePostRequest) async throws -> CreatePostResponse {
        // 模拟网络请求
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

        return CreatePostResponse(
            success: true,
            message: "发布成功",
            data: CreatePostData(
                postId: Int.random(in: 1000...9999),
                status: "published"
            )
        )
    }

    func createPostSmart(_ request: CreatePostRequest) async throws -> CreatePostResponse {
        // 验证认证状态
        guard let headers = authManager.getAuthHeader() else {
            if APIConfig.isDebugMode {
                print("❌ 认证失败: 无法获取认证头")
            }
            throw NetworkManager.NetworkError.networkError("用户未登录")
        }

        // 验证Token是否存在
        if let token = authManager.getToken() {
            if APIConfig.isDebugMode {
                print("🔐 当前Token: \(String(token.prefix(20)))...")
            }
        } else {
            if APIConfig.isDebugMode {
                print("❌ Token不存在")
            }
            throw NetworkManager.NetworkError.networkError("Token不存在")
        }

        // 构建请求参数
        var parameters: [String: Any] = [
            "content": request.content,
            "allowComments": request.allowComments,
            "allowShares": request.allowShares,
            "visibility": request.visibility,
            "isAIGenerated": request.isAIGenerated
        ]

        // 添加可选参数
        if let images = request.images, !images.isEmpty {
            parameters["images"] = images
        }

        if let video = request.video {
            parameters["video"] = video
        }

        if let tags = request.tags, !tags.isEmpty {
            parameters["tags"] = tags
        }

        if let location = request.location {
            parameters["location"] = location
        }

        if let latitude = request.latitude {
            parameters["latitude"] = latitude
        }

        if let longitude = request.longitude {
            parameters["longitude"] = longitude
        }

        if let checkinId = request.checkinId {
            parameters["checkinId"] = checkinId
        }

        if let workoutId = request.workoutId {
            parameters["workoutId"] = workoutId
        }

        if APIConfig.isDebugMode {
            print("🚀 发布帖子请求参数: \(parameters)")
            print("🔐 认证头信息: \(headers)")
            print("🌐 请求端点: \(Endpoint.posts)")
        }

        do {
            let response: CreatePostResponse = try await networkManager.post(
                endpoint: Endpoint.posts,
                parameters: parameters,
                headers: headers,
                responseType: CreatePostResponse.self
            )

            if APIConfig.isDebugMode {
                print("✅ 发布帖子响应成功: \(response)")
            }

            return response
        } catch {
            if APIConfig.isDebugMode {
                print("❌ 发布帖子请求失败: \(error)")
                if let networkError = error as? NetworkManager.NetworkError {
                    switch networkError {
                    case .serverError(let code):
                        print("❌ 服务器错误码: \(code)")
                    case .serverMessage(let message):
                        print("❌ 服务器错误消息: \(message)")
                    case .networkError(let message):
                        print("❌ 网络错误: \(message)")
                    default:
                        print("❌ 其他网络错误: \(networkError)")
                    }
                }
            }
            throw error
        }
    }

    func getNearbyPosts(latitude: Double, longitude: Double, radius: Double = 10.0, limit: Int = 20) async throws -> PostListResponse {
        // 模拟网络请求
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

        // 返回模拟的附近帖子数据
        let mockPosts = generateMockPostsData(count: limit)

        return PostListResponse(
            items: mockPosts,
            pagination: PaginationInfo(
                currentPage: 1,
                totalPages: 5,
                totalItems: 100,
                hasNext: true,
                hasPrevious: false
            ),
            recommendationInfo: nil as RecommendationInfo?
        )
    }
    
    // MARK: - Post Interaction Users
    
    /// 获取帖子点赞用户列表
    /// - Parameters:
    ///   - postId: 帖子ID
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 点赞用户列表响应
    func getPostLikes(postId: String, page: Int = 1, limit: Int = 20) async throws -> PostInteractionUsersResponse {
        let headers = authManager.getAuthHeader()
        
        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        
        let response: PostInteractionUsersResponse = try await networkManager.get(
            endpoint: "\(Endpoint.posts)/\(postId)/likes",
            parameters: parameters,
            headers: headers,
            responseType: PostInteractionUsersResponse.self
        )
        
        return response
    }
    
    /// 获取帖子收藏用户列表
    /// - Parameters:
    ///   - postId: 帖子ID
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 收藏用户列表响应
    func getPostBookmarks(postId: String, page: Int = 1, limit: Int = 20) async throws -> PostInteractionUsersResponse {
        let headers = authManager.getAuthHeader()
        
        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        
        let response: PostInteractionUsersResponse = try await networkManager.get(
            endpoint: "\(Endpoint.posts)/\(postId)/bookmarks",
            parameters: parameters,
            headers: headers,
            responseType: PostInteractionUsersResponse.self
        )
        
        return response
    }

    private func generateMockPostsData(count: Int) -> [Post] {
        var posts: [Post] = []

        for i in 1...count {
            let post = Post(
                id: "\(1000 + i)",
                authorId: 100 + i,
                content: "这是第\(i)条附近的帖子内容，分享一些有趣的生活片段。",
                images: [],
                video: nil,
                tags: ["附近", "生活"],
                category: nil,
                location: "附近位置\(i)",
                latitude: nil,
                longitude: nil,
                checkinId: nil,
                workoutId: nil,
                dataType: nil,
                likesCount: Int.random(in: 0...100),
                commentsCount: Int.random(in: 0...50),
                sharesCount: Int.random(in: 0...20),
                bookmarksCount: Int.random(in: 0...10),
                viewsCount: Int.random(in: 10...500),
                isLiked: false,
                isBookmarked: false,
                allowComments: true,
                allowShares: true,
                visibility: .public,
                status: .active,
                isTop: false,
                hotScore: Double.random(in: 0...100),
                lastActiveAt: Date().addingTimeInterval(-Double(i * 1800)).ISO8601Format(),
                createdAt: Date().addingTimeInterval(-Double(i * 3600)).ISO8601Format(),
                updatedAt: Date().addingTimeInterval(-Double(i * 3600)).ISO8601Format(),
                author: Author(
                    id: 100 + i,
                    nickname: "用户\(i)",
                    avatar: nil,
                    isVerified: false,
                    level: Int.random(in: 1...10),
                    followersCount: Int.random(in: 10...1000),
                    isFollowing: nil
                ),
                checkin: nil,
                workout: nil,
                finalScore: nil,
                explanation: nil,
                strategy: nil
            )
            posts.append(post)
        }

        return posts
    }

    func getPopularTags(limit: Int = 10) async throws -> PopularTagsResponse {
        let parameters: [String: Any] = [
            "limit": min(limit, 50) // 限制最大值为50
        ]

        // 热门标签API不需要认证
        let response: PopularTagsResponse = try await networkManager.get(
            endpoint: Endpoint.popularTags,
            parameters: parameters,
            headers: nil,
            responseType: PopularTagsResponse.self
        )

        return response
    }
    
    // MARK: - 同城功能
    
    /// 获取同城帖子
    /// - Parameters:
    ///   - latitude: 纬度
    ///   - longitude: 经度
    ///   - radius: 搜索半径（公里），默认50，最大200
    ///   - page: 页码，默认1
    ///   - limit: 每页数量，默认10，最大50
    /// - Returns: 同城帖子响应
    func getNearbyPosts(
        latitude: Double,
        longitude: Double,
        radius: Int = 50,
        page: Int = 1,
        limit: Int = 10
    ) async throws -> NearbyPostsResponse {
        let parameters: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "radius": min(radius, 200),  // 限制最大半径为200km
            "page": page,
            "limit": min(limit, 50)  // 限制最大每页数量为50
        ]
        
        let headers = authManager.getAuthHeader()
        
        let response: NearbyPostsResponse = try await networkManager.get(
            endpoint: "/community/nearby/posts",
            parameters: parameters,
            headers: headers,
            responseType: NearbyPostsResponse.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取同城帖子失败")
        }
        
        return response
    }
    
    /// 获取同城用户
    /// - Parameters:
    ///   - latitude: 纬度
    ///   - longitude: 经度
    ///   - radius: 搜索半径（公里），默认50
    ///   - page: 页码，默认1
    ///   - limit: 每页数量，默认10
    /// - Returns: 同城用户响应
    func getNearbyUsers(
        latitude: Double,
        longitude: Double,
        radius: Int = 50,
        page: Int = 1,
        limit: Int = 10
    ) async throws -> NearbyUsersResponse {
        let parameters: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "radius": radius,
            "page": page,
            "limit": limit
        ]
        
        let headers = authManager.getAuthHeader()
        
        let response: NearbyUsersResponse = try await networkManager.get(
            endpoint: "/community/nearby/users",
            parameters: parameters,
            headers: headers,
            responseType: NearbyUsersResponse.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.networkError(response.message ?? "获取同城用户失败")
        }
        
        return response
    }
}

/// 用户资料
struct UserProfile: Codable, Identifiable {
    let id: Int
    let nickname: String
    let avatar: String?
    var backgroundImage: String?
    let bio: String?
    let location: String?
    let gender: String?
    let birthday: String?
    let constellation: String?
    let hometown: String?
    let school: String?
    let ipLocation: String?
    let qingheId: String? // 青禾ID
    let level: Int?
    let isVerified: Bool?
    var followersCount: Int?
    let followingCount: Int?
    let postsCount: Int?
    let createdAt: String?
    let lastActiveAt: String?
    var isFollowing: Bool?
    let isFollowedBy: Bool?
    var isBlocked: Bool?
    var isMe: Bool?
    let hasPassword: Bool? // 是否设置了密码

    // 标准初始化方法
    init(id: Int, nickname: String, avatar: String?, backgroundImage: String?, bio: String?, location: String?, gender: String?, birthday: String?, constellation: String?, hometown: String?, school: String?, ipLocation: String?, qingheId: String?, level: Int?, isVerified: Bool?, followersCount: Int?, followingCount: Int?, postsCount: Int?, createdAt: String?, lastActiveAt: String?, isFollowing: Bool?, isFollowedBy: Bool?, isBlocked: Bool?, isMe: Bool?, hasPassword: Bool? = nil) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
        self.backgroundImage = backgroundImage
        self.bio = bio
        self.location = location
        self.gender = gender
        self.birthday = birthday
        self.constellation = constellation
        self.hometown = hometown
        self.school = school
        self.ipLocation = ipLocation
        self.qingheId = qingheId
        self.level = level
        self.isVerified = isVerified
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.postsCount = postsCount
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.isFollowing = isFollowing
        self.isFollowedBy = isFollowedBy
        self.isBlocked = isBlocked
        self.isMe = isMe
        self.hasPassword = hasPassword
    }

    // 自定义解码器处理布尔值的类型转换
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        nickname = try container.decode(String.self, forKey: .nickname)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        backgroundImage = try container.decodeIfPresent(String.self, forKey: .backgroundImage)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        birthday = try container.decodeIfPresent(String.self, forKey: .birthday)
        constellation = try container.decodeIfPresent(String.self, forKey: .constellation)
        hometown = try container.decodeIfPresent(String.self, forKey: .hometown)
        school = try container.decodeIfPresent(String.self, forKey: .school)
        ipLocation = try container.decodeIfPresent(String.self, forKey: .ipLocation)
        qingheId = try container.decodeIfPresent(String.self, forKey: .qingheId)
        level = try container.decodeIfPresent(Int.self, forKey: .level)
        followersCount = try container.decodeIfPresent(Int.self, forKey: .followersCount)
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount)
        postsCount = try container.decodeIfPresent(Int.self, forKey: .postsCount)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        lastActiveAt = try container.decodeIfPresent(String.self, forKey: .lastActiveAt)

        // 处理布尔值字段，可能是Bool或Int
        if let boolValue = try? container.decode(Bool.self, forKey: .isVerified) {
            isVerified = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isVerified) {
            isVerified = intValue != 0
        } else {
            isVerified = false
        }

        if let boolValue = try? container.decode(Bool.self, forKey: .isFollowing) {
            isFollowing = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isFollowing) {
            isFollowing = intValue != 0
        } else {
            isFollowing = false
        }

        if let boolValue = try? container.decode(Bool.self, forKey: .isFollowedBy) {
            isFollowedBy = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isFollowedBy) {
            isFollowedBy = intValue != 0
        } else {
            isFollowedBy = false
        }

        if let boolValue = try? container.decode(Bool.self, forKey: .isBlocked) {
            isBlocked = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isBlocked) {
            isBlocked = intValue != 0
        } else {
            isBlocked = false
        }

        if let boolValue = try? container.decode(Bool.self, forKey: .isMe) {
            isMe = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isMe) {
            isMe = intValue != 0
        } else {
            isMe = false
        }

        if let boolValue = try? container.decode(Bool.self, forKey: .hasPassword) {
            hasPassword = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .hasPassword) {
            hasPassword = intValue != 0
        } else {
            hasPassword = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, nickname, avatar, backgroundImage, bio, location, gender, birthday, constellation, hometown, school, ipLocation, qingheId, level, isVerified
        case followersCount, followingCount, postsCount, createdAt, lastActiveAt
        case isFollowing, isFollowedBy, isBlocked, isMe, hasPassword
    }
}


