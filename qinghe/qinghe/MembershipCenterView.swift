import SwiftUI

struct MembershipCenterView: View {
    @StateObject private var viewModel = MembershipViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: MembershipPlan?
    @State private var isAnimating = false
    @State private var showHero = false
    @State private var showJourney = false
    @State private var showUserStory = false
    @State private var showPricing = false
    @State private var emojiRotation: Double = 0
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isRestoreSuccess = false
    @State private var showMembershipAgreement = false
    @State private var membershipAgreementNavPath = NavigationPath()
    @State private var showPrivacyPolicy = false
    @State private var privacyPolicyNavPath = NavigationPath()
    @State private var showTermsOfUse = false
    @State private var termsOfUseNavPath = NavigationPath()
    // 滚动驱动的导航栏背景
    @State private var scrollOffset: CGFloat = 0

    // 新增状态：轮播相关
    @State private var currentBenefitIndex = 0
    @State private var benefitCardOffset: CGFloat = 0
    @State private var isDragging = false
    private let benefitCardTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 会员状态卡片（已开通会员时显示）
                if viewModel.isActiveMember {
                    activeMembershipCard
                        .padding(.top, 12)
                        .padding(.horizontal, 20)
                        .opacity(showPricing ? 1 : 0)
                        .offset(y: showPricing ? 0 : 30)
                }

                // 第一栏：价格卡片横向滚动列表（仅未开通会员时显示）
                if !viewModel.isActiveMember {
                    horizontalPricingSection
                        .padding(.top, 12)
                        .opacity(showPricing ? 1 : 0)
                        .offset(y: showPricing ? 0 : 30)
                }

                // 第二栏：会员特权 + 即将上线
                privilegesAndRoadmapSection
                    .padding(.top, viewModel.isActiveMember ? 24 : 24)
                    .opacity(showPricing ? 1 : 0)

                // 第三栏：产品愿景与自律价值说明（我们的出发点）
                whyAndHowSection
                    .padding(.top, 24)
                    .opacity(showJourney ? 1 : 0)
                    .offset(y: showJourney ? 0 : 20)

                // 底部保障（仅未开通会员时显示）
                if !viewModel.isActiveMember {
                    guaranteeSection
                        .padding(.top, 32)
                        .padding(.bottom, 60)
                        .opacity(showPricing ? 1 : 0)
                }
            }
            // 监听滚动偏移
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: MembershipScrollOffsetKey.self,
                        value: proxy.frame(in: .named("membershipScroll")).minY
                    )
                }
            )
        }
        .coordinateSpace(name: "membershipScroll")
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.94),
                    Color(red: 0.95, green: 0.93, blue: 0.90)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            // 页面标题：会员中心
            ToolbarItem(placement: .principal) {
                Text("会员中心")
                    .font(AppFont.kangxi(size: 20))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        // 顶部渐显背景（与系统导航栏叠加，只负责背景与分隔线）
        .safeAreaInset(edge: .top) {
            ZStack(alignment: .bottom) {
                Color.clear
                    .frame(height: 44)
                    .background(.ultraThinMaterial.opacity(navOpacity))
                Rectangle()
                    .fill(Color.black.opacity(0.08 * navOpacity))
                    .frame(height: 0.5)
            }
        }
        .onPreferenceChange(MembershipScrollOffsetKey.self) { value in
            scrollOffset = value
        }
        .task {
            // 并行触发数据加载，避免阻塞首屏呈现
            Task { await viewModel.load() }
            // 入场动画不再等待网络完成
            withAnimation(.easeOut(duration: 0.6)) { showHero = true }
            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.easeOut(duration: 0.6)) { showJourney = true }
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.easeOut(duration: 0.6)) { showPricing = true }
        }
        .onReceive(benefitCardTimer) { _ in
            if !isDragging {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentBenefitIndex = (currentBenefitIndex + 1) % benefits.count
                }
            }
        }
        .overlay(purchasingOverlay)
        .onAppear {
            isAnimating = true
            emojiRotation = -10
        }
        .alert(isRestoreSuccess ? "恢复成功" : "购买成功", isPresented: $showSuccessAlert) {
            Button("确定") {
                dismiss()
            }
        } message: {
            if isRestoreSuccess {
                Text("您的购买记录已恢复，会员权益已激活 🎉")
            } else {
                Text("感谢您的支持！您已成为会员，尽情享受所有功能吧 🎉")
            }
        }
        .alert("购买失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        // 会员服务协议弹窗
        .sheet(isPresented: $showMembershipAgreement) {
            NavigationStack(path: $membershipAgreementNavPath) {
                MembershipServiceAgreementView(navigationPath: $membershipAgreementNavPath)
                    .navigationBarHidden(true)
            }
        }
        // 隐私政策弹窗
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack(path: $privacyPolicyNavPath) {
                PrivacyPolicyView(navigationPath: $privacyPolicyNavPath)
                    .navigationBarHidden(true)
            }
        }
        // 使用条款弹窗
        .sheet(isPresented: $showTermsOfUse) {
            NavigationStack(path: $termsOfUseNavPath) {
                TermsOfUseView(navigationPath: $termsOfUseNavPath)
                    .navigationBarHidden(true)
            }
        }
    }
    
    // 顶部背景透明度：上滑 8pt 开始出现，约 24pt 全不透明
    private var navOpacity: Double {
        let shown = max(0, min(1, Double((-(scrollOffset) - 8) / 24)))
        return shown
    }

    // MARK: - 已开通会员状态卡片
    private var activeMembershipCard: some View {
        VStack(spacing: 0) {
            // 顶部装饰条
            HStack(spacing: 4) {
                ForEach(0..<20, id: \.self) { _ in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.75, green: 0.55, blue: 0.35),
                                    Color(red: 0.65, green: 0.45, blue: 0.25)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 3, height: 3)
                }
            }
            .padding(.bottom, 16)

            VStack(spacing: 16) {
                // 会员标识和名称
                HStack(spacing: 12) {
                    // 会员图标
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.75, green: 0.55, blue: 0.35),
                                        Color(red: 0.65, green: 0.45, blue: 0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.status?.currentPlan?.planName ?? "会员")
                            .font(AppFont.kangxi(size: 22))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.65, green: 0.45, blue: 0.25))

                            Text("会员服务生效中")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                        }
                    }

                    Spacer()
                }

                // 分隔线
                Rectangle()
                    .fill(Color(red: 0.9, green: 0.88, blue: 0.85))
                    .frame(height: 1)

                // 会员信息
                VStack(spacing: 12) {
                    // 到期时间
                    if let endDate = viewModel.status?.endDate {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.65, green: 0.45, blue: 0.25))

                                Text("到期时间")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                            }

                            Spacer()

                            Text(formatExpiryDate(endDate))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        }
                    }

                    // 剩余天数
                    if let days = viewModel.status?.daysRemaining, days >= 0 {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "hourglass")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.65, green: 0.45, blue: 0.25))

                                Text("剩余时间")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                            }

                            Spacer()

                            Text("\(days) 天")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(days < 7 ? Color.red : Color(red: 0.2, green: 0.15, blue: 0.1))
                        }
                    }

                    // 自动续费状态
                    if let autoRenew = viewModel.status?.autoRenew {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: autoRenew ? "arrow.clockwise.circle.fill" : "pause.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(autoRenew ? Color.green : Color.orange)

                                Text("自动续费")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                            }

                            Spacer()

                            Text(autoRenew ? "已开启" : "已关闭")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(autoRenew ? Color.green : Color.orange)
                        }
                    }

                    // 会员来源
                    if let source = viewModel.status?.source {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: sourceIcon(source))
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.65, green: 0.45, blue: 0.25))

                                Text("购买渠道")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                            }

                            Spacer()

                            Text(sourceName(source))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 0.98, green: 0.96, blue: 0.94)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.75, green: 0.55, blue: 0.35).opacity(0.3),
                                        Color(red: 0.65, green: 0.45, blue: 0.25).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.15),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            )
        }
    }

    // 格式化到期日期
    private func formatExpiryDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年MM月dd日"
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }

        // 尝试其他格式
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = altFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年MM月dd日"
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }

        // 如果都失败，返回原始字符串
        return dateString
    }

    // 获取来源图标
    private func sourceIcon(_ source: String) -> String {
        switch source.lowercased() {
        case "apple":
            return "apple.logo"
        case "wechat":
            return "message.fill"
        case "alipay":
            return "creditcard.fill"
        case "admin":
            return "person.badge.key.fill"
        default:
            return "bag.fill"
        }
    }

    // 获取来源名称
    private func sourceName(_ source: String) -> String {
        switch source.lowercased() {
        case "apple":
            return "Apple 内购"
        case "wechat":
            return "微信支付"
        case "alipay":
            return "支付宝"
        case "admin":
            return "管理员赠送"
        default:
            return source
        }
    }

    // MARK: - 新第一栏：我们的出发点（愿景） + 自律价值
    private var whyAndHowSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 出发点
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                Text("我们的出发点")
                    .font(AppFont.kangxi(size: 22))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            }

            let manifesto = """
            当下的时代，物质极度丰富，信息瞬息万变。
            人们被裹挟在欲望与焦虑的洪流中，健康被透支，
            精神被稀释，文化的根也在逐渐淡忘。
            
            我们希望通过这款应用，让人重新找回平衡。
            以科技为桥梁，让古人的智慧与现代生活重新对话。

            我们相信——身体的健康，是自律的果；心灵的安宁，是文化的根。

            这不是一款普通的应用，而是一场通往身心合一、自我觉醒的旅程。
            
            愿你在这里，找回节制、静气与笃行，让生活重新回到“道”的轨迹上。
            """
            Text(manifesto)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.42, green: 0.36, blue: 0.3))
                .lineSpacing(6)

            Divider().opacity(0.25)

            // 我们如何具体帮到你（保留要点，便于转化）
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                Text("我们如何帮助你自律")
                    .font(AppFont.kangxi(size: 22))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
            }

            VStack(spacing: 12) {
                ValuePointRow(icon: "calendar.badge.clock", title: "复习计划与间隔重复", detail: "按遗忘曲线安排复习，自动出现待办，避免临时抱佛脚")
                ValuePointRow(icon: "checkmark.seal.fill", title: "了凡四训功过格", detail: "每日记录善行与过失，量化自我修养，培养自律习惯，实现知行合一")
                ValuePointRow(icon: "figure.run", title: "运动助手", detail: "AI 智能运动指导，实时语音提示，科学运动计划，让每次运动更高效")
                ValuePointRow(icon: "sparkles", title: "AI 健康助手", detail: "用自然语言设定目标与提醒，精准到作息、学习与运动")
                ValuePointRow(icon: "book.closed.fill", title: "国学阅读与背诵测试", detail: "填空/默写/听写/听力多种练习，配合统计与错题回顾")
                ValuePointRow(icon: "moon.stars.fill", title: "睡眠与专注工具", detail: "白噪音、引导与专注计时，帮助进入状态")
                ValuePointRow(icon: "chart.bar.fill", title: "数据反馈与统计", detail: "复习、题目、习惯数据可视化，清晰看到进步")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color(red: 0.98, green: 0.97, blue: 0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.75, green: 0.55, blue: 0.35).opacity(0.25),
                                    Color(red: 0.65, green: 0.45, blue: 0.25).opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - 会员特权数据
    private let benefits: [BenefitStory] = [
        BenefitStory(
            icon: "sparkles",
            title: "AI 健康助手",
            description: "智能分析，个性化健康建议",
            detailDescription: "基于您的健康数据，AI 助手提供 24/7 专业健康咨询，让健康管理更智能",
            gradient: [Color(red: 0.75, green: 0.55, blue: 0.35), Color(red: 0.85, green: 0.65, blue: 0.45)],
            emoji: "✨"
        ),
        BenefitStory(
            icon: "eye",
            title: "AI 舌面分析",
            description: "专业中医诊断，了解身体状况",
            detailDescription: "通过 AI 识别技术，快速分析舌象面相，提供专业的中医体质分析报告",
            gradient: [Color(red: 0.65, green: 0.45, blue: 0.25), Color(red: 0.75, green: 0.55, blue: 0.35)],
            emoji: "👁️"
        ),
        BenefitStory(
            icon: "moon.stars",
            title: "睡眠分析",
            description: "深度睡眠监测，改善睡眠质量",
            detailDescription: "智能监测睡眠质量，分析睡眠周期，提供个性化改善建议",
            gradient: [Color(red: 0.55, green: 0.35, blue: 0.15), Color(red: 0.65, green: 0.45, blue: 0.25)],
            emoji: "🌙"
        ),
        BenefitStory(
            icon: "figure.run",
            title: "AI 运动教练",
            description: "语音指导，科学运动计划",
            detailDescription: "专业运动指导，实时语音提示，让每一次运动都更科学有效",
            gradient: [Color(red: 0.75, green: 0.55, blue: 0.35), Color(red: 0.85, green: 0.65, blue: 0.45)],
            emoji: "🏃"
        ),
        BenefitStory(
            icon: "book.closed",
            title: "国学经典",
            description: "海量经典书籍，传承千年智慧",
            detailDescription: "精选国学经典，配备专业朗读，让传统文化触手可及",
            gradient: [Color(red: 0.65, green: 0.45, blue: 0.25), Color(red: 0.75, green: 0.55, blue: 0.35)],
            emoji: "📚"
        ),
        BenefitStory(
            icon: "sparkle",
            title: "去除广告",
            description: "纯净体验，专注健康管理",
            detailDescription: "享受无广告打扰的纯净体验，让您更专注于健康生活",
            gradient: [Color(red: 0.55, green: 0.35, blue: 0.15), Color(red: 0.65, green: 0.45, blue: 0.25)],
            emoji: "💎"
        )
    ]

    // MARK: - Header Section
    private var headerSection: some View {
        // 需求：移除“会员中心”主标题，这里返回空视图以保持布局兼容
        EmptyView()
    }

    // MARK: - 第一栏：会员特权轮播故事卡片
    private var benefitStoryCarousel: some View {
        VStack(spacing: 20) {

            // 轮播卡片
            GeometryReader { geometry in
                let cardWidth = geometry.size.width - 40

                ZStack {
                    ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                        BenefitStoryCard(benefit: benefit)
                            .frame(width: cardWidth)
                            .offset(x: CGFloat(index - currentBenefitIndex) * (cardWidth + 20))
                            .scaleEffect(index == currentBenefitIndex ? 1.0 : 0.9)
                            .opacity(index == currentBenefitIndex ? 1.0 : 0.5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentBenefitIndex)
                    }
                }
                .frame(width: geometry.size.width, height: 320)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            benefitCardOffset = value.translation.width
                        }
                        .onEnded { value in
                            isDragging = false
                            let threshold: CGFloat = 50

                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                if value.translation.width < -threshold && currentBenefitIndex < benefits.count - 1 {
                                    currentBenefitIndex += 1
                                } else if value.translation.width > threshold && currentBenefitIndex > 0 {
                                    currentBenefitIndex -= 1
                                }
                                benefitCardOffset = 0
                            }
                        }
                )
            }
            .frame(height: 320)

            // 指示器
            HStack(spacing: 8) {
                ForEach(0..<benefits.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentBenefitIndex ?
                              Color(red: 0.65, green: 0.45, blue: 0.25) :
                              Color(red: 0.65, green: 0.45, blue: 0.25).opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentBenefitIndex)
                }
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 第二栏：横向滚动价格卡片
    private var horizontalPricingSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(viewModel.isActiveMember ? "续费或升级" : "选择套餐")
                    .font(AppFont.kangxi(size: 24))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                if viewModel.isActiveMember {
                    Text("继续享受会员特权")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .tint(Color(red: 0.65, green: 0.45, blue: 0.25))
                    .padding(.vertical, 60)
            } else {
                // 横向滚动的价格卡片
                let allPlans = viewModel.plans.isEmpty ? defaultPlans : viewModel.plans
                let paidPlans = allPlans.filter { $0.price > 0 }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(paidPlans) { plan in
                            HorizontalPricingCard(
                                plan: plan,
                                isSelected: selectedPlan?.id == plan.id,
                                onSelect: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedPlan = plan
                                    }
                                },
                                onPurchase: {
                                    Task {
                                        // 清空之前的错误信息和成功标志
                                        viewModel.errorMessage = nil
                                        viewModel.purchaseSuccess = false

                                        await viewModel.purchase(plan: plan)

                                        // 检查是否有错误信息
                                        if let error = viewModel.errorMessage {
                                            errorMessage = error
                                            showErrorAlert = true
                                            viewModel.errorMessage = nil
                                        } else if viewModel.purchaseSuccess {
                                            // 只有在明确标记购买成功时才显示成功提示
                                            // 用户取消的情况 purchaseSuccess = false，不会显示成功
                                            isRestoreSuccess = false
                                            showSuccessAlert = true
                                        }
                                        // 如果既没有错误也没有成功（用户取消），则不显示任何提示
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12) // 给放大后的卡片留出上下空间，避免裁剪
                }
            }
        }
    }

    // MARK: - 第三栏：会员特权 + 即将上线（整合为一个卡片，分两列展示）
    private var privilegesAndRoadmapSection: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                // 左列：会员特权
                VStack(spacing: 16) {
                    HStack {
                        Text("会员特权")
                            .font(AppFont.kangxi(size: 18))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        Spacer()
                    }

                    VStack(spacing: 10) {
                        PrivilegeRow(icon: "checkmark.circle.fill", title: "无限次 AI 健康咨询", isActive: true)
                        PrivilegeRow(icon: "checkmark.circle.fill", title: "AI 舌面分析", isActive: true)
                        PrivilegeRow(icon: "checkmark.circle.fill", title: "深度睡眠监测", isActive: true)
                        PrivilegeRow(icon: "checkmark.circle.fill", title: "AI 运动语音指导", isActive: true)
                        PrivilegeRow(icon: "checkmark.circle.fill", title: "国学经典无限畅读", isActive: true)
                        PrivilegeRow(icon: "checkmark.circle.fill", title: "去除所有广告", isActive: true)
                    }
                }
                .frame(maxWidth: .infinity)

                // 右列：即将上线
                VStack(spacing: 16) {
                    HStack {
                        Text("即将上线")
                            .font(AppFont.kangxi(size: 18))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                        Text("敬请期待")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(red: 0.75, green: 0.55, blue: 0.35))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.75, green: 0.55, blue: 0.35).opacity(0.15))
                            )

                        Spacer()
                    }

                    VStack(spacing: 10) {
                        PrivilegeRow(icon: "clock.fill", title: "AI 把脉手环（研发中）", isActive: false)
                        PrivilegeRow(icon: "clock.fill", title: "读书交友匹配", isActive: false)
                        PrivilegeRow(icon: "clock.fill", title: "营养膳食定制方案", isActive: false)
                        PrivilegeRow(icon: "clock.fill", title: "线下健康活动优先", isActive: false)
                        PrivilegeRow(icon: "clock.fill", title: "专属健康顾问", isActive: false)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 保障区域
    private var guaranteeSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                // 第一行：会员服务协议
                HStack(spacing: 4) {
                    Text("点击支付即表示同意")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))

                    Button(action: {
                        showMembershipAgreement = true
                    }) {
                        Text("《增值服务协议》")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                            .underline()
                    }
                }

                // 第二行：隐私政策和使用条款
                HStack(spacing: 4) {
                    Button(action: {
                        showPrivacyPolicy = true
                    }) {
                        Text("《隐私政策》")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                            .underline()
                    }

                    Text("和")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))

                    Button(action: {
                        showTermsOfUse = true
                    }) {
                        Text("《使用条款》")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                            .underline()
                    }
                }
            }
            .padding(.horizontal, 32)

            // 恢复购买按钮
            Button(action: {
                Task {
                    await viewModel.restorePurchases()
                    // 检查是否有错误信息
                    if let error = viewModel.errorMessage {
                        errorMessage = error
                        showErrorAlert = true
                        viewModel.errorMessage = nil
                    } else {
                        // 恢复成功，显示成功提示
                        isRestoreSuccess = true
                        showSuccessAlert = true
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))

                    Text("恢复购买")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(viewModel.isRestoring)
            .opacity(viewModel.isRestoring ? 0.6 : 1.0)
            .padding(.top, 8)
        }
    }
    
    // MARK: - 购买中遮罩
    @ViewBuilder
    private var purchasingOverlay: some View {
        if viewModel.isPurchasing || viewModel.isRestoring {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    
                    Text(viewModel.isRestoring ? "正在恢复购买..." : "正在处理购买...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "1F2937"))
                )
            }
        }
    }
    
    // MARK: - 默认套餐（用于展示）
    private var defaultPlans: [MembershipPlan] {
        [
            MembershipPlan(
                id: 1,
                planCode: "monthly_auto",
                planName: "连续包月会员",
                planDescription: "自动续费，随时取消",
                price: 29.9,
                originalPrice: nil,
                duration: 1,
                durationType: "month",
                isRecommended: false,
                promotionTag: "自动续费",
                limits: nil,
                features: nil
            ),
            MembershipPlan(
                id: 2,
                planCode: "standard_monthly",
                planName: "月度会员",
                planDescription: "按月付费，功能完整",
                price: 39.9,
                originalPrice: nil,
                duration: 1,
                durationType: "month",
                isRecommended: false,
                promotionTag: "热门",
                limits: nil,
                features: nil
            ),
            MembershipPlan(
                id: 3,
                planCode: "quarterly",
                planName: "季度会员",
                planDescription: "三个月畅享",
                price: 69.9,
                originalPrice: 119.7,
                duration: 3,
                durationType: "month",
                isRecommended: false,
                promotionTag: "优惠",
                limits: nil,
                features: nil
            ),
            MembershipPlan(
                id: 4,
                planCode: "standard_yearly",
                planName: "年度会员",
                planDescription: "全年畅享，最划算",
                price: 169.0,
                originalPrice: 478.8,
                duration: 12,
                durationType: "month",
                isRecommended: true,
                promotionTag: "推荐",
                limits: nil,
                features: PlanFeatures(adFree: true, prioritySupport: nil, exclusiveContent: nil, advancedAnalytics: nil)
            )
        ]
    }
}

// MARK: - 子组件

// 套餐卡片
private struct PricingPlanCard: View {
    let plan: MembershipPlan
    let isSelected: Bool
    let onSelect: () -> Void
    let onPurchase: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: handleTap) {
            cardContent
        }
        .background(cardBackground)
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }

    private func handleTap() {
        if !isSelected {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            onSelect()
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            promotionTagView

            VStack(alignment: .leading, spacing: 16) {
                headerView
                Divider().background(Color(red: 0.8, green: 0.75, blue: 0.7))
                priceView
                bonusView
                actionButtonView
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private var promotionTagView: some View {
        if let tag = plan.promotionTag {
            HStack {
                Spacer()
                Text(tag)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(promotionTagBackground)
            }
            .padding(.horizontal, 20)
            .padding(.top, -10)
            .zIndex(1)
        }
    }

    private var promotionTagBackground: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.75, green: 0.55, blue: 0.35),
                        Color(red: 0.65, green: 0.45, blue: 0.25)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(
                color: Color(red: 0.6, green: 0.4, blue: 0.2).opacity(isSelected ? 0.6 : 0.4),
                radius: 10
            )
    }

    private var headerView: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.planName)
                    .font(AppFont.kangxi(size: 20))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                if let desc = plan.planDescription {
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                }
            }

            Spacer()

            if plan.promotionTag == nil {
                Text("无优惠")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(red: 0.9, green: 0.88, blue: 0.85)))
            }
        }
    }

    private var priceView: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formatPrice(plan.price))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                Text("元/\(durationText)")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
            }

            Spacer()

            if let original = plan.originalPrice, original > plan.price {
                Text("¥\(Int(original))")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                    .strikethrough(true, color: Color(red: 0.6, green: 0.5, blue: 0.4))
            }
        }
    }

    @ViewBuilder
    private var bonusView: some View {
        if let original = plan.originalPrice, original > plan.price {
            HStack(spacing: 6) {
                Text("额外再送")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.75, green: 0.55, blue: 0.35))

                Text("+\(Int((original - plan.price) * 10)) 试意币")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.75, green: 0.55, blue: 0.35))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(bonusBackground)
        }
    }

    private var bonusBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(red: 0.75, green: 0.55, blue: 0.35).opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0.75, green: 0.55, blue: 0.35).opacity(0.3), lineWidth: 1)
            )
    }

    private var actionButtonView: some View {
        HStack {
            Spacer()
            if isSelected {
                purchaseButton
            } else {
                selectButton
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var purchaseButton: some View {
        Button(action: onPurchase) {
            Text("立即购买 \(durationText) \(formatPrice(plan.price))元")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(purchaseButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var purchaseButtonBackground: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.75, green: 0.55, blue: 0.35),
                        Color(red: 0.65, green: 0.45, blue: 0.25)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(
                color: Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.4),
                radius: 12,
                y: 6
            )
    }

    private var selectButton: some View {
        Text("选择此套餐")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(red: 0.6, green: 0.4, blue: 0.2), lineWidth: 2)
            )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .overlay(cardBorder)
            .shadow(
                color: isSelected ?
                    Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.3) :
                    Color.black.opacity(0.05),
                radius: isSelected ? 20 : 8,
                x: 0,
                y: isSelected ? 10 : 4
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                isSelected ?
                Color(red: 0.75, green: 0.55, blue: 0.35) :
                Color(red: 0.9, green: 0.88, blue: 0.85),
                lineWidth: isSelected ? 3 : 1
            )
    }

    // 价格展示：整数不带小数，非整数最多保留1位小数
    private func formatPrice(_ price: Double) -> String {
        let intPart = Int(price)
        if abs(price - Double(intPart)) < 0.001 {
            return String(intPart)
        } else {
            return String(format: "%.1f", price)
        }
    }
    
    private var durationText: String {
        if plan.planCode == "monthly_auto" {
            return "月"
        }
        switch plan.durationType {
        case "month":
            if let duration = plan.duration, duration > 1 {
                return "季"
            }
            return "月"
        case "year":
            return "年"
        default:
            return "月"
        }
    }

    // MARK: - 根据计划构建真实功能说明
    private func buildFeatureTexts(for plan: MembershipPlan) -> [String] {
        var items: [String] = []

        // 领域功能（与项目真实功能对应）
        // AI 健康助手
        if let ai = plan.limits?.aiChat {
            let detail = formatLimit(prefix: "AI 健康助手问答", limit: ai)
            items.append(detail)
        } else {
            items.append("AI 健康助手问答")
        }

        // 舌诊/面诊
        if let tongue = plan.limits?.tongueDiagnosis {
            let detail = formatLimit(prefix: "AI 舌诊/面诊分析", limit: tongue)
            items.append(detail)
        } else {
            items.append("AI 舌诊/面诊分析报告")
        }

        // 睡眠分析
        if let sleep = plan.limits?.sleepAnalysis {
            let detail = formatLimit(prefix: "睡眠分析与洞察", limit: sleep)
            items.append(detail)
        } else {
            items.append("睡眠分析与洞察")
        }

        // AI 教练语音
        if let coach = plan.limits?.aiCoachVoice {
            let detail = formatLimit(prefix: "AI 运动教练实时语音指导", limit: coach)
            items.append(detail)
        } else {
            items.append("AI 运动教练实时语音指导")
        }

        // 白噪音
        items.append("白噪音完整曲库播放")

        // 计划功能开关（PlanFeatures）
        if plan.features?.exclusiveContent == true { items.append("专属内容持续更新") }
        if plan.features?.advancedAnalytics == true { items.append("健康数据高级分析") }
        if plan.features?.prioritySupport == true { items.append("优先客服支持") }
        // 去广告对所有会员套餐生效，始终展示
        items.append("应用内去广告")

        // 去重，避免同类条目重复
        return Array(Set(items)).sorted()
    }

    private func formatLimit(prefix: String, limit: PlanLimitItem) -> String {
        let dailyText: String
        if let d = limit.daily {
            dailyText = d > 0 ? "每日\(d)次" : "每日不限次"
        } else {
            dailyText = "每日不限次"
        }

        var monthlyText = ""
        if let m = limit.monthly {
            monthlyText = m > 0 ? " / 每月\(m)次" : " / 每月不限次"
        }
        return "\(prefix)（\(dailyText)\(monthlyText)）"
    }
}

// 功能行
private struct FeatureRow: View {
    let text: String
    var isSpecial: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isSpecial ? Color(hex: "10B981") : .white.opacity(0.7))
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(isSpecial ? Color(hex: "10B981") : .white.opacity(0.7))
        }
    }
}

// 权益行组件
private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                iconColor.opacity(0.2),
                                iconColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
            }

            // 文字内容
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// 简洁价值要点行
private struct ValuePointRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.95, green: 0.93, blue: 0.90))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

// MARK: - 会员特权故事数据模型
struct BenefitStory: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let detailDescription: String
    let gradient: [Color]
    let emoji: String
}

// MARK: - 滚动监听 Key（会员中心）
private struct MembershipScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - 会员特权故事卡片
struct BenefitStoryCard: View {
    let benefit: BenefitStory
    @State private var animate = false
    @State private var shine = false

    var body: some View {
        ZStack {
            // 背景：分层渐变 + 柔光
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            benefit.gradient.first!.opacity(0.95),
                            benefit.gradient.last!.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // 顶部与右下角的光晕
                    ZStack {
                        RadialGradient(
                            colors: [Color.white.opacity(0.35), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 220
                        )
                        RadialGradient(
                            colors: [Color.white.opacity(0.2), .clear],
                            center: .bottomTrailing,
                            startRadius: 0,
                            endRadius: 260
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                )
                .shadow(color: benefit.gradient.last!.opacity(0.35), radius: 18, x: 0, y: 10)

            // 动态描边（细微动效）
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .white.opacity(0.6),
                            Color.white.opacity(0.1),
                            .white.opacity(0.6)
                        ]),
                        center: .center
                    ),
                    lineWidth: 0.8
                )
                .opacity(0.8)
                .rotationEffect(.degrees(animate ? 360 : 0))
                .animation(.linear(duration: 18).repeatForever(autoreverses: false), value: animate)

            VStack(spacing: 0) {
                // 顶部玻璃球体 + Emoji
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 108, height: 108)
                        .blur(radius: 0.5)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                                .blur(radius: 0.5)
                        )

                    Text(benefit.emoji)
                        .font(.system(size: 56))
                        .scaleEffect(shine ? 1.06 : 0.98)
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
                }
                .frame(height: 132)
                .padding(.top, 16)

                Spacer(minLength: 0)

                // 内容区域
                VStack(spacing: 10) {
                    // 标题 + 芯片
                    HStack(spacing: 8) {
                        Text(benefit.title)
                            .font(AppFont.kangxi(size: 24))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)

                        Text("会员特权")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(Color.white.opacity(0.18))
                            )
                    }

                    Text(benefit.detailDescription)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 24)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding(.bottom, 26)
            }

            // 斜向高光（Shimmer 效果，细微流动）
            ShimmerStroke(cornerRadius: 24)
                .blendMode(.screen)
                .opacity(0.65)
        }
        .frame(height: 300)
        .onAppear {
            animate = true
            withAnimation(
                .easeInOut(duration: 2.2).repeatForever(autoreverses: true)
            ) { shine = true }
        }
    }
}

// MARK: - 细微流光描边
private struct ShimmerStroke: View {
    let cornerRadius: CGFloat
    @State private var move = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(lineWidth: 1.2)
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0),
                        .white.opacity(0.55),
                        .white.opacity(0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .offset(x: move ? 18 : -18, y: move ? -18 : 18)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: move)
            .onAppear { move = true }
    }
}

// MARK: - 横向价格卡片
struct HorizontalPricingCard: View {
    let plan: MembershipPlan
    let isSelected: Bool
    let onSelect: () -> Void
    let onPurchase: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 卡片主体
            VStack(spacing: 16) {
                // 顶部标签（固定高度，保证所有卡片一致）
                Group {
                    if let promotionTag = plan.promotionTag, !promotionTag.isEmpty {
                        HStack {
                            Spacer()
                            Text(promotionTag)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.85, green: 0.35, blue: 0.25),
                                                    Color(red: 0.95, green: 0.45, blue: 0.35)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    } else if plan.isRecommended == true {
                        HStack {
                            Spacer()
                            Text("推荐")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.75, green: 0.55, blue: 0.35),
                                                    Color(red: 0.65, green: 0.45, blue: 0.25)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    } else {
                        // 占位，确保高度一致
                        Color.clear
                    }
                }
                .frame(height: 20)

                // 套餐名称
                Text(plan.planName)
                    .font(AppFont.kangxi(size: 20))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineLimit(1)

                // 价格
                VStack(spacing: 4) {
                    // 原价区域（固定高度）
                    Group {
                        if let originalPrice = plan.originalPrice, originalPrice > plan.price {
                            Text("¥\(formatPrice(originalPrice))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                                .strikethrough()
                        } else {
                            Text(" ") // 占位
                                .font(.system(size: 14, weight: .medium))
                                .opacity(0)
                        }
                    }
                    .frame(height: 18)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("¥")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.65, green: 0.45, blue: 0.25))

                        Text(formatPrice(plan.price))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(red: 0.65, green: 0.45, blue: 0.25))
                    }

                    // 时长区域（固定高度）
                    Group {
                        Text(durationText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    }
                    .frame(height: 16)
                }

                // 购买按钮
                Button(action: onPurchase) {
                    Text("立即购买")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.75, green: 0.55, blue: 0.35),
                                    Color(red: 0.65, green: 0.45, blue: 0.25)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .padding(20)
        }
        .frame(width: 200, height: 260)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ?
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.75, green: 0.55, blue: 0.35),
                                        Color(red: 0.65, green: 0.45, blue: 0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.2),
                                        Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ?
                        Color(red: 0.65, green: 0.45, blue: 0.25).opacity(0.3) :
                        Color.black.opacity(0.05),
                    radius: isSelected ? 12 : 8,
                    x: 0,
                    y: isSelected ? 6 : 4
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .zIndex(isSelected ? 1 : 0)
        .onTapGesture {
            onSelect()
        }
    }

    // 价格格式化：保留一位小数
    private func formatPrice(_ price: Double) -> String {
        return String(format: "%.1f", price)
    }

    // 时长文本 - 显示具体天数
    private var durationText: String {
        // 计算总天数
        let totalDays: Int

        guard let duration = plan.duration else {
            return "30天"
        }

        switch plan.durationType {
        case "month":
            // 智能判断：如果 duration 看起来像天数（≤365），直接当天数用
            // 否则当月数计算
            if duration <= 365 {
                totalDays = duration  // 直接当天数
            } else {
                totalDays = duration * 30  // 当月数计算
            }
        case "year":
            // 年度：如果 duration 看起来像天数（≤3650），直接用
            // 否则当年数计算
            if duration <= 3650 {
                totalDays = duration
            } else {
                totalDays = duration * 365
            }
        case "day":
            totalDays = duration
        default:
            totalDays = duration <= 365 ? duration : 30
        }

        return "\(totalDays)天"
    }
}

// MARK: - 特权行组件
struct PrivilegeRow: View {
    let icon: String
    let title: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(
                    isActive ?
                        Color(red: 0.65, green: 0.45, blue: 0.25) :
                        Color(red: 0.5, green: 0.4, blue: 0.3).opacity(0.5)
                )
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15, weight: isActive ? .medium : .regular))
                .foregroundColor(
                    isActive ?
                        Color(red: 0.2, green: 0.15, blue: 0.1) :
                        Color(red: 0.5, green: 0.4, blue: 0.3)
                )

            Spacer()
        }
    }
}

// MARK: - 预览
#Preview("会员中心 - 已开通会员") {
    let viewModel = MembershipViewModel()
    // 模拟已开通会员状态
    viewModel.status = MembershipStatusData(
        hasMembership: true,
        currentPlan: MembershipPlanRef(
            id: 1,
            planCode: "monthly_auto",
            planName: "连续包月会员",
            planDescription: "最受欢迎的月度订阅"
        ),
        status: "active",
        startDate: "2025-10-01T00:00:00.000Z",
        endDate: "2025-11-29T23:59:59.000Z",
        daysRemaining: 30,
        autoRenew: true,
        source: "apple",
        features: nil,
        limits: nil
    )

    return NavigationStack {
        MembershipCenterView()
            .environmentObject(viewModel)
    }
}

#Preview("会员中心 - 未开通会员") {
    let viewModel = MembershipViewModel()
    // 模拟未开通会员状态
    viewModel.status = MembershipStatusData(
        hasMembership: false,
        currentPlan: nil,
        status: "free",
        startDate: nil,
        endDate: nil,
        daysRemaining: nil,
        autoRenew: nil,
        source: nil,
        features: nil,
        limits: nil
    )

    return NavigationStack {
        MembershipCenterView()
            .environmentObject(viewModel)
    }
}
