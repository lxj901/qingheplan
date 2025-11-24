import SwiftUI

/// 活动中心视图
struct ActivityCenterView: View {
    @StateObject private var viewModel = ActivityCenterViewModel()
    @State private var selectedTab = 0 // 0: 推荐活动, 1: 我参与的
    
    var body: some View {
        VStack(spacing: 0) {
            // 标签切换
            tabSelector
            
            // 活动列表
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if selectedTab == 0 {
                            // 推荐活动
                            if viewModel.activities.isEmpty {
                                emptyStateView(message: "暂无推荐活动")
                            } else {
                                ForEach(viewModel.activities, id: \.id) { activity in
                                    ActivityItemView(activity: activity)
                                }
                            }
                        } else {
                            // 我参与的活动
                            if viewModel.participatedActivities.isEmpty {
                                emptyStateView(message: "暂无参与的活动")
                            } else {
                                ForEach(viewModel.participatedActivities, id: \.id) { activity in
                                    ActivityItemView(activity: activity)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("活动广场")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadActivities()
        }
    }
    
    // MARK: - 标签选择器
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "推荐活动", index: 0)
            tabButton(title: "我参与的", index: 1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
                if index == 0 {
                    viewModel.loadActivities()
                } else {
                    viewModel.loadParticipatedActivities()
                }
            }
        }) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: selectedTab == index ? .semibold : .regular))
                    .foregroundColor(selectedTab == index ? .primary : .secondary)
                
                if selectedTab == index {
                    Rectangle()
                        .fill(AppConstants.Colors.primaryGreen)
                        .frame(width: 40, height: 3)
                        .cornerRadius(1.5)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 3)
                }
            }
        }
        .padding(.trailing, 24)
    }
    
    // MARK: - 空状态视图
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Text("敬请期待精彩活动")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 100)
    }
}

// MARK: - 活动项视图
struct ActivityItemView: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 封面图
            if let coverURL = URL(string: activity.coverImage) {
                AsyncImage(url: coverURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(height: 160)
                .clipped()
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(activity.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(activity.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 12))
                        Text("\(activity.participantsCount)人参与")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    statusBadge(status: activity.status)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func statusBadge(status: String) -> some View {
        let (text, color) = statusInfo(status: status)
        return Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(4)
    }
    
    private func statusInfo(status: String) -> (String, Color) {
        switch status {
        case "upcoming":
            return ("即将开始", .orange)
        case "ongoing":
            return ("进行中", .green)
        case "ended":
            return ("已结束", .gray)
        default:
            return ("未知", .gray)
        }
    }
}

// MARK: - 活动中心ViewModel
class ActivityCenterViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var participatedActivities: [Activity] = []
    @Published var isLoading: Bool = false
    
    func loadActivities() {
        isLoading = true
        Task {
            do {
                let list = try await CreatorAPIService.shared.fetchActivities(status: "ongoing")
                await MainActor.run {
                    self.activities = list
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("❌ 加载活动列表失败: \(error)")
            }
        }
    }
    
    func loadParticipatedActivities() {
        isLoading = true
        Task {
            do {
                let list = try await CreatorAPIService.shared.fetchParticipatedActivities()
                await MainActor.run {
                    self.participatedActivities = list
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("❌ 加载参与活动失败: \(error)")
            }
        }
    }
}

// MARK: - 活动数据模型
struct Activity: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
    let coverImage: String
    let startDate: String
    let endDate: String
    let status: String
    let participantsCount: Int
    let prizesInfo: String?
    let rules: String?
}

// MARK: - 预览
#Preview {
    NavigationStack {
        ActivityCenterView()
    }
}
