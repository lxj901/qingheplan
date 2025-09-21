import SwiftUI

/// 诱惑记录界面
struct TemptationRecordView: View {
    @StateObject private var viewModel = TemptationRecordViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // 表单状态
    @State private var selectedTemptationType: ExtendedTemptationType = .procrastination
    @State private var intensity: Double = 5.0
    @State private var resistanceResult: ResistanceResult = .resisted
    @State private var note: String = ""
    @State private var selectedStrategies: Set<String> = []
    @State private var recordTime = Date()
    
    // UI 状态
    @State private var showingStrategyPicker = false
    
    // 预定义抵抗策略
    private let availableStrategies = ["深呼吸", "专注工作", "运动锻炼", "听音乐", "冥想", "转移注意力", "设定目标", "寻求帮助", "记录想法", "延迟满足"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 头部区域
                        headerSection

                        // 诱惑类型选择
                        temptationTypeSection

                        // 强度选择
                        intensitySection

                        // 抵抗结果
                        resistanceResultSection

                        // 抵抗策略
                        strategiesSection

                        // 备注
                        noteSection

                        // 时间选择
                        timeSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 100) // 为底部按钮留空间
                }
            }
            .navigationTitle("记录诱惑")
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
                        saveTemptationRecord()
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
            Text("诱惑记录已保存")
        }
        .alert("保存失败", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        .sheet(isPresented: $showingStrategyPicker) {
            strategyPickerSheet
        }
    }
    
    // MARK: - 头部区域
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 诱惑图标
            ZStack {
                Circle()
                    .fill(selectedTemptationType.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Text(selectedTemptationType.emoji)
                    .font(.system(size: 40))
            }
            
            Text("记录诱惑抵抗情况")
                .font(ModernDesignSystem.Typography.headline)
                .foregroundColor(ModernDesignSystem.Colors.textPrimary)
            
            Text("记录你面对诱惑时的表现，提升自控力")
                .font(ModernDesignSystem.Typography.caption)
                .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - 诱惑类型选择
    private var temptationTypeSection: some View {
        ModernFormCard(
            title: "诱惑类型",
            subtitle: "选择你遇到的诱惑类型"
        ) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(ExtendedTemptationType.allCases, id: \.self) { temptation in
                    TemptationTypeButton(
                        temptation: temptation,
                        isSelected: selectedTemptationType == temptation
                    ) {
                        selectedTemptationType = temptation
                    }
                }
            }
        }
    }
    
    // MARK: - 强度选择
    private var intensitySection: some View {
        ModernFormCard(
            title: "诱惑强度",
            subtitle: "评估这次诱惑的强烈程度"
        ) {
            VStack(spacing: 16) {
                HStack {
                    Text("轻微")
                        .font(ModernDesignSystem.Typography.caption)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(intensity))/10")
                        .font(ModernDesignSystem.Typography.headline)
                        .foregroundColor(selectedTemptationType.color)
                    
                    Spacer()
                    
                    Text("强烈")
                        .font(ModernDesignSystem.Typography.caption)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                }
                
                Slider(value: $intensity, in: 1...10, step: 1)
                    .accentColor(selectedTemptationType.color)
            }
        }
    }
    
    // MARK: - 抵抗结果
    private var resistanceResultSection: some View {
        ModernFormCard(
            title: "抵抗结果",
            subtitle: "你是否成功抵抗了这次诱惑？"
        ) {
            HStack(spacing: 16) {
                ForEach(ResistanceResult.allCases, id: \.self) { result in
                    ResistanceResultButton(
                        result: result,
                        isSelected: resistanceResult == result
                    ) {
                        resistanceResult = result
                    }
                }
            }
        }
    }
    
    // MARK: - 抵抗策略
    private var strategiesSection: some View {
        ModernFormCard(
            title: "抵抗策略",
            subtitle: "你使用了哪些方法来抵抗诱惑？（可选）"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // 已选择的策略
                if !selectedStrategies.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(Array(selectedStrategies), id: \.self) { strategy in
                            StrategyChip(text: strategy, isSelected: true) {
                                selectedStrategies.remove(strategy)
                            }
                        }
                    }
                }
                
                // 添加策略按钮
                Button(action: {
                    showingStrategyPicker = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text(selectedStrategies.isEmpty ? "添加抵抗策略" : "添加更多策略")
                    }
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                }
            }
        }
    }
    
    // MARK: - 备注
    private var noteSection: some View {
        ModernFormCard(
            title: "详细备注",
            subtitle: "记录当时的情况和想法（可选）"
        ) {
            TextField("详细描述当时的情况和使用的方法...", text: $note, axis: .vertical)
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
            subtitle: "选择诱惑发生的时间"
        ) {
            DatePicker("", selection: $recordTime, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
        }
    }
    
    // MARK: - 底部保存按钮
    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: saveTemptationRecord) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: resistanceResult == .resisted ? "shield.checkered" : "shield.slash")
                    }
                    
                    Text("保存诱惑记录")
                        .font(ModernDesignSystem.Typography.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(resistanceResult.color)
                .cornerRadius(ModernDesignSystem.CornerRadius.md)
            }
            .disabled(viewModel.isLoading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(ModernDesignSystem.Colors.backgroundPrimary)
        }
    }
    
    // MARK: - 策略选择器
    private var strategyPickerSheet: some View {
        NavigationView {
            List {
                ForEach(availableStrategies, id: \.self) { strategy in
                    Button(action: {
                        if selectedStrategies.contains(strategy) {
                            selectedStrategies.remove(strategy)
                        } else {
                            selectedStrategies.insert(strategy)
                        }
                    }) {
                        HStack {
                            Text(strategy)
                                .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            if selectedStrategies.contains(strategy) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择抵抗策略")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showingStrategyPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - 保存方法
    private func saveTemptationRecord() {
        let temptationRecord = TemptationRecordRequest(
            type: selectedTemptationType.rawValue,
            intensity: Int(intensity),
            result: resistanceResult.rawValue,
            note: note.isEmpty ? nil : note,
            strategies: Array(selectedStrategies),
            recordTime: ISO8601DateFormatter().string(from: recordTime)
        )
        
        Task {
            await viewModel.saveTemptationRecord(temptationRecord)
        }
    }
}

// MARK: - 诱惑类型按钮组件
struct TemptationTypeButton: View {
    let temptation: ExtendedTemptationType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? temptation.color.opacity(0.3) : ModernDesignSystem.Colors.backgroundSecondary)
                        .frame(width: 60, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? temptation.color : Color.clear, lineWidth: 2)
                        )

                    Text(temptation.emoji)
                        .font(.system(size: 24))
                }

                Text(temptation.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? temptation.color : ModernDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - 抵抗结果按钮组件
struct ResistanceResultButton: View {
    let result: ResistanceResult
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? result.color.opacity(0.2) : ModernDesignSystem.Colors.backgroundSecondary)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? result.color : Color.clear, lineWidth: 2)
                        )

                    Text(result.emoji)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.description)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? result.color : ModernDesignSystem.Colors.textPrimary)

                    Text(result.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? result.color.opacity(0.1) : ModernDesignSystem.Colors.backgroundSecondary)
            .cornerRadius(ModernDesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .stroke(isSelected ? result.color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - 策略芯片组件
struct StrategyChip: View {
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
