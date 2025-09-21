import Foundation
import SwiftUI
import Combine

/// 帖子详情页面视图模型
@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var post: Post?
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var replyingToComment: Comment?
    @Published var isFollowingAuthor = false
    @Published var isFollowActionLoading = false
    @Published var showError = false
    @Published var totalCommentsCount = 0
    @Published var commentSortType: CommentSortType = .newest

    // 添加postId属性
    private(set) var postId: String = ""

    private let communityService = CommunityAPIService.shared
    private let authManager = AuthManager.shared

    init() {
        // PostDetailViewModel 初始化
    }

    /// 加载帖子详情
    func loadPost(postId: String) async {
        // 避免重复加载相同的帖子
        guard self.postId != postId || self.post == nil else {
            print("🔄 PostDetailViewModel: 跳过重复加载，postId: \(postId)")
            return
        }

        print("🔄 PostDetailViewModel: 开始加载帖子详情，postId: \(postId)")
        
        await MainActor.run {
            self.postId = postId  // 存储postId
            isLoading = true
            errorMessage = nil
        }

        do {
            // 使用 Task.detached 避免阻塞主线程
            let postDetailResponse = try await communityService.getPostDetail(postId: postId)

            await MainActor.run {
                if postDetailResponse.success {
                    self.post = postDetailResponse.data
                    print("✅ PostDetailViewModel: 帖子详情加载成功")
                } else {
                    self.errorMessage = postDetailResponse.message ?? "获取帖子详情失败"
                    print("❌ PostDetailViewModel: 帖子详情加载失败: \(self.errorMessage ?? "")")
                }
            }

            // 如果帖子作者不是当前用户，获取关注状态
            if let post = self.post, !isCurrentUserPost(post) {
                await loadFollowStatus(userId: post.author.id)
            }

            // 异步加载评论，不阻塞UI
            Task {
                await loadComments(postId: postId)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载帖子失败: \(error.localizedDescription)"
                self.showError = true
                print("❌ PostDetailViewModel: 网络请求异常: \(error.localizedDescription)")
            }
        }

        await MainActor.run {
            isLoading = false
            print("🔄 PostDetailViewModel: 帖子详情加载完成")
        }
    }

    /// 加载评论列表
    func loadComments(postId: String) async {
        print("🔄 PostDetailViewModel: 开始加载评论，postId: \(postId)")
        do {
            let commentsResponse = try await communityService.getComments(postId: postId)
            await MainActor.run {
                self.comments = commentsResponse.items
                print("✅ PostDetailViewModel: 评论加载成功，数量: \(commentsResponse.items.count)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载评论失败: \(error.localizedDescription)"
                print("❌ PostDetailViewModel: 评论加载失败: \(error.localizedDescription)")
            }
        }
    }

    /// 切换点赞状态
    func toggleLike() {
        guard let post = post else { return }

        Task {
            do {
                let response = try await communityService.toggleLikePost(postId: post.id)
                if response.success {
                    self.post?.isLiked = response.data?.isLiked ?? false
                    if response.data?.isLiked == true {
                        self.post?.likesCount += 1
                    } else {
                        self.post?.likesCount = max(0, (self.post?.likesCount ?? 0) - 1)
                    }
                }
            } catch {
                self.errorMessage = "操作失败: \(error.localizedDescription)"
            }
        }
    }

    /// 发布评论
    func postComment(content: String) async -> Bool {
        guard let post = post else { return false }

        do {
            let request = CreateCommentRequest(
                content: content,
                parentCommentId: replyingToComment?.id,
                replyToUserId: replyingToComment?.authorId
            )

            let response = try await communityService.createComment(postId: post.id, request: request)
            if response.success, let newComment = response.data {
                await MainActor.run {
                    // 根据是否有父评论来决定添加位置
                    if let parentCommentId = newComment.parentCommentId {
                        // 这是一个回复评论，添加到父评论的回复列表中
                        self.addReplyToParentComment(reply: newComment, parentCommentId: parentCommentId)
                    } else {
                        // 这是一个顶级评论，添加到顶级评论列表开头
                        self.comments.insert(newComment, at: 0)
                    }
                    self.post?.commentsCount += 1
                    self.replyingToComment = nil
                }
                return true
            } else {
                await MainActor.run {
                    self.errorMessage = response.message ?? "发布评论失败"
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "发布评论失败: \(error.localizedDescription)"
            }
            return false
        }
    }

    /// 删除帖子
    func deletePost() async -> Bool {
        guard let post = post else { return false }

        do {
            let response = try await communityService.deletePost(postId: post.id)
            return response.success
        } catch {
            self.errorMessage = "删除帖子失败: \(error.localizedDescription)"
            return false
        }
    }
    
    /// 切换关注状态
    func toggleFollowUser() async {
        guard let post = post else { return }

        // 防止重复操作
        guard !isFollowActionLoading else { return }

        isFollowActionLoading = true

        do {
            let response: CommunityAPIResponse<FollowResponse>

            if isFollowingAuthor {
                response = try await communityService.unfollowUser(userId: post.author.id)
            } else {
                response = try await communityService.followUser(userId: post.author.id)
            }

            // 检查响应状态
            if response.success {
                // 更新关注状态
                if let data = response.data {
                    isFollowingAuthor = data.isFollowing
                } else {
                    // 如果服务器没有返回data字段，根据操作类型推断最终状态
                    isFollowingAuthor = !isFollowingAuthor
                }

                // 更新帖子中的作者关注状态
                self.post?.author = Author(
                    id: post.author.id,
                    nickname: post.author.nickname,
                    avatar: post.author.avatar,
                    isVerified: post.author.isVerified,
                    level: post.author.level,
                    followersCount: response.data?.followersCount ?? post.author.followersCount,
                    isFollowing: isFollowingAuthor
                )

                // 根据最终状态显示消息
                if let message = response.message,
                   (message.contains("已经关注了该用户") || message.contains("未关注该用户") || message.contains("没有关注该用户")) {
                    // 显示服务器返回的具体消息
                    successMessage = message
                } else {
                    // 显示默认成功消息
                    successMessage = isFollowingAuthor ? "关注成功" : "取消关注成功"
                }

                // 操作成功后，重新获取最新的关注状态以确保准确性
                await loadFollowStatus(userId: post.author.id)
            } else {
                // 处理失败情况
                errorMessage = response.message ?? "操作失败"
            }
        } catch {
            // 由于CommunityAPIService已经处理了大部分特殊情况，这里主要处理真正的网络错误
            print("❌ 关注操作失败: \(error)")
            errorMessage = "操作失败: \(error.localizedDescription)"
        }

        isFollowActionLoading = false
    }

    /// 加载关注状态
    private func loadFollowStatus(userId: Int) async {
        do {
            let response = try await communityService.getUserProfile(userId: userId)
            if response.success, let data = response.data {
                await MainActor.run {
                    isFollowingAuthor = data.isFollowing ?? false
                }
            }
        } catch {
            // 获取关注状态失败，保持默认状态
        }
    }



    /// 判断是否是当前用户的帖子
    private func isCurrentUserPost(_ post: Post) -> Bool {
        guard let currentUserId = authManager.getCurrentUserId() else {
            return false
        }
        return currentUserId == post.author.id
    }
    
    /// 切换收藏状态
    func toggleBookmark() {
        guard let post = post else { return }

        Task {
            do {
                let response = try await communityService.toggleBookmarkPost(postId: post.id)
                if response.success {
                    await MainActor.run {
                        self.post?.isBookmarked = response.data?.isBookmarked ?? false
                        if response.data?.isBookmarked == true {
                            self.post?.bookmarksCount += 1
                        } else {
                            self.post?.bookmarksCount = max(0, (self.post?.bookmarksCount ?? 0) - 1)
                        }
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = response.message ?? "收藏操作失败"
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "收藏操作失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// 切换评论点赞
    func toggleCommentLike(commentId: String) async {
        // 先在本地更新UI，提供即时反馈
        updateCommentLikeStatus(commentId: commentId)

        // TODO: 实现评论点赞API调用
        // do {
        //     let response = try await communityService.toggleCommentLike(commentId: commentId)
        //     if !response.success {
        //         // 如果API调用失败，回滚本地状态
        //         updateCommentLikeStatus(commentId: commentId)
        //         self.errorMessage = "点赞失败: \(response.message ?? "未知错误")"
        //     }
        // } catch {
        //     // 如果失败，回滚本地状态
        //     updateCommentLikeStatus(commentId: commentId)
        //     self.errorMessage = "点赞失败: \(error.localizedDescription)"
        // }
    }
    
    /// 回复评论
    func replyToComment(_ comment: Comment) {
        self.replyingToComment = comment
    }
    
    /// 切换评论展开状态
    func toggleCommentExpansion(commentId: String) {
        // TODO: 实现评论展开功能
    }
    
    /// 加载评论回复
    func loadCommentReplies(commentId: String) async {
        do {
            // 使用第一个方法，它直接返回CommentListData
            let repliesData: CommentListData = try await communityService.getCommentReplies(
                commentId: commentId,
                page: 1,
                limit: 20
            )

            // 找到对应的评论并更新其回复列表
            await MainActor.run {
                updateCommentReplies(commentId: commentId, replies: repliesData.items)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载回复失败: \(error.localizedDescription)"
            }
        }
    }
    
    /// 删除评论
    func deleteComment(commentId: String) async {
        // 先找到要删除的评论，计算会影响的评论数量
        let commentToDelete = findComment(by: commentId, in: comments)
        let deletedCommentsCount = calculateDeletedCommentsCount(comment: commentToDelete)

        do {
            // 调用后端API删除评论
            let response: CommunityAPIResponse<String> = try await communityService.deleteComment(commentId: commentId)

            if response.success {
                await MainActor.run {
                    // 从本地列表中移除评论
                    removeCommentFromList(commentId: commentId)

                    // 更新帖子的评论数量（删除评论会同时删除其所有回复）
                    if let post = post {
                        self.post?.commentsCount = max(0, post.commentsCount - deletedCommentsCount)
                    }

                    // 显示成功消息
                    self.successMessage = "评论删除成功"
                }
            } else {
                await MainActor.run {
                    self.errorMessage = response.message ?? "删除评论失败"
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "删除评论失败: \(error.localizedDescription)"
            }
        }
    }
    
    /// 切换评论排序
    func changeCommentSort(to sortType: CommentSortType) async {
        self.commentSortType = sortType
        // TODO: 重新加载评论
    }

    // MARK: - 私有辅助方法

    /// 更新评论点赞状态
    private func updateCommentLikeStatus(commentId: String) {
        // 递归查找并更新评论
        updateCommentLikeStatusRecursive(in: &comments, commentId: commentId)
    }

    /// 递归更新评论点赞状态
    private func updateCommentLikeStatusRecursive(in comments: inout [Comment], commentId: String) {
        for i in 0..<comments.count {
            if comments[i].id == commentId {
                comments[i].isLiked.toggle()
                comments[i].likesCount += comments[i].isLiked ? 1 : -1
                return
            }
            // 递归搜索回复
            updateCommentLikeStatusRecursive(in: &comments[i].replies, commentId: commentId)
        }
    }

    /// 更新评论回复列表
    private func updateCommentReplies(commentId: String, replies: [Comment]) {
        updateCommentRepliesRecursive(in: &comments, commentId: commentId, replies: replies)
    }

    /// 递归更新评论回复列表
    private func updateCommentRepliesRecursive(in comments: inout [Comment], commentId: String, replies: [Comment]) {
        for i in 0..<comments.count {
            if comments[i].id == commentId {
                comments[i].replies = replies
                comments[i].isExpanded = true
                return
            }
            // 递归搜索回复
            updateCommentRepliesRecursive(in: &comments[i].replies, commentId: commentId, replies: replies)
        }
    }

    /// 从评论列表中移除评论
    private func removeCommentFromList(commentId: String) {
        removeCommentRecursive(from: &comments, commentId: commentId)
    }

    /// 递归移除评论
    private func removeCommentRecursive(from comments: inout [Comment], commentId: String) {
        // 移除顶级评论
        comments.removeAll { $0.id == commentId }

        // 递归移除回复中的评论
        for i in 0..<comments.count {
            removeCommentRecursive(from: &comments[i].replies, commentId: commentId)
        }
    }

    /// 查找评论
    private func findComment(by commentId: String, in comments: [Comment]) -> Comment? {
        for comment in comments {
            if comment.id == commentId {
                return comment
            }
            if let found = findComment(by: commentId, in: comment.replies) {
                return found
            }
        }
        return nil
    }

    /// 计算删除评论时会影响的总评论数（包括所有子回复）
    private func calculateDeletedCommentsCount(comment: Comment?) -> Int {
        guard let comment = comment else { return 1 }

        var count = 1 // 当前评论

        // 递归计算所有子回复
        for reply in comment.replies {
            count += calculateDeletedCommentsCount(comment: reply)
        }

        return count
    }

    /// 将回复添加到父评论的回复列表中
    private func addReplyToParentComment(reply: Comment, parentCommentId: String) {
        addReplyRecursive(to: &comments, reply: reply, parentCommentId: parentCommentId)
    }

    /// 递归查找父评论并添加回复
    private func addReplyRecursive(to comments: inout [Comment], reply: Comment, parentCommentId: String) {
        for i in 0..<comments.count {
            if comments[i].id == parentCommentId {
                // 找到父评论，添加回复到其回复列表
                comments[i].replies.append(reply)
                comments[i].repliesCount += 1
                // 如果父评论已经展开，确保新回复可见
                if !comments[i].isExpanded {
                    comments[i].isExpanded = true
                }
                return
            }
            // 递归搜索回复中的评论
            addReplyRecursive(to: &comments[i].replies, reply: reply, parentCommentId: parentCommentId)
        }
    }

    /// 更新评论总数（优先保持服务端的正确数值，只在本地计算确实更大时才更新）
    func updateCommentsCount(_ newCount: Int) {
        let existingPostCount = post?.commentsCount ?? 0

        // 如果服务端已有正确的评论总数，且本地计算的数值不大于它，则保持不变
        if existingPostCount > 0 && newCount <= existingPostCount {
            print("📊 PostDetailViewModel: 保持服务端评论总数 \(existingPostCount)，忽略本地计算值 \(newCount)")
            return
        }

        // 只有在本地计算的数值确实更大时才更新
        let best = max(totalCommentsCount, newCount, existingPostCount)
        totalCommentsCount = best
        post?.commentsCount = best
        print("📊 PostDetailViewModel: 更新评论总数到 \(best) (本地计算: \(newCount), 原有: \(existingPostCount))")
    }
}
