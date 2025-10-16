import SwiftUI

/// 支持多级嵌套的评论行组件
struct NestedCommentRowView: View {
    @Binding var comment: Comment
    let onLike: (String) -> Void // 传递评论ID
    let onReply: (Comment) -> Void // 传递评论对象
    let onToggleExpansion: (String) -> Void // 传递评论ID
    let onLoadReplies: (String) -> Void // 传递评论ID
    let onDelete: ((String) -> Void)? // 删除评论回调
    let level: Int // 嵌套层级，用于缩进

    private let indentWidth: CGFloat = 20 // 二级评论的缩进宽度

    // 计算实际缩进：只有二级及以上评论缩进，但都与二级对齐
    private var actualIndentWidth: CGFloat {
        return level > 0 ? indentWidth : 0
    }

    @State private var showingDeleteAlert = false // 显示删除确认对话框

    // 获取当前用户ID
    private var currentUserId: Int? {
        AuthManager.shared.getCurrentUserId()
    }

    // 判断是否是当前用户的评论
    private var isCurrentUserComment: Bool {
        guard let currentUserId = currentUserId else { return false }
        return comment.author.id == currentUserId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主评论内容
            HStack(alignment: .top, spacing: 12) {
                // 左侧缩进（只有二级及以上评论缩进，且都与二级对齐）
                if level > 0 {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: actualIndentWidth)
                }

                // 评论内容
                commentContent
            }

            // 子评论（递归显示）
            if comment.isExpanded && !comment.replies.isEmpty {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach($comment.replies) { $reply in
                        NestedCommentRowView(
                            comment: $reply,
                            onLike: onLike, // 传递给父组件处理
                            onReply: onReply, // 传递给父组件处理
                            onToggleExpansion: onToggleExpansion, // 传递给父组件处理
                            onLoadReplies: onLoadReplies, // 传递给父组件处理
                            onDelete: onDelete, // 传递删除回调
                            level: level + 1 // 无限层次嵌套
                        )
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private var commentContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 用户信息和评论内容
            HStack(alignment: .top, spacing: 12) {
                // 用户头像区域（包含"我"标识）
                ZStack {
                    AsyncImage(url: URL(string: comment.author.avatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(AppConstants.Colors.primaryGreen.opacity(0.2))
                            .overlay(
                                Text(String(comment.author.nickname.prefix(1)))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppConstants.Colors.primaryGreen)
                            )
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())

                    // "我"标识
                    if isCurrentUserComment {
                        Circle()
                            .fill(AppConstants.Colors.primaryGreen)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text("我")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 12, y: 12)
                    }
                }

                // 评论内容区域
                VStack(alignment: .leading, spacing: 4) {
                    // 用户名和时间
                    HStack(spacing: 6) {
                        Text(comment.author.nickname)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppConstants.Colors.primaryText)

                        if comment.author.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }

                        Spacer()

                        Text(formatTime(comment.createdAt))
                            .font(.system(size: 12))
                            .foregroundColor(AppConstants.Colors.tertiaryText)
                    }

                    // 回复目标用户（如果有）
                    if let replyToUser = comment.replyToUser {
                        HStack(spacing: 4) {
                            Text("回复")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.Colors.tertiaryText)

                            Text("@\(replyToUser.nickname)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppConstants.Colors.primaryGreen)
                        }
                    }

                    // 评论内容
                    Text(comment.content)
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    // 操作按钮
                    HStack(spacing: 16) {
                        // 点赞按钮
                        Button(action: { onLike(comment.id) }) {
                            HStack(spacing: 4) {
                                Image(systemName: comment.isLiked == true ? "heart.fill" : "heart")
                                    .font(.system(size: 14))
                                    .foregroundColor(comment.isLiked == true ? .red : AppConstants.Colors.tertiaryText)

                                if comment.likesCount > 0 {
                                    Text("\(comment.likesCount)")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppConstants.Colors.tertiaryText)
                                }
                            }
                        }

                        // 回复按钮
                        Button(action: { onReply(comment) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppConstants.Colors.tertiaryText)

                                Text("回复")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppConstants.Colors.tertiaryText)
                            }
                        }

                        // 查看回复按钮（如果有回复）
                        if comment.repliesCount > 0 {
                            Button(action: {
                                if comment.replies.isEmpty {
                                    onLoadReplies(comment.id)
                                } else {
                                    onToggleExpansion(comment.id)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    if comment.isLoadingReplies {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: comment.isExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppConstants.Colors.tertiaryText)
                                    }

                                    // 显示实时计算的回复总数（包括所有层级）
                                    Text("\(comment.repliesCount)条回复")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppConstants.Colors.tertiaryText)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 8)
        .onLongPressGesture {
            // 只有当前用户的评论才能删除
            if isCurrentUserComment {
                showingDeleteAlert = true
            }
        }
        .alert("删除评论", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                onDelete?(comment.id)
            }
        } message: {
            if comment.repliesCount > 0 {
                Text("确定要删除这条评论吗？这将同时删除该评论下的所有 \(comment.repliesCount) 条回复，删除后无法恢复。")
            } else {
                Text("确定要删除这条评论吗？删除后无法恢复。")
            }
        }
    }

    private func formatTime(_ timeString: String) -> String {
        // 尝试多种日期格式解析
        let date = parseDate(from: timeString)
        guard let parsedDate = date else {
            // 如果解析失败，尝试移除秒数部分
            print("⚠️ 嵌套评论时间解析失败，原始字符串: \(timeString)")
            return removeSecondsFromTimeString(timeString)
        }

        let now = Date()
        let timeInterval = now.timeIntervalSince(parsedDate)

        // 调试信息
        print("🕐 嵌套评论时间调试信息:")
        print("   原始字符串: \(timeString)")
        print("   解析后时间: \(parsedDate)")
        print("   当前时间: \(now)")
        print("   时间间隔: \(timeInterval)秒 (\(timeInterval/60)分钟)")

        if timeInterval < 0 {
            // 如果时间间隔为负数，说明是未来时间，可能是时区问题
            print("⚠️ 检测到未来时间，可能存在时区问题")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            return dateFormatter.string(from: parsedDate)
        } else if timeInterval < 60 {
            return "刚刚"
        } else if timeInterval < 3600 {
            return "\(Int(timeInterval / 60))分钟前"
        } else if timeInterval < 86400 {
            return "\(Int(timeInterval / 3600))小时前"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            return dateFormatter.string(from: parsedDate)
        }
    }

    private func parseDate(from timeString: String) -> Date? {
        // 尝试ISO8601格式
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: timeString) {
            print("✅ 嵌套评论ISO8601格式解析成功: \(timeString) -> \(date)")
            return date
        }

        // 尝试常见的日期格式
        let formatters: [(String, TimeZone?)] = [
            ("yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'", TimeZone(secondsFromGMT: 0)),
            ("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone(secondsFromGMT: 0)),
            ("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", TimeZone.current), // 本地时区
            ("yyyy-MM-dd'T'HH:mm:ss", TimeZone.current),
            ("yyyy-MM-dd HH:mm:ss", TimeZone.current),
            ("yyyy-MM-dd HH:mm", TimeZone.current),
            ("MM-dd HH:mm:ss", TimeZone.current),
            ("MM-dd HH:mm", TimeZone.current)
        ]

        for (format, timeZone) in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = timeZone
            if let date = formatter.date(from: timeString) {
                print("✅ 嵌套评论格式解析成功: \(format) (\(timeZone?.identifier ?? "nil")) -> \(timeString) -> \(date)")
                return date
            }
        }

        print("❌ 嵌套评论所有格式解析失败: \(timeString)")
        return nil
    }

    private func removeSecondsFromTimeString(_ timeString: String) -> String {
        // 如果日期解析失败，尝试从字符串中移除秒数部分
        let patterns = [
            (":\\d{2}(\\.\\d+)?Z?$", ""), // 移除 :秒数 部分
            (":\\d{2}(\\.\\d+)?$", ""), // 移除 :秒数 部分（无Z）
        ]

        var result = timeString
        for (pattern, replacement) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(location: 0, length: result.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: replacement)
            }
        }

        return result
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var sampleComment = Comment(
            id: "1",
            postId: "sample_post",
            authorId: 1,
            content: "这是一条测试评论，内容比较长，用来测试评论的显示效果。",
            parentCommentId: nil,
            replyToUserId: nil,
            likesCount: 5,
            repliesCount: 2,
            level: 1,
            status: "active",
            isTop: false,
            isLiked: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            author: PostAuthor(
                id: 1,
                nickname: "测试用户",
                avatar: nil,
                isVerified: true,
                level: 1,
                followersCount: 100
            ),
            replyToUser: nil
        )
        
        var body: some View {
            NestedCommentRowView(
                comment: $sampleComment,
                onLike: { _ in },
                onReply: { _ in },
                onToggleExpansion: { _ in },
                onLoadReplies: { _ in },
                onDelete: { _ in },
                level: 0
            )
            .padding()
            .background(Color.white)
        }
    }
    
    return PreviewWrapper()
}