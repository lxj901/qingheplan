import SwiftUI
import Charts
import EventKit

struct NewRecordCenterView: View {
    @StateObject private var viewModel = NewRecordCenterViewModel()
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedTab = 0
    @State private var selectedRecordType: RecordType? = nil
    @State private var showingAddPlan = false
    @State private var showingRecordHistory = false
    @State private var selectedEmotion: EmotionNew?
    @State private var selectedTemptation: TemptationNew?
    @State private var selectedPlan: PlanNew?

    // 三个标签：情绪记录/诱惑记录/计划管理
    private var tabTitles: [String] {
        [
            localizationManager.localizedString(key: "emotion_record"),
            localizationManager.localizedString(key: "temptation_record"),
            localizationManager.localizedString(key: "plan_management")
        ]
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            // 添加数据加载保护
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                    Text(localizationManager.localizedString(key: "loading"))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            } else {
                VStack(spacing: 0) {
                    // 自律状态卡片
                    selfDisciplineStatusCard
                        .padding(.top, 8)

                    // 分段控制器
                    tabSelector
                        .padding(.vertical, 8)

                    // 内容区域
                    tabContentView
                        .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle(localizationManager.localizedString(key: "record_center"))
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light) // 记录页面不适配深色模式
        .asRootView() // 标记为根视图，显示Tab栏
        // 弹出创建记录类型选择
        .fullScreenCover(item: $selectedRecordType) { type in
            NavigationView {
                switch type {
                case .emotion:
                    EmotionRecordView()
                case .temptation:
                    TemptationRecordView()
                case .plan:
                    CreatePlanView { _ in
                        // 计划创建成功后刷新数据
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                }
            }
        }
        .onChange(of: selectedRecordType) { newValue in
            // 当sheet被dismiss时（newValue变为nil），刷新数据
            if newValue == nil {
                Task {
                    await viewModel.refreshData()
                }
            }
        }
        // 弹出创建计划页面
        .sheet(isPresented: $showingAddPlan) {
            AddPlanView()
        }
        .onChange(of: showingAddPlan) { isPresented in
            // 当计划创建sheet被dismiss时，刷新数据
            if !isPresented {
                Task {
                    await viewModel.refreshData()
                }
            }
        }
        // 弹出历史记录页面
        .sheet(isPresented: $showingRecordHistory) {
            RecordHistoryView()
        }
        // 情绪详情页面
        .sheet(item: $selectedEmotion) { emotion in
            EmotionDetailView(emotion: emotion)
        }
        // 诱惑详情页面
        .sheet(item: $selectedTemptation) { temptation in
            TemptationDetailView(temptation: temptation)
        }
        // 计划详情页面
        .sheet(item: $selectedPlan) { plan in
            PlanDetailView(plan: plan) { updatedPlan in
                // 更新后刷新数据
                Task {
                    await viewModel.refreshData()
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }


    // MARK: - 现代化分段控制器
    private var tabSelector: some View {
        Picker("记录类型", selection: $selectedTab) {
            ForEach(0..<tabTitles.count, id: \.self) { index in
                Text(tabTitles[index])
                    .font(.system(size: 15, weight: .medium))
                    .tag(index)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "heart.fill"      // 情绪记录
        case 1: return "shield.fill"     // 诱惑记录  
        case 2: return "checkmark.circle.fill" // 计划管理
        default: return "circle.fill"
        }
    }

    // MARK: - 内容区域
    private var tabContentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                switch selectedTab {
                case 0:
                    emotionRecordView
                case 1:
                    temptationRecordView
                case 2:
                    todayPlanView
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut, value: selectedTab)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - 今日自律状态
    private var selfDisciplineStatusCard: some View {
        VStack(spacing: 16) {
            // 头部信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日自律")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(getCurrentDateString())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 16)
                
                Spacer()
                
                // 总体评分
                VStack(spacing: 2) {
                    Text("\(calculateOverallScore())")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(getScoreColor())
                    
                    Text("总分")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(getScoreColor().opacity(0.1))
                .cornerRadius(12)
                .padding(.trailing, 16)
            }
            
            // 数据展示区域 - 横向滚动卡片
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 计划完成
                    StatusMetricCard(
                        title: "计划完成",
                        value: "\(max(0, viewModel.planCompletionRate))%",
                        icon: "checkmark.circle.fill",
                        color: Color(hex: "4CAF50"),
                        subtitle: "\(max(0, viewModel.completedPlans))/\(max(0, viewModel.totalPlans)) 已完成"
                    )
                    
                    // 情绪状态
                    StatusMetricCard(
                        title: "情绪状态",
                        value: viewModel.mainEmotion,
                        icon: "heart.fill", 
                        color: Color(hex: "2196F3"),
                        subtitle: "今日主要情绪"
                    )
                    
                    // 抵抗诱惑
                    StatusMetricCard(
                        title: "抵抗诱惑",
                        value: "\(viewModel.temptationResistanceRate)%",
                        icon: "shield.fill",
                        color: Color(hex: "FF9800"),
                        subtitle: "成功抵抗率"
                    )
                    
                    // 记录次数 - 可点击跳转至历史记录页面
                    Button(action: {
                        showingRecordHistory = true
                    }) {
                        StatusMetricCard(
                            title: "记录次数",
                            value: "\(getTotalRecordsCount())",
                            icon: "doc.text.fill",
                            color: Color(hex: "9C27B0"),
                            subtitle: "总记录数"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color(UIColor.systemGray6).opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
    
    // 计算总体评分
    private func calculateOverallScore() -> Int {
        let planScore = max(0, min(100, viewModel.planCompletionRate))
        let temptationScore = max(0, min(100, viewModel.temptationResistanceRate))
        let emotionScore = max(0, min(100, getEmotionScore(viewModel.mainEmotion)))
        
        let totalScore = (planScore + temptationScore + emotionScore) / 3
        return max(0, min(100, totalScore))
    }
    
    // 获取情绪评分
    private func getEmotionScore(_ emotion: String) -> Int {
        switch emotion {
        case "开心", "兴奋", "满足": return 90
        case "平静", "放松": return 80
        case "一般", "普通": return 60
        case "焦虑", "紧张": return 40
        case "难过", "愤怒": return 20
        default: return 60
        }
    }
    
    // 获取评分颜色
    private func getScoreColor() -> Color {
        let score = calculateOverallScore()
        if score >= 80 { return Color(hex: "4CAF50") }
        else if score >= 60 { return Color(hex: "FF9800") }
        else { return Color(hex: "F44336") }
    }
    
    // 获取当前日期字符串
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }
    
    // 获取总记录数
    private func getTotalRecordsCount() -> Int {
        // 这里应该从API获取总记录数，目前使用模拟数据
        // 当前显示的是今日记录数，我们可以添加一个模拟的总记录数
        let todayCount = viewModel.emotionRecords.count + viewModel.temptationRecords.count
        // 假设历史记录是今日记录的10倍左右
        return todayCount + 25  // 添加一个基础值，确保即使今日没有记录也显示有历史记录
    }
    
    // 安全计算进度条宽度
    private func calculateProgressWidth(geometry: GeometryProxy) -> CGFloat {
        // 确保几何尺寸有效
        guard geometry.size.width > 0, 
              geometry.size.width.isFinite,
              geometry.size.width.isNormal else {
            print("⚠️ Invalid geometry width: \(geometry.size.width)")
            return 0
        }
        
        // 确保计划数据有效
        let totalCount = max(0, viewModel.totalPlans)
        let completedCount = max(0, viewModel.completedPlans)
        
        guard totalCount > 0, completedCount >= 0 else {
            return 0
        }
        
        // 计算进度比例，确保在0-1范围内
        let ratio = Double(completedCount) / Double(totalCount)
        
        guard ratio.isFinite, ratio.isNormal || ratio == 0 else {
            print("⚠️ Invalid ratio: \(ratio)")
            return 0
        }
        
        let clampedRatio = max(0, min(1, ratio))
        
        // 计算最终宽度，确保不超过容器宽度
        let width = CGFloat(clampedRatio) * geometry.size.width
        
        // 最终安全检查
        guard width.isFinite, 
              width.isNormal || width == 0,
              width >= 0 else {
            print("⚠️ Invalid calculated width: \(width)")
            return 0
        }
        
        let finalWidth = min(width, geometry.size.width)
        return max(0, finalWidth)
    }
    
    // MARK: - 今日计划视图
    private var todayPlanView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 创建计划提示卡片
            createRecordPromptCard(
                title: "创建新计划",
                description: "设定目标，规划时间，让每一天都有意义",
                icon: "plus.circle.fill",
                color: AppTheme.accentBlue,
                action: { 
                    showingAddPlan = true
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            
            // 计划完成进度
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("今日计划完成进度")
                        .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                    
                    Text("\(max(0, viewModel.completedPlans))/\(max(0, viewModel.totalPlans))")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.primaryGradientStart)
                }
                
                // 现代化进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.systemGray5))
                        
                        let progressWidth = calculateProgressWidth(geometry: geometry)
                        if progressWidth > 0 {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientStart.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, min(progressWidth, geometry.size.width)))
                        }
                    }
                }
                .frame(height: 12)
                
                // 状态统计
                if viewModel.totalPlans > 0 {
                    HStack(spacing: 16) {
                        // 待开始
                        StatusCount(
                            count: viewModel.plans.filter { PlanStatusManager.shared.calculatePlanStatus(for: $0) == .pending }.count,
                            label: "待开始",
                            color: Color(red: 99/255, green: 102/255, blue: 241/255)
                        )

                        // 进行中
                        StatusCount(
                            count: viewModel.plans.filter { PlanStatusManager.shared.calculatePlanStatus(for: $0) == .inProgress }.count,
                            label: "进行中",
                            color: Color(red: 245/255, green: 166/255, blue: 35/255)
                        )

                        // 已完成
                        StatusCount(
                            count: viewModel.plans.filter { PlanStatusManager.shared.calculatePlanStatus(for: $0) == .completed }.count,
                            label: "已完成",
                            color: Color(red: 34/255, green: 197/255, blue: 94/255)
                        )
                    }
                    .font(.system(size: 12, weight: .medium))
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            .padding(.horizontal, 16)
            
            // 进行中的计划
            if viewModel.plans.isEmpty {
                emptyRecordView(
                    message: "今日暂无计划安排",
                    actionTitle: "创建计划",
                    action: {
                        showingAddPlan = true
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.plans, id: \.id) { plan in
                            Button(action: {
                                // 将Plan转换为PlanNew
                                let planNew = PlanNew(
                                    title: plan.title,
                                    description: plan.description,
                                    category: plan.category,
                                    startDate: plan.startDate,
                                    endDate: plan.endDate,
                                    isActive: plan.isActive,
                                    progress: plan.progress
                                )
                                selectedPlan = planNew
                            }) {
                                PlanItemView(plan: plan)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    // MARK: - 情绪记录视图
    private var emotionRecordView: some View {
        VStack(spacing: 12) {
            // 创建记录提示卡片
            createRecordPromptCard(
                title: "记录情绪状态",
                description: "记录当下的情绪变化，了解自己的情感模式",
                icon: "heart.fill",
                color: .pink,
                action: { selectedRecordType = RecordType.emotion }
            )
            
            if viewModel.emotionRecords.isEmpty {
                emptyRecordView(message: "今日暂无情绪记录", 
                              actionTitle: "开始记录", 
                              action: { selectedRecordType = RecordType.emotion })
                    .padding(.top, 8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.emotionRecords) { record in
                            Button(action: {
                                selectedEmotion = record
                            }) {
                                EmotionRecordItemView(record: record)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - 诱惑记录视图
    private var temptationRecordView: some View {
        VStack(spacing: 12) {
            // 创建记录提示卡片
            createRecordPromptCard(
                title: "记录诱惑抵抗",
                description: "记录面对诱惑时的处理方式，提升自控力",
                icon: "shield.fill",
                color: .orange,
                action: { selectedRecordType = RecordType.temptation }
            )
            
            if viewModel.temptationRecords.isEmpty {
                emptyRecordView(message: "今日暂无诱惑记录",
                              actionTitle: "开始记录", 
                              action: { selectedRecordType = RecordType.temptation })
                    .padding(.top, 8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.temptationRecords) { record in
                            Button(action: {
                                selectedTemptation = record
                            }) {
                                TemptationRecordItemView(record: record)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - 空记录视图
    private func emptyRecordView(message: String, actionTitle: String = "开始记录", action: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.top, 16)
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("记录生活点滴，见证成长足迹")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppTheme.primaryGradientStart,
                            AppTheme.primaryGradientStart.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(22)
                .shadow(color: AppTheme.primaryGradientStart.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 创建记录提示卡片
    private func createRecordPromptCard(title: String, description: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标区域
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(color)
                }
                
                // 文本区域
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - 自律分析视图
struct SelfDisciplineAnalysisView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("这里将显示详细的自律分析数据")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("自律分析")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - 计划项视图
struct PlanItemView: View {
    let plan: Plan
    @StateObject private var planStatusManager = PlanStatusManager.shared
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 12) {
                // 顶部：时间和状态
                HStack(alignment: .center) {
                    // 提醒时间
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        Text(plan.reminderTime != nil ? formatTimeFromDate(plan.reminderTime!) : "未设置")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    // 状态标签
                    Text(formatPlanStatus(plan))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(planStatusColor(plan))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(planStatusColor(plan).opacity(0.15))
                        .cornerRadius(12)
                }
                
                // 计划标题
                Text(plan.title)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // 剩余时间描述
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(planStatusManager.getRemainingTimeDescription(for: plan))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // 底部：分类和优先级
                HStack {
                    // 分类
                    Label(plan.category, systemImage: categoryIcon(for: plan.category))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    
                    // 优先级
                    Label(getPlanPriority(plan), systemImage: priorityIcon(for: getPlanPriority(plan)))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(priorityColor(for: getPlanPriority(plan)))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor(for: getPlanPriority(plan)).opacity(0.1))
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    // 预估时间（根据计划持续时间计算）
                    let estimatedDays = Calendar.current.dateComponents([.day], from: plan.startDate, to: plan.endDate).day ?? 0
                    if estimatedDays > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "hourglass")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("\(estimatedDays)天")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - 辅助方法
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "学习": return "book.fill"
        case "工作": return "briefcase.fill"
        case "运动": return "figure.run"
        case "生活": return "house.fill"
        case "健康": return "heart.fill"
        default: return "tag.fill"
        }
    }
    
    private func priorityIcon(for priority: String) -> String {
        switch priority {
        case "高": return "exclamationmark.triangle.fill"
        case "中": return "minus.circle.fill"
        case "低": return "checkmark.circle.fill"
        default: return "circle.fill"
        }
    }
    
    private func priorityColor(for priority: String) -> Color {
        switch priority {
        case "高": return Color(red: 239/255, green: 68/255, blue: 68/255)
        case "中": return Color(red: 245/255, green: 166/255, blue: 35/255)
        case "低": return Color(red: 34/255, green: 197/255, blue: 94/255)
        default: return .gray
        }
    }
}

// MARK: - 情绪记录项视图
struct EmotionRecordItemView: View {
    let record: EmotionNew
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(record.type)
                        .font(.system(size: 18, weight: .medium))
                    
                    Text(getEmotionEmoji(for: record.type))
                        .font(.system(size: 18))
                    
                    Spacer()
                    
                    Text("强度: \(record.intensity)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                if let trigger = record.trigger, !trigger.isEmpty {
                    Text("触发因素: \(trigger)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let note = record.note, !note.isEmpty {
                    Text("备注: \(note)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(formatDate(record.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func getEmotionEmoji(for type: String) -> String {
        switch type {
        case "开心": return "😊"
        case "难过": return "😢"
        case "悲伤": return "😭"
        case "焦虑": return "😰"
        case "愤怒": return "😠"
        case "平静": return "😌"
        case "兴奋": return "🤩"
        case "沮丧": return "😞"
        case "紧张": return "😬"
        case "放松": return "😎"
        case "满足": return "😌"
        case "困惑": return "😕"
        default: return "❓"
        }
    }
}

// MARK: - 诱惑记录项视图
struct TemptationRecordItemView: View {
    let record: TemptationNew
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(record.type)
                        .font(.system(size: 18, weight: .medium))
                    
                    Spacer()
                    
                    Text("强度: \(record.intensity)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("结果: \(record.resisted ? "成功抵抗" : "未能抵抗")")
                        .font(.system(size: 14))
                    
                    if record.resisted {
                        Text("✓")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Text("✗")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                
                if let strategy = record.strategy, !strategy.isEmpty {
                    Text("应对策略: \(strategy)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(formatDate(record.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - 现代化添加计划视图
struct AddPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = "学习"
    @State private var selectedPriority = "中"
    @State private var estimatedTime = 30
    @State private var reminderTime: Date = {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
    }()
    @State private var showingTimePicker = false
    @State private var addToCalendar = false
    @State private var calendarPermissionGranted = false
    @State private var showingCalendarAlert = false
    @State private var calendarAlertMessage = ""
    @State private var isSaving = false
    
    private let eventStore = EKEventStore()
    
    private let categories = ["学习", "工作", "运动", "生活", "健康", "其他"]
    private let priorities = ["低", "中", "高"]
    private let timeOptions = [15, 30, 45, 60, 90, 120]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 现代化背景 - 使用系统动态颜色
                Color(.systemBackground)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // 现代化标题区域
                        modernHeaderSection
                            .padding(.top, 20)
                        
                        // 主要内容区域
                        VStack(spacing: 32) {
                            // 快速模板
                            quickTemplatesSection
                            
                            // 计划信息表单
                            planFormSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 120)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(
                modernFloatingActionBar,
                alignment: .bottom
            )
            .overlay(
                loadingOverlay,
                alignment: .center
            )
            .alert("日历访问", isPresented: $showingCalendarAlert) {
                Button("确定") { }
            } message: {
                Text(calendarAlertMessage)
            }
        }
        .onAppear {
            checkCalendarPermission()
        }
    }
    
    // MARK: - 现代化标题区域
    private var modernHeaderSection: some View {
        VStack(spacing: 20) {
            // 关闭按钮
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // 标题和图标
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryGradientStart.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "target")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(AppTheme.primaryGradientStart)
                }
                
                VStack(spacing: 8) {
                    Text("创建新计划")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("规划时间，成就目标")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var quickTemplatesSection: some View {
        ModernFormCard(
            title: "快速模板",
            subtitle: "选择预设模板，快速创建计划"
        ) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ModernQuickTemplateCard(
                        icon: "book.fill",
                        title: "晨间阅读",
                        description: "专业书籍 • 30分钟",
                        color: .blue,
                        action: {
                            title = "晨间阅读"
                            selectedCategory = "学习"
                            estimatedTime = 30
                        }
                    )
                    
                    ModernQuickTemplateCard(
                        icon: "figure.run",
                        title: "健身锻炼",
                        description: "有氧运动 • 60分钟",
                        color: .orange,
                        action: {
                            title = "健身锻炼"
                            selectedCategory = "运动"
                            estimatedTime = 60
                        }
                    )
                    
                    ModernQuickTemplateCard(
                        icon: "laptopcomputer",
                        title: "专注工作",
                        description: "深度工作 • 90分钟",
                        color: .purple,
                        action: {
                            title = "专注工作"
                            selectedCategory = "工作"
                            estimatedTime = 90
                        }
                    )
                    
                    ModernQuickTemplateCard(
                        icon: "heart.fill",
                        title: "冥想练习",
                        description: "正念冥想 • 15分钟",
                        color: .pink,
                        action: {
                            title = "冥想练习"
                            selectedCategory = "健康"
                            estimatedTime = 15
                        }
                    )
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    private var planFormSection: some View {
        VStack(spacing: 32) {
            // 计划标题
            ModernFormCard(
                title: "计划标题",
                subtitle: "为你的计划起一个有意义的名字"
            ) {
                TextField("输入你的计划目标", text: $title)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(title.isEmpty ? Color.clear : AppTheme.primaryGradientStart.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // 计划描述
            ModernFormCard(
                title: "计划描述",
                subtitle: "详细描述你的计划内容和期望"
            ) {
                TextEditor(text: $description)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(12)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(description.isEmpty ? Color.clear : AppTheme.primaryGradientStart.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        VStack {
                            if description.isEmpty {
                                Text("详细描述你的计划内容...")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }
            
            // 计划分类
            ModernFormCard(
                title: "计划分类",
                subtitle: "选择最适合的计划类型"
            ) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        ModernCategoryButton(
                            title: category,
                            icon: categoryIcon(for: category),
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
            }
            
            // 优先级
            ModernFormCard(
                title: "优先级",
                subtitle: "设置计划的重要程度和紧急性"
            ) {
                VStack(spacing: 16) {
                    // 优先级选择器
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(priorities, id: \.self) { priority in
                            EnhancedPriorityCard(
                                priority: priority,
                                isSelected: selectedPriority == priority,
                                action: { selectedPriority = priority }
                            )
                        }
                    }
                    
                    // 优先级说明
                    if !selectedPriority.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(priorityColor(for: selectedPriority))
                                .font(.system(size: 16))
                            
                            Text(priorityDescription(for: selectedPriority))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(priorityColor(for: selectedPriority).opacity(0.1))
                        .cornerRadius(12)
                        .animation(.easeInOut(duration: 0.3), value: selectedPriority)
                    }
                }
            }
            
            // 预估时间
            ModernFormCard(
                title: "预估时间",
                subtitle: "选择完成这个计划大概需要的时间"
            ) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(timeOptions, id: \.self) { time in
                        ModernTimeButton(
                            minutes: time,
                            isSelected: estimatedTime == time,
                            action: { estimatedTime = time }
                        )
                    }
                }
            }
            
            // 提醒时间
            ModernFormCard(
                title: "提醒时间",
                subtitle: "设置执行计划的提醒时间"
            ) {
                Button(action: { showingTimePicker.toggle() }) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(AppTheme.primaryGradientStart)
                            .font(.system(size: 20))
                        
                        Text(reminderTime, style: .time)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(12)
                }
                .sheet(isPresented: $showingTimePicker) {
                    NavigationView {
                        VStack {
                            DatePicker("选择时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .padding()
                            
                            Spacer()
                        }
                        .navigationTitle("设置提醒时间")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("完成") {
                                    showingTimePicker = false
                                }
                                .foregroundColor(AppTheme.primaryGradientStart)
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
            
            // 写入日历
            ModernFormCard(
                title: "写入日历",
                subtitle: "将计划同步到系统日历，确保不会错过"
            ) {
                VStack(spacing: 20) {
                    // 开关控制
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                                
                                Text("添加到日历")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            Text("创建计划时自动在系统日历中创建对应事件")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $addToCalendar)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .onChange(of: addToCalendar) { newValue in
                                if newValue && !calendarPermissionGranted {
                                    requestCalendarPermission()
                                }
                            }
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    // 权限状态显示
                    if addToCalendar {
                        HStack(spacing: 12) {
                            Image(systemName: calendarPermissionGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(calendarPermissionGranted ? .green : .orange)
                                .font(.system(size: 16))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(calendarPermissionGranted ? "日历权限已授权" : "需要日历权限")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(calendarPermissionGranted ? .green : .orange)
                                
                                Text(calendarPermissionGranted ? 
                                    "计划将自动同步到系统日历" : 
                                    "请在设置中授权访问日历")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if !calendarPermissionGranted {
                                Button("授权") {
                                    requestCalendarPermission()
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .animation(.easeInOut(duration: 0.3), value: calendarPermissionGranted)
                    }
                }
            }
        }
    }
    
    // MARK: - 浮动操作栏
    private var modernFloatingActionBar: some View {
        VStack(spacing: 0) {
            // 渐变遮罩
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.white.opacity(0.8),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)
            
            // 操作按钮区域
            HStack(spacing: 16) {
                // 取消按钮
                Button("取消") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(26)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                
                // 保存按钮
                Button(action: {
                    Task {
                        await savePlan()
                    }
                }) {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("创建中...")
                                .font(.system(size: 16, weight: .bold))
                        } else {
                            Text("创建计划")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .background(
                        (title.isEmpty || isSaving) ? Color.gray.opacity(0.5) : AppTheme.primaryGradientStart
                    )
                    .cornerRadius(26)
                    .shadow(color: AppTheme.primaryGradientStart.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(title.isEmpty || isSaving)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
            .background(Color.white)
        }
    }
    
    // MARK: - 加载遮罩
    private var loadingOverlay: some View {
        VStack {
            if isSaving {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryGradientStart))
                            .scaleEffect(1.2)
                        
                        Text("创建计划中...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    )
                }
            }
        }
    }
    
    // MARK: - 辅助函数
    private func priorityColor(for priority: String) -> Color {
        switch priority {
        case "高": return Color(red: 239/255, green: 68/255, blue: 68/255)
        case "中": return Color(red: 245/255, green: 166/255, blue: 35/255)
        case "低": return Color(red: 34/255, green: 197/255, blue: 94/255)
        default: return .gray
        }
    }
    
    private func priorityDescription(for priority: String) -> String {
        switch priority {
        case "高": return "紧急重要，需要立即处理的计划"
        case "中": return "重要但不紧急，可以安排时间完成"
        case "低": return "不紧急不重要，空闲时间可以处理"
        default: return ""
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "学习": return "book.fill"
        case "工作": return "briefcase.fill"
        case "运动": return "figure.run"
        case "生活": return "house.fill"
        case "健康": return "heart.fill"
        default: return "ellipsis.circle.fill"
        }
    }
    
    // MARK: - Calendar Methods
    private func checkCalendarPermission() {
        let status = EKEventStore.authorizationStatus(for: .event)
        calendarPermissionGranted = (status == .authorized)
    }
    
    private func requestCalendarPermission() {
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                calendarPermissionGranted = granted
                if let error = error {
                    calendarAlertMessage = "获取日历权限失败: \(error.localizedDescription)"
                    showingCalendarAlert = true
                } else if !granted {
                    calendarAlertMessage = "需要日历权限才能将计划同步到系统日历。请前往设置 > 隐私与安全性 > 日历 中授权。"
                    showingCalendarAlert = true
                }
            }
        }
    }
    
    private func createCalendarEvent() -> Bool {
        guard calendarPermissionGranted else { return false }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = description.isEmpty ? nil : description
        event.startDate = reminderTime
        event.endDate = Calendar.current.date(byAdding: .minute, value: estimatedTime, to: reminderTime) ?? reminderTime
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // 添加提醒
        let alarm = EKAlarm(absoluteDate: reminderTime)
        event.addAlarm(alarm)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            DispatchQueue.main.async {
                calendarAlertMessage = "创建日历事件失败: \(error.localizedDescription)"
                showingCalendarAlert = true
            }
            return false
        }
    }
    
    private func savePlan() async {
        isSaving = true
        
        do {
            // 创建计划请求模型
            // 开始时间设置为今天，提醒时间单独设置
            let today = Calendar.current.startOfDay(for: Date())

            // 根据预估时间计算结束时间
            let estimatedTimeInSeconds = TimeInterval(estimatedTime * 60)
            let calculatedEndDate = reminderTime.addingTimeInterval(estimatedTimeInSeconds)

            let planRequest = PlanRequestNew(
                title: title,
                description: description.isEmpty ? "无描述" : description,
                category: selectedCategory,
                startDate: today,
                endDate: calculatedEndDate,
                goals: [],
                reminderTime: reminderTime
            )
            
            // 调用API创建计划
            let createdPlan = try await PlanService.shared.createPlan(planRequest)

            // 保存提醒时间到本地存储
            PlanReminderManager.shared.saveReminderTime(for: createdPlan.title, reminderTime: reminderTime)

            // 将PlanNew转换为Plan以便状态管理
            let _ = Plan(
                title: createdPlan.title,
                description: createdPlan.description,
                category: createdPlan.category,
                startDate: createdPlan.startDate,
                endDate: createdPlan.endDate,
                isActive: createdPlan.isActive,
                progress: createdPlan.progress,
                reminderTime: reminderTime
            )
            
            // 如果启用了日历集成且有权限，创建日历事件
            if addToCalendar && calendarPermissionGranted {
                let calendarSuccess = createCalendarEvent()
                if calendarSuccess {
                    calendarAlertMessage = "计划已成功创建并添加到日历，通知已设置"
                } else {
                    calendarAlertMessage = "计划创建成功，通知已设置，但添加到日历失败"
                }
                showingCalendarAlert = true
            } else {
                calendarAlertMessage = "计划创建成功，通知已设置"
                showingCalendarAlert = true
            }
            
            print("✅ 计划创建成功: ID=\(createdPlan.id), 标题=\(createdPlan.title)")
            
        } catch {
            print("❌ 计划创建失败: \(error.localizedDescription)")
            calendarAlertMessage = "计划创建失败: \(error.localizedDescription)"
            showingCalendarAlert = true
        }
        
        isSaving = false
        
        // 延迟关闭页面，让用户看到反馈信息
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - 现代化组件

// 增强的优先级卡片
struct EnhancedPriorityCard: View {
    let priority: String
    let isSelected: Bool
    let action: () -> Void
    
    private var priorityColor: Color {
        switch priority {
        case "高": return Color(red: 239/255, green: 68/255, blue: 68/255)
        case "中": return Color(red: 245/255, green: 166/255, blue: 35/255)
        case "低": return Color(red: 34/255, green: 197/255, blue: 94/255)
        default: return .gray
        }
    }
    
    private var priorityIcon: String {
        switch priority {
        case "高": return "exclamationmark.triangle.fill"
        case "中": return "minus.circle.fill"
        case "低": return "checkmark.circle.fill"
        default: return "circle.fill"
        }
    }
    
    private var priorityLevel: String {
        switch priority {
        case "高": return "HIGH"
        case "中": return "MED"
        case "低": return "LOW"
        default: return ""
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // 顶部图标区域
                ZStack {
                    Circle()
                        .fill(isSelected ? priorityColor : priorityColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: priorityIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : priorityColor)
                }
                
                // 文字区域
                VStack(spacing: 4) {
                    Text(priority)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? priorityColor : .primary)
                    
                    Text(priorityLevel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isSelected ? priorityColor.opacity(0.8) : .secondary)
                        .tracking(1.2)
                }
                
                Spacer()
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? priorityColor.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? priorityColor : priorityColor.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? priorityColor.opacity(0.2) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .buttonStyle(ScaleButtonStyle())
    }
}

// 现代化快速模板卡片
struct ModernQuickTemplateCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(color.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(16)
            .frame(width: 140, height: 110)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// 现代化表单区块
struct ModernFormSection<Content: View>: View {
    let title: String
    let isRequired: Bool
    let content: Content
    
    init(title: String, isRequired: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isRequired = isRequired
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                if isRequired {
                    Text("*")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            
            content
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// 现代化文本输入框样式
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.clear, lineWidth: 1)
            )
    }
}

// 现代化分类按钮
struct ModernCategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : AppTheme.primaryGradientStart)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.primaryGradientStart : Color(UIColor.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : AppTheme.primaryGradientStart.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// 现代化优先级按钮
struct ModernPriorityButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private var priorityColor: Color {
        switch title {
        case "高": return .red
        case "中": return .orange
        case "低": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? priorityColor : Color(UIColor.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : priorityColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// 现代化时间按钮
struct ModernTimeButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isSelected ? .white : AppTheme.primaryGradientStart)
                
                Text("分钟")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.primaryGradientStart : Color(UIColor.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : AppTheme.primaryGradientStart.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// 保留原有的快速开始选项视图（向后兼容）
struct QuickStartOptionView: View {
    let icon: String
    let title: String
    let description: String
    let duration: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.primaryGradientStart)
                
                Spacer()
                
                Text(duration)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 160, height: 120)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 分类按钮
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                getCategoryIcon(for: title)
                    .foregroundColor(isSelected ? Color(hex: "4CAF50") : .secondary)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? Color(hex: "4CAF50") : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "E8F5E9") : Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private func getCategoryIcon(for category: String) -> some View {
        switch category {
        case "学习":
            return Image(systemName: "book.fill")
        case "工作":
            return Image(systemName: "briefcase.fill")
        case "运动":
            return Image(systemName: "figure.run")
        case "生活":
            return Image(systemName: "house.fill")
        default:
            return Image(systemName: "ellipsis.circle.fill")
        }
    }
}


// 格式化日期
func formatDate(_ dateString: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    
    guard let date = dateFormatter.date(from: dateString) else {
        return dateString
    }
    
    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    return outputFormatter.string(from: date)
}

// MARK: - 自定义按钮样式
// ScaleButtonStyle 已在 SharedTypes.swift 中定义

// MARK: - 状态计数组件
struct StatusCount: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("\(count)")
                .foregroundColor(color)
                .fontWeight(.semibold)
            
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 状态指标卡片
struct StatusMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(width: 120, height: 80)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 快速操作按钮
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            QuickActionButtonContent(title: title, icon: icon, color: color)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - 快速操作按钮内容
struct QuickActionButtonContent: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [color, color.opacity(0.8)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 预览
struct NewRecordCenterView_Previews: PreviewProvider {
    static var previews: some View {
        NewRecordCenterView()
    }
}

// MARK: - 辅助函数
// 格式化时间
func formatTime(_ timeString: String?) -> String {
    guard let timeString = timeString else { return "未设置" }
    if timeString.contains("T") {
        return formatDate(timeString)
    }
    return timeString
}

// 格式化Date类型的时间
func formatTimeFromDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.locale = Locale(identifier: "zh_CN")
    return formatter.string(from: date)
}

// 格式化计划状态（统一使用 PlanStatusManager 计算）
@MainActor
func formatPlanStatus(_ plan: Plan) -> String {
    let status = PlanStatusManager.shared.calculatePlanStatus(for: plan)
    return status.displayName
}

// 计划状态颜色（统一使用 PlanStatusManager 计算）
@MainActor
func planStatusColor(_ plan: Plan) -> Color {
    let status = PlanStatusManager.shared.calculatePlanStatus(for: plan)
    switch status {
    case .completed:
        return .green
    case .inProgress:
        return .blue
    case .pending:
        return .orange
    case .cancelled:
        return .red
    case .expired:
        return .gray
    }
}

// 获取计划优先级（Plan模型没有priority属性，根据其他属性推断）
func getPlanPriority(_ plan: Plan) -> String {
    // 根据计划的结束时间和当前时间来推断优先级
    let now = Date()
    let timeInterval = plan.endDate.timeIntervalSince(now)
    let daysRemaining = timeInterval / (24 * 60 * 60)

    if daysRemaining < 7 {
        return "高"
    } else if daysRemaining < 30 {
        return "中"
    } else {
        return "低"
    }
}

// 格式化状态
func formatStatus(_ status: String) -> String {
    switch status {
    case "completed":
        return "已完成"
    case "in_progress":
        return "进行中"
    case "pending":
        return "待开始"
    case "expired":
        return "已过期"
    case "cancelled":
        return "已取消"
    default:
        return status
    }
}

// 状态颜色
func statusColor(_ status: String) -> Color {
    switch status {
    case "completed":
        return Color(red: 34/255, green: 197/255, blue: 94/255)  // 绿色
    case "in_progress":
        return Color(red: 245/255, green: 166/255, blue: 35/255) // 橙色
    case "pending":
        return Color(red: 99/255, green: 102/255, blue: 241/255) // 蓝色
    case "expired":
        return Color(red: 239/255, green: 68/255, blue: 68/255)  // 红色
    case "cancelled":
        return Color(red: 107/255, green: 114/255, blue: 128/255) // 灰色
    default:
        return .gray
    }
}

// MARK: - RecordType Enum
enum RecordType: String, CaseIterable, Identifiable {
    case emotion = "emotion"
    case temptation = "temptation"
    case plan = "plan"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .emotion: return "情绪记录"
        case .temptation: return "诱惑记录"
        case .plan: return "计划管理"
        }
    }
}

