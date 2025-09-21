import SwiftUI

// MARK: - 用户信息模块
struct ProfileInfoModule: View {
    let userProfile: UserProfile
    @ObservedObject var viewModel: UserProfileViewModel
    let scrollOffset: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 用户名和操作按钮行
            userNameAndActionsRow

            // 个人简介
            if let bio = userProfile.bio, !bio.isEmpty {
                bioSection(bio)
            }

            // 位置、链接和加入时间信息
            metadataSection

            // 关注数据
            followStatsSection
        }
        .padding(.horizontal, 16)
        .padding(.top, 40) // 为头像留出空间
        .background(Color(.systemBackground))
        .opacity(calculateInfoOpacity())
        .animation(.easeInOut(duration: 0.3), value: calculateInfoOpacity())
    }
    
    // MARK: - 用户名和操作按钮行
    private var userNameAndActionsRow: some View {
        HStack(alignment: .center) {
            // 用户名和认证信息
            userNameSection
            
            Spacer()
            
            // 操作按钮
            actionButtonsView
        }
    }
    
    // MARK: - 用户名区域
    private var userNameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(userProfile.nickname)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if userProfile.safeIsVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
            }

            Text("@user\(userProfile.id)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - 操作按钮视图
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            if !userProfile.safeIsMe {
                // 关注/取消关注按钮
                followButton
                
                // 消息按钮
                messageButton
            } else {
                // 编辑资料按钮
                editProfileButton
            }
        }
    }
    
    // MARK: - 关注按钮
    private var followButton: some View {
        Button(action: {
            Task {
                if userProfile.safeIsFollowing {
                    await viewModel.unfollowUser()
                } else {
                    await viewModel.followUser()
                }
            }
        }) {
            HStack(spacing: 4) {
                if viewModel.isFollowActionLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Text(userProfile.safeIsFollowing ? "已关注" : "关注")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(userProfile.safeIsFollowing ? .primary : .white)
            .frame(width: 80, height: 32)
            .background(
                userProfile.safeIsFollowing ? 
                Color(.systemGray5) : 
                AppConstants.Colors.primaryGreen
            )
            .cornerRadius(16)
        }
        .disabled(viewModel.isFollowActionLoading)
    }
    
    // MARK: - 消息按钮
    private var messageButton: some View {
        Button(action: {
            // TODO: 实现消息功能
        }) {
            Image(systemName: "message")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
                .background(Color(.systemGray5))
                .cornerRadius(16)
        }
    }
    
    // MARK: - 编辑资料按钮
    private var editProfileButton: some View {
        Button(action: {
            // TODO: 实现编辑资料功能
        }) {
            Text("编辑资料")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 80, height: 32)
                .background(Color(.systemGray5))
                .cornerRadius(16)
        }
    }
    
    // MARK: - 个人简介区域
    private func bioSection(_ bio: String) -> some View {
        Text(bio)
            .font(.subheadline)
            .foregroundColor(.primary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
    
    // MARK: - 元数据区域（位置、链接和加入时间）
    private var metadataSection: some View {
        HStack(spacing: 12) {
            // 位置信息
            if let location = userProfile.location, !location.isEmpty {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // 示例链接（可以根据实际需求添加到UserProfile模型中）
            Label("example.com", systemImage: "link")
                .font(.caption)
                .foregroundColor(.gray)

            // 加入时间
            Label(formatJoinDateShort(userProfile.createdAt), systemImage: "calendar")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    // MARK: - 关注统计区域
    private var followStatsSection: some View {
        HStack(spacing: 16) {
            Text("\(userProfile.safeFollowingCount) Following")
                .font(.subheadline)
                .fontWeight(.bold)

            Text("\(userProfile.safeFollowersCount) Followers")
                .font(.subheadline)
                .fontWeight(.bold)
        }
    }
    
    // MARK: - 计算信息透明度
    private func calculateInfoOpacity() -> Double {
        // 根据滚动偏移调整透明度，创建淡入淡出效果
        if scrollOffset > -50 {
            return 1.0
        } else if scrollOffset < -150 {
            return 0.3
        } else {
            // 在 -50 到 -150 之间线性插值
            let progress = (scrollOffset + 150) / 100
            return 0.3 + (progress * 0.7)
        }
    }

    // MARK: - 格式化加入时间
    private func formatJoinDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "加入时间未知" }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年M月"
            return "加入时间 \(displayFormatter.string(from: date))"
        }

        return "加入时间未知"
    }

    // MARK: - 格式化加入时间（简短版本）
    private func formatJoinDateShort(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "Joined" }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM yyyy"
            displayFormatter.locale = Locale(identifier: "en_US")
            return "Joined \(displayFormatter.string(from: date))"
        }

        return "Joined"
    }
}

// MARK: - 预览
struct ProfileInfoModule_Previews: PreviewProvider {
    static var previews: some View {
        ProfileInfoModule(
            userProfile: UserProfile(
                id: 1,
                nickname: "测试用户",
                avatar: nil,
                backgroundImage: nil,
                bio: "这是一个测试用户的个人简介，可能会很长，用来测试多行文本的显示效果。",
                location: "北京市",
                gender: "男",
                birthday: "1990-01-01",
                constellation: "摩羯座",
                hometown: "北京市",
                school: "某某大学",
                ipLocation: "北京市朝阳区",
                qingheId: "qinghe123456",
                level: 1,
                isVerified: true,
                followersCount: 100,
                followingCount: 50,
                postsCount: 25,
                createdAt: "2024-01-01T00:00:00.000Z",
                lastActiveAt: "2024-01-01T00:00:00.000Z",
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false,
                isMe: false
            ),
            viewModel: UserProfileViewModel(),
            scrollOffset: 0
        )
        .previewLayout(.sizeThatFits)
    }
}
