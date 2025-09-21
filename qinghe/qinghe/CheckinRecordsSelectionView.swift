import SwiftUI

struct CheckinRecordsSelectionView: View {
    let onSelection: (CheckinDataForPost?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCheckin: CheckinDataForPost?
    
    // 从 API 获取的打卡数据
    @State private var checkinRecords: [CheckinDataForPost] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // 打卡数据服务
    private let checkinService = CheckinService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("加载打卡记录中...")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("加载失败")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("重试") {
                            loadCheckinRecords()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if checkinRecords.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("暂无打卡记录")
                            .font(.headline)
                        Text("完成打卡后，记录会显示在这里")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        Section("选择打卡记录") {
                            ForEach(checkinRecords, id: \.id) { checkin in
                                CheckinRecordRow(checkin: checkin, isSelected: selectedCheckin?.id == checkin.id)
                                    .onTapGesture {
                                        selectedCheckin = checkin
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("打卡记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onSelection(nil)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        onSelection(selectedCheckin)
                    }
                    .disabled(selectedCheckin == nil)
                }
            }
            .onAppear {
                loadCheckinRecords()
            }
            .refreshable {
                loadCheckinRecords()
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadCheckinRecords() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 获取最近的打卡记录
                let records = try await checkinService.getCheckinHistory(page: 1, limit: 20)
                
                // 获取统计数据
                let statsResponse = try await checkinService.getStatistics()
                
                // 转换为 CheckinDataForPost 格式
                let checkinData = records.compactMap { record in
                    CheckinDataForPost.from(
                        apiRecord: record,
                        stats: statsResponse.data
                    )
                }
                
                await MainActor.run {
                    self.checkinRecords = checkinData
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct CheckinRecordRow: View {
    let checkin: CheckinDataForPost
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(checkin.displayText)
                    .font(.headline)
                
                if let location = checkin.location {
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let note = checkin.note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Label("连续\(checkin.consecutiveDays)天", systemImage: "flame")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Label("总计\(checkin.totalDays)天", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Extensions

extension CheckinDataForPost {
    static func from(apiRecord: CheckinAPIRecord, stats: CheckinStatistics?) -> CheckinDataForPost? {
        // 解析日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: apiRecord.date) else {
            return nil
        }
        
        // 构建位置信息
        let location = apiRecord.locationAddress?.isEmpty == false ? apiRecord.locationAddress : nil
        
        // 获取统计数据
        let consecutiveDays = stats?.consecutiveDays ?? 0
        let totalDays = stats?.totalDays ?? 0
        
        return CheckinDataForPost(
            checkinId: apiRecord.id, // 使用真正的打卡记录ID
            date: date,
            location: location,
            note: apiRecord.note?.isEmpty == false ? apiRecord.note : nil,
            consecutiveDays: consecutiveDays,
            totalDays: totalDays
        )
    }
}

#Preview {
    CheckinRecordsSelectionView { checkinData in
        print("Selected checkin: \(checkinData?.displayText ?? "none")")
    }
}
