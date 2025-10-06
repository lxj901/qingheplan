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

    // 本地音频片段状态
    @State private var localAudioSegments: [SleepLocalAudioSegment] = []
    @State private var isLoadingAudioSegments = false

    // 音频播放器管理
    @State private var audioPlayer: AVAudioPlayer?
    @State private var nowPlayingSegmentId: UUID?
    @State private var isPlayingSegment: Bool = false
    @State private var audioPlayerDelegate: SleepDetailAudioPlayerDelegate?

    private let tabs = ["概览", "音频", "分析", "建议"]

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

                    // 建议页面
                    enhancedRecommendationsTab
                        .tag(3)
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
                await loadHealthReportAnalysis()  // 替换 DeepSeek 分析
                
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

            // 分享按钮
            Button(action: {
                // TODO: 实现分享功能
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
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

                // 健康洞察
                healthInsights
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
            // 标题栏
            analysisHeaderView

            // 内容区域
            analysisMainContent
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

    // 分析标题栏
    private var analysisHeaderView: some View {
        HStack {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))

            Text("健康分析")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            // 显示健康等级
            if let healthLevel = healthReportData?.healthOverview.healthLevel {
                healthLevelBadge(healthLevel)
            }
        }
    }
    
    // 健康等级徽章
    private func healthLevelBadge(_ level: String) -> some View {
        let (text, color): (String, Color) = {
            switch level.lowercased() {
            case "excellent": return ("优秀", .green)
            case "good": return ("良好", .blue)
            case "fair": return ("一般", .orange)
            case "poor": return ("较差", .red)
            default: return (level, .gray)
            }
        }()
        
        return HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(text)
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

    // 分析主要内容
    private var analysisMainContent: some View {
        Group {
            if let reportData = healthReportData {
                healthReportAnalysisView(reportData)
            } else {
                analysisEmptyStateView
            }
        }
    }

    // 空状态视图
    private var analysisEmptyStateView: some View {
        VStack(spacing: 12) {
            if isLoadingHealthReport {
                loadingStateView
            } else if let error = healthReportError {
                errorStateView(error)
            } else {
                defaultEmptyStateView
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20)
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

            // AI 洞察列表
            if !analysis.aiInsights.isEmpty {
                aiInsightsPreview(analysis.aiInsights)
            }
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

    // AI 洞察预览
    private func aiInsightsPreview(_ insights: [DeepSeekSleepInsight]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI 洞察")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            ForEach(insights.prefix(3), id: \.id) { insight in
                deepSeekInsightCard(insight)
            }

            if insights.count > 3 {
                Text("还有 \(insights.count - 3) 条洞察...")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 4)
            }
        }
    }

    // DeepSeek 洞察卡片
    private func deepSeekInsightCard(_ insight: DeepSeekSleepInsight) -> some View {
        HStack(spacing: 12) {
            // 洞察类型图标
            Image(systemName: insight.type.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(insight.type.color)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(insight.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()

                    // 置信度
                    Text("\(Int(insight.confidence))%")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }

                Text(insight.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(insight.type.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(insight.type.color.opacity(0.3), lineWidth: 0.5)
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
            } else {
                Text("暂无详细分析数据")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
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

    // 所有洞察卡片
    private func allInsightsCard(_ insights: [DeepSeekSleepInsight]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.yellow)

                Text("详细洞察")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(insights.count) 条")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            LazyVStack(spacing: 12) {
                ForEach(insights, id: \.id) { insight in
                    deepSeekInsightCard(insight)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
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

    // MARK: - 睡眠建议
    private var sleepRecommendations: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2))

                Text("个性化建议")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            // 显示基础建议
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(getSleepRecommendations(), id: \.self) { recommendation in
                    unifiedRecommendationItem(recommendation)
                }
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

    private func unifiedRecommendationItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(red: 1.0, green: 0.8, blue: 0.2))
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - 健康洞察
    private var healthInsights: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))

                Text("AI 健康洞察")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            // 显示基础健康洞察
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(getHealthInsights(), id: \.self) { insight in
                    unifiedInsightItem(insight)
                }
            }
            
            // 如果有健康报告数据，显示健康等级总结
            if let reportData = healthReportData {
                let healthLevel = reportData.healthOverview.healthLevel
                if healthLevel == "优秀" || healthLevel == "良好" {
                    healthSummaryCard(
                        title: "健康状态良好",
                        description: "您的整体健康状态处于\(healthLevel)水平，请继续保持良好的生活习惯。",
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )
                } else {
                    healthSummaryCard(
                        title: "健康状态需要关注",
                        description: "您的健康状态为\(healthLevel)，建议关注健康建议，改善生活方式。",
                        color: .orange,
                        icon: "exclamationmark.triangle.fill"
                    )
                }
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

    // 健康总结卡片
    private func healthSummaryCard(title: String, description: String, color: Color, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func unifiedInsightItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(red: 1.0, green: 0.4, blue: 0.4))
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
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

    private func getHealthInsights() -> [String] {
        var insights: [String] = []

        let deepSleepMinutes = Int(deepSleepPercentage * record.totalSleepDuration / 60)
        let remSleepMinutes = Int(remSleepPercentage * record.totalSleepDuration / 60)

        insights.append("深睡眠时长: \(deepSleepMinutes)分钟，占总睡眠的\(Int(deepSleepPercentage * 100))%")
        insights.append("REM睡眠时长: \(remSleepMinutes)分钟，占总睡眠的\(Int(remSleepPercentage * 100))%")

        if record.sleepQualityScore >= 90 {
            insights.append("睡眠质量优秀，身体得到了充分的休息和恢复")
        } else if record.sleepQualityScore >= 70 {
            insights.append("睡眠质量良好，但仍有改善空间")
        } else {
            insights.append("睡眠质量需要改善，建议关注睡眠环境和习惯")
        }

        return insights
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