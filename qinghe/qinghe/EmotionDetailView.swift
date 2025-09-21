import SwiftUI

struct EmotionDetailView: View {
    let emotion: EmotionNew
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EmotionDetailViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 详情内容
                    contentSection
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("情绪记录")
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
            
            // 触发因素
            if let trigger = emotion.trigger, !trigger.isEmpty {
                triggerSection(trigger)
            }
            
            // 标签
            if let tags = emotion.tags, !tags.isEmpty {
                tagsSection(tags)
            }
            
            // 备注
            if let note = emotion.note, !note.isEmpty {
                noteSection(note)
            }
            
            // 记录时间
            timeSection
        }
        .padding(.top, 0)
    }
    
    // MARK: - 信息块组件
    private var infoSection: some View {
        VStack(spacing: 0) {
            infoRow(label: "情绪类型", value: emotion.type, isFirst: true)
            infoRow(label: "强度等级", value: "\(emotion.intensity) / 10", isFirst: false)
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    private func triggerSection(_ trigger: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("触发因素")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(trigger)
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
    
    private func tagsSection(_ tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("相关标签")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(emotionColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(emotionColor.opacity(0.1))
                        .cornerRadius(16)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private func noteSection(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("备注")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(note)
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
            infoRow(label: "记录时间", value: formatDate(emotion.recordedAt), isFirst: true)
            infoRow(label: "创建时间", value: formatDate(emotion.createdAt), isFirst: false)
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
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
                .padding(.leading, 16),
            alignment: .bottom
        )
        .opacity(isFirst ? 1 : 1)
    }
    
    // MARK: - 辅助方法
    private var emotionColor: Color {
        switch emotion.type {
        case "开心", "兴奋", "满足": return .green
        case "悲伤", "难过", "沮丧": return .blue
        case "愤怒", "紧张": return .red
        case "焦虑", "困惑": return .orange
        case "平静", "放松": return .mint
        default: return .gray
        }
    }
    
    private var emotionEmoji: String {
        switch emotion.type {
        case "开心": return "😊"
        case "悲伤", "难过": return "😢"
        case "愤怒": return "😠"
        case "焦虑": return "😰"
        case "平静": return "😌"
        case "兴奋": return "🤩"
        case "沮丧": return "😔"
        case "紧张": return "😬"
        case "放松": return "😴"
        case "满足": return "😌"
        case "困惑": return "😕"
        default: return "😐"
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
}

// MARK: - 预览
struct EmotionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionDetailView(emotion: EmotionNew(
            id: 1,
            userId: 1,
            type: "开心",
            intensity: 8,
            note: "今天成功完成了一个重要的项目里程碑，团队合作很愉快，感觉很有成就感。",
            tags: ["工作", "成就感", "满足"],
            trigger: "完成了重要的项目任务",
            recordedAt: "2025-01-29T14:30:00.000Z",
            createdAt: "2025-01-29T14:30:00.000Z",
            updatedAt: "2025-01-29T14:30:00.000Z"
        ))
    }
}