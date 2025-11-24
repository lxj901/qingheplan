import SwiftUI
import Foundation

/// 标签详情页面视图模型
@MainActor
class TagDetailViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasMorePosts: Bool = true
    @Published var totalCount: Int?
    
    private let communityService = CommunityAPIService.shared
    private var currentPage: Int = 1
    private var currentTagName: String = ""
    private var currentSortBy: String = "latest"
    private var currentLoadTask: Task<Void, Never>?
    
    // MARK: - 加载标签帖子
    func loadTagPosts(tagName: String, sortBy: String = "latest", refresh: Bool = false) async {
        // 取消之前的请求
        currentLoadTask?.cancel()
        
        if refresh {
            currentPage = 1
            hasMorePosts = true
            posts = []
        }
        
        guard !isLoading && hasMorePosts else { return }
        
        isLoading = true
        errorMessage = nil
        currentTagName = tagName
        currentSortBy = sortBy
        
        print("🏷️ 开始加载标签帖子: \(tagName), 排序: \(sortBy), 页码: \(currentPage)")
        print("🏷️ 调用 API: getPostsByTag")
        print("🏷️ 参数 - tagName: '\(tagName)', page: \(currentPage), limit: 20, sortBy: '\(sortBy)'")

        // 创建新的任务
        currentLoadTask = Task {
            do {
                print("🏷️ 正在调用 communityService.getPostsByTag...")
                let response = try await communityService.getPostsByTag(
                    tagName: tagName,
                    page: currentPage,
                    limit: 20,
                    sortBy: sortBy
                )
                print("🏷️ API 调用完成，收到响应")
                
                // 检查任务是否被取消
                guard !Task.isCancelled else { return }
                
                print("🏷️ 响应状态: success=\(response.success)")
                if let message = response.message {
                    print("🏷️ 响应消息: \(message)")
                }

                guard response.success, let data = response.data else {
                    let failureMessage = response.message ?? "获取标签帖子失败"
                    print("❌ 标签帖子获取失败: \(failureMessage)")
                    errorMessage = failureMessage
                    return
                }
                
                print("🏷️ 成功获取标签帖子: \(data.items.count) 个")
                print("🏷️ 标签名称: \(data.tagName)")
                print("🏷️ 总数: \(data.pagination.total)")
                
                if refresh {
                    posts = data.items
                } else {
                    posts.append(contentsOf: data.items)
                }
                
                totalCount = data.pagination.total
                hasMorePosts = data.pagination.hasNext
                currentPage += 1
                
                print("🏷️ 更新后总帖子数: \(posts.count)")
                print("🏷️ hasMorePosts: \(hasMorePosts)")
                
            } catch {
                // 检查任务是否被取消
                guard !Task.isCancelled else {
                    print("🏷️ 任务被取消")
                    return
                }

                // 过滤掉取消错误
                if error is CancellationError {
                    print("🏷️ 收到取消错误")
                    return
                }

                if let urlError = error as? URLError, urlError.code == .cancelled {
                    print("🏷️ 收到 URL 取消错误")
                    return
                }

                print("❌ 加载标签帖子失败: \(error)")
                print("❌ 错误类型: \(type(of: error))")
                print("❌ 错误描述: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
        
        await currentLoadTask?.value
    }
    
    // MARK: - 加载更多帖子
    func loadMorePosts() async {
        guard !currentTagName.isEmpty else { return }
        await loadTagPosts(tagName: currentTagName, sortBy: currentSortBy, refresh: false)
    }
    
    // MARK: - 切换点赞状态
    func toggleLike(postId: String) async {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        
        // 乐观更新UI
        let wasLiked = posts[index].isLiked
        posts[index].isLiked.toggle()
        posts[index].likesCount += wasLiked ? -1 : 1
        
        do {
            let response = try await communityService.toggleLikePost(postId: postId)
            
            if response.success, let likeData = response.data {
                // 使用服务器返回的真实数据更新
                posts[index].isLiked = likeData.isLiked
                // 注意：LikeData 不包含 likesCount，所以保持当前的乐观更新值

                print("🏷️ 点赞状态更新成功: \(likeData.isLiked)")
            } else {
                // 如果失败，回滚UI更改
                posts[index].isLiked = wasLiked
                posts[index].likesCount += wasLiked ? 1 : -1
                print("🏷️ 点赞失败: \(response.message ?? "未知错误")")
            }
        } catch {
            // 如果出错，回滚UI更改
            posts[index].isLiked = wasLiked
            posts[index].likesCount += wasLiked ? 1 : -1
            print("🏷️ 点赞请求失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 切换收藏状态
    func toggleBookmark(postId: String) async {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        
        // 乐观更新UI
        let wasBookmarked = posts[index].isBookmarked
        posts[index].isBookmarked.toggle()
        posts[index].bookmarksCount += wasBookmarked ? -1 : 1
        
        do {
            let response = try await communityService.toggleBookmarkPost(postId: postId)
            
            if response.success, let bookmarkData = response.data {
                // 使用服务器返回的真实数据更新
                posts[index].isBookmarked = bookmarkData.isBookmarked
                // 注意：BookmarkData 不包含 bookmarksCount，所以保持当前的乐观更新值

                print("🏷️ 收藏状态更新成功: \(bookmarkData.isBookmarked)")
            } else {
                // 如果失败，回滚UI更改
                posts[index].isBookmarked = wasBookmarked
                posts[index].bookmarksCount += wasBookmarked ? 1 : -1
                print("🏷️ 收藏失败: \(response.message ?? "未知错误")")
            }
        } catch {
            // 如果出错，回滚UI更改
            posts[index].isBookmarked = wasBookmarked
            posts[index].bookmarksCount += wasBookmarked ? 1 : -1
            print("🏷️ 收藏请求失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 取消当前请求
    func cancelCurrentRequest() {
        currentLoadTask?.cancel()
        currentLoadTask = nil
        isLoading = false
    }
    
    // MARK: - 清理资源
    deinit {
        currentLoadTask?.cancel()
    }
}

// MARK: - 热门标签视图模型
@MainActor
class PopularTagsViewModel: ObservableObject {
    @Published var popularTags: [PopularTag] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let communityService = CommunityAPIService.shared
    private var currentLoadTask: Task<Void, Never>?
    
    // MARK: - 加载热门标签
    func loadPopularTags(limit: Int = 10) async {
        // 取消之前的请求
        currentLoadTask?.cancel()
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        print("🏷️ 开始加载热门标签, 限制数量: \(limit)")
        
        // 创建新的任务
        currentLoadTask = Task {
            do {
                let response = try await communityService.getPopularTags(limit: limit)
                
                // 检查任务是否被取消
                guard !Task.isCancelled else { return }
                
                guard response.success, let tags = response.data else {
                    errorMessage = response.message ?? "获取热门标签失败"
                    return
                }
                
                print("🏷️ 成功获取热门标签: \(tags.count) 个")
                popularTags = tags
                
            } catch {
                // 检查任务是否被取消
                guard !Task.isCancelled else { return }
                
                // 过滤掉取消错误
                if error is CancellationError {
                    return
                }
                
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    return
                }
                
                print("🏷️ 加载热门标签失败: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
        
        await currentLoadTask?.value
    }
    
    // MARK: - 取消当前请求
    func cancelCurrentRequest() {
        currentLoadTask?.cancel()
        currentLoadTask = nil
        isLoading = false
    }
    
    // MARK: - 清理资源
    deinit {
        currentLoadTask?.cancel()
    }
}
