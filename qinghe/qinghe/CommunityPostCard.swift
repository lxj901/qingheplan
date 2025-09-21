import SwiftUI

// MARK: - 社区帖子卡片（已弃用，使用PostCardView代替）
struct CommunityPostCard: View {
    let post: Post
    let showHotBadge: Bool
    let showEditButton: Bool
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onNavigateToDetail: (String) -> Void
    let onNavigateToUserProfile: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 用户信息栏
            userInfoHeader
            
            // 帖子内容
            postContent
            
            // 互动按钮栏
            interactionBar
        }
        .padding(16)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
        .onTapGesture {
            onNavigateToDetail(post.id)
        }
    }
    
    // MARK: - 用户信息栏
    private var userInfoHeader: some View {
        HStack(spacing: 12) {
            // 用户头像
            Button(action: {
                onNavigateToUserProfile(String(post.authorId))
            }) {
                Image(systemName: post.author.avatar ?? "person.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    // 用户名
                    Text(post.author.nickname)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    // 热门标识
                    if showHotBadge {
                        Text("热门")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    // 编辑按钮
                    if showEditButton {
                        Button(action: {
                            // 编辑帖子
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 发布时间
                Text(post.timeAgo)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - 帖子内容
    private var postContent: some View {
        Text(post.content)
            .font(.system(size: 15))
            .foregroundColor(.primary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
    
    // MARK: - 互动按钮栏
    private var interactionBar: some View {
        HStack(spacing: 24) {
            // 点赞按钮
            Button(action: onLike) {
                HStack(spacing: 4) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(post.isLiked ? .red : .secondary)
                    
                    if post.likesCount > 0 {
                        Text("\(post.likesCount)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 评论按钮
            Button(action: {
                onNavigateToDetail(post.id)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    if post.commentsCount > 0 {
                        Text("\(post.commentsCount)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 收藏按钮
            Button(action: onBookmark) {
                Image(systemName: post.isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16))
                    .foregroundColor(post.isBookmarked ? .blue : .secondary)
            }
        }
    }
}

// MARK: - 预览
#Preview {
    Text("此组件已弃用，请使用PostCardView")
        .foregroundColor(.secondary)
        .padding()
}
