import Foundation
import SwiftUI

/// 黑名单视图模型
@MainActor
class BlacklistViewModel: ObservableObject {
    @Published var blockedUsers: [BlockedUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var hasMoreUsers = true
    @Published var currentPage = 1
    
    private let apiService = CommunityAPIService.shared
    private let pageLimit = 20
    
    /// 加载屏蔽用户列表
    func loadBlockedUsers(refresh: Bool = false) async {
        // 如果是刷新，重置页码
        if refresh {
            currentPage = 1
            hasMoreUsers = true
        }
        
        // 如果没有更多数据，不再加载
        guard hasMoreUsers else { return }
        
        // 如果正在加载，不重复加载
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getBlockedUsers(page: currentPage, limit: pageLimit)
            
            guard response.success, let data = response.data else {
                errorMessage = response.message ?? "获取黑名单失败"
                showError = true
                isLoading = false
                return
            }
            
            if refresh {
                blockedUsers = data.items
            } else {
                blockedUsers.append(contentsOf: data.items)
            }
            
            // 更新分页信息
            hasMoreUsers = data.pagination.hasNext
            currentPage += 1
            
            print("✅ 加载黑名单成功 - 当前数量: \(blockedUsers.count), 总数: \(data.pagination.total)")
            
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
            showError = true
            print("❌ 加载黑名单失败: \(error)")
        }
        
        isLoading = false
    }
    
    /// 刷新黑名单列表
    func refreshBlockedUsers() async {
        await loadBlockedUsers(refresh: true)
    }
    
    /// 加载更多黑名单用户
    func loadMoreBlockedUsers() async {
        await loadBlockedUsers(refresh: false)
    }
    
    /// 解除屏蔽用户
    func unblockUser(_ user: BlockedUser) async {
        do {
            let response = try await apiService.unblockUser(userId: user.id)

            guard response.success else {
                errorMessage = response.message ?? "解除屏蔽失败"
                showError = true
                return
            }

            // 从列表中移除该用户
            blockedUsers.removeAll { $0.id == user.id }

            print("✅ 解除屏蔽成功 - 用户ID: \(user.id)")

        } catch {
            errorMessage = "解除屏蔽失败: \(error.localizedDescription)"
            showError = true
            print("❌ 解除屏蔽失败: \(error)")
        }
    }
    
    /// 删除用户（通过索引）
    func deleteUsers(at offsets: IndexSet) async {
        for index in offsets {
            let user = blockedUsers[index]
            await unblockUser(user)
        }
    }
}

