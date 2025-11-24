import SwiftUI
import AVFoundation

/// 睡眠详情页面
/// 展示完整的睡眠记录详情，包括音频播放、分析结果等
struct SleepDetailView: View {
    let record: SleepRecord
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sleepManager = SleepDataManager.shared
    @State private var selectedTab = 0
    @State private var audioFiles: [LocalAudioFile] = []
    @State private var isLoadingAudio = false
    @State private var errorMessage: String?

    // 本地音频分析状态
    @State private var localAnalysisResult: SleepAudioAnalysisResult?
    @State private var isLoadingLocalAnalysis = false
    @State private var localAnalysisError: String?

    // 服务器健康报告分析结果（替代 DeepSeek）
    @State private var healthReportData: HealthReportData?
    @State private var isLoadingHealthReport = false
    @State private var healthReportError: String?

    // 单次会话分析结果
    @State private var sessionAnalysisData: SingleSessionQualityData?
    @State private var isLoadingSessionAnalysis = false
    @State private var sessionAnalysisError: String?

    // 睡眠 AI 分析报告（新增）
    @State private var aiReportData: SleepAIReportData?
    @State private var isLoadingAIReport = false
    @State private var aiReportError: String?

    // 本地音频片段状态
    @State private var localAudioSegments: [SleepLocalAudioSegment] = []
    @State private var isLoadingAudioSegments = false

    // 音频播放器管理
    @State private var audioPlayer: AVAudioPlayer?
    @State private var nowPlayingSegmentId: UUID?
    @State private var isPlayingSegment: Bool = false
    @State private var audioPlayerDelegate: SleepDetailAudioPlayerDelegate?

    private let tabs = ["概览", "音频", "分析"]

    // 统一的会话ID获取逻辑
    private var derivedSessionId: String {
        if let originalSessionId = record.originalSessionId {
            return originalSessionId
        } else if let sleepId = record.sleepId {
            return String(sleepId) 
        } else {
            return record.id.uuidString
        }
    }

    var body: some View {
        ZStack {
            // 统一的深色背景 - 与睡眠记录页面一致
            Color(red: 0.08, green: 0.12, blue: 0.25)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 自定义导航栏
                customNavigationBar

                // 统一标签栏
                unifiedTabBar
                    .padding(.top, 20)

                // 内容区域
                TabView(selection: $selectedTab) {
                    // 概览页面
                    enhancedOverviewTab
                        .tag(0)

                    // 音频页面
                    enhancedAudioTab
                        .tag(1)

                    // 分析页面
                    enhancedAnalysisTab
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await loadLocalSleepData()
                await loadLocalAnalysisResult()
                await loadLocalAudioSegments()
                await loadHealthReportAnalysis()  // 健康报告分析
                await loadSessionAnalysis()  // 单次会话分析
                await loadAIReport()  // 睡眠 AI 分析报告（新增）

                // 确保事件数据被加载
                print("🔍 睡眠详情页面加载事件数据，会话 ID: \(derivedSessionId)")
                sleepManager.loadEventSegmentsFromDisk(for: derivedSessionId)
                print("🔍 事件数据加载完成，当前事件数量: \(sleepManager.eventSegments.count)")
            }
        }
    }

    // MARK: - 自定义导航栏 - 与睡眠记录页面一致
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

            Text("睡眠详情")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            // 占位视图，保持标题居中
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                Text("返回")
                    .font(.system(size: 16, weight: .medium))
            }
            .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 15)
    }

    // MARK: - 统一标签栏 - 与睡眠记录页面风格一致
    private var unifiedTabBar: some View {
        VStack(spacing: 14) {
            // 标题
            HStack {
                Text("详情视图")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text(formatDate(record.bedTime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            // 胶囊形状的标签选择器
            HStack(spacing: 4) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        if selectedTab != index {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedTab = index
                            }
                        }
                    }) {
                        Text(tabs[index])
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedTab == index ? Color.white.opacity(0.15) : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.1))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - 增强概览页面
    private var enhancedOverviewTab: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 24) {
                // 睡眠时间卡片
                sleepTimeCard
                    .padding(.top, 20)

                // 睡眠质量卡片
                sleepQualityCard

                // 睡眠阶段图表
                if !record.sleepStages.isEmpty {
                    sleepStagesChart
                }

                // 基本指标网格
                basicMetricsGrid
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
    }

    // MARK: - 音频页面 - 简化版本，直接展示事件列表
    private var enhancedAudioTab: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 20) {
                // 事件统计摘要 - 放在最上面
                eventSummaryCard
                    .padding(.top, 20)

                // 直接展示事件列表，不需要点击进入
                eventSegmentsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .onAppear {
            print("🔍 睡眠详情页音频tab加载事件数据，会话 ID: \(derivedSessionId)")
            
            // 🔥 首先清空之前的事件数据，避免显示其他会话的数据
            sleepManager.eventSegments = []
            
            sleepManager.loadEventSegmentsFromDisk(for: derivedSessionId)
            print("🔍 事件数据加载完成，当前事件数量: \(sleepManager.eventSegments.count)")
        }
    }

    // MARK: - 事件统计摘要（用于分析/建议）
    private var eventSummaryCard: some View {
        let segments = sleepManager.eventSegments
        let snore = segments.filter { $0.type.lowercased() == "snoring" }
        let talk = segments.filter { $0.type.lowercased() == "talking" }
        let totalDuration = segments.reduce(0) { $0 + $1.duration }
        let longest = segments.map { $0.duration }.max() ?? 0
        let formatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            return df
        }()
        let timeSpan: String = {
            let dates = segments.compactMap { $0.eventDate }.sorted()
            guard let first = dates.first, let last = dates.last else { return "--" }
            return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
        }()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.circle")
                    .foregroundColor(.cyan)
                Text("事件摘要")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                
                if segments.isEmpty {
                    // 🔥 空状态显示
                    VStack(spacing: 2) {
                        Text("🎉")
                            .font(.system(size: 16))
                        Text("优秀")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green.opacity(0.8))
                    }
                } else {
                    Text("共 \(segments.count) 个事件")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            if segments.isEmpty {
                // 🔥 空状态的积极反馈
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        Label("打鼾 0 次", systemImage: "zzz")
                            .foregroundColor(.white.opacity(0.85))
                        Label("说话 0 次", systemImage: "zzz")
                            .foregroundColor(.white.opacity(0.85))
                    }
                    HStack(spacing: 16) {
                        Label("累计时长 0秒", systemImage: "timer")
                            .foregroundColor(.white.opacity(0.85))
                        Label("睡眠质量优秀", systemImage: "checkmark.circle")
                            .foregroundColor(.green.opacity(0.85))
                    }
                    HStack {
                        Label("安静睡眠，身心放松", systemImage: "moon.stars")
                            .foregroundColor(.blue.opacity(0.85))
                            .font(.system(size: 13, weight: .medium))
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        Label("打鼾 \(snore.count) 次", systemImage: "zzz")
                            .foregroundColor(.white.opacity(0.85))
                        Label("梦话 \(talk.count) 次", systemImage: "mic")
                            .foregroundColor(.white.opacity(0.85))
                    }
                    HStack(spacing: 16) {
                        Label("累计时长 \(formatInterval(totalDuration))", systemImage: "timer")
                            .foregroundColor(.white.opacity(0.85))
                        Label("最长单次 \(formatInterval(longest))", systemImage: "hourglass")
                            .foregroundColor(.white.opacity(0.85))
                    }
                    HStack(spacing: 16) {
                        Label("发生时间段 \(timeSpan)", systemImage: "clock")
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(segments.isEmpty ? Color.green.opacity(0.3) : Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func formatInterval(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        if m > 0 { return String(format: "%d分%02d秒", m, s) }
        return String(format: "%d秒", s)
    }


    // MARK: - 事件列表展示区域 - 直接展示，不需要点击进入
    private var eventSegmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform.path")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.cyan)
                Text("音频事件列表")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(sleepManager.eventSegments.count)个事件")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.cyan)
            }

            if sleepManager.eventSegments.isEmpty {
                // 🔥 优化：更详细的空状态描述
                VStack(spacing: 16) {
                    Image(systemName: "waveform.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(spacing: 8) {
                        Text("暂无音频事件")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(spacing: 4) {
                            Text("此睡眠记录中未检测到打鼾或说话等音频事件")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                            
                            Text("🎉 这通常表示您的睡眠质量很好")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // 事件列表
                LazyVStack(spacing: 12) {
                    ForEach(sleepManager.eventSegments, id: \.id) { segment in
                        eventSegmentCard(segment)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }


    private func eventSegmentCard(_ segment: SleepLocalAudioSegment) -> some View {
        HStack(spacing: 12) {
            // 事件类型图标和颜色
            ZStack {
                Circle()
                    .fill(eventTypeColor(for: segment.type).opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: eventTypeIcon(for: segment.type))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(eventTypeColor(for: segment.type))
            }

            // 事件信息
            VStack(alignment: .leading, spacing: 6) {
                // 中文事件名称（使用模型内置映射，避免硬编码）
                Text(segment.typeName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                // 置信度显示
                HStack(spacing: 8) {
                    Text("置信度")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    
                    ProgressView(value: min(max(segment.confidence, 0), 1))
                        .progressViewStyle(LinearProgressViewStyle(tint: eventTypeColor(for: segment.type)))
                        .frame(height: 4)
                    
                    Text("\(Int(segment.confidence * 100))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(eventTypeColor(for: segment.type))
                }

                // 详细信息
                HStack(spacing: 12) {
                    Text(String(format: "%.1fs", segment.duration))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                    if let date = segment.eventDate {
                        Text(eventDateFormatter.string(from: date))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }

            Spacer()

            // 播放按钮
            Button(action: {
                togglePlayEventSegment(segment)
            }) {
                Image(systemName: (nowPlayingSegmentId == segment.id && isPlayingSegment) ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.cyan)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(eventTypeColor(for: segment.type).opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - 事件类型辅助方法
    // 统一改为使用模型层的 segment.typeName，避免此处硬编码。该方法保留作为兼容占位，并直接返回原始类型字符串。
    private func eventDisplayName(_ type: String) -> String {
        return type
    }

    private func eventTypeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "snoring": return .orange
        case "talking": return .purple
        case "breathing": return .blue
        case "movement": return .green
        case "silence": return .gray
        default: return .gray
        }
    }

    private func eventTypeIcon(for type: String) -> String {
        switch type.lowercased() {
        case "snoring": return "zzz"
        case "talking": return "zzz"
        case "breathing": return "zzz"
        case "movement": return "zzz"
        case "silence": return "zzz"
        default: return "zzz"
        }
    }

    private var eventDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    // MARK: - 播放事件音频
    private func togglePlayEventSegment(_ segment: SleepLocalAudioSegment) {
        print("🎵 切换播放事件音频: \(eventDisplayName(segment.type))")
        
        // 如果点击的是当前正在播放的片段，则暂停/恢复
        if nowPlayingSegmentId == segment.id {
            if isPlayingSegment {
                audioPlayer?.pause()
                isPlayingSegment = false
                print("⏸️ 暂停播放")
            } else {
                audioPlayer?.play()
                isPlayingSegment = true
                print("▶️ 恢复播放")
            }
            return
        }
        
        // 如果点击的是不同的片段，则停止当前播放并播放新片段
        audioPlayer?.stop()
        isPlayingSegment = false

        guard let filePath = segment.actualFilePath else {
            print("❌ 事件音频文件路径为空")
            return
        }

        guard FileManager.default.fileExists(atPath: filePath) else {
            print("❌ 事件音频文件不存在: \(filePath)")
            return
        }

        do {
            // 配置音频会话
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)

            // 创建新的播放器
            let url = URL(fileURLWithPath: filePath)
            let player = try AVAudioPlayer(contentsOf: url)
            self.audioPlayer = player
            
            // 设置播放器代理来处理播放结束
            let delegate = SleepDetailAudioPlayerDelegate {
                DispatchQueue.main.async {
                    self.isPlayingSegment = false
                    self.nowPlayingSegmentId = nil
                    print("✅ 音频播放完成，按钮状态已重置")
                }
            }
            self.audioPlayerDelegate = delegate
            player.delegate = delegate
            
            player.prepareToPlay()
            nowPlayingSegmentId = segment.id
            
            let success = player.play()
            if success {
                isPlayingSegment = true
                print("✅ 开始播放: \(eventDisplayName(segment.type))")
            } else {
                print("❌ 播放失败")
            }
        } catch {
            print("❌ 播放事件音频失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 增强分析页面
    private var enhancedAnalysisTab: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 24) {
                // AI分析概览
                aiAnalysisOverview
                    .padding(.top, 20)

                // 详细分析结果
                detailedAnalysisResults
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
    }

    // MARK: - 增强建议页面
    private var enhancedRecommendationsTab: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 24) {
                // 睡眠建议
                sleepRecommendations
                    .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
    }

    // MARK: - 睡眠时间卡片 - 统一设计风格

    private var sleepTimeCard: some View {
        VStack(spacing: 16) {
            // 日期标题
            HStack {
                Text(formatDate(record.bedTime))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // 质量评分徽章
                Text("\(record.sleepQualityScore)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                    )
            }

            // 时间信息
            HStack(spacing: 20) {
                unifiedTimeInfoItem(
                    title: "就寝时间",
                    time: record.formattedBedTime,
                    icon: "bed.double.fill",
                    color: Color(red: 0.4, green: 0.6, blue: 1.0)
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))

                unifiedTimeInfoItem(
                    title: "起床时间",
                    time: record.formattedWakeTime,
                    icon: "sun.max.fill",
                    color: Color(red: 1.0, green: 0.6, blue: 0.4)
                )
            }

            // 总睡眠时长
            HStack {
                Text("总睡眠时长")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text(record.formattedSleepDuration)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
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

    private func unifiedTimeInfoItem(title: String, time: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text(time)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 睡眠质量卡片 - 统一设计风格

    private var sleepQualityCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("睡眠质量")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text(getQualityLevel(from: record.sleepQualityScore))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(qualityColor.opacity(0.3))
                    )
            }

            // 质量评分圆环
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(record.sleepQualityScore) / 100)
                    .stroke(
                        LinearGradient(
                            colors: [Color(red: 0.4, green: 0.6, blue: 1.0), qualityColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(record.sleepQualityScore)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("分")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Text("睡眠效率: \(Int(record.sleepEfficiency * 100))%")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
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
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var qualityColor: Color {
        switch record.sleepQualityScore {
        case 90...100:
            return .green
        case 80..<90:
            return .blue
        case 70..<80:
            return .orange
        case 60..<70:
            return .red
        default:
            return .gray
        }
    }

    // MARK: - 睡眠阶段图表 - 统一设计风格

    private var sleepStagesChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("睡眠阶段")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("时长分布")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            // 睡眠阶段时间轴
            sleepStagesTimeline

            // 睡眠阶段统计
            sleepStagesStats
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

    private var sleepStagesTimeline: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(record.sleepStages) { stage in
                    Rectangle()
                        .fill(stage.stage.color)
                        .frame(width: geometry.size.width * CGFloat(stage.duration / record.totalSleepDuration))
                }
            }
        }
        .frame(height: 20)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var sleepStagesStats: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(SleepStageType.allCases, id: \.self) { stageType in
                let duration = record.sleepStages
                    .filter { $0.stage == stageType }
                    .reduce(0) { $0 + $1.duration }

                if duration > 0 {
                    stageStatItem(
                        stage: stageType,
                        duration: duration,
                        percentage: record.totalSleepDuration > 0 && record.totalSleepDuration.isFinite ?
                                   duration / record.totalSleepDuration : 0.0
                    )
                }
            }
        }
    }

    private func stageStatItem(stage: SleepStageType, duration: TimeInterval, percentage: Double) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stage.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(stage.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Text("\(Int(duration) / 60)分钟 (\(Int(percentage * 100))%)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()
        }
    }

    // MARK: - 基本指标网格 - 统一设计风格

    private var basicMetricsGrid: some View {
        VStack(spacing: 16) {
            HStack {
                Text("睡眠指标")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("详细数据")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                unifiedMetricCard(
                    title: "总睡眠时长",
                    value: record.formattedSleepDuration,
                    icon: "moon.zzz.fill",
                    color: Color(red: 0.6, green: 0.4, blue: 0.9)
                )

                unifiedMetricCard(
                    title: "夜间觉醒",
                    value: "\(record.sleepStages.filter { $0.stage == .awake }.count)次",
                    icon: "eye.fill",
                    color: Color(red: 1.0, green: 0.6, blue: 0.4)
                )

                unifiedMetricCard(
                    title: "深睡比例",
                    value: "\(Int(deepSleepPercentage * 100))%",
                    icon: "bed.double.fill",
                    color: Color(red: 0.4, green: 0.6, blue: 1.0)
                )

                unifiedMetricCard(
                    title: "REM比例",
                    value: "\(Int(remSleepPercentage * 100))%",
                    icon: "brain.head.profile",
                    color: Color(red: 0.8, green: 0.4, blue: 0.9)
                )
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

    private func unifiedMetricCard(title: String, value: String, icon: String, color: Color) -> some View {
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

    // MARK: - 计算属性

    private var deepSleepPercentage: Double {
        let deepSleepDuration = record.sleepStages
            .filter { $0.stage == .deep }
            .reduce(0) { $0 + $1.duration }

        guard record.totalSleepDuration > 0 && record.totalSleepDuration.isFinite else {
            return 0.0
        }

        let percentage = deepSleepDuration / record.totalSleepDuration

        if percentage.isFinite && percentage >= 0 {
            return percentage
        } else {
            return 0.0
        }
    }

    private var remSleepPercentage: Double {
        let remSleepDuration = record.sleepStages
            .filter { $0.stage == .rem }
            .reduce(0) { $0 + $1.duration }

        guard record.totalSleepDuration > 0 && record.totalSleepDuration.isFinite else {
            return 0.0
        }

        let percentage = remSleepDuration / record.totalSleepDuration

        if percentage.isFinite && percentage >= 0 {
            return percentage
        } else {
            return 0.0
        }
    }





    // MARK: - AI分析概览
    private var aiAnalysisOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏 - 纯文字格式
            analysisHeaderView

            // 内容区域
            analysisMainContent
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
        )
    }

    // 分析标题栏 - 纯文字格式
    private var analysisHeaderView: some View {
        HStack {
            Text("AI 睡眠分析报告")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            // 显示健康等级（纯文字）
            if let healthLevel = healthReportData?.healthOverview.healthLevel {
                Text(healthLevelText(healthLevel))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // 健康等级文本
    private func healthLevelText(_ level: String) -> String {
        switch level.lowercased() {
        case "excellent": return "健康等级：优秀"
        case "good": return "健康等级：良好"
        case "fair": return "健康等级：一般"
        case "poor": return "健康等级：较差"
        default: return "健康等级：\(level)"
        }
    }

    // 置信度徽章
    private func confidenceBadge(_ confidence: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            Text("\(Int(confidence))%")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.1))
        )
    }

    // 分析主要内容 - 优先显示 AI 报告，其次显示单次会话分析
    private var analysisMainContent: some View {
        Group {
            if let aiReport = aiReportData {
                // 优先显示 AI 报告
                aiReportAnalysisView(aiReport)
            } else if let sessionData = sessionAnalysisData {
                // 其次显示单次会话分析
                sessionAnalysisView(sessionData)
            } else {
                analysisEmptyStateView
            }
        }
    }

    // 空状态视图
    private var analysisEmptyStateView: some View {
        VStack(spacing: 12) {
            if isLoadingAIReport {
                aiReportLoadingStateView
            } else if isLoadingSessionAnalysis {
                sessionLoadingStateView
            } else if let error = aiReportError {
                errorStateView(error)
            } else if let error = sessionAnalysisError {
                errorStateView(error)
            } else {
                defaultEmptyStateView
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20)
    }

    // AI 报告加载状态视图
    private var aiReportLoadingStateView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.white)

            Text("DeepSeek AI 正在分析...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))

            Text("生成睡眠 AI 分析报告")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    // 单次会话加载状态视图
    private var sessionLoadingStateView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.white)

            Text("AI 正在分析...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))

            Text("分析单次睡眠会话")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // 加载状态视图
    private var loadingStateView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.white)

            Text("DeepSeek AI 正在分析...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))

            let analysisEngine = EnhancedDeepSeekSleepAnalysisEngine.shared
            if !analysisEngine.currentAnalysisStage.isEmpty {
                Text(analysisEngine.currentAnalysisStage)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // 错误状态视图
    private func errorStateView(_ error: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)

            Text("分析失败")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))

            Text(error)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }

    // 默认空状态视图
    private var defaultEmptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.4))

            Text("暂无健康分析数据")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))

            Text("数据将在后台自动生成")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - AI 报告分析视图（新增）

    /// 显示 AI 报告分析的内容
    private func aiReportAnalysisView(_ aiReport: SleepAIReportData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 睡眠摘要卡片
            aiReportSummaryCard(aiReport.sleepSummary)

            // 睡眠阶段卡片
            if !aiReport.sleepStages.isEmpty {
                aiReportSleepStagesCard(aiReport.sleepStages)
            }

            // AI 洞察卡片
            if !aiReport.insights.isEmpty {
                aiReportInsightsCard(aiReport.insights)
            }

            // AI 分析详情卡片
            aiReportAnalysisDetailCard(aiReport.aiAnalysis)
        }
    }

    // AI 报告睡眠摘要卡片 - 纯文字报告格式
    private func aiReportSummaryCard(_ summary: AIReportSleepSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("1. 睡眠质量总评")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 6) {
                Text("• 睡眠评分 \(summary.overallQuality) 分\(qualityLevelDescription(summary.overallQuality))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))

                Text("• \(summary.sleepEfficiency) 的睡眠效率\(efficiencyDescriptionFromString(summary.sleepEfficiency))")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))

                Text("• \(formatMinutesToHours(summary.totalSleepTime))睡眠时长\(durationDescription(summary.totalSleepTime))")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))

                Text("• \(summary.sleepLatency)分钟清醒时间和\(summary.sleepLatency)次翻身显示\(latencyDescription(summary.sleepLatency))")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))
            }
        }
    }

    // 质量等级描述
    private func qualityLevelDescription(_ score: Int) -> String {
        switch score {
        case 90...100: return "属于优秀水平，接近优秀范围（90分以上）"
        case 85..<90: return "属于良好水平，接近优秀范围（85分以上）"
        case 75..<85: return "属于良好水平"
        case 60..<75: return "属于一般水平"
        default: return "需要改善"
        }
    }

    // 效率描述（从字符串转换）
    private func efficiencyDescriptionFromString(_ efficiencyStr: String) -> String {
        // 移除百分号并转换为整数
        let cleanedStr = efficiencyStr.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
        guard let efficiency = Int(cleanedStr) else {
            return ""
        }
        return efficiencyDescription(efficiency)
    }

    // 效率描述
    private func efficiencyDescription(_ efficiency: Int) -> String {
        if efficiency >= 85 {
            return "非常理想（医学推荐>85%）"
        } else if efficiency >= 75 {
            return "基本理想（医学推荐>85%）"
        } else {
            return "需要改善（医学推荐>85%）"
        }
    }

    // 时长描述
    private func durationDescription(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        if hours >= 7 {
            return "基本满足成人睡眠需求"
        } else if hours >= 6 {
            return "略低于成人睡眠需求"
        } else {
            return "明显低于成人睡眠需求"
        }
    }

    // 入睡时长描述
    private func latencyDescription(_ latency: Int) -> String {
        if latency <= 5 {
            return "夜间睡眠连续性良好"
        } else if latency <= 15 {
            return "存在轻度晚睡倾向"
        } else {
            return "存在明显晚睡倾向"
        }
    }

    // 格式化分钟为小时
    private func formatMinutesToHours(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        return String(format: "%.1f小时", hours)
    }

    // 质量评分颜色
    private func qualityColor(_ score: Int) -> Color {
        switch score {
        case 90...100:
            return Color(red: 0.2, green: 0.8, blue: 0.4)  // 绿色
        case 75..<90:
            return Color(red: 0.3, green: 0.6, blue: 1.0)  // 蓝色
        case 60..<75:
            return Color(red: 1.0, green: 0.6, blue: 0.2)  // 橙色
        default:
            return Color(red: 1.0, green: 0.3, blue: 0.3)  // 红色
        }
    }

    // AI 报告睡眠阶段卡片 - 纯文字报告格式
    private func aiReportSleepStagesCard(_ stages: [AIReportSleepStage]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("2. 睡眠时间规律性分析")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(stages.indices, id: \.self) { index in
                    aiReportStageRow(stages[index])
                }
            }
        }
    }

    // AI 报告阶段行 - 纯文字格式
    private func aiReportStageRow(_ stage: AIReportSleepStage) -> some View {
        let percentage = calculateStagePercentage(stage)
        let description = stageQualityDescription(stage.stage, quality: stage.quality, percentage: percentage)

        return Text("• \(stageName(stage.stage))（\(formatMinutesToHours(stage.duration))/\(percentage)%）\(description)")
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.75))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    // 计算阶段百分比
    private func calculateStagePercentage(_ stage: AIReportSleepStage) -> Int {
        // 这里需要根据总睡眠时间计算百分比
        // 暂时返回一个估算值
        return Int(Double(stage.duration) / 420.0 * 100) // 假设总时长为 420 分钟（7小时）
    }

    // 阶段质量描述
    private func stageQualityDescription(_ stageName: String, quality: Int, percentage: Int) -> String {
        switch stageName.lowercased() {
        case "deep":
            if percentage >= 20 && percentage <= 25 {
                return ""
            } else if percentage < 20 {
                return "占比略低于理想范围（20-25%）"
            } else {
                return "占比偏高（理想为 20-25%）"
            }
        case "light":
            if percentage >= 55 && percentage <= 65 {
                return ""
            } else if percentage < 55 {
                return "占比略低（理想为 55-65%）"
            } else {
                return "占比偏高（理想为 55-65%）"
            }
        case "rem":
            if percentage >= 20 && percentage <= 25 {
                return ""
            } else {
                return "占比需要关注"
            }
        default:
            return ""
        }
    }

    // 阶段图标
    private func stageIcon(_ stage: String) -> String {
        switch stage.lowercased() {
        case "light": return "moon.fill"
        case "deep": return "moon.zzz.fill"
        case "rem": return "brain.head.profile"
        default: return "moon"
        }
    }

    // 阶段颜色
    private func stageColor(_ stage: String) -> Color {
        switch stage.lowercased() {
        case "light": return .blue
        case "deep": return .purple
        case "rem": return .green
        default: return .gray
        }
    }

    // 阶段名称
    private func stageName(_ stage: String) -> String {
        switch stage.lowercased() {
        case "light": return "浅睡眠"
        case "deep": return "深睡眠"
        case "rem": return "REM 睡眠"
        default: return stage
        }
    }

    // MARK: - 单次会话分析视图
    
    /// 显示单次会话分析的内容
    private func sessionAnalysisView(_ sessionData: SingleSessionQualityData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 整体质量评分卡片
            sessionQualityScoreCard(sessionData.qualityAnalysis)

            // 关键指标卡片
            sessionKeyMetricsCard(sessionData.qualityAnalysis.keyMetrics)
        }
    }
    
    // 整体质量评分卡片
    private func sessionQualityScoreCard(_ analysis: SessionQualityAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("睡眠质量评估")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 16) {
                // 整体评分
                VStack(spacing: 4) {
                    Text("\(analysis.overallScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(
                            red: analysis.qualityColor.red,
                            green: analysis.qualityColor.green,
                            blue: analysis.qualityColor.blue
                        ))
                    Text("综合评分")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 60)
                
                // 质量等级
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: analysis.qualityIcon)
                            .font(.system(size: 16))
                            .foregroundColor(Color(
                                red: analysis.qualityColor.red,
                                green: analysis.qualityColor.green,
                                blue: analysis.qualityColor.blue
                            ))
                        Text(analysis.qualityLevelText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text("睡眠质量等级")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // 关键指标卡片
    private func sessionKeyMetricsCard(_ metrics: SessionKeyMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关键指标")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                sessionMetricItem(
                    icon: "gauge.medium",
                    label: "睡眠效率",
                    value: "\(metrics.sleepEfficiency)%",
                    color: .blue
                )
                
                sessionMetricItem(
                    icon: "moon.zzz.fill",
                    label: "深睡占比",
                    value: "\(metrics.deepSleepPercentage)%",
                    color: .purple
                )
                
                sessionMetricItem(
                    icon: "brain.head.profile",
                    label: "REM 占比",
                    value: "\(metrics.remSleepPercentage)%",
                    color: .green
                )
                
                sessionMetricItem(
                    icon: "clock.fill",
                    label: "入睡时长",
                    value: "\(metrics.sleepLatency)分钟",
                    color: .orange
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }

    // AI 报告洞察卡片
    private func aiReportInsightsCard(_ insights: [AIReportInsight]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI 健康洞察")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            ForEach(insights.indices, id: \.self) { index in
                aiReportInsightRow(insights[index])
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }

    // AI 报告洞察行
    private func aiReportInsightRow(_ insight: AIReportInsight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题和类型图标
            HStack(spacing: 8) {
                Image(systemName: insight.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: insight.iconColor.red, green: insight.iconColor.green, blue: insight.iconColor.blue))

                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()
            }

            // 描述
            Text(insight.description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            // 影响（如果有）
            if let impact = insight.impact, !impact.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange.opacity(0.8))

                    Text("影响：\(impact)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(2)
                }
                .padding(.top, 4)
            }

            // 证据（如果有）
            if let evidence = insight.evidence, !evidence.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("相关证据：")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    ForEach(evidence, id: \.self) { item in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))

                            Text(item)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }

    // AI 报告分析详情卡片 - 纯文字报告格式（睡眠模式和环境因素已移除）
    private func aiReportAnalysisDetailCard(_ analysis: AIAnalysisDetail) -> some View {
        EmptyView()
    }

    // 指标项
    private func sessionMetricItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - 健康报告分析视图
    
    /// 显示健康报告的分析内容
    private func healthReportAnalysisView(_ reportData: HealthReportData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 健康概览卡片
            healthOverviewCard(reportData.healthOverview)
            
            // 睡眠汇总分析
            if let sleepSummary = reportData.detailedAnalysis?.sleepSummary {
                sleepSummaryCard(sleepSummary)
            }
            
            // 体质分析
            if let constitution = reportData.detailedAnalysis?.constitution {
                detailedConstitutionCard(constitution)
            }
            
            // 健康建议
            if let recommendations = reportData.recommendations {
                recommendationsCard(recommendations)
            }
            
            // 健康趋势
            if let trends = reportData.healthTrends {
                healthTrendsCard(trends)
            }
            
            // 风险评估
            if let riskAssessments = reportData.riskAssessment, !riskAssessments.isEmpty {
                riskAssessmentCard(riskAssessments)
            }
        }
    }
    
    // 健康概览卡片
    private func healthOverviewCard(_ overview: HealthOverview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("健康概览")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 16) {
                // 综合评分
                VStack(spacing: 4) {
                    Text("\(overview.overallScore ?? 0)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                    Text("综合评分")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 50)
                
                // 其他信息
                VStack(alignment: .leading, spacing: 8) {
                    if let primaryConstitution = overview.primaryConstitution {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            Text("体质: \(primaryConstitution)")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    if let solarTerm = overview.currentSolarTerm {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text("节气: \(solarTerm)")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // 睡眠汇总卡片
    private func sleepSummaryCard(_ summary: SleepSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("睡眠汇总（最近3天）")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                summaryMetricItem(icon: "bed.double.fill", label: "总会话", value: "\(summary.totalSessions)次", color: .blue)
                
                summaryMetricItem(icon: "calendar", label: "本周会话", value: "\(summary.weeklySessions)次", color: .green)
                
                summaryMetricItem(icon: "clock.fill", label: "平均时长", value: String(format: "%.1f小时", summary.averageSleepDuration), color: .purple)
                
                summaryMetricItem(icon: "chart.line.uptrend.xyaxis", label: "近3天平均", value: "\(summary.average3DaySessions)次", color: .orange)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // 汇总指标项
    private func summaryMetricItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // 体质分析卡片（用于简单的 ConstitutionAnalysis）
    private func constitutionCard(_ constitution: ConstitutionAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("体质分析")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            if let hasAnalysis = constitution.hasAnalysis, hasAnalysis {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let primaryConstitution = constitution.primaryConstitution {
                            Text(primaryConstitution)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        
                        if let confidence = constitution.confidence {
                            Text("置信度: \(Int(confidence * 100))%")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    Spacer()
                }
            } else {
                Text("暂无体质分析数据")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // 详细体质分析卡片（用于健康报告中的 DetailedConstitutionAnalysis）
    private func detailedConstitutionCard(_ constitution: DetailedConstitutionAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("体质分析")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 8) {
                if let primaryConstitution = constitution.primaryConstitution {
                    HStack {
                        Text("主要体质:")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        Text(primaryConstitution)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                
                if let secondaryConstitution = constitution.secondaryConstitution {
                    HStack {
                        Text("次要体质:")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        Text(secondaryConstitution)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }
                
                HStack {
                    Text("置信度:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(Int(constitution.confidence * 100))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // 健康建议卡片
    private func recommendationsCard(_ recommendations: Recommendations) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("健康建议")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 8) {
                // 即时建议
                if let immediate = recommendations.immediate, !immediate.isEmpty {
                    ForEach(immediate, id: \.self) { advice in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text(advice)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                // 长期建议
                if let longTerm = recommendations.longTerm, !longTerm.isEmpty {
                    ForEach(longTerm, id: \.self) { advice in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            Text(advice)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // 健康趋势卡片
    private func healthTrendsCard(_ trends: HealthTrends) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("健康趋势")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 8) {
                trendItem(label: "睡眠", trend: trends.sleep)
                trendItem(label: "运动", trend: trends.exercise)
                trendItem(label: "整体", trend: trends.overall)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // 趋势项
    private func trendItem(label: String, trend: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            let (icon, color) = trendIndicator(trend)
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(trendText(trend))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(color)
            }
        }
    }
    
    private func trendIndicator(_ trend: String) -> (String, Color) {
        switch trend.lowercased() {
        case "improving": return ("arrow.up.circle.fill", .green)
        case "stable", "good": return ("minus.circle.fill", .blue)
        case "declining": return ("arrow.down.circle.fill", .red)
        default: return ("circle.fill", .gray)
        }
    }
    
    private func trendText(_ trend: String) -> String {
        switch trend.lowercased() {
        case "improving": return "改善中"
        case "stable": return "稳定"
        case "good": return "良好"
        case "declining": return "下降中"
        default: return trend
        }
    }
    
    // 风险评估卡片
    private func riskAssessmentCard(_ assessments: [RiskAssessment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("风险评估")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 8) {
                ForEach(assessments.indices, id: \.self) { index in
                    let assessment = assessments[index]
                    riskItem(assessment)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // 风险项
    private func riskItem(_ assessment: RiskAssessment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                let (icon, color) = riskLevelIndicator(assessment.level)
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(riskLevelText(assessment.level))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(assessment.factor)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(assessment.advice)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func riskLevelIndicator(_ level: String) -> (String, Color) {
        switch level.lowercased() {
        case "high": return ("exclamationmark.triangle.fill", .red)
        case "medium": return ("exclamationmark.circle.fill", .orange)
        case "low": return ("checkmark.circle.fill", .green)
        default: return ("circle.fill", .gray)
        }
    }
    
    private func riskLevelText(_ level: String) -> String {
        switch level.lowercased() {
        case "high": return "高风险"
        case "medium": return "中风险"
        case "low": return "低风险"
        default: return level
        }
    }

    private func insightCard(_ insight: String) -> some View {
        Text(insight)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.8, green: 0.4, blue: 0.9).opacity(0.3), lineWidth: 1)
                    )
            )
    }

    // 分析内容视图
    private func analysisContentView(_ analysis: DeepSeekSleepAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 睡眠质量评分卡片
            qualityScoreCard(analysis.qualityAssessment)
        }
    }

    // 质量评分卡片
    private func qualityScoreCard(_ qualityAssessment: DeepSeekSleepQualityAssessment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("睡眠质量评分")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))

                Text("\(Int(qualityAssessment.overallScore))分")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(qualityAssessment.qualityLevel.color)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(qualityAssessment.qualityLevel.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(qualityAssessment.qualityLevel.color)

                Text(qualityAssessment.qualityLevel.description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(qualityAssessment.qualityLevel.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(qualityAssessment.qualityLevel.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - 详细分析结果
    private var detailedAnalysisResults: some View {
        VStack(spacing: 20) {
            // 显示本地分析结果
            if let localResult = localAnalysisResult {
                ForEach(LocalSleepAudioAnalyzer.SoundType.allCases, id: \.self) { soundType in
                    if let stats = localResult.getStatistics(for: soundType), stats.count > 0 {
                        localSoundTypeDetailCard(soundType: soundType, stats: stats)
                    }
                }
            }
        }
    }

    // 睡眠阶段分析卡片
    private func sleepStageAnalysisCard(_ stageAnalysis: SleepStageAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)

                Text("睡眠阶段分析")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            // 睡眠效率
            HStack {
                Text("睡眠效率")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text("\(Int(stageAnalysis.sleepEfficiency * 100))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(stageAnalysis.sleepEfficiency >= 0.85 ? .green : stageAnalysis.sleepEfficiency >= 0.70 ? .orange : .red)
            }

            // 睡眠阶段百分比网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                stageMetricCard(
                    title: "浅睡眠",
                    percentage: stageAnalysis.lightSleepPercentage,
                    color: .cyan,
                    icon: "cloud.fill"
                )

                stageMetricCard(
                    title: "深睡眠",
                    percentage: stageAnalysis.deepSleepPercentage,
                    color: .blue,
                    icon: "moon.fill"
                )

                stageMetricCard(
                    title: "REM睡眠",
                    percentage: stageAnalysis.remSleepPercentage,
                    color: .purple,
                    icon: "brain.head.profile"
                )

                stageMetricCard(
                    title: "清醒时间",
                    percentage: (stageAnalysis.awakeDuration / 3600) * 100, // 转换为百分比
                    color: .orange,
                    icon: "eye.fill"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // 睡眠阶段指标卡片
    private func stageMetricCard(title: String, percentage: Double, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Spacer()

                Text("\(Int(percentage))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    // 睡眠质量详细指标卡片
    private func sleepQualityMetricsCard(_ qualityAssessment: DeepSeekSleepQualityAssessment) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)

                Text("质量指标详情")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                qualityMetricCard(
                    title: "效率评分",
                    score: qualityAssessment.efficiencyScore,
                    icon: "speedometer",
                    color: .blue
                )

                qualityMetricCard(
                    title: "结构评分",
                    score: qualityAssessment.structureScore,
                    icon: "building.columns.fill",
                    color: .purple
                )

                qualityMetricCard(
                    title: "连续性评分",
                    score: qualityAssessment.continuityScore,
                    icon: "link",
                    color: .cyan
                )

                qualityMetricCard(
                    title: "干扰评分",
                    score: qualityAssessment.disruptionScore,
                    icon: "shield.fill",
                    color: .orange
                )
            }

            // 改善潜力
            if qualityAssessment.improvementPotential > 0 {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)

                    Text("改善潜力: \(Int(qualityAssessment.improvementPotential))分")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // 质量指标卡片
    private func qualityMetricCard(title: String, score: Double, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Spacer()

                Text("\(Int(score))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    private func localSoundTypeDetailCard(soundType: LocalSleepAudioAnalyzer.SoundType, stats: SoundTypeStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color(hex: soundType.color))
                    .frame(width: 12, height: 12)

                Text(soundType.rawValue)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(stats.count)次")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("总时长")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))

                    Text(stats.formattedDuration)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("平均置信度")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))

                    Text("\(Int(stats.averageConfidence * 100))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: soundType.color))
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: soundType.color).opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - 睡眠建议 - 纯文字报告格式
    private var sleepRecommendations: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("个性化建议")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            // 优先显示 AI 报告建议
            if let aiReport = aiReportData,
               !aiReport.aiAnalysis.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(aiReport.aiAnalysis.recommendations.indices, id: \.self) { index in
                        aiRecommendationRow(aiReport.aiAnalysis.recommendations[index])
                    }
                }
            } else if let sessionData = sessionAnalysisData,
                      !sessionData.qualityAnalysis.recommendations.isEmpty {
                // 其次显示单次会话建议
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(sessionData.qualityAnalysis.recommendations.indices, id: \.self) { index in
                        sessionRecommendationRow(sessionData.qualityAnalysis.recommendations[index])
                    }
                }
            } else {
                // 显示基础建议（后备方案）
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(getSleepRecommendations(), id: \.self) { recommendation in
                        unifiedRecommendationItem(recommendation)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
        )
    }

    // AI 报告建议行 - 增强版，显示更多详细信息
    private func aiRecommendationRow(_ recommendation: AIAnalysisRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // 标题和优先级
            HStack(spacing: 8) {
                Image(systemName: recommendation.priorityIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: recommendation.priorityColor.red, green: recommendation.priorityColor.green, blue: recommendation.priorityColor.blue))

                Text(recommendation.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                // 类别标签
                Text(getCategoryText(recommendation.category))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                    )
            }

            // 描述
            if !recommendation.description.isEmpty {
                Text(recommendation.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 时间框架（如果有）
            if let timeframe = recommendation.timeframe, !timeframe.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.blue.opacity(0.8))

                    Text("时间框架：\(timeframe)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // 行动步骤（如果有）
            if let actionSteps = recommendation.actionSteps, !actionSteps.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("行动步骤：")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    ForEach(actionSteps.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 6) {
                            Text("\(index + 1).")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))

                            Text(actionSteps[index])
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            // 预期收益（如果有）
            if let expectedBenefit = recommendation.expectedBenefit, !expectedBenefit.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow.opacity(0.8))

                    Text("预期收益：\(expectedBenefit)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }

    // 获取类别文本
    private func getCategoryText(_ category: String) -> String {
        switch category {
        case "medical":
            return "医疗"
        case "behavioral":
            return "行为"
        case "environment":
            return "环境"
        case "lifestyle":
            return "生活方式"
        default:
            return category
        }
    }
    
    // 单次会话建议行 - 纯文字格式
    private func sessionRecommendationRow(_ recommendation: SessionRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("• \(recommendation.text)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            if !recommendation.description.isEmpty {
                Text(recommendation.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 12)
            }
        }
    }

    // 统一建议项 - 纯文字格式
    private func unifiedRecommendationItem(_ recommendation: String) -> some View {
        Text("• \(recommendation)")
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.75))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    // 优先级文本
    private func priorityText(_ priority: String) -> String {
        switch priority.lowercased() {
        case "high": return "高优先级"
        case "medium": return "中优先级"
        case "low": return "低优先级"
        default: return priority
        }
    }

    // DeepSeek 建议卡片
    private func deepSeekRecommendationCard(_ recommendation: DeepSeekSleepRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和优先级
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        // 优先级标签
                        Text(recommendation.priority.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(recommendation.priority.color.opacity(0.8))
                            )

                        // 类别标签
                        Text(recommendation.category.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }

                Spacer()

                // 预期影响
                VStack(alignment: .trailing, spacing: 2) {
                    Text("预期影响")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))

                    Text(recommendation.estimatedImpact.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(recommendation.estimatedImpact.color)
                }
            }

            // 建议描述
            Text(recommendation.description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(nil)

            // 底部信息
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))

                    Text(recommendation.timeToSeeResults)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))

                    Text("难度: \(recommendation.implementationDifficulty.displayName)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(recommendation.priority.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(recommendation.priority.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - 辅助方法

    private func getSleepRecommendations() -> [String] {
        var recommendations: [String] = []

        // 基于睡眠质量的建议
        if record.sleepQualityScore < 70 {
            recommendations.append("建议保持规律的作息时间，每天同一时间上床睡觉")
            recommendations.append("睡前1小时避免使用电子设备")
        }

        // 基于睡眠效率的建议
        if record.sleepEfficiency < 0.85 {
            recommendations.append("尝试在睡前进行放松活动，如冥想或深呼吸")
            recommendations.append("确保卧室环境舒适，温度适宜")
        }

        // 基于深睡比例的建议
        if deepSleepPercentage < 0.15 {
            recommendations.append("增加白天的运动量，但避免睡前3小时内剧烈运动")
            recommendations.append("考虑调整饮食，避免睡前摄入咖啡因")
        }

        if recommendations.isEmpty {
            recommendations.append("您的睡眠质量很好，请继续保持良好的睡眠习惯")
        }

        return recommendations
    }

    private func getQualityLevel(from score: Int) -> String {
        switch score {
        case 90...100:
            return "优秀"
        case 80..<90:
            return "良好"
        case 70..<80:
            return "一般"
        case 60..<70:
            return "较差"
        default:
            return "待改善"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }



    // MARK: - 数据加载方法

    @MainActor
    private func loadLocalSleepData() async {
        isLoadingAudio = true
        print("📱 开始加载本地睡眠数据...")

        // 使用现有的音频文件获取方法
        let sessionAudioFiles = sleepManager.getCurrentSessionAudioFiles()
        audioFiles = sessionAudioFiles.filter { $0.sessionId == derivedSessionId }
        print("✅ 加载了 \(audioFiles.count) 个本地音频文件")

        isLoadingAudio = false
    }

    @MainActor
    private func loadLocalAnalysisResult() async {
        let sessionId: String
        if let originalSessionId = record.originalSessionId {
            sessionId = originalSessionId
        } else if let sleepId = record.sleepId {
            sessionId = String(sleepId)
        } else {
            sessionId = record.id.uuidString
        }

        isLoadingLocalAnalysis = true
        localAnalysisError = nil

        print("🧠 开始加载本地音频分析结果，会话ID: \(sessionId)")

        // 从 deepSeekAnalysisResults 字典中获取分析结果
        let result = sleepManager.deepSeekAnalysisResults[derivedSessionId]

        // 将DeepSeekSleepAnalysis转换为SleepAudioAnalysisResult
        if let result = result {
            localAnalysisResult = SleepAudioAnalysisResult(
                sessionId: derivedSessionId,
                overallQuality: result.qualityAssessment.overallScore,
                sleepQualityScore: result.qualityAssessment.overallScore,
                qualityLevel: .good,
                sleepQualityInsights: result.aiInsights.map { $0.title },
                analysisDate: result.analysisDate
            )
            print("✅ 本地音频分析结果加载成功")
        } else {
            print("⚠️ 未找到本地音频分析结果")
        }

        isLoadingLocalAnalysis = false
    }

    @MainActor
    private func loadLocalAudioSegments() async {
        isLoadingAudioSegments = true

        print("🎵 开始加载本地音频片段，会话 ID: \(derivedSessionId)")

        // 将LocalAudioFile转换为SleepLocalAudioSegment（携带文件信息，便于直接播放）
        let allAudioFiles = sleepManager.getCurrentSessionAudioFiles()
        let audioFiles = allAudioFiles.filter { $0.sessionId == derivedSessionId }
        let segments = audioFiles.map { audioFile in
            SleepLocalAudioSegment(
                type: "audio",
                startTime: 0,
                endTime: audioFile.duration,
                confidence: 0.8,
                sessionId: derivedSessionId,
                fileName: audioFile.fileName,
                filePath: audioFile.filePath,
                eventDate: audioFile.recordingDate
            )
        }
        self.localAudioSegments = segments

        print("✅ 本地音频片段加载完成: \(segments.count)个片段")

        isLoadingAudioSegments = false
    }

    @MainActor
    private func loadHealthReportAnalysis() async {
        // 清除之前的错误状态
        healthReportError = nil
        
        print("📊 开始加载健康报告分析，日期: \(record.bedTime)")
        isLoadingHealthReport = true
        
        do {
            // 调用API获取健康报告（使用睡眠日期）
            let reportData = try await SleepAPIService.shared.getHealthReportForDate(record.bedTime)
            healthReportData = reportData
            isLoadingHealthReport = false
            
            print("✅ 健康报告加载成功")
            
            // 打印睡眠分析数据
            if let sleepSummary = reportData.detailedAnalysis?.sleepSummary {
                print("📊 睡眠汇总: 总会话\(sleepSummary.totalSessions ?? 0)次, 平均时长\(sleepSummary.averageSleepDuration ?? 0.0)小时")
            }
            
        } catch {
            print("❌ 加载健康报告失败: \(error.localizedDescription)")
            isLoadingHealthReport = false
            
            // 如果当天没有报告（404），不算错误，只是显示空状态
            if let networkError = error as? NetworkManager.NetworkError,
               case .serverError(let code) = networkError,
               code == 404 {
                print("ℹ️ 该日期暂无健康报告，显示空状态")
                healthReportError = nil
            } else {
                // 其他错误正常显示
                healthReportError = error.localizedDescription
            }
        }
    }
    
    @MainActor
    private func loadSessionAnalysis() async {
        // 清除之前的错误状态
        sessionAnalysisError = nil

        print("🔍 开始加载单次会话分析，会话ID: \(derivedSessionId)")
        isLoadingSessionAnalysis = true

        do {
            // 调用API获取单次会话分析
            let analysisData = try await SleepAPIService.shared.getSingleSessionQualityAnalysis(sessionId: derivedSessionId)
            sessionAnalysisData = analysisData
            isLoadingSessionAnalysis = false

            print("✅ 单次会话分析加载成功")
            print("   - 整体评分: \(analysisData.qualityAnalysis.overallScore)")
            print("   - 质量等级: \(analysisData.qualityAnalysis.qualityLevel)")
            print("   - 洞察数量: \(analysisData.qualityAnalysis.insights.count)")
            print("   - 建议数量: \(analysisData.qualityAnalysis.recommendations.count)")

        } catch {
            print("❌ 加载单次会话分析失败: \(error.localizedDescription)")
            isLoadingSessionAnalysis = false
            sessionAnalysisError = error.localizedDescription
        }
    }

    /// 加载睡眠 AI 分析报告（新增）
    @MainActor
    private func loadAIReport() async {
        // 清除之前的错误状态
        aiReportError = nil

        print("🤖 开始加载睡眠 AI 分析报告，会话ID: \(derivedSessionId)")
        isLoadingAIReport = true

        do {
            // 调用API获取睡眠 AI 分析报告
            let reportData = try await SleepAPIService.shared.getSleepAIReport(sessionId: derivedSessionId)
            aiReportData = reportData
            isLoadingAIReport = false

            print("✅ 睡眠 AI 分析报告加载成功")
            print("   - 报告ID: \(reportData.reportId)")
            print("   - 生成时间: \(reportData.generatedAt)")
            print("   - 整体质量: \(reportData.sleepSummary.overallQuality)")
            print("   - 睡眠效率: \(reportData.sleepSummary.sleepEfficiency)%")
            print("   - 睡眠阶段数: \(reportData.sleepStages.count)")
            print("   - AI 洞察数: \(reportData.insights.count)")
            print("   - AI 建议数: \(reportData.aiAnalysis.recommendations.count)")

        } catch {
            print("❌ 加载睡眠 AI 分析报告失败: \(error.localizedDescription)")
            isLoadingAIReport = false
            aiReportError = error.localizedDescription
        }
    }

    /// 查找本地睡眠会话
    private func findLocalSleepSession() -> LocalSleepSession? {
        // 尝试从 SleepDataManager 获取当前会话
        if let currentSession = sleepManager.currentSession,
           currentSession.sessionId == derivedSessionId {
            return currentSession
        }

        // 如果没有当前会话，尝试从记录中重建
        if true {
            return LocalSleepSession(
                sessionId: derivedSessionId,
                startTime: record.bedTime,
                endTime: record.wakeTime
            )
        }

        return nil
    }

    /// 获取会话的音频文件
    private func getAudioFilesForSession() -> [LocalAudioFile] {
        // 从 SleepDataManager 获取音频文件，根据会话ID匹配
        return sleepManager.recordedAudioFiles.compactMap { audioFile in
            if audioFile.sessionId == derivedSessionId {
                return audioFile
            }
            return nil
        }
    }

    /// 创建后备分析结果
    private func createFallbackAnalysis() -> DeepSeekSleepAnalysis {
        let qualityScore = Double(record.sleepQualityScore)

        return DeepSeekSleepAnalysis(
            sessionId: derivedSessionId,
            qualityScore: qualityScore,
            insights: ["由于网络或其他原因，使用了基础分析模式。建议稍后重试获取完整的 AI 分析。"],
            recommendations: ["建议保持固定的睡眠和起床时间，有助于改善睡眠质量。"]
        )
    }

    /// 获取质量等级
    private func getQualityLevel(from score: Double) -> DeepSeekSleepQualityLevel {
        switch score {
        case 90...100: return .excellent
        case 75..<90: return .good
        case 60..<75: return .fair
        default: return .poor
        }
    }
}

// MARK: - Audio Player Delegate for SleepDetailView
private class SleepDetailAudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinished: () -> Void
    
    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinished()
    }
}

#Preview {
    // 创建一个简单的示例睡眠记录用于预览
    let bedTime = Date().addingTimeInterval(-8*3600)
    let sleepTime = Date().addingTimeInterval(-7.5*3600)
    let wakeTime = Date()

    let sampleStages = [
        SleepStage(stage: .light, startTime: sleepTime, duration: 2*3600),
        SleepStage(stage: .deep, startTime: sleepTime.addingTimeInterval(2*3600), duration: 2*3600),
        SleepStage(stage: .rem, startTime: sleepTime.addingTimeInterval(4*3600), duration: 1.5*3600)
    ]

    let sampleRecord = SleepRecord(
        sleepId: 1,
        originalSessionId: "sample-session",
        bedTime: bedTime,
        sleepTime: sleepTime,
        wakeTime: wakeTime,
        sleepStages: sampleStages,
        sleepScore: 85,
        sleepEfficiency: 0.85,
        totalSleepTime: 450,
        notes: "测试睡眠记录"
    )

    return SleepDetailView(record: sampleRecord)
}