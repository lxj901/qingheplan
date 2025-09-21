import SwiftUI

// MARK: - StatItem Component
struct StatItem: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)

            Text(unit)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - PlanCardView Component
struct PlanCardView: View {
    let plan: Plan
    let onTap: () -> Void
    let onToggleStatus: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(plan.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Menu {
                    Button(plan.isActive ? "暂停" : "激活") {
                        onToggleStatus()
                    }

                    Button("删除", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }

            // 进度条
            ProgressView(value: plan.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: plan.isActive ? .blue : .gray))

            HStack {
                Text("\(Int(plan.progress * 100))% 完成")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(plan.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
}

struct PlanManagementView: View {
    @StateObject private var viewModel = PlanManagementViewModel()
    @State private var showingCreatePlan = false
    @State private var selectedPlan: Plan?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部统计卡片
                if let stats = viewModel.planStats {
                    planStatsCard(stats)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }
                
                // 计划列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.isLoading {
                            loadingView
                        } else if viewModel.plans.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(viewModel.plans, id: \.id) { plan in
                                planCardView(for: plan)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .refreshable {
                    await viewModel.loadPlans()
                }
            }
            .background(backgroundGradient)
            .navigationTitle("计划管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreatePlan = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            })
        }
        .task {
            await viewModel.loadPlans()
            await viewModel.loadPlanStats()
        }
        .sheet(isPresented: $showingCreatePlan) {
            CreatePlanView { newPlan in
                await viewModel.addPlan(newPlan)
            }
        }
        .sheet(item: $selectedPlan) { plan in
            PlanDetailView(plan: plan.toPlanNew()) { updatedPlan in
                await viewModel.updatePlan(updatedPlan)
            }
        }
        .alert("操作失败", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("加载计划中...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.gray)
            
            Text("还没有计划")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text("创建你的第一个计划，开始规划美好生活")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingCreatePlan = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("创建计划")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(24)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func planCardView(for plan: Plan) -> some View {
        PlanCardView(
            plan: plan,
            onTap: {
                selectedPlan = plan
            },
            onToggleStatus: {
                Task {
                    // 切换计划状态（暂停/激活）
                    var updatedPlan = plan
                    updatedPlan = Plan(
                        title: plan.title,
                        description: plan.description,
                        category: plan.category,
                        startDate: plan.startDate,
                        endDate: plan.endDate,
                        isActive: !plan.isActive,
                        progress: plan.progress,
                        reminderTime: plan.reminderTime
                    )
                    await viewModel.updatePlan(updatedPlan.toPlanNew())
                }
            },
            onDelete: {
                Task {
                    await viewModel.deletePlan(plan)
                }
            }
        )
    }

    private func planStatsCard(_ stats: PlanStats) -> some View {
        HStack(spacing: 16) {
            StatItem(
                title: "总计划",
                value: "\(stats.totalPlans)",
                unit: "个",
                color: .blue
            )
            
            StatItem(
                title: "进行中",
                value: "\(stats.activePlans)",
                unit: "个",
                color: .green
            )

            StatItem(
                title: "已完成",
                value: "\(stats.completedPlans)",
                unit: "个",
                color: .orange
            )

            StatItem(
                title: "完成率",
                value: "\(Int(stats.completionRate * 100))",
                unit: "%",
                color: .purple
            )
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

// MARK: - Supporting Views

struct PlanCard: View {
    let plan: SimplePlan
    let onTap: () -> Void
    let onToggleStatus: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 头部信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if !plan.description.isEmpty {
                        Text(plan.description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // 状态标签
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor)
                    .cornerRadius(16)
            }
            
            // 进度条
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("进度")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(plan.progress)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(statusColor)
                            .frame(width: geometry.size.width * CGFloat(plan.progress) / 100.0, height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
            
            // 时间信息
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(formatDateFromDate(plan.startDate))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(formatDateFromDate(plan.endDate))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                Button(action: onToggleStatus) {
                    HStack(spacing: 6) {
                        Image(systemName: statusText == "进行中" ? "pause.circle" : "play.circle")
                        Text(statusText == "进行中" ? "暂停" : "开始")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: onTap) {
                    Text("查看详情")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private var statusText: String {
        // 从本地存储获取提醒时间
        let reminderTime = PlanReminderManager.shared.getReminderTime(for: plan.title)

        // 创建 Plan 对象以使用状态管理器
        let planWithReminder = Plan(
            title: plan.title,
            description: plan.description,
            category: plan.category,
            startDate: plan.startDate,
            endDate: plan.endDate,
            isActive: plan.isActive,
            progress: plan.progress,
            reminderTime: reminderTime
        )

        // 使用状态管理器计算状态
        let status = PlanStatusManager.shared.calculatePlanStatus(for: planWithReminder)
        return status.displayName
    }

    private var statusColor: Color {
        // 从本地存储获取提醒时间
        let reminderTime = PlanReminderManager.shared.getReminderTime(for: plan.title)

        // 创建 Plan 对象以使用状态管理器
        let planWithReminder = Plan(
            title: plan.title,
            description: plan.description,
            category: plan.category,
            startDate: plan.startDate,
            endDate: plan.endDate,
            isActive: plan.isActive,
            progress: plan.progress,
            reminderTime: reminderTime
        )

        // 使用状态管理器计算状态
        let status = PlanStatusManager.shared.calculatePlanStatus(for: planWithReminder)

        switch status {
        case .completed:
            return .green
        case .inProgress:
            return .blue
        case .pending:
            return .orange
        case .cancelled:
            return .red
        case .expired:
            return .gray
        }
    }
    
    private func formatDate(_ dateString: String?) -> String? {
        guard let dateString = dateString else { return nil }
        
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return nil }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MM月dd日 HH:mm"
        displayFormatter.locale = Locale(identifier: "zh_CN")
        
        return displayFormatter.string(from: date)
    }

    private func formatDateFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}



// MARK: - Preview
struct PlanManagementView_Previews: PreviewProvider {
    static var previews: some View {
        PlanManagementView()
    }
}
