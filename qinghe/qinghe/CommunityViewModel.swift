import SwiftUI
import Foundation
import CoreLocation

// MARK: - 发布状态枚举
enum PublishStatus {
    case idle
    case preparing
    case uploading
    case publishing
    case success
    case failed

    var message: String {
        switch self {
        case .idle: return ""
        case .preparing: return "准备发布..."
        case .uploading: return "上传图片中..."
        case .publishing: return "发布中..."
        case .success: return "发布成功！"
        case .failed: return "发布失败"
        }
    }
}

// MARK: - 文件上传服务
class FileUploadService {
    static let shared = FileUploadService()

    enum UploadFolder {
        case community
        case avatar
        case chat

        var path: String {
            switch self {
            case .community: return "community"
            case .avatar: return "avatar"
            case .chat: return "chat"
            }
        }
    }

    func uploadImage(_ image: UIImage, folder: UploadFolder) async throws -> String {
        // 使用真正的图片上传API
        let uploadResponse = try await ChatAPIService.shared.uploadImage(image)
        return uploadResponse.url
    }
}

// MARK: - 请求模型
struct MinimalCreatePostRequest: Codable {
    let content: String
    let images: [String]
}

struct SimpleCreatePostRequest: Codable {
    let content: String
    let images: [String]
    let tags: [String]
}

struct CreatePostRequest: Codable {
    let content: String
    let images: [String]?
    let video: String?
    let tags: [String]?
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let checkinId: Int?
    let workoutId: Int?
    let isAIGenerated: Bool
    let allowComments: Bool
    let allowShares: Bool
    let visibility: String

    init(
        content: String,
        images: [String]? = nil,
        video: String? = nil,
        tags: [String]? = nil,
        location: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        checkinId: Int? = nil,
        workoutId: Int? = nil,
        isAIGenerated: Bool = false,
        allowComments: Bool = true,
        allowShares: Bool = true,
        visibility: String = "public"
    ) {
        self.content = content
        self.images = images
        self.video = video
        self.tags = tags
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.checkinId = checkinId
        self.workoutId = workoutId
        self.isAIGenerated = isAIGenerated
        self.allowComments = allowComments
        self.allowShares = allowShares
        self.visibility = visibility
    }
}

// MARK: - 社区视图模型
@MainActor
class CommunityViewModel: ObservableObject {
    // 单例模式
    static let shared = CommunityViewModel()

    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedTab: CommunityTab = .recommended
    @Published var selectedCategory: PostCategory = .all
    @Published var currentPage: Int = 1
    @Published var searchText: String = ""
    @Published var hasMoreData: Bool = true

    private let pageSize: Int = 20
    @Published var hasMorePosts: Bool = true

    // 发布相关属性
    @Published var showError = false
    @Published var publishStatus: PublishStatus = .idle
    @Published var publishProgress: Double = 0.0
    @Published var isPublishing = false
    @Published var publishMessage = ""

    private let communityService = CommunityAPIService.shared
    private var currentLoadTask: Task<Void, Never>?
    private let fileUploadService = FileUploadService.shared
    private var locationManager: AppleMapService?

    // 同城功能相关属性
    @Published var currentLatitude: Double?
    @Published var currentLongitude: Double?
    @Published var nearbyRadius: Int = 50  // 默认搜索半径50公里
    @Published var isLoadingLocation: Bool = false
    @Published var locationPermissionDenied: Bool = false

    // MARK: - 缓存相关属性
    // 缓存最后加载时间（按 tab 分别记录）
    private var lastLoadTime: [CommunityTab: Date] = [:]
    // 缓存有效期（秒），默认5分钟
    private let cacheValidDuration: TimeInterval = 5 * 60
    // 是否已经初次加载过
    private var hasInitialLoaded: [CommunityTab: Bool] = [:]

    // 私有初始化方法，防止外部创建实例
    private init() {}

    // MARK: - 检查缓存是否有效
    func shouldLoadData(forceRefresh: Bool = false) -> Bool {
        // 如果强制刷新，直接返回 true
        if forceRefresh {
            return true
        }
        
        // 如果当前 tab 从未加载过，需要加载
        if hasInitialLoaded[selectedTab] != true {
            return true
        }
        
        // 检查缓存是否过期
        if let lastTime = lastLoadTime[selectedTab] {
            let timeElapsed = Date().timeIntervalSince(lastTime)
            // 如果缓存未过期，不需要重新加载
            if timeElapsed < cacheValidDuration {
                print("📦 社区数据缓存有效，剩余时间: \(Int(cacheValidDuration - timeElapsed))秒")
                return false
            }
        }
        
        return true
    }
    
    // MARK: - 加载帖子
    func loadPosts(refresh: Bool = false, isLoadingMore: Bool = false) async {
        // 检查是否需要加载数据（除非是强制刷新或加载更多）
        // 加载更多时不检查缓存，直接加载下一页
        if !refresh && !isLoadingMore && !shouldLoadData(forceRefresh: false) {
            print("📦 使用缓存数据，跳过加载")
            return
        }

        // 取消之前的请求
        currentLoadTask?.cancel()

        // 如果是刷新，重置状态（必须在 guard 之前）
        if refresh {
            currentPage = 1
            hasMorePosts = true
        }

        // 检查是否可以加载（刷新时已经重置了 hasMorePosts）
        guard !isLoading && hasMorePosts else {
            print("⚠️ 跳过加载 - isLoading: \(isLoading), hasMorePosts: \(hasMorePosts)")
            return
        }

        isLoading = true
        errorMessage = nil

        // 创建新的任务
        currentLoadTask = Task {
            do {
                // 检查是否是同城标签，如果是则使用同城API
                if selectedTab == .nearby {
                    // 确保有位置信息
                    if currentLatitude == nil || currentLongitude == nil {
                        await loadCurrentLocation()
                    }
                    
                    guard let latitude = currentLatitude, let longitude = currentLongitude else {
                        errorMessage = "无法获取位置信息，请检查位置权限"
                        isLoading = false
                        return
                    }
                    
                    // 调用同城API
                    let nearbyResponse = try await communityService.getNearbyPosts(
                        latitude: latitude,
                        longitude: longitude,
                        radius: nearbyRadius,
                        page: currentPage,
                        limit: 20
                    )
                    
                    guard !Task.isCancelled else { return }
                    
                    print("========================================")
                    print("🌍 CommunityViewModel 加载同城帖子成功")
                    print("🌍 位置: (\(latitude), \(longitude)), 半径: \(nearbyRadius)km")
                    print("🌍 获取到 \(nearbyResponse.data?.items.count ?? 0) 个帖子")
                    print("🌍 refresh: \(refresh)")
                    print("========================================")
                    
                    // 将同城帖子转换为普通帖子
                    let nearbyPosts = nearbyResponse.data?.items.map { $0.toPost() } ?? []
                    
                    if refresh {
                        posts = nearbyPosts
                    } else {
                        posts.append(contentsOf: nearbyPosts)
                    }
                    
                    hasMorePosts = nearbyResponse.data?.pagination.hasNextPage ?? false
                    currentPage += 1
                    
                } else {
                    // 使用普通帖子API
                    let response = try await communityService.getPosts(
                        tab: selectedTab,
                        category: selectedCategory,
                        page: currentPage,
                        limit: 20
                    )

                    // 检查任务是否被取消
                    guard !Task.isCancelled else { return }

                    print("========================================")
                    print("🔍 CommunityViewModel 加载帖子成功")
                    print("🔍 获取到 \(response.items.count) 个帖子")
                    print("🔍 refresh: \(refresh)")

                    // 打印前几个帖子的ID用于调试
                    for (index, post) in response.items.prefix(3).enumerated() {
                        print("🔍 帖子 \(index): ID='\(post.id)', 标题='\(String(post.content.prefix(30)))...'")
                    }
                    print("========================================")

                    if refresh {
                        posts = response.items
                    } else {
                        posts.append(contentsOf: response.items)
                    }

                    hasMorePosts = response.pagination.hasNextPage
                    currentPage += 1

                    print("🔍 更新后总帖子数: \(posts.count)")
                    print("🔍 hasMorePosts: \(hasMorePosts)")
                    print("========================================")
                }
                
                // 标记当前 tab 已初次加载完成
                hasInitialLoaded[selectedTab] = true
                // 更新最后加载时间
                lastLoadTime[selectedTab] = Date()
                print("📦 缓存已更新，tab: \(selectedTab.displayName)")

            } catch {
                // 检查任务是否被取消
                guard !Task.isCancelled else { return }

                // 过滤掉取消错误，避免显示"cancelled"错误
                if error is CancellationError {
                    return
                }

                if let urlError = error as? URLError, urlError.code == .cancelled {
                    return
                }

                errorMessage = error.localizedDescription
            }

            isLoading = false
        }

        await currentLoadTask?.value
    }

    // MARK: - 刷新帖子
    func refreshPosts() async {
        await loadPosts(refresh: true)
    }

    // MARK: - 取消当前请求
    func cancelCurrentRequest() {
        currentLoadTask?.cancel()
        currentLoadTask = nil
        isLoading = false
    }

    // MARK: - 加载更多帖子
    func loadMorePosts() async {
        await loadPosts(refresh: false, isLoadingMore: true)
    }

    // MARK: - 切换Tab
    func switchTab(_ tab: CommunityTab) async {
        // 如果点击的是当前已选中的标签，强制刷新数据
        let isSameTab = (selectedTab == tab)

        selectedTab = tab

        if isSameTab {
            // 点击当前标签，强制刷新（忽略缓存）
            print("🔄 点击当前标签 \(tab.displayName)，强制刷新数据")
            await loadPosts(refresh: true, isLoadingMore: false)
        } else {
            // 切换到不同标签，正常刷新（会检查缓存）
            print("🔄 切换到标签 \(tab.displayName)")
            await refreshPosts()
        }
    }

    // MARK: - 切换分类
    func switchCategory(_ category: PostCategory) async {
        selectedCategory = category
        await refreshPosts()
    }

    // MARK: - 点赞帖子
    func toggleLike(for postId: String) async {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }

        do {
            let result = try await communityService.toggleLike(postId: postId)
            posts[index].isLiked = result.isLiked

            if result.isLiked {
                posts[index].likesCount += 1
            } else {
                posts[index].likesCount = max(0, posts[index].likesCount - 1)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - 收藏帖子
    func toggleBookmark(for postId: String) async {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }

        do {
            let result = try await communityService.toggleBookmark(postId: postId)
            posts[index].isBookmarked = result.isBookmarked

            if result.isBookmarked {
                posts[index].bookmarksCount += 1
            } else {
                posts[index].bookmarksCount = max(0, posts[index].bookmarksCount - 1)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - 分享帖子
    func sharePost(_ postId: String, platform: String = "system") async {
        do {
            try await communityService.sharePost(postId: postId, platform: platform)

            // 更新分享数
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].sharesCount += 1
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - 举报帖子
    func reportPost(_ postId: String, reason: ReportReason, description: String?) async {
        do {
            try await communityService.reportPost(postId: postId, reason: reason, description: description)
            // 可以显示举报成功的提示
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - 同城功能 - 获取当前位置
    func loadCurrentLocation() async {
        isLoadingLocation = true
        locationPermissionDenied = false
        
        // 初始化位置管理器
        if locationManager == nil {
            locationManager = AppleMapService.shared
        }
        
        guard let manager = locationManager else {
            errorMessage = "无法初始化位置服务"
            isLoadingLocation = false
            return
        }
        
        // 检查权限状态
        switch manager.authorizationStatus {
        case .notDetermined:
            // 请求权限
            manager.requestLocationPermission()
            // 等待权限结果
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 等待2秒
            
        case .denied, .restricted:
            locationPermissionDenied = true
            errorMessage = "位置权限被拒绝，请在设置中开启"
            isLoadingLocation = false
            return
            
        case .authorizedWhenInUse, .authorizedAlways:
            break
            
        @unknown default:
            break
        }
        
        // 等待位置更新
        var retryCount = 0
        while manager.currentLocation == nil && retryCount < 10 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 等待0.5秒
            retryCount += 1
        }
        
        if let location = manager.currentLocation {
            currentLatitude = location.coordinate.latitude
            currentLongitude = location.coordinate.longitude
            print("📍 获取到当前位置: (\(currentLatitude!), \(currentLongitude!))")
        } else {
            errorMessage = "无法获取当前位置，请检查GPS信号"
        }
        
        isLoadingLocation = false
    }
    
    // MARK: - 更新搜索半径
    func updateNearbyRadius(_ radius: Int) async {
        nearbyRadius = radius
        if selectedTab == .nearby {
            await refreshPosts()
        }
    }

    /// 发布新帖子（使用新的图片直接上传方式）
    func createPostWithDirectUpload(
        content: String,
        images: [UIImage],
        tags: [String],
        // 移除 category 参数，因为不再需要分类功能
        allowComments: Bool = true,
        allowShares: Bool = true,
        visibility: String = "public"
    ) {
        Task {
            do {
                if APIConfig.isDebugMode {
                    print("🆕 使用新的图片直接上传方式发布帖子")
                    print("📝 内容: \(content)")
                    print("🖼️ 图片数量: \(images.count)")
                }

                // 1. 先上传图片获取真实URL
                var imageUrls: [String] = []
                for (index, image) in images.enumerated() {
                    if APIConfig.isDebugMode {
                        print("📤 正在上传第 \(index + 1)/\(images.count) 张图片...")
                    }
                    let imageUrl = try await fileUploadService.uploadImage(image, folder: .community)
                    imageUrls.append(imageUrl)
                    if APIConfig.isDebugMode {
                        print("✅ 图片上传成功: \(imageUrl)")
                    }
                }

                // 2. 使用真实的图片URL发布帖子
                let request = CreatePostRequest(
                    content: content,
                    images: imageUrls.isEmpty ? nil : imageUrls,
                    video: nil,
                    tags: tags,
                    location: nil,
                    latitude: nil,
                    longitude: nil,
                    checkinId: nil,
                    workoutId: nil,
                    allowComments: allowComments,
                    allowShares: allowShares,
                    visibility: visibility
                )

                let response = try await communityService.createPostSmart(request)

                if response.success, let postData = response.data {
                    // 创建新的Post对象
                    let newPost = Post(
                        id: String(postData.postId),
                        authorId: 1, // 当前用户ID，应该从用户管理器获取
                        content: content,
                        images: imageUrls, // 使用真实的图片URL
                        video: nil,
                        tags: tags,
                        category: nil,
                        location: nil,
                        latitude: nil,
                        longitude: nil,
                        checkinId: nil,
                        workoutId: nil,
                        dataType: nil,
                        likesCount: 0,
                        commentsCount: 0,
                        sharesCount: 0,
                        bookmarksCount: 0,
                        viewsCount: 0,
                        isLiked: false,
                        isBookmarked: false,
                        allowComments: allowComments,
                        allowShares: allowShares,
                        visibility: PostVisibility(rawValue: visibility) ?? .public,
                        status: .active,
                        isTop: false,
                        hotScore: 0.0,
                        lastActiveAt: Date().ISO8601Format(),
                        createdAt: Date().ISO8601Format(),
                        updatedAt: Date().ISO8601Format(),
                        author: Author(
                            id: 1,
                            nickname: "当前用户",
                            avatar: nil,
                            isVerified: false,
                            level: 1,
                            followersCount: 0,
                            isFollowing: nil
                        ),
                        checkin: nil,
                        workout: nil,
                        finalScore: nil,
                        explanation: nil,
                        strategy: nil
                    )

                    // 将新帖子添加到列表顶部
                    posts.insert(newPost, at: 0)
                    
                    if APIConfig.isDebugMode {
                        print("✅ 帖子发布成功，ID: \(newPost.id)")
                    }
                } else {
                    // 失败时也尝试拼接审核详情
                    var err = response.message
                    if let details = response.moderationDetails, !details.isEmpty {
                        let blocked = details.filter { ($0.action ?? "").lowercased() == "block" }
                        if !blocked.isEmpty {
                            let parts = blocked.map { item -> String in
                                var segment: [String] = []
                                if let t = item.type { segment.append("[") ; segment.append(t) ; segment.append("]") }
                                if let msg = item.message { segment.append(msg) }
                                if let vio = item.violations, !vio.isEmpty {
                                    let vStr = vio.compactMap { v in
                                        var s: [String] = []
                                        if let lbl = v.label { s.append(lbl) }
                                        if let conf = v.confidence { s.append(String(format: "%.0f%%", conf)) }
                                        if let r = v.riskLevel { s.append("(") ; s.append(r) ; s.append(")") }
                                        return s.joined(separator: " ")
                                    }.joined(separator: ", ")
                                    if !vStr.isEmpty { segment.append("原因: ") ; segment.append(vStr) }
                                }
                                if let url = item.imageUrl { segment.append("\n图片: ") ; segment.append(url) }
                                return segment.joined()
                            }
                            let appendix = parts.joined(separator: "\n")
                            if !appendix.isEmpty {
                                err = err.isEmpty ? appendix : (err + "\n" + appendix)
                            }
                        }
                    }
                    errorMessage = err
                    showError = true
                }

            } catch {
                if APIConfig.isDebugMode {
                    print("❌ 发布失败: \(error)")
                }
                errorMessage = "发布失败：\(error.localizedDescription)"
                showError = true
            }
        }
    }

    /// 发布新帖子（原有方式，兼容性保留）
    func createPost(content: String, images: [UIImage], tags: [String], allowComments: Bool = true, allowShares: Bool = true, visibility: String = "public") {
        Task {
            do {
                // 1. 上传图片
                var imageUrls: [String] = []

                for (_, image) in images.enumerated() {
                    let imageUrl = try await fileUploadService.uploadImage(
                        image,
                        folder: .community
                    )
                    imageUrls.append(imageUrl)
                }

                // 2. 创建帖子 - 使用逐步降级策略
                var response: PostDetailResponse?
                var publishSuccess = false

                // 策略1: 尝试最小化版本（仅必需字段）
                if !publishSuccess {
                    do {
                        let minimalRequest = MinimalCreatePostRequest(
                            content: content,
                            images: imageUrls
                        )

                        let createResponse = try await communityService.createPostSmart(minimalRequest)
                        // 创建一个临时的 Post 对象
                        let tempPost = Post(
                            id: String(createResponse.data?.postId ?? 0),
                            authorId: 1,
                            content: content,
                            images: imageUrls,
                            video: nil,
                            tags: tags,
                            category: nil,
                            location: nil,
                            latitude: nil,
                            longitude: nil,
                            checkinId: nil,
                            workoutId: nil,
                            dataType: nil,
                            likesCount: 0,
                            commentsCount: 0,
                            sharesCount: 0,
                            bookmarksCount: 0,
                            viewsCount: 0,
                            isLiked: false,
                            isBookmarked: false,
                            allowComments: allowComments,
                            allowShares: allowShares,
                            visibility: PostVisibility(rawValue: visibility) ?? .public,
                            status: .active,
                            isTop: false,
                            hotScore: 0.0,
                            lastActiveAt: Date().ISO8601Format(),
                            createdAt: Date().ISO8601Format(),
                            updatedAt: Date().ISO8601Format(),
                            author: Author(
                                id: 1,
                                nickname: "当前用户",
                                avatar: nil,
                                isVerified: false,
                                level: 1,
                                followersCount: 0,
                                isFollowing: nil
                            ),
                            checkin: nil,
                            workout: nil,
                            finalScore: nil,
                            explanation: nil,
                            strategy: nil
                        )

                        response = PostDetailResponse(
                            success: createResponse.success,
                            data: tempPost,
                            message: createResponse.message
                        )
                        publishSuccess = true

                        if APIConfig.isDebugMode {
                            print("✅ 最小化版本发布成功")
                        }
                    } catch {
                        if APIConfig.isDebugMode {
                            print("⚠️ 最小化版本失败: \(error)")
                        }
                    }
                }

                // 策略2: 尝试简化版本
                if !publishSuccess {
                    do {
                        let simpleRequest = SimpleCreatePostRequest(
                            content: content,
                            images: imageUrls,
                            tags: tags
                        )

                        let createResponse = try await communityService.createPostSmart(simpleRequest)

                        // 创建临时的 Post 对象
                        let tempPost = Post(
                            id: String(createResponse.data?.postId ?? 0),
                            authorId: AuthManager.shared.getCurrentUserId() ?? 0,
                            content: content,
                            images: imageUrls,
                            video: nil,
                            tags: tags,
                            category: nil,
                            location: nil,
                            latitude: nil,
                            longitude: nil,
                            checkinId: nil,
                            workoutId: nil,
                            dataType: nil,
                            likesCount: 0,
                            commentsCount: 0,
                            sharesCount: 0,
                            bookmarksCount: 0,
                            viewsCount: 0,
                            isLiked: false,
                            isBookmarked: false,
                            allowComments: allowComments,
                            allowShares: allowShares,
                            visibility: PostVisibility(rawValue: visibility) ?? .public,
                            status: .active,
                            isTop: false,
                            hotScore: 0.0,
                            lastActiveAt: Date().ISO8601Format(),
                            createdAt: Date().ISO8601Format(),
                            updatedAt: Date().ISO8601Format(),
                            author: Author(
                                id: AuthManager.shared.getCurrentUserId() ?? 0,
                                nickname: "我",
                                avatar: nil,
                                isVerified: false,
                                level: 1,
                                followersCount: 0,
                                isFollowing: nil
                            ),
                            checkin: nil,
                            workout: nil,
                            finalScore: nil,
                            explanation: nil,
                            strategy: nil
                        )

                        response = PostDetailResponse(
                            success: createResponse.success,
                            data: tempPost,
                            message: createResponse.message
                        )
                        publishSuccess = true

                        if APIConfig.isDebugMode {
                            print("✅ 简化版本发布成功")
                        }
                    } catch {
                        if APIConfig.isDebugMode {
                            print("⚠️ 简化版本失败: \(error)")
                        }
                    }
                }

                // 策略3: 尝试完整版本
                if !publishSuccess {
                    let fullRequest = CreatePostRequest(
                        content: content,
                        images: imageUrls,
                        video: nil,
                        tags: tags,
                        location: nil,
                        latitude: nil,
                        longitude: nil,
                        checkinId: nil,
                        workoutId: nil,
                        allowComments: allowComments,
                        allowShares: allowShares,
                        visibility: visibility
                    )

                    let createResponse = try await communityService.createPostSmart(fullRequest)

                    // 创建临时的 Post 对象
                    let tempPost = Post(
                        id: String(createResponse.data?.postId ?? 0),
                        authorId: AuthManager.shared.getCurrentUserId() ?? 0,
                        content: content,
                        images: imageUrls,
                        video: nil,
                        tags: tags,
                        category: nil,
                        location: nil,
                        latitude: nil,
                        longitude: nil,
                        checkinId: nil,
                        workoutId: nil,
                        dataType: nil,
                        likesCount: 0,
                        commentsCount: 0,
                        sharesCount: 0,
                        bookmarksCount: 0,
                        viewsCount: 0,
                        isLiked: false,
                        isBookmarked: false,
                        allowComments: allowComments,
                        allowShares: allowShares,
                        visibility: PostVisibility(rawValue: visibility) ?? .public,
                        status: .active,
                        isTop: false,
                        hotScore: 0.0,
                        lastActiveAt: Date().ISO8601Format(),
                        createdAt: Date().ISO8601Format(),
                        updatedAt: Date().ISO8601Format(),
                        author: Author(
                            id: AuthManager.shared.getCurrentUserId() ?? 0,
                            nickname: "我",
                            avatar: nil,
                            isVerified: false,
                            level: 1,
                            followersCount: 0,
                            isFollowing: nil
                        ),
                        checkin: nil,
                        workout: nil,
                        finalScore: nil,
                        explanation: nil,
                        strategy: nil
                    )

                    response = PostDetailResponse(
                        success: createResponse.success,
                        data: tempPost,
                        message: createResponse.message
                    )
                    publishSuccess = true

                    if APIConfig.isDebugMode {
                        print("✅ 完整版本发布成功")
                    }
                }

                if let response = response, response.success {
                    // 将新帖子添加到列表顶部
                    posts.insert(response.data, at: 0)
                }

            } catch {
                errorMessage = "发布失败：\(error.localizedDescription)"
                showError = true
            }
        }
    }

    /// 发布新帖子（完整版本，支持位置、打卡、运动数据）
    func publishPost(
        content: String,
        images: [UIImage] = [],
        tags: [String] = [],
        // 移除 category 参数，因为不再需要分类功能
        allowComments: Bool = true,
        allowShares: Bool = true,
        visibility: String = "public",
        location: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        checkinId: Int? = nil,
        workoutId: Int? = nil,
        isAIGenerated: Bool = false,
        onSuccess: (() -> Void)? = nil,
        onFailure: ((String) -> Void)? = nil
    ) {
        Task {
            // 重置状态
            publishStatus = .preparing
            publishProgress = 0.0
            isPublishing = true
            publishMessage = publishStatus.message

            do {
                // 模拟准备阶段
                publishProgress = 0.2
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

                // 上传阶段
                if !images.isEmpty {
                    publishStatus = .uploading
                    publishMessage = publishStatus.message
                    publishProgress = 0.5
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                }

                // 发布阶段
                publishStatus = .publishing
                publishMessage = publishStatus.message
                publishProgress = 0.8

                if APIConfig.isDebugMode {
                    print("🆕 发布帖子 - 完整版本")
                    print("📝 内容: \(content)")
                    print("🖼️ 图片数量: \(images.count)")
                    print("📍 位置: \(location ?? "无")")
                    print("🎯 打卡ID: \(checkinId?.description ?? "无")")
                    print("🏃 运动ID: \(workoutId?.description ?? "无")")
                }

                // 上传图片并获取URL
                var imageUrls: [String] = []
                if !images.isEmpty {
                    publishStatus = .uploading
                    publishMessage = publishStatus.message

                    for (index, image) in images.enumerated() {
                        let imageUrl = try await fileUploadService.uploadImage(
                            image,
                            folder: .community
                        )
                        imageUrls.append(imageUrl)

                        // 更新上传进度
                        publishProgress = 0.1 + (0.6 * Double(index + 1) / Double(images.count))
                    }
                }

                publishStatus = .publishing
                publishMessage = publishStatus.message
                publishProgress = 0.8

                // 调用API
                let request = CreatePostRequest(
                    content: content,
                    images: imageUrls.isEmpty ? nil : imageUrls,
                    video: nil,
                    tags: tags.isEmpty ? nil : tags,
                    location: location,
                    latitude: latitude,
                    longitude: longitude,
                    checkinId: checkinId,
                    workoutId: workoutId,
                    isAIGenerated: isAIGenerated,
                    allowComments: allowComments,
                    allowShares: allowShares,
                    visibility: visibility
                )

                let response = try await communityService.createPostSmart(request)

                publishProgress = 1.0

                if response.success, let postData = response.data {
                    // 发布成功
                    publishStatus = .success
                    publishMessage = publishStatus.message

                    // 创建新的Post对象并添加到列表顶部
                    let newPost = Post(
                        id: String(postData.postId),
                        authorId: 1, // 当前用户ID，应该从用户管理器获取
                        content: content,
                        images: [],
                        video: nil,
                        tags: tags,
                        category: nil,
                        location: location,
                        latitude: latitude.map { String($0) },
                        longitude: longitude.map { String($0) },
                        checkinId: checkinId,
                        workoutId: workoutId,
                        dataType: nil,
                        likesCount: 0,
                        commentsCount: 0,
                        sharesCount: 0,
                        bookmarksCount: 0,
                        viewsCount: 0,
                        isLiked: false,
                        isBookmarked: false,
                        allowComments: allowComments,
                        allowShares: allowShares,
                        visibility: PostVisibility(rawValue: visibility) ?? .public,
                        status: .active,
                        isTop: false,
                        hotScore: 0.0,
                        lastActiveAt: Date().ISO8601Format(),
                        createdAt: Date().ISO8601Format(),
                        updatedAt: Date().ISO8601Format(),
                        author: Author(
                            id: 1,
                            nickname: "当前用户",
                            avatar: nil,
                            isVerified: false,
                            level: 1,
                            followersCount: 0,
                            isFollowing: nil
                        ),
                        checkin: nil,
                        workout: nil,
                        finalScore: nil,
                        explanation: nil,
                        strategy: nil
                    )
                    posts.insert(newPost, at: 0)

                    // 延迟一下让用户看到成功状态
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒

                    // 重置状态
                    resetPublishState()

                    // 自动跳转到关注页面
                    selectedTab = .following

                    // 调用成功回调
                    onSuccess?()

                    if APIConfig.isDebugMode {
                        print("✅ 帖子发布成功，ID: \(newPost.id)")
                        print("🔄 自动跳转到关注页面")
                    }
                } else {
                    // 发布失败：拼接审核详情
                    var errorMsg = response.message
                    if let details = response.moderationDetails, !details.isEmpty {
                        // 只展示被拦截的条目（action == block）
                        let blocked = details.filter { ($0.action ?? "").lowercased() == "block" }
                        if !blocked.isEmpty {
                            let parts = blocked.map { item -> String in
                                var segment: [String] = []
                                if let t = item.type { segment.append("[") ; segment.append(t) ; segment.append("]") }
                                if let msg = item.message { segment.append(msg) }
                                if let vio = item.violations, !vio.isEmpty {
                                    let vStr = vio.compactMap { v in
                                        var s: [String] = []
                                        if let lbl = v.label { s.append(lbl) }
                                        if let conf = v.confidence { s.append(String(format: "%.0f%%", conf)) }
                                        if let r = v.riskLevel { s.append("(") ; s.append(r) ; s.append(")") }
                                        return s.joined(separator: " ")
                                    }.joined(separator: ", ")
                                    if !vStr.isEmpty { segment.append("原因: ") ; segment.append(vStr) }
                                }
                                if let url = item.imageUrl { segment.append("\n图片: ") ; segment.append(url) }
                                return segment.joined()
                            }
                            let appendix = parts.joined(separator: "\n")
                            if !appendix.isEmpty {
                                errorMsg = errorMsg.isEmpty ? appendix : (errorMsg + "\n" + appendix)
                            }
                        }
                    }

                    publishStatus = .failed
                    publishMessage = errorMsg

                    // 延迟一下让用户看到失败状态
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒

                    // 重置状态
                    resetPublishState()

                    // 调用失败回调
                    onFailure?(errorMsg)
                }

            } catch {
                // 发布失败
                let errorMsg = "发布失败：\(error.localizedDescription)"
                publishStatus = .failed
                publishMessage = errorMsg

                if APIConfig.isDebugMode {
                    print("❌ 发布失败: \(error)")
                }

                // 延迟一下让用户看到失败状态
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒

                // 重置状态
                resetPublishState()

                // 调用失败回调
                onFailure?(errorMsg)
            }
        }
    }

    /// 重置发布状态
    private func resetPublishState() {
        isPublishing = false
        publishProgress = 0.0
        publishStatus = .idle
        publishMessage = ""
    }

    // MARK: - 筛选和搜索
    
    /// 切换标签页
    func selectTab(_ tab: CommunityTab) {
        guard tab != selectedTab else { return }

        selectedTab = tab
        Task {
            await loadPosts()
        }
    }
    
    /// 搜索帖子
    func searchPosts() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Task {
                await loadPosts()
            }
            return
        }
        
        Task<Void, Never> { @MainActor in
            do {
                let request = SearchRequest(
                    q: searchText,
                    type: "posts",
                    sort: "latest",
                    page: 1,
                    limit: pageSize
                )

                let response = try await communityService.search(request)

                if response.success != 0, let searchData = response.data {
                    // 将 CommunityPost 转换为 Post
                    let communityPosts = searchData.results.posts ?? []
                    posts = communityPosts.map { communityPost in
                        Post(
                            id: communityPost.id,
                            authorId: communityPost.authorId,
                            content: communityPost.content,
                            images: communityPost.images ?? [],
                            video: communityPost.video,
                            tags: communityPost.tags ?? [],
                            category: communityPost.category,
                            location: communityPost.location,
                            latitude: communityPost.latitude,
                            longitude: communityPost.longitude,
                            checkinId: communityPost.checkinId,
                            workoutId: communityPost.workoutId,
                            dataType: communityPost.dataType,
                            likesCount: communityPost.likesCount,
                            commentsCount: communityPost.commentsCount,
                            sharesCount: communityPost.sharesCount,
                            bookmarksCount: communityPost.bookmarksCount,
                            viewsCount: communityPost.viewsCount,
                            isLiked: communityPost.isLiked,
                            isBookmarked: communityPost.isBookmarked,
                            allowComments: communityPost.allowComments,
                            allowShares: communityPost.allowShares,
                            visibility: PostVisibility(rawValue: communityPost.visibility) ?? .public,
                            status: PostStatus(rawValue: communityPost.status) ?? .active,
                            isTop: communityPost.isTop,
                            hotScore: communityPost.hotScore,
                            lastActiveAt: communityPost.lastActiveAt,
                            createdAt: communityPost.createdAt,
                            updatedAt: communityPost.updatedAt,
                            author: communityPost.author,
                            checkin: communityPost.checkin,
                            workout: communityPost.workout,
                            finalScore: nil,
                            explanation: nil,
                            strategy: nil
                        )
                    }
                    hasMoreData = searchData.pagination.hasNext
                }

            } catch {
                errorMessage = "搜索失败：\(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    // MARK: - 便捷方法
    
    /// 清除错误状态
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    /// 检查是否需要加载更多数据
    func shouldLoadMore(for post: CommunityPost) -> Bool {
        guard let lastPost = posts.last else { return false }
        return post.id == lastPost.id && hasMoreData && !isLoading
    }

    // MARK: - 私有辅助方法

    /// 根据标签页获取对应的tab参数
    private func getTabParam(for tab: CommunityTab) -> String {
        switch tab {
        case .recommended, .following, .nearby:
            // 对于全局分类标签页，直接使用对应的tab参数
            return tab.apiValue
        }
    }

    /// 根据标签页获取对应的分类参数
    private func getCategoryParam(for tab: CommunityTab) -> String {
        switch tab {
        case .recommended, .following, .nearby:
            // 对于全局分类标签页，使用all分类
            return "all"
        }
    }

    /// 加载同城帖子
    /// - Parameter page: 页码，默认为1
    /// - Returns: 帖子列表响应
    private func loadNearbyPosts(page: Int = 1) async throws -> PostListResponse {
        // 获取当前位置
        guard let location = await getCurrentLocation() else {
            throw APIError.invalidData("无法获取当前位置，请检查位置权限设置")
        }

        // 调用同城帖子API
        return try await communityService.getNearbyPosts(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radius: 50, // 默认50公里半径
            limit: pageSize
        )
    }

    /// 获取当前位置
    /// - Returns: 当前位置，如果获取失败返回nil
    private func getCurrentLocation() async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            // 如果有LocationManager实例，尝试获取当前位置
            if let locationManager = locationManager,
               let currentLocation = locationManager.currentLocation {
                continuation.resume(returning: currentLocation)
            } else {
                // 如果没有位置信息，返回默认位置（北京天安门）用于测试
                print("⚠️ 无法获取当前位置，使用默认位置（北京天安门）")
                let defaultLocation = CLLocation(latitude: 39.9042, longitude: 116.4074)
                continuation.resume(returning: defaultLocation)
            }
        }
    }
}


