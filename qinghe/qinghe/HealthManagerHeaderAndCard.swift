import SwiftUI
import UIKit
import AVFoundation
import Vision


// 顶部欢迎区 + 右侧插画占位
struct HeaderSection: View {
    var showTexts: Bool = true
    var onOpenAssistant: (() -> Void)? = nil
    @ObservedObject private var authManager = AuthManager.shared

    private var registerDays: Int {
        guard let createdAt = authManager.currentUser?.createdAt, !createdAt.isEmpty else { return 0 }
        if let date = parseDate(createdAt) {
            let start = Calendar.current.startOfDay(for: date)
            let today = Calendar.current.startOfDay(for: Date())
            return max(0, Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0)
        }
        return 0
    }

    private var todayString: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }


    private func parseDate(_ s: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: s) { return d }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        for f in ["yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd"] {
            df.dateFormat = f
            if let d = df.date(from: s) { return d }
        }
        return nil
    }

    var body: some View {
        HStack(alignment: .top) {
            // 标题与副标题
            VStack(alignment: .leading, spacing: 10) {
                if showTexts {
                    ChatInviteBubble(onTapAssistant: { onOpenAssistant?() })
                        .padding(.top, 8) // 向下移动一点
                }
            }
            .padding(.top, 0)
            .padding(.leading, 12)
            Spacer()
            // 右侧插画占位（可替换为设计资源）
            ZStack(alignment: .top) {
                ConcentricWavesView(base: 36, step: 12, count: 5)
                    .frame(width: 110, height: 110)
                    .opacity(0.30)
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 110, height: 110)
                Group {
                    if let ui = UIImage(named: "health_bird") ?? UIImage(named: "test") {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: "bird")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.white)
                    }
                }
                .frame(width: 165, height: 165)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 6)
            }
        }
        .padding(.bottom, 0) // 让卡片与 IP 底部贴底（配合外部 spacing=0）
    }
}

// MARK: - 顶部聊天引导气泡
private struct ChatInviteBubble: View {
    var onTapAssistant: (() -> Void)? = nil
    @StateObject private var healthDataManager = HealthProfileDataManager.shared
    @State private var currentBubbleIndex = 0
    
    // 气泡内容类型
    enum BubbleContentType {
        case healthCompanion    // 健康陪伴型
        case dataRelated       // 数据关联型
        case topicGuided       // 话题引导型
        case emotionalSupport  // 情感陪伴型
    }
    
    // 气泡内容配置
    struct BubbleContent {
        let title: String
        let subtitle: String
        let type: BubbleContentType
    }
    
    // 所有可用的气泡内容
    private let bubbleContents: [BubbleContent] = [
        // 健康陪伴型
        BubbleContent(
            title: "今天感觉怎么样？",
            subtitle: "想和我聊聊身体的小信号吗？",
            type: .healthCompanion
        ),
        BubbleContent(
            title: "我在这儿等你",
            subtitle: "有健康困惑随时问我",
            type: .healthCompanion
        ),
        BubbleContent(
            title: "身体的变化，一句话就能发现线索",
            subtitle: "要不要聊聊？",
            type: .healthCompanion
        ),
        
        // 数据关联型
        BubbleContent(
            title: "你的健康数据更新啦",
            subtitle: "需要我帮你解读一下吗？",
            type: .dataRelated
        ),
        BubbleContent(
            title: "想知道最近舌诊/面诊有什么变化吗？",
            subtitle: "可以和我聊聊哦",
            type: .dataRelated
        ),
        BubbleContent(
            title: "结果只是一个参考",
            subtitle: "结合你的日常习惯聊一聊会更准确",
            type: .dataRelated
        ),
        
        // 话题引导型
        BubbleContent(
            title: "最近睡眠怎么样？",
            subtitle: "或者你想问问饮食、运动都行",
            type: .topicGuided
        ),
        BubbleContent(
            title: "不知道该从哪开始？",
            subtitle: "你可以直接问我：'怎么改善气色？'",
            type: .topicGuided
        ),
        BubbleContent(
            title: "随便说说今天的状态",
            subtitle: "我能帮你找健康建议",
            type: .topicGuided
        ),
        
        // 情感陪伴型
        BubbleContent(
            title: "就像和朋友聊天一样",
            subtitle: "告诉我你的感受，我来帮你分析",
            type: .emotionalSupport
        )
    ]
    
    // 根据场景选择合适的气泡内容
    private var currentBubbleContent: BubbleContent {
        let appropriateContents = getAppropriateContents()
        let index = currentBubbleIndex % appropriateContents.count
        return appropriateContents[index]
    }
    
    // 获取适合当前场景的内容
    private func getAppropriateContents() -> [BubbleContent] {
        let now = Date()
        let lastUpdateTime = healthDataManager.lastUpdateTime ?? Date.distantPast
        let timeSinceUpdate = now.timeIntervalSince(lastUpdateTime)
        
        // 数据更新后（2小时内）→ 数据关联型
        if timeSinceUpdate < 2 * 3600 {
            return bubbleContents.filter { $0.type == .dataRelated }
        }
        
        // 用户久未互动（超过1天）→ 健康陪伴型 + 情感陪伴型
        if timeSinceUpdate > 24 * 3600 {
            return bubbleContents.filter { 
                $0.type == .healthCompanion || $0.type == .emotionalSupport 
            }
        }
        
        // 日常打开 → 话题引导型
        return bubbleContents.filter { $0.type == .topicGuided }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(currentBubbleContent.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black.opacity(0.95))
                    .lineLimit(2)
                Text(currentBubbleContent.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.6))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black.opacity(0.5))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .frame(maxWidth: 280) // 设置最大宽度
        .background(
            BubbleWithRightPointer()
                .fill(Color.white.opacity(0.96))
        )
        .overlay(
            BubbleWithRightPointer()
                .stroke(Color.black.opacity(0.08), lineWidth: 0.6)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .onAppear {
            // 页面加载时随机选择一个内容索引
            currentBubbleIndex = Int.random(in: 0..<bubbleContents.count)
        }
        .onTapGesture {
            // 点击时切换到下一个内容（同类型内循环）
            let appropriateContents = getAppropriateContents()
            currentBubbleIndex = (currentBubbleIndex + 1) % appropriateContents.count

            // 短暂延时后打开健康助手（回调由上层处理）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onTapAssistant?()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentBubbleContent.title)
    }
}

// 健康报告卡片
struct AskSuggestionsCard: View {
    var showHealthRecordRow: Bool = true
    var showSuggestionRows: Bool = true
    
    @StateObject private var healthDataManager = HealthProfileDataManager.shared
    @ObservedObject private var sleepManager = SleepDataManager.shared
    @StateObject private var healthReportManager = HealthReportManager.shared
    @State private var selectedDate: Date = Date() // 添加选中日期状态
    @State private var isLoadingReport = false // 添加加载状态
    @State private var currentReportData: HealthReportData? // 当前报告数据

    // 获取当前日期
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // 动态健康指标数据（基于真实API数据）
    private var dynamicMetrics: [RadarMetric] {
        let overallScore = Double(healthDataManager.overallHealthScore)
        let constitutionScore = overallScore > 0 ? overallScore : 75.0 // 基于体质分析得分
        let sleepScore = Double(calculateSleepScore())
        let exerciseScore = 60.0 // 暂时使用默认值，待运动数据API
        let bmiScore = Double(calculateBMIScore())
        
        return [
            RadarMetric(name: "综合", value: overallScore > 0 ? overallScore : 75.0),
            RadarMetric(name: "体质", value: constitutionScore),
            RadarMetric(name: "运动", value: exerciseScore),
            RadarMetric(name: "睡眠", value: sleepScore),
            RadarMetric(name: "BMI", value: bmiScore)
        ]
    }

    // 体质分析数据（基于真实API数据）
    private var dynamicConstitution: ConstitutionAnalysisData {
        // 优先使用健康报告中的体质分析数据
        if let constitutionAnalysis = healthDataManager.healthReport?.detailedAnalysis?.constitution,
           let primaryConstitution = constitutionAnalysis.primaryConstitution {
            
            let secondaryConstitution = constitutionAnalysis.secondaryConstitution ?? "气虚质"
            let confidence = constitutionAnalysis.confidence ?? 0.85
            let score = constitutionAnalysis.score ?? healthDataManager.overallHealthScore
            let physiqueAnalysis = constitutionAnalysis.physiqueAnalysis ?? "基于您的健康报告分析得出"
            let recommendations = constitutionAnalysis.recommendations ?? generatePersonalizedRecommendations()
            
            return ConstitutionAnalysisData(
                hasAnalysis: true,
                primaryConstitution: primaryConstitution,
                secondaryConstitution: secondaryConstitution,
                confidence: confidence,
                organDistribution: ConstitutionAnalysisData.sample.organDistribution,
                nineConstitutionScores: ConstitutionAnalysisData.sample.nineConstitutionScores,
                recommendations: recommendations,
                score: score,
                physiqueName: primaryConstitution,
                physiqueAnalysis: physiqueAnalysis,
                typicalSymptom: ConstitutionAnalysisData.sample.typicalSymptom,
                riskWarning: ConstitutionAnalysisData.sample.riskWarning,
                features: ConstitutionAnalysisData.sample.features,
                syndromeName: ConstitutionAnalysisData.sample.syndromeName,
                syndromeIntroduction: ConstitutionAnalysisData.sample.syndromeIntroduction,
                tfDetectMatches: ConstitutionAnalysisData.sample.tfDetectMatches,
                adviceSections: ConstitutionAnalysisData.sample.adviceSections,
                goods: ConstitutionAnalysisData.sample.goods
            )
        }
        
        // 其次使用舌诊分析中的体质结果
        let hasRealData = healthDataManager.healthProfile?.primaryConstitution != nil
        
        if hasRealData {
            // 使用健康档案中的数据创建体质分析数据
            let primaryConstitution = healthDataManager.primaryConstitution
            let score = healthDataManager.overallHealthScore
            
            return ConstitutionAnalysisData(
                hasAnalysis: true,
                primaryConstitution: primaryConstitution,
                secondaryConstitution: "气虚质", // 暂时使用默认值
                confidence: 0.82,
                organDistribution: ConstitutionAnalysisData.sample.organDistribution,
                nineConstitutionScores: ConstitutionAnalysisData.sample.nineConstitutionScores,
                recommendations: generatePersonalizedRecommendations(),
                score: score,
                physiqueName: primaryConstitution,
                physiqueAnalysis: "基于您的健康档案分析得出",
                typicalSymptom: ConstitutionAnalysisData.sample.typicalSymptom,
                riskWarning: ConstitutionAnalysisData.sample.riskWarning,
                features: ConstitutionAnalysisData.sample.features,
                syndromeName: ConstitutionAnalysisData.sample.syndromeName,
                syndromeIntroduction: ConstitutionAnalysisData.sample.syndromeIntroduction,
                tfDetectMatches: ConstitutionAnalysisData.sample.tfDetectMatches,
                adviceSections: ConstitutionAnalysisData.sample.adviceSections,
                goods: ConstitutionAnalysisData.sample.goods
            )
        } else {
            return .sample
        }
    }

    // 五运六气数据（基于真实API数据和玫瑰图需要的格式）
    private var dynamicWYCard: WYCardData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        
        // 从API数据中提取信息，如果没有则使用默认值
        let fiveElements = healthDataManager.fiveElementsAnalysis
        let mainYun = fiveElements?.fiveMovements?.element ?? "金"
        let nature = fiveElements?.fiveMovements?.nature ?? "不及"
        let mainQi = extractMainQi(from: fiveElements?.sixQi?.qi)
        
        return WYCardData(
            dateText: dateFormatter.string(from: Date()),
            mainYun: mainYun,
            mainQi: mainQi,
            excessType: nature,
            siTian: mainQi, // 司天暂时使用主气
            zaiQuan: "风", // 在泉暂时使用默认值
            yunStrength: generateYunStrength(mainElement: mainYun),
            qiStrength: generateQiStrength(mainQi: mainQi),
            advice: generateWYAdvice()
        )
    }
    
    // 从六气名称中提取主要气（去掉阴阳前缀）
    private func extractMainQi(from qiName: String?) -> String {
        guard let qi = qiName else { return "燥" }
        
        if qi.contains("风") { return "风" }
        if qi.contains("火") { return "火" }
        if qi.contains("湿") || qi.contains("土") { return "湿" }
        if qi.contains("燥") || qi.contains("金") { return "燥" }
        if qi.contains("寒") || qi.contains("水") { return "寒" }
        
        return "燥" // 默认值
    }
    
    // 根据主运生成运强度分布
    private func generateYunStrength(mainElement: String) -> [String: Double] {
        var base: [String: Double] = ["木": 0.2, "火": 0.2, "土": 0.2, "金": 0.2, "水": 0.2]
        
        // 增强当前主运的强度
        switch mainElement {
        case "金": base["金"] = 0.6
        case "木": base["木"] = 0.6
        case "水": base["水"] = 0.6
        case "火": base["火"] = 0.6
        case "土": base["土"] = 0.6
        default: base["金"] = 0.6
        }
        
        return base
    }
    
    // 根据主气生成气强度分布
    private func generateQiStrength(mainQi: String) -> [String: Double] {
        var base: [String: Double] = ["风": 0.17, "暑": 0.17, "湿": 0.17, "燥": 0.17, "寒": 0.16, "火": 0.16]
        
        // 增强当前主气的强度
        switch mainQi {
        case "燥": base["燥"] = 0.5
        case "风": base["风"] = 0.5
        case "火": base["火"] = 0.5
        case "湿": base["湿"] = 0.5
        case "寒": base["寒"] = 0.5
        case "暑": base["暑"] = 0.5
        default: base["燥"] = 0.5
        }
        
        return base
    }
    
    // 生成五运六气建议（格式化为WYAdviceItem）
    private func generateWYAdvice() -> [WYAdviceItem] {
        let adviceTexts = generateFiveElementsAdvice()
        
        return adviceTexts.enumerated().map { index, text in
            let reason = index == 0 ? "基于当前五运特点" : "基于当前六气特点"
            return WYAdviceItem(text: text, reason: reason)
        }
    }
    
    // 计算睡眠评分
    private func calculateSleepScore() -> Int {
        let todaySleepHours = sleepManager.todaySleepDuration / 3600
        
        if todaySleepHours >= 7 && todaySleepHours <= 9 {
            return 85
        } else if todaySleepHours >= 6 && todaySleepHours <= 10 {
            return 70
        } else if todaySleepHours >= 5 && todaySleepHours <= 11 {
            return 55
        } else {
            return 40
        }
    }
    
    // 计算BMI评分
    private func calculateBMIScore() -> Int {
        guard let height = healthDataManager.healthProfile?.height,
              let weight = healthDataManager.healthProfile?.weight,
              height > 0 else {
            return 75 // 默认值
        }
        
        let heightInMeters = height / 100
        let bmi = weight / (heightInMeters * heightInMeters)
        
        if bmi >= 18.5 && bmi <= 24.9 {
            return 90
        } else if bmi >= 25 && bmi <= 29.9 {
            return 70
        } else {
            return 50
        }
    }
    
    // 生成个性化建议
    private func generatePersonalizedRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let constitution = healthDataManager.primaryConstitution
        let sleepScore = calculateSleepScore()
        
        if constitution.contains("气虚") {
            recommendations.append("适当补气食物，如黄芪、人参")
        } else if constitution.contains("阳虚") {
            recommendations.append("注意保暖，多食温补食材")
        } else if constitution.contains("阴虚") {
            recommendations.append("滋阴润燥，多食银耳、枸杞")
        } else {
            recommendations.append("保持规律作息，适当午休")
        }
        
        if sleepScore < 70 {
            recommendations.append("改善睡眠质量，建议21:30前就寝")
        }
        
        recommendations.append("饮食清淡，忌辛辣油腻，增加蔬果摄入")
        
        return recommendations
    }
    
    // 生成五运六气建议
    private func generateFiveElementsAdvice() -> [String] {
        var advice: [String] = []
        
        // 从五运六气分析中获取建议
        if let fiveElements = healthDataManager.fiveElementsAnalysis {
            if let fiveMovements = fiveElements.fiveMovements {
                advice.append(fiveMovements.influence ?? "根据五运调养身体")
            }
            
            if let sixQi = fiveElements.sixQi {
                advice.append(sixQi.influence ?? "根据六气调理脏腑")
            }
        }
        
        // 如果没有API数据，使用默认建议
        if advice.isEmpty {
            advice = [
                "循节气调养，避免辛辣煎炸",
                "早睡早起，适当晨练，顺应木气升发",
                "居室常通风，注意润燥护肺"
            ]
        }
        
        return advice
    }

    // 五运六气 新卡片演示数据（与体质联动可后续接入）
    private var sampleWYCard: WYCardData {
        WYCardData(
            dateText: {
                let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"; df.locale = Locale(identifier: "zh_CN");
                return df.string(from: Date())
            }(),
            mainYun: "金",
            mainQi: "燥",
            excessType: "太过",
            siTian: "燥",
            zaiQuan: "风",
            yunStrength: ["木":0.24, "火":0.31, "土":0.27, "金":0.52, "水":0.18],
            qiStrength: ["风":0.28, "暑":0.12, "湿":0.35, "燥":0.66, "寒":0.14, "火":0.22],
            advice: [
                WYAdviceItem(text: "加湿器维持室内湿度 45%~55%", reason: "外圈燥偏强且体质偏阴虚，需增湿润肺"),
                WYAdviceItem(text: "晚间温水泡脚 15 分钟", reason: "助阳护肾、缓解燥气所致睡眠不稳"),
                WYAdviceItem(text: "运动选择低强度慢跑 20~30 分钟", reason: "避免过汗耗津，加重燥象")
            ]
        )
    }


    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 顶部：周日历条（替换原日期/英文/节气图标）
            WeekCalendarStripView(
                selectedDate: $selectedDate,
                onDateSelected: { date in
                    // 日期选择回调，加载该日期的数据
                    Task {
                        await loadHealthReportForDate(date)
                    }
                }
            )
            .padding(.top, 4)

            // 根据选中日期和数据状态显示内容
            if isLoadingReport {
                VStack(spacing: 16) {
                    ProgressView("正在加载...")
                        .frame(height: 100)
                }
            } else if let reportData = currentReportData {
                // 显示基于选中日期的健康卡片
                HealthRadarCard(metrics: getMetricsFromReport(reportData))
                ConstitutionAnalysisCard(data: getConstitutionFromReport(reportData))
                NavigationLink(destination: WuYunLiuQiView()) {
                    WuYunLiuQiSummaryCard(data: getWuYunFromReport(reportData))
                }
            } else if healthReportManager.hasReport(for: selectedDate) {
                // 使用原有的动态数据显示
                HealthRadarCard(metrics: dynamicMetrics)
                ConstitutionAnalysisCard(data: dynamicConstitution)
                NavigationLink(destination: WuYunLiuQiView()) {
                    WuYunLiuQiSummaryCard(data: dynamicWYCard)
                }
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                        Text("今日无报告")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    }
                    Text("健康报告每 3 天生成一次，请在报告生成后查看健康维度概览、体质分析与五运六气")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.45))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .modernCardPadding()
                .modernCard()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.78))
                .background(
                    // 卡片内轻雾化高光
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
                        .shadow(color: .white.opacity(0.35), radius: 20, x: 0, y: 6)
                        .blur(radius: 0)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.45), lineWidth: 0.5)
        )
        .padding(.top, -28) // 紧贴 IP 底部，无保留间距
        .task {
            // 页面加载时获取健康数据
            await healthDataManager.refreshAllData()
            // 加载当前日期的报告数据
            await loadHealthReportForDate(selectedDate)
        }
        .refreshable {
            // 下拉刷新时重新获取数据
            await healthDataManager.refreshAllData()
            await loadHealthReportForDate(selectedDate)
        }
    }
    
    // MARK: - 辅助方法
    
    /// 加载指定日期的健康报告
    @MainActor
    private func loadHealthReportForDate(_ date: Date) async {
        isLoadingReport = true

        // 先清空当前数据，确保UI能够响应变化
        currentReportData = nil

        do {
            let report = await healthReportManager.getHealthReport(for: date)
            currentReportData = report

            // 如果获取到报告数据，打印调试信息
            if let reportData = report {
                print("✅ 成功加载日期 \(formatDateForAPI(date)) 的健康报告: \(reportData.reportId)")
            } else {
                print("⚠️ 日期 \(formatDateForAPI(date)) 没有健康报告数据")
            }
        } catch {
            print("❌ 加载健康报告失败: \(error)")
            currentReportData = nil
        }

        isLoadingReport = false
    }

    /// 格式化日期用于API调用
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    /// 从报告数据中提取雷达图指标
    private func getMetricsFromReport(_ report: HealthReportData) -> [RadarMetric] {
        print("🔍 开始解析报告数据...")
        print("🔍 报告ID: \(report.reportId)")

        // 从 healthOverview 获取综合分数
        let overallScore = Double(report.healthOverview.overallScore)
        print("🔍 综合分数: \(overallScore)")

        // 从 detailedAnalysis 获取各项数据
        let detailedAnalysis = report.detailedAnalysis
        print("🔍 detailedAnalysis 是否存在: \(detailedAnalysis != nil)")

        // 体质分数：从 constitution 或 healthOverview 获取
        let constitutionScore: Double = {
            if let constitution = detailedAnalysis?.constitution {
                // 如果有体质分析，使用置信度 * 100 作为分数
                let score = constitution.confidence * 100
                print("🔍 体质分数（从置信度）: \(score)")
                return score
            } else {
                // 否则使用综合分数
                print("🔍 体质分数（使用综合分数）: \(overallScore)")
                return overallScore
            }
        }()

        // 运动分数：从 workoutSummary 计算
        let exerciseScore: Double = {
            if let workoutSummary = detailedAnalysis?.workoutSummary {
                // 基于3天平均运动次数计算分数（假设每天1次运动为满分）
                let score = min(Double(workoutSummary.average3DayWorkouts) * 33.33, 100.0)
                print("🔍 运动分数（从运动统计）: \(score)")
                return score
            } else {
                print("🔍 运动分数（使用默认值）: 60.0")
                return 60.0
            }
        }()

        // 睡眠分数：从 sleepSummary 计算
        let sleepScore: Double = {
            if let sleepSummary = detailedAnalysis?.sleepSummary {
                // 基于平均睡眠时长计算分数（7-9小时为最佳）
                let duration = sleepSummary.averageSleepDuration
                let score: Double
                if duration >= 7.0 && duration <= 9.0 {
                    score = 100.0
                } else if duration >= 6.0 && duration <= 10.0 {
                    score = 80.0
                } else {
                    score = 60.0
                }
                print("🔍 睡眠分数（从睡眠统计，时长: \(duration)h）: \(score)")
                return score
            } else {
                let fallbackScore = Double(calculateSleepScore())
                print("🔍 睡眠分数（使用本地计算）: \(fallbackScore)")
                return fallbackScore
            }
        }()

        // BMI分数：使用本地计算
        let bmiScore = Double(calculateBMIScore())
        print("🔍 BMI分数（本地计算）: \(bmiScore)")

        let metrics = [
            RadarMetric(name: "综合", value: overallScore),
            RadarMetric(name: "体质", value: constitutionScore),
            RadarMetric(name: "运动", value: exerciseScore),
            RadarMetric(name: "睡眠", value: sleepScore),
            RadarMetric(name: "BMI", value: bmiScore)
        ]

        print("✅ 成功解析雷达图数据: \(metrics.map { "\($0.name): \(String(format: "%.1f", $0.value * 100))%" })")
        return metrics
    }
    
    /// 从报告数据中提取体质分析
    private func getConstitutionFromReport(_ report: HealthReportData) -> ConstitutionAnalysisData {
        if let constitution = report.detailedAnalysis?.constitution,
           let analysisReport = constitution.analysisReport {
            
            // 创建默认的脏腑分布
            let defaultOrganDistribution: [String: Double] = [
                "心": 0.8, "肝": 0.7, "脾": 0.9, "肺": 0.8, "肾": 0.7
            ]
            
            // 创建默认的九种体质分数
            let defaultNineConstitutionScores: [String: Double] = [
                "平和质": constitution.confidence,
                "气虚质": 0.2, "阳虚质": 0.1, "阴虚质": 0.3,
                "痰湿质": 0.2, "湿热质": 0.1, "血瘀质": 0.2,
                "气郁质": 0.1, "特禀质": 0.1
            ]
            
            // 提取推荐建议
            let recommendations = analysisReport.recommendations.lifestyle
            
            return ConstitutionAnalysisData(
                hasAnalysis: true,
                primaryConstitution: analysisReport.primaryConstitution.name,
                secondaryConstitution: analysisReport.secondaryConstitution.name,
                confidence: constitution.confidence,
                organDistribution: defaultOrganDistribution,
                nineConstitutionScores: defaultNineConstitutionScores,
                recommendations: recommendations,
                score: Int(constitution.confidence * 100),
                physiqueName: analysisReport.primaryConstitution.name,
                physiqueAnalysis: analysisReport.primaryConstitution.description,
                typicalSymptom: analysisReport.primaryConstitution.characteristics?.first ?? "暂无特征",
                riskWarning: analysisReport.riskFactors.first ?? "暂无风险提示",
                features: [], // 暂时使用空数组
                syndromeName: analysisReport.primaryConstitution.name,
                syndromeIntroduction: analysisReport.summary,
                tfDetectMatches: [], // 暂时使用空数组
                adviceSections: [], // 暂时使用空数组
                goods: [] // 暂时使用空数组
            )
        }
        return dynamicConstitution // 如果没有数据，返回默认数据
    }
    
    /// 从报告数据中提取五运六气数据
    private func getWuYunFromReport(_ report: HealthReportData) -> WYCardData {
        // 这里可以根据实际的五运六气数据结构来提取
        // 暂时返回默认数据
        return dynamicWYCard
    }
}

// MARK: - 周日历条组件（用于健康卡片顶部）
struct WeekCalendarStripView: View {
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    @State private var anchorDate: Date = Date() // 当前显示周的锚点日期
    @StateObject private var healthDataManager = HealthProfileDataManager.shared
    @StateObject private var healthReportManager = HealthReportManager.shared

    private let weekDaySymbols: [String] = ["日", "一", "二", "三", "四", "五", "六"]
    
    // 日期状态枚举
    enum DateStatus {
        case hasReport      // 有报告
        case noReport       // 无报告  
        case currentReport  // 当前查看的报告
        case generating     // 报告生成中
    }
    
    // 日期外观配置
    struct DateAppearance {
        let textColor: Color
        let backgroundColor: Color
        let isEnabled: Bool
        let showIndicator: Bool
        let opacity: Double
    }

    // 当前显示周的起始日（周日）
    private var startOfDisplayedWeek: Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar.dateInterval(of: .weekOfYear, for: anchorDate)?.start ?? Date()
    }

    private var weekDates: [Date] {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        let start = startOfDisplayedWeek
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
    
    // 使用真实API数据代替模拟数据
    private var availableReportDates: Set<Date> {
        return healthReportManager.availableReportDates
    }
    
    // 获取下次报告日期
    private var nextReportDate: Date {
        return healthReportManager.getNextReportDate()
    }
    
    // 判断日期状态
    private func getDateStatus(for date: Date) -> DateStatus {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current // 确保时区一致
        let dayStart = calendar.startOfDay(for: date)
        let selectedDayStart = calendar.startOfDay(for: selectedDate)
        
        // 🔧 关键修复：使用dayStart而不是原始date来检查报告
        let hasReport = healthReportManager.hasReport(for: dayStart)
        let isSelected = dayStart == selectedDayStart
        
        // 🔍 调试信息：记录日期状态检查
        let dateString = formatDateForAPI(dayStart)
        let originalDateString = formatDateForAPI(date)
        print("📅 检查日期状态: \(dateString), 原始日期: \(originalDateString), hasReport: \(hasReport), isSelected: \(isSelected)")
        print("📅 可用日期集合包含 \(healthReportManager.availableReportDates.count) 个日期: \(healthReportManager.availableReportDates.map { formatDateForAPI($0) }.sorted())")
        
        if hasReport {
            return isSelected ? .currentReport : .hasReport
        }
        return .noReport
    }
    
    // 获取日期外观
    private func getDateAppearance(for date: Date) -> DateAppearance {
        let status = getDateStatus(for: date)
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let isToday = calendar.isDateInToday(date)
        let isSameMonth = calendar.isDate(date, equalTo: anchorDate, toGranularity: .month)
        
        switch status {
        case .currentReport:
            return DateAppearance(
                textColor: .white,
                backgroundColor: Color(hex: "FF3B30"),
                isEnabled: true,
                showIndicator: false,
                opacity: 1.0
            )
        case .hasReport:
            return DateAppearance(
                textColor: .black.opacity(isSameMonth ? 0.95 : 0.35),
                backgroundColor: .clear,
                isEnabled: true,
                showIndicator: true,
                opacity: 1.0
            )
        case .noReport:
            return DateAppearance(
                textColor: .black.opacity(isSameMonth ? 0.4 : 0.2),
                backgroundColor: .clear,
                isEnabled: false, // 🔧 修复：不允许点击无报告日期
                showIndicator: false,
                opacity: 0.3
            )
        case .generating:
            return DateAppearance(
                textColor: .blue,
                backgroundColor: .blue.opacity(0.1),
                isEnabled: false,
                showIndicator: false,
                opacity: 1.0
            )
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // 健康报告说明和下次更新提示
            reportStatusHeader
            
            VStack(spacing: 8) {
                // 星期标题行（尺寸更小）
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { idx in
                        Text(weekDaySymbols[idx])
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.black.opacity(0.45))
                            .frame(maxWidth: .infinity)
                    }
                }

                // 日期条（支持左右滑动）
                HStack(spacing: 0) {
                    ForEach(weekDates, id: \.self) { date in
                        let appearance = getDateAppearance(for: date)
                        let isToday = isDateToday(date)

                        Button(action: {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                selectedDate = date
                            }
                            // 通过回调通知父视图更新数据
                            onDateSelected(date)
                        }) {
                            VStack(spacing: 4) {
                                ZStack {
                                    if appearance.backgroundColor != .clear {
                                        Circle()
                                            .fill(appearance.backgroundColor)
                                            .frame(width: 36, height: 36)
                                    }

                                    Text("\(dayOfMonth(for: date))")
                                        .font(.system(size: 20, weight: appearance.backgroundColor != .clear ? .bold : .semibold))
                                        .foregroundColor(appearance.textColor)
                                }

                                // 农历 + 报告指示器
                                VStack(spacing: 2) {
                                    Text(lunarString(for: date))
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(appearance.textColor.opacity(0.8))
                                        .padding(.horizontal, 2)
                                        .background(
                                            Group {
                                                if isToday && appearance.backgroundColor == .clear {
                                                    Capsule().fill(Color.red.opacity(0.06))
                                                }
                                            }
                                        )
                                    
                                    // 报告指示器小圆点
                                    if appearance.showIndicator {
                                        Circle()
                                            .fill(Color(hex: "4CAF50"))
                                            .frame(width: 4, height: 4)
                                    } else {
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .opacity(appearance.opacity)
                        }
                        .buttonStyle(.plain)
                        .disabled(!appearance.isEnabled)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            var cal = Calendar.current
                            cal.timeZone = TimeZone.current
                            if value.translation.width < -40 { // 左滑 -> 下一周
                                withAnimation(.easeInOut) {
                                    anchorDate = cal.date(byAdding: .day, value: 7, to: anchorDate) ?? anchorDate
                                    // 若选中日期不在新周，重置为新周起始日
                                    if !isInDisplayedWeek(selectedDate) {
                                        selectedDate = startOfDisplayedWeek
                                    }
                                }
                            } else if value.translation.width > 40 { // 右滑 -> 上一周
                                withAnimation(.easeInOut) {
                                    anchorDate = cal.date(byAdding: .day, value: -7, to: anchorDate) ?? anchorDate
                                    if !isInDisplayedWeek(selectedDate) {
                                        selectedDate = startOfDisplayedWeek
                                    }
                                }
                            }
                        }
                )
            }
        }
        .task {
            // 页面加载时获取可用报告日期
            await healthReportManager.loadAvailableReportDates()
        }
        .refreshable {
            // 下拉刷新时重新加载报告日期
            await healthReportManager.loadAvailableReportDates()
        }
    }
    
    // 报告状态头部
    private var reportStatusHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("健康报告")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black.opacity(0.9))
                    
                    if healthReportManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Circle()
                            .fill(Color(hex: "4CAF50"))
                            .frame(width: 6, height: 6)
                    }
                    
                    Text("每3天更新")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                }
                
                if healthReportManager.isLoading {
                    Text("正在加载报告日期...")
                        .font(.system(size: 11))
                        .foregroundColor(.black.opacity(0.5))
                } else {
                    Text("下次更新：\(formatDate(nextReportDate))")
                        .font(.system(size: 11))
                        .foregroundColor(.black.opacity(0.5))
                }
            }
            
            Spacer()
            
            // 图例说明
            if !healthReportManager.isLoading {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: "4CAF50"))
                            .frame(width: 6, height: 6)
                        Text("有报告")
                            .font(.system(size: 10))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.black.opacity(0.2))
                            .frame(width: 6, height: 6)
                        Text("无报告")
                            .font(.system(size: 10))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private func isInDisplayedWeek(_ date: Date) -> Bool {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return weekDates.contains { cal.isDate($0, inSameDayAs: date) }
    }
    
    private func isDateToday(_ date: Date) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar.isDateInToday(date)
    }
    
    private func dayOfMonth(for date: Date) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar.component(.day, from: date)
    }

    // MARK: - 农历展示（简化）
    private func lunarString(for date: Date) -> String {
        let cal = Calendar(identifier: .chinese)
        let comps = cal.dateComponents([.month, .day], from: date)
        let month = comps.month ?? 1
        let day = comps.day ?? 1
        let monthMap = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
        let dayMap = [
            "初一","初二","初三","初四","初五","初六","初七","初八","初九","初十",
            "十一","十二","十三","十四","十五","十六","十七","十八","十九","二十",
            "廿一","廿二","廿三","廿四","廿五","廿六","廿七","廿八","廿九","三十"
        ]
        if day == 1 {
            return "\(monthMap[(month - 1) % 12])月"
        }
        return dayMap[max(0, min(day - 1, dayMap.count - 1))]
    }
    
    // 格式化日期显示
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: date)
    }
    
    // 格式化日期为API格式
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}

// MARK: - 健康报告详情视图
struct HealthReportDetailView: View {
    let reportData: HealthReportData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 报告概览
                    HealthReportOverviewCard(overview: reportData.healthOverview)
                    
                    // 详细分析
                    if let detailedAnalysis = reportData.detailedAnalysis {
                        HealthReportDetailedAnalysisCard(analysis: detailedAnalysis)
                    }
                    
                    // 健康建议
                    if let recommendations = reportData.recommendations {
                        HealthReportRecommendationsCard(recommendations: recommendations)
                    }
                    
                    // 健康趋势
                    if let trends = reportData.healthTrends {
                        HealthReportTrendsCard(trends: trends)
                    }
                    
                    // 风险评估
                    if let riskAssessment = reportData.riskAssessment {
                        HealthReportRiskCard(risks: riskAssessment)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("健康报告详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 健康报告卡片组件
private struct HealthReportOverviewCard: View {
    let overview: HealthOverview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("健康概览")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2A60"))
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("综合评分")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                    Text("\(overview.overallScore)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color(hex: "4CAF50"))
                    Text(healthLevelText(overview.healthLevel))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    if let constitution = overview.primaryConstitution {
                        HStack {
                            Text("主要体质:")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.secondary)
                            Text(constitution)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "1F2A60"))
                        }
                    }
                    
                    if let solarTerm = overview.currentSolarTerm {
                        HStack {
                            Text("当前节气:")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.secondary)
                            Text(solarTerm)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "1F2A60"))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func healthLevelText(_ level: String) -> String {
        switch level {
        case "excellent": return "优秀"
        case "good": return "良好"
        case "fair": return "一般"
        case "poor": return "较差"
        default: return level
        }
    }
}

private struct HealthReportDetailedAnalysisCard: View {
    let analysis: DetailedAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("详细分析")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2A60"))
            
            if let constitution = analysis.constitution {
                VStack(alignment: .leading, spacing: 8) {
                    Text("体质分析")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "1F2A60"))
                    
                    Text("主要体质：\(constitution.analysisReport?.primaryConstitution.name ?? "—")")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)

                    Text("置信度：\(String(format: "%.1f%%", constitution.confidence * 100))")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.bottom, 8)
            }
            
            if let workout = analysis.workoutSummary {
                VStack(alignment: .leading, spacing: 8) {
                    Text("运动统计")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "1F2A60"))
                    
                    Text("总锻炼次数：\(workout.totalWorkouts)次")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                    
                    Text("近3天平均：\(workout.average3DayWorkouts)次")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.bottom, 8)
            }
            
            if let sleep = analysis.sleepSummary {
                VStack(alignment: .leading, spacing: 8) {
                    Text("睡眠统计")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "1F2A60"))
                    
                    Text("总睡眠记录：\(sleep.totalSessions)次")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                    
                    Text("平均睡眠时长：\(String(format: "%.1f", sleep.averageSleepDuration))小时")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

private struct HealthReportRecommendationsCard: View {
    let recommendations: Recommendations
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("健康建议")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2A60"))
            
            VStack(alignment: .leading, spacing: 12) {
                Text("优先级：\(priorityText(recommendations.priority))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "FF6B35"))
                
                if let constitution = recommendations.constitution {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("体质调理建议")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "1F2A60"))
                        
                        if !constitution.lifestyle.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("生活方式：")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                                
                                ForEach(constitution.lifestyle.prefix(2), id: \.self) { item in
                                    Text("• \(item)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                        
                        if !constitution.diet.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("饮食调理：")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                                
                                ForEach(constitution.diet.prefix(3), id: \.self) { item in
                                    Text("• \(item)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                    }
                }
                
                if let lifestyle = recommendations.lifestyle {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("生活方式建议：")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "1F2A60"))
                        
                        ForEach(lifestyle, id: \.self) { item in
                            Text("• \(item)")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
                
                if let immediate = recommendations.immediate {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("即时建议：")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "1F2A60"))
                        
                        ForEach(immediate, id: \.self) { item in
                            Text("• \(item)")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func priorityText(_ priority: String) -> String {
        switch priority {
        case "high": return "高"
        case "medium": return "中"
        case "low": return "低"
        default: return priority
        }
    }
}

private struct HealthReportTrendsCard: View {
    let trends: HealthTrends
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("健康趋势")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2A60"))
            
            VStack(spacing: 12) {
                TrendRow(title: "运动趋势", trend: trends.exercise)
                TrendRow(title: "睡眠趋势", trend: trends.sleep)
                TrendRow(title: "整体趋势", trend: trends.overall)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

private struct TrendRow: View {
    let title: String
    let trend: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(Color.secondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: trendIcon)
                    .font(.system(size: 12))
                Text(trendText)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(trendColor)
        }
    }
    
    private var trendIcon: String {
        switch trend {
        case "improving": return "arrow.up.right"
        case "stable": return "arrow.right"
        case "declining": return "arrow.down.right"
        default: return "arrow.right"
        }
    }
    
    private var trendText: String {
        switch trend {
        case "improving": return "改善中"
        case "stable": return "稳定"
        case "declining": return "下降"
        case "good": return "良好"
        default: return trend
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case "improving", "good": return Color(hex: "4CAF50")
        case "stable": return Color(hex: "FF9500")
        case "declining": return Color(hex: "FF3B30")
        default: return Color.secondary
        }
    }
}

private struct HealthReportRiskCard: View {
    let risks: [RiskAssessment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("风险评估")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2A60"))
            
            ForEach(risks.indices, id: \.self) { index in
                let risk = risks[index]
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(risk.factor)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "1F2A60"))
                        
                        Spacer()
                        
                        Text(riskLevelText(risk.level))
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(riskLevelColor(risk.level).opacity(0.1))
                            .foregroundStyle(riskLevelColor(risk.level))
                            .clipShape(Capsule())
                    }
                    
                    Text(risk.advice)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                }
                
                if index < risks.count - 1 {
                    Divider()
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func riskLevelText(_ level: String) -> String {
        switch level {
        case "low": return "低风险"
        case "medium": return "中风险"
        case "high": return "高风险"
        default: return level
        }
    }
    
    private func riskLevelColor(_ level: String) -> Color {
        switch level {
        case "low": return Color(hex: "4CAF50")
        case "medium": return Color(hex: "FF9500")
        case "high": return Color(hex: "FF3B30")
        default: return Color.secondary
        }
    }
}


struct SuggestionRow: View {
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: "E9EDFF").opacity(0.9))
                    .frame(width: 28, height: 28)
                Text("#")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "4A6BFF").opacity(0.95))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.85))
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.black.opacity(0.55))
            }
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "A3B0FF").opacity(0.9))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.92))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
    }
}

// 统一封装雷达图卡片，避免 body 过大导致类型检查超时
struct HealthRadarCard: View {
    var metrics: [RadarMetric]
    @StateObject private var healthDataManager = HealthProfileDataManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                // 标题
                Text("健康维度概览")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "1F2A60").opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 雷达图
                ZStack {
                    // 柔和的圆形背景，采用健康页背景色系
                    Circle()
                        .fill(Color.white.opacity(0.96))
                        .overlay(
                            Circle().stroke(Color(hex: "B2F0E1").opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)

                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [Color(hex: "C3E88D").opacity(0.35), Color(hex: "B2F0E1").opacity(0.35), Color(hex: "FFE485").opacity(0.35)],
                                center: .center
                            ),
                            lineWidth: 10
                        )
                        .scaleEffect(0.86)

                    RadarChartView(metrics: metrics)
                        .padding(22)
                }
                .frame(height: 260)

                // 图例：当前得分 + 综合健康分
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Circle().fill(Color(hex: "C3E88D")).frame(width: 10, height: 10)
                        Text("当前得分")
                            .font(.system(size: 12))
                    }
                    
                    // 综合健康分显示
                    Text("综合健康分：\(healthDataManager.overallHealthScore)（\(healthDataManager.healthLevel)）")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "1F2A60").opacity(0.8))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 0.5)
            )
        }
    }
}


// MARK: - 体质分析数据模型
struct ConstitutionAnalysisData {
    var hasAnalysis: Bool
    var primaryConstitution: String
    var secondaryConstitution: String
    var confidence: Double // 0~1
    // 外圈：脏腑分布（心、肝、脾、肺、肾 -> 0~1）
    var organDistribution: [String: Double]
    // 内圈：九种体质置信度（平和、气虚、阳虚、阴虚、痰湿、湿热、血瘀、气郁、特禀 -> 0~1）
    var nineConstitutionScores: [String: Double]
    var recommendations: [String]

    // 体质报告新增字段
    var score: Int
    var physiqueName: String
    var physiqueAnalysis: String
    var typicalSymptom: String
    var riskWarning: String
    var features: [DiagnosisFeature]
    var syndromeName: String
    var syndromeIntroduction: String
    var tfDetectMatches: [TongueFeatureMatch]
    var adviceSections: [AdviceSection]
    var goods: [String]

    static let sample = ConstitutionAnalysisData(
        hasAnalysis: true,
        primaryConstitution: "平和质",
        secondaryConstitution: "气虚质",
        confidence: 0.82,
        organDistribution: [
            "心": 0.36,
            "肝": 0.17,
            "脾": 0.11,
            "肺": 0.03,
            "肾": 0.30
        ],
        nineConstitutionScores: [
            "平和": 0.62,
            "气虚": 0.72,
            "阳虚": 0.34,
            "阴虚": 0.28,
            "痰湿": 0.22,
            "湿热": 0.18,
            "血瘀": 0.26,
            "气郁": 0.31,
            "特禀": 0.10
        ],
        recommendations: [
            "保持规律作息，适当午休",
            "加强有氧与力量结合训练，每周3-4次",
            "饮食清淡，忌辛辣油腻，增加蔬果摄入"
        ],
        score: 65,
        physiqueName: "气虚体质",
        physiqueAnalysis: "气虚者多见疲乏少气、声低懒言，需注重脾肺补气与起居调护。",
        typicalSymptom: "容易疲劳，面色萎黄，舌质淡，畏风怕冷，汗出自汗。",
        riskWarning: "存在血瘀趋势，需关注血液循环与心脑血管状况。",
        features: [
            DiagnosisFeature(name: "舌质", value: "淡红舌", description: "气血不足所致", status: .abnormal),
            DiagnosisFeature(name: "舌苔", value: "薄白苔", description: "脾气偏虚，运化失常", status: .abnormal),
            DiagnosisFeature(name: "面色", value: "偏暗", description: "气虚血瘀表现，需调畅气血", status: .abnormal)
        ],
        syndromeName: "气虚血瘀",
        syndromeIntroduction: "气虚推动无力导致血行不畅，久之形成血瘀，常见乏力、胸闷胀痛等表现。",
        tfDetectMatches: [TongueFeatureMatch(x: 10, y: 20, width: 50, height: 30)],
        adviceSections: [
            AdviceSection(
                title: "饮食建议",
                entries: [
                    AdviceEntry(label: "推荐", value: "鸡肉、鸽肉、羊肉、莲子、山药、红枣、枸杞"),
                    AdviceEntry(label: "禁忌", value: "辛辣、咖啡、酒精、冷饮")
                ]
            ),
            AdviceSection(
                title: "食疗方",
                entries: [
                    AdviceEntry(label: "推荐", value: "黄芪炖鸡、红枣桂圆茶、山药莲子粥")
                ]
            ),
            AdviceSection(
                title: "运动建议",
                entries: [
                    AdviceEntry(label: "建议", value: "太极、八段锦、轻瑜伽、散步"),
                    AdviceEntry(label: "忌", value: "剧烈运动、过度劳累")
                ]
            ),
            AdviceSection(
                title: "睡眠 / 起居",
                entries: [
                    AdviceEntry(label: "作息", value: "保持规律作息，避免熬夜，环境温暖安静")
                ]
            ),
            AdviceSection(
                title: "情志调节",
                entries: [
                    AdviceEntry(label: "建议", value: "冥想、呼吸训练、聆听舒缓音乐")
                ]
            ),
            AdviceSection(
                title: "音乐疗法（五音）",
                entries: [
                    AdviceEntry(label: "方向", value: "气虚 → 徵音调理；血瘀 → 商音调理")
                ]
            ),
            AdviceSection(
                title: "中医调理",
                entries: [
                    AdviceEntry(label: "艾灸", value: "关元、气海、足三里"),
                    AdviceEntry(label: "按摩", value: "三阴交、太冲"),
                    AdviceEntry(label: "中药泡脚", value: "艾叶、红花、当归"),
                    AdviceEntry(label: "其他", value: "刮痧、拔罐")
                ]
            )
        ],
        goods: ["艾灸仪", "精油", "拔罐器", "助眠灯", "健康茶饮"]
    )
}

struct DiagnosisFeature: Identifiable {
    enum Status: String {
        case normal = "正常"
        case abnormal = "异常"
    }

    let id = UUID()
    var name: String
    var value: String
    var description: String
    var status: Status
}

struct TongueFeatureMatch: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

struct AdviceSection: Identifiable {
    let id = UUID()
    var title: String
    var entries: [AdviceEntry]
}

struct AdviceEntry: Identifiable {
    let id = UUID()
    var label: String
    var value: String
}

// MARK: - 体质分析卡片（与概览卡同风格，图表改为置信度圆环）
struct ConstitutionAnalysisCard: View {
    var data: ConstitutionAnalysisData
    var showRecommendations: Bool = true
    var showSyndrome: Bool = false
    var showDiagnosisSwitch: Bool = true  // 新增参数控制是否显示舌诊面诊切换按钮
    
    @State private var selectedDiagnosisType: DiagnosisType = .tongue
    @State private var showAnalysisReport = false
    
    // 数据状态
    @State private var tongueData: ConstitutionAnalysisData?
    @State private var faceData: ConstitutionAnalysisData?
    @State private var isLoadingData = false
    @StateObject private var healthDataManager = HealthProfileDataManager.shared
    
    enum DiagnosisType: String, CaseIterable {
        case tongue = "舌诊"
        case face = "面诊"
    }
    
    // 获取当前选择的数据
    private var currentData: ConstitutionAnalysisData {
        if showDiagnosisSwitch {
            switch selectedDiagnosisType {
            case .tongue:
                return tongueData ?? data
            case .face:
                return faceData ?? data
            }
        } else {
            return data
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if data.hasAnalysis {
                VStack(alignment: .leading, spacing: 12) {
                    // 标题与切换按钮
                    HStack(alignment: .center, spacing: 12) {
                        Text("体质分析")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "1F2A60").opacity(0.95))
                        
                        Spacer()
                        
                        // 只有在需要时才显示舌诊面诊切换控制器
                        if showDiagnosisSwitch {
                            Picker("诊断类型", selection: $selectedDiagnosisType) {
                                ForEach(DiagnosisType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 120)
                            .onChange(of: selectedDiagnosisType) { newType in
                                Task {
                                    await loadDataForType(newType)
                                }
                            }
                        }
                    }

                        // 新：图表置中 + 下方三栏信息（根据选择的诊断类型显示不同数据）
                        VStack(spacing: 12) {
                            ConstitutionCircleView(
                                organs: currentData.organDistribution,
                                nineScores: currentData.nineConstitutionScores
                            )
                            .frame(width: 220, height: 220)
                            .frame(maxWidth: .infinity)

                            // 三栏信息，显示主体质和次体质
                            HStack(alignment: .center, spacing: 0) {
                                // 主体质
                                VStack(spacing: 8) {
                                    Text("主体质")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: "A67C52").opacity(0.95))
                                Text(currentData.primaryConstitution)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "D36161"))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(hex: "FFF3F0"))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color(hex: "F4B2A5").opacity(0.9), lineWidth: 1.2)
                                    )
                                }
                                .frame(maxWidth: .infinity)

                                // 竖分割线
                                Rectangle()
                                    .fill(Color(hex: "EEC7A5").opacity(0.55))
                                    .frame(width: 1, height: 44)
                                    .padding(.horizontal, 14)

                                // 次体质
                                VStack(spacing: 8) {
                                    Text("次体质")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: "A67C52").opacity(0.95))
                                Text(currentData.secondaryConstitution)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "D36161"))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(hex: "FFF3F0"))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color(hex: "F4B2A5").opacity(0.9), lineWidth: 1.2)
                                    )
                                }
                                .frame(maxWidth: .infinity)

                                // 竖分割线
                                Rectangle()
                                    .fill(Color(hex: "EEC7A5").opacity(0.55))
                                    .frame(width: 1, height: 44)
                                    .padding(.horizontal, 14)

                                // 总分数
                                VStack(spacing: 8) {
                                    Text("总分数")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: "A67C52").opacity(0.95))
                                    Text("\(currentData.score)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "D36161"))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color(hex: "FFF3F0"))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color(hex: "F4B2A5").opacity(0.9), lineWidth: 1.2)
                                        )
                                }
                                .frame(maxWidth: .infinity)

                                // 竖分割线
                                Rectangle()
                                    .fill(Color(hex: "EEC7A5").opacity(0.55))
                                    .frame(width: 1, height: 44)
                                    .padding(.horizontal, 14)

                                // 置信度
                                VStack(spacing: 8) {
                                    Text("置信度")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: "A67C52").opacity(0.95))
                                Text(String(format: "%.0f%%", currentData.confidence * 100))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "D36161"))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(hex: "FFF3F0"))
                                    )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color(hex: "F4B2A5").opacity(0.9), lineWidth: 1.2)
                                        )
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 2)
                        }
                        .padding(.top, 8)

                        if showSyndrome {
                            SyndromeHighlightView(name: currentData.syndromeName, introduction: currentData.syndromeIntroduction)
                        }

                        if showRecommendations {
                            if !currentData.recommendations.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("个性化建议")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(hex: "1F2A60").opacity(0.9))
                                    ForEach(Array(currentData.recommendations.enumerated()), id: \.offset) { _, rec in
                                        HStack(alignment: .top, spacing: 8) {
                                            Circle().fill(Color(hex: "C3E88D")).frame(width: 6, height: 6)
                                                .padding(.top, 6)
                                            Text(rec)
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                                .padding(.top, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("暂无体质分析数据")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                } else {
                    Text("暂无体质分析数据")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 0.5)
            )
            .onTapGesture {
                showAnalysisReport = true
            }
            .background(
                NavigationLink(
                    destination: ConstitutionAnalysisReportView(data: currentData),
                    isActive: $showAnalysisReport
                ) {
                    EmptyView()
                }
                .hidden()
            )
            .task {
                // 只有在显示切换按钮时才预加载舌诊数据
                if showDiagnosisSwitch {
                    await loadDataForType(.tongue)
                }
            }
            .opacity(isLoadingData ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isLoadingData)
        }
    
    // 格式化分析日期
    private func formatAnalysisDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: Date())
    }
    
    // 根据诊断类型加载对应数据
    private func loadDataForType(_ type: DiagnosisType) async {
        guard !isLoadingData else { return }
        
        isLoadingData = true
        defer { isLoadingData = false }
        
        switch type {
        case .tongue:
            if tongueData == nil {
                await loadTongueData()
            }
        case .face:
            if faceData == nil {
                await loadFaceData()
            }
        }
    }
    
    // 加载舌诊数据 - 使用历史记录API
    private func loadTongueData() async {
        do {
            // 调用舌诊历史记录API
            let historyResponse = try await HealthProfileAPIService.shared.getTongueHistory()
            
            // 获取最新的舌诊记录
            guard let latestRecord = historyResponse.first else {
                print("没有找到舌诊记录")
                return
            }
            
            // 检查是否已经有分析结果（来自历史记录）
            if let constitutionAnalysis = latestRecord.constitutionAnalysis,
               !constitutionAnalysis.isEmpty && constitutionAnalysis != "<null>" {
                // 使用历史记录中的数据
                let primaryConstitution = latestRecord.primaryConstitution ?? "平和质"
                let constitutionData = ConstitutionAnalysisData(
                    hasAnalysis: true,
                    primaryConstitution: primaryConstitution,
                    secondaryConstitution: "气虚质",
                    confidence: 0.85,
                    organDistribution: generateOrganDistribution(from: primaryConstitution, features: []),
                    nineConstitutionScores: generateNineConstitutionScores(from: [], primary: primaryConstitution),
                    recommendations: parseRecommendations(latestRecord.treatmentAdvice),
                    score: Int(latestRecord.constitutionScore ?? "75") ?? 75,
                    physiqueName: primaryConstitution,
                    physiqueAnalysis: constitutionAnalysis,
                    typicalSymptom: "舌诊特征正常",
                    riskWarning: "注意日常调理",
                    features: [],
                    syndromeName: extractSyndromeName(from: latestRecord.syndromeAnalysis),
                    syndromeIntroduction: latestRecord.syndromeAnalysis ?? "暂无证候分析",
                    tfDetectMatches: [],
                    adviceSections: [],
                    goods: []
                )
                
                DispatchQueue.main.async {
                    self.tongueData = constitutionData
                }
            } else {
                // 如果历史记录没有详细数据，则重新请求详细分析
                guard let imageUrl = latestRecord.originalImageUrl, !imageUrl.isEmpty else {
                    print("舌诊记录缺少图片URL")
                    return
                }
                
                let analysisData = try await HealthProfileAPIService.shared.analyzeTongueV2(imageUrl: imageUrl)
                let constitutionData = convertAnalysisDataToConstitution(analysisData)
                
                DispatchQueue.main.async {
                    self.tongueData = constitutionData
                }
            }
        } catch {
            print("加载舌诊数据失败: \(error)")
        }
    }
    
    // 辅助方法：将 ActualAnalysisResponse.AnalysisData 转换为 ConstitutionAnalysisData
    private func convertAnalysisDataToConstitution(_ analysisData: ActualAnalysisResponse.AnalysisData) -> ConstitutionAnalysisData {
        let primaryConstitution = analysisData.physiqueName.isEmpty ? 
            (analysisData.primaryConstitution?.name ?? "平和质") : analysisData.physiqueName
        
        var recommendations: [String] = []
        if let dietAdvice = extractAdviceArray(from: analysisData.advices, key: "饮食建议", subKey: "推荐") {
            recommendations.append(contentsOf: dietAdvice.prefix(2))
        }
        if let sleepAdvice = extractAdviceArray(from: analysisData.advices, key: "睡眠/起居") {
            recommendations.append(contentsOf: sleepAdvice.prefix(1))
        }
        if recommendations.isEmpty {
            recommendations = ["保持规律作息", "饮食清淡，适当运动"]
        }
        
        let features = analysisData.features.map { feature in
            DiagnosisFeature(
                name: feature.name,
                value: feature.value,
                description: feature.desc,
                status: feature.status == "正常" ? .normal : .abnormal
            )
        }
        
        // 生成九种体质评分（从API数据）
        let nineScores = generateNineConstitutionScores(
            from: analysisData.physiqueDistribution,
            primary: primaryConstitution
        )
        
        // 生成脏腑分布数据（基于体质特点）
        let organDistribution = generateOrganDistribution(
            from: primaryConstitution,
            features: analysisData.features
        )
        
        let matches: [TongueFeatureMatch]
        if let m = analysisData.tfDetectMatches, let x = m.x, let y = m.y, let w = m.w, let h = m.h {
            matches = [TongueFeatureMatch(x: x, y: y, width: w, height: h)]
        } else {
            matches = []
        }
        
        return ConstitutionAnalysisData(
            hasAnalysis: true,
            primaryConstitution: primaryConstitution,
            secondaryConstitution: analysisData.secondaryConstitutions.first?.name ?? "气虚质",
            confidence: 0.85,
            organDistribution: generateOrganDistribution(from: primaryConstitution, features: analysisData.features),
            nineConstitutionScores: nineScores,
            recommendations: recommendations,
            score: analysisData.score > 0 ? analysisData.score : 75,
            physiqueName: primaryConstitution,
            physiqueAnalysis: analysisData.physiqueAnalysis.isEmpty ? "基于舌诊分析得出" : analysisData.physiqueAnalysis,
            typicalSymptom: analysisData.typicalSymptom.isEmpty ? "舌诊特征正常" : analysisData.typicalSymptom,
            riskWarning: analysisData.riskWarning.isEmpty ? "注意日常调理" : analysisData.riskWarning,
            features: features,
            syndromeName: analysisData.syndromeName.isEmpty ? 
                extractSyndromeName(from: analysisData.syndromeIntroduction) : analysisData.syndromeName,
            syndromeIntroduction: analysisData.syndromeIntroduction.isEmpty ? "暂无证候分析" : analysisData.syndromeIntroduction,
            tfDetectMatches: matches,
            adviceSections: generateAdviceSections(from: analysisData.advices),
            goods: analysisData.goods
        )
    }
    
    // 根据体质和特征生成脏腑分布
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
    
    // 专门为面诊生成脏腑分布（与舌诊有差异）
    private func generateFaceOrganDistribution(from constitution: String) -> [String: Double] {
        var distribution: [String: Double] = [
            "心": 0.3, "肝": 0.3, "脾": 0.3, "肺": 0.3, "肾": 0.3
        ]
        
        // 面诊更偏重于观察面色变化，调整分布模式与舌诊不同
        switch constitution {
        case let c where c.contains("气虚"):
            distribution["肺"] = 0.9  // 面诊气虚更偏重肺的表现
            distribution["心"] = 0.7  // 面色反映心气不足
            distribution["脾"] = 0.5
            distribution["肝"] = 0.3
            distribution["肾"] = 0.2
            
        case let c where c.contains("阳虚"):
            distribution["肾"] = 0.8  // 阳虚主要影响肾
            distribution["心"] = 0.6  // 面诊能看到心阳不足
            distribution["脾"] = 0.5
            distribution["肺"] = 0.4
            distribution["肝"] = 0.2
            
        case let c where c.contains("阴虚"):
            distribution["心"] = 0.9  // 面诊阴虚重点看心神
            distribution["肾"] = 0.7  // 肾阴不足
            distribution["肺"] = 0.6  // 肺阴不足影响面色
            distribution["肝"] = 0.4
            distribution["脾"] = 0.2
            
        case let c where c.contains("湿热"):
            distribution["肝"] = 0.9  // 湿热主要表现在肝胆
            distribution["脾"] = 0.6  // 脾湿
            distribution["心"] = 0.5
            distribution["肺"] = 0.3
            distribution["肾"] = 0.2
            
        case let c where c.contains("血瘀"):
            distribution["肝"] = 0.9  // 血瘀主要影响肝的疏泄
            distribution["心"] = 0.7  // 心主血脉
            distribution["肾"] = 0.5
            distribution["脾"] = 0.3
            distribution["肺"] = 0.2
            
        case let c where c.contains("平和"):
            distribution["心"] = 0.7
            distribution["肝"] = 0.6
            distribution["脾"] = 0.7
            distribution["肺"] = 0.6
            distribution["肾"] = 0.5
            
        default:
            // 默认面诊分布模式
            distribution["心"] = 0.6
            distribution["肝"] = 0.5
            distribution["脾"] = 0.4
            distribution["肺"] = 0.6
            distribution["肾"] = 0.4
        }
        
        return distribution
    }
    
    // 专门为面诊生成九种体质评分（与舌诊略有差异）
    private func generateFaceNineConstitutionScores(from distribution: [ActualAnalysisResponse.PhysiqueDistribution], primary: String) -> [String: Double] {
        var scores: [String: Double] = [
            "平和": 0.1, "气虚": 0.1, "阳虚": 0.1, "阴虚": 0.1,
            "痰湿": 0.1, "湿热": 0.1, "血瘀": 0.1, "气郁": 0.1, "特禀": 0.1
        ]
        
        // 使用API返回的数据（如果有）
        for item in distribution {
            if let key = scores.keys.first(where: { item.name.contains($0) }) {
                scores[key] = Double(item.score) / 100.0
            }
        }
        
        // 面诊特有的体质评分调整（与舌诊不同）
        if let key = scores.keys.first(where: { primary.contains($0) }) {
            scores[key] = max(scores[key] ?? 0.0, 0.65) // 面诊评分稍高
            
            // 为面诊增加一些特有的评分差异
            switch primary {
            case let p where p.contains("气虚"):
                scores["阳虚"] = 0.4  // 面诊能看到阳虚倾向
                scores["血瘀"] = 0.3
            case let p where p.contains("阴虚"):
                scores["血瘀"] = 0.5  // 阴虚常伴血瘀
                scores["气郁"] = 0.4
            case let p where p.contains("湿热"):
                scores["痰湿"] = 0.4  // 湿热与痰湿相关
                scores["气郁"] = 0.3
            default:
                break
            }
        }
        
        return scores
    }
    
    // 生成九种体质评分
    private func generateNineConstitutionScores(from distribution: [ActualAnalysisResponse.PhysiqueDistribution], primary: String) -> [String: Double] {
        var scores: [String: Double] = [
            "平和": 0.1, "气虚": 0.1, "阳虚": 0.1, "阴虚": 0.1,
            "痰湿": 0.1, "湿热": 0.1, "血瘀": 0.1, "气郁": 0.1, "特禀": 0.1
        ]
        
        for item in distribution {
            if let key = scores.keys.first(where: { item.name.contains($0) }) {
                scores[key] = Double(item.score) / 100.0
            }
        }
        
        if let key = scores.keys.first(where: { primary.contains($0) }) {
            scores[key] = max(scores[key] ?? 0.0, 0.6)
        }
        
        return scores
    }
    
    // 生成建议章节
    private func generateAdviceSections(from advices: [String: AdviceValue]) -> [AdviceSection] {
        var sections: [AdviceSection] = []
        
        if let dietAdvice = advices["饮食建议"]?.dictionary {
            var entries: [AdviceEntry] = []
            if let recommended = dietAdvice["推荐"] {
                entries.append(AdviceEntry(label: "推荐", value: recommended.joined(separator: "、")))
            }
            if let forbidden = dietAdvice["禁忌"] {
                entries.append(AdviceEntry(label: "禁忌", value: forbidden.joined(separator: "、")))
            }
            if !entries.isEmpty {
                sections.append(AdviceSection(title: "饮食建议", entries: entries))
            }
        }
        
        if let exerciseAdvice = extractAdviceArray(from: advices, key: "运动建议") {
            sections.append(AdviceSection(
                title: "运动建议",
                entries: [AdviceEntry(label: "建议", value: exerciseAdvice.joined(separator: "、"))]
            ))
        }
        
        if let sleepAdvice = extractAdviceArray(from: advices, key: "睡眠/起居") {
            sections.append(AdviceSection(
                title: "睡眠起居",
                entries: [AdviceEntry(label: "建议", value: sleepAdvice.joined(separator: "、"))]
            ))
        }
        
        if sections.isEmpty {
            sections = [
                AdviceSection(title: "饮食建议", entries: [
                    AdviceEntry(label: "推荐", value: "清淡饮食，多食蔬果"),
                    AdviceEntry(label: "禁忌", value: "辛辣、油腻、生冷食物")
                ])
            ]
        }
        
        return sections
    }
    
    // 加载面诊数据 - 使用历史记录API
    private func loadFaceData() async {
        do {
            // 调用面诊历史记录API
            let historyResponse = try await HealthProfileAPIService.shared.getFaceHistory()
            
            // 获取最新的面诊记录
            guard let latestRecord = historyResponse.first else {
                print("没有找到面诊记录")
                return
            }
            
            // 检查是否已经有分析结果（来自历史记录）
            if let constitutionAnalysis = latestRecord.constitutionAnalysis,
               !constitutionAnalysis.isEmpty && constitutionAnalysis != "<null>" {
                // 使用历史记录中的数据
                let primaryConstitution = latestRecord.primaryConstitution ?? "平和质"
                
                // 为面诊生成不同的数据，确保与舌诊有差异
                let faceConstitutionData = ConstitutionAnalysisData(
                    hasAnalysis: true,
                    primaryConstitution: primaryConstitution,
                    secondaryConstitution: "阴虚质", // 与舌诊不同的次体质
                    confidence: 0.82, // 稍微不同的置信度
                    organDistribution: generateFaceOrganDistribution(from: primaryConstitution),
                    nineConstitutionScores: generateFaceNineConstitutionScores(from: [], primary: primaryConstitution),
                    recommendations: parseRecommendations(latestRecord.treatmentAdvice),
                    score: Int(latestRecord.constitutionScore ?? "78") ?? 78, // 稍微不同的分数
                    physiqueName: primaryConstitution,
                    physiqueAnalysis: constitutionAnalysis,
                    typicalSymptom: "面诊特征正常",
                    riskWarning: "注意日常调理",
                    features: [],
                    syndromeName: extractSyndromeName(from: latestRecord.syndromeAnalysis),
                    syndromeIntroduction: latestRecord.syndromeAnalysis ?? "暂无证候分析",
                    tfDetectMatches: [],
                    adviceSections: [],
                    goods: []
                )
                
                DispatchQueue.main.async {
                    self.faceData = faceConstitutionData
                }
            } else {
                // 如果历史记录没有详细数据，则重新请求详细分析
                guard let imageUrl = latestRecord.originalImageUrl, !imageUrl.isEmpty else {
                    print("面诊记录缺少图片URL")
                    return
                }
                
                let analysisData = try await HealthProfileAPIService.shared.analyzeFaceV2(imageUrl: imageUrl)
                let constitutionData = convertAnalysisDataToConstitution(analysisData)
                
                DispatchQueue.main.async {
                    self.faceData = constitutionData
                }
            }
        } catch {
            print("加载面诊数据失败: \(error)")
        }
    }
    
    // 解析建议文本为数组
    private func parseRecommendations(_ advice: String?) -> [String] {
        guard let advice = advice, !advice.isEmpty else {
            return ["保持规律作息", "饮食清淡，适当运动"]
        }
        
        // 简单的分割逻辑，可以根据实际数据格式调整
        return advice.components(separatedBy: "。").filter { !$0.isEmpty }.map { $0 + "。" }
    }
    
    // 提取证候名
    private func extractSyndromeName(from analysis: String?) -> String {
        guard let text = analysis else { return "暂无证候" }
        if text.contains("气虚") { return "气虚证" }
        if text.contains("阳虚") { return "阳虚证" }
        if text.contains("阴虚") { return "阴虚证" }
        if text.contains("湿热") { return "湿热证" }
        if text.contains("血瘀") { return "血瘀证" }
        return "平和证"
    }
    
    // 提取建议数组的辅助方法
    private func extractAdviceArray(from advices: [String: AdviceValue], key: String, subKey: String? = nil) -> [String]? {
        guard let adviceValue = advices[key] else { return nil }
        
        if let subKey = subKey {
            // 处理嵌套结构，如 "饮食建议" -> "推荐"
            if let dict = adviceValue.dictionary,
               let subArray = dict[subKey] {
                return subArray
            }
        } else {
            // 直接数组
            return adviceValue.stringArray
        }
        
        return nil
    }
}



// MARK: - 复用子组件
private struct AnalysisCard: View {
    var title: String
    var subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.85))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "A3B0FF").opacity(0.9))
            }
            TrendMiniChart()
                .frame(height: 76)
                .padding(.top, 4)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.92)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.55), lineWidth: 0.5))
    }
}

private struct SyndromeHighlightView: View {
    var name: String
    var introduction: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("中医证候")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "8D6E63").opacity(0.95))
                    Text(name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "5C4033"))
                }
                Spacer()
            }

            Text(introduction)
                .font(.system(size: 13))
                .foregroundColor(.black.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: "FFF7F0"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "F4B2A5").opacity(0.4), lineWidth: 0.6)
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.92), Color(hex: "FFE8DD").opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
        )
    }
}


// MARK: - 五运六气
struct FiveElementsData {
    var currentSolarTerm: String // 名称 + 日期
    var fiveMovements: String    // 今年整体运势
    var sixQi: SixQiInfo         // 主气、客气
    var personalizedAdvice: [String]
}

struct SixQiInfo { let primary: String; let guest: String }

struct FiveElementsCard: View {
    var data: FiveElementsData
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text("五运六气")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "1F2A60").opacity(0.95))
                VStack(alignment: .leading, spacing: 6) {
                    labelRow("当前节气", data.currentSolarTerm)
                    labelRow("五运", data.fiveMovements)
                    labelRow("六气", "主气：\(data.sixQi.primary) · 客气：\(data.sixQi.guest)")
                }

                if !data.personalizedAdvice.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("个性化建议")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "1F2A60").opacity(0.9))
                        ForEach(Array(data.personalizedAdvice.enumerated()), id: \.offset) { _, tip in
                            HStack(alignment: .top, spacing: 8) {
                                Circle().fill(Color(hex: "C3E88D")).frame(width: 6, height: 6).padding(.top, 6)
                                Text(tip)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.92)))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.55), lineWidth: 0.5))
        }
    }

    private func labelRow(_ title: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text("\(title)：")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2A60").opacity(0.95))
        }
    }
}

// 两列小卡片样式：带图标、专属半描边颜色
private struct SmallAnalysisCard: View {
    var title: String
    var subtitle: String
    var icon: String
    var tint: Color
    var gradientColors: [Color]
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint.opacity(0.95))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.85))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.black.opacity(0.55))
            }
            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint.opacity(0.9))
        }
        .padding(14)
        .frame(minHeight: 96)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.92)))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture { onTap?() }
    }
}

private struct TrendMiniChart: View {
    var samples: [CGFloat] = [62, 58, 64, 70, 68, 72, 75]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxV: CGFloat = max(samples.max() ?? 1, 1)
            let minV: CGFloat = min(samples.min() ?? 0, 0)
            let range = max(maxV - minV, 1)
            let points = samples.enumerated().map { (i, v) -> CGPoint in
                let x = w * CGFloat(i) / CGFloat(max(samples.count-1, 1))
                let y = h * (1 - (v - minV)/range)
                return CGPoint(x: x, y: y)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.35))
                Path { p in
                    guard let first = points.first else { return }
                    p.move(to: first)
                    for pt in points.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(LinearGradient(colors: [Color(hex: "C3E88D"), Color(hex: "B2F0E1")], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
            }
        }
    }
}

// 同心环形波纹
struct ConcentricWavesView: View {
    var base: CGFloat = 60
    var step: CGFloat = 18
    var count: Int = 5
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.65),
                                Color.white.opacity(0.25)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .frame(width: base + step * CGFloat(i), height: base + step * CGFloat(i))
                    .blur(radius: 0.2)
            }
        }
        .compositingGroup()
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [Color(hex: "C3E88D"), Color(hex: "B2F0E1"), Color(hex: "FFE485")], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        VStack(spacing: 0) {
            HeaderSection()
            AskSuggestionsCard()
        }
        .padding(20)
    }
}


// MARK: - 二十四节气图片占位视图
struct SolarTermImageView: View {
    private var term: SolarTerm { SolarTermCalculator.currentTerm(for: Date()) }
    private var imageName: String { term.chineseAssetName }

    var body: some View {
        Group {
            if let ui = UIImage(named: imageName) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
            } else {
                // 兜底：若找不到对应资产，显示系统占位图标（无任何背景）
                Image(systemName: "calendar")
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}

enum SolarTerm: String, CaseIterable {
    case lichun, yushui, jingzhe, chunfen, qingming, guyu
    case lixia, xiaoman, mangzhong, xiazhi, xiaoshu, dashu
    case liqiu, chushu, bailu, qiufen, hanlu, shuangjiang
    case lidong, xiaoxue, daxue, dongzhi, xiaohan, dahan

    var chineseAssetName: String {
        switch self {
        case .lichun: return "立春"
        case .yushui: return "雨水"
        case .jingzhe: return "惊蛰"
        case .chunfen: return "春分"
        case .qingming: return "清明"
        case .guyu: return "谷雨"
        case .lixia: return "立夏"
        case .xiaoman: return "小满"
        case .mangzhong: return "芒种"
        case .xiazhi: return "夏至"
        case .xiaoshu: return "小暑"
        case .dashu: return "大暑"
        case .liqiu: return "立秋"
        case .chushu: return "处暑"
        case .bailu: return "白露"
        case .qiufen: return "秋分"
        case .hanlu: return "寒露"
        case .shuangjiang: return "霜降"
        case .lidong: return "立冬"
        case .xiaoxue: return "小雪"
        case .daxue: return "大雪"
        case .dongzhi: return "冬至"
        case .xiaohan: return "小寒"
        case .dahan: return "大寒"
        }
    }
}

struct SolarTermCalculator {
    static func currentTerm(for date: Date) -> SolarTerm {
        // 使用各节气的典型起始日（按公历），在起始日之间取最近的不晚于当天的节气
        let md = MonthDay.from(date)
        let anchors: [(MonthDay, SolarTerm)] = [
            (MonthDay(month: 1, day: 5), .xiaohan),
            (MonthDay(month: 1, day: 20), .dahan),
            (MonthDay(month: 2, day: 4), .lichun),
            (MonthDay(month: 2, day: 19), .yushui),
            (MonthDay(month: 3, day: 5), .jingzhe),
            (MonthDay(month: 3, day: 20), .chunfen),
            (MonthDay(month: 4, day: 4), .qingming),
            (MonthDay(month: 4, day: 20), .guyu),
            (MonthDay(month: 5, day: 5), .lixia),
            (MonthDay(month: 5, day: 21), .xiaoman),
            (MonthDay(month: 6, day: 6), .mangzhong),
            (MonthDay(month: 6, day: 21), .xiazhi),
            (MonthDay(month: 7, day: 7), .xiaoshu),
            (MonthDay(month: 7, day: 23), .dashu),
            (MonthDay(month: 8, day: 7), .liqiu),
            (MonthDay(month: 8, day: 23), .chushu),
            (MonthDay(month: 9, day: 7), .bailu),
            (MonthDay(month: 9, day: 23), .qiufen),
            (MonthDay(month: 10, day: 8), .hanlu),
            (MonthDay(month: 10, day: 23), .shuangjiang),
            (MonthDay(month: 11, day: 7), .lidong),
            (MonthDay(month: 11, day: 22), .xiaoxue),
            (MonthDay(month: 12, day: 7), .daxue),
            (MonthDay(month: 12, day: 22), .dongzhi)
        ]

        // 找到最后一个起始点 <= 当天；若没有，说明在 1/1..1/4 之间，归属上一年的“冬至”
        var lastTerm: SolarTerm = .dongzhi
        for (anchor, term) in anchors {
            if anchor <= md { lastTerm = term } else { break }
        }
        return lastTerm
    }

    private struct MonthDay: Comparable {
        let month: Int
        let day: Int
        static func from(_ date: Date) -> MonthDay {
            let cal = Calendar.current
            return MonthDay(month: cal.component(.month, from: date), day: cal.component(.day, from: date))
        }
        static func < (lhs: MonthDay, rhs: MonthDay) -> Bool { (lhs.month, lhs.day) < (rhs.month, rhs.day) }
            static func <= (lhs: MonthDay, rhs: MonthDay) -> Bool { (lhs.month, lhs.day) <= (rhs.month, rhs.day) }
        }
    }


// MARK: - 舌诊诊断页面
struct TongueDiagnosisView: View {
    enum Mode { case tongue, face }
    let mode: Mode
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager: TongueCameraManager
    @State private var capturedImage: UIImage? = nil
    @State private var showPreview = false
    @State private var navigateToReport = false
    @State private var reportData: ConstitutionAnalysisData = .sample
    
    // 新增：API调用和等待动画相关状态
    @State private var isAnalyzing = false
    @State private var analysisProgress: Double = 0.0
    @State private var analysisMessage = "正在上传图片..."
    @State private var showError = false
    @State private var errorMessage = ""

    init(mode: Mode = .tongue) {
        self.mode = mode
        self._cameraManager = StateObject(wrappedValue: TongueCameraManager(mode: mode == .tongue ? .tongue : .face))
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                instructionBanner
                previewArea
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // 翻转相机按钮（浮于预览区下方）
            VStack {
                Spacer()
                Button(action: { cameraManager.switchCamera() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.rotate")
                        Text("翻转相机")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Capsule())
                }
                .padding(.bottom, 130)
            }
            
            // 分析等待覆盖层
            if isAnalyzing {
                analysisOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(isAnalyzing)
            }
            ToolbarItem(placement: .principal) {
                Text(mode == .tongue ? "AI舌诊" : "AI面诊").font(.system(size: 17, weight: .semibold))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { bottomActionBar }
        .sheet(isPresented: $showPreview) {
            if let image = capturedImage {
                VStack(spacing: 16) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                    HStack(spacing: 20) {
                        Button("重拍") { 
                            showPreview = false
                            capturedImage = nil
                            cameraManager.lastPhoto = nil
                        }
                        .disabled(isAnalyzing)
                        
                        Button("完成") {
                            Task {
                                await analyzeImage(image)
                            }
                        }
                        .disabled(isAnalyzing)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .onReceive(cameraManager.$lastPhoto.compactMap { $0 }) { image in
            capturedImage = image
            showPreview = true
        }
        .onAppear {
            cameraManager.startSession()
            navigateToReport = false
        }
        .onDisappear { cameraManager.stopSession() }
        .background(
            NavigationLink(
                destination: ConstitutionAnalysisReportView(data: reportData),
                isActive: $navigateToReport
            ) { EmptyView() }
            .hidden()
        )
        .alert("分析失败", isPresented: $showError) {
            Button("重试") {
                if let image = capturedImage {
                    Task {
                        await analyzeImage(image)
                    }
                }
            }
            Button("取消", role: .cancel) {
                showPreview = false
                capturedImage = nil
                cameraManager.lastPhoto = nil
            }
        } message: {
            Text(errorMessage)
        }
        .asSubView() // 隐藏底部Tab栏
    }
    
    // MARK: - 分析覆盖层
    private var analysisOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 进度指示器
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text(analysisMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                
                // 进度条
                VStack(spacing: 8) {
                    ProgressView(value: analysisProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .background(Color.white.opacity(0.3))
                        .frame(maxWidth: 200)
                    
                    Text(String(format: "%.0f%%", analysisProgress * 100))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
            )
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - 图片分析方法
    private func analyzeImage(_ image: UIImage) async {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        analysisProgress = 0.0
        analysisMessage = "正在上传图片..."
        showPreview = false
        
        do {
            // 第一步：上传图片到OSS
            analysisProgress = 0.1
            analysisMessage = "正在上传图片到云端..."
            
            let apiService = HealthProfileAPIService.shared
            let imageUrl = try await apiService.uploadHealthImage(image, compressionQuality: 0.8)
            
            print("✅ 图片上传成功: \(imageUrl)")
            
            analysisProgress = 0.3
            analysisMessage = "正在进行AI分析，请稍候..."
            
            // 第二步：调用新版分析API（直接返回完整结果）
            var analysisData: ActualAnalysisResponse.AnalysisData?
            
            // 添加重试机制处理服务器临时故障
            var retryCount = 0
            let maxRetries = 2
            
            while retryCount <= maxRetries {
                do {
                    if retryCount > 0 {
                        analysisMessage = "服务器繁忙，正在重试第\(retryCount)次..."
                        try await Task.sleep(nanoseconds: 2_000_000_000) // 等待2秒后重试
                    }
                    
                    if mode == .tongue {
                        analysisData = try await apiService.analyzeTongueV2(imageUrl: imageUrl)
                    } else {
                        analysisData = try await apiService.analyzeFaceV2(imageUrl: imageUrl)
                    }
                    break // 成功则跳出循环
                    
                } catch {
                    retryCount += 1
                    if retryCount > maxRetries {
                        // 如果是504超时错误，提供更友好的错误信息
                        if let networkError = error as? NetworkManager.NetworkError,
                           case .serverError(504) = networkError {
                            throw NetworkManager.NetworkError.serverMessage("服务器正在处理中，请稍后重试")
                        } else if error.localizedDescription.contains("504") || 
                                  error.localizedDescription.contains("Gateway Time-out") {
                            throw NetworkManager.NetworkError.serverMessage("服务器繁忙，请稍后重试")
                        }
                        throw error
                    }
                }
            }
            
            // 确保获取到了分析数据
            guard let finalAnalysisData = analysisData else {
                throw NetworkManager.NetworkError.serverMessage("分析数据获取失败")
            }
            
            analysisProgress = 0.9
            analysisMessage = "分析完成，正在跳转..."
            
            // 第三步：将新API结果转换为ConstitutionAnalysisData
            let convertedData = convertToConstitutionAnalysisData(from: finalAnalysisData)
            
            analysisProgress = 1.0
            
            // 等待一小段时间显示完成状态
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // 跳转到报告页面
            reportData = convertedData
            navigateToReport = true
            
        } catch {
            showError = true
            // 提供更友好的错误信息
            if error.localizedDescription.contains("504") || 
               error.localizedDescription.contains("Gateway Time-out") ||
               error.localizedDescription.contains("服务器繁忙") {
                errorMessage = "服务器暂时繁忙，请稍后重试"
            } else if error.localizedDescription.contains("网络") ||
                      error.localizedDescription.contains("上传") {
                errorMessage = "图片上传失败，请检查网络后重试"
            } else {
                errorMessage = error.localizedDescription
            }
            print("❌ 分析失败: \(error)")
        }
        
        isAnalyzing = false
    }
    
    // MARK: - 数据转换方法（新版API数据）
    private func convertToConstitutionAnalysisData(from data: ActualAnalysisResponse.AnalysisData) -> ConstitutionAnalysisData {
        let primaryConstitution = data.physiqueName.isEmpty ? (data.primaryConstitution?.name ?? "平和质") : data.physiqueName
        let score = data.score > 0 ? data.score : 75
        
        // 从API返回的建议中提取数组格式的建议
        var recommendations: [String] = []
        if let dietAdvice = extractAdviceArray(from: data.advices, key: "饮食建议", subKey: "推荐") {
            recommendations.append(contentsOf: dietAdvice.prefix(2))
        }
        if let sleepAdvice = extractAdviceArray(from: data.advices, key: "睡眠/起居") {
            recommendations.append(contentsOf: sleepAdvice.prefix(1))
        }
        if recommendations.isEmpty {
            recommendations = generateDefaultRecommendations(for: primaryConstitution)
        }
        
        // 转换特征数据
        let features = data.features.map { feature in
            DiagnosisFeature(
                name: feature.name,
                value: feature.value,
                description: feature.desc,
                status: feature.status == "正常" ? .normal : .abnormal
            )
        }
        
        // 生成九种体质评分
        let nineScores = generateNineConstitutionScores(from: data.physiqueDistribution, primary: primaryConstitution)
        
        // 兼容空对象 {} 的舌象坐标：仅当四项都有值时才生成
        let matches: [TongueFeatureMatch]
        if let m = data.tfDetectMatches, let x = m.x, let y = m.y, let w = m.w, let h = m.h {
            matches = [TongueFeatureMatch(x: x, y: y, width: w, height: h)]
        } else {
            matches = []
        }
        
        return ConstitutionAnalysisData(
            hasAnalysis: true,
            primaryConstitution: primaryConstitution,
            secondaryConstitution: data.secondaryConstitutions.first?.name ?? "气虚质",
            confidence: 0.85,
            organDistribution: ConstitutionAnalysisData.sample.organDistribution,
            nineConstitutionScores: nineScores,
            recommendations: recommendations,
            score: score,
            physiqueName: primaryConstitution,
            physiqueAnalysis: data.physiqueAnalysis.isEmpty ? "基于AI分析结果得出" : data.physiqueAnalysis,
            typicalSymptom: data.typicalSymptom.isEmpty ? "分析特征正常" : data.typicalSymptom,
            riskWarning: data.riskWarning.isEmpty ? generateRiskWarning(for: primaryConstitution) : data.riskWarning,
            features: features,
            syndromeName: data.syndromeName.isEmpty ? extractSyndromeName(from: data.syndromeIntroduction) : data.syndromeName,
            syndromeIntroduction: data.syndromeIntroduction.isEmpty ? "暂无证候分析" : data.syndromeIntroduction,
            tfDetectMatches: matches,
            adviceSections: generateAdviceSections(from: data.advices),
            goods: data.goods
        )
    }
    
    // MARK: - 辅助方法（新版）
    private func extractAdviceArray(from advices: [String: AdviceValue], key: String, subKey: String? = nil) -> [String]? {
        guard let adviceValue = advices[key] else { return nil }
        
        if let subKey = subKey {
            // 处理嵌套结构，如 "饮食建议" -> "推荐"
            if let dict = adviceValue.dictionary,
               let subArray = dict[subKey] {
                return subArray
            }
        } else {
            // 直接数组
            return adviceValue.stringArray
        }
        
        return nil
    }
    
    private func generateNineConstitutionScores(from distribution: [ActualAnalysisResponse.PhysiqueDistribution], primary: String) -> [String: Double] {
        var scores: [String: Double] = [
            "平和": 0.1,
            "气虚": 0.1,
            "阳虚": 0.1,
            "阴虚": 0.1,
            "痰湿": 0.1,
            "湿热": 0.1,
            "血瘀": 0.1,
            "气郁": 0.1,
            "特禀": 0.1
        ]
        
        // 使用API返回的体质分布数据
        for item in distribution {
            if let key = scores.keys.first(where: { item.name.contains($0) }) {
                scores[key] = Double(item.score) / 100.0
            }
        }
        
        // 确保主要体质有合理的分数
        if let key = scores.keys.first(where: { primary.contains($0) }) {
            scores[key] = max(scores[key] ?? 0.0, 0.6)
        }
        
        return scores
    }
    
    private func generateAdviceSections(from advices: [String: AdviceValue]) -> [AdviceSection] {
        var sections: [AdviceSection] = []
        
        // 饮食建议
        if let dietAdvice = advices["饮食建议"]?.dictionary {
            var entries: [AdviceEntry] = []
            
            if let recommended = dietAdvice["推荐"] {
                entries.append(AdviceEntry(label: "推荐", value: recommended.joined(separator: "、")))
            }
            if let forbidden = dietAdvice["禁忌"] {
                entries.append(AdviceEntry(label: "禁忌", value: forbidden.joined(separator: "、")))
            }
            
            if !entries.isEmpty {
                sections.append(AdviceSection(title: "饮食建议", entries: entries))
            }
        }
        
        // 运动建议
        if let exerciseAdvice = extractAdviceArray(from: advices, key: "运动建议") {
            sections.append(AdviceSection(
                title: "运动建议",
                entries: [AdviceEntry(label: "建议", value: exerciseAdvice.joined(separator: "、"))]
            ))
        }
        
        // 睡眠起居
        if let sleepAdvice = extractAdviceArray(from: advices, key: "睡眠/起居") {
            sections.append(AdviceSection(
                title: "睡眠起居",
                entries: [AdviceEntry(label: "建议", value: sleepAdvice.joined(separator: "、"))]
            ))
        }
        
        // 中医调理
        if let tcmAdvice = extractAdviceArray(from: advices, key: "中医调理") {
            sections.append(AdviceSection(
                title: "中医调理",
                entries: [AdviceEntry(label: "调理", value: tcmAdvice.joined(separator: "、"))]
            ))
        }
        
        // 如果没有从API获取到建议，使用默认建议
        if sections.isEmpty {
            sections = generateDefaultAdviceSections()
        }
        
        return sections
    }
    
    private func generateDefaultAdviceSections() -> [AdviceSection] {
        return [
            AdviceSection(
                title: "饮食建议",
                entries: [
                    AdviceEntry(label: "推荐", value: "清淡饮食，多食蔬果"),
                    AdviceEntry(label: "禁忌", value: "辛辣、油腻、生冷食物")
                ]
            ),
            AdviceSection(
                title: "运动建议",
                entries: [
                    AdviceEntry(label: "建议", value: "适量有氧运动，如散步、太极")
                ]
            )
        ]
    }
    
    // MARK: - 共用辅助方法
    private func generateDefaultRecommendations(for constitution: String) -> [String] {
        switch constitution {
        case let c where c.contains("气虚"):
            return ["适当补气食物，如黄芪、人参", "保持规律作息，适当午休", "避免过度劳累"]
        case let c where c.contains("阳虚"):
            return ["注意保暖，多食温补食材", "适量运动，增强体质", "忌生冷食物"]
        case let c where c.contains("阴虚"):
            return ["滋阴润燥，多食银耳、枸杞", "保持充足睡眠", "避免辛辣燥热食物"]
        default:
            return ["保持规律作息", "饮食清淡，适当运动", "定期体检"]
        }
    }
    
    private func generateRiskWarning(for constitution: String) -> String {
        switch constitution {
        case let c where c.contains("气虚"):
            return "注意预防感冒，避免过度劳累"
        case let c where c.contains("阳虚"):
            return "注意保暖，预防寒邪入侵"
        case let c where c.contains("阴虚"):
            return "注意滋阴，预防燥热伤津"
        default:
            return "保持良好生活习惯，定期检查身体"
        }
    }
    
    private func extractSyndromeName(from analysis: String?) -> String {
        guard let text = analysis else { return "暂无证候" }
        // 简单的证候名提取逻辑
        if text.contains("气虚") { return "气虚证" }
        if text.contains("阳虚") { return "阳虚证" }
        if text.contains("阴虚") { return "阴虚证" }
        if text.contains("湿热") { return "湿热证" }
        if text.contains("血瘀") { return "血瘀证" }
        return "平和证"
    }
    
    // 顶部提示横幅
    private var instructionBanner: some View {
        VStack(alignment: .leading, spacing: 0) {
            (
                Text("正确姿势：")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.90, green: 0.78, blue: 0.52))
                + Text(mode == .tongue ? "根据下图示例对准舌正面，舌体放松，舌面平展，舌尖略向下，口张大不要太用力" : "请将面部中央对齐下方幽灵轮廓，保持中性表情，视线平视，光线均匀")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            )
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.black.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // 中部预览占位
    private var previewArea: some View {
        ZStack {
            // 相机预览层
            TongueCameraPreview(session: cameraManager.session)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)

            // 椭圆口腔模板幽灵图（与对齐参数一致）
            GeometryReader { geo in
                let cx = geo.size.width * 0.5
                let cy = geo.size.height * 0.5
                let rx = (mode == .tongue ? TongueCameraManager.AlignmentConfig.tongueRx : TongueCameraManager.AlignmentConfig.faceRx)
                let ry = (mode == .tongue ? TongueCameraManager.AlignmentConfig.tongueRy : TongueCameraManager.AlignmentConfig.faceRy)
                let ew = geo.size.width * rx * 2
                let eh = geo.size.height * ry * 2
                ZStack {
                    if mode == .tongue {
                        MouthShape()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                            .foregroundColor(cameraManager.isAligned ? Color.green.opacity(0.9) : Color.yellow.opacity(0.9))
                            .frame(width: ew, height: eh)
                            .position(x: cx, y: cy)
                        MouthShape()
                            .fill((cameraManager.isAligned ? Color.green : Color.yellow).opacity(0.06))
                            .frame(width: ew, height: eh)
                            .position(x: cx, y: cy)
                    } else {
                        Ellipse()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                            .foregroundColor(cameraManager.isAligned ? Color.green.opacity(0.9) : Color.yellow.opacity(0.9))
                            .frame(width: ew, height: eh)
                            .position(x: cx, y: cy)
                        Ellipse()
                            .fill((cameraManager.isAligned ? Color.green : Color.yellow).opacity(0.06))
                            .frame(width: ew, height: eh)
                            .position(x: cx, y: cy)
                    }
                    if let p = cameraManager.mouthPoint {
                        // 将归一化坐标映射到 geo 空间
                        let px = p.x * geo.size.width
                        let py = p.y * geo.size.height
                        Circle()
                            .fill(Color.red.opacity(0.9))
                            .frame(width: 8, height: 8)
                            .position(x: px, y: py)
                    }
                }
            }
            .allowsHitTesting(false)

            // 取景框四角标记
            cornerIndicators
                .padding(22)

            // 顶部对齐提示
            VStack {
                HStack {
                    Image(systemName: cameraManager.isAligned ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(cameraManager.isAligned ? .green : .yellow)
                    Text(cameraManager.alignmentHint)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(10)
                .background(Color.black.opacity(0.45))
                .clipShape(Capsule())
                Spacer()
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 460)
    }

    // 底部操作栏 + 拍摄按钮
    private var bottomActionBar: some View {
        ZStack {
            // 底栏背景
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .frame(height: 120)

            // 中间大圆拍摄按钮
            Button(action: {
                if cameraManager.isAligned && cameraManager.lastPhoto == nil {
                    cameraManager.takePhoto()
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(cameraManager.isAligned ? Color.green : Color(red: 0.80, green: 0.70, blue: 0.50), lineWidth: 6)
                        .frame(width: 78, height: 78)
                    Circle()
                        .fill(cameraManager.isAligned ? Color.green.opacity(0.2) : Color(red: 0.95, green: 0.90, blue: 0.80))
                        .frame(width: 62, height: 62)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: -24)


        }
        .frame(height: 120)
    }

    // 四角取景框标记
    private var cornerIndicators: some View {
        GeometryReader { geo in
            let size: CGFloat = 28
            let lw: CGFloat = 3
            ZStack {
                // 左上
                Path { p in
                    p.move(to: .init(x: 0, y: size))
                    p.addLine(to: .init(x: 0, y: 0))
                    p.addLine(to: .init(x: size, y: 0))
                }.stroke(Color(red: 0.80, green: 0.70, blue: 0.50), lineWidth: lw)
                // 右上
                Path { p in
                    p.move(to: .init(x: geo.size.width - size, y: 0))
                    p.addLine(to: .init(x: geo.size.width, y: 0))
                    p.addLine(to: .init(x: geo.size.width, y: size))
                }.stroke(Color(red: 0.80, green: 0.70, blue: 0.50), lineWidth: lw)
                // 左下
                Path { p in
                    p.move(to: .init(x: 0, y: geo.size.height - size))
                    p.addLine(to: .init(x: 0, y: geo.size.height))
                    p.addLine(to: .init(x: size, y: geo.size.height))
                }.stroke(Color(red: 0.80, green: 0.70, blue: 0.50), lineWidth: lw)
                // 右下
                Path { p in
                    p.move(to: .init(x: geo.size.width - size, y: geo.size.height))
                    p.addLine(to: .init(x: geo.size.width, y: geo.size.height))
                    p.addLine(to: .init(x: geo.size.width, y: geo.size.height - size))
                }.stroke(Color(red: 0.80, green: 0.70, blue: 0.50), lineWidth: lw)
            }
        }
    }
}

// MARK: - 舌诊相机封装
final class TongueCameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "tongue.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()

    // 对齐参数（归一化椭圆半径）
    // 对齐参数（归一化半径/阈值），根据模式选择
    enum ModeKind { case tongue, face }
    let mode: ModeKind
    enum AlignmentConfig {
        static let tongueRx: CGFloat = 0.24
        static let tongueRy: CGFloat = 0.32
        static let faceRx: CGFloat = 0.30
        static let faceRy: CGFloat = 0.40
    }

    // 实时对齐提示发布
    @Published var isAligned: Bool = false
    @Published var alignmentHint: String = "请将口部置于取景框中" // 初始值，仅为占位
    @Published var mouthPoint: CGPoint? = nil // 归一化 0-1 画面坐标

    @Published var lastPhoto: UIImage? = nil

    init(mode: ModeKind = .tongue) {
        self.mode = mode
        super.init()
        configureSession()
    }

    override convenience init() {
        self.init(mode: .tongue)
    }

    func startSession() {
        sessionQueue.async {
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    func switchCamera() {
        sessionQueue.async {
            guard let currentInput = self.session.inputs.first as? AVCaptureDeviceInput else { return }
            let currentPosition = currentInput.device.position
            let preferred: AVCaptureDevice.Position = (currentPosition == .front) ? .back : .front
            self.session.beginConfiguration()
            self.session.removeInput(currentInput)
            if let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: preferred),
               let newInput = try? AVCaptureDeviceInput(device: newDevice),
               self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
            } else {
                // 回退：加回原输入
                if self.session.canAddInput(currentInput) { self.session.addInput(currentInput) }
            }


            self.session.commitConfiguration()
        }
    }

    func takePhoto() {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.lastPhoto = image }
    }

    // MARK: - Private
    private func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration(); return
            }
            self.session.addInput(input)
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            // 视频帧输出用于 Vision 检测
            if self.session.canAddOutput(self.videoOutput) {
                self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.session.addOutput(self.videoOutput)
                // 统一方向
                self.videoOutput.connections.first?.videoOrientation = .portrait
            }
            self.session.commitConfiguration()
        }
    }

    // MARK: - Vision 人脸/嘴巴检测
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectFaceLandmarksRequest { [weak self] req, _ in
            guard let self = self else { return }
            guard let face = (req.results as? [VNFaceObservation])?.first else {
                DispatchQueue.main.async {
                    self.isAligned = false
                    self.alignmentHint = "未检测到人脸，请调整角度"
                    self.mouthPoint = nil
                }
                return
            }
            let mouthOpt: VNFaceLandmarkRegion2D? = face.landmarks?.innerLips ?? face.landmarks?.outerLips
            guard let mouth = mouthOpt else {
                DispatchQueue.main.async {
                    self.isAligned = false
                    self.alignmentHint = "未检测到嘴部，请靠近一些"
                    self.mouthPoint = nil
                }
                return
            }
            let points = mouth.normalizedPoints
            guard points.count > 0 else {
                DispatchQueue.main.async {
                    self.isAligned = false
                    self.alignmentHint = "嘴部特征不清晰，请重试"
                    self.mouthPoint = nil
                }
                return
            }
            // 取嘴唇平均点作为参考
            let avgX = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
            let avgY = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
            // 把人脸坐标变换到画面坐标（VN 是左下为原点，需翻转 y）
            let faceBox = face.boundingBox
            let px = faceBox.origin.x + avgX * faceBox.size.width
            let py = faceBox.origin.y + avgY * faceBox.size.height
            let normalized = CGPoint(x: px, y: 1 - py)

            // 椭圆模板区域（画面中心，半径取 AlignmentConfig）
            let cx: CGFloat = 0.5, cy: CGFloat = 0.5
            let rx = (self.mode == .tongue ? TongueCameraManager.AlignmentConfig.tongueRx : TongueCameraManager.AlignmentConfig.faceRx)
            let ry = (self.mode == .tongue ? TongueCameraManager.AlignmentConfig.tongueRy : TongueCameraManager.AlignmentConfig.faceRy)
            // 椭圆方程：(x-cx)^2/rx^2 + (y-cy)^2/ry^2 <= 1
            let dx = (normalized.x - cx) / rx
            let dy = (normalized.y - cy) / ry
            let value = dx*dx + dy*dy
            let aligned = value <= 1
            let hint: String
            if !aligned {
                var tips: [String] = []
                if normalized.x < cx - rx { tips.append("向左移动") }
                else if normalized.x > cx + rx { tips.append("向右移动") }
                if normalized.y < cy - ry { tips.append("抬高一些") }
                else if normalized.y > cy + ry { tips.append("降低一些") }
                hint = tips.joined(separator: "，")
            } else {
                hint = "很好，保持这个姿势"
            }
            DispatchQueue.main.async {
                self.isAligned = aligned
                self.alignmentHint = hint
                self.mouthPoint = normalized
            }
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
    }
}

struct TongueCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewView { PreviewView(session: session) }
    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        private let previewLayer = AVCaptureVideoPreviewLayer()
        init(session: AVCaptureSession) {
            super.init(frame: .zero)
            backgroundColor = .black
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(previewLayer)
        }
        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = bounds
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}





//#Preview {
//    NavigationView { TongueDiagnosisView() }
//}

// MARK: - 健康档案页面（简洁版本，只有导航栏）
struct HealthRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared
    @State private var basicInfo = BasicHealthInfo()
    @State private var showingBasicInfoEditor = false
    @State private var showingDiagnosisRecords = false

    var body: some View {
        ZStack(alignment: .top) {
            // 页面全局底色
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            // 顶部渐变层：参考设计稿绿色到天蓝的柔和过渡
            HealthRecordTopGradient()
                .frame(height: 270)
                .ignoresSafeArea(edges: .top)

            // 主要内容区域 - 可滚动
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HealthRecordProfileBadge()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                        .padding(.leading, 16)

                    HealthRecordSummaryCard()
                        .padding(.horizontal, 16)

                    HealthBasicInfoCard(info: basicInfo) {
                        showingBasicInfoEditor = true
                    }
                        .padding(.horizontal, 16)

                SleepExerciseCard()
                    .padding(.horizontal, 16)

                    DiagnosisRecordsCard(onManageRecords: { showingDiagnosisRecords = true })
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 32)
            }
            NavigationLink(destination: DiagnosisRecordsView(), isActive: $showingDiagnosisRecords) { EmptyView() }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundColor(.black)
                .tint(.black)
            }
            ToolbarItem(placement: .principal) {
                Text("健康档案")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .sheet(isPresented: $showingBasicInfoEditor) {
            HealthBasicInfoEditSheet(info: $basicInfo)
        }
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
            appearance.backgroundColor = UIColor.white.withAlphaComponent(0.12)
            appearance.shadowColor = .clear
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            let navBar = UINavigationBar.appearance()
            navBar.standardAppearance = appearance
            navBar.compactAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
            navBar.tintColor = .black
            syncBasicInfoWithUser()
        }
        .onDisappear {
            let navBar = UINavigationBar.appearance()
            navBar.tintColor = .black
        }
        .asSubView()
    }

    private func syncBasicInfoWithUser() {
        guard let user = authManager.currentUser else { return }
        let trimmedName = user.nickname?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        basicInfo.name = trimmedName
    }
}

/// 健康档案顶部渐变背景
private struct HealthRecordTopGradient: View {
    var body: some View {
        ZStack {
            // 主体线性渐变：左上绿色向右上天蓝过渡，并向下柔和趋近白色
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "C7F5C7"), location: 0.0),
                    .init(color: Color(hex: "A5E3F8"), location: 0.58),
                    .init(color: Color(hex: "F4F8FF"), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 左上高光，让绿色部分更通透
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

            // 右上冷色晕染，营造蓝色过渡的层次
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
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.0),
                    Color.white.opacity(0.5),
                    Color(UIColor.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
        }
    }
}

/// 顶部个人信息气泡
private struct HealthRecordProfileBadge: View {
    @ObservedObject private var authManager = AuthManager.shared

    private var avatarURL: URL? {
        guard let urlString = authManager.currentUser?.avatar, let url = URL(string: urlString), !urlString.isEmpty else {
            return nil
        }
        return url
    }

    private var maskedName: String {
        guard let rawName = authManager.currentUser?.nickname, !rawName.isEmpty else { return "健康报告" }
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 1 else { return trimmed }
        let first = trimmed.first ?? "*"
        if trimmed.count == 2 {
            return "\(first)*"
        }
        let last = trimmed.last ?? "*"
        return "\(first)*\(last)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                avatarView
                Text(maskedName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(
            BubbleWithPointer()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "6B63FF"), Color(hex: "5A5DF7"), Color(hex: "8076FF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            BubbleWithPointer()
                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
        )
        .shadow(color: Color(hex: "3726A2").opacity(0.25), radius: 18, x: 0, y: 12)
        .fixedSize()
    }

    @ViewBuilder
    private var avatarView: some View {
        Group {
            if let url = avatarURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholderAvatar
                }
            } else {
                placeholderAvatar
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }

    private var placeholderAvatar: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.28))
            Image(systemName: "person.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color.white)
        }
    }
}

private struct BasicHealthInfo: Equatable {
    var name: String = ""
    var age: Int?
    var heightCM: Double?
    var weightKG: Double?
    var bloodType: String?

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "--" : trimmed
    }

    var displayAge: String {
        guard let age else { return "--" }
        return "\(age) 岁"
    }

    var displayHeight: String {
        formatted(value: heightCM, unit: "cm")
    }

    var displayWeight: String {
        formatted(value: weightKG, unit: "kg")
    }

    var displayBloodType: String {
        guard let bloodType, !bloodType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "--" }
        return bloodType.uppercased()
    }

    private func formatted(value: Double?, unit: String) -> String {
        guard let value else { return "--" }
        if value.rounded() == value {
            return "\(Int(value)) \(unit)"
        }
        return String(format: "%.1f %@", value, unit)
    }
}

/// 健康档案主体内容卡片（白色）
private struct HealthRecordSummaryCard: View {
    @ObservedObject private var sleepManager = SleepDataManager.shared
    @StateObject private var healthDataManager = HealthProfileDataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日摘要")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2A60"))

            // 显示数据状态
            if healthDataManager.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在加载健康数据...")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                }
            } else if healthDataManager.healthProfile != nil || healthDataManager.lastUpdateTime != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("健康数据已更新")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "4CAF50"))
                    
                    if let updateTime = healthDataManager.lastUpdateTime {
                        Text("最后更新：\(formatUpdateTime(updateTime))")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                    }
                }
            } else {
                Text("暂无数据，稍后更新健康档案内容。")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.secondary)
            }

            Divider()

            HStack(spacing: 16) {
                SummaryMetricView(
                    title: "体质", 
                    value: healthDataManager.primaryConstitution,
                    unit: "类型"
                )
                SummaryMetricView(
                    title: "睡眠", 
                    value: formattedTodaySleepHours,
                    unit: "h"
                )
                SummaryMetricView(
                    title: "健康", 
                    value: healthDataManager.overallHealthScore > 0 ? "\(healthDataManager.overallHealthScore)" : "--",
                    unit: "分"
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        .task {
            // 加载健康数据
            await healthDataManager.refreshAllData()
        }
    }
    
    private func formatUpdateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private struct SummaryMetricView: View {
        let title: String
        let value: String
        let unit: String

        var body: some View {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                Text(value)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "1F2A60"))
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var formattedTodaySleepHours: String {
        let seconds = sleepManager.todaySleepDuration
        guard seconds > 0 else { return "--" }
        let hours = seconds / 3600
        // 一位小数展示
        return String(format: "%.1f", hours)
    }
}

/// 基础健康信息卡片（白色）
private struct HealthBasicInfoCard: View {
    var info: BasicHealthInfo
    var onEdit: (() -> Void)? = nil
    
    @StateObject private var healthDataManager = HealthProfileDataManager.shared

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("基础健康信息")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "1F2A60"))
                Spacer()
                Button(action: { onEdit?() }) {
                    Label("编辑", systemImage: "pencil")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "6B63FF"))
                .controlSize(.small)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                InfoItem(title: "姓名", value: info.displayName)
                InfoItem(title: "年龄", value: displayAge)
                InfoItem(title: "身高", value: displayHeight)
                InfoItem(title: "体重", value: displayWeight)
                InfoItem(title: "血型", value: displayBloodType)
                InfoItem(title: "体质", value: healthDataManager.primaryConstitution)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)
        .task {
            await healthDataManager.refreshAllData()
        }
    }
    
    // 计算属性，优先使用API数据
    private var displayAge: String {
        if let age = healthDataManager.healthProfile?.healthMetrics?.age {
            return "\(age) 岁"
        }
        return info.displayAge
    }
    
    private var displayHeight: String {
        if let height = healthDataManager.healthProfile?.height {
            return String(format: "%.0f cm", height)
        }
        return info.displayHeight
    }
    
    private var displayWeight: String {
        if let weight = healthDataManager.healthProfile?.weight {
            return String(format: "%.1f kg", weight)
        }
        return info.displayWeight
    }
    
    private var displayBloodType: String {
        if let bloodType = healthDataManager.healthProfile?.bloodType,
           bloodType != "unknown" && !bloodType.isEmpty {
            return bloodType.uppercased()
        }
        return info.displayBloodType
    }

    private struct InfoItem: View {
        let title: String
        let value: String

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "1F2A60"))
            }
        }
    }
}

/// 基础健康信息编辑表单
private struct HealthBasicInfoEditSheet: View {
    @Binding var info: BasicHealthInfo
    @Environment(\.dismiss) private var dismiss

    @State private var age: String
    @State private var height: String
    @State private var weight: String
    @State private var bloodType: String
    init(info: Binding<BasicHealthInfo>) {
        _info = info
        _age = State(initialValue: info.wrappedValue.age.map { String($0) } ?? "")
        _height = State(initialValue: HealthBasicInfoEditSheet.numberString(for: info.wrappedValue.heightCM))
        _weight = State(initialValue: HealthBasicInfoEditSheet.numberString(for: info.wrappedValue.weightKG))
        _bloodType = State(initialValue: info.wrappedValue.bloodType ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    HStack {
                        Text("姓名")
                        Spacer()
                        Text(info.displayName)
                            .foregroundStyle(.secondary)
                    }
                    TextField("年龄", text: $age)
                        .keyboardType(.numberPad)
                }

                Section("身体指标") {
                    TextField("身高 (cm)", text: $height)
                        .keyboardType(.decimalPad)
                    TextField("体重 (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                }

                Section("其他") {
                    TextField("血型", text: $bloodType)
                }
            }
            .navigationTitle("编辑健康信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
            }
        }
    }

    private func save() {
        info.age = Int(age.trimmingCharacters(in: .whitespacesAndNewlines))
        info.heightCM = Double(height.trimmingCharacters(in: .whitespacesAndNewlines))
        info.weightKG = Double(weight.trimmingCharacters(in: .whitespacesAndNewlines))
        info.bloodType = emptyToNil(bloodType)
        dismiss()
    }

    private func emptyToNil(_ string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func numberString(for value: Double?) -> String {
        guard let value else { return "" }
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

/// 睡眠与运动统计卡片
private struct SleepExerciseCard: View {
    @StateObject private var healthDataManager = HealthProfileDataManager.shared
    @ObservedObject private var sleepManager = SleepDataManager.shared
    
    private struct MetricBlock: View {
        let title: String
        let value: String
        let subtitle: String
        let icon: String
        let background: LinearGradient

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
            }
            .foregroundStyle(Color.white)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(background)
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("睡眠与运动统计")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2A60"))

            HStack(spacing: 14) {
                MetricBlock(
                    title: "睡眠评分",
                    value: sleepScoreText,
                    subtitle: sleepSubtitle,
                    icon: "moon.zzz.fill",
                    background: LinearGradient(
                        colors: [Color(hex: "5F7FFF"), Color(hex: "8EA6FF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                MetricBlock(
                    title: "运动评分",
                    value: exerciseScoreText,
                    subtitle: exerciseSubtitle,
                    icon: "figure.run.circle.fill",
                    background: LinearGradient(
                        colors: [Color(hex: "5BC2B1"), Color(hex: "7BDCC6")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
        .task {
            await healthDataManager.refreshAllData()
        }
    }
    
    // 计算睡眠评分和文本
    private var sleepScoreText: String {
        if let sleepScore = healthDataManager.healthProfile?.healthMetrics?.sleepScore {
            return "\(sleepScore)"
        }
        return "--"
    }
    
    private var sleepSubtitle: String {
        if let sleepQuality = healthDataManager.healthProfile?.healthMetrics?.sleepQualityLevel {
            switch sleepQuality {
            case "excellent": return "睡眠质量优秀"
            case "good": return "睡眠质量良好"
            case "fair": return "睡眠质量一般"
            case "poor": return "睡眠质量较差"
            default: return "睡眠质量评估"
            }
        }
        return "睡眠质量评估"
    }
    
    // 计算运动评分和文本
    private var exerciseScoreText: String {
        if let exerciseScore = healthDataManager.healthProfile?.healthMetrics?.exerciseScore {
            return "\(exerciseScore)"
        }
        return "--"
    }
    
    private var exerciseSubtitle: String {
        if let activityLevel = healthDataManager.healthProfile?.healthMetrics?.activityLevel {
            switch activityLevel {
            case "very_active": return "运动量很充足"
            case "active": return "运动量充足"
            case "moderate": return "运动量适中"
            case "low": return "运动量较少"
            case "sedentary": return "运动量不足"
            default: return "运动量评估"
            }
        }
        return "运动量评估"
    }
}

/// 舌诊与面诊记录卡片
private struct DiagnosisRecordsCard: View {
    @StateObject private var healthDataManager = HealthProfileDataManager.shared
    
    private struct DiagnosisRow: View {
        let title: String
        let description: String
        let status: String
        let icon: String
        let lastAnalyzedAt: String?

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "EEF2FF"))
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "4F5FEF"))
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text(status)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "4F5FEF"))
                    }
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                    
                    if let lastAnalyzedAt = lastAnalyzedAt {
                        Text("最后分析：\(formatAnalyzedTime(lastAnalyzedAt))")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary.opacity(0.8))
                    }
                }
            }
            .padding(.vertical, 6)
        }
        
        private func formatAnalyzedTime(_ timeString: String) -> String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: timeString) {
                let displayFormatter = DateFormatter()
                displayFormatter.locale = Locale(identifier: "zh_CN")
                displayFormatter.dateFormat = "MM-dd HH:mm"
                return displayFormatter.string(from: date)
            }
            return "未知时间"
        }
    }

    var onManageRecords: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("舌诊与面诊记录")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2A60"))

            VStack(spacing: 12) {
                DiagnosisRow(
                    title: "舌诊",
                    description: tongueDescription,
                    status: tongueStatus,
                    icon: "mouth",
                    lastAnalyzedAt: healthDataManager.healthProfile?.latestTongueAnalysis?.analyzedAt
                )
                Divider().overlay(Color.secondary.opacity(0.08))
                DiagnosisRow(
                    title: "面诊",
                    description: faceDescription,
                    status: faceStatus,
                    icon: "face.smiling",
                    lastAnalyzedAt: healthDataManager.healthProfile?.latestFaceAnalysis?.analyzedAt
                )
            }

            Button {
                onManageRecords()
            } label: {
                Text("管理所有记录")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "4F5FEF"))
            .controlSize(.regular)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
        .task {
            await healthDataManager.refreshAllData()
        }
    }
    
    // 舌诊相关计算属性
    private var tongueDescription: String {
        if let tongueAnalysis = healthDataManager.comprehensiveProfile?.latestTongueAnalysis {
            if let constitution = tongueAnalysis.constitutionAnalysis?.constitution {
                return "最新分析显示体质为：\(constitution)，建议根据体质特点进行调理。"
            }
            return "舌诊分析已完成，请查看详细报告了解体质特点。"
        }
        return "当前暂无舌诊记录，完成检测后会在此展示结果与时间。"
    }
    
    private var tongueStatus: String {
        if healthDataManager.healthProfile?.latestTongueAnalysis?.analyzedAt != nil {
            return "已分析"
        }
        return "暂无记录"
    }
    
    // 面诊相关计算属性
    private var faceDescription: String {
        if healthDataManager.comprehensiveProfile?.latestFaceAnalysis?.analysisStatus == "completed" {
            return "面诊分析已完成，详细结果请查看分析报告。"
        }
        return "当前暂无面诊记录，完成检测后可查看详细分析。"
    }
    
    private var faceStatus: String {
        if healthDataManager.healthProfile?.latestFaceAnalysis?.analyzedAt != nil {
            return "已分析"
        }
        return "暂无记录"
    }
}

private struct DiagnosisRecordsView: View {
    @Environment(\.dismiss) private var dismiss

    private let sections = DiagnosisRecordSection.samples

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(sections) { section in
                    DiagnosisRecordSectionView(section: section)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("舌诊与面诊记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundStyle(Color.black)
            }
        }
    }
}

private struct DiagnosisRecordSectionView: View {
    let section: DiagnosisRecordSection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(section.accent.opacity(0.15))
                    Image(systemName: section.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(section.accent)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "1F2A60"))
                    Text(section.recordCountDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
            }

            if section.records.isEmpty {
                Text("目前没有记录，完成检测后会自动生成历史。")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(section.records) { record in
                    DiagnosisRecordRow(record: record, accent: section.accent)
                    if record.id != section.records.last?.id {
                        Divider().overlay(Color.secondary.opacity(0.08))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
    }
}

private struct DiagnosisRecordRow: View {
    let record: DiagnosisRecord
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.result)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "1F2A60"))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: record.statusIcon)
                    Text(record.status)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(accent)
            }

            Text(record.summary)
                .font(.system(size: 13))
                .foregroundStyle(Color.secondary)

            HStack {
                Label(record.date, systemImage: "clock")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                Spacer()
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("查看详情")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(accent)
            }
        }
    }
}

private struct DiagnosisRecordSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let accent: Color
    let records: [DiagnosisRecord]

    var recordCountDescription: String {
        records.isEmpty ? "尚无记录" : "共 \(records.count) 条记录"
    }

    static let samples: [DiagnosisRecordSection] = [
        DiagnosisRecordSection(
            title: "舌诊记录",
            icon: "mouth.fill",
            accent: Color(hex: "4F5FEF"),
            records: [
                DiagnosisRecord(
                    date: "2025-09-21 09:35",
                    result: "平和质",
                    summary: "舌质红润、苔薄白，整体表现平和，建议保持目前生活习惯。",
                    status: "已分析",
                    statusIcon: "checkmark.circle.fill"
                ),
                DiagnosisRecord(
                    date: "2025-09-14 08:50",
                    result: "气虚倾向",
                    summary: "舌体略胖，齿痕轻，提示气虚倾向，注意补中益气。",
                    status: "已分析",
                    statusIcon: "checkmark.circle.fill"
                ),
                DiagnosisRecord(
                    date: "2025-09-01 22:10",
                    result: "建议复检",
                    summary: "舌象拍摄环境偏暗，建议在光线均匀的环境重新采集数据。",
                    status: "需补拍",
                    statusIcon: "exclamationmark.circle.fill"
                )
            ]
        ),
        DiagnosisRecordSection(
            title: "面诊记录",
            icon: "face.smiling.fill",
            accent: Color(hex: "F08A5B"),
            records: [
                DiagnosisRecord(
                    date: "2025-09-20 19:05",
                    result: "气血和缓",
                    summary: "肤色红润，面色明亮，说明气血运行良好，可保持现有作息。",
                    status: "已分析",
                    statusIcon: "checkmark.circle.fill"
                ),
                DiagnosisRecord(
                    date: "2025-09-05 18:12",
                    result: "肝郁倾向",
                    summary: "面部略显暗沉，建议适度舒缓压力，增加户外活动。",
                    status: "已分析",
                    statusIcon: "checkmark.circle.fill"
                )
            ]
        )
    ]
}

private struct DiagnosisRecord: Identifiable {
    let id = UUID()
    let date: String
    let result: String
    let summary: String
    let status: String
    let statusIcon: String
}

/// 带右侧指针的气泡形状
private struct BubbleWithRightPointer: Shape {
    func path(in rect: CGRect) -> Path {
        let pointerWidth: CGFloat = 6
        let pointerHeight: CGFloat = 14
        let cornerRadius: CGFloat = min(rect.height * 0.5, 22)
        let mainRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width - pointerWidth, height: rect.height)

        var path = Path(roundedRect: mainRect, cornerRadius: cornerRadius)

        let pointerStartY = mainRect.midY - pointerHeight / 2
        path.move(to: CGPoint(x: mainRect.maxX, y: pointerStartY))
        path.addLine(to: CGPoint(x: rect.maxX, y: mainRect.midY))
        path.addLine(to: CGPoint(x: mainRect.maxX, y: pointerStartY + pointerHeight))
        path.closeSubpath()

        return path
    }
}

/// 带底部指针的气泡形状
private struct BubbleWithPointer: Shape {
    func path(in rect: CGRect) -> Path {
        let pointerHeight: CGFloat = 6
        let pointerWidth: CGFloat = 14
        let cornerRadius: CGFloat = min(rect.height * 0.5, 22)
        let mainRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - pointerHeight)

        var path = Path(roundedRect: mainRect, cornerRadius: cornerRadius)

        let pointerStartX = mainRect.midX - pointerWidth / 2
        path.move(to: CGPoint(x: pointerStartX, y: mainRect.maxY))
        path.addLine(to: CGPoint(x: mainRect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: pointerStartX + pointerWidth, y: mainRect.maxY))
        path.closeSubpath()

        return path
    }
}
