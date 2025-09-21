import SwiftUI

struct CreatePlanView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreatePlanViewModel()
    
    let onPlanCreated: (PlanNew) async -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 基本信息
                    basicInfoSection
                    
                    // 时间设置
                    timeSettingsSection
                    
                    // 优先级和分类
                    priorityAndCategorySection
                    
                    // 目标设置
                    goalsSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(backgroundGradient)
            .navigationTitle("创建计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        Task {
                            await handleCreatePlan()
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView("创建中...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                }
            }
        )
        .alert("创建失败", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
    }
    
    // MARK: - View Components
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("基本信息")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // 计划标题
                VStack(alignment: .leading, spacing: 8) {
                    Text("计划标题 *")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    TextField("输入计划标题", text: $viewModel.title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 16, weight: .medium))
                }
                
                // 计划描述
                VStack(alignment: .leading, spacing: 8) {
                    Text("计划描述")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    TextField("输入计划描述（可选）", text: $viewModel.description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(3...6)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var timeSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("时间设置")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // 开始时间
                VStack(alignment: .leading, spacing: 8) {
                    Text("开始时间 *")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                }
                
                // 是否设置结束时间
                Toggle("设置结束时间", isOn: $viewModel.hasEndDate)
                    .font(.system(size: 16, weight: .medium))
                
                // 结束时间
                if viewModel.hasEndDate {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("结束时间")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)

                        DatePicker("", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                    }
                }

                // 是否设置提醒时间
                Toggle("设置提醒时间", isOn: $viewModel.hasReminderTime)
                    .font(.system(size: 16, weight: .medium))

                // 提醒时间
                if viewModel.hasReminderTime {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("提醒时间")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)

                        DatePicker("", selection: $viewModel.reminderTime, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var priorityAndCategorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("优先级和分类")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // 优先级选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("优先级")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Picker("优先级", selection: $viewModel.selectedPriority) {
                        ForEach(viewModel.priorities, id: \.self) { priority in
                            Text(priority).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 分类选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("分类")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Picker("分类", selection: $viewModel.selectedCategory) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("目标设置")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // 目标列表
                ForEach(Array(viewModel.goals.enumerated()), id: \.offset) { index, goal in
                    HStack {
                        TextField("目标 \(index + 1)", text: Binding(
                            get: { viewModel.goals[index] },
                            set: { viewModel.goals[index] = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 16, weight: .medium))
                        
                        Button(action: {
                            viewModel.removeGoal(at: index)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .disabled(viewModel.goals.count <= 1)
                    }
                }
                
                // 添加目标按钮
                Button(action: {
                    viewModel.addGoal()
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("添加目标")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                }
                .disabled(viewModel.goals.count >= 10)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 248/255, green: 250/255, blue: 252/255),
                Color(red: 241/255, green: 245/255, blue: 249/255)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Helper Methods

extension CreatePlanView {
    private func handleCreatePlan() async {
        if await viewModel.createPlan() {
            let plan = createPlanFromViewModel()
            await onPlanCreated(plan)
            dismiss()
        }
    }

    private func createPlanFromViewModel() -> PlanNew {
        // 计算结束时间：如果设置了结束时间则使用，否则根据预估时间计算
        let calculatedEndDate: Date
        if viewModel.hasEndDate {
            calculatedEndDate = viewModel.endDate
        } else {
            // 根据预估时间计算结束时间
            let baseTime = viewModel.hasReminderTime ? viewModel.reminderTime : viewModel.startDate
            let estimatedTimeInSeconds = TimeInterval(viewModel.estimatedTime * 60)
            calculatedEndDate = baseTime.addingTimeInterval(estimatedTimeInSeconds)
        }

        return PlanNew(
            title: viewModel.title,
            description: viewModel.description.isEmpty ? "无描述" : viewModel.description,
            category: viewModel.selectedCategory,
            startDate: viewModel.startDate,
            endDate: calculatedEndDate,
            isActive: true,
            progress: 0.0
        )
    }
}

// MARK: - Preview
struct CreatePlanView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePlanView { _ in }
    }
}
