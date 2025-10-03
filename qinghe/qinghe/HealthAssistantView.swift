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
    // 使用单例获取 TabBar 可见性，避免环境注入缺失导致崩溃

    // 消息数据模型
    struct ChatMessage: Identifiable {
        let id = UUID()
        let content: String
        let isUser: Bool
        let timestamp: Date
    }

    var body: some View {
        ZStack(alignment: .top) {
            // 页面全局底色
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            // 顶部柔和渐变（参考健康档案页）
            AssistantTopGradient()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 可滚动内容（上滑显示导航栏）
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 滚动监听器 - 使用与 UserProfileView 相同的实现方式
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
                                        .onChange(of: y) { oldValue, newValue in
                                            print("📈 健康助手滚动监听器检测到变化: \(oldValue) -> \(newValue)")

                                            // 直接在这里更新状态
                                            DispatchQueue.main.async {
                                                scrollOffset = newValue
                                                print("✅ scrollOffset 已更新为: \(newValue)")
                                            }
                                        }
                                }
                            )

                        // 头部问候 + 插画
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, -10)

                        // 今日自律卡片（放在头部下方与其同层级）
                        DailySelfDisciplineCard(
                            suggestions: [
                                "怎么判断自己是否气血充足？",
                                "便秘时不能吃什么水果？",
                                "为什么年龄越大脸越大？"
                            ],
                            onTapSuggestion: { _ in /* TODO: 触发向健康助手发问 */ }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, -42)

                        // 消息列表
                        if !messages.isEmpty || isTyping {
                            VStack(spacing: 12) {
                                // 已完成的消息（除了最后一条）
                                ForEach(messages.dropLast(isTyping ? 1 : 0)) { message in
                                    MessageBubble(message: message, displayedText: message.content)
                                }

                                // 正在打字的消息
                                if isTyping, let lastMessage = messages.last {
                                    MessageBubble(message: lastMessage, displayedText: displayedText)
                                }

                                // 正在发送消息的加载指示器
                                if isSendingMessage {
                                    HStack(alignment: .top, spacing: 8) {
                                        HStack(spacing: 4) {
                                            ForEach(0..<3) { index in
                                                Circle()
                                                    .fill(Color(hex: "1F774E").opacity(0.6))
                                                    .frame(width: 8, height: 8)
                                                    .scaleEffect(isSendingMessage ? 1.0 : 0.5)
                                                    .animation(
                                                        Animation.easeInOut(duration: 0.6)
                                                            .repeatForever()
                                                            .delay(Double(index) * 0.2),
                                                        value: isSendingMessage
                                                    )
                                            }
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
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }

                        Color.clear.frame(height: 24)
                        // 额外留白，确保可产生实际滚动，从而触发顶部导航渐显
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

                Spacer(minLength: 0)

                // 操作菜单（输入框上方）
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

                // 底部输入栏
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
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingActionMenu)
        // 顶部导航栏（使用 safeAreaInset，更符合 SwiftUI 推荐方式）
        .safeAreaInset(edge: .top) { topNavigationBar(opacity: navOpacity) }
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

                    ConversationSidebarView(isPresented: $showingSidebar)
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

    // MARK: - 打字机效果
    private func startTypingEffect(for text: String) async {
        displayedText = ""
        isTyping = true

        let characters = Array(text)
        for (index, char) in characters.enumerated() {
            displayedText.append(char)

            // 每个字符延迟，可以根据字符类型调整速度
            let delay: UInt64
            if char == "\n" {
                delay = 30_000_000 // 换行符稍慢一点 (0.03秒)
            } else if char.isWhitespace {
                delay = 10_000_000 // 空格快一点 (0.01秒)
            } else {
                delay = 30_000_000 // 普通字符 (0.03秒)
            }

            // 最后一个字符不需要延迟
            if index < characters.count - 1 {
                try? await Task.sleep(nanoseconds: delay)
            }
        }

        isTyping = false
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
                            print("✅ AI响应完成: \(aiResponse)")
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
            let aiMessage = ChatMessage(
                content: content,
                isUser: false,
                timestamp: Date()
            )
            messages.append(aiMessage)

            // 启动打字机效果
            Task {
                await startTypingEffect(for: content)
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

        let result = ConstitutionAnalysisData(
            hasAnalysis: true,
            primaryConstitution: d.primaryConstitution?.name ?? d.physiqueName,
            secondaryConstitution: d.secondaryConstitutions.first?.name ?? "",
            confidence: d.primaryConstitution?.confidence ?? 0.82,
            organDistribution: [:], // v2数据中无此字段
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
            // 导航栏标题（居中、黑色，仅标题）
            Text("健康助手")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
            Spacer()
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.08))
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

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                header
                ForEach(suggestions.indices, id: \.self) { idx in
                    suggestionRow(index: idx, text: suggestions[idx])
                        .onTapGesture { onTapSuggestion(idx) }
                }
            }
            .padding(14)
            .background(panelBackground)
            .overlay(panelStroke)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 6)
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
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.conversations) { conversation in
                                conversationRow(conversation)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .frame(width: 300)
            .frame(maxHeight: .infinity)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.2), radius: 10, x: -5, y: 0)
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
        .background(Color(.systemBackground))
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
            // 对话图标
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "1F774E"))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color(hex: "1F774E").opacity(0.1))
                )

            // 对话信息
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title ?? "新对话")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(formatDate(conversation.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 删除按钮
            Button(action: {
                Task {
                    await viewModel.deleteConversation(conversation.id)
                }
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .onTapGesture {
            viewModel.selectConversation(conversation.id)
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
                    Conversation(
                        id: item.conversationId,
                        title: item.title,
                        createdAt: parseDate(item.createdAt),
                        updatedAt: parseDate(item.updatedAt)
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

    func selectConversation(_ id: String) {
        // TODO: 通知主视图切换到选中的对话
        print("选中对话: \(id)")
    }

    private func parseDate(_ dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString) ?? Date()
    }
}

// MARK: - 对话数据模型
struct Conversation: Identifiable, Codable {
    let id: String
    let title: String?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - 消息气泡组件
struct MessageBubble: View {
    let message: HealthAssistantView.ChatMessage
    let displayedText: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 50)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(displayedText)
                    .font(.system(size: 15))
                    .foregroundColor(message.isUser ? .white : Color(hex: "1F2A60"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(message.isUser ? Color(hex: "34C759") : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(message.isUser ? Color.clear : Color(hex: "E0E0E0"), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

                // 时间戳
                Text(formatTime(message.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.horizontal, 4)
            }

            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    HealthAssistantView()
}
