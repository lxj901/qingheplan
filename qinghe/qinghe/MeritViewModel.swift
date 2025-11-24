import SwiftUI
import Foundation

/// 功过格 ViewModel - 管理功过记录的数据和 API 调用
@MainActor
class MeritViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 月度数据
    @Published var monthlyRecords: [MeritRecord] = []
    @Published var dailyScores: [Date: DailyScore] = [:]
    @Published var dayRecords: [Date: [MeritRecord]] = [:]
    
    // 当前选中的月份
    @Published var currentMonth: Date = Date()
    
    private let meritService = MeritService.shared
    
    struct DailyScore {
        var merit: Int
        var demerit: Int
    }
    
    // MARK: - API 调用
    
    /// 加载指定月份的功过记录
    func loadMonthlyRecords(for date: Date) async {
        isLoading = true
        errorMessage = nil
        currentMonth = date
        
        do {
            let calendar = Calendar.current
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            
            // 获取月度记录列表
            let response = try await meritService.getRecords(
                page: 1,
                limit: 100,
                startDate: firstDayOfMonth(date),
                endDate: lastDayOfMonth(date)
            )
            
            monthlyRecords = response.data?.records ?? []
            processRecords(monthlyRecords)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ 加载月度记录失败: \(error)")
        }
    }
    
    /// 创建功过记录
    func createRecord(
        type: String,
        category: String,
        title: String,
        points: Int,
        date: Date,
        notes: String? = nil
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let dateString = formatDateString(date)
            let request = CreateMeritRequest(
                type: type,
                title: title,
                points: points,
                category: category,
                note: notes,
                recordedAt: dateString
            )
            let record = try await meritService.createRecord(request)
            
            // 重新加载当前月份的数据
            await loadMonthlyRecords(for: currentMonth)
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ 创建记录失败: \(error)")
            return false
        }
    }
    
    /// 更新功过记录
    func updateRecord(
        id: Int,
        category: String? = nil,
        title: String? = nil,
        points: Int? = nil,
        date: Date? = nil,
        notes: String? = nil
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let dateString = date != nil ? formatDateString(date!) : nil
            let request = UpdateMeritRequest(
                title: title,
                points: points,
                note: notes,
                recordedAt: dateString
            )
            let record = try await meritService.updateRecord(id: id, request)
            
            // 重新加载当前月份的数据
            await loadMonthlyRecords(for: currentMonth)
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ 更新记录失败: \(error)")
            return false
        }
    }
    
    /// 删除功过记录
    func deleteRecord(id: Int) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await meritService.deleteRecord(id: id)
            
            // 重新加载当前月份的数据
            await loadMonthlyRecords(for: currentMonth)
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ 删除记录失败: \(error)")
            return false
        }
    }
    
    // MARK: - 数据处理
    
    /// 处理记录列表，生成每日汇总
    private func processRecords(_ records: [MeritRecord]) {
        dailyScores.removeAll()
        dayRecords.removeAll()
        
        let calendar = Calendar.current
        
        // 按日期分组
        let groupedRecords = Dictionary(grouping: records) { record -> Date in
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            if let date = dateFormatter.date(from: record.recordedAt) {
                return calendar.startOfDay(for: date)
            }
            return calendar.startOfDay(for: Date())
        }
        
        // 计算每日的功过分数
        for (date, dayRecordsList) in groupedRecords {
            // 分别过滤功和过的记录
            let meritRecords = dayRecordsList.filter { $0.type == "merit" }
            let demeritRecords = dayRecordsList.filter { $0.type == "demerit" }
            
            // 计算总分
            let meritPoints = meritRecords.reduce(0) { sum, record in
                sum + record.points
            }
            
            let demeritPoints = demeritRecords.reduce(0) { sum, record in
                sum + record.points
            }
            
            dailyScores[date] = DailyScore(merit: meritPoints, demerit: demeritPoints)
            dayRecords[date] = dayRecordsList
        }
    }
    
    /// 获取指定日期的记录
    func getRecordsForDate(_ date: Date) -> [MeritRecord] {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        return dayRecords[normalizedDate] ?? []
    }
    
    /// 获取指定日期的分数
    func getScoreForDate(_ date: Date) -> DailyScore? {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        return dailyScores[normalizedDate]
    }
    
    // MARK: - 日期工具方法
    
    private func firstDayOfMonth(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        if let firstDay = calendar.date(from: components) {
            return formatDateString(firstDay)
        }
        return formatDateString(date)
    }
    
    private func lastDayOfMonth(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        if let firstDay = calendar.date(from: components),
           let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay) {
            return formatDateString(lastDay)
        }
        return formatDateString(date)
    }
    
    private func formatDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}

