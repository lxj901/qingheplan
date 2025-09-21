import Foundation
import SwiftUI

/// 用户管理器
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    
    private init() {
        loadCurrentUser()
    }
    
    /// 加载当前用户信息
    private func loadCurrentUser() {
        // 从本地存储或网络加载用户信息
        // 这里是示例实现
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isLoggedIn = true
        }
    }
    
    /// 设置当前用户
    func setCurrentUser(_ user: User) {
        self.currentUser = user
        self.isLoggedIn = true
        
        // 保存到本地存储
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    /// 登出
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    /// 更新用户信息
    func updateUser(_ user: User) {
        self.currentUser = user
        
        // 保存到本地存储
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
}

/// 用户模型
struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let nickname: String
    let avatar: String?
    let email: String?
    let phone: String?
    let isVerified: Bool
    let level: Int
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let bio: String?
    let location: String?
    let website: String?
    let birthday: String?
    let gender: String?
    let createdAt: String
    let updatedAt: String
}
