import SwiftUI

// MARK: - 聊天UI组件

/// 消息功能卡片组件
struct MessageFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // 图标背景圆圈
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }

                // 标题
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}

/// 加号菜单项组件
struct PlusMenuItemView: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            .padding(.vertical, ModernDesignSystem.Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}





/// 聊天列表项组件
struct ChatListItemView: View {
    let conversation: ChatConversation
    let onTap: (() -> Void)?
    let onDelete: () -> Void
    let isActionOpen: Bool
    let onActionStateChanged: (Bool) -> Void

    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack {
            // 背景操作按钮
            HStack(spacing: 0) {
                Spacer()

                // 删除
                Button(action: {
                    withAnimation(.spring()) {
                        offset = 0
                    }
                    onActionStateChanged(false)
                    onDelete()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                        Text("删除")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(width: 80)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                }
            }

            // 主要内容
            Group {
                if let onTap = onTap {
                    Button(action: onTap) {
                        contentView
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    contentView
                }
            }
            .offset(x: offset)
            .simultaneousGesture(
                // 只有在操作按钮打开时才添加点击手势
                isActionOpen ? TapGesture().onEnded {
                    withAnimation(.spring()) {
                        offset = 0
                    }
                    onActionStateChanged(false)
                } : nil
            )
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        let translation = value.translation.width
                        let verticalTranslation = value.translation.height
                        
                        // 只有当水平移动大于垂直移动时才响应手势（确保是水平滑动）
                        if abs(translation) > abs(verticalTranslation) && translation < 0 {
                            // 只允许向左滑动
                            offset = max(translation, -80) // 最大滑动距离为1个按钮的宽度
                        }
                    }
                    .onEnded { value in
                        let translation = value.translation.width
                        let velocity = value.velocity.width
                        let verticalTranslation = value.translation.height
                        
                        // 只有当水平移动大于垂直移动时才处理结束事件
                        if abs(translation) > abs(verticalTranslation) {
                            withAnimation(.spring()) {
                                if translation < -40 || velocity < -500 {
                                    // 显示操作按钮
                                    offset = -80
                                    onActionStateChanged(true)
                                } else {
                                    // 回到原位
                                    offset = 0
                                    onActionStateChanged(false)
                                }
                            }
                        } else {
                            // 如果是垂直滑动，重置偏移
                            withAnimation(.spring()) {
                                offset = 0
                                onActionStateChanged(false)
                            }
                        }
                    }
            )
        }
        .clipped()
        .onChange(of: isActionOpen) { newValue in
            // 监听外部状态变化，当状态变为 false 时关闭操作按钮
            if !newValue {
                withAnimation(.spring()) {
                    offset = 0
                }
            }
        }
    }

    private var contentView: some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // 头像 - 根据会话类型显示不同样式
            Group {
                if conversation.type == .group {
                    // 群聊：如果有成员信息则显示九宫格头像，否则显示群头像
                    if !conversation.participants.isEmpty {
                        GroupAvatarView(
                            members: conversation.participants,
                            size: 52
                        )
                    } else {
                        // 回退到单个群头像
                        ChatAvatarView(
                            avatarUrl: conversation.avatar,
                            displayName: conversation.displayName,
                            size: 52,
                            isOnline: nil
                        )
                    }
                } else {
                    // 私聊：显示单个头像
                    ChatAvatarView(
                        avatarUrl: conversation.displayAvatar,
                        displayName: conversation.displayName,
                        size: 52,
                        isOnline: conversation.type == .privateChat ? conversation.participants.first?.isOnline : nil,
                        isMember: conversation.type == .privateChat ? (conversation.participants.first?.isMember ?? false) : false
                    )
                }
            }

            // 内容区域
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // 会话名称
                    Text(conversation.displayName)
                        .font(ModernDesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    // 时间和状态指示器
                    HStack(spacing: 4) {
                        if conversation.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                        }

                        if conversation.isMuted ?? false {
                            Image(systemName: "speaker.slash.fill")
                                .font(.system(size: 10))
                                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                        }

                        Text(conversation.lastMessageTimeDisplay)
                            .font(ModernDesignSystem.Typography.caption2)
                            .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    }
                }

                HStack {
                    // 最后消息预览
                    Text(conversation.lastMessagePreview)
                        .font(ModernDesignSystem.Typography.footnote)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        .lineLimit(2)

                    Spacer()

                    // 未读消息数量
                    if (conversation.unreadCount ?? 0) > 0 {
                        UnreadBadgeView(count: conversation.unreadCount ?? 0)
                    }
                }
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.md)
        .background(ModernDesignSystem.Colors.backgroundCard)
        .contentShape(Rectangle())
    }
}

/// 聊天头像组件
struct ChatAvatarView: View {
    let avatarUrl: String?
    let displayName: String
    let size: CGFloat
    let isOnline: Bool?
    let isMember: Bool

    init(avatarUrl: String?, displayName: String, size: CGFloat, isOnline: Bool? = nil, isMember: Bool = false) {
        self.avatarUrl = avatarUrl
        self.displayName = displayName
        self.size = size
        self.isOnline = isOnline
        self.isMember = isMember
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // 头像
            if let avatarUrl = avatarUrl, !avatarUrl.isEmpty {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultAvatarView
                }
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.15)) // 方块形，带圆角
            } else {
                defaultAvatarView
            }

            // 在线状态指示器（左上角）
            if let isOnline = isOnline, isOnline {
                Circle()
                    .fill(ModernDesignSystem.Colors.successGreen)
                    .frame(width: size * 0.25, height: size * 0.25)
                    .overlay(
                        Circle()
                            .stroke(ModernDesignSystem.Colors.backgroundCard, lineWidth: 2)
                    )
                    .offset(x: size * 0.3, y: -size * 0.3)
            }

            // 会员标识（右下角）
            if isMember {
                memberBadge
            }
        }
    }

    // 会员标识
    private var memberBadge: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0),
                            Color(red: 1.0, green: 0.71, blue: 0.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.30, height: size * 0.30)

            Circle()
                .stroke(ModernDesignSystem.Colors.backgroundCard, lineWidth: max(1.5, size * 0.03))
                .frame(width: size * 0.30, height: size * 0.30)

            Image(systemName: "crown.fill")
                .font(.system(size: size * 0.165, weight: .bold))
                .foregroundColor(.white)
        }
        .offset(x: size * 0.045, y: size * 0.045)
    }

    private var defaultAvatarView: some View {
        RoundedRectangle(cornerRadius: size * 0.15)
            .fill(ModernDesignSystem.Colors.primaryGreen.opacity(0.1))
            .frame(width: size, height: size)
            .overlay(
                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
            )
    }
}

/// 群聊头像组件 - 九宫格样式
struct GroupAvatarView: View {
    let members: [ChatUser]
    let size: CGFloat
    
    // 根据成员数量决定显示的头像数量和布局
    private var displayMembers: [ChatUser] {
        Array(members.prefix(9))
    }
    
    private var gridLayout: (rows: Int, columns: Int) {
        let count = displayMembers.count
        switch count {
        case 0, 1: return (1, 1)
        case 2: return (1, 2)  // 2个成员：1行2列
        case 3: return (2, 2)  // 3个成员：2行2列（右下角空）
        case 4: return (2, 2)  // 4个成员：2行2列
        case 5...6: return (2, 3)  // 5-6个成员：2行3列
        case 7...9: return (3, 3)  // 7-9个成员：3行3列
        default: return (3, 3)
        }
    }
    
    var body: some View {
        let layout = gridLayout
        let itemSize = size / CGFloat(max(layout.rows, layout.columns))
        let spacing: CGFloat = 1
        
        // 调试信息
        let _ = print("🔍 GroupAvatarView - members count: \(members.count), displayMembers: \(displayMembers.count), layout: \(layout)")
        
        VStack(spacing: spacing) {
            ForEach(0..<layout.rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<layout.columns, id: \.self) { col in
                        let index = row * layout.columns + col
                        if index < displayMembers.count {
                            let _ = print("🔍 Member[\(index)]: \(displayMembers[index].nickname), avatar: \(displayMembers[index].avatar ?? "nil")")
                            memberAvatarView(member: displayMembers[index], size: itemSize - spacing)
                        }
                        // 移除了 else 分支，不再显示透明占位符
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .background(ModernDesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
    }
    
    @ViewBuilder
    private func memberAvatarView(member: ChatUser, size: CGFloat) -> some View {
        Group {
            if let avatarUrl = member.avatar, !avatarUrl.isEmpty, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        // 加载失败，显示默认头像
                        defaultMemberAvatar(member: member, size: size)
                    case .empty:
                        // 加载中，显示默认头像作为占位符
                        defaultMemberAvatar(member: member, size: size)
                    @unknown default:
                        defaultMemberAvatar(member: member, size: size)
                    }
                }
                .frame(width: size, height: size)
                .clipped()
            } else {
                defaultMemberAvatar(member: member, size: size)
            }
        }
    }
    
    private func defaultMemberAvatar(member: ChatUser, size: CGFloat) -> some View {
        Rectangle()
            .fill(avatarColor(for: member.id))
            .frame(width: size, height: size)
            .overlay(
                Text(String(member.nickname.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.white)
            )
    }
    
    // 根据用户ID生成不同的颜色
    private func avatarColor(for userId: Int) -> Color {
        let colors: [Color] = [
            ModernDesignSystem.Colors.primaryGreen,
            .blue,
            .purple,
            .orange,
            .pink,
            .teal,
            .indigo,
            .cyan,
            .mint
        ]
        return colors[abs(userId.hashValue) % colors.count]
    }
}

/// 未读消息徽章
struct UnreadBadgeView: View {
    let count: Int

    var body: some View {
        Group {
            if count > 0 {
                Text(count > 99 ? "99+" : "\(count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, count > 9 ? 6 : 8)
                    .padding(.vertical, 4)
                    .background(ModernDesignSystem.Colors.errorRed)
                    .clipShape(Capsule())
                    .scaleEffect(count > 0 ? 1.0 : 0.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: count)
            }
        }
    }
}

/// 搜索栏组件
struct ChatSearchBar: View {
    @Binding var searchText: String
    @FocusState private var isSearchFocused: Bool
    let onSearchSubmit: () -> Void
    let onCancelSearch: () -> Void

    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.sm) {
            // 搜索输入框
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(ModernDesignSystem.Colors.textTertiary)

                TextField("搜索聊天记录", text: $searchText)
                    .focused($isSearchFocused)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(ModernDesignSystem.Typography.body)
                    .onSubmit {
                        onSearchSubmit()
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        onCancelSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.md)
            .padding(.vertical, ModernDesignSystem.Spacing.sm)
            .background(ModernDesignSystem.Colors.backgroundSecondary)
            .cornerRadius(ModernDesignSystem.CornerRadius.md)

            // 取消按钮（搜索时显示）
            if isSearchFocused {
                Button("取消") {
                    searchText = ""
                    isSearchFocused = false
                    onCancelSearch()
                }
                .font(ModernDesignSystem.Typography.body)
                .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }
}

/// 聊天分类筛选器
struct ChatCategoryFilter: View {
    @Binding var selectedCategory: ChatCategory
    let categories: [ChatCategory] = ChatCategory.allCases

    var body: some View {
        HStack(spacing: 0) {
            ForEach(categories, id: \.self) { category in
                ChatCategoryButton(
                    category: category,
                    isSelected: selectedCategory == category
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = category
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(ModernDesignSystem.Colors.backgroundPrimary)
    }
}

/// 聊天分类按钮
struct ChatCategoryButton: View {
    let category: ChatCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(category.displayName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Rectangle()
                        .fill(isSelected ? ModernDesignSystem.Colors.primaryGreen.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 空状态视图
struct ChatEmptyStateView: View {
    let type: EmptyStateType

    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            Image(systemName: type.iconName)
                .font(.system(size: 64))
                .foregroundColor(ModernDesignSystem.Colors.textTertiary)

            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                Text(type.title)
                    .font(ModernDesignSystem.Typography.headline)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)

                Text(type.subtitle)
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ModernDesignSystem.Spacing.xl)
            }

            if let actionTitle = type.actionTitle {
                Button(actionTitle) {
                    // 处理操作
                }
                .modernButtonStyle()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ModernDesignSystem.Colors.backgroundPrimary)
    }
}

/// 消息气泡组件 - 重新设计的现代化版本
struct MessageBubbleView: View {
    let message: ChatMessage
    let isHighlighted: Bool
    let onLongPress: () -> Void
    let onReplyTap: ((String) -> Void)?
    let findMessage: ((String) -> ChatMessage?)?

    init(message: ChatMessage, isHighlighted: Bool = false, onLongPress: @escaping () -> Void, onReplyTap: ((String) -> Void)? = nil, findMessage: ((String) -> ChatMessage?)? = nil) {
        self.message = message
        self.isHighlighted = isHighlighted
        self.onLongPress = onLongPress
        self.onReplyTap = onReplyTap
        self.findMessage = findMessage
    }

    var body: some View {
        Group {
            if message.type == .system {
                // 系统消息：使用与上方卡片一致的“卡片样式”，占满行宽
                systemMessageCard
            } else {
                HStack(alignment: .top, spacing: ModernDesignSystem.Spacing.sm) {
                    if message.isFromCurrentUser {
                        // 自己发送的消息 - 右对齐
                        Spacer(minLength: 80)
                        messageBubble
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
                    } else {
                        // 他人发送的消息 - 左对齐
                        if shouldShowAvatar {
                            ChatAvatarView(
                                avatarUrl: message.sender.avatar,
                                displayName: message.sender.nickname,
                                size: 36,
                                isOnline: nil,
                                isMember: message.sender.isMember ?? false
                            )
                            .padding(.top, 2)
                        } else {
                            Spacer().frame(width: 36)
                        }

                        messageBubble
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                        Spacer(minLength: 80)
                    }
                }
                .padding(.horizontal, ModernDesignSystem.Spacing.md)
                .background(
                    // 高亮背景效果
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ModernDesignSystem.Colors.primaryGreen.opacity(isHighlighted ? 0.15 : 0))
                        .animation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true), value: isHighlighted)
                        .padding(.horizontal, -8)
                        .padding(.vertical, -4)
                )
                .onLongPressGesture { onLongPress() }
            }
        }
    }

    // 系统消息卡片：与 AskSuggestionsCard 保持一致的视觉风格
    private var systemMessageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(systemMessageText)
                .font(ModernDesignSystem.Typography.subheadline)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                        .shadow(color: .white.opacity(0.35), radius: 20, x: 0, y: 6)
                        .blur(radius: 0)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
        )

    }

    private var systemMessageText: String {
        // 将特定占位表情替换为 Emoji（或后续替换为图片富文本）
        message.content.replacingOccurrences(of: "[社会社会]", with: "😎")
    }


    private var messageBubble: some View {
        VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 6) {
            // 发送者名称（仅群聊中他人消息显示）
            if shouldShowSenderName {
                HStack {
                    Text(message.sender.nickname)
                        .font(ModernDesignSystem.Typography.caption1)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal, 2)
            }

            // 消息内容容器
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // 消息内容（包含回复消息）
                VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 8) {
                    // 回复消息预览（如果存在）
                    if let replyToMessageId = message.replyToMessageId {
                        replyMessagePreview(replyToMessageId: replyToMessageId)
                            .onAppear {
                                print("🔄 MessageBubbleView: 消息 \(message.id) 有回复ID: \(replyToMessageId)")
                            }
                    }

                    // 主消息内容
                    messageContent
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(bubbleBackground)
                .clipShape(modernBubbleShape)
                .overlay(
                    modernBubbleShape
                        .stroke(bubbleBorderColor, lineWidth: 0.5)
                )

                // 时间和状态（系统消息不显示）
                if message.type != .system {
                    HStack(spacing: 4) {
                        if message.isFromCurrentUser {
                            messageStatusIcon
                        }

                        Text(detailedTimeDisplay)
                            .font(ModernDesignSystem.Typography.caption2)
                            .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    private var messageContent: some View {
        Group {
            if message.isRecalled == true {
                // 撤回消息显示
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.left")
                        .font(.system(size: 12))
                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)

                    Text(message.content)
                        .font(ModernDesignSystem.Typography.footnote)
                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                        .italic()
                }
            } else {
                switch message.type {
                case .text:
                    Text(message.content)
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(message.isFromCurrentUser ? .trailing : .leading)
                case .image:
                    ImageMessageView(
                        imageUrl: message.mediaUrl,
                        thumbnailUrl: message.thumbnailUrl,
                        textColor: textColor
                    )
                case .video:
                    // TODO: 实现视频消息
                    Text("[视频]")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(textColor)
                case .audio:
                    AudioMessageView(
                        message: message,
                        textColor: textColor
                    )
                case .file:
                    // TODO: 实现文件消息
                    Text("[文件]")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(textColor)
                case .system:
                    // 系统消息在外层使用卡片视图，messageContent 本体仅作为占位
                    EmptyView()
                }
            }
        }
    }

    private var bubbleBackground: Color {
        // 系统消息不使用聊天气泡背景（使用卡片样式），此处返回值不会被用到
        return message.isFromCurrentUser ?
            ModernDesignSystem.Colors.chatBubbleSent :
            ModernDesignSystem.Colors.chatBubbleReceived
    }

    private var bubbleBorderColor: Color {
        // 系统消息不使用聊天气泡边框
        return message.isFromCurrentUser ? Color.clear : ModernDesignSystem.Colors.borderLight
    }

    private var modernBubbleShape: some Shape {
        RoundedRectangle(cornerRadius: 18)
    }

    private var textColor: Color {
        if message.type == .system {
            return ModernDesignSystem.Colors.textSecondary
        }
        return message.isFromCurrentUser ?
            .white :
            ModernDesignSystem.Colors.textPrimary
    }

    private var messageStatusIcon: some View {
        Group {
            switch message.status {
            case .sending:
                ProgressView()
                    .scaleEffect(0.5)
                    .tint(ModernDesignSystem.Colors.textTertiary)
            case .sent:
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            case .delivered:
                HStack(spacing: -2) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .medium))
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            case .read:
                HStack(spacing: -2) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .medium))
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(ModernDesignSystem.Colors.errorRed)
            }
        }
    }

    private var shouldShowAvatar: Bool {
        // 群聊中的他人消息显示头像；系统消息不显示头像
        return !message.isFromCurrentUser && message.type != .system
    }

    private var shouldShowSenderName: Bool {
        // 群聊中的他人消息显示发送者名称；系统消息不显示
        return !message.isFromCurrentUser && message.type != .system
    }

    /// 详细的时间显示格式
    private var detailedTimeDisplay: String {
        // 尝试多种时间格式解析
        let date = parseMessageDate(message.createdAt)

        guard let date = date else {
            // 如果解析失败，返回刚刚
            return "刚刚"
        }

        let now = Date()
        let calendar = Calendar.current
        let timeInterval = now.timeIntervalSince(date)

        // 1分钟内显示"刚刚"
        if timeInterval < 60 {
            return "刚刚"
        }

        // 1小时内显示"X分钟前"
        if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分钟前"
        }

        // 24小时内显示"X小时前"
        if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)小时前"
        }

        // 昨天显示"昨天 HH:mm"
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            timeFormatter.locale = Locale(identifier: "zh_CN")
            timeFormatter.timeZone = TimeZone.current // 使用当前时区（北京时间）
            return "昨天 \(timeFormatter.string(from: date))"
        }

        // 一周内显示"星期X HH:mm"
        if timeInterval < 604800 { // 7天
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.dateFormat = "EEEE"
            weekdayFormatter.locale = Locale(identifier: "zh_CN")
            weekdayFormatter.timeZone = TimeZone.current
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            timeFormatter.locale = Locale(identifier: "zh_CN")
            timeFormatter.timeZone = TimeZone.current
            return "\(weekdayFormatter.string(from: date)) \(timeFormatter.string(from: date))"
        }

        // 超过一周显示完整日期时间 "yyyy年MM月dd日 HH:mm"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.timeZone = TimeZone.current // 使用当前时区（北京时间）
        return dateFormatter.string(from: date)
    }

    /// 解析消息时间，支持多种格式
    /// 后端返回的是北京时间，解析后直接使用
    private func parseMessageDate(_ dateString: String) -> Date? {
        // 优先使用 ISO8601 格式解析（推荐）
        if #available(iOS 10.0, *) {
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // 尝试不带毫秒的格式
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
        }

        // 备用格式解析
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",     // 2025-08-22T13:30:00.000Z
            "yyyy-MM-dd'T'HH:mm:ss'Z'",       // 2025-08-22T13:30:00Z
            "yyyy-MM-dd'T'HH:mm:ssZ",         // 2025-08-22T13:30:00+0000
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",   // 2025-08-22T13:30:00.000Z
            "yyyy-MM-dd HH:mm:ss",            // 2025-08-22 13:30:00 (北京时间)
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            // 对于带时区信息的格式，让系统自动处理时区
            // 对于不带时区信息的格式，假设为北京时间（因为服务器已修改为北京时间）
            if !format.contains("Z") && !format.contains("z") {
                formatter.timeZone = TimeZone(identifier: "Asia/Shanghai") // 北京时间
            }

            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    /// 回复消息预览组件
    @ViewBuilder
    private func replyMessagePreview(replyToMessageId: String) -> some View {
        let replyMessage = findMessage?(replyToMessageId)

        // 调试信息
        let _ = print("🔍 replyMessagePreview: 查找回复消息ID: \(replyToMessageId)")
        let _ = print("🔍 replyMessagePreview: 找到的消息: \(replyMessage?.content ?? "未找到")")
        let _ = print("🔍 replyMessagePreview: findMessage函数是否存在: \(findMessage != nil)")

        HStack(spacing: 8) {
            // 左侧竖线指示器
            Rectangle()
                .fill(ModernDesignSystem.Colors.primaryGreen)
                .frame(width: 3)
                .cornerRadius(1.5)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.left")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen)

                    Text(replyMessage != nil ? "回复 \(replyMessage!.sender.nickname)" : "回复消息")
                        .font(ModernDesignSystem.Typography.caption1)
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                        .fontWeight(.medium)

                    Spacer()
                }

                // 被回复的消息内容预览
                Text(replyMessage?.preview ?? "消息内容加载中...")
                    .font(ModernDesignSystem.Typography.footnote)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    message.isFromCurrentUser
                    ? Color.white.opacity(0.2)
                    : ModernDesignSystem.Colors.backgroundSecondary.opacity(0.8)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    message.isFromCurrentUser
                    ? Color.white.opacity(0.3)
                    : ModernDesignSystem.Colors.borderLight,
                    lineWidth: 0.5
                )
        )
        .onTapGesture {
            onReplyTap?(replyToMessageId)
        }
    }
}

// MARK: - 辅助枚举



/// 空状态类型
enum EmptyStateType {
    case noChats
    case noSearchResults
    case noUnreadMessages

    var iconName: String {
        switch self {
        case .noChats: return "bubble.left.and.bubble.right"
        case .noSearchResults: return "magnifyingglass"
        case .noUnreadMessages: return "checkmark.circle"
        }
    }

    var title: String {
        switch self {
        case .noChats: return "暂无聊天"
        case .noSearchResults: return "无搜索结果"
        case .noUnreadMessages: return "没有未读消息"
        }
    }

    var subtitle: String {
        switch self {
        case .noChats: return "开始与朋友聊天吧"
        case .noSearchResults: return "尝试使用其他关键词搜索"
        case .noUnreadMessages: return "所有消息都已阅读"
        }
    }

    var actionTitle: String? {
        switch self {
        case .noChats: return "开始聊天"
        case .noSearchResults, .noUnreadMessages: return nil
        }
    }
}

// MARK: - 音频消息组件
struct AudioMessageView: View {
    let message: ChatMessage
    let textColor: Color
    @ObservedObject private var audioManager = AudioMessageManager.shared

    private var isCurrentlyPlaying: Bool {
        audioManager.isPlaying && audioManager.currentPlayingMessageId == message.id
    }

    private var currentProgress: Double {
        audioManager.currentPlayingMessageId == message.id ? audioManager.playbackProgress : 0
    }

    private var displayDuration: Double {
        if audioManager.currentPlayingMessageId == message.id && audioManager.duration > 0 {
            return audioManager.duration
        }
        return Double(message.mediaDuration ?? 0)
    }

    private var displayCurrentTime: Double {
        audioManager.currentPlayingMessageId == message.id ? audioManager.currentTime : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // 播放/暂停按钮
            Button(action: {
                togglePlayback()
            }) {
                Image(systemName: isCurrentlyPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(textColor)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 6) {
                // 音频波形或进度条
                audioWaveform

                // 时长显示
                Text(formatAudioDuration())
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(textColor.opacity(0.8))
            }
        }
        .frame(maxWidth: 220)
        .padding(.vertical, 6)
    }

    private var audioWaveform: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<15, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(textColor.opacity(isCurrentlyPlaying && index < Int(currentProgress * 15) ? 1.0 : 0.3))
                        .frame(width: 2.5, height: waveformHeight(for: index))
                        .animation(.easeInOut(duration: 0.1), value: currentProgress)
                }
            }
            .frame(maxWidth: .infinity)
            .onTapGesture { location in
                // 点击波形跳转到指定位置
                let progress = location.x / geometry.size.width
                let targetTime = progress * displayDuration
                if audioManager.currentPlayingMessageId == message.id {
                    audioManager.seekTo(time: targetTime)
                }
            }
        }
        .frame(height: 20)
    }

    private func waveformHeight(for index: Int) -> CGFloat {
        // 创建一个基于消息ID的伪随机波形，确保每条消息的波形是固定的
        let seed = message.id.hashValue + index
        let normalizedSeed = abs(seed) % 100
        return CGFloat(8 + (normalizedSeed % 12)) // 8-20的高度范围
    }

    private func togglePlayback() {
        audioManager.playAudio(from: message)
    }

    private func formatAudioDuration() -> String {
        if isCurrentlyPlaying && audioManager.currentPlayingMessageId == message.id {
            let currentSeconds = Int(displayCurrentTime)
            let totalSeconds = Int(displayDuration)

            let currentMinutes = currentSeconds / 60
            let currentSecondsRemainder = currentSeconds % 60
            let totalMinutes = totalSeconds / 60
            let totalSecondsRemainder = totalSeconds % 60

            return String(format: "%d:%02d / %d:%02d",
                         currentMinutes, currentSecondsRemainder,
                         totalMinutes, totalSecondsRemainder)
        } else {
            let totalSeconds = Int(displayDuration)
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - 图片消息组件
struct ImageMessageView: View {
    let imageUrl: String?
    let thumbnailUrl: String?
    let textColor: Color

    @State private var showingFullScreen = false

    // 修复localhost URL的辅助方法
    private func fixImageUrl(_ url: String?) -> String? {
        guard let url = url else { return nil }

        // 如果URL包含localhost，替换为正确的域名
        if url.contains("localhost:3000") {
            return url.replacingOccurrences(of: "http://localhost:3000", with: "https://api.qinghejihua.com.cn")
        }

        return url
    }

    var body: some View {
        Group {
            if let imageUrl = imageUrl, !imageUrl.isEmpty {
                Button(action: {
                    showingFullScreen = true
                }) {
                    CachedAsyncImage(url: URL(string: fixImageUrl(thumbnailUrl) ?? fixImageUrl(imageUrl) ?? imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: 220, maxHeight: 220)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                            )
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ModernDesignSystem.Colors.backgroundSecondary)
                            .frame(width: 220, height: 160)
                            .overlay(
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(ModernDesignSystem.Colors.primaryGreen)
                                    Text("加载中...")
                                        .font(ModernDesignSystem.Typography.caption1)
                                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                                }
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showingFullScreen) {
                    ImageViewerSheet(images: [fixImageUrl(imageUrl) ?? imageUrl], selectedIndex: .constant(0))
                }
            } else {
                // 图片URL为空时的占位符
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .fill(ModernDesignSystem.Colors.backgroundSecondary)
                    .frame(width: 200, height: 150)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                            Text("图片加载失败")
                                .font(ModernDesignSystem.Typography.caption1)
                                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                        }
                    )
            }
        }
    }
}


