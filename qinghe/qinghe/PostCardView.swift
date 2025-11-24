import SwiftUI

// MARK: - 帖子卡片视图
struct PostCardView: View {
    let post: Post
    let showHotBadge: Bool
    let showEditButton: Bool
    let onLike: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    let onReport: () -> Void
    let onNavigateToDetail: (String) -> Void
    let onNavigateToUserProfile: (Author) -> Void

    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingActionSheet = false
    @State private var lastTapTime: Date = Date.distantPast // 防止重复点击

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 用户信息栏
            userInfoHeader
                .padding(.leading, 16) // 只设置左边距，确保头像在最左
                .padding(.trailing, 16)
                .padding(.top, 16)

            // 帖子内容 - 与头像对齐
            if !post.content.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    postContent

                    // AI生成标识
                    if post.isAIGenerated == true {
                        aiGeneratedBadge
                    }
                }
                .padding(.leading, 16) // 与头像左边缘对齐
                .padding(.trailing, 16)
                .padding(.top, 16)
            }

            // 图片内容 - 与头像对齐
            if let images = post.images, !images.isEmpty {
                imageContent
                    .padding(.leading, 16) // 与头像左边缘对齐
                    .padding(.trailing, 16)
                    .padding(.top, 16)
            }

            // 视频内容 - 全宽无边距无圆角
            if let video = post.video {
                videoContent(video)
                    .padding(.top, 16)
            }

            // 位置信息 - 与头像对齐
            if let location = post.location {
                locationInfo
                    .padding(.leading, 16) // 与头像左边缘对齐
                    .padding(.trailing, 16)
                    .padding(.top, 16)
            }

            // 标签 - 与头像对齐
            if let tags = post.tags, !tags.isEmpty {
                tagsView(tags)
                    .padding(.leading, 16) // 与头像左边缘对齐
                    .padding(.trailing, 16)
                    .padding(.top, 16)
            }

            // 打卡数据显示 - 与头像对齐
            if let checkin = post.checkin {
                checkinDataView(checkin)
                    .padding(.leading, 16) // 与头像左边缘对齐
                    .padding(.trailing, 16)
                    .padding(.top, 16)
            }

            // 运动数据显示 - 与头像对齐
            if let workout = post.workout {
                workoutDataView(workout)
                    .padding(.leading, 16) // 与头像左边缘对齐
                    .padding(.trailing, 16)
                    .padding(.top, 16)
            }

            // 互动栏 - 与用户信息栏对齐
            interactionBar
                .padding(.leading, 16) // 与用户信息栏保持相同的左边距
                .padding(.trailing, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture {
            let now = Date()
            guard now.timeIntervalSince(lastTapTime) > 0.5 else {
                print("🔍 PostCardView: 重复点击被忽略，帖子ID: \(post.id)")
                return
            }
            
            lastTapTime = now
            print("🔍 PostCardView: 帖子点击，帖子ID: \(post.id)")
            
            // 添加触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            onNavigateToDetail(post.id)
        }
        .confirmationDialog(localizationManager.localizedString(key: "select_action"), isPresented: $showingActionSheet) {
            if !showEditButton {
                Button(localizationManager.localizedString(key: "report"), role: .destructive) {
                    print("⚠️ PostCardView: 点击举报按钮，帖子ID: \(post.id)")
                    onReport()
                }
            }

            Button(localizationManager.localizedString(key: "cancel"), role: .cancel) { }
        }
    }

    // MARK: - 计算属性

    // 处理头像URL，过滤空字符串
    private var avatarURL: URL? {
        guard let avatar = post.author.avatar,
              !avatar.isEmpty,
              !avatar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return URL(string: avatar)
    }

    // 获取用户名首字母
    private var userInitial: String {
        let nickname = post.author.nickname
        if let firstChar = nickname.first {
            return String(firstChar).uppercased()
        }
        return "U"
    }

    // 头像占位符（显示首字母）
    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))

            Text(userInitial)
                .font(.system(size: 20, weight: .semibold)) // 调整字体大小以匹配48pt头像
                .foregroundColor(.green)
        }
    }

    // MARK: - 子视图

    // 用户信息头部
    private var userInfoHeader: some View {
        HStack(alignment: .top, spacing: 12) { // 确保顶部对齐
            // 用户头像 - 确保在最左边
            Button(action: {
                onNavigateToUserProfile(post.author)
            }) {
                AvatarWithMemberBadge(
                    avatarUrl: post.author.avatar,
                    isMember: post.author.isMember ?? false,
                    size: 48,
                    cornerRadius: 24  // 圆形头像
                )
            }

            // 用户名和时间信息 - 确保左对齐
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) { // 减少间距让元素更紧凑
                    Button(action: {
                        onNavigateToUserProfile(post.author)
                    }) {
                        Text(post.author.nickname)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 认证标识
                    if post.author.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }

                    // 热门标识
                    if showHotBadge {
                        Text(localizationManager.localizedString(key: "hot"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }

                }

                Text(post.formattedDateTime)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer() // 推送更多按钮到最右边

            // 更多操作按钮
            Button(action: {
                showingActionSheet = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }

    // 帖子内容
    private var postContent: some View {
        Text(truncatedContent)
            .font(.system(size: 16, weight: .regular)) // 调整字体大小与详情页一致
            .foregroundColor(.primary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }

    // AI生成标识
    private var aiGeneratedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "info.circle")
                .font(.system(size: 11))
            Text(localizationManager.localizedString(key: "ai_generated_content"))
                .font(.system(size: 12))
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }

    // 截取内容到200字
    private var truncatedContent: String {
        if post.content.count <= 200 {
            return post.content
        } else {
            // 安全地计算索引，避免越界
            guard let index = post.content.index(post.content.startIndex, offsetBy: 200, limitedBy: post.content.endIndex) else {
                return post.content
            }
            return String(post.content[..<index]) + "..."
        }
    }

    // 图片内容
    private var imageContent: some View {
        TwitterStyleImageGrid(
            images: post.images ?? [],
            onImageTap: { index in
                // 点击图片时导航到详情页
                onNavigateToDetail(post.id)
            }
        )
    }

    // 视频内容
    private func videoContent(_ videoURL: String) -> some View {
        VideoThumbnailView(
            videoURL: videoURL,
            duration: nil, // 可以从后端获取视频时长
            isFullWidth: true, // 全宽显示
            showControls: false, // 列表模式：无控制
            onTap: {
                // 点击视频跳转到详情页，而不是打开全屏播放器
                onNavigateToDetail(post.id)
            }
        )
    }

    // 位置信息
    private var locationInfo: some View {
        HStack(spacing: 4) {
            Image(systemName: "location")
                .font(.system(size: 12))
                .foregroundColor(.green)

            Text(post.location!)
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    // 数据展示栏（均分布局）
    private var interactionBar: some View {
        HStack(spacing: 0) {
            // 点赞数量显示
            Button(action: onLike) {
                HStack(spacing: 4) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(post.isLiked ? .red : .secondary)
                        .font(.system(size: 14))

                    Text("\(post.likesCount)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PlainButtonStyle())

            // 评论数量显示
            Button(action: {
                onNavigateToDetail(post.id)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))

                    Text("\(post.commentsCount)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PlainButtonStyle())

            // 收藏数量显示
            Button(action: onBookmark) {
                HStack(spacing: 4) {
                    Image(systemName: post.isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(post.isBookmarked ? .green : .secondary)
                        .font(.system(size: 14))

                    Text("\(post.bookmarksCount)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PlainButtonStyle())

            // 浏览数量显示
            HStack(spacing: 4) {
                Image(systemName: "eye")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))

                Text("\(post.viewsCount)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
    }
}

// MARK: - 预览
#Preview {
    // 创建一个简化的示例帖子用于预览
    let samplePost = Post(
        id: "1",
        authorId: 1,
        content: "今天坚持了120分钟的学习，感觉很充实！",
        images: ["https://example.com/image1.jpg"],
        tags: ["学习", "坚持"],
        category: "life",
        location: "北京市朝阳区",
        likesCount: 15,
        commentsCount: 3,
        sharesCount: 2,
        bookmarksCount: 5,
        viewsCount: 100,
        isLiked: false,
        isBookmarked: false,
        allowComments: true,
        allowShares: true,
        visibility: .public,
        status: .active,
        isTop: false,
        hotScore: 85.0,
        lastActiveAt: "2024-01-01T12:00:00Z",
        createdAt: "2024-01-01T10:00:00Z",
        updatedAt: "2024-01-01T10:00:00Z",
        author: Author(
            id: 1,
            nickname: "青禾用户",
            avatar: "https://example.com/avatar.jpg",
            isVerified: true,
            level: 5,
            followersCount: 1200
        )
    )
    
    PostCardView(
        post: samplePost,
        showHotBadge: true,
        showEditButton: false,
        onLike: {},
        onBookmark: {},
        onShare: {},
        onReport: {},
        onNavigateToDetail: { _ in },
        onNavigateToUserProfile: { _ in }
    )
    .padding()
}

// MARK: - PostCardView 扩展
extension PostCardView {
    // MARK: - 标签视图
    private func tagsView(_ tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Button(action: {
                        navigateToTagSearch(tag)
                    }) {
                        // 如果标签不以#开头，添加#号显示
                        Text(tag.hasPrefix("#") ? tag : "#\(tag)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppConstants.Colors.primaryGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppConstants.Colors.primaryGreen.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 0)
        }
    }

    /// 导航到标签搜索
    private func navigateToTagSearch(_ tagName: String) {
        // 统一标签格式：如果不以#开头，添加#号
        let searchTag = tagName.hasPrefix("#") ? tagName : "#\(tagName)"
        print("🏷️ 点击标签: \(searchTag)")

        // 发送通知，让主视图处理标签搜索导航
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToTagSearch"),
            object: nil,
            userInfo: ["tagName": searchTag]
        )
    }

    // MARK: - 打卡数据视图
    private func checkinDataView(_ checkin: CheckinData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)

                Text(localizationManager.localizedString(key: "checkin_record"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(localizationManager.localizedString(key: "time") + ":")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)

                    Text("\(checkin.date) \(checkin.time)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()
                }

                if let address = checkin.locationAddress, !address.isEmpty {
                    HStack {
                        Text(localizationManager.localizedString(key: "location") + ":")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        Text(address)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()
                    }
                }

                if let note = checkin.note, !note.isEmpty {
                    let formattedNote = formatCheckinNote(note)
                    if !formattedNote.isEmpty {
                        HStack(alignment: .top) {
                            Text(localizationManager.localizedString(key: "note") + ":")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .leading)

                            Text(formattedNote)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .lineLimit(2)

                            Spacer()
                        }
                    }
                }

                // 连续打卡天数显示
                if let consecutiveDays = checkin.consecutiveDays, consecutiveDays > 0 {
                    HStack {
                        Text(localizationManager.localizedString(key: "consecutive") + ":")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)

                            Text(String(format: localizationManager.localizedString(key: "consecutive_days"), consecutiveDays))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.orange)
                        }

                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.green.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 运动数据视图
    private func workoutDataView(_ workout: PostWorkoutData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)

                Text(localizationManager.localizedString(key: "workout_record"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(localizationManager.localizedString(key: "type") + ":")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)

                    Text(getWorkoutTypeChinese(workout.workoutType))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()
                }

                HStack {
                    Text(localizationManager.localizedString(key: "time") + ":")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)

                    Text(formatWorkoutTime(workout.startTime, workout.endTime))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()
                }

                HStack {
                    Text(localizationManager.localizedString(key: "duration") + ":")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)

                    Text(formatDuration(workout.duration))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()
                }

                // 距离
                if let distance = workout.totalDistance, !distance.isEmpty {
                    HStack {
                        Text(localizationManager.localizedString(key: "distance") + ":")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        Text(distance)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }

                // 卡路里
                if let calories = workout.calories {
                    HStack {
                        Text(localizationManager.localizedString(key: "calories") + ":")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        Text("\(calories)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }

                if let steps = workout.totalSteps {
                    HStack {
                        Text(localizationManager.localizedString(key: "steps") + ":")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        Text("\(steps)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.orange.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 格式化运动时长
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%d小时%d分钟", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d分钟%d秒", minutes, remainingSeconds)
        } else {
            return String(format: "%d秒", remainingSeconds)
        }
    }

    // MARK: - 格式化打卡备注
    private func formatCheckinNote(_ note: String) -> String {
        // 检查是否包含连续天数信息的模式
        if note.contains("连续") && note.contains("天") {
            return note
        }

        // 检查是否包含"第X天"的模式
        if note.contains("第") && note.contains("天") {
            return note
        }

        // 检查是否包含数字+天的模式（如"15天"）
        let dayPattern = #"\d+天"#
        if note.range(of: dayPattern, options: .regularExpression) != nil {
            return note
        }

        // 如果备注是"iOS应用打卡"或类似的系统默认备注，不显示
        if note == "iOS应用打卡" || note.isEmpty {
            return ""
        }

        // 其他情况直接返回原备注
        return note
    }

    // MARK: - 运动类型中文映射
    private func getWorkoutTypeChinese(_ workoutType: String) -> String {
        switch workoutType.lowercased() {
        case "running", "run":
            return "跑步"
        case "walking", "walk":
            return "步行"
        case "cycling", "bike", "bicycle":
            return "骑行"
        case "swimming", "swim":
            return "游泳"
        case "hiking", "hike":
            return "徒步"
        case "yoga":
            return "瑜伽"
        case "fitness", "gym", "workout":
            return "健身"
        case "basketball":
            return "篮球"
        case "football", "soccer":
            return "足球"
        case "tennis":
            return "网球"
        case "badminton":
            return "羽毛球"
        case "pingpong", "tabletennis":
            return "乒乓球"
        case "climbing":
            return "攀岩"
        case "dancing", "dance":
            return "舞蹈"
        case "boxing":
            return "拳击"
        case "martial arts", "martialarts":
            return "武术"
        case "pilates":
            return "普拉提"
        case "aerobics":
            return "有氧运动"
        case "strength", "weightlifting":
            return "力量训练"
        case "cardio":
            return "有氧训练"
        default:
            return workoutType
        }
    }

    // MARK: - 格式化运动时间（统一到公共 Helper）
    private func formatWorkoutTime(_ startTime: String, _ endTime: String) -> String {
        let text = DateParsingHelper.formatTimeRange(
            startTime: startTime,
            endTime: endTime,
            sameDayMerge: true,
            dateFormat: "yyyy-MM-dd",
            timeFormat: "HH:mm"
        )
        return text.isEmpty ? "运动时间" : text
    }

    // MARK: - 从字符串中提取时间
    private func extractTimeFromString(_ timeString: String) -> String {
        // 尝试匹配 HH:mm:ss 或 HH:mm 格式
        let timePattern = #"\d{1,2}:\d{2}(:\d{2})?"#
        if let range = timeString.range(of: timePattern, options: .regularExpression) {
            let timeStr = String(timeString[range])
            // 如果包含秒，去掉秒部分
            if timeStr.count > 5 {
                return String(timeStr.prefix(5))
            }
            return timeStr
        }

        // 如果没有找到时间格式，返回空字符串
        return ""
    }
}
