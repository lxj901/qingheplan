import SwiftUI

/// 打卡输入视图
struct CheckinInputView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var checkinViewModel = CheckinViewModel()

    @State private var noteText = ""
    @State private var isSubmitting = false
    @State private var currentEmojiIndex = 0
    @State private var animationTimer: Timer?
    @State private var selectedCategory = 0 // 当前选中的分类

    private let maxNoteLength = 200

    // 分类标题和图标
    private let categories = ["正能量", "坚持", "专注", "感恩", "成长"]
    private let categoryEmojis = ["✨", "💪", "🎯", "🙏", "🌱"]
    // 50条精心设计的打卡句子，分为不同类别
    private let quickNotes = [
        // 积极正能量 (10条)
        "今天状态很棒", "充满正能量", "心情特别好", "感觉很幸福", "今天很有收获",
        "满满的成就感", "今天进步了", "感觉很充实", "心情阳光明媚", "今天很开心",

        // 坚持与努力 (10条)
        "继续坚持下去", "不放弃努力", "一步一个脚印", "坚持就是胜利", "努力奋斗中",
        "向目标前进", "保持初心", "永不言弃", "持续努力中", "坚定前行",

        // 专注与学习 (10条)
        "专注当下", "认真学习中", "保持专注力", "今天学到很多", "思维很清晰",
        "效率很高", "注意力集中", "学习状态佳", "思考很深入", "收获满满",

        // 感恩与反思 (10条)
        "心怀感恩", "感谢今天", "珍惜当下", "反思与成长", "感恩遇见",
        "今天很感动", "心存感激", "感谢生活", "珍惜拥有", "感恩每一天",

        // 挑战与成长 (10条)
        "迎接新挑战", "突破自己", "勇敢面对", "成长的一天", "克服困难",
        "挑战成功", "超越昨天", "勇于尝试", "不断进步", "成长路上"
    ]

    private let quickNoteEmojis = [
        // 积极正能量对应表情
        "😊", "✨", "😄", "🥰", "📈",
        "🎉", "👍", "💯", "☀️", "😃",

        // 坚持与努力对应表情
        "💪", "🔥", "👣", "🏆", "⚡",
        "🎯", "❤️", "🚀", "⏰", "🌟",

        // 专注与学习对应表情
        "🎯", "📚", "🧠", "💡", "🔍",
        "⚡", "👀", "📖", "🤔", "🎓",

        // 感恩与反思对应表情
        "🙏", "💖", "🌸", "🌱", "🤝",
        "😌", "💝", "🌺", "💎", "🌅",

        // 挑战与成长对应表情
        "⚔️", "🚀", "💪", "🌱", "🏔️",
        "🎊", "📊", "🌟", "📈", "🛤️"
    ]
    private let emojis = ["😊", "💪", "🌟", "🎯", "✨", "🔥", "💯", "🚀"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 主要内容
                    ScrollView {
                        VStack(spacing: 24) {
                            // 顶部图标和标题
                            headerSection
                            
                            // 备注输入区域
                            noteInputSection

                            // 快捷备注选项
                            quickNotesSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // 底部按钮
                    bottomButtonSection
                }
            }
            .navigationTitle("打卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            startEmojiAnimation()
        }
        .onDisappear {
            stopEmojiAnimation()
        }
    }
    
    // MARK: - 头部区域
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 动画表情符号图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.1),
                                Color(red: 56/255, green: 142/255, blue: 60/255).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.3),
                                        Color(red: 56/255, green: 142/255, blue: 60/255).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                Text(emojis[currentEmojiIndex])
                    .font(.system(size: 50))
                    .scaleEffect(isSubmitting ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: currentEmojiIndex)
                    .animation(.easeInOut(duration: 0.2), value: isSubmitting)
            }
            .shadow(
                color: Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.15),
                radius: 20,
                x: 0,
                y: 10
            )
            
            VStack(spacing: 8) {
                Text("今日打卡")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("记录这一刻的坚持")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - 备注输入区域
    private var noteInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("打卡备注")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("(\(noteText.count)/\(maxNoteLength))")
                    .font(.caption)
                    .foregroundColor(noteText.count > maxNoteLength ? .red : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .stroke(
                            noteText.count > maxNoteLength ? Color.red : Color(.systemGray4),
                            lineWidth: 1
                        )
                        .frame(height: 100)
                    
                    if noteText.isEmpty {
                        Text("分享此刻的心情或感受...")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }
                    
                    TextEditor(text: $noteText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                }
                
                if noteText.count > maxNoteLength {
                    Text("备注不能超过\(maxNoteLength)个字符")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - 快捷备注选项
    private var quickNotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("写作提示")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    // 收起功能，这里可以添加收起逻辑
                }) {
                    HStack(spacing: 4) {
                        Text("收起")
                            .font(.system(size: 14, weight: .medium))

                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color(red: 76/255, green: 175/255, blue: 80/255))
                }
            }

            // 当前分类的句子 - 垂直列表布局
            let startIndex = selectedCategory * 10
            let endIndex = min(startIndex + 10, quickNotes.count)
            let currentNotes = Array(quickNotes[startIndex..<endIndex])

            VStack(spacing: 12) {
                ForEach(Array(currentNotes.enumerated()), id: \.offset) { index, note in
                    HStack(alignment: .center, spacing: 12) {
                        // 左侧圆点
                        Circle()
                            .fill(Color(red: 76/255, green: 175/255, blue: 80/255))
                            .frame(width: 6, height: 6)

                        // 中间文本
                        Text(note)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)

                        Spacer()

                        // 右侧使用按钮
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                noteText = note
                            }
                        }) {
                            Text("使用")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(red: 76/255, green: 175/255, blue: 80/255))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(noteText == note ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: noteText == note)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                noteText == note ?
                                Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.1) :
                                Color(.systemGray6)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                noteText == note ?
                                Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.3) :
                                Color.clear,
                                lineWidth: 1
                            )
                    )
                }
            }

            // 分类切换按钮
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedCategory = index
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(categoryEmojis[index])
                                    .font(.system(size: 12))

                                Text(category)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(selectedCategory == index ? .white : Color(red: 76/255, green: 175/255, blue: 80/255))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        selectedCategory == index ?
                                        Color(red: 76/255, green: 175/255, blue: 80/255) :
                                        Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.1)
                                    )
                            )
                            .scaleEffect(selectedCategory == index ? 1.05 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    

    
    // MARK: - 底部按钮区域
    private var bottomButtonSection: some View {
        VStack(spacing: 16) {
            Divider()
            
            Button(action: {
                performCheckin()
            }) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Text(isSubmitting ? "打卡中..." : "完成打卡")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 76/255, green: 175/255, blue: 80/255),
                            Color(red: 56/255, green: 142/255, blue: 60/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(
                    color: Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .disabled(isSubmitting || noteText.count > maxNoteLength)
            .opacity(isSubmitting || noteText.count > maxNoteLength ? 0.6 : 1.0)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 私有方法

    private func startEmojiAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentEmojiIndex = (currentEmojiIndex + 1) % emojis.count
            }
        }
    }

    private func stopEmojiAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func performCheckin() {
        guard !isSubmitting else { return }
        guard noteText.count <= maxNoteLength else { return }

        // 停止动画并显示提交状态表情
        stopEmojiAnimation()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentEmojiIndex = emojis.firstIndex(of: "🚀") ?? 0
            isSubmitting = true
        }
        
        Task { @MainActor in
            do {
                // 执行打卡
                let checkinRecord = try await CheckinAPIService.shared.checkin(
                    note: noteText.isEmpty ? nil : noteText,
                    mood: nil as String?,
                    challenges: nil as String?,
                    location: nil as CheckinLocation?
                )
                
                // 更新状态
                checkinViewModel.hasCheckedInToday = true
                checkinViewModel.todayCheckinRecord = checkinRecord

                // 显示成功表情符号
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentEmojiIndex = emojis.firstIndex(of: "💯") ?? 0
                }

                // 短暂延迟显示成功状态
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

                // 显示成功提示
                checkinViewModel.checkinToastMessage = "打卡成功！"
                checkinViewModel.showCheckinToast = true

                // 刷新数据
                await checkinViewModel.loadStatistics()
                await checkinViewModel.loadRecentCheckins()

                // 发送通知，通知主页面刷新状态
                NotificationCenter.default.post(name: NSNotification.Name("CheckinSuccessful"), object: checkinRecord)

                // 关闭界面
                dismiss()
                
            } catch {
                // 显示错误表情符号
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentEmojiIndex = emojis.firstIndex(of: "😊") ?? 0 // 回到默认表情
                }

                // 处理错误
                checkinViewModel.checkinToastMessage = "打卡失败，请重试"
                checkinViewModel.showCheckinToast = true

                // 重新开始动画
                startEmojiAnimation()
            }

            isSubmitting = false
        }
    }
}

#Preview {
    CheckinInputView()
}
