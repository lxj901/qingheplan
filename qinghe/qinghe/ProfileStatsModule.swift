import SwiftUI

// MARK: - 用户统计数据模块
struct ProfileStatsModule: View {
    let userProfile: UserProfile
    @Binding var showFollowersList: Bool
    @Binding var showFollowingList: Bool
    let scrollOffset: CGFloat
    
    var body: some View {
        HStack(spacing: 24) {
            // 帖子统计
            StatItemView(
                title: "帖子",
                count: userProfile.safePostsCount,
                action: nil
            )
            
            // 关注统计
            StatItemView(
                title: "关注",
                count: userProfile.safeFollowingCount,
                action: {
                    showFollowingList = true
                }
            )
            
            // 粉丝统计
            StatItemView(
                title: "粉丝",
                count: userProfile.safeFollowersCount,
                action: {
                    showFollowersList = true
                }
            )
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .opacity(calculateStatsOpacity())
        .scaleEffect(calculateStatsScale())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: calculateStatsOpacity())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: calculateStatsScale())
    }
    
    // MARK: - 计算统计数据透明度
    private func calculateStatsOpacity() -> Double {
        if scrollOffset > -100 {
            return 1.0
        } else if scrollOffset < -200 {
            return 0.2
        } else {
            // 在 -100 到 -200 之间线性插值
            let progress = (scrollOffset + 200) / 100
            return 0.2 + (progress * 0.8)
        }
    }
    
    // MARK: - 计算统计数据缩放比例
    private func calculateStatsScale() -> CGFloat {
        if scrollOffset > -50 {
            return 1.0
        } else if scrollOffset < -150 {
            return 0.9
        } else {
            // 在 -50 到 -150 之间线性插值
            let progress = (scrollOffset + 150) / 100
            return 0.9 + (progress * 0.1)
        }
    }
}

// MARK: - 统计项视图
struct StatItemView: View {
    let title: String
    let count: Int
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

// MARK: - 预览
struct ProfileStatsModule_Previews: PreviewProvider {
    @State static var showFollowersList = false
    @State static var showFollowingList = false
    
    static var previews: some View {
        ProfileStatsModule(
            userProfile: UserProfile(
                id: 1,
                nickname: "测试用户",
                avatar: nil,
                backgroundImage: nil,
                bio: "这是一个测试用户",
                location: "北京",
                gender: "男",
                birthday: "1990-01-01",
                constellation: "摩羯座",
                hometown: "北京",
                school: "某某大学",
                ipLocation: "北京市朝阳区",
                qingheId: "qinghe123456",
                level: 1,
                isVerified: true,
                followersCount: 1234,
                followingCount: 567,
                postsCount: 89,
                createdAt: "2024-01-01T00:00:00.000Z",
                lastActiveAt: "2024-01-01T00:00:00.000Z",
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false,
                isMe: false
            ),
            showFollowersList: $showFollowersList,
            showFollowingList: $showFollowingList,
            scrollOffset: 0
        )
        .previewLayout(.sizeThatFits)
    }
}
