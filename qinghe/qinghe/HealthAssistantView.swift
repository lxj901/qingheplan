import SwiftUI

/// 健康助手页面（青禾）
struct HealthAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inputText: String = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var showingSidebar: Bool = false
    // 导航与弹窗状态
    @State private var showingTongue = false
    @State private var showingFace = false
    @State private var showingHealthRecord = false
    @State private var showingSleepDashboard = false
    @State private var showingReportTypePicker = false
    @State private var showingReportDatePicker = false
    @State private var selectedReportDate: Date = Date()
    // 导航到体质分析报告页面
    @State private var showingConstitutionReport = false
    @State private var navConstitutionData: ConstitutionAnalysisData = .sample
    @State private var selectedReportSource: ReportSource = .tongue
    @State private var showNoReportAlert = false
    @StateObject private var healthReportManager = HealthReportManager.shared

    // 当前对话ID
    @State private var currentConversationId: String? = nil
    @State private var hasCreatedInitialConversation = false  // 是否创建了初始对话
    @State private var appDidEnterBackground = false  // 标记 app 是否进入过后台

    // 消息列表
    @State private var messages: [ChatMessage] = []
    @State private var displayedText: String = "" // 用于打字机效果的文本
    @State private var isTyping: Bool = false // 是否正在打字
    @State private var showingActionMenu: Bool = false // 是否显示操作菜单
    @FocusState private var isInputFocused: Bool // 输入框焦点状态
    @State private var keyboardHeight: CGFloat = 0 // 键盘高度
    @State private var isSendingMessage: Bool = false // 是否正在发送消息
    @State private var loadingRotation: Double = 0 // 加载动画旋转角度
    // 帖子详情页 sheet
    @State private var showingPostDetail = false
    @State private var selectedPostId: String? = nil
    // 历史对话详情页
    @State private var showingConversationHistory = false
    @State private var selectedConversationId: String? = nil
    // 使用单例获取 TabBar 可见性，避免环境注入缺失导致崩溃
    
    // 会员中心相关状态
    @State private var showingMembershipAlert = false
    @State private var showingMembershipCenter = false
    @State private var membershipAlertMessage = ""

    // 消息数据模型
    struct ChatMessage: Identifiable, Equatable {
        let id = UUID()
        let content: String
        let isUser: Bool
        let timestamp: Date

        static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
            lhs.id == rhs.id
        }
    }

    var body: some View {
        mainContentView
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingActionMenu)
        // 顶部导航栏（使用 safeAreaInset，更符合 SwiftUI 推荐方式）
        .safeAreaInset(edge: .top) { topNavigationBar(opacity: navOpacity) }
        .preferredColorScheme(.light) // 健康助手页面不适配深色模式
        // 侧边栏
        .overlay(alignment: .trailing) {
            ZStack(alignment: .trailing) {
                if showingSidebar {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingSidebar = false
                            }
                        }
                        .transition(.opacity)

                    ConversationSidebarView(
                        isPresented: $showingSidebar,
                        selectedConversationId: $selectedConversationId,
                        showingConversationHistory: $showingConversationHistory
                    )
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingSidebar)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingActionMenu)
        // 监听键盘事件
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                keyboardHeight = keyboardFrame.cgRectValue.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        // 点击任意位置收起键盘
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                isInputFocused = false
            }
        )
        // 隐藏系统导航栏
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .asRootView() // 显示底部Tab栏（健康助手是Tab栏的一个根页面）
        // 帖子详情页 sheet
        .sheet(isPresented: $showingPostDetail) {
            if let postId = selectedPostId {
                NavigationStack {
                    PostDetailView(postId: postId, isSheetPresentation: true)
                        .navigationBarHidden(true)
                }
            }
        }
        // 历史对话详情页 - 全屏展示
        .fullScreenCover(isPresented: $showingConversationHistory) {
            if let conversationId = selectedConversationId {
                NavigationStack {
                    ConversationHistoryDetailView(conversationId: conversationId)
                }
            }
        }
        // 全屏导航到各个页面
        .fullScreenCover(isPresented: $showingTongue) {
            NavigationStack {
                TongueDiagnosisView(mode: .tongue)
            }
        }
        .fullScreenCover(isPresented: $showingFace) {
            NavigationStack {
                TongueDiagnosisView(mode: .face)
            }
        }
        .fullScreenCover(isPresented: $showingHealthRecord) {
            NavigationStack {
                HealthRecordView()
            }
        }
        .fullScreenCover(isPresented: $showingConstitutionReport) {
            NavigationStack {
                ConstitutionAnalysisReportView(data: navConstitutionData)
            }
        }
        .fullScreenCover(isPresented: $showingSleepDashboard) {
            NavigationStack {
                SleepDashboardView()
            }
        }
        // 第一步：选择报告来源（舌诊/面诊）
        .sheet(isPresented: $showingReportTypePicker) {
            ReportSourcePickerSheet(
                selected: selectedReportSource,
                onClose: { showingReportTypePicker = false },
                onPick: { source in
                    selectedReportSource = source
                    showingReportTypePicker = false
                    // 下一步选择日期/记录
                    showingReportDatePicker = true
                }
            )
            .presentationDetents([.height(220)])
        }
        // 选择日期查看报告
        .sheet(isPresented: $showingReportDatePicker) {
            RecordPickerSheet(
                source: selectedReportSource,
                onCancel: { showingReportDatePicker = false },
                onPickRecord: { recordId in
                    Task {
                        do {
                            switch selectedReportSource {
                            case .tongue:
                                print("🔍 正在获取舌诊详情（v2格式），ID: \(recordId)")
                                let detail = try await HealthProfileAPIService.shared.getTongueAnalysisDetail(id: String(recordId))
                                print("✅ 舌诊详情获取成功（v2格式）")
                                let converted = convertV2ToConstitution(detail)
                                await MainActor.run {
                                    navConstitutionData = converted
                                    showingConstitutionReport = true
                                }
                            case .face:
                                print("🔍 正在获取面诊详情（v2格式），ID: \(recordId)")
                                let detail = try await HealthProfileAPIService.shared.getFaceAnalysisDetail(id: String(recordId))
                                print("✅ 面诊详情获取成功（v2格式）")
                                let converted = convertV2ToConstitution(detail)
                                await MainActor.run {
                                    navConstitutionData = converted
                                    showingConstitutionReport = true
                                }
                            }
                        } catch {
                            print("❌ 获取诊断详情失败: \(error)")
                            // 检查是否是网络错误或API错误
                            if let nsError = error as NSError? {
                                print("❌ 错误详情 - Domain: \(nsError.domain), Code: \(nsError.code), Description: \(nsError.localizedDescription)")
                            }
                            await MainActor.run {
                                showNoReportAlert = true
                                print("⚠️ 显示无报告提示")
                            }
                        }
                        await MainActor.run { showingReportDatePicker = false }
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
        // 无报告提示
        .alert("提示", isPresented: $showNoReportAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("该日没有报告")
        }
        // 会员升级提示
        .alert("使用次数已达上限", isPresented: $showingMembershipAlert) {
            Button("升级会员", role: .none) {
                showingMembershipCenter = true
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(membershipAlertMessage)
        }
        // 导航到会员中心
        .navigationDestination(isPresented: $showingMembershipCenter) {
            MembershipCenterView()
                .asSubView()
        }
        // 监听 app 进入后台
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            print("📱 App 进入后台")
            appDidEnterBackground = true
        }
        // 监听 app 从后台返回,只有真正从后台返回时才创建新对话
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if appDidEnterBackground {
                print("📱 App 从后台返回,创建新对话")
                appDidEnterBackground = false
                createNewConversation()
            } else {
                print("📱 App 前台切换,不创建新对话")
            }
        }
        // 首次加载时创建对话
        .onAppear {
            if !hasCreatedInitialConversation {
                hasCreatedInitialConversation = true
                print("📱 首次加载健康助手页面,创建初始对话")
                createNewConversation()
            }
        }
        // 不再预加载日期型报告,避免误触发旧接口日志
    }

    // MARK: - 主内容视图
    private var mainContentView: some View {
        ZStack(alignment: .top) {
            backgroundView
            contentStackView
        }
    }

    // MARK: - 背景视图
    private var backgroundView: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            AssistantTopGradient()
                .ignoresSafeArea()
        }
    }

    // MARK: - 内容堆栈视图
    private var contentStackView: some View {
        VStack(spacing: 0) {
            scrollableContentView
            Spacer(minLength: 0)
            actionMenuView
            inputBarView
        }
    }

    // MARK: - 可滚动内容视图
    private var scrollableContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                scrollOffsetTracker
                headerWithCard
                messagesListView
                Color.clear.frame(height: 24)
                Color.clear.frame(height: 480)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .coordinateSpace(name: "assistantScroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            print("📍 assistantScroll offset updated: \(value)")
            DispatchQueue.main.async {
                scrollOffset = value
            }
        }
    }

    // MARK: - 滚动偏移追踪器
    private var scrollOffsetTracker: some View {
        Color.clear
            .frame(height: 1)
            .background(
                GeometryReader { g in
                    let y = g.frame(in: .named("assistantScroll")).minY
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: y)
                        .onAppear {
                            print("📍 健康助手滚动监听器初始化，初始Y值: \(y)")
                        }
                        .onChange(of: y) { newValue in
                            print("📈 健康助手滚动监听器检测到变化: -> \(newValue)")
                            DispatchQueue.main.async {
                                scrollOffset = newValue
                                print("✅ scrollOffset 已更新为: \(newValue)")
                            }
                        }
                }
            )
    }

    // MARK: - 头部和卡片
    private var headerWithCard: some View {
        Group {
            headerSection
                .padding(.horizontal, 20)
                .padding(.top, -10)

            DailySelfDisciplineCard(
                suggestions: healthSuggestions,
                onTapSuggestion: { index in
                    // 点击提示语时发送消息
                    let suggestion = healthSuggestions[index]
                    inputText = suggestion
                    sendMessage()
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, -42)
        }
    }

    // MARK: - 健康咨询提示语
    private let healthSuggestions = [
        "怎么判断自己是否气血充足？",
        "便秘时不能吃什么水果？",
        "为什么年龄越大脸越大？",
        "如何改善睡眠质量？",
        "经常熬夜对身体有什么危害？",
        "如何科学减肥不反弹？",
        "怎样判断自己是否湿气重？",
        "长期久坐如何缓解腰痛？"
    ]

    // MARK: - 消息列表视图
    private var messagesListView: some View {
        Group {
            if !messages.isEmpty || isTyping {
                VStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            displayedText: (message == messages.last && isTyping) ? displayedText : message.content,
                            isTyping: message == messages.last && isTyping,
                            onLinkTap: handleLinkTap
                        )
                        .id(message.id)
                    }

                    if isSendingMessage {
                        loadingIndicatorView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
    }

    // MARK: - 加载指示器视图
    private var loadingIndicatorView: some View {
        HStack(alignment: .top, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        Color(hex: "1F774E"),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 16, height: 16)
                    .rotationEffect(Angle(degrees: loadingRotation))
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 1.0)
                                .repeatForever(autoreverses: false)
                        ) {
                            loadingRotation = 360
                        }
                    }

                Text("思考中...")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "1F774E"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(hex: "E0E0E0"), lineWidth: 1)
            )

            Spacer(minLength: 50)
        }
        .onDisappear {
            loadingRotation = 0
        }
    }

    // MARK: - 操作菜单视图
    private var actionMenuView: some View {
        Group {
            if showingActionMenu {
                ActionMenu(
                    onTapTongue: {
                        showingTongue = true
                        showingActionMenu = false
                    },
                    onTapFace: {
                        showingFace = true
                        showingActionMenu = false
                    },
                    onTapReport: {
                        showingReportTypePicker = true
                        showingActionMenu = false
                    },
                    onTapProfile: {
                        showingHealthRecord = true
                        showingActionMenu = false
                    },
                    onTapSleep: {
                        showingSleepDashboard = true
                        showingActionMenu = false
                    },
                    onTapConversation: {
                        showingSidebar = true
                        showingActionMenu = false
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - 输入栏视图
    private var inputBarView: some View {
        VStack(spacing: 0) {
            ChatInputBar(
                text: $inputText,
                onSend: {
                    sendMessage()
                },
                showingActionMenu: $showingActionMenu,
                isInputFocused: $isInputFocused
            )
        }
        .padding(.bottom, bottomSafeAreaInset)
    }

    // MARK: - 创建新对话
    private func createNewConversation() {
        Task {
            do {
                print("🔄 正在创建新对话...")
                let response = try await HealthChatAPIService.shared.createNewConversation()
                if let data = response.data {
                    currentConversationId = data.conversationId
                    print("✅ 新对话创建成功: \(data.conversationId)")

                    // 清空旧消息
                    await MainActor.run {
                        messages.removeAll()
                    }

                    // 添加欢迎消息并启动打字机效果
                    if let welcomeMsg = data.welcomeMessage {
                        print("📝 欢迎消息内容：")
                        print(welcomeMsg)
                        print("📏 欢迎消息长度: \(welcomeMsg.count) 字符")

                        let message = ChatMessage(
                            content: welcomeMsg,
                            isUser: false,
                            timestamp: Date()
                        )
                        await MainActor.run {
                            messages.append(message)
                        }
                        print("✅ 已添加欢迎消息，开始打字机效果")

                        // 启动打字机效果
                        await startTypingEffect(for: welcomeMsg)
                    }
                }
            } catch {
                print("❌ 创建新对话失败: \(error)")
            }
        }
    }

    // MARK: - 底部安全区域（仅考虑TabBar，不处理键盘）
    private var bottomSafeAreaInset: CGFloat {
        // 键盘弹起时，不添加额外的 padding，让系统自动处理
        if keyboardHeight > 0 {
            return 0
        }
        // 键盘收起时，考虑 TabBar
        if TabBarVisibilityManager.shared.isTabBarVisible {
            let contentH = max(0, TabBarVisibilityManager.shared.tabBarContentHeight)
            return getSafeAreaBottom() + contentH + 14
        }
        return getSafeAreaBottom()
    }

    private func getSafeAreaBottom() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 34 // iPhone 带Home Indicator的典型安全区
        }
        return window.safeAreaInsets.bottom
    }

    // MARK: - 打字机效果（优化版：批量更新减少渲染次数）
    private func startTypingEffect(for text: String) async {
        await MainActor.run {
            displayedText = ""
            isTyping = true
        }

        let characters = Array(text)
        let batchSize = 3 // 每次更新3个字符，减少渲染频率
        var currentIndex = 0

        while currentIndex < characters.count {
            let endIndex = min(currentIndex + batchSize, characters.count)
            let batch = characters[currentIndex..<endIndex]

            // 批量添加字符（在主线程更新）
            await MainActor.run {
                for char in batch {
                    displayedText.append(char)
                }
            }

            currentIndex = endIndex

            // 只有不是最后一批才延迟
            if currentIndex < characters.count {
                // 根据批次大小调整延迟
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05秒
            }
        }

        await MainActor.run {
            isTyping = false
            print("✅ 打字机效果完成，最终显示文本长度: \(displayedText.count) 字符")
            print("📝 最终显示文本内容：")
            print(displayedText)
        }
    }

    // MARK: - 发送消息
    private func sendMessage() {
        let messageContent = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageContent.isEmpty else { return }

        // 清空输入框
        inputText = ""

        // 添加用户消息到列表
        let userMessage = ChatMessage(
            content: messageContent,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)

        // 显示加载状态
        isSendingMessage = true

        // 调用 API 发送消息
        Task {
            do {
                print("📤 正在发送消息: \(messageContent)")
                let response = try await HealthChatAPIService.shared.sendMessage(
                    message: messageContent,
                    conversationId: currentConversationId
                )

                if let data = response.data {
                    print("✅ 消息发送成功，jobId: \(data.jobId ?? "无")")

                    // 如果有 jobId，需要轮询任务状态获取 AI 响应
                    if let jobId = data.jobId {
                        await pollJobStatus(jobId: jobId)
                    } else if let aiResponse = data.response {
                        // 直接返回了响应
                        await MainActor.run {
                            isSendingMessage = false
                        }
                        await addAIMessage(aiResponse)
                    }
                }
            } catch {
                print("❌ 发送消息失败: \(error)")
                // 隐藏加载状态
                await MainActor.run {
                    isSendingMessage = false
                }
                
                // 检查是否为403错误且消息包含使用次数限制
                if let networkError = error as? NetworkManager.NetworkError,
                   case .serverMessage(let message) = networkError,
                   message.contains("使用次数已达上限") || message.contains("升级会员") {
                    // 显示会员升级提示
                    await MainActor.run {
                        membershipAlertMessage = message
                        showingMembershipAlert = true
                    }
                } else {
                    // 添加错误提示消息
                    await MainActor.run {
                        let errorMessage = ChatMessage(
                            content: "抱歉，消息发送失败，请稍后重试。",
                            isUser: false,
                            timestamp: Date()
                        )
                        messages.append(errorMessage)
                    }
                }
            }
        }
    }

    // MARK: - 轮询任务状态
    private func pollJobStatus(jobId: String) async {
        var attempts = 0
        let maxAttempts = 30 // 最多轮询30次（约30秒）

        while attempts < maxAttempts {
            do {
                let statusResponse = try await HealthChatAPIService.shared.getJobStatus(jobId: jobId)

                if let data = statusResponse.data {
                    print("📊 任务状态: \(data.status)")

                    switch data.status.lowercased() {
                    case "completed":
                        // 任务完成，提取 AI 回复
                        // 优先使用 result.aiReply，否则使用 response
                        let aiResponse = data.result?.aiReply ?? data.response
                        if let aiResponse = aiResponse {
                            print("✅ AI响应完成")
                            print("📝 AI回复原始内容:")
                            print("====================")
                            print(aiResponse)
                            print("====================")
                            await MainActor.run {
                                isSendingMessage = false
                            }
                            await addAIMessage(aiResponse)
                        } else {
                            print("⚠️ 任务完成但没有响应内容")
                            await MainActor.run {
                                isSendingMessage = false
                            }
                        }
                        return
                    case "failed", "error":
                        print("❌ AI响应失败: \(data.error ?? "未知错误")")
                        await MainActor.run {
                            isSendingMessage = false
                        }
                        await addAIMessage("抱歉，处理您的问题时出现了错误，请稍后重试。")
                        return
                    case "processing", "active", "pending":
                        // 继续轮询
                        print("⏳ AI正在处理中... (状态: \(data.status))")
                    default:
                        print("⚠️ 未知状态: \(data.status)")
                        break
                    }
                }

                // 等待1秒后继续轮询
                try await Task.sleep(nanoseconds: 1_000_000_000)
                attempts += 1
            } catch {
                print("❌ 轮询任务状态失败: \(error)")
                await MainActor.run {
                    isSendingMessage = false
                }
                await addAIMessage("抱歉，获取响应时出现了错误，请稍后重试。")
                return
            }
        }

        // 超时
        print("⏰ 轮询超时")
        await MainActor.run {
            isSendingMessage = false
        }
        await addAIMessage("抱歉，响应超时，请稍后重试。")
    }

    // MARK: - 添加 AI 消息
    private func addAIMessage(_ content: String) async {
        await MainActor.run {
            // 处理可能的转义字符，将 \n 转换为真正的换行符
            let processedContent = content
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\\t", with: "\t")
            
            print("📝 处理后的AI回复内容:")
            print("====================")
            print(processedContent)
            print("====================")
            
            let aiMessage = ChatMessage(
                content: processedContent,
                isUser: false,
                timestamp: Date()
            )
            messages.append(aiMessage)

            // 启动打字机效果
            Task {
                await startTypingEffect(for: processedContent)
            }
        }
    }

    // MARK: - 操作菜单
    private struct ActionMenu: View {
        var onTapTongue: () -> Void
        var onTapFace: () -> Void
        var onTapReport: () -> Void
        var onTapProfile: () -> Void
        var onTapSleep: () -> Void
        var onTapConversation: () -> Void

        var body: some View {
            VStack(spacing: 12) {
                // 第一行
                HStack(spacing: 12) {
                    menuItem(icon: "camera.macro", iconColor: Color(hex: "6C63FF"), title: "舌诊", action: onTapTongue)
                    menuItem(icon: "face.smiling", iconColor: Color(hex: "34C759"), title: "面诊", action: onTapFace)
                    menuItem(icon: "doc.text.magnifyingglass", iconColor: Color(hex: "6C63FF"), title: "体质报告", action: onTapReport)
                }

                // 第二行
                HStack(spacing: 12) {
                    menuItem(icon: "person.text.rectangle", iconColor: Color(hex: "6C63FF"), title: "健康档案", action: onTapProfile)
                    menuItem(icon: "bed.double.fill", iconColor: Color(hex: "FF9500"), title: "睡眠管理", action: onTapSleep)
                    menuItem(icon: "bubble.left.and.bubble.right.fill", iconColor: Color(hex: "1F774E"), title: "对话管理", action: onTapConversation)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.7), lineWidth: 0.8)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -5)
            )
        }

        private func menuItem(icon: String, iconColor: Color, title: String, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(iconColor)
                    }
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "121A2D"))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 选择报告来源
    private enum ReportSource { case tongue, face }

    private struct ReportSourcePickerSheet: View {
        var selected: ReportSource
        var onClose: () -> Void
        var onPick: (ReportSource) -> Void
        var body: some View {
            VStack(spacing: 16) {
                HStack {
                    Text("选择报告类型")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Button("关闭", action: onClose).foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                HStack(spacing: 12) {
                    pill(title: "舌诊报告", systemImage: "mouth", color: Color(hex: "6C63FF")) { onPick(.tongue) }
                    pill(title: "面诊报告", systemImage: "face.smiling", color: Color(hex: "34C759")) { onPick(.face) }
                }
                .padding(.horizontal, 16)
                Spacer(minLength: 0)
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        private func pill(title: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                HStack(spacing: 10) {
                    Image(systemName: systemImage).foregroundColor(color)
                    Text(title).foregroundColor(Color(hex: "121A2D")).font(.system(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.7))
                        RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.7), lineWidth: 0.6)
                    }
                )
            }
            .buttonStyle(.plain)
        }
    }

    // 旧的日期选择器已移除（改为从历史记录选择具体记录）

    private struct RecordPickerSheet: View {
        var source: ReportSource
        var onCancel: () -> Void
        var onPickRecord: (Int) -> Void

        @State private var loading = true
        @State private var errorText: String? = nil
        @State private var tongue: [TongueHistoryRecord] = []
        @State private var face: [FaceHistoryRecord] = []
        @State private var selectedId: Int? = nil

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("选择日期")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Button("取消", action: onCancel).foregroundColor(.secondary)
                    Button("查看") { if let id = selectedId { onPickRecord(id) } }
                        .font(.system(size: 16, weight: .semibold))
                        .disabled(selectedId == nil)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if loading {
                    ProgressView("正在加载...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = errorText {
                    Text(err).foregroundColor(.secondary).padding(.horizontal, 16)
                    Spacer()
                } else {
                    ScrollView {
                        let baseList: [(id: Int, date: String, status: String)] = {
                            if source == .tongue {
                                return tongue.map { ($0.id, $0.analyzedAt ?? $0.created_at ?? "-", $0.analysisStatus) }
                            } else {
                                return face.map { ($0.id, $0.analyzedAt ?? $0.created_at ?? "-", $0.analysisStatus) }
                            }
                        }()
                        // 仅保留已完成的记录，按时间倒序列出每条记录
                        let completed = baseList.filter { $0.status.lowercased() == "completed" }
                            .sorted { ($0.date) > ($1.date) }
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(completed.indices, id: \.self) { idx in
                                let item = completed[idx]
                                selectableRow(id: item.id, dateText: item.date)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .task { await load() }
        }

        private func selectableRow(id: Int, dateText: String) -> some View {
            let isSel = selectedId == id
            return HStack(spacing: 12) {
                Image(systemName: isSel ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSel ? Color(hex: "6C63FF") : .secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateText).font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "121A2D"))
                }
                Spacer()
            }
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.8))
                    RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.7), lineWidth: 0.6)
                }
            )
            .onTapGesture { selectedId = id }
        }

        private func format(_ text: String) -> String {
            // 尝试提取 yyyy-MM-dd
            let comps = text.split(separator: " ")
            return String(comps.first ?? Substring(text))
        }

        private func load() async {
            loading = true
            do {
                switch source {
                case .tongue:
                    print("🔍 正在加载舌诊历史记录...")
                    tongue = try await HealthProfileAPIService.shared.getTongueHistory()
                    print("✅ 舌诊历史记录加载成功，共 \(tongue.count) 条记录")
                    if tongue.isEmpty {
                        print("⚠️ 舌诊历史记录为空")
                    }
                case .face:
                    print("🔍 正在加载面诊历史记录...")
                    face = try await HealthProfileAPIService.shared.getFaceHistory()
                    print("✅ 面诊历史记录加载成功，共 \(face.count) 条记录")
                    if face.isEmpty {
                        print("⚠️ 面诊历史记录为空")
                    }
                }
                loading = false
            } catch {
                print("❌ 加载历史记录失败: \(error)")
                if let nsError = error as NSError? {
                    print("❌ 错误详情 - Domain: \(nsError.domain), Code: \(nsError.code), Description: \(nsError.localizedDescription)")
                }
                errorText = "加载历史记录失败: \(error.localizedDescription)"
                loading = false
            }
        }
    }

    // MARK: - 报告 -> 体质分析数据转换
    private func convertReportToConstitution(_ report: HealthReportData) -> ConstitutionAnalysisData {
        if let constitution = report.detailedAnalysis?.constitution,
           let analysisReport = constitution.analysisReport {
            let defaultOrganDistribution: [String: Double] = ["心": 0.8, "肝": 0.7, "脾": 0.9, "肺": 0.8, "肾": 0.7]
            let defaultNineScores: [String: Double] = [
                "平和质": constitution.confidence,
                "气虚质": 0.2, "阳虚质": 0.1, "阴虚质": 0.3,
                "痰湿质": 0.2, "湿热质": 0.1, "血瘀质": 0.2,
                "气郁质": 0.1, "特禀质": 0.1
            ]
            return ConstitutionAnalysisData(
                hasAnalysis: true,
                primaryConstitution: analysisReport.primaryConstitution.name,
                secondaryConstitution: analysisReport.secondaryConstitution.name,
                confidence: constitution.confidence,
                organDistribution: defaultOrganDistribution,
                nineConstitutionScores: defaultNineScores,
                recommendations: analysisReport.recommendations.lifestyle,
                score: Int(constitution.confidence * 100),
                physiqueName: analysisReport.primaryConstitution.name,
                physiqueAnalysis: analysisReport.primaryConstitution.description,
                typicalSymptom: analysisReport.primaryConstitution.characteristics?.first ?? "暂无特征",
                riskWarning: analysisReport.riskFactors.first ?? "暂无风险提示",
                features: [],
                syndromeName: analysisReport.primaryConstitution.name,
                syndromeIntroduction: analysisReport.summary,
                tfDetectMatches: [],
                adviceSections: [],
                goods: []
            )
        }
        // 兜底
        return ConstitutionAnalysisData.sample
    }

    // MARK: - 体质数据转换（从v2完整数据到报告页数据）
    private func convertV2ToConstitution(_ d: ActualAnalysisResponse.AnalysisData) -> ConstitutionAnalysisData {
        print("🔄 开始转换v2数据到体质分析数据")
        print("📊 原始数据 - 评分: \(d.score), 体质: \(d.physiqueName)")
        print("📊 特征数量: \(d.features.count), 体质分布数量: \(d.physiqueDistribution.count)")

        // 转换特征数据
        let features = d.features.map { f in
            DiagnosisFeature(
                name: f.name,
                value: f.value,
                description: f.desc,
                status: f.status == "正常" ? .normal : .abnormal
            )
        }
        print("✅ 转换了 \(features.count) 个特征")

        // 转换九大体质分布
        var nineScores: [String: Double] = [:]
        for item in d.physiqueDistribution {
            nineScores[item.name] = Double(item.score) / 100.0
        }
        
        // 如果后端没有返回体质分布数据，则根据主体质生成默认分布
        if nineScores.isEmpty {
            nineScores = generateNineConstitutionScores(
                from: d.primaryConstitution?.name ?? d.physiqueName,
                secondaryConstitutions: d.secondaryConstitutions
            )
            print("⚠️ 后端未返回体质分布，已生成默认分布")
        }
        print("✅ 转换了 \(nineScores.count) 个体质分布: \(nineScores)")

        // 转换调理建议
        var adviceSections: [AdviceSection] = []

        // 饮食建议
        if let dietAdvice = d.advices["饮食建议"] {
            var entries: [AdviceEntry] = []
            if let recommendedArray = dietAdvice.dictionary?["推荐"] {
                entries.append(AdviceEntry(label: "推荐", value: recommendedArray.joined(separator: "、")))
            }
            if let avoidArray = dietAdvice.dictionary?["禁忌"] {
                entries.append(AdviceEntry(label: "禁忌", value: avoidArray.joined(separator: "、")))
            }
            if !entries.isEmpty {
                adviceSections.append(AdviceSection(title: "饮食建议", entries: entries))
            }
        }

        // 食疗方
        if let therapyAdvice = d.advices["食疗方"], let therapyArray = therapyAdvice.stringArray {
            let entries = [AdviceEntry(label: "食疗方", value: therapyArray.joined(separator: "\n"))]
            adviceSections.append(AdviceSection(title: "食疗方", entries: entries))
        }

        // 运动建议
        if let exerciseAdvice = d.advices["运动建议"], let exerciseArray = exerciseAdvice.stringArray {
            let entries = [AdviceEntry(label: "运动", value: exerciseArray.joined(separator: "、"))]
            adviceSections.append(AdviceSection(title: "运动建议", entries: entries))
        }

        // 睡眠起居
        if let sleepAdvice = d.advices["睡眠/起居"], let sleepArray = sleepAdvice.stringArray {
            let entries = [AdviceEntry(label: "起居", value: sleepArray.joined(separator: "\n"))]
            adviceSections.append(AdviceSection(title: "睡眠/起居", entries: entries))
        }

        // 情志调节
        if let emotionAdvice = d.advices["情志调节"], let emotionArray = emotionAdvice.stringArray {
            let entries = [AdviceEntry(label: "情志", value: emotionArray.joined(separator: "、"))]
            adviceSections.append(AdviceSection(title: "情志调节", entries: entries))
        }

        // 音乐疗法
        if let musicAdvice = d.advices["音乐疗法"], let musicArray = musicAdvice.stringArray {
            let entries = [AdviceEntry(label: "音乐", value: musicArray.joined(separator: "、"))]
            adviceSections.append(AdviceSection(title: "音乐疗法", entries: entries))
        }

        // 中医调理
        if let tcmAdvice = d.advices["中医调理"], let tcmArray = tcmAdvice.stringArray {
            let entries = [AdviceEntry(label: "调理", value: tcmArray.joined(separator: "\n"))]
            adviceSections.append(AdviceSection(title: "中医调理", entries: entries))
        }

        print("✅ 转换了 \(adviceSections.count) 个调理建议章节")

        // 转换舌象检测坐标（如果有）
        var tfMatches: [TongueFeatureMatch] = []
        if let tf = d.tfDetectMatches,
           let x = tf.x, let y = tf.y, let w = tf.w, let h = tf.h {
            tfMatches.append(TongueFeatureMatch(
                x: x,
                y: y,
                width: w,
                height: h
            ))
            print("✅ 转换了舌象检测坐标")
        }
        
        // 生成脏腑分布数据
        let organDistribution = generateOrganDistribution(
            from: d.primaryConstitution?.name ?? d.physiqueName,
            features: d.features
        )
        print("✅ 生成了脏腑分布数据: \(organDistribution)")

        let result = ConstitutionAnalysisData(
            hasAnalysis: true,
            primaryConstitution: d.primaryConstitution?.name ?? d.physiqueName,
            secondaryConstitution: d.secondaryConstitutions.first?.name ?? "",
            confidence: d.primaryConstitution?.confidence ?? 0.82,
            organDistribution: organDistribution,
            nineConstitutionScores: nineScores,
            recommendations: [], // 已转换为adviceSections
            score: d.score,
            physiqueName: d.physiqueName,
            physiqueAnalysis: d.physiqueAnalysis,
            typicalSymptom: d.typicalSymptom,
            riskWarning: d.riskWarning,
            features: features,
            syndromeName: d.syndromeName,
            syndromeIntroduction: d.syndromeIntroduction,
            tfDetectMatches: tfMatches,
            adviceSections: adviceSections,
            goods: d.goods
        )

        print("✅ v2数据转换完成")
        print("📊 最终数据 - hasAnalysis: \(result.hasAnalysis)")
        print("📊 特征: \(result.features.count), 建议: \(result.adviceSections.count), 体质分布: \(result.nineConstitutionScores.count)")

        return result
    }
    
    // MARK: - 生成脏腑分布数据
    private func generateOrganDistribution(from constitution: String, features: [ActualAnalysisResponse.Feature]) -> [String: Double] {
        var distribution: [String: Double] = [
            "心": 0.3, "肝": 0.3, "脾": 0.3, "肺": 0.3, "肾": 0.3
        ]
        
        // 根据体质特点调整脏腑分布（增大差异以便观察）
        switch constitution {
        case let c where c.contains("气虚"):
            distribution["脾"] = 0.8  // 气虚主要影响脾
            distribution["肺"] = 0.6  // 气虚也影响肺
            distribution["心"] = 0.4
            distribution["肝"] = 0.2
            distribution["肾"] = 0.3
            
        case let c where c.contains("阳虚"):
            distribution["肾"] = 0.9  // 阳虚主要影响肾
            distribution["脾"] = 0.7  // 阳虚也影响脾
            distribution["心"] = 0.5
            distribution["肝"] = 0.3
            distribution["肺"] = 0.4
            
        case let c where c.contains("阴虚"):
            distribution["肾"] = 0.8  // 阴虚主要影响肾
            distribution["心"] = 0.6  // 阴虚也影响心
            distribution["肝"] = 0.5
            distribution["脾"] = 0.3
            distribution["肺"] = 0.4
            
        case let c where c.contains("痰湿"):
            distribution["脾"] = 0.9  // 痰湿主要影响脾
            distribution["肺"] = 0.6  // 痰湿也影响肺
            distribution["肾"] = 0.5
            distribution["心"] = 0.3
            distribution["肝"] = 0.3
            
        case let c where c.contains("湿热"):
            distribution["脾"] = 0.8  // 湿热主要影响脾
            distribution["肝"] = 0.7  // 湿热也影响肝
            distribution["肺"] = 0.5
            distribution["心"] = 0.4
            distribution["肾"] = 0.3
            
        case let c where c.contains("血瘀"):
            distribution["心"] = 0.9  // 血瘀主要影响心
            distribution["肝"] = 0.8  // 血瘀也影响肝
            distribution["脾"] = 0.4
            distribution["肺"] = 0.3
            distribution["肾"] = 0.4
            
        case let c where c.contains("气郁"):
            distribution["肝"] = 0.9  // 气郁主要影响肝
            distribution["心"] = 0.6  // 气郁也影响心
            distribution["脾"] = 0.5
            distribution["肺"] = 0.4
            distribution["肾"] = 0.3
            
        case let c where c.contains("特禀"):
            distribution["肺"] = 0.7  // 特禀主要影响肺
            distribution["脾"] = 0.6  // 特禀也影响脾
            distribution["肝"] = 0.5
            distribution["心"] = 0.4
            distribution["肾"] = 0.4
            
        case let c where c.contains("平和"):
            distribution["心"] = 0.6
            distribution["肝"] = 0.5
            distribution["脾"] = 0.6
            distribution["肺"] = 0.5
            distribution["肾"] = 0.6
            
        default:
            // 默认保持适中分布，但有差异
            distribution["心"] = 0.5
            distribution["肝"] = 0.4
            distribution["脾"] = 0.5
            distribution["肺"] = 0.4
            distribution["肾"] = 0.5
        }
        
        // 根据具体特征进一步调整
        for feature in features {
            switch feature.name {
            case let n where n.contains("舌质") || n.contains("舌尖"):
                if feature.status == "异常" {
                    distribution["心"] = min(1.0, (distribution["心"] ?? 0.3) + 0.2)
                }
            case let n where n.contains("舌苔") || n.contains("脾胃"):
                if feature.status == "异常" {
                    distribution["脾"] = min(1.0, (distribution["脾"] ?? 0.3) + 0.2)
                }
            case let n where n.contains("面色") || n.contains("肝"):
                if feature.status == "异常" {
                    distribution["肝"] = min(1.0, (distribution["肝"] ?? 0.3) + 0.2)
                }
            case let n where n.contains("舌根") || n.contains("肾"):
                if feature.status == "异常" {
                    distribution["肾"] = min(1.0, (distribution["肾"] ?? 0.3) + 0.2)
                }
            default:
                break
            }
        }
        
        return distribution
    }
    
    // MARK: - 生成九种体质分布数据
    private func generateNineConstitutionScores(from primaryConstitution: String, secondaryConstitutions: [ActualAnalysisResponse.ConstitutionItem]) -> [String: Double] {
        // 九种体质的默认基础分数（较低）
        var scores: [String: Double] = [
            "平和质": 0.2,
            "气虚质": 0.15,
            "阳虚质": 0.15,
            "阴虚质": 0.15,
            "痰湿质": 0.15,
            "湿热质": 0.15,
            "血瘀质": 0.15,
            "气郁质": 0.15,
            "特禀质": 0.15
        ]
        
        // 主体质设置为高分（0.7-0.9）
        if let mainScore = scores.keys.first(where: { primaryConstitution.contains($0.replacingOccurrences(of: "质", with: "")) }) {
            scores[mainScore] = 0.85
        }
        
        // 次要体质设置为中等分数（0.4-0.6）
        for (index, item) in secondaryConstitutions.prefix(2).enumerated() {
            if let key = scores.keys.first(where: { item.name.contains($0.replacingOccurrences(of: "质", with: "")) }) {
                scores[key] = index == 0 ? 0.55 : 0.45
            }
        }
        
        // 如果主体质是"平和质"，调整其他体质分数都较低
        if primaryConstitution.contains("平和") {
            scores["平和质"] = 0.8
            for key in scores.keys where key != "平和质" {
                scores[key] = 0.1
            }
        }
        
        return scores
    }

    // 已移除：内联体质报告对话流（改为直接跳转报告页）

    // MARK: - Wrap 布局（用于建议标签）
    private struct WrapHStack<Content: View>: View {
        let spacing: CGFloat
        let lineSpacing: CGFloat
        let content: () -> Content

        init(spacing: CGFloat = 8, lineSpacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
            self.spacing = spacing
            self.lineSpacing = lineSpacing
            self.content = content
        }

        var body: some View {
            FlowLayout(spacing: spacing, lineSpacing: lineSpacing, content: content)
        }
    }

    private struct FlowLayout<Content: View>: View {
        let spacing: CGFloat
        let lineSpacing: CGFloat
        let content: () -> Content

        init(spacing: CGFloat = 8, lineSpacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
            self.spacing = spacing
            self.lineSpacing = lineSpacing
            self.content = content
        }

        var body: some View {
            GeometryReader { geo in
                generateContent(in: geo.size)
            }
            .frame(minHeight: 10)
        }

        private func generateContent(in size: CGSize) -> some View {
            var x: CGFloat = 0
            var y: CGFloat = 0
            return ZStack(alignment: .topLeading) {
                content()
                    .alignmentGuide(.leading) { d in
                        if x + d.width > size.width {
                            x = 0
                            y -= d.height + lineSpacing
                        }
                        let result = x
                        x -= d.width + spacing
                        return result
                    }
                    .alignmentGuide(.top) { d in
                        let result = y
                        return result
                    }
            }
        }
    }

    // MARK: - 头部
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hi! 我叫青禾")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(Color(hex: "131A38"))
                Text("你身边的AI健康助手")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Color(hex: "1F774E"))
                Text("24小时守护健康")
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.45))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(y: -15)

            ZStack(alignment: .top) {
                Circle().fill(.white.opacity(0.18)).frame(width: 110, height: 110)
                if let ui = UIImage(named: "health_bird") ?? UIImage(named: "test") {
                    Image(uiImage: ui).resizable().scaledToFit()
                } else {
                    Image(systemName: "figure.walk")
                        .resizable().scaledToFit().foregroundStyle(Color.white)
                }
            }
            .frame(width: 120, height: 120)
            .offset(y: -20)
        }
    }

    // MARK: - 顶部渐变（参考健康档案页面）
    private struct AssistantTopGradient: View {
        var body: some View {
            ZStack {
                // 主体线性渐变
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "C7F5C7"), location: 0.0),
                        .init(color: Color(hex: "A5E3F8"), location: 0.58),
                        .init(color: Color(hex: "F4F8FF"), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // 左上高光
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.55),
                        Color.white.opacity(0.18),
                        .clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 260
                )
                .blendMode(.screen)

                // 右上冷色晕染
                RadialGradient(
                    colors: [
                        Color(hex: "8FD9FB").opacity(0.34),
                        Color(hex: "B3E7FE").opacity(0.12),
                        .clear
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 360
                )


            }
        }
    }

    // MARK: - 顶部导航栏（渐显）
    private var navOpacity: Double {
        // 更灵敏：上滑 8pt 开始出现，约 24pt 完全显示
        let shown = max(0, min(1, Double((-(scrollOffset) - 8) / 24)))
        // 调试：打印滚动偏移和透明度
        if shown > 0 {
            print("📊 scrollOffset: \(scrollOffset), navOpacity: \(shown) ✅ 导航栏应该显示")
        }
        return shown
    }

    private func topNavigationBar(opacity: Double) -> some View {
        HStack {
            Spacer()
            // 导航栏标题（居中，使用系统动态颜色）
            Text("健康助手")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(.label))
            Spacer()
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color(.separator).opacity(0.5))
                .frame(height: 0.5)
            , alignment: .bottom
        )
        .opacity(opacity)
    }

    private func getSafeAreaTop() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 44 // 默认状态栏高度
        }
        return window.safeAreaInsets.top
    }
    
    // 处理链接点击
    private func handleLinkTap(_ urlString: String) {
        print("🔗 健康助手链接点击: \(urlString)")
        
        // 解析 qinghe://post/{postId}
        if urlString.hasPrefix("qinghe://post/") {
            let postId = urlString.replacingOccurrences(of: "qinghe://post/", with: "")
            print("📱 提取到帖子ID: \(postId)")
            
            // 设置帖子ID并显示 sheet
            selectedPostId = postId
            showingPostDetail = true
            print("✅ 准备以 sheet 方式打开帖子详情页")
        }
    }

    // MARK: - 简单卡片占位
    private func assistantCard(title: String, subtitle: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(Color(hex: "20C997").opacity(0.9)))

            Text(subtitle).font(.system(size: 16, weight: .semibold)).foregroundColor(Color(hex: "1F2A60"))
            Text(body).font(.system(size: 14)).foregroundColor(.black.opacity(0.8))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.92)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.55), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 今日自律卡片（新UI）
    private struct DailySelfDisciplineCard: View {
        var suggestions: [String]
        var onTapSuggestion: (Int) -> Void

        // 随机显示3个提示语
        @State private var displayedIndices: [Int] = []

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                header

                // 显示随机选择的提示语
                ForEach(displayedIndices, id: \.self) { index in
                    if index < suggestions.count {
                        suggestionRow(index: index, text: suggestions[index])
                            .onTapGesture { onTapSuggestion(index) }
                    }
                }

                // 刷新按钮
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            refreshSuggestions()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                            Text("换一换")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "5972FF"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(hex: "5972FF").opacity(0.1))
                        )
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(14)
            .background(panelBackground)
            .overlay(panelStroke)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 6)
            .onAppear {
                if displayedIndices.isEmpty {
                    refreshSuggestions()
                }
            }
        }

        private func refreshSuggestions() {
            // 随机选择3个不重复的索引
            let count = min(3, suggestions.count)
            displayedIndices = Array(suggestions.indices.shuffled().prefix(count))
        }

        // MARK: Header
        private var header: some View {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("健康咨询")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "1F2A60"))
                    Text("HEALTH CONSULTATION")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "1F2A60").opacity(0.55))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("今日 健康")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "1F2A60").opacity(0.7))
                    Text("\(weekdayCN(Date()))  \(dateMD(Date()))")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "1F2A60").opacity(0.45))
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 2)
        }

        private func suggestionRow(index: Int, text: String) -> some View {
            HStack(spacing: 12) {
                tagHash
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "1F2A60"))
                    .lineLimit(1)
                Spacer()
                arrowCircle
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(Color.white)
            .overlay(rowStroke)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }

        // MARK: Elements
        private var featuredBadge: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color(hex: "FF6B6B").opacity(0.95),
                            Color(hex: "FFA8A8").opacity(0.9)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Image(systemName: "gift.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 64, height: 64)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.55), lineWidth: 0.8)
            )
        }

        private var tagHash: some View {
            Text("#")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color(hex: "5972FF").opacity(0.9))
                )
        }

        private var arrowCircle: some View {
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "1F2A60").opacity(0.55))
                .frame(width: 26, height: 26)
                .background(
                    Circle().fill(Color.white.opacity(0.7))
                )
        }

        // Backgrounds
        private var panelBackground: some View {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(colors: [
                                Color.white.opacity(0.18),
                                Color(hex: "BFD9FF").opacity(0.15)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )
        }

        private var panelStroke: some View {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.35), lineWidth: 0.8)
        }

        private var rowStroke: some View {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 0.8)
        }

        // MARK: Date Utils
        private func weekdayCN(_ date: Date) -> String {
            let w = Calendar.current.component(.weekday, from: date)
            switch w { case 1: return "周日"; case 2: return "周一"; case 3: return "周二"; case 4: return "周三"; case 5: return "周四"; case 6: return "周五"; default: return "周六" }
        }
        private func dateMD(_ date: Date) -> String {
            let f = DateFormatter()
            f.dateFormat = "MM/dd"
            return f.string(from: date)
        }
    }


}

// MARK: - 对话侧边栏
struct ConversationSidebarView: View {
    @Binding var isPresented: Bool
    @Binding var selectedConversationId: String?
    @Binding var showingConversationHistory: Bool
    @StateObject private var viewModel = ConversationSidebarViewModel()

    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // 侧边栏头部
                sidebarHeader

                // 对话列表
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.conversations.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.conversations) { conversation in
                                conversationRow(conversation)
                            }
                        }
                    }
                }
            }
            .frame(width: 300)
            .frame(maxHeight: .infinity)
            .background(Color(.systemBackground))
            .onAppear {
                Task {
                    await viewModel.loadConversations()
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - 侧边栏头部
    private var sidebarHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Text("对话管理")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .padding(.top, getSafeAreaTop())
        }
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 0.5)
            , alignment: .bottom
        )
    }

    // 获取安全区域顶部高度
    private func getSafeAreaTop() -> CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return keyWindow?.safeAreaInsets.top ?? 0
    }

    // MARK: - 对话行
    private func conversationRow(_ conversation: Conversation) -> some View {
        HStack(spacing: 12) {
            // 对话信息（占据全部宽度）
            VStack(alignment: .leading, spacing: 6) {
                // 标题（显示对话主题）
                Text(conversation.title ?? "健康咨询")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // 底部信息栏
                HStack(spacing: 8) {
                    // 最后一条消息预览
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // 最后消息时间
                    Text(formatDate(conversation.lastMessageAt))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 0.5)
            , alignment: .bottom
        )
        .onTapGesture {
            viewModel.selectConversation(conversation.id) { conversationId in
                selectedConversationId = conversationId
                showingConversationHistory = true
            }
            isPresented = false
        }
    }

    // MARK: - 空状态
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)

            Text("还没有对话")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)

            Text("请返回主页开始对话")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 对话侧边栏 ViewModel
@MainActor
class ConversationSidebarViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadConversations() async {
        isLoading = true
        do {
            let response = try await HealthChatAPIService.shared.getConversationHistory(page: 1, limit: 50)
            if let data = response.data {
                conversations = data.conversations.map { item in
                    print("📅 原始日期字符串 - startedAt: \(item.startedAt), lastMessageAt: \(item.lastMessageAt)")
                    let startDate = parseDate(item.startedAt)
                    let lastDate = parseDate(item.lastMessageAt)
                    print("📅 解析后日期 - startedAt: \(startDate), lastMessageAt: \(lastDate)")
                    
                    return Conversation(
                        id: item.conversationId,
                        title: item.title,
                        lastMessage: item.lastMessage,
                        messageCount: item.messageCount,
                        startedAt: startDate,
                        lastMessageAt: lastDate
                    )
                }
                print("✅ 加载了 \(conversations.count) 条对话记录")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ 加载对话列表失败: \(error)")
        }
        isLoading = false
    }

    func createNewConversation() async {
        do {
            let response = try await HealthChatAPIService.shared.createNewConversation()
            if let data = response.data {
                print("✅ 创建新对话成功: \(data.conversationId)")
                await loadConversations()
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ 创建新对话失败: \(error)")
        }
    }

    func deleteConversation(_ id: String) async {
        do {
            try await HealthChatAPIService.shared.deleteConversation(conversationId: id)
            print("✅ 删除对话成功: \(id)")
            await loadConversations()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ 删除对话失败: \(error)")
        }
    }

    func selectConversation(_ id: String, showHistory: @escaping (String) -> Void) {
        print("选中对话: \(id)")
        showHistory(id)
    }

    private func parseDate(_ dateString: String) -> Date {
        // 尝试多种日期格式
        
        // 1. ISO8601 格式（带时区）
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // 2. 标准 ISO8601（不带毫秒）
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // 3. 常见格式："yyyy-MM-dd HH:mm:ss"
        let standardFormatter = DateFormatter()
        standardFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        standardFormatter.locale = Locale(identifier: "en_US_POSIX")
        standardFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        if let date = standardFormatter.date(from: dateString) {
            return date
        }
        
        // 4. 带 T 的格式："yyyy-MM-dd'T'HH:mm:ss"
        standardFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = standardFormatter.date(from: dateString) {
            return date
        }
        
        // 5. 时间戳（毫秒）
        if let timestamp = Double(dateString) {
            return Date(timeIntervalSince1970: timestamp / 1000)
        }
        
        // 如果所有格式都失败，打印错误并返回当前时间
        print("⚠️ 无法解析日期字符串: \(dateString)")
        return Date()
    }
}

// MARK: - 对话数据模型
struct Conversation: Identifiable, Codable {
    let id: String
    let title: String?
    let lastMessage: String?
    let messageCount: Int?
    let startedAt: Date  // 对话开始时间
    let lastMessageAt: Date  // 最后消息时间
    
    // 为了向后兼容保留 createdAt
    var createdAt: Date { startedAt }
}

// MARK: - 消息气泡组件
struct MessageBubble: View {
    let message: HealthAssistantView.ChatMessage
    let displayedText: String
    var isTyping: Bool = false
    var onLinkTap: ((String) -> Void)? = nil

    @State private var showCopyMenu = false
    @State private var copyMenuParagraphs: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if message.isUser {
                // 用户消息 - 右对齐，不占满全宽
                HStack {
                    Spacer(minLength: 50)
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(displayedText)
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(hex: "1F774E"))
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        
                        // 时间戳
                        Text(formatTime(message.timestamp))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.horizontal, 4)
                    }
                }
            } else {
                // AI 回复 - 占满全宽的白色半透明卡片
                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 8) {
                        MarkdownTextView(
                            text: displayedText,
                            isTyping: isTyping,
                            onLinkTap: onLinkTap
                        )

                        // AI 生成提示（卡片内部）
                        Text("内容由 AI 生成")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.85))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: "E0E0E0").opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .onLongPressGesture {
                        // 长按显示复制菜单
                        extractParagraphs()
                        showCopyMenu = true
                    }
                    
                    // 时间戳
                    Text(formatTime(message.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.horizontal, 4)
                }
                .sheet(isPresented: $showCopyMenu) {
                    CopyMenuView(
                        fullText: displayedText,
                        paragraphs: copyMenuParagraphs,
                        onCopy: { text in
                            copyToClipboard(text)
                            showCopyMenu = false
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }
    
    // 提取段落内容
    private func extractParagraphs() {
        let lines = displayedText.components(separatedBy: "\n")
        var paragraphs: [String] = []
        var currentParagraph = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty {
                // 空行表示段落结束
                if !currentParagraph.isEmpty {
                    paragraphs.append(currentParagraph.trimmingCharacters(in: .whitespacesAndNewlines))
                    currentParagraph = ""
                }
            } else {
                // 累积段落内容
                if !currentParagraph.isEmpty {
                    currentParagraph += "\n"
                }
                currentParagraph += line
            }
        }
        
        // 添加最后一个段落
        if !currentParagraph.isEmpty {
            paragraphs.append(currentParagraph.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        copyMenuParagraphs = paragraphs
    }
    
    // 复制到剪贴板
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        
        // 触觉反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 复制菜单视图
struct CopyMenuView: View {
    let fullText: String
    let paragraphs: [String]
    let onCopy: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedParagraphIndex: Int? = nil
    
    var body: some View {
        NavigationView {
            List {
                // 复制全文选项
                Section {
                    Button(action: {
                        onCopy(fullText)
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(Color(hex: "4A90E2"))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("复制全文")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "1F2A60"))
                                
                                Text("\(fullText.count) 字符")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 段落列表
                if !paragraphs.isEmpty {
                    Section(header: Text("选择段落复制").font(.system(size: 13, weight: .semibold))) {
                        ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                            Button(action: {
                                selectedParagraphIndex = index
                                onCopy(paragraph)
                            }) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(Color(hex: "4A90E2"))
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("段落 \(index + 1)")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(hex: "1F2A60"))
                                        
                                        Text(paragraph)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                            .lineLimit(3)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("\(paragraph.count) 字符")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedParagraphIndex == index {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(hex: "34C759"))
                                            .font(.system(size: 20))
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary.opacity(0.5))
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("复制内容")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "4A90E2"))
                }
            }
        }
    }
}

// MARK: - Markdown 文本视图组件
struct MarkdownTextView: View {
    let text: String
    var isTyping: Bool = false
    var onLinkTap: ((String) -> Void)? = nil

    // 缓存解析结果，避免重复解析
    @State private var cachedElements: [MarkdownElement] = []
    @State private var lastParsedText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(cachedElements, id: \.id) { element in
                renderElement(element)
            }
        }
        .onAppear {
            print("📱 MarkdownTextView onAppear - 文本长度: \(text.count), isTyping: \(isTyping)")
            // 初次加载时解析
            if cachedElements.isEmpty || lastParsedText != text {
                parseAndCache()
            }
        }
        .onChange(of: text) { newValue in
            print("📱 MarkdownTextView onChange - 新文本长度: \(newValue.count), isTyping: \(isTyping)")
            // 文本变化时重新解析
            parseAndCache()
        }
    }

    // 解析并缓存结果（使用防抖优化性能）
    private func parseAndCache() {
        // 避免重复解析相同的文本
        guard lastParsedText != text else {
            print("⚠️ MarkdownTextView - 跳过重复解析")
            return
        }

        lastParsedText = text

        print("🔄 MarkdownTextView - 开始解析文本，长度: \(text.count)")

        // 使用后台线程解析，避免阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async {
            let parsed = self.parseMarkdown(text)

            print("✅ MarkdownTextView - 解析完成，元素数量: \(parsed.count)")

            // 回到主线程更新UI
            DispatchQueue.main.async {
                self.cachedElements = parsed
                print("✅ MarkdownTextView - UI 已更新，缓存元素数量: \(self.cachedElements.count)")
            }
        }
    }
    
    // 渲染单个元素
    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element.type {
        case .heading2:
            Text(element.content)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "1F2A60"))
                .lineSpacing(6)
                .padding(.top, 4)
        
        case .heading3:
            Text(element.content)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1F2A60"))
                .lineSpacing(6)
                .padding(.top, 2)
        
        case .listItem:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "4A90E2"))
                    .padding(.top, 2)
                
                renderInlineContent(element.content)
                
                Spacer(minLength: 0)
            }
        
        case .numberedListItem:
            HStack(alignment: .top, spacing: 8) {
                Text("\(element.listNumber ?? 1).")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "4A90E2"))
                    .frame(width: 20, alignment: .leading)
                
                renderInlineContent(element.content)
                
                Spacer(minLength: 0)
            }
        
        case .paragraph:
            renderInlineContent(element.content)
        
        case .table:
            renderTable(element.tableData ?? [])
        }
    }
    
    // 渲染内联内容（支持粗体、斜体、链接等格式）
    // 使用单一 Text 视图提升性能，链接通过 AttributedString 实现
    @ViewBuilder
    private func renderInlineContent(_ text: String) -> some View {
        let segments = parseInlineSegments(text)
        
        // 构建 AttributedString
        let attributedText = buildAttributedString(from: segments)
        
        // 使用单一 Text 视图渲染，性能更好
        Text(attributedText)
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "1F2A60"))
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 2)
            .environment(\.openURL, OpenURLAction { url in
                // 拦截链接点击
                if url.scheme == "qinghe" {
                    onLinkTap?(url.absoluteString)
                    return .handled
                }
                return .systemAction
            })
    }
    
    // 构建 AttributedString（支持样式和可点击链接）
    private func buildAttributedString(from segments: [InlineSegment]) -> AttributedString {
        var result = AttributedString()
        
        for segment in segments {
            var segmentText = AttributedString(segment.text)
            
            switch segment.type {
            case .bold:
                segmentText.font = .system(size: 16, weight: .bold)
            case .italic:
                segmentText.font = .system(size: 16).italic()
            case .plain:
                segmentText.font = .system(size: 16)
            case .link:
                segmentText.font = .system(size: 16)
                segmentText.foregroundColor = Color(hex: "4A90E2")
                segmentText.underlineStyle = .single
                // 添加链接
                if let urlString = segment.url, let url = URL(string: urlString) {
                    segmentText.link = url
                }
            }
            
            result.append(segmentText)
        }
        
        return result
    }
    
    // 解析内联片段（返回可点击的片段）
    private func parseInlineSegments(_ text: String) -> [InlineSegment] {
        var segments: [InlineSegment] = []
        var currentText = ""
        var i = text.startIndex
        
        while i < text.endIndex {
            // 检查链接 [text](url)
            if text[i] == "[", let linkEnd = findLinkEnd(in: text, from: i) {
                // 添加之前的文本
                if !currentText.isEmpty {
                    segments.append(InlineSegment(type: .plain, text: currentText))
                    currentText = ""
                }
                
                // 提取链接文本和 URL
                let linkStart = text.index(after: i)
                let substring = text[linkStart..<linkEnd]
                let textEnd = substring.firstIndex(of: "]") ?? linkStart
                let linkText = String(text[linkStart..<textEnd])
                
                let urlStart = text.index(textEnd, offsetBy: 2)
                let urlString = String(text[urlStart..<linkEnd])
                
                segments.append(InlineSegment(type: .link, text: linkText, url: urlString))
                
                i = text.index(after: linkEnd)
                continue
            }
            
            // 检查粗体 **text**
            if text[i] == "*", i < text.index(before: text.endIndex), text[text.index(after: i)] == "*" {
                let searchStart = text.index(i, offsetBy: 2)
                if let endIndex = text[searchStart...].firstIndex(where: { $0 == "*" }),
                   endIndex < text.index(before: text.endIndex),
                   text[text.index(after: endIndex)] == "*" {
                    // 添加之前的文本
                    if !currentText.isEmpty {
                        segments.append(InlineSegment(type: .plain, text: currentText))
                        currentText = ""
                    }
                    
                    // 添加粗体文本
                    let boldText = String(text[searchStart..<endIndex])
                    segments.append(InlineSegment(type: .bold, text: boldText))
                    
                    i = text.index(endIndex, offsetBy: 2)
                    continue
                }
            }
            
            // 检查斜体 *text*
            if text[i] == "*" {
                let searchStart = text.index(after: i)
                if let endIndex = text[searchStart...].firstIndex(of: "*") {
                    // 添加之前的文本
                    if !currentText.isEmpty {
                        segments.append(InlineSegment(type: .plain, text: currentText))
                        currentText = ""
                    }
                    
                    // 添加斜体文本
                    let italicText = String(text[searchStart..<endIndex])
                    segments.append(InlineSegment(type: .italic, text: italicText))
                    
                    i = text.index(after: endIndex)
                    continue
                }
            }
            
            currentText.append(text[i])
            i = text.index(after: i)
        }
        
        if !currentText.isEmpty {
            segments.append(InlineSegment(type: .plain, text: currentText))
        }
        
        return segments
    }
    
    // 解析内联 Markdown（粗体、斜体、链接）- 保留用于 Text 组合
    @ViewBuilder
    private func parseInlineMarkdown(_ text: String) -> Text {
        var result = Text("")
        var currentText = ""
        var i = text.startIndex
        
        while i < text.endIndex {
            // 检查链接 [text](url)
            if text[i] == "[", let linkEnd = findLinkEnd(in: text, from: i) {
                // 添加之前的文本
                if !currentText.isEmpty {
                    result = result + Text(currentText)
                    currentText = ""
                }
                
                // 提取链接文本和 URL
                let linkStart = text.index(after: i)
                let substring = text[linkStart..<linkEnd]
                let textEnd = substring.firstIndex(of: "]") ?? linkStart
                let linkText = String(text[linkStart..<textEnd])
                
                let urlStart = text.index(textEnd, offsetBy: 2)
                let urlString = String(text[urlStart..<linkEnd])
                
                // 创建蓝色下划线链接
                result = result + Text(linkText)
                    .foregroundColor(Color(hex: "4A90E2"))
                    .underline()
                
                i = text.index(after: linkEnd)
                continue
            }
            
            // 检查粗体 **text**
            if text[i] == "*", i < text.index(before: text.endIndex), text[text.index(after: i)] == "*" {
                let searchStart = text.index(i, offsetBy: 2)
                if let endIndex = text[searchStart...].firstIndex(where: { $0 == "*" }),
                   endIndex < text.index(before: text.endIndex),
                   text[text.index(after: endIndex)] == "*" {
                    // 添加之前的文本
                    if !currentText.isEmpty {
                        result = result + Text(currentText)
                        currentText = ""
                    }
                    
                    // 添加粗体文本
                    let boldText = String(text[searchStart..<endIndex])
                    result = result + Text(boldText).bold()
                    
                    i = text.index(endIndex, offsetBy: 2)
                    continue
                }
            }
            
            // 检查斜体 *text*
            if text[i] == "*" {
                let searchStart = text.index(after: i)
                if let endIndex = text[searchStart...].firstIndex(of: "*") {
                    // 添加之前的文本
                    if !currentText.isEmpty {
                        result = result + Text(currentText)
                        currentText = ""
                    }
                    
                    // 添加斜体文本
                    let italicText = String(text[searchStart..<endIndex])
                    result = result + Text(italicText).italic()
                    
                    i = text.index(after: endIndex)
                    continue
                }
            }
            
            currentText.append(text[i])
            i = text.index(after: i)
        }
        
        if !currentText.isEmpty {
            result = result + Text(currentText)
        }
        
        return result
    }
    
    // 查找链接结束位置
    private func findLinkEnd(in text: String, from start: String.Index) -> String.Index? {
        let substring = text[start..<text.endIndex]
        guard let textEnd = substring.firstIndex(of: "]") else { return nil }
        let nextIndex = text.index(after: textEnd)
        guard nextIndex < text.endIndex, text[nextIndex] == "(" else { return nil }
        let urlSubstring = text[nextIndex..<text.endIndex]
        return urlSubstring.firstIndex(of: ")")
    }
    
    // 渲染表格
    @ViewBuilder
    private func renderTable(_ rows: [[String]]) -> some View {
        if !rows.isEmpty {
            // 计算每列的相对权重
            let columnCount = rows.first?.count ?? 0
            let columnWeights = calculateColumnWeights(rows: rows, columnCount: columnCount)
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                        HStack(spacing: 0) {
                            ForEach(Array(row.enumerated()), id: \.offset) { colIndex, cell in
                                let weight = colIndex < columnWeights.count ? columnWeights[colIndex] : 1.0
                                
                                Text(cell.trimmingCharacters(in: .whitespaces))
                                    .font(.system(size: 14, weight: rowIndex == 0 ? .semibold : .regular))
                                    .foregroundColor(Color(hex: "1F2A60"))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 10)
                                    .frame(minWidth: 60, maxWidth: weight * 120, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(nil)
                                    .background(rowIndex == 0 ? Color(hex: "F0F4F8") : Color.white)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color(hex: "E0E0E0"), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                }
                .cornerRadius(8)
                .padding(.vertical, 4)
            }
        }
    }
    
    // 计算每列的相对权重（基于内容长度）
    private func calculateColumnWeights(rows: [[String]], columnCount: Int) -> [Double] {
        guard columnCount > 0 else { return [] }
        
        var maxLengths = Array(repeating: 0, count: columnCount)
        
        // 计算每列的最大字符长度
        for row in rows {
            for (index, cell) in row.enumerated() where index < columnCount {
                let length = cell.trimmingCharacters(in: .whitespaces).count
                maxLengths[index] = max(maxLengths[index], length)
            }
        }
        
        // 计算总长度
        let totalLength = maxLengths.reduce(0, +)
        guard totalLength > 0 else { return Array(repeating: 1.0, count: columnCount) }
        
        // 计算权重（最小权重为0.5，避免过窄）
        return maxLengths.map { length in
            max(0.5, Double(length) / Double(totalLength) * Double(columnCount))
        }
    }
    
    // 解析 Markdown 为元素列表
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: "\n")
        var currentParagraph = ""
        var listNumber = 1
        var inTable = false
        var tableRows: [[String]] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // 表格行
            if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
                    currentParagraph = ""
                }
                
                inTable = true
                let cells = trimmed
                    .split(separator: "|")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty && !$0.contains("---") }
                
                if !cells.isEmpty {
                    tableRows.append(cells)
                }
                continue
            } else if inTable {
                elements.append(MarkdownElement(type: .table, content: "", tableData: tableRows))
                tableRows = []
                inTable = false
            }
            
            // 空行 - 分隔段落
            if trimmed.isEmpty {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
                    currentParagraph = ""
                }
                listNumber = 1
                continue
            }
            
            // 二级标题
            if trimmed.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
                    currentParagraph = ""
                }
                elements.append(MarkdownElement(type: .heading2, content: String(trimmed.dropFirst(3))))
                listNumber = 1
                continue
            }
            
            // 三级标题
            if trimmed.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
                    currentParagraph = ""
                }
                elements.append(MarkdownElement(type: .heading3, content: String(trimmed.dropFirst(4))))
                listNumber = 1
                continue
            }
            
            // 项目符号列表
            if trimmed.hasPrefix("• ") || trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
                    currentParagraph = ""
                }
                elements.append(MarkdownElement(type: .listItem, content: String(trimmed.dropFirst(2))))
                continue
            }
            
            // 数字列表
            if let match = trimmed.range(of: "^\\d+\\. ", options: .regularExpression) {
                if !currentParagraph.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
                    currentParagraph = ""
                }
                let content = String(trimmed[match.upperBound...])
                elements.append(MarkdownElement(type: .numberedListItem, content: content, listNumber: listNumber))
                listNumber += 1
                continue
            }
            
            // 普通段落 - 保留换行（用换行符而非空格连接）
            if !currentParagraph.isEmpty {
                currentParagraph += "\n"
            }
            currentParagraph += trimmed
        }
        
        // 添加最后的段落或表格
        if inTable && !tableRows.isEmpty {
            elements.append(MarkdownElement(type: .table, content: "", tableData: tableRows))
        } else if !currentParagraph.isEmpty {
            elements.append(MarkdownElement(type: .paragraph, content: currentParagraph))
        }
        
        return elements
    }
}

// MARK: - FlowLayout（自动换行布局）
struct FlowLayout: Layout {
    var spacing: CGFloat = 0
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    // 换行
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Markdown 元素模型
struct MarkdownElement: Identifiable {
    let id = UUID()
    let type: ElementType
    let content: String
    var listNumber: Int? = nil
    var tableData: [[String]]? = nil
    
    enum ElementType {
        case heading2
        case heading3
        case listItem
        case numberedListItem
        case paragraph
        case table
    }
}

// MARK: - 内联片段模型
struct InlineSegment {
    let type: SegmentType
    let text: String
    var url: String? = nil
    
    enum SegmentType {
        case plain
        case bold
        case italic
        case link
    }
}

#Preview {
    HealthAssistantView()
}
