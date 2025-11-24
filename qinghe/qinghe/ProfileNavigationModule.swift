import SwiftUI

// MARK: - 用户资料导航栏模块
struct ProfileNavigationModule: View {
    let userProfile: UserProfile?
    let scrollOffset: CGFloat
    let showNavTitle: Bool
    let onBackTapped: () -> Void
    let onMoreTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 状态栏占位
            Rectangle()
                .fill(Color.clear)
                .frame(height: UIApplication.shared.statusBarHeight)
            
            // 导航栏内容
            navigationBarContent
        }
        .background(navigationBarBackground)
    }
    
    // MARK: - 导航栏内容
    private var navigationBarContent: some View {
        HStack(spacing: 16) {
            // 返回按钮
            backButton
            
            // 标题区域
            titleSection
            
            Spacer()
            
            // 更多按钮
            moreButton
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }
    
    // MARK: - 返回按钮
    private var backButton: some View {
        Button(action: onBackTapped) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .opacity(calculateButtonBackgroundOpacity())
                )
        }
        .opacity(calculateButtonOpacity())
        .animation(.easeInOut(duration: 0.25), value: calculateButtonOpacity())
    }
    
    // MARK: - 标题区域
    private var titleSection: some View {
        VStack(spacing: 2) {
            if showNavTitle, let userProfile = userProfile {
                Text(userProfile.nickname)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if userProfile.safePostsCount > 0 {
                    Text("\(userProfile.safePostsCount) 帖子")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .opacity(showNavTitle ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.25), value: showNavTitle)
    }
    
    // MARK: - 更多按钮
    private var moreButton: some View {
        Button(action: onMoreTapped) {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .opacity(calculateButtonBackgroundOpacity())
                )
        }
        .opacity(calculateButtonOpacity())
        .animation(.easeInOut(duration: 0.25), value: calculateButtonOpacity())
    }
    
    // MARK: - 导航栏背景
    private var navigationBarBackground: some View {
        Rectangle()
            .fill(Color(.systemBackground))
            .opacity(calculateNavBarBackgroundOpacity())
            .background(
                // 毛玻璃效果
                VisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
                    .opacity(calculateBlurOpacity())
            )
            .animation(.easeInOut(duration: 0.25), value: calculateNavBarBackgroundOpacity())
            .animation(.easeInOut(duration: 0.25), value: calculateBlurOpacity())
    }
    
    // MARK: - 计算导航栏背景透明度
    private func calculateNavBarBackgroundOpacity() -> Double {
        if scrollOffset > -50 {
            return 0.0
        } else if scrollOffset < -100 {
            return 0.95
        } else {
            // 在 -50 到 -100 之间线性插值
            let progress = abs(scrollOffset + 50) / 50
            return progress * 0.95
        }
    }
    
    // MARK: - 计算毛玻璃透明度
    private func calculateBlurOpacity() -> Double {
        if scrollOffset > -30 {
            return 0.0
        } else if scrollOffset < -80 {
            return 1.0
        } else {
            // 在 -30 到 -80 之间线性插值
            let progress = abs(scrollOffset + 30) / 50
            return progress
        }
    }
    
    // MARK: - 计算按钮透明度
    private func calculateButtonOpacity() -> Double {
        if scrollOffset > -20 {
            return 1.0
        } else if scrollOffset < -60 {
            return 1.0
        } else {
            return 1.0 // 按钮始终保持可见
        }
    }
    
    // MARK: - 计算按钮背景透明度
    private func calculateButtonBackgroundOpacity() -> Double {
        if scrollOffset > -30 {
            return 0.8
        } else if scrollOffset < -80 {
            return 0.2
        } else {
            // 在 -30 到 -80 之间线性插值
            let progress = abs(scrollOffset + 30) / 50
            return 0.8 - (progress * 0.6)
        }
    }
}

// MARK: - 毛玻璃效果视图（已在其他文件中定义，这里注释掉避免重复）
// struct VisualEffectView: UIViewRepresentable {
//     let effect: UIVisualEffect
//
//     func makeUIView(context: Context) -> UIVisualEffectView {
//         return UIVisualEffectView(effect: effect)
//     }
//
//     func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
//         uiView.effect = effect
//     }
// }

// MARK: - UIApplication 扩展
extension UIApplication {
    var statusBarHeight: CGFloat {
        if let windowScene = connectedScenes.first as? UIWindowScene,
           let statusBarManager = windowScene.statusBarManager {
            return statusBarManager.statusBarFrame.height
        }
        return 0
    }
}

// MARK: - 预览
struct ProfileNavigationModule_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ProfileNavigationModule(
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
                scrollOffset: -100,
                showNavTitle: true,
                onBackTapped: {},
                onMoreTapped: {}
            )
            
            Spacer()
        }
        .previewLayout(.sizeThatFits)
    }
}
