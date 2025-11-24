import SwiftUI

/// 消息选择界面
struct MessageSelectionView: View {
    @StateObject private var viewModel = MessageSelectionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let conversationId: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 消息列表
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.messages.isEmpty {
                    emptyView
                } else {
                    messagesList
                }
                
                // 底部操作栏
                bottomActionBar
            }
            .navigationTitle("选择分享消息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.generatePoster()
                    } label: {
                        if viewModel.isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("生成海报")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.selectedMessageIds.isEmpty || viewModel.isGenerating)
                }
            }
            .alert("提示", isPresented: $viewModel.showAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .sheet(isPresented: $viewModel.showPosterPreview) {
                if let posterUrl = viewModel.generatedPosterUrl {
                    PosterPreviewView(
                        posterUrl: posterUrl,
                        shareUrl: viewModel.generatedShareUrl,
                        onDismiss: {
                            dismiss()
                        }
                    )
                }
            }
        }
        .onAppear {
            viewModel.loadMessages(conversationId: conversationId)
        }
    }
    
    // MARK: - 加载视图
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("加载消息中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 空状态视图
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            Text("暂无消息")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("开始对话后即可分享消息")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 消息列表
    
    private var messagesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.messages) { message in
                    MessageSelectionRow(
                        message: message,
                        isSelected: viewModel.selectedMessageIds.contains(message.id)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.toggleSelection(message.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - 底部操作栏
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // 已选择数量
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                    
                    Text("已选择 \(viewModel.selectedMessageIds.count) 条")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    if viewModel.selectedMessageIds.count > 0 {
                        Text("/ 最多 10 条")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 全选按钮
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectAll()
                    }
                } label: {
                    Text("全选")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.selectedMessageIds.count == viewModel.messages.count || viewModel.messages.isEmpty)
                
                // 清空按钮
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.clearSelection()
                    }
                } label: {
                    Text("清空")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .disabled(viewModel.selectedMessageIds.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -2)
    }
}

// MARK: - 消息选择行

/// 消息选择行视图
struct MessageSelectionRow: View {
    let message: HealthChatMessage
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 选择标记
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray.opacity(0.5))
                .font(.title3)
                .frame(width: 24, height: 24)
            
            // 消息内容
            VStack(alignment: .leading, spacing: 8) {
                // 显示消息内容
                HStack(alignment: .top, spacing: 6) {
                    Text(message.isUser ? "我：" : "AI：")
                        .font(.caption)
                        .foregroundColor(message.isUser ? .secondary : .blue)
                        .fontWeight(.medium)

                    Text(message.content)
                        .font(.body)
                        .foregroundColor(message.isUser ? .primary : .secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // 时间
                Text(formatDate(message.createdAt ?? message.timestamp ?? ""))
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.3) : Color(.separator).opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods

    private func formatDate(_ dateString: String) -> String {
        // 解析日期字符串
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var date: Date?

        // 尝试 ISO8601 格式
        if let parsedDate = isoFormatter.date(from: dateString) {
            date = parsedDate
        } else {
            // 尝试其他格式
            let standardFormatter = DateFormatter()
            standardFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let parsedDate = standardFormatter.date(from: dateString) {
                date = parsedDate
            } else {
                standardFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                date = standardFormatter.date(from: dateString)
            }
        }

        guard let validDate = date else {
            return dateString // 如果无法解析，返回原始字符串
        }

        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(validDate) {
            formatter.dateFormat = "HH:mm"
            return "今天 " + formatter.string(from: validDate)
        } else if calendar.isDateInYesterday(validDate) {
            formatter.dateFormat = "HH:mm"
            return "昨天 " + formatter.string(from: validDate)
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: validDate)
        }
    }
}

// MARK: - 预览

#if DEBUG
struct MessageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        MessageSelectionView(conversationId: "test-conversation-id")
    }
}
#endif

