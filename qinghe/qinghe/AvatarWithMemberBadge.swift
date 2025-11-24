import SwiftUI

/// 带会员标识的头像组件
/// 在头像右下角显示会员标识（仅会员用户显示）
struct AvatarWithMemberBadge: View {
    let avatarUrl: String?
    let isMember: Bool
    let size: CGFloat
    let cornerRadius: CGFloat?
    
    init(
        avatarUrl: String?,
        isMember: Bool = false,
        size: CGFloat = 48,
        cornerRadius: CGFloat? = nil
    ) {
        self.avatarUrl = avatarUrl
        self.isMember = isMember
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // 头像
            avatarView
            
            // 会员标识（仅会员显示）
            if isMember {
                memberBadge
            }
        }
    }
    
    // MARK: - 头像视图
    private var avatarView: some View {
        Group {
            if let avatarUrl = avatarUrl, !avatarUrl.isEmpty, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        defaultAvatar
                    case .empty:
                        defaultAvatar
                    @unknown default:
                        defaultAvatar
                    }
                }
            } else {
                defaultAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: actualCornerRadius))
    }
    
    // MARK: - 默认头像
    private var defaultAvatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: actualCornerRadius)
                .fill(Color.gray.opacity(0.3))
            
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - 会员标识
    private var memberBadge: some View {
        ZStack {
            // 背景圆形
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0),  // 金色
                            Color(red: 1.0, green: 0.71, blue: 0.0)   // 深金色
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: badgeSize, height: badgeSize)
            
            // 白色边框
            Circle()
                .stroke(Color.white, lineWidth: badgeBorderWidth)
                .frame(width: badgeSize, height: badgeSize)
            
            // VIP 图标
            Image(systemName: "crown.fill")
                .font(.system(size: badgeIconSize, weight: .bold))
                .foregroundColor(.white)
        }
        .offset(x: badgeOffset, y: badgeOffset)
    }
    
    // MARK: - 计算属性
    
    /// 实际圆角半径
    private var actualCornerRadius: CGFloat {
        cornerRadius ?? (size * 0.15)
    }
    
    /// 徽章大小（头像大小的 30%）
    private var badgeSize: CGFloat {
        size * 0.30
    }
    
    /// 徽章图标大小
    private var badgeIconSize: CGFloat {
        badgeSize * 0.55
    }
    
    /// 徽章边框宽度
    private var badgeBorderWidth: CGFloat {
        max(1.5, size * 0.03)
    }
    
    /// 徽章偏移量（使其部分超出头像边界）
    private var badgeOffset: CGFloat {
        badgeSize * 0.15
    }
}

// MARK: - 预览
struct AvatarWithMemberBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // 会员用户 - 大头像
            AvatarWithMemberBadge(
                avatarUrl: "https://example.com/avatar.jpg",
                isMember: true,
                size: 80
            )
            
            // 会员用户 - 中等头像
            AvatarWithMemberBadge(
                avatarUrl: nil,
                isMember: true,
                size: 48
            )
            
            // 非会员用户
            AvatarWithMemberBadge(
                avatarUrl: nil,
                isMember: false,
                size: 48
            )
            
            // 会员用户 - 小头像
            AvatarWithMemberBadge(
                avatarUrl: nil,
                isMember: true,
                size: 32
            )
            
            // 圆形头像（自定义圆角）
            AvatarWithMemberBadge(
                avatarUrl: nil,
                isMember: true,
                size: 60,
                cornerRadius: 30
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

