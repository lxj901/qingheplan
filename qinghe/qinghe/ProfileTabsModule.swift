import SwiftUI

// MARK: - 用户资料标签页模块
struct ProfileTabsModule: View {
    @Binding var selectedTab: ProfileTab
    let userProfile: UserProfile
    let scrollOffset: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            // 标签页导航
            tabNavigationView
            
            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
        }
        .background(Color(.systemBackground))
        .opacity(calculateTabsOpacity())
        .animation(.easeInOut(duration: 0.25), value: calculateTabsOpacity())
    }
    
    // MARK: - 标签页导航视图
    private var tabNavigationView: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .frame(height: 44)
    }
    
    // MARK: - 标签页按钮
    private func tabButton(for tab: ProfileTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    // 标签页图标
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedTab == tab ? AppConstants.Colors.primaryGreen : .secondary)
                    
                    // 标签页标题
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedTab == tab ? AppConstants.Colors.primaryGreen : .secondary)
                    
                    // 显示数量
                    if let count = getTabCount(for: tab), count > 0 {
                        Text("(\(count))")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 底部指示器
                Rectangle()
                    .fill(selectedTab == tab ? AppConstants.Colors.primaryGreen : Color.clear)
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab == tab)
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 获取标签页数量
    private func getTabCount(for tab: ProfileTab) -> Int? {
        switch tab {
        case .posts:
            return userProfile.safePostsCount
        case .bookmarks:
            // 收藏数量通常不显示，返回 nil
            return nil
        }
    }
    
    // MARK: - 计算标签页透明度
    private func calculateTabsOpacity() -> Double {
        // 标签页在滚动时保持较高的可见性
        if scrollOffset > -200 {
            return 1.0
        } else if scrollOffset < -300 {
            return 0.8
        } else {
            // 在 -200 到 -300 之间线性插值
            let progress = (scrollOffset + 300) / 100
            return 0.8 + (progress * 0.2)
        }
    }
}

// MARK: - 固定标签页视图（用于导航栏下方）
struct StickyProfileTabsModule: View {
    @Binding var selectedTab: ProfileTab
    let userProfile: UserProfile
    let isVisible: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 标签页导航
            HStack(spacing: 0) {
                ForEach(ProfileTab.allCases, id: \.self) { tab in
                    stickyTabButton(for: tab)
                }
            }
            .frame(height: 44)
            .background(Color(.systemBackground))
            
            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.25), value: isVisible)
    }
    
    // MARK: - 固定标签页按钮
    private func stickyTabButton(for tab: ProfileTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedTab == tab ? AppConstants.Colors.primaryGreen : .secondary)
                    
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedTab == tab ? AppConstants.Colors.primaryGreen : .secondary)
                }
                
                // 底部指示器
                Rectangle()
                    .fill(selectedTab == tab ? AppConstants.Colors.primaryGreen : Color.clear)
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab == tab)
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 预览
struct ProfileTabsModule_Previews: PreviewProvider {
    @State static var selectedTab: ProfileTab = .posts
    
    static var previews: some View {
        VStack {
            ProfileTabsModule(
                selectedTab: $selectedTab,
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
                scrollOffset: 0
            )
            
            Divider()
            
            StickyProfileTabsModule(
                selectedTab: $selectedTab,
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
                isVisible: true
            )
        }
        .previewLayout(.sizeThatFits)
    }
}
