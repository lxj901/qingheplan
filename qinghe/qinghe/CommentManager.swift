import SwiftUI
import Combine

// MARK: - 评论管理器
@MainActor
class CommentManager: ObservableObject {
    @Published var comments: [CommentNode] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var replyingToComment: Comment?
    @Published var currentSortType: CommentSortType = .newest

    // 服务端返回的总评论数（包含所有层级）
    @Published private(set) var serverTotalComments: Int = 0

    private let communityService: CommunityAPIService
    private let postId: String

    // 评论总数变化回调
    var onCommentCountChanged: ((Int) -> Void)?
    
    init(postId: String, communityService: CommunityAPIService = CommunityAPIService.shared) {
        self.postId = postId
        self.communityService = communityService
    }
    
    // MARK: - 公共方法
    
    /// 加载评论列表
    func loadComments() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let commentsData = try await communityService.getComments(postId: postId)
            let commentNodes = buildCommentTree(from: commentsData.items)

            await MainActor.run {
                self.comments = commentNodes
                self.serverTotalComments = commentsData.pagination.total

                // 计算并通知评论总数变化（与服务端的分页 total 取最大值，避免低估）
                let localEstimatedTotal = calculateTotalComments()
                let bestTotal = max(localEstimatedTotal, self.serverTotalComments)
                print("📊 CommentManager: 加载评论完成，本地估算: \(localEstimatedTotal), 服务端total: \(self.serverTotalComments), 采用: \(bestTotal) (一级评论: \(commentNodes.count))")
                onCommentCountChanged?(bestTotal)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载评论失败: \(error.localizedDescription)"
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }
    
    /// 发表新评论
    func createComment(content: String, parentCommentId: String? = nil, replyToUserId: Int? = nil) async -> Bool {
        do {
            let request = CreateCommentRequest(
                content: content,
                parentCommentId: parentCommentId,
                replyToUserId: replyToUserId
            )
            
            let response = try await communityService.createComment(postId: postId, request: request)
            
            if response.success, let newComment = response.data {
                // 将新评论添加到本地数据结构中
                await insertNewComment(newComment)

                // 通知评论总数变化（取max(服务端, 本地估算)）
                await MainActor.run {
                    let totalComments = max(self.serverTotalComments, calculateTotalComments())
                    onCommentCountChanged?(totalComments)
                }

                return true
            } else {
                await MainActor.run {
                    self.errorMessage = response.message ?? "发表评论失败"
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "发表评论失败: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    /// 点赞评论
    func toggleCommentLike(commentId: String) {
        // 在本地先更新UI，然后发送网络请求
        updateCommentLikeStatus(commentId: commentId)

        Task {
            // TODO: 调用点赞API
            // do {
            //     try await communityService.toggleCommentLike(commentId: commentId)
            // } catch {
            //     // 如果失败，回滚本地状态
            //     updateCommentLikeStatus(commentId: commentId)
            //     self.errorMessage = "点赞失败: \(error.localizedDescription)"
            // }
        }
    }

    /// 删除评论
    func deleteComment(commentId: String) async {
        do {
            let response = try await communityService.deleteComment(commentId: commentId)

            if response.success {
                // 从本地数据结构中移除评论
                removeCommentFromTree(commentId: commentId)

                // 通知评论总数变化（取max(服务端, 本地估算)）
                let totalComments = max(self.serverTotalComments, calculateTotalComments())
                onCommentCountChanged?(totalComments)
            } else {
                self.errorMessage = response.message ?? "删除评论失败"
            }
        } catch {
            self.errorMessage = "删除评论失败: \(error.localizedDescription)"
        }
    }
    
    /// 加载评论的回复
    func loadCommentReplies(commentId: String) async {
        // TODO: 实现加载特定评论的回复
        // 这里可以调用API获取更多回复，然后更新对应的CommentNode
    }

    /// 切换评论展开状态
    func toggleCommentExpansion(commentId: String) async {
        guard let node = findCommentNode(by: commentId) else {
            print("❌ 找不到评论节点: \(commentId)")
            return
        }

        print("🔄 切换评论展开状态: \(commentId), 当前状态: \(node.isExpanded)")

        await MainActor.run {
            node.toggleExpansion()

            // 递归同步整个树的状态
            syncCommentNodeToModel(findRootNode(for: node))

            // 触发UI更新
            objectWillChange.send()
        }

        // 如果是展开状态且没有回复数据，则加载回复
        if node.isExpanded && node.replies.isEmpty && node.comment.repliesCount > 0 {
            print("📥 加载回复: \(commentId)")
            await loadReplies(for: commentId)
        }
    }

    /// 加载指定评论的回复
    func loadReplies(for commentId: String) async {
        guard let node = findCommentNode(by: commentId) else { return }

        await MainActor.run {
            node.isLoadingReplies = true
            node.comment.isLoadingReplies = true
            objectWillChange.send()
        }

        do {
            let repliesData: CommentListData = try await communityService.getCommentReplies(
                commentId: commentId,
                page: 1,
                limit: 20
            )

            await MainActor.run {
                // 构建回复节点树结构（支持多级回复）
                let replyNodes = buildCommentTree(from: repliesData.items)

                // 将回复节点添加到父节点
                for replyNode in replyNodes {
                    replyNode.parent = node
                }

                node.replies = replyNodes
                node.isExpanded = true

                // 同步到 Comment 模型（递归同步所有层级）
                syncCommentNodeToModel(node)

                node.isLoadingReplies = false
                node.comment.isLoadingReplies = false

                // 通知评论总数变化（取max(服务端, 本地估算)）
                let totalComments = max(self.serverTotalComments, calculateTotalComments())
                onCommentCountChanged?(totalComments)

                // 触发UI更新
                objectWillChange.send()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载回复失败: \(error.localizedDescription)"
                node.isLoadingReplies = false
                node.comment.isLoadingReplies = false
                objectWillChange.send()
            }
        }
    }
    
    /// 设置回复目标
    func setReplyTarget(_ comment: Comment) {
        replyingToComment = comment
    }
    
    /// 清除回复目标
    func clearReplyTarget() {
        replyingToComment = nil
    }
    
    // MARK: - 私有方法
    
    /// 构建评论树结构
    private func buildCommentTree(from comments: [Comment]) -> [CommentNode] {
        var commentMap: [String: CommentNode] = [:]
        var rootComments: [CommentNode] = []
        
        // 首先创建所有评论节点
        for comment in comments {
            let node = CommentNode(comment: comment)
            commentMap[comment.id] = node
        }
        
        // 然后建立父子关系
        for comment in comments {
            guard let node = commentMap[comment.id] else { continue }
            
            if let parentId = comment.parentCommentId,
               let parentNode = commentMap[parentId] {
                // 这是一个回复评论
                parentNode.replies.append(node)
                node.parent = parentNode
            } else {
                // 这是一个根评论
                rootComments.append(node)
            }
        }
        
        // 对回复进行排序（按时间）
        for node in commentMap.values {
            node.replies.sort { $0.comment.createdAt < $1.comment.createdAt }
        }
        
        // 对根评论进行排序（按时间倒序，最新的在前）
        rootComments.sort { $0.comment.createdAt > $1.comment.createdAt }

        // 同步所有节点的状态到 Comment 模型
        for rootNode in rootComments {
            syncCommentNodeToModel(rootNode)
        }

        return rootComments
    }
    
    /// 插入新评论到本地数据结构
    private func insertNewComment(_ comment: Comment) async {
        await MainActor.run {
            let newNode = CommentNode(comment: comment)

            if let parentId = comment.parentCommentId {
                // 这是一个回复评论，找到父评论并添加
                if let parentNode = findCommentNode(by: parentId) {
                    parentNode.replies.append(newNode)
                    newNode.parent = parentNode

                    // 更新父评论的回复数量
                    parentNode.comment.repliesCount += 1

                    // 确保父评论展开以显示新回复
                    if !parentNode.isExpanded {
                        parentNode.isExpanded = true
                        parentNode.comment.isExpanded = true
                    }

                    // 同步父节点状态到模型
                    syncCommentNodeToModel(findRootNode(for: parentNode))

                    print("✅ 新回复已添加到父评论: \(parentId)")
                }
            } else {
                // 这是一个根评论，添加到根列表的开头
                comments.insert(newNode, at: 0)
                print("✅ 新根评论已添加")
            }

            // 触发UI更新
            objectWillChange.send()
        }
    }
    
    /// 查找评论节点
    private func findCommentNode(by commentId: String) -> CommentNode? {
        return findCommentNodeRecursive(in: comments, commentId: commentId)
    }
    
    /// 递归查找评论节点
    private func findCommentNodeRecursive(in nodes: [CommentNode], commentId: String) -> CommentNode? {
        for node in nodes {
            if node.comment.id == commentId {
                return node
            }
            
            if let found = findCommentNodeRecursive(in: node.replies, commentId: commentId) {
                return found
            }
        }
        return nil
    }
    
    /// 更新评论点赞状态
    private func updateCommentLikeStatus(commentId: String) {
        guard let node = findCommentNode(by: commentId) else { return }

        node.comment.isLiked.toggle()
        node.comment.likesCount += node.comment.isLiked ? 1 : -1

        // 触发UI更新
        objectWillChange.send()
    }

    /// 从评论树中移除评论
    private func removeCommentFromTree(commentId: String) {
        // 先尝试从根评论中移除
        if let index = comments.firstIndex(where: { $0.comment.id == commentId }) {
            comments.remove(at: index)
            return
        }

        // 递归从子评论中移除
        removeCommentFromTreeRecursive(in: &comments, commentId: commentId)
    }

    /// 递归从评论树中移除评论
    private func removeCommentFromTreeRecursive(in nodes: inout [CommentNode], commentId: String) {
        for i in 0..<nodes.count {
            // 检查当前节点的回复
            if let index = nodes[i].replies.firstIndex(where: { $0.comment.id == commentId }) {
                nodes[i].replies.remove(at: index)
                // 更新父评论的回复数量
                nodes[i].comment.repliesCount = max(0, nodes[i].comment.repliesCount - 1)
                return
            }

            // 递归检查子节点
            removeCommentFromTreeRecursive(in: &nodes[i].replies, commentId: commentId)
        }
    }

    /// 递归同步 CommentNode 状态到 Comment 模型
    private func syncCommentNodeToModel(_ node: CommentNode) {
        // 同步当前节点的状态
        node.comment.isExpanded = node.isExpanded
        node.comment.isLoadingReplies = node.isLoadingReplies

        // 同步回复列表
        node.comment.replies = node.replies.map { replyNode in
            // 递归同步子节点
            syncCommentNodeToModel(replyNode)
            return replyNode.comment
        }
    }

    /// 找到节点的根节点
    private func findRootNode(for node: CommentNode) -> CommentNode {
        var current = node
        while let parent = current.parent {
            current = parent
        }
        return current
    }
}

// MARK: - 评论节点数据结构
class CommentNode: ObservableObject, Identifiable {
    let id = UUID()
    @Published var comment: Comment
    @Published var replies: [CommentNode] = []
    @Published var isExpanded: Bool = false
    @Published var isLoadingReplies: Bool = false

    weak var parent: CommentNode?

    init(comment: Comment) {
        self.comment = comment
    }
    
    /// 获取评论的嵌套层级
    var level: Int {
        var currentLevel = 0
        var currentParent = parent
        
        while currentParent != nil {
            currentLevel += 1
            currentParent = currentParent?.parent
        }
        
        return currentLevel
    }
    
    /// 切换展开状态
    func toggleExpansion() {
        isExpanded.toggle()
        // 同步到 Comment 模型
        comment.isExpanded = isExpanded
    }
    
    /// 获取所有子评论的数量（递归）
    var totalRepliesCount: Int {
        var count = replies.count
        for reply in replies {
            count += reply.totalRepliesCount
        }
        return count
    }
}

// MARK: - CommentManager 扩展
extension CommentManager {
    /// 计算评论总数（包括所有层级的评论）
    func calculateTotalComments() -> Int {
        let total = calculateCommentsCount(in: comments)
        print("📊 CommentManager: 评论总数计算详情 - 一级评论: \(comments.count), 本地估算总评论数: \(total)")
        return total
    }

    /// 用于展示的总评论数 = max(服务端总数, 本地估算)
    var displayTotalComments: Int {
        return max(serverTotalComments, calculateTotalComments())
    }

    /// 递归计算评论数量（包括所有层级）。
    /// 如果某个节点的子回复尚未加载（replies.isEmpty），则使用后端提供的 repliesCount 进行估算，
    /// 这样可以在不展开回复的情况下，也统计到二级、三级等更深层级的数量。
    private func calculateCommentsCount(in nodes: [CommentNode]) -> Int {
        var count = 0
        for node in nodes {
            // 先计入当前评论本身
            count += 1
            if node.replies.isEmpty {
                // 子回复未加载，使用后端给出的总回复数进行估算
                count += max(0, node.comment.repliesCount)
                if node.comment.repliesCount > 0 {
                    print("📊 CommentManager: 评论 \(node.comment.id) 子回复未加载，使用 repliesCount 估算: \(node.comment.repliesCount)")
                }
            } else {
                // 子回复已加载，递归计算实际数量
                let subtree = calculateCommentsCount(in: node.replies)
                count += subtree
                if subtree > 0 {
                    print("📊 CommentManager: 评论 \(node.comment.id) 已加载子回复，实际总数: \(subtree)")
                }
            }
        }
        return count
    }

    /// 按类型排序评论
    func sortComments(by sortType: CommentSortType) {
        currentSortType = sortType
        sortCommentsRecursive(&comments, by: sortType)
        objectWillChange.send()
    }

    /// 递归排序评论
    private func sortCommentsRecursive(_ nodes: inout [CommentNode], by sortType: CommentSortType) {
        switch sortType {
        case .newest:
            nodes.sort { $0.comment.createdAt > $1.comment.createdAt }
        case .oldest:
            nodes.sort { $0.comment.createdAt < $1.comment.createdAt }
        case .hottest:
            nodes.sort { $0.comment.likesCount > $1.comment.likesCount }
        }

        // 递归排序子评论
        for node in nodes {
            sortCommentsRecursive(&node.replies, by: sortType)
        }
    }
}


