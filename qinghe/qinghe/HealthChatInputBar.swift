import SwiftUI

/// 健康管理页面底部聊天输入栏（简化版）
struct ChatInputBar: View {
    @Binding var text: String
    var onSend: () -> Void
    @Binding var showingActionMenu: Bool // 是否显示操作菜单
    @FocusState.Binding var isInputFocused: Bool // 输入框焦点状态

    var body: some View {
        HStack(spacing: 12) {
            // 文本输入框（圆角胶囊）
            HStack(spacing: 10) {
                TextField("有什么健康问题问我吗", text: $text, axis: .vertical)
                    .focused($isInputFocused)
                    .lineLimit(1...4)
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.85))
                    .frame(minHeight: 22) // 设置最小高度确保单行居中
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44) // 确保整体有足够的点击区域
            .background(
                ZStack {
                    // 底层毛玻璃
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                    // 白色雾化蒙层（提升白感）
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                    // 轻描边
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 0.6)
                }
                .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 8)
            )

            // 功能按钮（+ 号或发送）
            Button(action: {
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // 输入框为空，显示/隐藏菜单
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingActionMenu.toggle()
                    }
                } else {
                    // 输入框有内容，发送消息
                    onSend()
                }
            }) {
                ZStack {
                    Circle().fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)

                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // 显示 + 号
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(hex: "131A38"))
                            .rotationEffect(.degrees(showingActionMenu ? 45 : 0))
                    } else {
                        // 显示发送图标
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(hex: "131A38"))
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        // 让整个输入栏在背景板内上下各留 4pt
        .padding(.vertical, 4)

    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        @State private var showMenu = false
        @FocusState private var isFocused: Bool
        
        var body: some View {
            ChatInputBar(text: $text, onSend: {}, showingActionMenu: $showMenu, isInputFocused: $isFocused)
                .background(
                    LinearGradient(colors: [Color(hex: "C3E88D"), Color(hex: "B2F0E1"), Color(hex: "FFE485")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        }
    }
    
    return PreviewWrapper()
}
