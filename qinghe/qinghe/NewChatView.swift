import SwiftUI

/// 新建聊天视图
struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewChatViewModel()
    @State private var searchText = ""
    @State private var selectedUsers: Set<ChatUser> = []
    @State private var groupName = ""
    @State private var showingGroupNameInput = false

    @State private var createdConversation: ChatConversation?
    @State private var showingChatDetail = false
    @State private var selectedLetter: String? = nil // 用于字母索引滚动
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar

            // 搜索栏
            searchBar

            // 用户列表（带字母索引）
            usersListWithIndex
        }
        .background(ModernDesignSystem.Colors.backgroundPrimary)
        .navigationBarHidden(true)
        .asSubView() // 隐藏底部Tab栏

        .navigationDestination(isPresented: $showingChatDetail) {
            if let conversation = createdConversation {
                ChatDetailView(conversation: conversation)
                    .asSubView() // 确保聊天详情页面也隐藏Tab栏
            }
        }
            .onAppear {
                Task {
                    await viewModel.loadUsers()
                }
            }
            .alert("创建群聊", isPresented: $showingGroupNameInput) {
                TextField("群聊名称", text: $groupName)
                Button("取消", role: .cancel) { }
                Button("创建") {
                    Task {
                        await createGroupChat()
                    }
                }
            } message: {
                Text("请输入群聊名称")
            }
            .alert("错误", isPresented: $viewModel.showError) {
                Button("确定") { }
            } message: {
                Text(viewModel.errorMessage ?? "未知错误")
            }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            // 取消按钮
            Button("取消") {
                dismiss()
            }
            .foregroundColor(ModernDesignSystem.Colors.textPrimary)

            Spacer()

            // 标题
            Text("发起群聊")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ModernDesignSystem.Colors.textPrimary)

            Spacer()

            // 完成按钮
            Button("完成") {
                createChat()
            }
            .foregroundColor(selectedUsers.isEmpty ? ModernDesignSystem.Colors.textSecondary : ModernDesignSystem.Colors.primaryGreen)
            .disabled(selectedUsers.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ModernDesignSystem.Colors.backgroundPrimary)
    }

    // MARK: - 快捷操作
    private var quickActionsSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: ModernDesignSystem.Spacing.lg) {
                // 创建群聊
                QuickActionButton(
                    title: "创建群聊",
                    icon: "person.2.fill",
                    color: ModernDesignSystem.Colors.primaryGreen,
                    action: {
                        // 快捷创建群聊，直接显示群名输入
                        if !selectedUsers.isEmpty {
                            showingGroupNameInput = true
                        }
                    }
                )

                // 扫一扫
                QuickActionButton(
                    title: "扫一扫",
                    icon: "qrcode.viewfinder",
                    color: ModernDesignSystem.Colors.primaryGreen,
                    action: {
                        // TODO: 实现扫码功能
                    }
                )

                // 面对面建群
                QuickActionButton(
                    title: "面对面建群",
                    icon: "person.2.wave.2",
                    color: ModernDesignSystem.Colors.primaryGreen,
                    action: {
                        // TODO: 实现面对面建群
                    }
                )

                Spacer()
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            .padding(.vertical, ModernDesignSystem.Spacing.md)

            Divider()
                .background(ModernDesignSystem.Colors.borderLight)
        }
    }

    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color.gray)

            TextField("搜索", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .onChange(of: searchText) { _, keyword in
                    viewModel.searchUsers(keyword: keyword)
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - 已选择的用户
    private var selectedUsersView: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
            HStack {
                Text("已选择 \(selectedUsers.count) 人")
                    .font(ModernDesignSystem.Typography.footnote)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                
                Spacer()
                
                if selectedUsers.count > 1 {
                    Button("创建群聊") {
                        showingGroupNameInput = true
                    }
                    .font(ModernDesignSystem.Typography.footnote)
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ModernDesignSystem.Spacing.sm) {
                    ForEach(Array(selectedUsers), id: \.id) { user in
                        SelectedUserChip(user: user) {
                            selectedUsers.remove(user)
                        }
                    }
                }
                .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            }
        }
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
        .background(ModernDesignSystem.Colors.backgroundSecondary)
    }
    
    // MARK: - 带字母索引的用户列表
    private var usersListWithIndex: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 主要用户列表
                usersListContent
                    .frame(width: geometry.size.width - 30)

                // 右侧字母索引
                alphabetIndex
                    .frame(width: 30)
            }
        }
    }

    // MARK: - 用户列表内容
    private var usersListContent: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredUsers.isEmpty {
                emptyView
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedUsers.keys.sorted(), id: \.self) { letter in
                                Section(header: sectionHeader(letter: letter)) {
                                    ForEach(Array((groupedUsers[letter] ?? []).enumerated()), id: \.element.id) { index, user in
                                        VStack(spacing: 0) {
                                            userRowView(user: user)

                                            // 分隔线（最后一个用户不显示）
                                            if index < (groupedUsers[letter]?.count ?? 0) - 1 {
                                                Divider()
                                                    .padding(.leading, 88) // 对齐用户信息
                                            }
                                        }
                                    }
                                }
                                .id(letter) // 为每个字母分组添加ID
                            }
                        }
                    }
                    .onChange(of: selectedLetter) { _, newLetter in
                        if let letter = newLetter {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(letter, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 分组后的用户数据
    private var groupedUsers: [String: [ChatUser]] {
        Dictionary(grouping: viewModel.filteredUsers) { user in
            // 🔥 修复：检查昵称是否为空，避免索引越界
            guard !user.nickname.isEmpty else {
                return "#"
            }

            let firstChar = String(user.nickname.prefix(1)).uppercased()
            // 检查是否为中文字符
            if firstChar.range(of: "[\u{4e00}-\u{9fff}]", options: .regularExpression) != nil {
                // 中文字符，返回拼音首字母（这里简化处理，实际应该使用拼音转换）
                return getPinyinFirstLetter(from: firstChar)
            } else if firstChar.range(of: "[A-Z]", options: .regularExpression) != nil {
                return firstChar
            } else {
                return "#"
            }
        }
    }

    // MARK: - 获取拼音首字母（简化版）
    private func getPinyinFirstLetter(from chinese: String) -> String {
        // 🔥 修复：检查输入字符串是否为空
        guard !chinese.isEmpty else {
            return "#"
        }

        let cfString = chinese as CFString
        let mutableString = CFStringCreateMutableCopy(nil, 0, cfString)!
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        let pinyinString = mutableString as String

        // 🔥 修复：检查转换后的字符串是否为空，避免索引越界
        guard !pinyinString.isEmpty else {
            return "#"
        }

        return String(pinyinString.prefix(1)).uppercased()
    }

    // MARK: - 用户列表
    private var usersList: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredUsers.isEmpty {
                emptyView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.filteredUsers) { user in
                            // UserListItemView(
                            //     user: user,
                            //     isSelected: selectedUsers.contains(user)
                            // ) {
                            //     toggleUserSelection(user)
                            // }
                            
                            // Temporary simple view
                            HStack {
                                Text(user.nickname)
                                Spacer()
                                if selectedUsers.contains(user) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .onTapGesture {
                                toggleUserSelection(user)
                            }
                            
                            if user.id != viewModel.filteredUsers.last?.id {
                                Divider()
                                    .padding(.leading, 68)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 分组标题
    private func sectionHeader(letter: String) -> some View {
        HStack {
            Text(letter)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ModernDesignSystem.Colors.primaryGreen)

            Rectangle()
                .fill(ModernDesignSystem.Colors.borderLight)
                .frame(height: 1)
                .padding(.leading, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            ModernDesignSystem.Colors.backgroundSecondary
                .opacity(0.8)
        )
    }

    // MARK: - 用户行视图
    private func userRowView(user: ChatUser) -> some View {
        let isSelected = selectedUsers.contains(user)

        return HStack(spacing: 16) {
            // 选择状态指示器
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    toggleUserSelection(user)
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.borderMedium, lineWidth: 2)
                        .fill(isSelected ? ModernDesignSystem.Colors.primaryGreen : Color.clear)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(isSelected ? 1.0 : 0.5)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // 用户头像（带在线状态）
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [
                                ModernDesignSystem.Colors.primaryGreen.opacity(0.3),
                                ModernDesignSystem.Colors.primaryGreenLight.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .overlay(
                            Text(user.nickname.prefix(1).uppercased())
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                        )
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? ModernDesignSystem.Colors.primaryGreen : Color.clear, lineWidth: 2)
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                )

                // 在线状态指示器
                if user.isOnline == true {
                    Circle()
                        .fill(ModernDesignSystem.Colors.successGreen)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }
            }

            // 用户信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.nickname)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                        .lineLimit(1)

                    // 认证标识
                    if user.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                    }

                    Spacer()
                }

                // 在线状态文本
                if let isOnline = user.isOnline {
                    Text(isOnline ? "在线" : "离线")
                        .font(.system(size: 12))
                        .foregroundColor(isOnline ? ModernDesignSystem.Colors.successGreen : ModernDesignSystem.Colors.textTertiary)
                } else if let lastSeenAt = user.lastSeenAt {
                    Text("最后在线: \(formatLastSeen(lastSeenAt))")
                        .font(.system(size: 12))
                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? ModernDesignSystem.Colors.primaryGreen.opacity(0.05) : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                toggleUserSelection(user)
            }
        }
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - 字母索引
    private var alphabetIndex: some View {
        VStack(spacing: 2) {
            ForEach(alphabetLetters, id: \.self) { letter in
                Text(letter)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(selectedLetter == letter ? .white : ModernDesignSystem.Colors.primaryGreen)
                    .frame(width: 20, height: 15)
                    .background(
                        Circle()
                            .fill(selectedLetter == letter ? ModernDesignSystem.Colors.primaryGreen : Color.clear)
                            .scaleEffect(selectedLetter == letter ? 1.2 : 1.0)
                    )
                    .scaleEffect(selectedLetter == letter ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedLetter)
                    .onTapGesture {
                        selectedLetter = letter
                        // 添加触觉反馈
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()

                        // 延迟重置选中状态
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            selectedLetter = nil
                        }
                    }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - 字母列表
    private var alphabetLetters: [String] {
        let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
                      "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "#"]
        return letters.filter { letter in
            groupedUsers.keys.contains(letter)
        }
    }

    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("加载用户列表...")
                .font(ModernDesignSystem.Typography.body)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 空状态视图
    private var emptyView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 64))
                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            
            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                Text("没有找到用户")
                    .font(ModernDesignSystem.Typography.headline)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                
                Text("尝试使用其他关键词搜索")
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 私有方法
    
    /// 切换用户选择状态
    private func toggleUserSelection(_ user: ChatUser) {
        if selectedUsers.contains(user) {
            selectedUsers.remove(user)
        } else {
            selectedUsers.insert(user)
        }
    }

    /// 格式化最后在线时间
    private func formatLastSeen(_ lastSeenAt: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: lastSeenAt) else {
            return "未知"
        }

        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 60 {
            return "刚刚"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分钟前"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)小时前"
        } else {
            let days = Int(timeInterval / 86400)
            if days == 1 {
                return "昨天"
            } else if days < 7 {
                return "\(days)天前"
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd"
                return dateFormatter.string(from: date)
            }
        }
    }
    
    /// 创建聊天
    private func createChat() {
        if selectedUsers.count == 1 {
            // 创建私聊
            Task {
                await createPrivateChat()
            }
        } else if selectedUsers.count > 1 {
            // 显示群聊名称输入
            showingGroupNameInput = true
        }
    }
    
    /// 创建私聊
    private func createPrivateChat() async {
        guard let user = selectedUsers.first else { return }
        
        do {
            let conversation = try await viewModel.createConversation(
                type: .privateChat,
                participantIds: [user.id],
                title: nil
            )
            
            // 创建成功，导航到聊天详情页面
            createdConversation = conversation
            showingChatDetail = true
            
        } catch {
            viewModel.errorMessage = "创建聊天失败: \(error.localizedDescription)"
            viewModel.showError = true
        }
    }
    
    /// 创建群聊
    private func createGroupChat() async {
        let participantIds = Array(selectedUsers).map { $0.id }
        
        do {
            let conversation = try await viewModel.createConversation(
                type: .group,
                participantIds: participantIds,
                title: groupName.isEmpty ? nil : groupName
            )
            
            // 创建成功，导航到聊天详情页面
            createdConversation = conversation
            showingChatDetail = true
            
        } catch {
            viewModel.errorMessage = "创建群聊失败: \(error.localizedDescription)"
            viewModel.showError = true
        }
    }
}





// MARK: - 预览
#Preview {
    NewChatView()
}
