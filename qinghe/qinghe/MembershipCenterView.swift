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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero 区域
                heroSection
                    .opacity(showHero ? 1 : 0)
                    .offset(y: showHero ? 0 : 30)
                
                // 90天蜕变之旅
                transformationJourneySection
                    .padding(.top, 60)
                    .opacity(showJourney ? 1 : 0)
                    .offset(y: showJourney ? 0 : 30)
                
                // 真实用户故事
                userStorySection
                    .padding(.top, 60)
                    .opacity(showUserStory ? 1 : 0)
                    .offset(y: showUserStory ? 0 : 30)
                
                // 免费 vs 会员对比
                freeVsPremiumSection
                    .padding(.top, 60)
                    .opacity(showPricing ? 1 : 0)
                    .offset(y: showPricing ? 0 : 30)
                
                // 套餐选择
                pricingSection
                    .padding(.top, 60)
                    .opacity(showPricing ? 1 : 0)
                    .offset(y: showPricing ? 0 : 30)
                
                // 底部保障
                guaranteeSection
                    .padding(.top, 40)
                    .padding(.bottom, 60)
                    .opacity(showPricing ? 1 : 0)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "0A1F1A"),
                    Color(hex: "0D1612")
                ],
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
                        .foregroundColor(.white)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
            // 启动入场动画序列
            withAnimation(.easeOut(duration: 0.6)) {
                showHero = true
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.easeOut(duration: 0.6)) {
                showJourney = true
            }
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.easeOut(duration: 0.6)) {
                showUserStory = true
            }
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.easeOut(duration: 0.6)) {
                showPricing = true
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
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 24) {
            // 顶部标签
            Text("已有 50,000+ 用户开启健康新生活")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "10B981").opacity(0.9))
                .padding(.top, 40)
            
            // 主标题
            VStack(spacing: 12) {
                Text("你离理想的自己")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                Text("只差一个决定")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color(hex: "10B981"))
                    .shadow(
                        color: Color(hex: "10B981").opacity(isAnimating ? 0.6 : 0.2),
                        radius: isAnimating ? 20 : 10
                    )
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            // 副标题
            VStack(spacing: 8) {
                Text("还记得上次精力充沛的感觉吗？还记得一觉到天亮的舒畅吗？")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Text("你的健康，值得被认真对待")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)
            
            // 用户痛点卡片
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Text("😔")
                        .font(.system(size: 40))
                        .rotationEffect(.degrees(emojiRotation))
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: emojiRotation
                        )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\"每天只能问 3 个问题，刚想深入了解就用完了...\"")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\"舌诊只能用 1 次，根本看不出变化趋势...\"")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\"睡眠分析只有 3 次，还没找到规律就没了...\"")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("— 来自免费用户的真实困扰")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 4)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
    
    // MARK: - 90天蜕变之旅
    private var transformationJourneySection: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("你的 90 天蜕变之旅")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("这不只是一个会员，而是一段改变人生的旅程")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            VStack(spacing: 0) {
                // Day 1
                JourneyMilestone(
                    day: "第 1 天",
                    tag: "好奇",
                    title: "开始记录",
                    description: "第一次舌诊，第一次睡眠分析，开始了解自己的身体",
                    color: Color(hex: "10B981"),
                    showLine: true
                )
                
                // Day 7
                JourneyMilestone(
                    day: "第 7 天",
                    tag: "惊喜",
                    title: "发现变化",
                    description: "连续记录一周，AI 发现了你的睡眠规律和体质特点",
                    color: Color(hex: "10B981"),
                    showLine: true
                )
                
                // Day 30
                JourneyMilestone(
                    day: "第 30 天",
                    tag: "自律",
                    title: "养成习惯",
                    description: "健康助手成为你的日常，AI 教练陪你完成了 20 次训练",
                    color: Color(hex: "10B981"),
                    showLine: true
                )
                
                // Day 90
                JourneyMilestone(
                    day: "第 90 天",
                    tag: "蜕变",
                    title: "脱胎换骨",
                    description: "睡眠质量提升 40%，体重下降 8 斤，精力充沛每一天",
                    color: Color(hex: "10B981"),
                    showLine: false
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - 真实用户故事
    private var userStorySection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "10B981").opacity(0.3),
                                        Color(hex: "10B981").opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Text("✨")
                            .font(.system(size: 32))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("真实用户故事")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("来自上海的 Linda，32 岁")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Text("\"作为一个互联网人，长期熬夜让我的身体亮起了红灯。免费试用时，每天 3 次的对话根本不够用，舌诊只能用 1 次，完全看不出变化。\"")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
                
                Text("\"成为年度会员后，一切都变了。每天早上舌诊记录，AI 健康助手随时解答疑问，睡眠分析帮我找到了失眠的根源。\"")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
                
                // 成果展示
                HStack(spacing: 0) {
                    UserStoryMetric(value: "90天", label: "坚持记录", color: Color(hex: "10B981"))
                    
                    Divider()
                        .frame(height: 60)
                        .background(Color.white.opacity(0.2))
                    
                    UserStoryMetric(value: "-12斤", label: "体重下降", color: Color(hex: "10B981"))
                    
                    Divider()
                        .frame(height: 60)
                        .background(Color.white.opacity(0.2))
                    
                    UserStoryMetric(value: "8小时", label: "优质睡眠", color: Color(hex: "10B981"))
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.3))
                )
                
                Text("\"现在的我，精力充沛，皮肤变好，整个人都年轻了。这 169.9 元，是我今年最值的投资。\"")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "10B981").opacity(0.15),
                                Color(hex: "10B981").opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "10B981").opacity(0.4),
                                        Color(hex: "10B981").opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 免费 vs 会员对比
    private var freeVsPremiumSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("免费 vs 会员")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("差的不只是功能，是整个人生")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            VStack(spacing: 16) {
                // AI 健康助手对比
                ComparisonCard(
                    icon: "brain",
                    title: "AI 健康助手",
                    subtitle: "深夜突发不适时",
                    freeText: "每天 3 次对话",
                    premiumText: "无限次深度对话",
                    description: "凌晨 2 点，突然胸闷。免费用户今天的 3 次机会已用完，只能焦虑等待。而会员用户，随时获得专业建议，安心入睡。"
                )
                
                // 舌面诊分析对比
                ComparisonCard(
                    icon: "camera.macro",
                    title: "舌面诊分析",
                    subtitle: "想了解体质变化时",
                    freeText: "共计 1 次体验",
                    premiumText: "每天记录，追踪变化",
                    description: "只用 1 次，看不出任何趋势。成为会员后，连续 30 天的记录让你清晰看到体质的改善曲线。"
                )
                
                // 睡眠分析对比
                ComparisonCard(
                    icon: "moon.zzz",
                    title: "睡眠分析",
                    subtitle: "想改善睡眠质量时",
                    freeText: "每天 3 次分析",
                    premiumText: "全天候监测优化",
                    description: "3 次分析不足以找到失眠原因。会员享受持续监测，AI 帮你发现深层睡眠障碍，制定改善方案。"
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - 套餐选择
    private var pricingSection: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("选择你的蜕变计划")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("投资健康，就是投资未来的自己")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(hex: "10B981"))
                        .padding(.vertical, 60)
                } else {
                    // 显示实际的套餐或默认套餐，过滤掉免费套餐
                    let allPlans = viewModel.plans.isEmpty ? defaultPlans : viewModel.plans
                    let paidPlans = allPlans.filter { $0.price > 0 }
                    
                    ForEach(paidPlans) { plan in
                        PricingPlanCard(
                            plan: plan,
                            isSelected: selectedPlan?.id == plan.id,
                            onSelect: {
                                selectedPlan = plan
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
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - 保障区域
    private var guaranteeSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("支付并同意")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button(action: {
                        showMembershipAgreement = true
                    }) {
                        Text("会员服务协议")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
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
                .foregroundColor(.white.opacity(0.8))
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
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
                planCode: "basic_monthly",
                planName: "基础月度会员",
                planDescription: "适合初次体验",
                price: 29.9,
                originalPrice: nil,
                duration: 1,
                durationType: "month",
                isRecommended: false,
                promotionTag: "入门",
                limits: nil,
                features: nil
            ),
            MembershipPlan(
                id: 2,
                planCode: "standard_monthly",
                planName: "标准月度会员",
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
                planCode: "premium_monthly",
                planName: "高级月度会员",
                planDescription: "享受全部高级功能",
                price: 59.9,
                originalPrice: nil,
                duration: 1,
                durationType: "month",
                isRecommended: false,
                promotionTag: "完整体验",
                limits: nil,
                features: nil
            ),
            MembershipPlan(
                id: 4,
                planCode: "standard_yearly",
                planName: "标准年度会员",
                planDescription: "平均每月更优惠",
                price: 169.0,
                originalPrice: 478.8,
                duration: 12,
                durationType: "month",
                isRecommended: true,
                promotionTag: "推荐",
                limits: nil,
                features: PlanFeatures(adFree: true, prioritySupport: nil, exclusiveContent: nil, advancedAnalytics: nil)
            ),
            MembershipPlan(
                id: 5,
                planCode: "premium_yearly",
                planName: "高级年度会员",
                planDescription: "最佳价值，完整蜕变",
                price: 599.9,
                originalPrice: 718.8,
                duration: 12,
                durationType: "month",
                isRecommended: false,
                promotionTag: "最划算",
                limits: nil,
                features: PlanFeatures(adFree: true, prioritySupport: true, exclusiveContent: true, advancedAnalytics: true)
            )
        ]
    }
}

// MARK: - 子组件

// 旅程里程碑
private struct JourneyMilestone: View {
    let day: String
    let tag: String
    let title: String
    let description: String
    let color: Color
    let showLine: Bool
    @State private var isPulsing = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧时间轴
            VStack(spacing: 0) {
                ZStack {
                    // 外圈脉冲效果
                    Circle()
                        .stroke(color.opacity(isPulsing ? 0.0 : 0.3), lineWidth: 2)
                        .frame(width: 48, height: 48)
                        .scaleEffect(isPulsing ? 1.3 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                    
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 2)
                        .frame(width: 48, height: 48)
                    
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(color)
                }
                .onAppear {
                    isPulsing = true
                }
                
                if showLine {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.5),
                                    color.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 80)
                }
            }
            
            // 右侧内容
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(day)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                    
                    Text("· \(tag)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(4)
            }
            .padding(.top, 4)
            
            Spacer()
        }
    }
}

// 用户故事指标
private struct UserStoryMetric: View {
    let value: String
    let label: String
    let color: Color
    @State private var isGlowing = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
                .shadow(
                    color: color.opacity(isGlowing ? 0.8 : 0.3),
                    radius: isGlowing ? 8 : 4
                )
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: isGlowing
                )
                .onAppear {
                    isGlowing = true
                }
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// 套餐卡片
private struct PricingPlanCard: View {
    let plan: MembershipPlan
    let isSelected: Bool
    let onSelect: () -> Void
    let onPurchase: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // 如果未选中，则选中套餐
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
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // 顶部标签
                if let tag = plan.promotionTag {
                    HStack {
                        Spacer()
                        Text(tag)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "10B981"),
                                                Color(hex: "059669")
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(
                                        color: Color(hex: "10B981").opacity(isSelected ? 0.6 : 0.4),
                                        radius: 10
                                    )
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -10)
                    .zIndex(1)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // 标题和描述
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plan.planName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let desc = plan.planDescription {
                            Text(desc)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    // 价格区域
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(formatPrice(plan.price))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("元/\(durationText)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    
                    // 优惠信息
                    if let original = plan.originalPrice, original > plan.price {
                        HStack(spacing: 8) {
                            Text(String(format: "相比月付节省 %.0f 元", original - plan.price))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "10B981"))
                        }
                    }
                    
                    // 功能列表（根据计划的真实功能与限制构建）
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(buildFeatureTexts(for: plan), id: \.self) { text in
                            FeatureRow(text: text)
                        }

                        // 长周期额外权益
                        if plan.planCode == "quarterly" || plan.planCode == "yearly" {
                            FeatureRow(text: "季度健康评估报告", isSpecial: true)
                        }
                        if plan.planCode == "yearly" {
                            FeatureRow(text: "年度深度体检建议", isSpecial: true)
                            FeatureRow(text: "优先体验新功能", isSpecial: true)
                        }
                    }
                    .padding(.top, 8)
                    
                    // 选择按钮
                    HStack {
                        Spacer()
                        
                        if isSelected {
                            Button(action: {
                                onPurchase()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Apple Pay 支付")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "10B981"),
                                                    Color(hex: "059669")
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(
                                            color: Color(hex: "10B981").opacity(0.6),
                                            radius: 12,
                                            y: 6
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Text("选择此套餐")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "10B981"),
                                                    Color(hex: "059669")
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(
                                            color: Color(hex: "10B981").opacity(0.4),
                                            radius: 8,
                                            y: 4
                                        )
                                )
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    isSelected ?
                    Color.white.opacity(0.1) :
                    Color.white.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ?
                            Color(hex: "10B981").opacity(0.5) :
                            Color.white.opacity(0.1),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ?
                        Color(hex: "10B981").opacity(0.3) :
                        Color.clear,
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
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

// 对比卡片
private struct ComparisonCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let freeText: String
    let premiumText: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题区域
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "10B981").opacity(0.3),
                                    Color(hex: "10B981").opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "10B981"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            // 对比区域
            HStack(spacing: 12) {
                // 免费用户
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("免费用户")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Text(freeText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                
                // 会员专享
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("会员专享")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "10B981"))
                    }
                    
                    Text(premiumText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "10B981"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "10B981").opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "10B981").opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // 描述文字
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
