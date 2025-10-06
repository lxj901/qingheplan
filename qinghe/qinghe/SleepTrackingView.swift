import SwiftUI
import UserNotifications
import AVFoundation
import EventKit

struct SleepTrackingView: View {
    @StateObject private var sleepManager = SleepDataManager.shared
    @StateObject private var backgroundManager = SleepBackgroundManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var breathingAnimation = false
    private var isTracking: Bool { sleepManager.isTrackingSleep }
    private var trackingStartTime: Date? { sleepManager.currentSession?.startTime }

    @State private var showWakeTimeSelection = false
    @State private var selectedWakeTime = Date()
    @State private var pulseAnimation = false
    @State private var starAnimation = false
    @State private var currentTime = Date()
    @State private var smartAlarmTime: Date?
    @State private var countdownText: String = ""
    @State private var audioEngine: AVAudioEngine?
    @State private var audioInputNode: AVAudioInputNode?
    @State private var eventStore = EKEventStore()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // 睡眠主题背景
                    sleepThemeBackground

                    VStack(spacing: 0) {
                        // 顶部导航区域
                        topNavigationArea
                            .padding(.top, 20)

                        Spacer()

                        // 主要追踪界面
                        mainTrackingInterface

                        Spacer()

                        // 睡眠小贴士
                        sleepTipsCard
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                    
                    // 上传状态Toast
                    if let message = sleepManager.uploadStatusMessage {
                        VStack {
                            Spacer()
                            HStack(spacing: 12) {
                                Image(systemName: message.contains("✅") ? "checkmark.circle.fill" : "info.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                
                                Text(message)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(message.contains("✅") ? Color.green : Color.blue)
                                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            )
                            .padding(.bottom, 100)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: sleepManager.uploadStatusMessage)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                breathingAnimation = true
                pulseAnimation = true
                starAnimation = true
            }

            // 检查是否有未完成的后台追踪
            restoreBackgroundTrackingState()
        }
        .onDisappear {
            // 页面消失时不停止后台追踪，让它继续运行
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            updateCountdown()
        }

        .onReceive(NotificationCenter.default.publisher(for: .sleepTrackingWillEnterForeground)) { _ in
            // 前台激活时同步追踪状态到UI
            if sleepManager.isTrackingSleep {
                if backgroundManager.hasActiveBackgroundTracking() {
                    let (_, alarmTime, _) = backgroundManager.getCurrentSessionInfo()
                    smartAlarmTime = alarmTime
                }
                updateCountdown()
                startAudioMonitoring()
            } else {
                countdownText = ""
            }
        }


        .sheet(isPresented: $showWakeTimeSelection) {
            WakeTimeSelectionView(
                selectedTime: $selectedWakeTime,
                onConfirm: { wakeTime in
                    smartAlarmTime = wakeTime
                    startSleepTrackingWithAlarm()
                    addAlarmToCalendar(for: wakeTime)
                }
            )
        }
    }

    // MARK: - 深度夜间背景

    private var sleepThemeBackground: some View {
        ZStack {
            // 深度渐变背景
            RadialGradient(
                colors: [
                    Color(red: 0.02, green: 0.05, blue: 0.15),
                    Color(red: 0.01, green: 0.03, blue: 0.10),
                    Color.black
                ],
                center: .center,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()

            // 动态星空效果
            ForEach(0..<40, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.3...0.8)))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .scaleEffect(starAnimation ? 1.0 : 0.3)
                    .opacity(starAnimation ? 1.0 : 0.2)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: starAnimation
                    )
            }

            // 月光效果
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .position(x: UIScreen.main.bounds.width * 0.8, y: 150)
                .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                .opacity(pulseAnimation ? 0.4 : 0.2)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: pulseAnimation)
        }
    }

    // MARK: - 顶部导航区域

    private var topNavigationArea: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Color(red: 0.6, green: 0.8, blue: 1.0))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.6, green: 0.8, blue: 1.0).opacity(0.3), lineWidth: 1)
                        )
                )
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(currentTime, style: .time)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.6, green: 0.8, blue: 1.0))
                    .monospacedDigit()

                Text("睡眠追踪")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // MARK: - 主要追踪界面

    private var mainTrackingInterface: some View {
        VStack(spacing: 40) {
            // 追踪状态显示
            trackingStatusDisplay

            // 主要操作按钮
            mainActionButton
        }
    }

    private var trackingStatusDisplay: some View {
        VStack(spacing: 32) {
            // 多层呼吸动画圆圈
            ZStack {
                // 外层光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(breathingAnimation ? 1.3 : 1.0)
                    .opacity(breathingAnimation ? 0.6 : 0.3)
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: breathingAnimation)

                // 中层圆环
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0.7, blue: 1.0).opacity(0.6),
                                Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(breathingAnimation ? 1.1 : 0.9)
                    .opacity(breathingAnimation ? 0.8 : 0.4)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.3), value: breathingAnimation)

                // 内层主圆
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                Color(red: 0.6, green: 0.4, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(breathingAnimation ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.6), value: breathingAnimation)

                // 中心图标
                VStack(spacing: 8) {
                    Image(systemName: isTracking ? "moon.zzz.fill" : "moon.stars.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                        .scaleEffect(breathingAnimation ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.9), value: breathingAnimation)

                    if isTracking {
                        Text("追踪中")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }

            // 状态信息
            VStack(spacing: 12) {
                Text(isTracking ? "正在追踪您的睡眠" : "准备开始睡眠追踪")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                if isTracking && !countdownText.isEmpty {
                    VStack(spacing: 4) {
                        Text("距离起床还有")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        Text(countdownText)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                } else if !isTracking {
                    Text("将自动检测您的睡眠状态和阶段")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - 主要操作按钮

    private var mainActionButton: some View {
        VStack(spacing: 16) {
            // 主要追踪按钮
            Button(action: {
                if isTracking {
                    stopSleepTracking()
                } else {
                    showWakeTimeSelection = true
                }
            }) {
                HStack(spacing: 16) {
                    Image(systemName: isTracking ? "stop.circle.fill" : "moon.circle.fill")
                        .font(.system(size: 24))

                    VStack(spacing: 2) {
                        Text(isTracking ? "停止追踪" : "开始睡眠追踪")
                            .font(.system(size: 18, weight: .semibold))

                        Text(isTracking ? "结束今晚的睡眠记录" : "设置起床时间并开始追踪")
                            .font(.system(size: 12, weight: .medium))
                            .opacity(0.8)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            isTracking ?
                            LinearGradient(
                                colors: [
                                    Color.red,
                                    Color.orange
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.6, blue: 1.0),
                                    Color(red: 0.6, green: 0.4, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(isTracking ? 1.02 : 1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isTracking)

        }
    }

    // MARK: - 睡眠小贴士卡片

    private var sleepTipsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.4))

                Text("睡眠小贴士")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }

            Text(getCurrentSleepTip())
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - 辅助方法

    private func startSleepTrackingWithAlarm() {
        // 使用真实API开始睡眠跟踪
        Task {
            await sleepManager.startSleepTracking()

            // 启动后台追踪管理器
            if let session = sleepManager.currentSession {
                backgroundManager.startBackgroundTracking(
                    sessionId: session.sessionId,
                    alarmTime: smartAlarmTime
                )
            }
        }

        // 设置抖音音乐闹钟通知
        if let alarmTime = smartAlarmTime {
            scheduleDouyinMusicAlarm(for: alarmTime)
        }

        // 开始音频监听（现在由SleepDataManager管理）
        startAudioMonitoring()

        // 更新倒计时
        updateCountdown()

        // 提供触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        print("🌙 睡眠追踪已启动，后台保护已激活")
    }

    private func stopSleepTracking() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            smartAlarmTime = nil
            countdownText = ""
        }

        // 停止后台追踪管理器
        backgroundManager.stopBackgroundTracking()

        // 使用真实API停止睡眠跟踪
        Task {
            await sleepManager.stopSleepTracking(
                sleepQualityRating: 5,
                userNotes: "手动结束"
            )
        }

        // 停止音频监听
        stopAudioMonitoring()

        // 取消闹钟通知
        cancelDouyinMusicAlarm()

        // 提供触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        print("☀️ 睡眠追踪已停止，后台保护已关闭")

        // 延迟关闭页面，让用户看到状态变化
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }

    // MARK: - 抖音音乐闹钟通知

    private func scheduleDouyinMusicAlarm(for alarmTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "起床闹钟"

        // 检查是否设置了抖音音乐
        content.body = "起床时间到了！"

        content.sound = .default
        content.categoryIdentifier = "DOUYIN_MUSIC_ALARM"
        content.userInfo = ["action": "play_douyin_music"]

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: alarmTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "douyin_music_alarm_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("设置抖音音乐闹钟失败: \(error)")
            } else {
                print("✅ 抖音音乐闹钟已设置，时间: \(alarmTime)")
            }
        }
    }

    private func cancelDouyinMusicAlarm() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🔕 已取消抖音音乐闹钟")
    }

    // MARK: - 格式化方法

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - 倒计时功能

    private func updateCountdown() {
        guard isTracking, let alarmTime = smartAlarmTime else {
            countdownText = ""
            return
        }

        let now = Date()
        let calendar = Calendar.current

        // 改进的时间计算逻辑，正确处理跨天情况
        var timeInterval = alarmTime.timeIntervalSince(now)

        // 如果起床时间在当前时间之前，说明是明天的起床时间
        if timeInterval < 0 {
            // 计算到明天同一时间的间隔
            if let nextDayAlarm = calendar.date(byAdding: .day, value: 1, to: alarmTime) {
                timeInterval = nextDayAlarm.timeIntervalSince(now)
            }
        }

        // 如果时间间隔仍然为负或者超过24小时，重新计算
        if timeInterval < 0 || timeInterval > 24 * 3600 {
            // 获取今天的起床时间
            let alarmHour = calendar.component(.hour, from: alarmTime)
            let alarmMinute = calendar.component(.minute, from: alarmTime)

            // 先尝试今天的起床时间
            if let todayAlarm = calendar.date(bySettingHour: alarmHour, minute: alarmMinute, second: 0, of: now) {
                timeInterval = todayAlarm.timeIntervalSince(now)

                // 如果今天的时间已经过了，使用明天的时间
                if timeInterval <= 0 {
                    if let tomorrowAlarm = calendar.date(byAdding: .day, value: 1, to: todayAlarm) {
                        timeInterval = tomorrowAlarm.timeIntervalSince(now)
                    }
                }
            }
        }

        if timeInterval <= 0 {
            countdownText = "起床时间到了"
            return
        }

        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60

        if hours > 0 {
            countdownText = String(format: "%d小时%02d分钟", hours, minutes)
        } else if minutes > 0 {
            countdownText = String(format: "%d分钟%02d秒", minutes, seconds)
        } else {
            countdownText = String(format: "%d秒", seconds)
        }
    }

    // MARK: - 音频监听功能

    private func startAudioMonitoring() {
        // 请求麦克风权限
        Task {
            if #available(iOS 17.0, *) {
                let granted = await AVAudioApplication.requestRecordPermission()
                if granted {
                    self.setupAudioEngine()
                } else {
                    print("麦克风权限被拒绝")
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        if granted {
                            self.setupAudioEngine()
                        } else {
                            print("麦克风权限被拒绝")
                        }
                    }
                }
            }
        }
    }

    private func setupAudioEngine() {
        do {
            // 配置音频会话
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true)

            // 创建音频引擎
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }

            audioInputNode = audioEngine.inputNode
            guard let audioInputNode = audioInputNode else { return }

            // 设置音频格式
            let recordingFormat = audioInputNode.outputFormat(forBus: 0)

            // 安装音频处理节点
            audioInputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, time in
                self.processAudioBuffer(buffer)
            }

            // 启动音频引擎
            try audioEngine.start()

            print("音频监听已启动")

        } catch {
            print("音频监听启动失败: \(error)")
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // 处理音频数据，分析睡眠声音
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        // 计算音量级别
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        let averageLevel = sum / Float(frameLength)

        // 在主线程更新UI或处理睡眠数据
        DispatchQueue.main.async {
            self.analyzeSleepSound(level: averageLevel)
        }
    }

    private func analyzeSleepSound(level: Float) {
        // 分析睡眠声音模式
        // 这里可以实现更复杂的睡眠阶段检测算法

        // 示例：根据音量级别判断睡眠状态
        if level > 0.01 {
            // 检测到声音，可能是翻身或说梦话
            print("检测到睡眠活动，音量级别: \(level)")
        }

        // 可以将数据发送到睡眠管理器进行进一步分析
        // sleepManager.processSleepAudioData(level: level) // 在后续版本中实现
    }

    private func stopAudioMonitoring() {
        audioEngine?.stop()
        audioInputNode?.removeTap(onBus: 0)
        audioEngine = nil
        audioInputNode = nil

        // 停用音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("停止音频会话失败: \(error)")
        }

        print("音频监听已停止")
    }

    /// 获取睡眠阶段显示名称
    private func getSleepStageDisplayName(_ stage: String) -> String {
        switch stage.lowercased() {
        case "awake":
            return "清醒"
        case "light":
            return "浅睡眠"
        case "deep":
            return "深睡眠"
        case "rem":
            return "REM睡眠"
        default:
            return "未知"
        }
    }

    private func getCurrentSleepTip() -> String {
        let tips = [
            "保持卧室温度在18-22°C之间有助于更好的睡眠质量",
            "睡前1小时避免使用电子设备，蓝光会影响褪黑素分泌",
            "规律的作息时间有助于调节生物钟，提高睡眠质量",
            "适量的运动可以改善睡眠，但避免在睡前3小时内剧烈运动",
            "创造一个安静、黑暗的睡眠环境有助于深度睡眠"
        ]

        let hour = Calendar.current.component(.hour, from: Date())
        let index = hour % tips.count
        return tips[index]
    }

    // MARK: - 后台状态恢复

    private func restoreBackgroundTrackingState() {
        // 检查是否有活跃的后台追踪
        if backgroundManager.hasActiveBackgroundTracking() {
            let (sessionId, alarmTime, startTime) = backgroundManager.getCurrentSessionInfo()

            if let sessionId = sessionId, let startTime = startTime {
                print("🔄 恢复后台睡眠追踪状态，会话ID: \(sessionId)")

                // 恢复UI状态（由 SleepDataManager 的 @Published 驱动）
                smartAlarmTime = alarmTime

                // 更新倒计时
                updateCountdown()

                // 重新启动音频监听
                startAudioMonitoring()

                print("✅ 睡眠追踪状态已恢复")
            }
        }
    }

    // MARK: - 录音功能

    private func startAudioRecording() {
        do {
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }

            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)

            audioInputNode = audioEngine.inputNode
            let recordingFormat = audioInputNode?.outputFormat(forBus: 0)

            audioInputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, time in
                // 这里可以处理音频数据，保存到文件或分析
                self.processAudioBuffer(buffer: buffer, time: time)
            }

            try audioEngine.start()
            print("🎤 开始录音...")

        } catch {
            print("❌ 录音启动失败: \(error)")
        }
    }

    private func stopAudioRecording() {
        audioEngine?.stop()
        audioInputNode?.removeTap(onBus: 0)
        audioEngine = nil
        audioInputNode = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("🛑 录音已停止")
        } catch {
            print("❌ 停止录音失败: \(error)")
        }
    }

    private func processAudioBuffer(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        // 简单的音频处理逻辑
        // 可以在这里分析音频数据，检测打鼾、呼吸等
        let channelData = buffer.floatChannelData?[0]
        let frameLength = Int(buffer.frameLength)

        var sum: Float = 0
        for i in 0..<frameLength {
            if let data = channelData {
                sum += abs(data[i])
            }
        }

        let averageAmplitude = sum / Float(frameLength)

        // 如果音量超过阈值，可以记录音频片段
        if averageAmplitude > 0.01 {
            // 这里可以保存音频片段
            DispatchQueue.main.async {
                // 更新UI或保存数据
            }
        }
    }

    // MARK: - 系统闹钟集成

    private func addAlarmToCalendar(for wakeTime: Date) {
        eventStore.requestAccess(to: .event) { granted, error in
            guard granted, error == nil else {
                print("❌ 日历权限被拒绝")
                return
            }

            DispatchQueue.main.async {
                self.createAlarmEvent(for: wakeTime)
            }
        }
    }

    private func createAlarmEvent(for wakeTime: Date) {
        let event = EKEvent(eventStore: eventStore)
        event.title = "起床闹钟 - 清河计划"
        event.startDate = wakeTime
        event.endDate = wakeTime.addingTimeInterval(60) // 持续1分钟
        event.calendar = eventStore.defaultCalendarForNewEvents

        // 添加提醒
        let alarm = EKAlarm(absoluteDate: wakeTime)
        event.addAlarm(alarm)

        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ 闹钟已添加到系统日历")

            // 同时创建本地通知作为备份
            scheduleLocalNotification(for: wakeTime)

        } catch {
            print("❌ 添加闹钟到日历失败: \(error)")
            // 如果日历失败，至少创建本地通知
            scheduleLocalNotification(for: wakeTime)
        }
    }

    private func scheduleLocalNotification(for wakeTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "清河计划 - 起床时间"
        content.body = "该起床了！您的睡眠追踪已完成。"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: wakeTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "sleep-wake-alarm", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 本地通知设置失败: \(error)")
            } else {
                print("✅ 本地通知已设置")
            }
        }
    }

    // MARK: - 辅助方法
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}



#Preview {
    SleepTrackingView()
}