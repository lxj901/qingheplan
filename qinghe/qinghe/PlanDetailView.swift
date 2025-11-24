import SwiftUI

struct PlanDetailView: View {
    let plan: PlanNew
    let onPlanUpdated: (PlanNew) async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PlanDetailViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 详情内容
                    contentSection
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("计划详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .task {
            await viewModel.loadPlanDetails(plan.id)
        }
        .alert("操作失败", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
    }
    
    
    // MARK: - 内容区域
    private var contentSection: some View {
        LazyVStack(spacing: 1) {
            // 基本信息
            infoSection
            
            // 计划描述
            if !plan.description.isEmpty {
                descriptionSection(plan.description)
            }
            
            // 时间信息
            timeSection
        }
        .padding(.top, 0)
    }
    
    // MARK: - 信息块组件
    private var infoSection: some View {
        VStack(spacing: 0) {
            infoRow(label: "计划分类", value: plan.category, isFirst: true)
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("计划描述")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(description)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private var timeSection: some View {
        VStack(spacing: 0) {
            infoRow(label: "结束时间", value: formatDateFromDate(plan.endDate), isFirst: true)
            infoRow(label: "提醒时间", value: formatReminderTime(), isFirst: false)
            infoRow(label: "创建时间", value: formatDateFromDate(plan.startDate), isFirst: false)
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 32)
    }
    
    // MARK: - 通用信息行
    private func infoRow(label: String, value: String, isFirst: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
                .padding(.leading, 16),
            alignment: .bottom
        )
        .opacity(isFirst ? 1 : 1)
    }
    
    // MARK: - 辅助方法
    private var planColor: Color {
        switch plan.category {
        case "工作": return .blue
        case "学习": return .purple
        case "生活": return .green
        case "健康": return .mint
        case "娱乐": return .orange
        default: return .gray
        }
    }
    
    private var statusColor: Color {
        if plan.progress >= 1.0 {
            return .green
        } else if plan.isActive {
            return .blue
        } else {
            return .orange
        }
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
    
    private var categoryEmoji: String {
        switch plan.category {
        case "工作": return "💼"
        case "学习": return "📚"
        case "生活": return "🏠"
        case "健康": return "❤️"
        case "娱乐": return "🎮"
        case "兴趣": return "🎨"
        case "社交": return "👥"
        default: return "📋"
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM月dd日 HH:mm"
            return displayFormatter.string(from: date)
        }

        return dateString
    }

    private func formatDateFromDate(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return displayFormatter.string(from: date)
    }

    private func formatReminderTime() -> String {
        // 从本地存储获取提醒时间
        if let reminderTime = PlanReminderManager.shared.getReminderTime(for: plan.title) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
            return displayFormatter.string(from: reminderTime)
        } else {
            return "未设置"
        }
    }
}

// MARK: - 预览
struct PlanDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PlanDetailView(
            plan: PlanNew(
                title: "学习SwiftUI开发",
                description: "系统学习SwiftUI框架，掌握现代iOS开发技能，包括UI布局、数据绑定、动画效果等核心概念。",
                category: "学习",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
                isActive: true,
                progress: 0.65,
                goals: ["掌握基础语法", "完成项目实战", "理解架构模式"]
            ),
            onPlanUpdated: { _ in }
        )
    }
}