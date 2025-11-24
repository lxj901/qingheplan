import Foundation
import SwiftUI

// MARK: - 趋势方向枚举
enum TrendDirection {
    case up
    case down
    case stable
}

// MARK: - 坚持详情ViewModel
@MainActor
class PersistenceDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var totalDays: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var monthlyDays: Int = 0
    @Published var weeklyDays: Int = 0
    @Published var totalPersistenceDays: Int = 0
    @Published var averageCheckinTime: String? = nil
    @Published var trendDirection: TrendDirection = .stable
    @Published var persistenceRate: Double = 0.0
    @Published var monthlyPersistenceRate: Double = 0.0

    // 新增的打卡历史相关属性
    @Published var checkinRecords: [CheckinHistoryRecord] = []
    @Published var monthlyCheckinCount: Int = 0
    @Published var consecutiveDays: Int = 0
    @Published var totalConsecutiveDays: Int = 0 // 新增：总连续天数
    @Published var insightCount: Int = 0
    
    // MARK: - Private Properties
    private let checkinAPIService = CheckinAPIService.shared
    
    // MARK: - Initialization
    init() {
        // 初始化默认数据
        setupDefaultData()
    }
    
    // MARK: - Public Methods
    
    /// 加载数据
    func loadData() async {
        isLoading = true
        
        do {
            // 获取统计数据
            let statistics = try await checkinAPIService.getCheckinStatistics()
            updateStatistics(statistics)
            
            // 计算趋势
            calculateTrend()
            
        } catch {
            print("加载坚持详情数据失败: \(error)")
            // 保持初始化的空数据状态，不使用模拟数据
        }
        
        isLoading = false
    }
    
    /// 刷新数据
    func refreshData() async {
        await loadData()
    }

    /// 加载指定月份的打卡历史
    func loadCheckinHistory(for date: Date) async {
        isLoading = true

        do {
            // 首先获取统计数据，包含历史最长连续天数
            let statistics = try await checkinAPIService.getCheckinStatistics()

            // 获取指定月份的打卡记录
            let calendar = Calendar.current
            let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
            let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date

            // 格式化日期为API需要的字符串格式
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startDateString = dateFormatter.string(from: startOfMonth)
            let endDateString = dateFormatter.string(from: endOfMonth)

            // 调用API获取打卡记录
            let response = try await checkinAPIService.getCheckinRecords(
                page: 1,
                limit: 100,
                startDate: startDateString,
                endDate: endDateString
            )

            // 转换API数据为UI模型
            let recordDateFormatter = DateFormatter()
            recordDateFormatter.dateFormat = "yyyy-MM-dd"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"

            let apiRecords = response.checkins.map { apiRecord in
                let recordDate = recordDateFormatter.date(from: apiRecord.date) ?? Date()
                let recordTime = timeFormatter.date(from: apiRecord.time) ?? Date()

                return CheckinHistoryRecord(
                    checkinId: apiRecord.id, // 保存真正的打卡记录ID
                    date: recordDate,
                    time: recordTime,
                    mood: apiRecord.mood,
                    note: apiRecord.note,
                    isConsecutive: false, // 先设为false，后面会计算
                    isInterrupted: false // 先设为false，后面会计算
                )
            }

            // 生成完整的月份日期列表，包括没有打卡的日期
            let completeRecords = generateCompleteMonthRecords(
                for: startOfMonth,
                endOfMonth: endOfMonth,
                checkinRecords: apiRecords
            )

            // 计算连续打卡和中断标记
            checkinRecords = calculateConsecutiveFlags(for: completeRecords)

            // 更新统计数据
            monthlyCheckinCount = checkinRecords.count
            consecutiveDays = calculateMonthlyConsecutiveDays(from: checkinRecords, for: startOfMonth) // 基于月份数据计算连续天数
            totalConsecutiveDays = statistics.longestStreak // 使用后端提供的历史最长连续天数
            insightCount = checkinRecords.filter { $0.note != nil && !$0.note!.isEmpty }.count

        } catch {
            print("加载打卡历史失败: \(error)")
            // 清空数据，不使用模拟数据
            checkinRecords = []
            monthlyCheckinCount = 0
            consecutiveDays = 0
            totalConsecutiveDays = 0
            insightCount = 0
        }

        isLoading = false
    }


    
    /// 获取周趋势图高度
    func getWeeklyTrendHeight(for index: Int) -> CGFloat {
        // 基于实际数据计算高度，如果没有数据则返回0
        if weeklyDays == 0 {
            return 0
        }

        // 根据一周中的打卡情况计算高度
        let maxHeight: CGFloat = 60
        let baseHeight: CGFloat = 20

        // 简单的计算逻辑：基于周打卡天数的比例
        let ratio = CGFloat(weeklyDays) / 7.0
        return baseHeight + (maxHeight - baseHeight) * ratio
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultData() {
        // 初始化为0，等待从API加载真实数据
        totalDays = 0
        currentStreak = 0
        longestStreak = 0
        monthlyDays = 0
        weeklyDays = 0
        totalPersistenceDays = 0
        averageCheckinTime = nil
        trendDirection = .stable
        persistenceRate = 0.0
        monthlyPersistenceRate = 0.0
    }
    
    private func updateStatistics(_ statistics: CheckinStatistics) {
        totalDays = statistics.totalDays
        currentStreak = statistics.consecutiveDays
        monthlyDays = statistics.thisMonthDays
        totalPersistenceDays = statistics.totalDays
        
        // 计算周数据（需要从API获取或计算）
        weeklyDays = min(7, statistics.consecutiveDays)
        
        // 计算坚持率
        let calendar = Calendar.current
        let now = Date()
        let currentDay = calendar.component(.day, from: now)
        monthlyPersistenceRate = currentDay > 0 ? (Double(monthlyDays) / Double(currentDay)) * 100 : 0.0
        persistenceRate = monthlyPersistenceRate
        
        // 分析平均打卡时间
        analyzeAverageCheckinTime(statistics)
    }
    
    private func analyzeAverageCheckinTime(_ statistics: CheckinStatistics) {
        // 从时间分析中获取最常见的打卡时间
        let timeAnalysis = statistics.timeAnalysis
        
        // 找出最常见的时间段
        let maxCount = max(timeAnalysis.morningCount, timeAnalysis.afternoonCount, timeAnalysis.eveningCount, timeAnalysis.nightCount)
        
        if maxCount == timeAnalysis.morningCount {
            averageCheckinTime = "08:30"
        } else if maxCount == timeAnalysis.afternoonCount {
            averageCheckinTime = "14:30"
        } else if maxCount == timeAnalysis.eveningCount {
            averageCheckinTime = "20:30"
        } else {
            averageCheckinTime = "22:30"
        }
    }
    
    private func calculateTrend() {
        // 基于当前连续天数和月度坚持率计算趋势
        if currentStreak >= 7 && monthlyPersistenceRate > 70 {
            trendDirection = .up
        } else if currentStreak <= 2 || monthlyPersistenceRate < 40 {
            trendDirection = .down
        } else {
            trendDirection = .stable
        }
    }

    /// 生成完整的月份记录，包括没有打卡的日期（只到今天为止）
    private func generateCompleteMonthRecords(
        for startOfMonth: Date,
        endOfMonth: Date,
        checkinRecords: [CheckinHistoryRecord]
    ) -> [CheckinHistoryRecord] {
        let calendar = Calendar.current
        var completeRecords: [CheckinHistoryRecord] = []
        var currentDate = startOfMonth
        let today = Date()

        // 计算实际的结束日期：取月末和今天的较早者
        // 如果是当前月份，只显示到今天；如果是以往月份，显示整个月
        let actualEndDate: Date
        if calendar.isDate(startOfMonth, equalTo: today, toGranularity: .month) {
            // 当前月份：只显示到今天（包含今天）
            actualEndDate = min(endOfMonth, calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today)) ?? today)
        } else {
            // 以往月份：显示整个月
            actualEndDate = endOfMonth
        }

        // 创建打卡记录的日期映射，便于快速查找
        let checkinMap = Dictionary(uniqueKeysWithValues: checkinRecords.map { record in
            let dateKey = calendar.startOfDay(for: record.date)
            return (dateKey, record)
        })

        // 遍历从月初到今天的每一天
        while currentDate < actualEndDate {
            let dayStart = calendar.startOfDay(for: currentDate)

            if let checkinRecord = checkinMap[dayStart] {
                // 有打卡记录的日期
                completeRecords.append(checkinRecord)
            } else {
                // 没有打卡记录的日期，创建一个空记录
                let emptyRecord = CheckinHistoryRecord(
                    checkinId: nil, // 没有打卡记录ID
                    date: currentDate,
                    time: nil, // 没有打卡时间
                    mood: nil, // 没有心情
                    note: nil, // 没有备注
                    isConsecutive: false,
                    isInterrupted: false
                )
                completeRecords.append(emptyRecord)
            }

            // 移动到下一天
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // 按日期倒序排列（最新的在前）
        return completeRecords.sorted { $0.date > $1.date }
    }

    /// 计算连续打卡标记
    private func calculateConsecutiveFlags(for records: [CheckinHistoryRecord]) -> [CheckinHistoryRecord] {
        guard !records.isEmpty else { return records }

        // 按日期排序（最新的在前）
        let sortedRecords = records.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        let today = Date()

        var updatedRecords: [CheckinHistoryRecord] = []
        var consecutiveCount = 0
        var previousDate: Date?

        // 只处理有打卡记录的日期来计算连续性
        let checkinRecords = sortedRecords.filter { $0.hasCheckin }
        var checkinIndex = 0

        for (_, record) in sortedRecords.enumerated() {
            var isConsecutive = false
            var isInterrupted = false

            // 只有有打卡记录的日期才参与连续性计算
            if record.hasCheckin {
                if checkinIndex == 0 {
                    // 第一条有打卡的记录（最新的）
                    let daysDifference = calendar.dateComponents([.day], from: record.date, to: today).day ?? 0

                    if daysDifference == 0 {
                        // 今天的记录，如果有后续连续记录则标记为连续
                        if checkinRecords.count > 1 {
                            let nextRecord = checkinRecords[1]
                            let nextDaysDiff = calendar.dateComponents([.day], from: nextRecord.date, to: record.date).day ?? 0
                            if nextDaysDiff == 1 {
                                consecutiveCount = 1
                                isConsecutive = true
                            }
                        }
                    } else if daysDifference == 1 {
                        // 昨天的记录，检查是否有连续
                        if checkinRecords.count > 1 {
                            let nextRecord = checkinRecords[1]
                            let nextDaysDiff = calendar.dateComponents([.day], from: nextRecord.date, to: record.date).day ?? 0
                            if nextDaysDiff == 1 {
                                consecutiveCount = 1
                                isConsecutive = true
                            }
                        }
                    }
                } else {
                    // 后续有打卡的记录
                    if let prevDate = previousDate {
                        let daysDifference = calendar.dateComponents([.day], from: record.date, to: prevDate).day ?? 0
                        if daysDifference == 1 {
                            consecutiveCount += 1
                            isConsecutive = true
                        } else if daysDifference > 1 {
                            // 检测到中断：如果间隔超过1天，且前面有连续记录
                            if consecutiveCount > 0 {
                                isInterrupted = true
                            }
                            consecutiveCount = 0
                            isConsecutive = false
                        }
                    }
                }
                previousDate = record.date
                checkinIndex += 1
            }

            let updatedRecord = CheckinHistoryRecord(
                checkinId: record.checkinId, // 保持原有的打卡记录ID
                date: record.date,
                time: record.time,
                mood: record.mood,
                note: record.note,
                isConsecutive: isConsecutive,
                isInterrupted: isInterrupted
            )

            updatedRecords.append(updatedRecord)
            previousDate = record.date
        }

        // 恢复原来的顺序
        return updatedRecords.sorted { $0.date > $1.date }
    }

    /// 计算月份内的连续打卡天数
    private func calculateMonthlyConsecutiveDays(from records: [CheckinHistoryRecord], for monthStart: Date) -> Int {
        guard !records.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = Date()

        // 只考虑有打卡记录的日期
        let checkinRecords = records.filter { $0.hasCheckin }.sorted { $0.date < $1.date }
        guard !checkinRecords.isEmpty else { return 0 }

        // 判断是当前月份还是以往月份
        let isCurrentMonth = calendar.isDate(monthStart, equalTo: today, toGranularity: .month)

        if isCurrentMonth {
            // 当前月份：计算从今天开始往前的连续天数
            return calculateCurrentMonthConsecutiveDays(from: checkinRecords)
        } else {
            // 以往月份：计算该月份内最长的连续天数
            return calculatePastMonthConsecutiveDays(from: checkinRecords)
        }
    }

    /// 计算当前月份的连续天数（从最近的打卡开始往前算）
    private func calculateCurrentMonthConsecutiveDays(from checkinRecords: [CheckinHistoryRecord]) -> Int {
        let calendar = Calendar.current

        // 按日期倒序排列（最新的在前）
        let sortedRecords = checkinRecords.sorted { $0.date > $1.date }
        guard !sortedRecords.isEmpty else { return 0 }

        var consecutiveCount = 1 // 从最近的一次打卡开始计算
        var currentDate = sortedRecords[0].date

        // 从第二条记录开始检查连续性
        for i in 1..<sortedRecords.count {
            let record = sortedRecords[i]
            let expectedDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!

            if calendar.isDate(record.date, inSameDayAs: expectedDate) {
                consecutiveCount += 1
                currentDate = record.date
            } else {
                // 不连续，停止计算
                break
            }
        }

        return consecutiveCount
    }

    /// 计算以往月份的最长连续天数
    private func calculatePastMonthConsecutiveDays(from checkinRecords: [CheckinHistoryRecord]) -> Int {
        guard !checkinRecords.isEmpty else { return 0 }

        let calendar = Calendar.current
        var maxConsecutive = 0
        var currentConsecutive = 1

        // 按日期正序排列
        let sortedRecords = checkinRecords.sorted { $0.date < $1.date }

        for i in 1..<sortedRecords.count {
            let previousRecord = sortedRecords[i-1]
            let currentRecord = sortedRecords[i]

            let daysDifference = calendar.dateComponents([.day], from: previousRecord.date, to: currentRecord.date).day ?? 0

            if daysDifference == 1 {
                // 连续的一天
                currentConsecutive += 1
            } else {
                // 不连续，更新最大值并重置当前连续数
                maxConsecutive = max(maxConsecutive, currentConsecutive)
                currentConsecutive = 1
            }
        }

        // 最后更新一次最大值
        maxConsecutive = max(maxConsecutive, currentConsecutive)

        return maxConsecutive
    }

    /// 计算历史上最长的连续天数
    private func calculateTotalConsecutiveDays(from records: [CheckinHistoryRecord]) -> Int {
        guard !records.isEmpty else { return 0 }

        let calendar = Calendar.current

        // 按日期排序（最旧的在前）
        let sortedRecords = records.sorted { $0.date < $1.date }

        var maxConsecutive = 1
        var currentConsecutive = 1
        var previousDate = sortedRecords.first!.date

        // 从第二条记录开始检查
        for i in 1..<sortedRecords.count {
            let record = sortedRecords[i]
            let daysDifference = calendar.dateComponents([.day], from: previousDate, to: record.date).day ?? 0

            if daysDifference == 1 {
                // 连续的一天
                currentConsecutive += 1
                maxConsecutive = max(maxConsecutive, currentConsecutive)
            } else {
                // 不连续，重新开始计算
                currentConsecutive = 1
            }

            previousDate = record.date
        }

        return maxConsecutive
    }
}