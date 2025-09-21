import SwiftUI

/// 分享弹窗
struct ShareSheet: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("分享帖子")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        AsyncImage(url: URL(string: post.author.avatar ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.author.nickname)
                                .font(.headline)
                            Text(post.timeAgo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Text(post.content)
                        .font(.body)
                        .lineLimit(3)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                VStack(spacing: 16) {
                    ShareButton(
                        icon: "square.and.arrow.up",
                        title: "系统分享",
                        action: {
                            shareToSystem()
                        }
                    )
                    
                    ShareButton(
                        icon: "doc.on.doc",
                        title: "复制链接",
                        action: {
                            copyLink()
                        }
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func shareToSystem() {
        let shareText = "\(post.author.nickname): \(post.content)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        
        dismiss()
    }
    
    private func copyLink() {
        let shareText = "\(post.author.nickname): \(post.content)"
        UIPasteboard.general.string = shareText
        dismiss()
    }
}

struct ShareButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.body)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    // 创建一个简化的示例帖子用于预览
    let samplePost = Post(
        id: "1",
        authorId: 1,
        content: "这是一个测试帖子",
        images: [String]?.none,
        video: String?.none,
        tags: [String]?.none,
        category: "life",
        location: String?.none,
        latitude: String?.none,
        longitude: String?.none,
        checkinId: Int?.none,
        workoutId: Int?.none,
        dataType: String?.none,
        likesCount: 10,
        commentsCount: 5,
        sharesCount: 2,
        bookmarksCount: 3,
        viewsCount: 100,
        isLiked: false,
        isBookmarked: false,
        allowComments: true,
        allowShares: true,
        visibility: .public,
        status: .active,
        isTop: false,
        hotScore: 0.5,
        lastActiveAt: "2024-01-01T00:00:00Z",
        createdAt: "2024-01-01T00:00:00Z",
        updatedAt: "2024-01-01T00:00:00Z",
        author: Author(
            id: 1, 
            nickname: "测试用户", 
            avatar: String?.none, 
            isVerified: false, 
            level: 1, 
            followersCount: 100
        ),
        checkin: CheckinData?.none,
        workout: PostWorkoutData?.none
    )
    
    ShareSheet(post: samplePost)
}
