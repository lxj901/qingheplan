import SwiftUI

struct TemptationDetailView: View {
    let temptation: TemptationNew
    @StateObject private var viewModel = TemptationDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 基本信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text("诱惑详情")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text("类型:")
                                .fontWeight(.medium)
                            Text(temptation.type)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack {
                            Text("强度:")
                                .fontWeight(.medium)
                            Text("\(temptation.intensity)/10")
                                .foregroundColor(intensityColor(temptation.intensity))
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        HStack {
                            Text("结果:")
                                .fontWeight(.medium)
                            Text(temptation.resisted ? "已抵抗住" : "未抵抗住")
                                .foregroundColor(resultColor(temptation.resisted ? "已抵抗住" : "未抵抗住"))
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        HStack {
                            Text("记录时间:")
                                .fontWeight(.medium)
                            Text(formatDateString(temptation.createdAt))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 备注
                    if let note = temptation.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("备注")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text(note)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // 应对策略
                    if let strategy = temptation.strategy, !strategy.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("应对策略")
                                .font(.headline)
                                .fontWeight(.bold)

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(strategy)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("诱惑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("编辑") {
                        // TODO: 实现编辑功能
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func intensityColor(_ intensity: Int) -> Color {
        switch intensity {
        case 1...3:
            return .green
        case 4...6:
            return .orange
        case 7...10:
            return .red
        default:
            return .gray
        }
    }
    
    private func resultColor(_ result: String) -> Color {
        switch result.lowercased() {
        case "抵抗成功", "成功抵抗":
            return .green
        case "部分抵抗":
            return .orange
        case "完全屈服", "屈服":
            return .red
        default:
            return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func formatDateString(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.locale = Locale(identifier: "zh_CN")

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Preview

struct TemptationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TemptationDetailView(temptation: TemptationNew(
            id: 1,
            userId: 1,
            type: "社交媒体",
            intensity: 7,
            resisted: true,
            strategy: "深呼吸",
            environment: "办公室",
            duration: 30,
            note: "今天工作压力很大，想要刷手机放松，但是想到自己的目标，最终还是抵抗住了诱惑。",
            recordedAt: "2025-01-15T14:30:00Z",
            createdAt: "2025-01-15T14:30:00Z",
            updatedAt: "2025-01-15T14:30:00Z"
        ))
    }
}
