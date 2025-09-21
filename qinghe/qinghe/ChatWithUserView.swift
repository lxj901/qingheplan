import SwiftUI

/// 与特定用户聊天的视图，用于半屏聊天功能
struct ChatWithUserView: View {
    let targetUser: UserProfile
    
    @State private var viewModel: ChatDetailViewModel?
    @State private var conversation: ChatConversation?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                // 加载状态
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("正在准备聊天...")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                // 错误状态
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("无法开始聊天")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("重试") {
                        Task {
                            await loadOrCreateConversation()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let conversation = conversation {
                // 聊天界面
                ChatDetailView(conversation: conversation)
            } else {
                // 意外状态
                VStack {
                    Text("出现了意外错误")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(targetUser.nickname)
        .onAppear {
            Task {
                await loadOrCreateConversation()
            }
        }
    }
    
    /// 加载或创建与目标用户的会话
    private func loadOrCreateConversation() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔍 ChatWithUserView: 开始创建与用户 \(targetUser.nickname) 的聊天")
            
            // 尝试创建或获取私聊会话
            let newConversation = try await ChatAPIService.shared.createPrivateChat(recipientId: targetUser.id)

            await MainActor.run {
                self.conversation = newConversation
                self.viewModel = ChatDetailViewModel(conversationId: newConversation.id)
                self.isLoading = false
                print("🔍 ChatWithUserView: 聊天会话创建成功，ID: \(newConversation.id)")
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "创建聊天失败：\(error.localizedDescription)"
                self.isLoading = false
                print("❌ ChatWithUserView: 创建聊天失败 - \(error)")
            }
        }
    }
}

// MARK: - 预览
struct ChatWithUserView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatWithUserView(targetUser: UserProfile(
                id: 1,
                nickname: "预览用户",
                avatar: nil,
                backgroundImage: nil,
                bio: "这是一个预览用户",
                location: nil,
                gender: nil,
                birthday: nil,
                constellation: nil,
                hometown: nil,
                school: nil,
                ipLocation: nil,
                qingheId: "qinghe123456",
                level: nil,
                isVerified: false,
                followersCount: 100,
                followingCount: 50,
                postsCount: 25,
                createdAt: nil,
                lastActiveAt: nil,
                isFollowing: false,
                isFollowedBy: false,
                isBlocked: false,
                isMe: false
            ))
        }
    }
}
