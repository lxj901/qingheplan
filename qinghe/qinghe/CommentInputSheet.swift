import SwiftUI

// MARK: - 评论输入弹窗
struct CommentInputSheet: View {
    let postId: String
    let replyingToComment: Comment?
    let onSubmit: (String) async -> Bool // 修改为返回Bool的async方法

    @State private var commentText = ""
    @State private var isSubmitting = false // 添加提交状态
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool

    private var isReply: Bool {
        replyingToComment != nil
    }

    private var titleText: String {
        if let replyComment = replyingToComment {
            return "回复 @\(replyComment.author.nickname)"
        } else {
            return "写评论"
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)

                    Spacer()

                    Text(titleText)
                        .font(.system(size: 16, weight: .semibold))

                    Spacer()

                    Button(isSubmitting ? "发布中..." : "发布") {
                        Task {
                            isSubmitting = true
                            let success = await onSubmit(commentText)
                            if success {
                                dismiss()
                            } else {
                                isSubmitting = false
                                // 可以在这里显示错误提示
                            }
                        }
                    }
                    .foregroundColor(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting ? .secondary : AppConstants.Colors.primaryGreen)
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)

                Divider()

                // 回复信息提示（如果是回复）
                if let replyComment = replyingToComment {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("回复")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Text("@\(replyComment.author.nickname)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppConstants.Colors.primaryGreen)

                            Spacer()
                        }

                        Text(replyComment.content)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.leading, 8)
                            .overlay(
                                Rectangle()
                                    .fill(AppConstants.Colors.primaryGreen)
                                    .frame(width: 2)
                                    .padding(.leading, 2),
                                alignment: .leading
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.05))

                    Divider()
                }

                // 输入区域
                VStack(alignment: .leading, spacing: 16) {
                    TextEditor(text: $commentText)
                        .focused($isTextFieldFocused)
                        .font(.system(size: 16))
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)

                    Text("\(commentText.count)/500")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)

                Spacer()
            }
            .background(Color.gray.opacity(0.05))
            .onAppear {
                // 每次打开都重置输入框状态
                commentText = ""

                // 如果是回复，自动添加@用户名
                if let replyComment = replyingToComment {
                    commentText = "@\(replyComment.author.nickname) "
                }

                // 延迟设置焦点，确保视图完全加载后再调起键盘
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}

#Preview {
    CommentInputSheet(
        postId: "1",
        replyingToComment: nil,
        onSubmit: { content in
            print("提交评论: \(content)")
            return true
        }
    )
}
