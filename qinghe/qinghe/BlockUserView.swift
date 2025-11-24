import SwiftUI

/// 屏蔽用户视图
struct BlockUserView: View {
    let userId: String
    let username: String
    let nickname: String
    let avatar: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var isBlocking = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 用户信息
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: avatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    
                    VStack(spacing: 4) {
                        Text(nickname)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("@\(username)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 警告信息
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("屏蔽用户")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("屏蔽后，您将不会再看到该用户的帖子和评论。该用户也无法看到您的内容或与您互动。")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // 操作按钮
                VStack(spacing: 12) {
                    Button(action: {
                        blockUser()
                    }) {
                        HStack {
                            if isBlocking {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isBlocking ? "屏蔽中..." : "确认屏蔽")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isBlocking)
                    
                    Button("取消") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                .padding(.bottom)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func blockUser() {
        isBlocking = true
        
        Task {
            do {
                // 这里应该调用实际的屏蔽用户API
                try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟网络请求
                
                await MainActor.run {
                    // 显示成功提示
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isBlocking = false
                    // 显示错误提示
                }
            }
        }
    }
}

#Preview {
    BlockUserView(
        userId: "1",
        username: "testuser",
        nickname: "测试用户",
        avatar: nil
    )
}
