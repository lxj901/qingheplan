import SwiftUI

// MARK: - 导出格式枚举
enum ExportFormat: String, CaseIterable, Codable {
    case json = "json"
    case txt = "txt"
    case download = "download"

    var displayName: String {
        switch self {
        case .json:
            return "JSON 格式"
        case .txt:
            return "文本格式"
        case .download:
            return "下载文件"
        }
    }

    var description: String {
        switch self {
        case .json:
            return "结构化数据，适合程序处理"
        case .txt:
            return "纯文本格式，便于阅读"
        case .download:
            return "直接下载文件到设备"
        }
    }

    var iconName: String {
        switch self {
        case .json:
            return "doc.text"
        case .txt:
            return "doc.plaintext"
        case .download:
            return "arrow.down.doc"
        }
    }

    var color: Color {
        switch self {
        case .json:
            return .blue
        case .txt:
            return .green
        case .download:
            return .orange
        }
    }
}

/// 聊天记录导出视图
struct ChatExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChatExportViewModel
    
    let conversationId: String
    let conversationTitle: String
    
    @State private var selectedFormat: ExportFormat = .json
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var showingDatePicker = false
    @State private var datePickerType: DatePickerType = .start
    
    init(conversationId: String, conversationTitle: String) {
        self.conversationId = conversationId
        self.conversationTitle = conversationTitle
        self._viewModel = StateObject(wrappedValue: ChatExportViewModel(conversationId: conversationId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 导出选项
            exportOptionsSection
            
            Divider()
            
            // 导出预览/状态
            exportStatusSection
            
            Spacer()
            
            // 底部按钮
            bottomButtons
        }
        .navigationTitle("导出聊天记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("帮助") {
                    // TODO: 显示导出帮助信息
                }
            }
        }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(
                    selectedDate: datePickerType == .start ? $startDate : $endDate,
                    title: datePickerType == .start ? "选择开始日期" : "选择结束日期"
                )
            }
            .alert("导出失败", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("确定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
    }
    
    // MARK: - 导出选项
    private var exportOptionsSection: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // 对话信息
            conversationInfoCard
            
            // 导出格式选择
            formatSelectionSection
            
            // 时间范围选择
            dateRangeSection
            
            // 导出预览信息
            exportPreviewInfo
        }
        .padding(ModernDesignSystem.Spacing.md)
    }
    
    private var conversationInfoCard: some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // 对话图标
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 24))
                .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                .frame(width: 40, height: 40)
                .background(ModernDesignSystem.Colors.primaryGreen.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(conversationTitle)
                    .font(ModernDesignSystem.Typography.headline)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                
                Text("导出聊天记录")
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(ModernDesignSystem.Spacing.md)
        .background(ModernDesignSystem.Colors.backgroundSecondary)
        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
    }
    
    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
            Text("导出格式")
                .font(ModernDesignSystem.Typography.subheadline)
                .foregroundColor(ModernDesignSystem.Colors.textPrimary)
            
            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    formatSelectionRow(format, isSelected: selectedFormat == format) {
                        selectedFormat = format
                    }
                }
            }
        }
    }
    
    private func formatSelectionRow(_ format: ExportFormat, isSelected: Bool, onSelect: @escaping () -> Void) -> some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // 格式图标
            Image(systemName: format.iconName)
                .font(.system(size: 20))
                .foregroundColor(format.color)
                .frame(width: 32, height: 32)
                .background(format.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(format.displayName)
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                
                Text(format.description)
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            // 选择状态
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? ModernDesignSystem.Colors.primaryGreen : ModernDesignSystem.Colors.textTertiary)
                .font(.system(size: 20))
        }
        .padding(ModernDesignSystem.Spacing.sm)
        .background(isSelected ? ModernDesignSystem.Colors.primaryGreen.opacity(0.05) : Color.clear)
        .cornerRadius(ModernDesignSystem.CornerRadius.md)
        .onTapGesture {
            onSelect()
        }
    }
    
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
            Text("时间范围")
                .font(ModernDesignSystem.Typography.subheadline)
                .foregroundColor(ModernDesignSystem.Colors.textPrimary)
            
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                // 开始日期
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                    Text("开始日期")
                        .font(ModernDesignSystem.Typography.caption1)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    
                    Button {
                        datePickerType = .start
                        showingDatePicker = true
                    } label: {
                        Text(formatDate(startDate))
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                            .padding(ModernDesignSystem.Spacing.sm)
                            .frame(maxWidth: .infinity)
                            .background(ModernDesignSystem.Colors.backgroundSecondary)
                            .cornerRadius(ModernDesignSystem.CornerRadius.md)
                    }
                }
                
                // 结束日期
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                    Text("结束日期")
                        .font(ModernDesignSystem.Typography.caption1)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    
                    Button {
                        datePickerType = .end
                        showingDatePicker = true
                    } label: {
                        Text(formatDate(endDate))
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                            .padding(ModernDesignSystem.Spacing.sm)
                            .frame(maxWidth: .infinity)
                            .background(ModernDesignSystem.Colors.backgroundSecondary)
                            .cornerRadius(ModernDesignSystem.CornerRadius.md)
                    }
                }
            }
        }
    }
    
    private var exportPreviewInfo: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
            Text("导出信息")
                .font(ModernDesignSystem.Typography.subheadline)
                .foregroundColor(ModernDesignSystem.Colors.textPrimary)
            
            HStack {
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                    Text("预计消息数量")
                        .font(ModernDesignSystem.Typography.caption1)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    
                    Text(viewModel.estimatedMessageCount > 0 ? "\(viewModel.estimatedMessageCount) 条" : "计算中...")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: ModernDesignSystem.Spacing.xs) {
                    Text("预计文件大小")
                        .font(ModernDesignSystem.Typography.caption1)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    
                    Text(viewModel.estimatedFileSize.isEmpty ? "计算中..." : viewModel.estimatedFileSize)
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                }
            }
            .padding(ModernDesignSystem.Spacing.md)
            .background(ModernDesignSystem.Colors.backgroundSecondary)
            .cornerRadius(ModernDesignSystem.CornerRadius.md)
        }
    }
    
    // MARK: - 导出状态
    private var exportStatusSection: some View {
        Group {
            if viewModel.isExporting {
                exportingView
            } else if viewModel.exportCompleted {
                exportCompletedView
            } else {
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var exportingView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // 进度指示器
            VStack(spacing: ModernDesignSystem.Spacing.md) {
                ProgressView(value: viewModel.exportProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(y: 2)
                
                Text("\(Int(viewModel.exportProgress * 100))%")
                    .font(ModernDesignSystem.Typography.headline)
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
            }
            
            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                Text("正在导出聊天记录...")
                    .font(ModernDesignSystem.Typography.subheadline)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                
                Text("请稍候，这可能需要几分钟时间")
                    .font(ModernDesignSystem.Typography.caption1)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }
        }
        .padding(ModernDesignSystem.Spacing.xl)
    }
    
    private var exportCompletedView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // 成功图标
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
            
            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                Text("导出完成")
                    .font(ModernDesignSystem.Typography.title2)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                
                Text("聊天记录已成功导出")
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }
            
            // 导出文件信息
            if let exportInfo = viewModel.exportInfo {
                exportFileInfoCard(exportInfo)
            }
        }
        .padding(ModernDesignSystem.Spacing.xl)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 48))
                .foregroundColor(ModernDesignSystem.Colors.textTertiary)
            
            VStack(spacing: ModernDesignSystem.Spacing.sm) {
                Text("准备导出")
                    .font(ModernDesignSystem.Typography.headline)
                    .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                
                Text("选择导出格式和时间范围，然后点击开始导出")
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(ModernDesignSystem.Spacing.xl)
    }
    
    private func exportFileInfoCard(_ info: ExportInfo) -> some View {
        VStack(spacing: ModernDesignSystem.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                    Text("文件名")
                        .font(ModernDesignSystem.Typography.caption1)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    
                    Text(info.fileName)
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: ModernDesignSystem.Spacing.xs) {
                    Text("文件大小")
                        .font(ModernDesignSystem.Typography.caption1)
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    
                    Text(info.fileSize)
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                }
            }
            
            // 分享按钮
            Button {
                shareExportedFile(info)
            } label: {
                HStack(spacing: ModernDesignSystem.Spacing.sm) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                    
                    Text("分享文件")
                        .font(ModernDesignSystem.Typography.body)
                }
                .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                .padding(ModernDesignSystem.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(ModernDesignSystem.Colors.primaryGreen.opacity(0.1))
                .cornerRadius(ModernDesignSystem.CornerRadius.md)
            }
        }
        .padding(ModernDesignSystem.Spacing.md)
        .background(ModernDesignSystem.Colors.backgroundSecondary)
        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
    }
    
    // MARK: - 底部按钮
    private var bottomButtons: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            if viewModel.exportCompleted {
                // 重新导出按钮
                Button {
                    viewModel.resetExport()
                } label: {
                    Text("重新导出")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.primaryGreen)
                        .padding(ModernDesignSystem.Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background(ModernDesignSystem.Colors.primaryGreen.opacity(0.1))
                        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
                }
            } else if viewModel.isExporting {
                // 取消导出按钮
                Button {
                    viewModel.cancelExport()
                } label: {
                    Text("取消导出")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.textPrimary)
                        .padding(ModernDesignSystem.Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background(ModernDesignSystem.Colors.backgroundSecondary)
                        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
                }
            } else {
                // 开始导出按钮
                Button {
                    Task {
                        await startExport()
                    }
                } label: {
                    Text("开始导出")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(.white)
                        .padding(ModernDesignSystem.Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background(ModernDesignSystem.Colors.primaryGreen)
                        .cornerRadius(ModernDesignSystem.CornerRadius.lg)
                }
                .disabled(!isValidDateRange)
            }
        }
        .padding(ModernDesignSystem.Spacing.md)
    }
    
    // MARK: - 私有方法
    
    private var isValidDateRange: Bool {
        startDate <= endDate
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func startExport() async {
        await viewModel.startExport(
            format: selectedFormat,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    private func shareExportedFile(_ info: ExportInfo) {
        // TODO: 实现文件分享功能
    }
}

// MARK: - 日期选择器类型
enum DatePickerType {
    case start
    case end
}

// MARK: - 日期选择器Sheet
struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    let title: String
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    title,
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 预览
#Preview {
    ChatExportView(
        conversationId: "test-conversation",
        conversationTitle: "测试群聊"
    )
}