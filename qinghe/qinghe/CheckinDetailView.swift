import SwiftUI

/// 打卡详情视图
struct CheckinDetailView: View {
    let checkinRecord: CheckinAPIRecord?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let record = checkinRecord {
                    // 有打卡记录时显示详情
                    checkinDetailContent(record)
                } else {
                    // 没有打卡记录时显示空状态
                    emptyStateView
                }
            }
            .navigationTitle("打卡详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 打卡详情内容
    @ViewBuilder
    private func checkinDetailContent(_ record: CheckinAPIRecord) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // 打卡时间卡片
                timeCard(record)
                
                // 打卡信息卡片
                infoCard(record)
                
                // 位置信息卡片（如果有）
                if record.locationAddress != nil || (record.locationLatitude != nil && record.locationLongitude != nil) {
                    locationCard(record)
                }
                
                // 备注信息卡片（如果有）
                if let note = record.note, !note.isEmpty {
                    noteCard(note)
                }
                
                // 心情和挑战卡片（如果有）
                if record.mood != nil || record.challenges != nil {
                    moodChallengeCard(record)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 时间卡片
    @ViewBuilder
    private func timeCard(_ record: CheckinAPIRecord) -> some View {
        VStack(spacing: 16) {
            // 打卡成功图标
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
            
            VStack(spacing: 8) {
                Text("打卡成功")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(formatDate(record.date))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(formatTime(record.time))
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 信息卡片
    @ViewBuilder
    private func infoCard(_ record: CheckinAPIRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("打卡信息")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                if let deviceInfo = record.deviceInfo {
                    infoRow(icon: "iphone", title: "设备信息", value: deviceInfo)
                }
                
                if let ipAddress = record.ipAddress {
                    infoRow(icon: "network", title: "IP地址", value: ipAddress)
                }
                
                infoRow(icon: "calendar", title: "打卡日期", value: formatDate(record.date))
                infoRow(icon: "clock", title: "打卡时间", value: formatTime(record.time))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 位置卡片
    @ViewBuilder
    private func locationCard(_ record: CheckinAPIRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("位置信息")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                if let address = record.locationAddress {
                    infoRow(icon: "location", title: "地址", value: address)
                }
                
                if let latitude = record.locationLatitude, let longitude = record.locationLongitude {
                    infoRow(icon: "location.circle", title: "坐标", value: String(format: "%.6f, %.6f", latitude, longitude))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 备注卡片
    @ViewBuilder
    private func noteCard(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("打卡备注")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(note)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 心情和挑战卡片
    @ViewBuilder
    private func moodChallengeCard(_ record: CheckinAPIRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("心情与挑战")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                if let mood = record.mood {
                    infoRow(icon: "face.smiling", title: "心情", value: mood)
                }
                
                if let challenges = record.challenges {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(ModernDesignSystem.Colors.accentOrange)
                                .frame(width: 20)
                            Text("挑战描述")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Text(challenges)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 28)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 信息行
    @ViewBuilder
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
    
    // MARK: - 空状态视图
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无打卡记录")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("今天还没有打卡记录")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 辅助方法
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy年M月d日"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
    
    private func formatTime(_ timeString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm:ss"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH:mm"
        
        if let time = inputFormatter.date(from: timeString) {
            return outputFormatter.string(from: time)
        }
        return timeString
    }
}

#Preview {
    CheckinDetailView(checkinRecord: nil)
}
