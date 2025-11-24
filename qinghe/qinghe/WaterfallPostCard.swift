import SwiftUI

/// 瀑布流帖子卡片 - 类似小红书的卡片样式
struct WaterfallPostCard: View {
    let post: Post
    let onTap: () -> Void
    let onLike: () -> Void
    let onUserTap: () -> Void
    
    @State private var imageHeight: CGFloat = 200
    @State private var calculatedHeight: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 图片/视频区域
            imageSection

            // 内容区域
            contentSection
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
    }

    /// 计算图片/视频的显示高度（基于宽高比）
    private func calculateHeight(for width: CGFloat, aspectRatio: CGFloat) -> CGFloat {
        let height = width / aspectRatio
        // 限制最小和最大高度，避免过高或过矮
        let minHeight: CGFloat = 150
        let maxHeight: CGFloat = 400
        return min(max(height, minHeight), maxHeight)
    }
    
    // MARK: - 图片/视频区域
    private var imageSection: some View {
        Group {
            if let images = post.images, !images.isEmpty, let firstImage = images.first {
                // 有图片的帖子 - 使用 AsyncImage 自动适应宽高比
                AsyncImage(url: URL(string: firstImage)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(3/4, contentMode: .fit)
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(3/4, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .tint(.green)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .aspectRatio(contentMode: .fit)
                .cornerRadius(8, corners: [.topLeft, .topRight])
            } else if let videoUrl = post.video, !videoUrl.isEmpty {
                // 有视频的帖子 - 显示视频缩略图
                ZStack(alignment: .topTrailing) {
                    // 使用视频封面，自动适应宽高比
                    if let thumbnailUrl = getVideoThumbnailUrl(videoUrl) {
                        AsyncImage(url: URL(string: thumbnailUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(9/16, contentMode: .fit)
                                    .clipped()
                            case .failure(_):
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .aspectRatio(9/16, contentMode: .fit)
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .aspectRatio(9/16, contentMode: .fit)
                                    .overlay(
                                        ProgressView()
                                            .tint(.green)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(9/16, contentMode: .fit)
                    }

                    // 播放按钮 - 右上角小图标
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .padding(8)
                }
                .cornerRadius(8, corners: [.topLeft, .topRight])
            } else {
                // 纯文本帖子 - 不显示图片区域
                EmptyView()
            }
        }
    }
    
    // MARK: - 内容区域
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题/内容
            if !post.content.isEmpty {
                // 判断是否为纯文本卡片（无图片无视频）
                let isPureText = (post.images == nil || post.images?.isEmpty == true) &&
                                 (post.video == nil || post.video?.isEmpty == true)

                if isPureText {
                    // 纯文本卡片：最多显示30个字
                    Text(truncateText(post.content, maxLength: 30))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                } else {
                    // 有图片/视频的卡片：显示2行
                    Text(post.content)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // 用户信息和点赞
            HStack(spacing: 8) {
                // 用户头像
                Button(action: onUserTap) {
                    if let avatarUrl = post.author.avatar, !avatarUrl.isEmpty {
                        CachedAsyncImage(
                            url: URL(string: avatarUrl),
                            content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                            },
                            placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    )
                            },
                            showRetryButton: false  // ✅ 头像场景不显示重试按钮
                        )
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            )
                    }
                }
                
                // 用户名
                Button(action: onUserTap) {
                    Text(post.author.nickname)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 点赞按钮
                Button(action: {
                    // 添加触觉反馈
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onLike()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(post.isLiked ? .red : .secondary)
                        
                        if post.likesCount > 0 {
                            Text(formatCount(post.likesCount))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
    }
    
    // MARK: - 辅助方法

    /// 格式化数字显示
    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000.0)
        } else if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }

    /// 截断文本到指定长度
    private func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        let index = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[..<index]) + "..."
    }

    /// 获取视频缩略图URL
    /// 优先使用后端返回的 videoCover，如果没有则使用 videoThumbnails[0]
    private func getVideoThumbnailUrl(_ videoUrl: String) -> String? {
        // 优先使用 videoCover（视频封面）
        if let cover = post.videoCover, !cover.isEmpty {
            return cover
        }

        // 如果没有 videoCover，尝试使用 videoThumbnails 数组的第一个缩略图
        if let thumbnails = post.videoThumbnails, !thumbnails.isEmpty, let firstThumbnail = thumbnails.first {
            return firstThumbnail
        }

        // 如果都没有，返回 nil 显示占位符
        return nil
    }

    /// 从SwiftUI Image获取UIImage（用于计算尺寸）
    private func getUIImage(from image: Image) -> UIImage? {
        // 这是一个简化的实现，实际中可能需要更复杂的逻辑
        return nil
    }
}

// MARK: - 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(WaterfallRoundedCorner(radius: radius, corners: corners))
    }
}

struct WaterfallRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 预览
#Preview {
    let sampleAuthor = Author(
        id: 1,
        nickname: "测试用户",
        avatar: nil,
        isVerified: false,
        level: 1,
        followersCount: 100,
        isFollowing: false,
        isMember: false
    )

    let samplePost = Post(
        id: "1",
        authorId: 1,
        content: "这是一个测试帖子的标题，用来展示瀑布流卡片的效果",
        images: ["https://picsum.photos/400/600"],
        video: nil,
        tags: ["测试", "瀑布流"],
        category: "health",
        location: "北京市",
        latitude: nil,
        longitude: nil,
        checkinId: nil,
        workoutId: nil,
        dataType: nil,
        likesCount: 1234,
        commentsCount: 56,
        sharesCount: 12,
        bookmarksCount: 89,
        viewsCount: 5678,
        isLiked: false,
        isBookmarked: false,
        allowComments: true,
        allowShares: true,
        visibility: .public,
        status: .active,
        isTop: false,
        hotScore: 0.0,
        isAIGenerated: false,
        lastActiveAt: "2024-01-01T00:00:00Z",
        createdAt: "2024-01-01T00:00:00Z",
        updatedAt: "2024-01-01T00:00:00Z",
        author: sampleAuthor,
        checkin: nil,
        workout: nil,
        finalScore: nil,
        explanation: nil,
        strategy: nil
    )

    WaterfallPostCard(
        post: samplePost,
        onTap: {},
        onLike: {},
        onUserTap: {}
    )
    .frame(width: 180)
    .padding()
}

