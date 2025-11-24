import SwiftUI
import Combine

/// 短视频滑动浏览 ViewModel
@MainActor
class ShortVideoFeedViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var hasMoreVideos = true
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let communityService = CommunityAPIService.shared
    private var currentPage = 1
    private let pageSize = 10
    private var loadedPostIds = Set<String>()
    
    // MARK: - Initialization
    
    init(posts: [Post] = []) {
        self.posts = posts
        // 记录已加载的帖子ID
        self.loadedPostIds = Set(posts.map { $0.id })
        print("🎬 ShortVideoFeedViewModel 初始化，已有 \(posts.count) 个视频")
    }
    
    // MARK: - Video Playback Control
    
    /// 播放指定索引的视频
    func playVideo(at index: Int) {
        guard index >= 0 && index < posts.count else {
            print("⚠️ ShortVideoFeedViewModel: 无效的视频索引 \(index)")
            return
        }
        
        let post = posts[index]
        guard let videoURL = post.video else {
            print("⚠️ ShortVideoFeedViewModel: 帖子 \(post.id) 没有视频")
            return
        }
        
        print("▶️ ShortVideoFeedViewModel: 播放视频 \(index) - \(videoURL)")
        ShortVideoPlayerManager.shared.play(
            url: videoURL,
            autoPlay: true,
            loop: true,
            muted: false
        )
    }
    
    /// 停止指定索引的视频
    func stopVideo(at index: Int) {
        guard index >= 0 && index < posts.count else { return }
        
        print("⏸️ ShortVideoFeedViewModel: 停止视频 \(index)")
        ShortVideoPlayerManager.shared.pause()
    }
    
    // MARK: - Preloading
    
    /// 预加载相邻视频
    func preloadAdjacentVideos(currentIndex: Int) {
        let preloadIndices = [currentIndex + 1, currentIndex + 2]
        
        for index in preloadIndices {
            guard index >= 0 && index < posts.count else { continue }
            
            if let videoURL = posts[index].video {
                print("📥 ShortVideoFeedViewModel: 预加载视频 \(index)")
                // TODO: 实现预加载逻辑
                // ShortVideoPlayerManager.shared.preload(url: videoURL)
            }
        }
    }
    
    // MARK: - Load More Videos
    
    /// 加载更多视频
    func loadMoreVideos() async {
        guard !isLoading && hasMoreVideos else {
            print("⏭️ ShortVideoFeedViewModel: 跳过加载（isLoading: \(isLoading), hasMoreVideos: \(hasMoreVideos)）")
            return
        }
        
        isLoading = true
        print("📥 ShortVideoFeedViewModel: 开始加载更多视频，页码: \(currentPage + 1)")
        
        do {
            // 获取推荐标签的帖子列表
            let data = try await communityService.getPosts(
                tab: .recommended,
                page: currentPage + 1,
                limit: pageSize
            )

            // 筛选出视频帖子，并去重
            let newVideoPosts = data.items.filter { post in
                post.video != nil && !loadedPostIds.contains(post.id)
            }

            print("✅ ShortVideoFeedViewModel: 加载成功，新增 \(newVideoPosts.count) 个视频")

            // 更新数据
            posts.append(contentsOf: newVideoPosts)
            loadedPostIds.formUnion(newVideoPosts.map { $0.id })
            currentPage += 1

            // 检查是否还有更多数据
            hasMoreVideos = data.pagination.hasNextPage
            
            isLoading = false
            
        } catch {
            print("❌ ShortVideoFeedViewModel: 加载失败 - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Initial Load
    
    /// 初始加载视频列表
    func loadInitialVideos() async {
        guard posts.isEmpty else {
            print("⏭️ ShortVideoFeedViewModel: 已有视频数据，跳过初始加载")
            return
        }
        
        isLoading = true
        currentPage = 1
        print("📥 ShortVideoFeedViewModel: 开始初始加载视频")
        
        do {
            // 获取推荐标签的帖子列表
            let data = try await communityService.getPosts(
                tab: .recommended,
                page: 1,
                limit: pageSize
            )

            // 筛选出视频帖子
            let videoPosts = data.items.filter { $0.video != nil }

            print("✅ ShortVideoFeedViewModel: 初始加载成功，获取 \(videoPosts.count) 个视频")

            // 更新数据
            posts = videoPosts
            loadedPostIds = Set(videoPosts.map { $0.id })

            // 检查是否还有更多数据
            hasMoreVideos = data.pagination.hasNextPage
            
            isLoading = false
            
        } catch {
            print("❌ ShortVideoFeedViewModel: 初始加载失败 - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Refresh
    
    /// 刷新视频列表
    func refresh() async {
        print("🔄 ShortVideoFeedViewModel: 刷新视频列表")
        posts.removeAll()
        loadedPostIds.removeAll()
        currentPage = 1
        hasMoreVideos = true
        await loadInitialVideos()
    }
}

