import Foundation
import SwiftUI
import Combine

// MARK: - 主页ViewModel
@MainActor
class HomePageViewModel: ObservableObject {
    // 服务依赖
    private let planService = PlanService.shared
    private let planStatusManager = PlanStatusManager.shared

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var showCheckinToast = false
    @Published var checkinToastMessage = ""
    @Published var isCheckingIn = false
    
    // 打卡相关数据
    @Published var hasCheckedInToday = false
    @Published var todayCheckinRecord: CheckinAPIRecord?
    @Published var checkinStatistics: CheckinStatistics?
    
    // 今日计划数据
    @Published var todayPlans: [TodayPlan] = []
    @Published var completedPlansCount = 0

    // 计算已完成计划的总用时（分钟）
    var completedPlansTime: Int {
        return todayPlans
            .filter { $0.isCompleted }
            .compactMap { $0.estimatedDuration }
            .reduce(0) { total, duration in
                total + Int(duration / 60) // 转换为分钟
            }
    }

    // 睡眠时间贡献（分钟）
    @Published var sleepTimeContribution: Int = 0

    // 运动时间贡献（分钟）
    @Published var exerciseTimeContribution: Int = 0

    // 综合自律时间（计划 + 睡眠 + 运动）
    var comprehensiveSelfDisciplineTime: Int {
        return completedPlansTime + sleepTimeContribution + exerciseTimeContribution
    }

    // 计算计划完成率（百分比）
    var planCompletionRate: Int {
        guard !todayPlans.isEmpty else { return 0 }
        return Int(Double(completedPlansCount) / Double(todayPlans.count) * 100)
    }
    
    // 应用使用数据
    @Published var appUsageData: [AppUsageData] = []
    
    // 睡眠分析数据
    @Published var sleepAnalysis: DeepSeekSleepAnalysis?

    // 运动分析数据
    @Published var isLoadingWorkoutData = false
    @Published var weeklyWorkoutData: [HomeWorkoutData] = []
    @Published var workoutAnalysisSummary: WorkoutAnalysisSummary?

    // 社区帖子数据
    @Published var communityPosts: [Post] = []

    // 打卡历史数据
    @Published var checkinHistory: [String] = []

    // 激励语录
    @Published var motivationalQuotes: [String] = [
        "今天的努力是明天成功的基石",
        "每一次坚持都在为更好的自己积累力量",
        "自律给我自由，坚持成就梦想",
        "小步快跑，持续进步",
        "今日事今日毕，明日更精彩"
    ]
    
    // MARK: - Private Properties
    private let checkinAPIService = CheckinAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupMockData()
        Task {
            await fetchData()
        }
    }
    
    // MARK: - Public Methods
    
    /// 获取数据
    func fetchData() async {
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadCheckinData() }
            group.addTask { await self.loadTodayPlans() }
            group.addTask { await self.loadAppUsageData() }
            group.addTask { await self.loadSleepAnalysis() }
            group.addTask { await self.loadWorkoutAnalysisData() }
            group.addTask { await self.loadCommunityPosts() }
            group.addTask { await self.loadCheckinHistory() }
        }

        // 计算自律时间贡献
        await calculateSelfDisciplineContributions()
        
        isLoading = false
    }
    
    /// 刷新数据
    func refreshData() async {
        await fetchData()
    }
    
    /// 执行打卡
    func performCheckin() async {
        guard !isCheckingIn && !hasCheckedInToday else { return }
        
        isCheckingIn = true
        
        do {
            let checkinRecord = try await checkinAPIService.checkin()
            
            // 更新状态
            hasCheckedInToday = true
            todayCheckinRecord = checkinRecord
            
            // 显示成功提示
            checkinToastMessage = "打卡成功！连续坚持，你很棒！"
            showCheckinToast = true
            
            // 刷新统计数据
            await loadCheckinStatistics()
            
        } catch {
            // 处理错误
            checkinToastMessage = "打卡失败，请重试"
            showCheckinToast = true
        }
        
        isCheckingIn = false
    }
    
    // MARK: - Private Methods
    
    private func loadCheckinData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadTodayCheckinStatus() }
            group.addTask { await self.loadCheckinStatistics() }
        }
    }
    
    private func loadTodayCheckinStatus() async {
        do {
            let status = try await checkinAPIService.getTodayCheckinStatus()
            hasCheckedInToday = status.hasCheckedIn
            todayCheckinRecord = status.checkin
        } catch {
            print("加载今日打卡状态失败: \(error)")
        }
    }
    
    func loadCheckinStatistics() async {
        do {
            checkinStatistics = try await checkinAPIService.getCheckinStatistics()
        } catch {
            print("加载打卡统计失败: \(error)")
        }
    }
    
    private func loadTodayPlans() async {
        do {
            // 获取今日计划
            let planList = try await planService.getPlans(page: 1, limit: 20)

            // 过滤今日计划（根据startTime或createdAt）
            let today = getCurrentDateString()
            var realTodayPlans = planList.plans.compactMap { planNew in
                // 从本地存储获取提醒时间
                let reminderTime = PlanReminderManager.shared.getReminderTime(for: planNew.title)
                // 将PlanNew转换为Plan
                return Plan(
                    title: planNew.title,
                    description: planNew.description,
                    category: planNew.category,
                    startDate: planNew.startDate,
                    endDate: planNew.endDate,
                    isActive: planNew.isActive,
                    progress: planNew.progress,
                    reminderTime: reminderTime
                )
            }.filter { plan in
                // 过滤今日计划
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let startDateString = dateFormatter.string(from: plan.startDate)
                return startDateString == today
            }

            // 使用状态管理器更新计划状态
            realTodayPlans = await planStatusManager.updatePlansStatus(realTodayPlans)

            // 转换为TodayPlan格式
            todayPlans = realTodayPlans.map { plan in
                let status = PlanStatusManager.shared.calculatePlanStatus(for: plan)
                let isCompleted = (status == .completed)

                // 计算预估时长：如果有提醒时间，使用 endDate - reminderTime；否则使用 endDate - startDate
                let estimatedDuration: TimeInterval
                if let reminderTime = plan.reminderTime {
                    estimatedDuration = plan.endDate.timeIntervalSince(reminderTime)
                } else {
                    estimatedDuration = plan.endDate.timeIntervalSince(plan.startDate)
                }

                return TodayPlan(
                    title: plan.title,
                    description: plan.description,
                    category: plan.category,
                    isCompleted: isCompleted,
                    completedAt: isCompleted ? Date() : nil,
                    estimatedDuration: estimatedDuration
                )
            }

            completedPlansCount = todayPlans.filter { $0.isCompleted }.count

            print("✅ 首页成功加载今日计划: \(todayPlans.count) 条，已完成: \(completedPlansCount) 条")
        } catch {
            print("❌ 首页加载今日计划失败: \(error.localizedDescription)")
            todayPlans = []
            completedPlansCount = 0
        }
    }

    // MARK: - Helper Methods
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// 计算自律时间贡献
    private func calculateSelfDisciplineContributions() async {
        await MainActor.run {
            // 计算睡眠时间贡献
            sleepTimeContribution = calculateSleepTimeContribution()

            // 计算运动时间贡献
            exerciseTimeContribution = calculateExerciseTimeContribution()

            // 更新应用管理器的综合自律时间
            let appUsageManager = AppUsageManager.shared
            appUsageManager.updateComprehensiveSelfDisciplineTime(
                planTime: completedPlansTime,
                sleepTime: sleepTimeContribution,
                exerciseTime: exerciseTimeContribution
            )

            print("📊 自律时间贡献计算完成 - 计划:\(completedPlansTime)分钟, 睡眠:\(sleepTimeContribution)分钟, 运动:\(exerciseTimeContribution)分钟")
        }
    }

    /// 计算睡眠时间贡献
    private func calculateSleepTimeContribution() -> Int {
        let sleepDataManager = SleepDataManager.shared

        // 获取最近的睡眠记录（昨夜）
        if let lastRecord = sleepDataManager.sleepRecords.first {
            let sleepHours = lastRecord.totalSleepDuration / 3600 // 转换为小时

            // 睡眠时间转换规则：
            // 6-7小时：30分钟自律时间
            // 7-8小时：50分钟自律时间
            // 8-9小时：60分钟自律时间
            // 少于6小时或多于9小时：按比例减少
            let contribution: Int
            if sleepHours >= 7 && sleepHours <= 8 {
                contribution = 50 // 最佳睡眠时间
            } else if sleepHours >= 8 && sleepHours <= 9 {
                contribution = 60 // 充足睡眠
            } else if sleepHours >= 6 && sleepHours < 7 {
                contribution = 30 // 基本睡眠
            } else if sleepHours >= 5 && sleepHours < 6 {
                contribution = 15 // 睡眠不足
            } else if sleepHours > 9 {
                contribution = Int(max(30, 60 - (sleepHours - 9) * 10)) // 过度睡眠递减
            } else {
                contribution = 0 // 严重睡眠不足
            }

            print("📊 睡眠时间贡献计算：睡眠\(String(format: "%.1f", sleepHours))小时 -> \(contribution)分钟自律时间")
            return contribution
        }

        // 如果没有睡眠记录，从睡眠分析数据中获取
        if let sleepAnalysis = sleepAnalysis {
            // 从睡眠阶段分析中计算总睡眠时间
            let totalSleepTime = sleepAnalysis.stageAnalysis.lightSleepDuration +
                               sleepAnalysis.stageAnalysis.deepSleepDuration +
                               sleepAnalysis.stageAnalysis.remSleepDuration
            let sleepHours = totalSleepTime / 3600
            let contribution = min(Int(sleepHours * 8), 60) // 简化计算
            return max(0, contribution)
        }

        return 0
    }

    /// 计算运动时间贡献
    private func calculateExerciseTimeContribution() -> Int {
        // 获取今日运动时间
        let todayExerciseMinutes = getTodayExerciseTime()

        // 运动时间转换规则：
        // 0-15分钟：按1:1转换
        // 15-30分钟：按1:1.2转换（奖励）
        // 30-60分钟：按1:1.5转换（更多奖励）
        // 60分钟以上：按1:1.5转换，但最多90分钟自律时间
        let contribution: Int
        if todayExerciseMinutes <= 15 {
            contribution = todayExerciseMinutes
        } else if todayExerciseMinutes <= 30 {
            contribution = Int(Double(todayExerciseMinutes) * 1.2)
        } else if todayExerciseMinutes <= 60 {
            contribution = Int(Double(todayExerciseMinutes) * 1.5)
        } else {
            contribution = min(Int(Double(todayExerciseMinutes) * 1.5), 90)
        }

        print("📊 运动时间贡献计算：运动\(todayExerciseMinutes)分钟 -> \(contribution)分钟自律时间")
        return contribution
    }

    /// 获取今日运动时间
    private func getTodayExerciseTime() -> Int {
        // 优先从运动分析摘要获取
        if let workoutSummary = workoutAnalysisSummary {
            return workoutSummary.totalDuration
        }

        // 从今日运动数据获取
        if let todayWorkout = weeklyWorkoutData.last {
            return todayWorkout.duration
        }

        // 从HealthKit获取今日运动数据
        // 这里可以添加从HealthKit获取今日运动时间的逻辑
        // 由于HealthKit查询是异步的，这里使用已缓存的数据

        return 0
    }
    
    private func loadAppUsageData() async {
        // 从 AppUsageManager 获取真实的应用使用数据
        await MainActor.run {
            let appUsageManager = AppUsageManager.shared

            // 将 AppUsageManager 的数据转换为 HomePageViewModel 的格式
            self.appUsageData = appUsageManager.appUsageData.map { data in
                AppUsageData(
                    appName: data.appName,
                    usageTime: Int(data.usageTime),
                    icon: data.icon
                )
            }

            print("📱 首页：已加载 \(self.appUsageData.count) 个应用的使用数据")
        }
    }
    
    private func loadSleepAnalysis() async {
        // 从SleepDataManager获取真实的睡眠数据
        let sleepManager = SleepDataManager.shared

        // 确保睡眠数据已加载
        await sleepManager.loadSleepHistory()

        await MainActor.run {
            // 获取近一月的睡眠记录
            let calendar = Calendar.current
            let now = Date()
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            let recentRecords = sleepManager.sleepRecords.filter { $0.bedTime >= monthAgo }

            if !recentRecords.isEmpty {
                // 计算近一月的平均数据
                let avgQuality = recentRecords.map { Double($0.sleepQualityScore) }.reduce(0, +) / Double(recentRecords.count)
                let avgEfficiency = recentRecords.map { $0.sleepEfficiency }.reduce(0, +) / Double(recentRecords.count)
                let totalSleepTime = recentRecords.map { $0.totalSleepDuration }.reduce(0, +)
                let avgSleepTime = totalSleepTime / Double(recentRecords.count)

                // 生成基于真实数据的洞察
                var insights: [String] = []
                var recommendations: [String] = []

                // 根据睡眠效率生成洞察
                if avgEfficiency >= 0.85 {
                    insights.append("您的睡眠效率很好，达到了\(String(format: "%.1f", avgEfficiency * 100))%")
                } else if avgEfficiency >= 0.75 {
                    insights.append("您的睡眠效率为\(String(format: "%.1f", avgEfficiency * 100))%，还有提升空间")
                    recommendations.append("尝试在睡前1小时避免使用电子设备")
                } else {
                    insights.append("您的睡眠效率偏低，为\(String(format: "%.1f", avgEfficiency * 100))%")
                    recommendations.append("建议调整睡眠环境，保持卧室安静和黑暗")
                }

                // 根据睡眠时长生成洞察
                let avgHours = avgSleepTime / 3600
                if avgHours >= 7.5 {
                    insights.append("您的平均睡眠时长为\(String(format: "%.1f", avgHours))小时，符合健康标准")
                } else if avgHours >= 6.5 {
                    insights.append("您的平均睡眠时长为\(String(format: "%.1f", avgHours))小时，建议适当增加")
                    recommendations.append("尝试提前30分钟上床睡觉")
                } else {
                    insights.append("您的睡眠时长不足，平均只有\(String(format: "%.1f", avgHours))小时")
                    recommendations.append("建议保证每晚至少7-8小时的睡眠时间")
                }

                // 根据睡眠质量评分生成建议
                if avgQuality >= 80 {
                    recommendations.append("继续保持良好的睡眠习惯")
                } else if avgQuality >= 70 {
                    recommendations.append("保持规律的作息时间")
                } else {
                    recommendations.append("建议咨询医生，改善睡眠质量")
                }

                // 计算睡眠阶段分布（基于真实数据的平均值）
                let avgDeepSleepPercentage = recentRecords.compactMap { record in
                    let deepStages = record.sleepStages.filter { $0.stage == .deep }
                    let totalDeepTime = deepStages.reduce(0) { $0 + $1.duration }
                    return record.totalSleepDuration > 0 ? (totalDeepTime / record.totalSleepDuration) * 100 : 0
                }.reduce(0, +) / Double(recentRecords.count)

                let avgLightSleepPercentage = recentRecords.compactMap { record in
                    let lightStages = record.sleepStages.filter { $0.stage == .light }
                    let totalLightTime = lightStages.reduce(0) { $0 + $1.duration }
                    return record.totalSleepDuration > 0 ? (totalLightTime / record.totalSleepDuration) * 100 : 0
                }.reduce(0, +) / Double(recentRecords.count)

                let avgRemSleepPercentage = recentRecords.compactMap { record in
                    let remStages = record.sleepStages.filter { $0.stage == .rem }
                    let totalRemTime = remStages.reduce(0) { $0 + $1.duration }
                    return record.totalSleepDuration > 0 ? (totalRemTime / record.totalSleepDuration) * 100 : 0
                }.reduce(0, +) / Double(recentRecords.count)


                self.sleepAnalysis = DeepSeekSleepAnalysis(
                    sessionId: "real_data_\(UUID().uuidString)",
                    qualityScore: avgQuality,
                    insights: insights,
                    recommendations: recommendations,
                    sleepEfficiency: avgEfficiency * 100, // 转换为百分比
                    lightSleepPercentage: avgLightSleepPercentage,
                    deepSleepPercentage: avgDeepSleepPercentage,
                    remSleepPercentage: avgRemSleepPercentage
                )

                print("📊 首页：已加载近一月睡眠分析数据，记录数: \(recentRecords.count)，平均质量: \(String(format: "%.1f", avgQuality))")
            } else {
                // 没有睡眠记录时，清空分析数据
                self.sleepAnalysis = nil
                print("📊 首页：近一月无睡眠记录，清空分析数据")
            }
        }
    }

    func loadWorkoutAnalysisData() async {
        isLoadingWorkoutData = true

        do {
            // 获取运动统计数据（最近一周）
            let statisticsData = try await NewWorkoutAPIService.shared.getWorkoutStatistics(period: "week")
            print("📊 成功获取运动统计数据，趋势数据条数: \(statisticsData.trends?.count ?? 0)")

            // 生成本周的运动数据（从周一开始）
            let calendar = Calendar.current
            let today = Date()
            var weeklyData: [HomeWorkoutData] = []

            // 获取本周的开始日期（周一）
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today

            // 获取主要运动类型
            let primaryWorkoutType = getPrimaryWorkoutType(from: statisticsData.workoutTypeBreakdown ?? [:])

            print("📊 API数据解析:")
            print("  总运动时长: \((statisticsData.totalDuration ?? 0) / 60)分钟")
            print("  总运动次数: \(statisticsData.totalWorkouts ?? 0)")
            print("  总卡路里: \(statisticsData.totalCalories ?? 0)")
            print("  主要运动类型: \(primaryWorkoutType)")

            print("📊 开始生成一周数据，今天是: \(getDayName(for: today))")
            print("📊 本周开始日期: \(startOfWeek)")

            // 获取本周的详细运动记录来生成准确的每日数据
            print("📊 获取本周详细运动记录")
            weeklyData = await generateWeeklyDataFromDetailedRecords(
                startOfWeek: startOfWeek,
                primaryWorkoutType: primaryWorkoutType,
                calendar: calendar,
                today: today
            )

            // 使用API返回的统计数据
            let apiTotalDuration = Int(statisticsData.effectiveStatistics.totalDuration) / 60 // 转换为分钟
            let apiTotalCalories = statisticsData.effectiveStatistics.totalCalories
            let workoutDays = weeklyData.filter { $0.duration > 0 }.count
            let averageDuration = workoutDays > 0 ? apiTotalDuration / workoutDays : 0

            await MainActor.run {
                self.workoutAnalysisSummary = WorkoutAnalysisSummary(
                    totalDuration: apiTotalDuration,
                    totalCalories: apiTotalCalories,
                    workoutDays: workoutDays,
                    averageDuration: averageDuration,
                    weeklyGoalProgress: min(Double(workoutDays) / 5.0, 1.0) // 假设每周目标5天
                )

                self.weeklyWorkoutData = weeklyData
                self.isLoadingWorkoutData = false

                print("📊 运动数据加载完成，共 \(weeklyData.count) 天数据")
                for data in weeklyData {
                    print("  \(data.date): \(data.duration)分钟 - \(data.type)")
                }
            }

        } catch {
            print("❌ 加载运动分析数据失败: \(error)")
            print("📊 使用模拟数据作为后备方案")

            // 如果API调用失败，使用模拟数据作为后备
            await loadMockWorkoutData()
        }
    }

    // 后备的模拟数据加载方法
    private func loadMockWorkoutData() async {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [HomeWorkoutData] = []

        // 获取本周的开始日期（周一）
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today

        // 从周一开始生成7天的模拟数据，确保有一些运动数据
        let mockDurations = [45, 30, 0, 60, 40, 90, 0] // 周一到周日的运动时长
        let mockTypes = ["跑步", "力量训练", "休息", "瑜伽", "跑步", "户外骑行", "休息"]

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? startOfWeek
            let dayName = getDayName(for: date)

            let duration = mockDurations[i]
            let workoutType = mockTypes[i]

            weeklyData.append(HomeWorkoutData(
                date: dayName,
                duration: duration,
                type: workoutType,
                calories: duration > 0 ? Int(Double(duration) * 8.5) : 0,
                distance: workoutType == "跑步" && duration > 0 ? Double(duration) * 0.15 :
                         workoutType == "户外骑行" && duration > 0 ? Double(duration) * 0.3 : 0
            ))
        }

        let totalDuration = weeklyData.reduce(0) { $0 + $1.duration }
        let totalCalories = weeklyData.reduce(0) { $0 + $1.calories }
        let workoutDays = weeklyData.filter { $0.duration > 0 }.count
        let averageDuration = workoutDays > 0 ? totalDuration / workoutDays : 0

        await MainActor.run {
            self.workoutAnalysisSummary = WorkoutAnalysisSummary(
                totalDuration: totalDuration,
                totalCalories: totalCalories,
                workoutDays: workoutDays,
                averageDuration: averageDuration,
                weeklyGoalProgress: min(Double(workoutDays) / 5.0, 1.0)
            )

            self.weeklyWorkoutData = weeklyData
            self.isLoadingWorkoutData = false
        }
    }

    private func getDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func getRandomWorkoutType() -> String {
        let types = ["跑步", "力量训练", "瑜伽", "骑行", "游泳", "休息"]
        return types.randomElement() ?? "跑步"
    }

    // 格式化日期用于比较（只保留年月日）
    private func formatDateForComparison(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "yyyy-MM-dd"
            return dayFormatter.string(from: date)
        }
        return dateString.prefix(10).description // 取前10个字符作为日期
    }

    // 根据运动趋势数据确定主要运动类型
    private func determineWorkoutType(from trends: [WorkoutTrendData], duration: Int) -> String {
        if duration == 0 {
            return "休息"
        }

        // 这里可以根据实际的运动类型数据来判断
        // 目前使用简单的逻辑：如果有距离数据，可能是跑步或骑行
        let hasDistance = trends.contains { $0.type == "distance" && $0.value > 0 }

        if hasDistance {
            // 根据距离和时长判断是跑步还是骑行
            let distance = trends.first { $0.type == "distance" }?.value ?? 0
            let speed = duration > 0 ? distance / (Double(duration) / 60.0) : 0 // km/h

            if speed > 15 {
                return "骑行"
            } else {
                return "跑步"
            }
        } else {
            // 没有距离数据，可能是力量训练、瑜伽等
            let workoutTypes = ["力量训练", "瑜伽", "健身", "游泳"]
            return workoutTypes.randomElement() ?? "健身"
        }
    }

    // 从运动类型分布中获取主要运动类型
    private func getPrimaryWorkoutType(from breakdown: [String: Int]) -> String {
        // 运动类型映射
        let typeMapping: [String: String] = [
            "walking": "步行",
            "running": "跑步",
            "cycling": "骑行",
            "swimming": "游泳",
            "yoga": "瑜伽",
            "strength": "力量训练",
            "hiking": "徒步",
            "other": "其他运动"
        ]

        // 找到次数最多的运动类型
        let primaryType = breakdown.max { $0.value < $1.value }?.key ?? "walking"
        return typeMapping[primaryType] ?? "运动"
    }

    // 从API获取本周详细运动记录并生成每日数据
    private func generateWeeklyDataFromDetailedRecords(
        startOfWeek: Date,
        primaryWorkoutType: String,
        calendar: Calendar,
        today: Date
    ) async -> [HomeWorkoutData] {
        var weeklyData: [HomeWorkoutData] = []

        do {
            // 计算本周的结束日期
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek

            // 格式化日期为API需要的格式
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startDateString = dateFormatter.string(from: startOfWeek)
            let endDateString = dateFormatter.string(from: endOfWeek)

            print("📊 获取运动记录: \(startDateString) 到 \(endDateString)")

            // 获取本周的运动记录
            let workouts = try await NewWorkoutAPIService.shared.getWorkouts(
                page: 1,
                limit: 100, // 获取足够多的记录
                startDate: startDateString,
                endDate: endDateString,
                sortBy: "startTime",
                sortOrder: "asc"
            )

            print("📊 获取到 \(workouts.count) 条运动记录")

            // 按日期分组运动数据
            var dailyWorkoutMap: [String: (duration: Int, calories: Int, distance: Double, count: Int, types: Set<String>)] = [:]

            for workout in workouts {
                // 解析运动开始时间 - API返回格式: "2025-09-14 05:05:20"
                let apiDateFormatter = DateFormatter()
                apiDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                apiDateFormatter.timeZone = TimeZone.current

                if let workoutDate = apiDateFormatter.date(from: workout.startTime) {
                    let dayKey = dateFormatter.string(from: workoutDate)

                    let durationMinutes = workout.duration / 60
                    let calories = workout.basicMetrics.calories
                    let distance = workout.basicMetrics.totalDistance
                    let workoutType = workout.workoutType

                    if var existingData = dailyWorkoutMap[dayKey] {
                        existingData.duration += durationMinutes
                        existingData.calories += calories
                        existingData.distance += distance
                        existingData.count += 1
                        existingData.types.insert(workoutType)
                        dailyWorkoutMap[dayKey] = existingData
                        print("📊 累加运动记录: \(dayKey) - \(workoutType) - \(durationMinutes)分钟 (总计: \(existingData.duration)分钟)")
                    } else {
                        dailyWorkoutMap[dayKey] = (
                            duration: durationMinutes,
                            calories: calories,
                            distance: distance,
                            count: 1,
                            types: Set([workoutType])
                        )
                        print("📊 新增运动记录: \(dayKey) - \(workoutType) - \(durationMinutes)分钟")
                    }
                } else {
                    print("❌ 日期解析失败: \(workout.startTime)")
                }
            }

            // 生成一周的数据
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? startOfWeek
                let dayName = getDayName(for: date)
                let dayKey = dateFormatter.string(from: date)
                let isToday = calendar.isDate(date, inSameDayAs: today)

                if let dayData = dailyWorkoutMap[dayKey] {
                    // 确定主要运动类型
                    let mainType = dayData.types.first ?? primaryWorkoutType
                    let displayType = convertWorkoutTypeToDisplayName(mainType)

                    weeklyData.append(HomeWorkoutData(
                        date: dayName,
                        duration: dayData.duration,
                        type: displayType,
                        calories: dayData.calories,
                        distance: dayData.distance
                    ))

                    print("📊 \(dayName) (索引\(i))\(isToday ? " [今天]" : ""): \(dayData.duration)分钟 - \(displayType)")
                } else {
                    // 没有运动数据的日子
                    weeklyData.append(HomeWorkoutData(
                        date: dayName,
                        duration: 0,
                        type: "休息",
                        calories: 0,
                        distance: 0.0
                    ))

                    print("📊 \(dayName) (索引\(i))\(isToday ? " [今天]" : ""): 0分钟 - 休息")
                }
            }

        } catch {
            print("❌ 获取运动记录失败: \(error)")
            // 如果API调用失败，生成全休息的一周
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? startOfWeek
                let dayName = getDayName(for: date)

                weeklyData.append(HomeWorkoutData(
                    date: dayName,
                    duration: 0,
                    type: "休息",
                    calories: 0,
                    distance: 0.0
                ))
            }
        }

        return weeklyData
    }

    // 将API运动类型转换为显示名称
    private func convertWorkoutTypeToDisplayName(_ type: String) -> String {
        switch type {
        case "running": return "跑步"
        case "walking": return "步行"
        case "cycling": return "骑行"
        case "swimming": return "游泳"
        case "yoga": return "瑜伽"
        case "strength": return "力量训练"
        case "hiking": return "徒步"
        default: return "运动"
        }
    }

    // 创建智能的运动数据分配策略
    private func createWorkoutDistribution(totalDuration: Int, totalWorkouts: Int, totalCalories: Int, totalDistance: Double) -> [(duration: Int, calories: Int, distance: Double)] {
        var distribution: [(duration: Int, calories: Int, distance: Double)] = []

        // 如果没有运动数据，返回全零数组
        if totalWorkouts == 0 || totalDuration == 0 {
            for _ in 0..<7 {
                distribution.append((duration: 0, calories: 0, distance: 0.0))
            }
            return distribution
        }

        print("📊 智能分配运动数据:")
        print("  总时长: \(totalDuration)分钟, 总次数: \(totalWorkouts)")

        // 根据总运动时长动态决定分配策略
        let (workoutDays, intensityPattern) = determineDistributionStrategy(totalDuration: totalDuration, totalWorkouts: totalWorkouts)

        print("  分配策略: \(workoutDays)天运动")
        print("  强度模式: \(intensityPattern)")

        // 计算有效的强度系数总和
        let totalIntensity = intensityPattern.reduce(0, +)

        // 为每天分配数据
        for i in 0..<7 {
            if intensityPattern[i] > 0 {
                // 根据强度系数分配运动时长
                let dayDuration = Int(Double(totalDuration) * intensityPattern[i] / totalIntensity)
                let dayCalories = Int(Double(totalCalories) * intensityPattern[i] / totalIntensity)
                let dayDistance = totalDistance * intensityPattern[i] / totalIntensity

                distribution.append((
                    duration: dayDuration,
                    calories: dayCalories,
                    distance: dayDistance
                ))

                print("  \(getDayName(for: Calendar.current.date(byAdding: .day, value: i, to: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()) ?? Date())): \(dayDuration)分钟")
            } else {
                // 休息日
                distribution.append((duration: 0, calories: 0, distance: 0.0))
                print("  \(getDayName(for: Calendar.current.date(byAdding: .day, value: i, to: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()) ?? Date())): 休息")
            }
        }

        return distribution
    }

    // 根据总运动时长和次数确定分配策略
    private func determineDistributionStrategy(totalDuration: Int, totalWorkouts: Int) -> (workoutDays: Int, intensityPattern: [Double]) {
        let avgDurationPerWorkout = totalDuration / max(totalWorkouts, 1)

        // 根据总运动时长和平均时长决定分配策略
        switch totalDuration {
        case 0..<30:
            // 少于30分钟：分配到2-3天，确保有一定的分散性
            return (3, [0.6, 1.0, 0.4, 0.0, 0.0, 0.0, 0.0])

        case 30..<60:
            // 30-60分钟：分配到2-3天
            return (3, [0.8, 1.0, 0.0, 0.7, 0.0, 0.0, 0.0])

        case 60..<120:
            // 1-2小时：分配到3-4天
            return (4, [0.8, 1.0, 0.0, 0.9, 0.7, 0.0, 0.0])

        case 120..<240:
            // 2-4小时：分配到4-5天
            return (5, [0.8, 1.0, 0.6, 0.9, 0.7, 1.2, 0.0])

        case 240..<360:
            // 4-6小时：分配到5-6天
            return (6, [0.8, 1.0, 0.6, 0.9, 0.7, 1.2, 0.5])

        default:
            // 超过6小时：分配到6天，留一天休息
            return (6, [1.0, 1.2, 0.8, 1.0, 0.9, 1.5, 0.0])
        }
    }

    private func loadCommunityPosts() async {
        // 模拟加载社区帖子数据
        try? await Task.sleep(nanoseconds: 300_000_000)

        // 创建模拟帖子数据
        communityPosts = []
    }

    private func loadCheckinHistory() async {
        do {
            // 获取当前月份的开始和结束日期
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now

            // 格式化日期为API需要的字符串格式
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startDateString = dateFormatter.string(from: startOfMonth)
            let endDateString = dateFormatter.string(from: endOfMonth)

            print("📅 加载打卡历史: \(startDateString) 到 \(endDateString)")

            // 调用API获取本月的打卡记录
            let response = try await checkinAPIService.getCheckinRecords(
                page: 1,
                limit: 100, // 获取足够多的记录
                startDate: startDateString,
                endDate: endDateString
            )

            print("📅 获取到 \(response.checkins.count) 条打卡记录")

            // 提取日期字符串
            var history: [String] = []
            for checkin in response.checkins {
                history.append(checkin.date)
                print("📅 打卡日期: \(checkin.date)")
            }

            checkinHistory = history

        } catch {
            print("❌ 加载打卡历史失败: \(error)")
            // 如果API调用失败，使用空数组
            checkinHistory = []
        }
    }

    private func setupMockData() {
        // 设置一些初始的模拟数据
        checkinStatistics = CheckinStatistics(
            totalDays: 45,
            consecutiveDays: 7,
            currentStreak: 7,
            longestStreak: 15,
            thisMonthDays: 15,
            lastCheckinDate: "2024-01-20",
            timeAnalysis: TimeAnalysis(
                morningCount: 20,
                afternoonCount: 15,
                eveningCount: 8,
                nightCount: 2,
                riskLevel: "low",
                suggestions: ["您的签到时间很规律，继续保持良好的作息习惯"]
            )
        )
    }
}

// MARK: - 数据模型



/// 应用使用数据模型
struct AppUsageData: Identifiable {
    let id = UUID()
    let appName: String
    let usageTime: Int // 分钟
    let icon: String

    var formattedTime: String {
        let hours = usageTime / 60
        let minutes = usageTime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var usageLevel: UsageLevel {
        switch usageTime {
        case 0..<30:
            return .low
        case 30..<120:
            return .medium
        default:
            return .high
        }
    }
}

enum UsageLevel {
    case low, medium, high

    var color: Color {
        switch self {
        case .low:
            return Color(red: 76/255, green: 175/255, blue: 80/255)
        case .medium:
            return Color(red: 255/255, green: 193/255, blue: 7/255)
        case .high:
            return Color(red: 255/255, green: 59/255, blue: 48/255)
        }
    }
}

// 注意：DeepSeekSleepAnalysis 和 SleepStageAnalysis 已在 DeepSeekSleepAnalysisModels.swift 中定义

// MARK: - 运动分析管理器
class WorkoutAnalyticsManager: ObservableObject {
    static let shared = WorkoutAnalyticsManager()

    @Published var isLoading = false
    @Published var weeklyWorkouts: [HomeWorkoutData] = []
    @Published var totalWorkoutTime: Int = 0
    @Published var averageHeartRate: Int = 0
    @Published var caloriesBurned: Int = 0
    
    private init() {
        setupMockData()
    }
    
    func refreshAnalyticsData() async {
        isLoading = true
        // 模拟数据刷新
        try? await Task.sleep(nanoseconds: 500_000_000)
        setupMockData()
        isLoading = false
    }
    
    private func setupMockData() {
        weeklyWorkouts = [
            HomeWorkoutData(date: "周一", duration: 45, type: "跑步", calories: 380, distance: 6.8),
            HomeWorkoutData(date: "周二", duration: 30, type: "力量训练", calories: 255, distance: 0),
            HomeWorkoutData(date: "周三", duration: 0, type: "休息", calories: 0, distance: 0),
            HomeWorkoutData(date: "周四", duration: 60, type: "瑜伽", calories: 180, distance: 0),
            HomeWorkoutData(date: "周五", duration: 40, type: "跑步", calories: 340, distance: 6.0),
            HomeWorkoutData(date: "周六", duration: 90, type: "户外骑行", calories: 540, distance: 18.5),
            HomeWorkoutData(date: "周日", duration: 0, type: "休息", calories: 0, distance: 0)
        ]
        
        totalWorkoutTime = weeklyWorkouts.reduce(0) { $0 + $1.duration }
        averageHeartRate = 145
        caloriesBurned = 1250
    }
}

/// 运动数据模型
struct HomeWorkoutData: Identifiable {
    let id = UUID()
    let date: String
    let duration: Int // 分钟
    let type: String
    let calories: Int // 卡路里
    let distance: Double // 公里

    var hasWorkout: Bool {
        return duration > 0
    }
}

/// 运动分析摘要模型
struct WorkoutAnalysisSummary {
    let totalDuration: Int // 总运动时间（分钟）
    let totalCalories: Int // 总卡路里
    let workoutDays: Int // 运动天数
    let averageDuration: Int // 平均运动时长
    let weeklyGoalProgress: Double // 周目标完成进度 (0.0-1.0)

    var formattedTotalDuration: String {
        let hours = totalDuration / 60
        let minutes = totalDuration % 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }

    var weeklyGoalPercentage: Int {
        return Int(weeklyGoalProgress * 100)
    }
}
