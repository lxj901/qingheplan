import Foundation
import SwiftUI

/// 用户资料管理器
class UserProfileManager: ObservableObject {
    @Published var selectedUserId: String?
    @Published var showingUserProfileFullScreen = false

    /// 显示用户资料页面（使用用户ID）
    func showUserProfile(userId: String) {
        self.selectedUserId = userId
        self.showingUserProfileFullScreen = true
    }

    /// 显示用户资料页面（使用User对象）
    func showUserProfile(_ user: User) {
        self.selectedUserId = String(user.id)
        self.showingUserProfileFullScreen = true
    }

    /// 隐藏用户资料页面
    func hideUserProfile() {
        self.showingUserProfileFullScreen = false
        self.selectedUserId = nil
    }
}

/// 现代化用户资料视图
struct ModernUserProfileView: View {
    let user: User
    @EnvironmentObject private var userProfileManager: UserProfileManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 自定义顶部栏
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Text(user.nickname)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    Button("完成") {
                        dismiss()
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(UIColor.separator)),
                    alignment: .bottom
                )

                ScrollView {
                    VStack(spacing: 20) {
                    // 用户头像和基本信息
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text(user.nickname)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if user.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text("@\(user.username)")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            if let bio = user.bio {
                                Text(bio)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // 统计信息
                    HStack(spacing: 40) {
                        StatView(title: "帖子", count: user.postsCount)
                        StatView(title: "关注", count: user.followingCount)
                        StatView(title: "粉丝", count: user.followersCount)
                    }
                    
                    // 操作按钮
                    HStack(spacing: 12) {
                        Button("关注") {
                            // 关注用户
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(AppConstants.Colors.primaryGreen)
                        .foregroundColor(.white)
                        .cornerRadius(22)
                        
                        Button("消息") {
                            // 发送消息
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(22)
                    }
                    .padding(.horizontal)
                    
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
        }
    }
}

struct StatView: View {
    let title: String
    let count: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ModernUserProfileView(user: User(
        id: 1,
        username: "testuser",
        nickname: "测试用户",
        avatar: nil,
        email: "test@example.com",
        phone: "13800138000",
        isVerified: true,
        level: 5,
        followersCount: 1000,
        followingCount: 500,
        postsCount: 100,
        bio: "这是一个测试用户的个人简介",
        location: "北京",
        website: "https://example.com",
        birthday: "1990-01-01",
        gender: "male",
        createdAt: "2024-01-01T00:00:00Z",
        updatedAt: "2024-01-01T00:00:00Z"
    ))
    .environmentObject(UserProfileManager())
}
