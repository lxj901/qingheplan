import SwiftUI

// MARK: - 加载视图
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppConstants.Colors.primaryGreen)
            
            Text("加载中...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - 错误视图
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("加载失败")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onRetry) {
                Text("重试")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 44)
                    .background(AppConstants.Colors.primaryGreen)
                    .cornerRadius(22)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - 加载更多视图
struct LoadingMoreView: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(AppConstants.Colors.primaryGreen)
            
            Text("加载更多...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// StatView 已在 UserProfileManager.swift 中定义，这里不重复定义

// MARK: - 用户头像视图
struct UserAvatarView: View {
    let avatarURL: String?
    let size: CGFloat
    let showBorder: Bool
    
    init(avatarURL: String?, size: CGFloat = 40, showBorder: Bool = false) {
        self.avatarURL = avatarURL
        self.size = size
        self.showBorder = showBorder
    }
    
    var body: some View {
        AsyncImage(url: URL(string: avatarURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(.white)
                )
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            showBorder ? 
            Circle().stroke(Color.white, lineWidth: 3) : 
            nil
        )
    }
}

// MARK: - 认证徽章视图
struct VerificationBadgeView: View {
    let isVerified: Bool
    let size: CGFloat
    
    init(isVerified: Bool, size: CGFloat = 16) {
        self.isVerified = isVerified
        self.size = size
    }
    
    var body: some View {
        if isVerified {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: size))
                .foregroundColor(.blue)
        }
    }
}

// MARK: - 关注按钮视图
struct FollowButtonView: View {
    let isFollowing: Bool
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(isFollowing ? .primary : .white)
                }
                
                Text(isFollowing ? "正在关注" : "关注")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(width: 100, height: 36)
            .background(
                isFollowing ? 
                Color.clear : 
                AppConstants.Colors.primaryGreen
            )
            .foregroundColor(
                isFollowing ? 
                .primary : 
                .white
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isFollowing ? 
                        Color.gray.opacity(0.3) : 
                        Color.clear,
                        lineWidth: 1
                    )
            )
            .cornerRadius(18)
        }
        .disabled(isLoading)
    }
}

// MARK: - 用户等级视图
struct UserLevelView: View {
    let level: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundColor(.orange)
            
            Text("Lv.\(level)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - 元信息行视图
struct MetaInfoRowView: View {
    let icon: String
    let text: String
    let isLink: Bool
    
    init(icon: String, text: String, isLink: Bool = false) {
        self.icon = icon
        self.text = text
        self.isLink = isLink
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(isLink ? .blue : .secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - 分割线视图
struct DividerView: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 0.5)
    }
}

// MARK: - 渐变背景视图
struct GradientBackgroundView: View {
    let colors: [Color]
    
    init(colors: [Color] = [AppConstants.Colors.primaryGreen.opacity(0.3), AppConstants.Colors.primaryGreen.opacity(0.1)]) {
        self.colors = colors
    }
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
