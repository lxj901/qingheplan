import SwiftUI

// MARK: - 用户资料头部模块
struct ProfileHeaderModule: View {
    let userProfile: UserProfile
    let scrollOffset: CGFloat
    let onAvatarOffsetChange: (CGFloat) -> Void

    // 背景图上传相关状态
    @State private var showingBackgroundImagePicker = false
    @State private var isUploadingBackgroundImage = false

    var body: some View {
        VStack(spacing: 0) {
            // 新的横幅和头像区域
            modernHeaderView
        }
        .sheet(isPresented: $showingBackgroundImagePicker) {
            ImagePicker { image in
                uploadBackgroundImage(image)
            }
        }
        .onAppear {
            print("🎯 ProfileHeaderModule 已渲染")
            print("🔍 用户资料: \(userProfile.nickname ?? "未知用户")")
            print("🔍 背景图URL: \(userProfile.backgroundImage ?? "无背景图")")
            print("🔍 safeIsMe: \(userProfile.safeIsMe)")
        }
    }

    // MARK: - 现代化头部视图
    private var modernHeaderView: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景图区域
            backgroundImageView
                .frame(height: 150)

            // 头像位置
            profileAvatarView
                .offset(x: 16, y: 40)
        }
        .frame(height: 180)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: AvatarOffsetPreferenceKey.self,
                              value: geometry.frame(in: .named("scrollView")).minY)
            }
        )
        .onPreferenceChange(AvatarOffsetPreferenceKey.self) { value in
            onAvatarOffsetChange(value)
        }
    }

    // MARK: - 背景图视图
    private var backgroundImageView: some View {
        ZStack {
            // 默认渐变背景
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.7),
                            Color.purple.opacity(0.5),
                            Color.pink.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // 用户背景图片
            if let backgroundImageUrl = userProfile.backgroundImage,
               !backgroundImageUrl.isEmpty {
                AsyncImage(url: URL(string: backgroundImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } placeholder: {
                    // 显示加载中的占位符
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            VStack {
                                ProgressView()
                                    .tint(.white)
                                Text("加载背景图...")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    print("🖼️ 正在加载背景图: \(backgroundImageUrl)")
                }
            } else {
                // 调试信息：显示背景图状态
                Rectangle()
                    .fill(Color.clear)
                    .onAppear {
                        print("🔍 背景图状态检查:")
                        print("   - userProfile.backgroundImage: \(userProfile.backgroundImage ?? "nil")")
                        print("   - isEmpty: \(userProfile.backgroundImage?.isEmpty ?? true)")
                    }
            }

            // 上传状态覆盖层
            if isUploadingBackgroundImage {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("上传中...")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    )
            }

            // 相机图标按钮（仅当前用户可见）
            if userProfile.safeIsMe && !isUploadingBackgroundImage {
                VStack {
                    HStack {
                        Spacer()

                        // 相机按钮
                        Button(action: {
                            print("📸 相机按钮被点击")
                            print("🎯 显示相机按钮 - userProfile.safeIsMe: \(userProfile.safeIsMe), isUploadingBackgroundImage: \(isUploadingBackgroundImage)")
                            showingBackgroundImagePicker = true
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20, weight: .medium))
                                Text("更换背景")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.7))
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.1), value: isUploadingBackgroundImage)

                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - 头像视图
    private var profileAvatarView: some View {
        let avatarScale = calculateAvatarScale()
        
        return AsyncImage(url: URL(string: userProfile.avatar ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                )
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 3)
        )
        .scaleEffect(avatarScale)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: avatarScale)
    }
    
    // MARK: - 计算头像缩放比例
    private func calculateAvatarScale() -> CGFloat {
        let baseScale: CGFloat = 1.0
        let minScale: CGFloat = 0.8
        let maxScale: CGFloat = 1.1
        
        // 根据滚动偏移计算缩放
        if scrollOffset > 0 {
            // 向下拉时稍微放大
            let scale = baseScale + (scrollOffset / 500) * 0.1
            return min(scale, maxScale)
        } else if scrollOffset < -50 {
            // 向上滚动时缩小
            let scale = baseScale + (scrollOffset + 50) / 200 * 0.2
            return max(scale, minScale)
        }
        
        return baseScale
    }

    // MARK: - 背景图上传
    private func uploadBackgroundImage(_ image: UIImage) {
        Task {
            await MainActor.run {
                isUploadingBackgroundImage = true
            }

            do {
                // 1. 上传图片到服务器
                let uploadResponse = try await ChatAPIService.shared.uploadImage(image)
                print("✅ 背景图上传成功: \(uploadResponse.url)")

                // 2. 更新用户资料
                let updateResponse = try await CommunityAPIService.shared.updateUserProfile(
                    backgroundImage: uploadResponse.url
                )

                print("🔍 updateResponse.success: \(updateResponse.success)")
                print("🔍 updateResponse.message: \(updateResponse.message ?? "无消息")")

                if updateResponse.success {
                    print("✅ 背景图更新成功")

                    await MainActor.run {
                        // 注意：这里无法直接更新 userProfile，因为它是 let 常量
                        // 需要通过通知或其他方式让父视图更新数据
                        isUploadingBackgroundImage = false

                        // 发送通知让 UserProfileView 刷新数据
                        print("📡 发送背景图更新通知: \(uploadResponse.url)")
                        NotificationCenter.default.post(
                            name: NSNotification.Name("BackgroundImageUpdated"),
                            object: nil,
                            userInfo: ["backgroundImage": uploadResponse.url]
                        )
                        print("📡 通知已发送")
                    }
                } else {
                    print("❌ 背景图更新失败: \(updateResponse.message ?? "未知错误")")
                    await MainActor.run {
                        isUploadingBackgroundImage = false
                    }
                }

            } catch {
                print("❌ 背景图上传失败: \(error)")
                print("🔍 错误类型: \(type(of: error))")
                print("🔍 错误详情: \(error.localizedDescription)")

                await MainActor.run {
                    isUploadingBackgroundImage = false
                }
            }
        }
    }
}

// MARK: - 头像偏移量 PreferenceKey（已在 UserProfileView 中定义，这里注释掉避免重复）
// struct AvatarOffsetPreferenceKey: PreferenceKey {
//     static var defaultValue: CGFloat = 0
//     static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
//         value = nextValue()
//     }
// }

// MARK: - 预览
struct ProfileHeaderModule_Previews: PreviewProvider {
    static var previews: some View {
        ProfileHeaderModule(
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
            scrollOffset: 0,
            onAvatarOffsetChange: { _ in }
        )
        .previewLayout(.sizeThatFits)
    }
}
