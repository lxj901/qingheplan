import SwiftUI
import Foundation
import Combine

/// 统一的评论列表视图
/// 管理评论的嵌套显示、加载状态和交互逻辑
struct UnifiedCommentListView: View {
    @StateObject private var commentManager: CommentManager
    @State private var showingCommentInput = false
    @State private var replyingToComment: Comment?
    
    let postId: String
    let onNavigateToProfile: (String) -> Void
    let onCommentCountChanged: ((Int) -> Void)?

    init(postId: String, onNavigateToProfile: @escaping (String) -> Void, onCommentCountChanged: ((Int) -> Void)? = nil) {
        self.postId = postId
        self.onNavigateToProfile = onNavigateToProfile
        self.onCommentCountChanged = onCommentCountChanged

        // 创建 CommentManager 并设置评论数量变化回调
        let manager = CommentManager(postId: postId)
        manager.onCommentCountChanged = onCommentCountChanged
        self._commentManager = StateObject(wrappedValue: manager)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 评论区标题
            commentSectionHeader
            
            // 评论列表内容
            commentListContent
        }
        .onAppear {
            Task {
                await commentManager.loadComments()

                // 加载完成后立即计算并通知评论总数（使用展示总数，取max(服务端, 本地估算)）
                await MainActor.run {
                    let totalComments = commentManager.displayTotalComments
                    onCommentCountChanged?(totalComments)
                    print("📊 UnifiedCommentListView: 评论总数计算完成(展示值): \(totalComments)")
                }
            }
        }
        .sheet(isPresented: $showingCommentInput) {
            CommentInputSheet(
                postId: postId,
                replyingToComment: replyingToComment,
                onSubmit: { content in
                    let parentCommentId = replyingToComment?.id
                    let replyToUserId = replyingToComment?.author.id
                    let success = await commentManager.createComment(
                        content: content,
                        parentCommentId: parentCommentId,
                        replyToUserId: replyToUserId
                    )
                    if success {
                        replyingToComment = nil
                    }
                    return success
                }
            )
        }
    }
    
    // MARK: - 评论区标题
    private var commentSectionHeader: some View {
        HStack {
            Text("评论 \(commentManager.displayTotalComments)")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            // 排序按钮
            Menu {
                Button("最新") {
                    commentManager.sortComments(by: .newest)
                }
                Button("最热") {
                    commentManager.sortComments(by: .hottest)
                }
            } label: {
                HStack(spacing: 4) {
                    Text(commentManager.currentSortType.displayName)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 评论列表内容
    private var commentListContent: some View {
        Group {
            if commentManager.isLoading {
                loadingView
            } else if commentManager.comments.isEmpty {
                emptyCommentsView
            } else {
                commentsList
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(ModernDesignSystem.Colors.primaryGreen)
            
            Text("加载评论中...")
                .font(ModernDesignSystem.Typography.caption1)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ModernDesignSystem.Spacing.xxxl)
    }
    
    // MARK: - 空评论视图
    private var emptyCommentsView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            Image(systemName: "bubble.right")
                .font(.system(size: 32))
                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            
            Text("还没有评论")
                .font(ModernDesignSystem.Typography.subheadline)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            
            Text("来发表第一条评论吧")
                .font(ModernDesignSystem.Typography.caption1)
                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            
            Button("写评论") {
                showingCommentInput = true
            }
            .modernButtonStyle(color: ModernDesignSystem.Colors.primaryGreen)
            .padding(.top, ModernDesignSystem.Spacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ModernDesignSystem.Spacing.xxxl)
    }
    
    // MARK: - 评论列表
    private var commentsList: some View {
        LazyVStack(spacing: 12) { // 增加评论之间的间距
            ForEach(commentManager.comments) { commentNode in
                commentWithReplies(commentNode, level: 0)
            }
        }
        .padding(.horizontal, 16) // 添加左右间距
        .padding(.vertical, 8) // 添加上下间距
    }
    
    // MARK: - 评论及其回复
    private func commentWithReplies(_ commentNode: CommentNode, level: Int) -> some View {
        CommentNodeView(
            commentNode: commentNode,
            level: level,
            onReply: { comment in
                replyingToComment = comment
                showingCommentInput = true
            },
            onToggleExpansion: { commentId in
                // 切换展开状态的逻辑
                Task {
                    await commentManager.toggleCommentExpansion(commentId: commentId)
                }
            },
            onLoadReplies: { commentId in
                // 加载回复的逻辑
                Task {
                    await commentManager.loadReplies(for: commentId)
                }
            },
            onDelete: { commentId in
                Task {
                    await commentManager.deleteComment(commentId: commentId)
                }
            }
        )
    }
    
    // MARK: - 加载更多回复按钮
    private func loadMoreRepliesButton(for comment: Comment, level: Int) -> some View {
        HStack {
            // 缩进
            ForEach(0..<level, id: \.self) { _ in
                Spacer()
                    .frame(width: ModernDesignSystem.Spacing.lg)
            }
            
            Button(action: {
                // commentManager.loadMoreReplies(for: comment) // 暂时注释，等待实现
            }) {
                HStack(spacing: ModernDesignSystem.Spacing.xs) {
                    Image(systemName: "arrow.down")
                        .font(ModernDesignSystem.Typography.caption2)
                    
                    Text("查看更多回复")
                        .font(ModernDesignSystem.Typography.caption1)
                }
                .foregroundColor(ModernDesignSystem.Colors.accentBlue)
                .padding(.horizontal, ModernDesignSystem.Spacing.md)
                .padding(.vertical, ModernDesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.sm)
                        .fill(ModernDesignSystem.Colors.backgroundSecondary)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
    }
}

// MARK: - CommentNodeView
/// 用于处理 CommentNode 绑定的包装视图
struct CommentNodeView: View {
    @ObservedObject var commentNode: CommentNode
    let level: Int
    let onReply: (Comment) -> Void
    let onToggleExpansion: (String) -> Void
    let onLoadReplies: (String) -> Void
    let onDelete: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 使用自定义的评论内容视图，避免递归绑定问题
            CommentContentView(
                commentNode: commentNode,
                level: level,
                onReply: onReply,
                onToggleExpansion: onToggleExpansion,
                onLoadReplies: onLoadReplies,
                onDelete: onDelete
            )

            // 分隔线（仅在顶级评论之间显示）
            if level == 0 {
                Rectangle()
                    .fill(ModernDesignSystem.Colors.borderLight)
                    .frame(height: 0.5)
                    .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                    .padding(.vertical, 8) // 为分隔线添加上下间距
            }
        }
    }
}

// MARK: - CommentContentView
/// 评论内容视图，直接使用 CommentNode 避免绑定问题
struct CommentContentView: View {
    @ObservedObject var commentNode: CommentNode
    let level: Int
    let onReply: (Comment) -> Void
    let onToggleExpansion: (String) -> Void
    let onLoadReplies: (String) -> Void
    let onDelete: (String) -> Void
    
    @State private var showingDeleteAlert = false

    private let indentWidth: CGFloat = 20 // 二级评论的缩进宽度

    // 计算实际缩进：只有二级及以上评论缩进，但都与二级对齐
    private var actualIndentWidth: CGFloat {
        return level > 0 ? indentWidth : 0
    }

    // 判断是否是当前用户的评论
    private var isCurrentUserComment: Bool {
        guard let currentUserId = AuthManager.shared.getCurrentUserId() else { return false }
        return commentNode.comment.author.id == currentUserId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 评论主体内容（带左侧缩进）
            HStack(alignment: .top, spacing: 0) {
                // 左侧缩进（只有二级及以上评论缩进，且都与二级对齐）
                if level > 0 {
                    // 简单的缩进空间
                    Spacer()
                        .frame(width: actualIndentWidth)

                    // 层级指示线
                    Rectangle()
                        .fill(ModernDesignSystem.Colors.borderLight.opacity(0.5))
                        .frame(width: 2)
                        .padding(.trailing, 8)
                }

                // 评论内容
                commentMainContent
            }

            // 子评论（递归显示，继承父级缩进）
            if commentNode.comment.isExpanded && !commentNode.replies.isEmpty {
                VStack(alignment: .leading, spacing: 12) { // 增加子评论之间的间距
                    ForEach(commentNode.replies) { replyNode in
                        CommentContentView(
                            commentNode: replyNode,
                            level: level + 1,
                            onReply: onReply,
                            onToggleExpansion: onToggleExpansion,
                            onLoadReplies: onLoadReplies,
                            onDelete: onDelete
                        )
                    }
                }
                .padding(.top, 12) // 增加子评论区域的上边距
            }
        }
    }

    private var commentMainContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 用户信息和评论内容
            HStack(alignment: .top, spacing: 12) {
                // 用户头像区域（包含"我"标识）
                ZStack {
                    AsyncImage(url: URL(string: commentNode.comment.author.avatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(AppConstants.Colors.primaryGreen.opacity(0.2))
                            .overlay(
                                Text(String(commentNode.comment.author.nickname.prefix(1)))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppConstants.Colors.primaryGreen)
                            )
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())

                    // "我"标识
                    if isCurrentUserComment {
                        Circle()
                            .fill(AppConstants.Colors.primaryGreen)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text("我")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 12, y: 12)
                    }
                }
                .frame(width: 32, height: 32)

                // 评论内容区域
                VStack(alignment: .leading, spacing: 4) {
                    // 用户名和时间
                    HStack {
                        Text(commentNode.comment.author.nickname)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppConstants.Colors.primaryText)

                        Spacer()

                        Text(formatTimeAgoFromString(commentNode.comment.createdAt))
                            .font(.system(size: 12))
                            .foregroundColor(AppConstants.Colors.tertiaryText)
                    }

                    // 评论文本
                    Text(commentNode.comment.content)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)

                    // 操作按钮行
                    HStack(spacing: 16) {
                        // 回复按钮
                        Button(action: { onReply(commentNode.comment) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppConstants.Colors.tertiaryText)

                                Text("回复")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppConstants.Colors.tertiaryText)
                            }
                        }

                        // 查看回复按钮（如果有回复）
                        if commentNode.comment.repliesCount > 0 {
                            Button(action: {
                                if commentNode.replies.isEmpty {
                                    onLoadReplies(commentNode.comment.id)
                                } else {
                                    onToggleExpansion(commentNode.comment.id)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    if commentNode.comment.isLoadingReplies {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: commentNode.comment.isExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppConstants.Colors.tertiaryText)
                                    }

                                    // 显示实时计算的回复总数（包括所有层级）
                                    Text("\(commentNode.comment.repliesCount)条回复")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppConstants.Colors.tertiaryText)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 12) // 增加每个评论的垂直内边距
        .onLongPressGesture {
            if isCurrentUserComment {
                showingDeleteAlert = true
            }
        }
        .alert("删除评论", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                onDelete(commentNode.comment.id)
            }
        } message: {
            Text("确定要删除这条评论吗？")
        }
    }

    private func formatTimeAgo(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 60 {
            return "刚刚"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分钟前"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)小时前"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)天前"
        }
    }

    private func formatTimeAgoFromString(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            return formatTimeAgo(date)
        }

        // 如果解析失败，尝试其他格式
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        fallbackFormatter.timeZone = TimeZone(abbreviation: "UTC")

        if let date = fallbackFormatter.date(from: dateString) {
            return formatTimeAgo(date)
        }

        // 如果都解析失败，返回原始字符串
        return dateString
    }
}

// MARK: - 预览
struct UnifiedCommentListView_Previews: PreviewProvider {
    static var previews: some View {
        UnifiedCommentListView(
            postId: "sample_post",
            onNavigateToProfile: { _ in }
        )
    }
}