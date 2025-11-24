import SwiftUI

// MARK: - 举报帖子视图
struct ReportPostView: View {
    let postId: String
    let onReport: (ReportReason, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason = .spam
    @State private var description: String = ""
    @State private var isSubmitting: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题说明
                VStack(alignment: .leading, spacing: 8) {
                    Text("举报原因")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("请选择举报的原因，我们会认真处理您的反馈")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                
                // 举报原因选择
                VStack(spacing: 0) {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        Button(action: {
                            selectedReason = reason
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reason.displayName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text(getReasonDescription(reason))
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedReason == reason ? .blue : .secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(Color(.systemBackground))
                        
                        if reason != ReportReason.allCases.last {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                
                // 详细描述
                VStack(alignment: .leading, spacing: 8) {
                    Text("详细描述（可选）")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    TextEditor(text: $description)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(minHeight: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // 提交按钮
                Button(action: submitReport) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        
                        Text(isSubmitting ? "提交中..." : "提交举报")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSubmitting)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("举报内容")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                print("✅ ReportPostView: 页面已显示，帖子ID: \(postId)")
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func getReasonDescription(_ reason: ReportReason) -> String {
        switch reason {
        case .spam:
            return "垃圾广告、重复内容等"
        case .inappropriate:
            return "不当言论、低俗内容等"
        case .harassment:
            return "恶意骚扰、人身攻击等"
        case .violence:
            return "暴力威胁、危险行为等"
        case .copyright:
            return "侵犯版权、盗用内容等"
        case .other:
            return "其他违规行为"
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        
        // 模拟网络请求延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onReport(selectedReason, description.isEmpty ? nil : description)
            isSubmitting = false
            dismiss()
        }
    }
}

// MARK: - 预览
#Preview {
    ReportPostView(postId: "test_post") { reason, description in
        print("举报原因: \(reason.displayName)")
        if let desc = description {
            print("详细描述: \(desc)")
        }
    }
}
