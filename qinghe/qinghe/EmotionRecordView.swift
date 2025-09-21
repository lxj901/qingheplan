import SwiftUI

/// 情绪记录界面
struct EmotionRecordView: View {
    @StateObject private var viewModel = EmotionRecordViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // 表单状态
    @State private var selectedEmotionType: ExtendedEmotionType = .happy
    @State private var intensity: Double = 5.0
    @State private var trigger: String = ""
    @State private var note: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var weather: String = ""
    @State private var recordedAt = Date()
    
    // UI 状态
    @State private var showingTagPicker = false
    @State private var showingWeatherPicker = false
    
    // 预定义标签
    private let availableTags = ["工作", "学习", "生活", "健康", "家庭", "朋友", "运动", "娱乐", "成就感", "压力", "疲劳", "兴奋"]
    private let weatherOptions = ["晴天", "多云", "阴天", "雨天", "雪天", "雾天"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 头部区域
                        headerSection

                        // 情绪类型选择
                        emotionTypeSection

                        // 强度选择
                        intensitySection

                        // 触发因素
                        triggerSection

                        // 标签选择
                        tagsSection

                        // 天气选择
                        weatherSection

                        // 备注
                        noteSection

                        // 时间选择
                        timeSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100) // 为底部按钮留空间
                }
            }
            .navigationTitle("记录情绪")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveEmotionRecord()
                    }
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                    .disabled(viewModel.isLoading)
                }
            }
            .overlay(alignment: .bottom) {
                // 底部保存按钮
                saveButton
            }
        }
        .alert("保存成功", isPresented: $viewModel.showSuccess) {
            Button("确定") {
                dismiss()
            }
        } message: {
            Text("情绪记录已保存")
        }
        .alert("保存失败", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        .sheet(isPresented: $showingTagPicker) {
            tagPickerSheet
        }
        .sheet(isPresented: $showingWeatherPicker) {
            weatherPickerSheet
        }
    }
    
    // MARK: - 头部区域
    private var headerSection: some View {
        VStack(spacing: 12) {
            // 情绪图标
            ZStack {
                Circle()
                    .fill(selectedEmotionType.color.opacity(0.2))
                    .frame(width: 70, height: 70)

                Text(selectedEmotionType.emoji)
                    .font(.system(size: 36))
            }

            Text("记录你的情绪状态")
                .font(ModernDesignSystem.Typography.headline)
                .foregroundColor(ModernDesignSystem.Colors.textPrimary)

            Text("了解自己的情绪变化，更好地管理心理健康")
                .font(ModernDesignSystem.Typography.caption)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - 情绪类型选择
    private var emotionTypeSection: some View {
        ModernFormCard(
            title: "情绪类型",
            subtitle: "选择最符合当前感受的情绪"
        ) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(ExtendedEmotionType.allCases, id: \.self) { emotion in
                    EmotionTypeButton(
                        emotion: emotion,
                        isSelected: selectedEmotionType == emotion
                    ) {
                        selectedEmotionType = emotion
                    }
                }
            }
        }
    }
    
    // MARK: - 强度选择
    private var intensitySection: some View {
        ModernFormCard(
            title: "情绪强度",
            subtitle: "评估这种情绪的强烈程度"
        ) {
            VStack(spacing: 16) {
                HStack {
                    Text("轻微")
                        .font(ModernDesignSystem.Typography.caption)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(intensity))/10")
                        .font(ModernDesignSystem.Typography.headline)
                        .foregroundColor(selectedEmotionType.color)
                    
                    Spacer()
                    
                    Text("强烈")
                        .font(ModernDesignSystem.Typography.caption)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                }
                
                Slider(value: $intensity, in: 1...10, step: 1)
                    .accentColor(selectedEmotionType.color)
            }
        }
    }
    
    // MARK: - 触发因素
    private var triggerSection: some View {
        ModernFormCard(
            title: "触发因素",
            subtitle: "是什么引起了这种情绪？（可选）"
        ) {
            TextField("例如：工作顺利、考试压力等", text: $trigger, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .font(ModernDesignSystem.Typography.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ModernDesignSystem.Colors.backgroundSecondary)
                .cornerRadius(ModernDesignSystem.CornerRadius.md)
                .lineLimit(2...4)
        }
    }
    
    // MARK: - 标签选择
    private var tagsSection: some View {
        ModernFormCard(
            title: "相关标签",
            subtitle: "添加相关标签便于分类（可选）"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // 已选择的标签
                if !selectedTags.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(Array(selectedTags), id: \.self) { tag in
                            TagChip(text: tag, isSelected: true) {
                                selectedTags.remove(tag)
                            }
                        }
                    }
                }
                
                // 添加标签按钮
                Button(action: {
                    showingTagPicker = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text(selectedTags.isEmpty ? "添加标签" : "添加更多标签")
                    }
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                }
            }
        }
    }
    
    // MARK: - 天气选择
    private var weatherSection: some View {
        ModernFormCard(
            title: "天气情况",
            subtitle: "当时的天气状况（可选）"
        ) {
            Button(action: {
                showingWeatherPicker = true
            }) {
                HStack {
                    if weather.isEmpty {
                        Text("选择天气")
                            .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                    } else {
                        Text(weather)
                            .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(ModernDesignSystem.Colors.textTertiary)
                }
                .font(ModernDesignSystem.Typography.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ModernDesignSystem.Colors.backgroundSecondary)
                .cornerRadius(ModernDesignSystem.CornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - 备注
    private var noteSection: some View {
        ModernFormCard(
            title: "详细备注",
            subtitle: "记录更多细节和想法（可选）"
        ) {
            TextField("详细描述当时的情况和感受...", text: $note, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .font(ModernDesignSystem.Typography.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ModernDesignSystem.Colors.backgroundSecondary)
                .cornerRadius(ModernDesignSystem.CornerRadius.md)
                .lineLimit(3...6)
        }
    }
    
    // MARK: - 时间选择
    private var timeSection: some View {
        ModernFormCard(
            title: "记录时间",
            subtitle: "选择情绪发生的时间"
        ) {
            DatePicker("", selection: $recordedAt, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
        }
    }
    
    // MARK: - 底部保存按钮
    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: saveEmotionRecord) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "heart.fill")
                    }
                    
                    Text("保存情绪记录")
                        .font(ModernDesignSystem.Typography.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedEmotionType.color)
                .cornerRadius(ModernDesignSystem.CornerRadius.md)
            }
            .disabled(viewModel.isLoading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(ModernDesignSystem.Colors.backgroundPrimary)
        }
    }
    
    // MARK: - 标签选择器
    private var tagPickerSheet: some View {
        NavigationView {
            List {
                ForEach(availableTags, id: \.self) { tag in
                    Button(action: {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }) {
                        HStack {
                            Text(tag)
                                .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showingTagPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - 天气选择器
    private var weatherPickerSheet: some View {
        NavigationView {
            List {
                ForEach(weatherOptions, id: \.self) { option in
                    Button(action: {
                        weather = option
                        showingWeatherPicker = false
                    }) {
                        HStack {
                            Text(option)
                                .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            if weather == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择天气")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        showingWeatherPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - 保存方法
    private func saveEmotionRecord() {
        let emotionRecord = EmotionRecordRequest(
            type: selectedEmotionType.rawValue,
            intensity: Int(intensity),
            trigger: trigger.isEmpty ? nil : trigger,
            note: note.isEmpty ? nil : note,
            tags: Array(selectedTags),
            weather: weather.isEmpty ? nil : weather,
            recordedAt: ISO8601DateFormatter().string(from: recordedAt)
        )
        
        Task {
            await viewModel.saveEmotionRecord(emotionRecord)
        }
    }
}

// MARK: - 情绪类型按钮组件
struct EmotionTypeButton: View {
    let emotion: ExtendedEmotionType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? emotion.color.opacity(0.3) : ModernDesignSystem.Colors.backgroundSecondary)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? emotion.color : Color.clear, lineWidth: 2)
                        )

                    Text(emotion.emoji)
                        .font(.system(size: 24))
                }

                Text(emotion.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? emotion.color : ModernDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - 标签芯片组件
struct TagChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(text)
                    .font(.system(size: 14, weight: .medium))

                if isSelected {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .foregroundColor(isSelected ? .white : ModernDesignSystem.Colors.primaryGreen)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.primaryGreen.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ModernDesignSystem.Colors.primaryGreen.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 现代化表单卡片组件
struct ModernFormCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(ModernDesignSystem.Typography.headline)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(ModernDesignSystem.Typography.caption)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                }
            }

            content
        }
        .padding(20)
        .background(ModernDesignSystem.Colors.backgroundCard)
        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
        .shadow(
            color: ModernDesignSystem.Shadow.light.color,
            radius: ModernDesignSystem.Shadow.light.radius,
            x: ModernDesignSystem.Shadow.light.x,
            y: ModernDesignSystem.Shadow.light.y
        )
    }
}
