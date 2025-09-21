import SwiftUI

struct RecordHistoryView: View {
    @StateObject private var viewModel = RecordHistoryViewModel()
    @State private var selectedSegment = 0
    @State private var selectedEmotion: EmotionNew?
    @State private var selectedTemptation: TemptationNew?
    @State private var selectedPlan: PlanNew?
    @Environment(\.dismiss) private var dismiss
    
    private let segments = ["全部记录", "情绪记录", "诱惑记录", "计划记录"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计卡片区域
                statisticsCardsView
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                
                // 分段控制器
                Picker("记录类型", selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Text(segments[index])
                            .font(.system(size: 15, weight: .medium))
                            .tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // 记录列表
                recordListView
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("导出数据") {
                            viewModel.exportRecords()
                        }
                        
                        Button("统计分析") {
                            viewModel.showStatistics()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            })
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
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
                await viewModel.refreshData()
            }
        }
    }
    
    // MARK: - 统计卡片区域
    private var statisticsCardsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 总记录数
                StatisticsCard(
                    title: "总记录数",
                    value: "\(viewModel.totalRecordsCount)",
                    icon: "doc.text.fill",
                    color: Color(hex: "6366F1"),
                    subtitle: "累计记录"
                )
                
                // 情绪记录数
                StatisticsCard(
                    title: "情绪记录",
                    value: "\(viewModel.emotionRecordsCount)",
                    icon: "heart.fill",
                    color: Color(hex: "EC4899"),
                    subtitle: "情绪记录总数"
                )
                
                // 诱惑记录数
                StatisticsCard(
                    title: "诱惑记录",
                    value: "\(viewModel.temptationRecordsCount)",
                    icon: "shield.fill",
                    color: Color(hex: "F59E0B"),
                    subtitle: "诱惑记录总数"
                )
                
                // 计划记录数
                StatisticsCard(
                    title: "计划记录",
                    value: "\(viewModel.planRecordsCount)",
                    icon: "checkmark.circle.fill",
                    color: Color(hex: "10B981"),
                    subtitle: "计划记录总数"
                )
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 记录列表视图
    @ViewBuilder
    private var recordListView: some View {
        if viewModel.isLoading {
            loadingView
        } else if filteredRecords.isEmpty {
            emptyView
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredRecords, id: \.id) { record in
                        recordRowView(record)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("加载中...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: getEmptyStateIcon())
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(getEmptyStateTitle())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(getEmptyStateSubtitle())
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - 记录行视图
    private func recordRowView(_ record: RecordHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 类型图标和标题
                HStack(spacing: 10) {
                    Image(systemName: record.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(record.color)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(record.typeLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(record.color)
                    }
                }
                
                Spacer()
                
                // 时间
                Text(formatRelativeTime(record.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            // 内容摘要
            if !record.summary.isEmpty {
                Text(record.summary)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal, 34) // 对齐图标位置
            }
            
            // 底部信息条
            HStack {
                // 强度或状态信息
                if let intensity = record.intensity {
                    Label("强度 \(intensity)", systemImage: "gauge")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                if let status = record.status {
                    Label(status, systemImage: getStatusIcon(status))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(getStatusColor(status))
                }
                
                Spacer()
                
                // 详情箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 34) // 对齐图标位置
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .onTapGesture {
            handleRecordTap(record)
        }
    }
    
    // MARK: - 处理记录点击
    private func handleRecordTap(_ record: RecordHistoryItem) {
        Task {
            switch record.type {
            case .emotion:
                // 根据记录ID获取完整的情绪数据
                do {
                    if let emotionId = Int(record.id) {
                        let emotion = try await EmotionService.shared.getEmotion(id: emotionId)
                        selectedEmotion = emotion
                    }
                } catch {
                    print("❌ 获取情绪详情失败: \(error.localizedDescription)")
                }
                
            case .temptation:
                // 根据记录ID获取完整的诱惑数据
                do {
                    if let temptationId = Int(record.id) {
                        let temptation = try await TemptationService.shared.getTemptation(id: temptationId)
                        selectedTemptation = temptation
                    }
                } catch {
                    print("❌ 获取诱惑详情失败: \(error.localizedDescription)")
                }
                
            case .plan:
                // 根据记录ID获取完整的计划数据
                do {
                    if let planId = Int(record.id) {
                        let plan = try await PlanService.shared.getPlan(id: planId)
                        selectedPlan = plan
                    }
                } catch {
                    print("❌ 获取计划详情失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 计算属性
    private var filteredRecords: [RecordHistoryItem] {
        switch selectedSegment {
        case 0: return viewModel.allRecords
        case 1: return viewModel.emotionRecords
        case 2: return viewModel.temptationRecords
        case 3: return viewModel.planRecords
        default: return viewModel.allRecords
        }
    }
    
    // MARK: - 辅助方法
    private func getEmptyStateIcon() -> String {
        switch selectedSegment {
        case 1: return "heart"
        case 2: return "shield"
        case 3: return "checkmark.circle"
        default: return "doc.text"
        }
    }
    
    private func getEmptyStateTitle() -> String {
        switch selectedSegment {
        case 1: return "暂无情绪记录"
        case 2: return "暂无诱惑记录"
        case 3: return "暂无计划记录"
        default: return "暂无记录"
        }
    }
    
    private func getEmptyStateSubtitle() -> String {
        switch selectedSegment {
        case 1: return "开始记录你的情绪变化，了解自己的情感模式"
        case 2: return "记录面对诱惑时的处理方式，提升自控力"
        case 3: return "创建和管理你的计划，实现目标"
        default: return "开始记录你的生活点滴，见证成长足迹"
        }
    }
    
    private func getStatusIcon(_ status: String) -> String {
        switch status {
        case "已完成": return "checkmark.circle.fill"
        case "进行中": return "clock.fill"
        case "已抵抗": return "checkmark.shield.fill"
        case "未抵抗": return "xmark.shield.fill"
        default: return "circle.fill"
        }
    }
    
    private func getStatusColor(_ status: String) -> Color {
        switch status {
        case "已完成", "已抵抗": return .green
        case "进行中": return .orange
        case "未抵抗": return .red
        default: return .secondary
        }
    }
    
    private func formatRelativeTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MM月dd日 HH:mm"
        return outputFormatter.string(from: date)
    }
}

// MARK: - 统计卡片组件
struct StatisticsCard: View {
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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
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

// MARK: - ViewModel
@MainActor
class RecordHistoryViewModel: ObservableObject {
    @Published var allRecords: [RecordHistoryItem] = []
    @Published var emotionRecords: [RecordHistoryItem] = []
    @Published var temptationRecords: [RecordHistoryItem] = []
    @Published var planRecords: [RecordHistoryItem] = []
    @Published var isLoading = false
    
    // 服务实例
    private let emotionService = EmotionService.shared
    private let temptationService = TemptationService.shared
    private let planService = PlanService.shared
    
    // 统计数据
    var totalRecordsCount: Int {
        emotionRecordsCount + temptationRecordsCount + planRecordsCount
    }
    
    var emotionRecordsCount: Int {
        emotionRecords.count
    }
    
    var temptationRecordsCount: Int {
        temptationRecords.count
    }
    
    var planRecordsCount: Int {
        planRecords.count
    }
    
    func loadData() async {
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadEmotionRecords() }
            group.addTask { await self.loadTemptationRecords() }
            group.addTask { await self.loadPlanRecords() }
        }
        
        // 合并所有记录并按时间排序
        combineAndSortRecords()
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadData()
    }
    
    private func loadEmotionRecords() async {
        do {
            let emotions = try await emotionService.getEmotions(page: 1, limit: 50)
            
            emotionRecords = (emotions.data?.emotions ?? []).map { emotion in
                RecordHistoryItem(
                    id: "\(emotion.id)",
                    type: .emotion,
                    title: emotion.type,
                    summary: emotion.note ?? "无备注",
                    createdAt: emotion.createdAt,
                    icon: "heart.fill",
                    color: .pink,
                    typeLabel: "情绪记录",
                    intensity: emotion.intensity,
                    status: nil
                )
            }
            
            print("✅ 成功加载情绪记录: \(emotionRecords.count) 条")
        } catch {
            print("❌ 加载情绪记录失败: \(error.localizedDescription)")
            emotionRecords = []
        }
    }
    
    private func loadTemptationRecords() async {
        do {
            let temptations = try await temptationService.getTemptations(page: 1, limit: 50)
            
            temptationRecords = temptations.temptations.map { temptation in
                RecordHistoryItem(
                    id: "\(temptation.id)",
                    type: .temptation,
                    title: temptation.type,
                    summary: temptation.note ?? "无备注",
                    createdAt: temptation.createdAt,
                    icon: "shield.fill",
                    color: .orange,
                    typeLabel: "诱惑记录",
                    intensity: temptation.intensity,
                    status: temptation.resisted ? "已抵抗" : "未抵抗"
                )
            }
            
            print("✅ 成功加载诱惑记录: \(temptationRecords.count) 条")
        } catch {
            print("❌ 加载诱惑记录失败: \(error.localizedDescription)")
            temptationRecords = []
        }
    }
    
    private func loadPlanRecords() async {
        do {
            let plans = try await planService.getPlans(page: 1, limit: 50)
            
            planRecords = plans.plans.map { plan in
                let formatter = ISO8601DateFormatter()
                return RecordHistoryItem(
                    id: "\(plan.id)",
                    type: .plan,
                    title: plan.title,
                    summary: plan.description,
                    createdAt: formatter.string(from: plan.startDate),
                    icon: "checkmark.circle.fill",
                    color: .green,
                    typeLabel: "计划记录",
                    intensity: nil,
                    status: "进行中" // PlanNew没有status属性，使用默认值
                )
            }
            
            print("✅ 成功加载计划记录: \(planRecords.count) 条")
        } catch {
            print("❌ 加载计划记录失败: \(error.localizedDescription)")
            planRecords = []
        }
    }
    
    private func combineAndSortRecords() {
        allRecords = (emotionRecords + temptationRecords + planRecords)
            .sorted { record1, record2 in
                let formatter = ISO8601DateFormatter()
                let date1 = formatter.date(from: record1.createdAt) ?? Date.distantPast
                let date2 = formatter.date(from: record2.createdAt) ?? Date.distantPast
                return date1 > date2
            }
    }
    
    private func formatPlanStatus(_ status: String) -> String {
        switch status {
        case "completed": return "已完成"
        case "in_progress": return "进行中"
        case "pending": return "待开始"
        case "expired": return "已过期"
        case "cancelled": return "已取消"
        default: return status
        }
    }
    
    func exportRecords() {
        // TODO: 实现导出功能
        print("导出记录功能")
    }
    
    func showStatistics() {
        // TODO: 实现统计分析功能
        print("统计分析功能")
    }
}

// MARK: - 数据模型
struct RecordHistoryItem: Identifiable {
    let id: String
    let type: RecordType
    let title: String
    let summary: String
    let createdAt: String
    let icon: String
    let color: Color
    let typeLabel: String
    let intensity: Int?
    let status: String?
    
    enum RecordType {
        case emotion
        case temptation
        case plan
    }
}

// MARK: - Helper Functions
extension RecordHistoryView {
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 预览
struct RecordHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        RecordHistoryView()
    }
}