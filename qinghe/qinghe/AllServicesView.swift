import SwiftUI

/// 全部服务视图
struct AllServicesView: View {
    private let services = [
        ServiceItem(icon: "doc.text", title: "作品管理", description: "管理你的所有作品"),
        ServiceItem(icon: "chart.bar", title: "数据助手", description: "查看作品数据分析"),
        ServiceItem(icon: "dollarsign.circle", title: "收益提现", description: "查看和提现收益"),
        ServiceItem(icon: "flag", title: "活动广场", description: "参与平台活动"),
        ServiceItem(icon: "folder", title: "专栏管理", description: "管理你的专栏"),
        ServiceItem(icon: "person.2", title: "粉丝管理", description: "查看和管理粉丝"),
        ServiceItem(icon: "bell", title: "消息通知", description: "查看系统通知"),
        ServiceItem(icon: "gearshape", title: "创作设置", description: "设置创作偏好"),
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(services) { service in
                    ServiceItemView(service: service)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("全部服务")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 服务项视图
struct ServiceItemView: View {
    let service: ServiceItem
    
    var body: some View {
        Button(action: {
            // TODO: 处理服务点击
        }) {
            VStack(spacing: 12) {
                Image(systemName: service.icon)
                    .font(.system(size: 32))
                    .foregroundColor(AppConstants.Colors.primaryGreen)
                
                Text(service.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(service.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - 服务项数据模型
struct ServiceItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - 预览
#Preview {
    NavigationStack {
        AllServicesView()
    }
}

