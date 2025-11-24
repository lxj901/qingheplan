import SwiftUI
import Foundation

@MainActor
class RecordCenterViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var emotionRecords: [EmotionNew] = []
    @Published var temptationRecords: [TemptationNew] = []
    @Published var checkinStats: ActualCheckinStatsData?
    
    @Published var todayRecordsCount: Int = 0
    @Published var consecutiveDays: Int = 0
    @Published var totalRecordsCount: Int = 0
    @Published var hasCheckedInToday: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var isCreating: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    @Published var hasMoreEmotions: Bool = false
    @Published var hasMoreTemptations: Bool = false
    
    // MARK: - Private Properties
    private var currentEmotionPage = 1
    private var currentTemptationPage = 1
    private let pageSize = 10
    
    // MARK: - Initialization
    init() {
        Task {
            await loadData()
        }
    }
    
    // MARK: - Public Methods
    
    func loadData() async {
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadEmotionRecords() }
            group.addTask { await self.loadTemptationRecords() }
            group.addTask { await self.loadCheckinStats() }
            group.addTask { await self.loadTodayStats() }
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        currentEmotionPage = 1
        currentTemptationPage = 1
        emotionRecords.removeAll()
        temptationRecords.removeAll()
        
        await loadData()
    }
    
    func loadMoreEmotions() async {
        guard hasMoreEmotions && !isLoading else { return }
        
        currentEmotionPage += 1
        await loadEmotionRecords(append: true)
    }
    
    func loadMoreTemptations() async {
        guard hasMoreTemptations && !isLoading else { return }
        
        currentTemptationPage += 1
        await loadTemptationRecords(append: true)
    }
    
    func performCheckin() async {
        guard !hasCheckedInToday else {
            UserFeedbackManager.shared.showInfo("今日已打卡")
            return
        }

        let taskId = "checkin"
        UserFeedbackManager.shared.startLoading("打卡中...", taskId: taskId)
        isCreating = true

        do {
            let location = CheckinLocation(
                latitude: 0.0, // 实际应用中应获取真实位置
                longitude: 0.0,
                address: "当前位置"
            )

            let response = try await CheckinService.shared.checkin(
                note: "今日打卡",
                location: location.address,
                latitude: location.latitude,
                longitude: location.longitude,
                mood: "良好",
                challenges: ["继续坚持"]
            )

            if response.success {
                hasCheckedInToday = true
                consecutiveDays += 1
                await loadCheckinStats()
                await loadTodayStats()
                UserFeedbackManager.shared.showSuccess("打卡成功！")
            } else {
                UserFeedbackManager.shared.showError(response.message ?? "打卡失败")
            }
        } catch {
            NetworkErrorHandler.shared.handleError(error)
        }

        UserFeedbackManager.shared.stopLoading(taskId: taskId)
        isCreating = false
    }
    
    // MARK: - Private Methods
    
    private func loadEmotionRecords(append: Bool = false) async {
        do {
            let data = try await EmotionService.shared.getEmotions(
                page: currentEmotionPage,
                limit: pageSize
            )

            if append {
                emotionRecords.append(contentsOf: data.emotions)
            } else {
                emotionRecords = data.emotions
            }

            hasMoreEmotions = data.pagination.hasNextPage
        } catch {
            showErrorMessage("加载情绪记录失败: \(error.localizedDescription)")
        }
    }
    
    private func loadTemptationRecords(append: Bool = false) async {
        do {
            let data = try await TemptationService.shared.getTemptations(
                page: currentTemptationPage,
                limit: pageSize
            )

            if append {
                temptationRecords.append(contentsOf: data.temptations)
            } else {
                temptationRecords = data.temptations
            }

            hasMoreTemptations = data.pagination.hasNextPage
        } catch {
            showErrorMessage("加载诱惑记录失败: \(error.localizedDescription)")
        }
    }
    
    private func loadCheckinStats() async {
        do {
            let response = try await CheckinService.shared.getStatistics()

            if let data = response.data {
                checkinStats = ActualCheckinStatsData(
                    totalCheckins: data.totalDays,
                    currentStreak: data.currentStreak,
                    longestStreak: data.longestStreak,
                    averageTime: "09:00",
                    weeklyData: [],
                    heatmapData: [],
                    totalDays: data.totalDays,
                    consecutiveDays: data.currentStreak,
                    thisMonthDays: data.thisMonthDays,
                    monthlyDays: 0,
                    timeAnalysis: ActualTimeAnalysisData(
                        averageCheckinTime: "09:00",
                        mostActiveHour: 9,
                        checkinPattern: [],
                        consistencyScore: 0.8,
                        morningCount: 5,
                        afternoonCount: 3,
                        eveningCount: 2,
                        nightCount: 1
                    )
                )
                consecutiveDays = data.currentStreak
            }
        } catch {
            showErrorMessage("加载打卡统计失败: \(error.localizedDescription)")
        }
    }
    
    private func loadTodayStats() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.checkTodayCheckin() }
            group.addTask { await self.loadTodayRecordsCount() }
            group.addTask { await self.loadTotalRecordsCount() }
        }
    }
    
    private func checkTodayCheckin() async {
        do {
            let response = try await CheckinService.shared.getTodayStatus()
            hasCheckedInToday = response.data != nil
        } catch {
            hasCheckedInToday = false
        }
    }
    
    private func loadTodayRecordsCount() async {
        let today = DateFormatter.iso8601.string(from: Date())
        var count = 0
        
        // 计算今日情绪记录数
        let todayEmotions = emotionRecords.filter { emotion in
            emotion.recordedAt.starts(with: String(today.prefix(10)))
        }
        count += todayEmotions.count
        
        // 计算今日诱惑记录数
        let todayTemptations = temptationRecords.filter { temptation in
            temptation.recordedAt.starts(with: String(today.prefix(10)))
        }
        count += todayTemptations.count
        
        // 如果今日已打卡，+1
        if hasCheckedInToday {
            count += 1
        }
        
        todayRecordsCount = count
    }
    
    private func loadTotalRecordsCount() async {
        totalRecordsCount = emotionRecords.count + temptationRecords.count + (checkinStats?.totalDays ?? 0)
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Supporting Data Models

// 这些类型已在NetworkModels.swift中定义

// MARK: - 这些数据模型已在NetworkModels.swift中定义

// MARK: - Extensions

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? self
    }
}