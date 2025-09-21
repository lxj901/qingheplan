import SwiftUI

struct SleepRecordsView: View {
    @StateObject private var sleepManager = SleepDataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: SleepStatisticsPeriod = .week
    @State private var showingRecordDetail = false
    @State private var selectedRecord: SleepRecord?
    @State private var scrollOffset: CGFloat = 0

    // 本地数据状态
    @State private var isLoadingData = false

    var body: some View {
        ZStack {
            // 统一的深色背景 - 与睡眠建议页面一致
            Color(red: 0.08, green: 0.12, blue: 0.25)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 自定义导航栏
                customNavigationBar

                // 主要内容区域
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 20, pinnedViews: []) {
                        // 统计概览卡片
                        sleepStatisticsCard
                            .id("statistics-card")

                        // 时间段选择器
                        periodSelector
                            .id("period-selector")

                        // 睡眠记录列表
                        sleepRecordsList
                            .id("records-list")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 120)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("SleepRecordsView appeared")
            loadLocalData()
        }
        .fullScreenCover(item: $selectedRecord) { record in
            SleepDetailView(record: record)
        }
    }

    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("返回")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
            }

            Spacer()

            Text("睡眠记录")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 15)
    }

    // MARK: - 统计概览卡片
    private var sleepStatisticsCard: some View {
        VStack(spacing: 18) {
            // 标题和时间段选择
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("睡眠统计")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text(selectedPeriod.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
            }

            if let localStatistics = sleepManager.sleepStatistics {
                // 后备：使用本地数据
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        modernStatisticCard(
                            icon: "bed.double.fill",
                            title: "平均睡眠",
                            value: formatDuration(localStatistics.averageSleepDuration),
                            color: Color(red: 0.4, green: 0.6, blue: 1.0)
                        )

                        modernStatisticCard(
                            icon: "heart.fill",
                            title: "平均质量",
                            value: localStatistics.averageSleepQuality > 0 ? "\(Int(localStatistics.averageSleepQuality))分" : "暂无",
                            color: Color(red: 0.8, green: 0.4, blue: 0.9)
                        )
                    }

                    HStack(spacing: 12) {
                        modernStatisticCard(
                            icon: "percent",
                            title: "睡眠效率",
                            value: localStatistics.averageSleepEfficiency > 0 ? "\(Int(localStatistics.averageSleepEfficiency * 100))%" : "暂无",
                            color: Color(red: 0.2, green: 0.8, blue: 0.6)
                        )

                        modernStatisticCard(
                            icon: "clock.arrow.circlepath",
                            title: "规律性",
                            value: localStatistics.consistencyScore > 0 ? String(format: "%.2f分", localStatistics.consistencyScore) : "暂无",
                            color: Color(red: 1.0, green: 0.6, blue: 0.4)
                        )
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.6))

                    VStack(spacing: 8) {
                        Text("暂无统计数据")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("开始记录睡眠获得详细分析")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func modernStatisticCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    // MARK: - 时间段选择器
    private var periodSelector: some View {
        VStack(spacing: 14) {
            // 标题
            HStack {
                Text("时间范围")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text(getCurrentPeriodDescription())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            // 分段控制器风格的按钮组
            periodButtonGroup
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.20, blue: 0.35),
                            Color(red: 0.15, green: 0.23, blue: 0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var periodButtonGroup: some View {
        HStack(spacing: 4) {
            ForEach(SleepStatisticsPeriod.allCases, id: \.self) { period in
                periodButton(for: period)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.1))
        )
    }
    
    private func periodButton(for period: SleepStatisticsPeriod) -> some View {
        Button(action: {
            if selectedPeriod != period {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedPeriod = period
                    // 重新加载对应时间段的本地数据
                    loadLocalDataForPeriod()
                }
            }
        }) {
            Text(period.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selectedPeriod == period ? Color.white.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func getCurrentPeriodDescription() -> String {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "MM月dd日"
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
            return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
        case .month:
            formatter.dateFormat = "yyyy年MM月"
            return formatter.string(from: now)
        case .year:
            formatter.dateFormat = "yyyy年"
            return formatter.string(from: now)
        }
    }

    // MARK: - 睡眠记录列表
    private var sleepRecordsList: some View {
        VStack(spacing: 16) {
            // 标题和记录数量
            HStack {
                Text("睡眠记录")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // 使用现有的sleepRecords数据进行筛选
                let allRecords = sleepManager.sleepRecords
                let filteredRecords = allRecords // 临时使用所有记录
                Text("\(filteredRecords.count) 条记录")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            // 记录列表
            LazyVStack(spacing: 12) {
                // 当前睡眠会话信息 (如果存在且正在追踪)
                if let currentSession = sleepManager.currentSession, sleepManager.isTrackingSleep {
                    currentSleepSessionCard(currentSession)
                        .padding(.bottom, 8)
                }
                
                // 使用现有的sleepRecords数据进行筛选
                let allRecords = sleepManager.sleepRecords
                let filteredRecords = allRecords // 临时使用所有记录

                if filteredRecords.isEmpty && sleepManager.currentSession == nil {
                    // 空状态显示
                    modernEmptyStateView
                        .padding(.top, 40)
                } else {
                    ForEach(filteredRecords) { record in
                        modernSleepRecordCard(record)
                            .onTapGesture {
                                selectedRecord = record
                                showingRecordDetail = true
                            }
                    }
                }
            }
        }
    }

    // MARK: - 当前睡眠会话卡片
    private func currentSleepSessionCard(_ session: LocalSleepSession) -> some View {
        VStack(spacing: 16) {
            // 顶部标题区域
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // 正在进行的指示器
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(sleepManager.isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: sleepManager.isRecording)
                        
                        Text("当前睡眠会话")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("开始时间：\(formatTime(session.startTime))")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currentSessionDuration(from: session.startTime))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("已记录")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // 会话状态指标
            HStack(spacing: 12) {
                sessionStatusItem(
                    icon: "waveform",
                    label: "录音状态",
                    value: sleepManager.isRecording ? "录制中" : "已暂停",
                    color: sleepManager.isRecording ? Color.green : Color.orange
                )
                
                sessionStatusItem(
                    icon: "folder.fill",
                    label: "音频文件",
                    value: "\(sleepManager.recordedAudioFiles.count)个",
                    color: Color.blue
                )
                
                if let endTime = session.endTime {
                    sessionStatusItem(
                        icon: "checkmark.circle.fill",
                        label: "已完成",
                        value: formatTime(endTime),
                        color: Color.green
                    )
                } else {
                    sessionStatusItem(
                        icon: "clock.fill",
                        label: "进行中",
                        value: "追踪中",
                        color: Color.yellow
                    )
                }
            }
            
            // 会话备注 (如果有)
            if let notes = session.notes, !notes.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.15),
                            Color.blue.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func sessionStatusItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func currentSessionDuration(from startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - 现代化空状态视图
    private var modernEmptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 8) {
                Text("暂无\(selectedPeriod.displayName)睡眠记录")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("开始记录您的睡眠，获得更好的睡眠分析")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 50)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    private func modernSleepRecordCard(_ record: SleepRecord) -> some View {
        let bedTimeText = formatDate(record.bedTime)
        let timeRangeText = "\(record.formattedBedTime) - \(record.formattedWakeTime)"
        let qualityScore = record.sleepQualityScore
        
        return VStack(spacing: 16) {
            recordHeader(bedTimeText: bedTimeText, timeRangeText: timeRangeText, qualityScore: qualityScore)
            recordMetrics(record: record)
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.2, blue: 0.35),
                    Color(red: 0.1, green: 0.15, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }
    
    private func recordHeader(bedTimeText: String, timeRangeText: String, qualityScore: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bedTimeText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(timeRangeText)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(qualityScore)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("质量评分")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
    
    private func recordMetrics(record: SleepRecord) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                modernMetricItem(
                    icon: "bed.double.fill",
                    label: "睡眠时长",
                    value: record.formattedSleepDuration,
                    color: Color(red: 0.4, green: 0.6, blue: 1.0)
                )

                modernMetricItem(
                    icon: "percent",
                    label: "睡眠效率",
                    value: "\(Int(record.sleepEfficiency * 100))%",
                    color: Color(red: 0.2, green: 0.8, blue: 0.6)
                )

                if !record.sleepStages.isEmpty {
                    modernMetricItem(
                        icon: "brain.head.profile",
                        label: "深睡眠",
                        value: formatDeepSleepPercentage(record),
                        color: Color(red: 0.6, green: 0.4, blue: 0.9)
                    )
                }
            }

            // 睡眠阶段可视化（保持原有功能）
            if !record.sleepStages.isEmpty {
                sleepStagesVisualization(record.sleepStages)
            }

            // 音频播放功能（需要修复getAudioFiles方法）
            if let sessionId = record.sleepId {
                let audioFiles = sleepManager.recordedAudioFiles.filter { $0.sessionId == String(sessionId) }
                if !audioFiles.isEmpty {
                    audioFilesSection(audioFiles)
                }
            }
        }
    }
    
    private func modernMetricItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
        )
    }

    
    private func sleepStagesVisualization(_ stages: [SleepStage]) -> some View {
        HStack(spacing: 2) {
            ForEach(stages.indices, id: \.self) { index in
                let stage = stages[index]
                Rectangle()
                    .fill(stage.stage.color)
                    .frame(height: 8)
                    .frame(maxWidth: .infinity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    // MARK: - 辅助方法
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    private func formatDeepSleepPercentage(_ record: SleepRecord) -> String {
        let deepSleepDuration = record.sleepStages
            .filter { $0.stage == .deep }
            .reduce(0) { $0 + $1.duration }
        
        // 安全计算百分比，处理除零和无效值
        guard record.totalSleepDuration > 0 && record.totalSleepDuration.isFinite else {
            return "0%"
        }
        
        let percentage = (deepSleepDuration / record.totalSleepDuration) * 100
        
        // 安全转换为Int，处理无穷大和NaN值
        if percentage.isFinite && percentage >= 0 {
            return "\(Int(percentage))%"
        } else {
            return "0%"
        }
    }
    
    // MARK: - 音频文件部分
    
    private func audioFilesSection(_ audioFiles: [LocalAudioFile]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.6, green: 0.8, blue: 1.0))
                
                Text("睡眠音频")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("\(audioFiles.count) 个文件")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(audioFiles) { audioFile in
                        compactAudioPlayerCard(audioFile)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.top, 8)
    }
    
    private func compactAudioPlayerCard(_ audioFile: LocalAudioFile) -> some View {
        VStack(spacing: 6) {
            // 音频状态指示器
            HStack(spacing: 4) {
                Circle()
                    .fill(audioFile.statusColor)
                    .frame(width: 6, height: 6)
                
                Text(audioFile.formattedDuration)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // 音频播放器
            Text("音频播放器")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 120)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.6, green: 0.8, blue: 1.0).opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - 本地数据加载方法
    private func loadLocalData() {
        print("🔄 开始加载睡眠记录页面本地数据...")
        Task {
            // 使用现有的loadSleepHistory方法，现在会自动生成统计数据
            await sleepManager.loadSleepHistory(forceRefresh: true)
        }
        print("✅ 睡眠记录页面本地数据加载完成")
    }

    private func loadLocalDataForPeriod() {
        print("🔄 开始重新计算\(selectedPeriod.displayName)的统计数据...")
        Task {
            // 重新生成指定时间段的统计数据
            await sleepManager.generateSleepStatistics(for: selectedPeriod)
        }
        print("✅ \(selectedPeriod.displayName)统计数据计算完成")
    }
}

// MARK: - 扩展
extension LocalAudioFile {
    var statusColor: Color {
        if isUploaded {
            return .green
        } else {
            return .orange
        }
    }
}

// 注意：SleepStageType.color 已在 SleepModels.swift 中定义

#Preview {
    SleepRecordsView()
}