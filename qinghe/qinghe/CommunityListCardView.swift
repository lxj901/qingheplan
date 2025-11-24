import SwiftUI

// MARK: - 社区列表专用帖子卡片视图
struct CommunityListCardView: View {
    let post: Post
    let onNavigateToDetail: (String) -> Void
    let onNavigateToUserProfile: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 用户信息栏
            userInfoHeader

            // 帖子内容（限制200字）
            postContent

            // 图片内容
            if let images = post.images, !images.isEmpty {
                imageContent
            }

            // 位置信息
            if let location = post.location {
                locationInfo
            }

            // 打卡数据显示
            if let checkin = post.checkin {
                checkinDataView(checkin)
            }

            // 运动数据显示
            if let workout = post.workout {
                workoutDataView(workout)
            }

            // 数据展示栏（只显示数量，不可交互）
            dataDisplayBar
        }
        .padding(16)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
        .onTapGesture {
            onNavigateToDetail(post.id)
        }
    }

    // MARK: - 子视图

    // 用户信息头部
    private var userInfoHeader: some View {
        HStack(spacing: 12) {
            // 用户头像
            Button(action: {
                onNavigateToUserProfile(String(post.author.id))
            }) {
                AsyncImage(url: URL(string: post.author.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
                .frame(width: 40, height: 40)
                .background(Color.green.opacity(0.1))
                .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Button(action: {
                        onNavigateToUserProfile(String(post.author.id))
                    }) {
                        Text(post.author.nickname)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 认证标识
                    if post.author.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }

                // 发布时间（具体日期时间格式）
                Text(post.formattedDateTime)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // 帖子内容（限制200字）
    private var postContent: some View {
        Text(truncatedContent)
            .font(.system(size: 15))
            .foregroundColor(.primary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(post.images ?? [], id: \.self) { imageUrl in
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // 位置信息
    private var locationInfo: some View {
        HStack(spacing: 4) {
            Image(systemName: "location")
                .font(.system(size: 12))
                .foregroundColor(.green)

            Text(post.location ?? "")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }

    // 数据展示栏（只显示数量，不可交互）
    private var dataDisplayBar: some View {
        HStack(spacing: 24) {
            // 点赞数量显示
            HStack(spacing: 4) {
                Image(systemName: post.isLiked ? "heart.fill" : "heart")
                    .foregroundColor(post.isLiked ? .red : .secondary)
                    .font(.system(size: 16))

                if post.likesCount > 0 {
                    Text("\(post.likesCount)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            // 评论数量显示
            HStack(spacing: 4) {
                Image(systemName: "bubble.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))

                if post.commentsCount > 0 {
                    Text("\(post.commentsCount)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            // 收藏数量显示
            HStack(spacing: 4) {
                Image(systemName: post.isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(post.isBookmarked ? .green : .secondary)
                    .font(.system(size: 16))

                if post.bookmarksCount > 0 {
                    Text("\(post.bookmarksCount)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            // 浏览数量显示
            HStack(spacing: 4) {
                Image(systemName: "eye")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))

                if post.viewsCount > 0 {
                    Text("\(post.viewsCount)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }

    // 打卡数据视图
    private func checkinDataView(_ checkin: CheckinData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)

                Text("打卡记录")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("时间:")
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
                        Text("地点:")
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
                            Text("备注:")
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
                        Text("连续:")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)

                            Text("连续打卡 \(consecutiveDays) 天")
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

    // 运动数据视图
    private func workoutDataView(_ workout: PostWorkoutData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)

                Text("运动记录")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("类型:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)

                    Text(getWorkoutTypeChinese(workout.workoutType))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()
                }

                HStack {
                    Text("时间:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)

                    Text(formatWorkoutTime(workout.startTime, workout.endTime))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()
                }

                HStack {
                    Text("时长:")
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
                        Text("距离:")
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
                        Text("卡路里:")
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
                        Text("步数:")
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

    // 格式化运动时长
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
        createdAt: "2025-08-09T10:00:00Z",
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
    
    CommunityListCardView(
        post: samplePost,
        onNavigateToDetail: { _ in },
        onNavigateToUserProfile: { _ in }
    )
    .padding()
}
