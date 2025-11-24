//
//  ReviewViewModel.swift
//  qinghe
//
//  Created by Augment Agent on 2025-10-20.
//  复习计划 ViewModel

import Foundation
import SwiftUI

@MainActor
class ReviewViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var reviewItems: [ReviewItem] = []
    @Published var reviewStats: ReviewStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 分组后的复习项目
    @Published var dateGroups: [ReviewDateGroup] = []
    
    // 今日待复习项目
    var todayItems: [ReviewItem] {
        reviewItems.filter { $0.isDueToday }
    }
    
    // 未来复习项目
    var futureItems: [ReviewItem] {
        reviewItems.filter { !$0.isDueToday }
    }
    
    // MARK: - API Configuration
    private let baseURL = "https://api.qinghejihua.com.cn/api/v1/classics"
    private let useMockData = false  // 切换到真实 API
    
    // MARK: - Initialization
    init() {
        loadReviewList()
        loadReviewStats()
    }
    
    // MARK: - API Methods
    
    /// 加载复习列表
    func loadReviewList(dueOnly: Bool = false) {
        isLoading = true
        errorMessage = nil

        // 开发时使用 Mock 数据
        if useMockData {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.reviewItems = ReviewItem.mockData
                self?.groupReviewItems()
                self?.isLoading = false
            }
            return
        }

        // 实际 API 调用
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            print("⚠️ 复习计划：用户未登录")
            errorMessage = "用户未登录"
            isLoading = false
            return
        }

        let dueOnlyParam = dueOnly ? "true" : "false"
        let urlString = "\(baseURL)/review/list?userId=\(userId)&dueOnly=\(dueOnlyParam)"

        print("📝 复习计划：开始加载复习列表")
        print("📝 请求 URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ 复习计划：无效的 URL")
            errorMessage = "无效的 URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // 添加认证 token
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("📝 复习计划：已添加认证 Token")
        } else {
            print("⚠️ 复习计划：未找到认证 Token")
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    print("❌ 复习计划：网络错误 - \(error.localizedDescription)")
                    self?.errorMessage = "网络错误: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    print("❌ 复习计划：未收到数据")
                    self?.errorMessage = "未收到数据"
                    return
                }

                // 打印原始响应用于调试
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📝 复习计划 API 响应: \(jsonString)")
                }

                do {
                    let apiResponse = try JSONDecoder().decode(ReviewListResponse.self, from: data)
                    if apiResponse.code == 0 {
                        print("✅ 复习计划：成功获取 \(apiResponse.data.count) 条复习计划")
                        self?.reviewItems = apiResponse.data
                        self?.groupReviewItems()
                    } else {
                        print("❌ 复习计划：API 返回错误 - \(apiResponse.message)")
                        self?.errorMessage = apiResponse.message
                    }
                } catch {
                    print("❌ 复习计划：数据解析失败 - \(error.localizedDescription)")
                    self?.errorMessage = "数据解析失败: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    /// 完成复习
    func completeReview(item: ReviewItem, quality: ReviewQuality, completion: @escaping (ReviewCompleteResponse?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // 开发时使用 Mock 数据
        if useMockData {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                let mockResponse = ReviewCompleteResponse(
                    nextReviewAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(Double(quality.rawValue) * 86400)),
                    interval: quality.rawValue,
                    reviewCount: item.reviewCount + 1
                )
                self?.isLoading = false
                completion(mockResponse)
                
                // 刷新列表
                self?.loadReviewList()
            }
            return
        }
        
        // 实际 API 调用
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            errorMessage = "用户未登录"
            isLoading = false
            completion(nil)
            return
        }
        
        let urlString = "\(baseURL)/review/complete"
        guard let url = URL(string: urlString) else {
            errorMessage = "无效的 URL"
            isLoading = false
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证 token
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = ReviewCompleteRequest(
            userId: userId,
            sectionId: item.sectionId,
            quality: quality.rawValue
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            errorMessage = "请求数据编码失败"
            isLoading = false
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "网络错误: \(error.localizedDescription)"
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "未收到数据"
                    completion(nil)
                    return
                }
                
                do {
                    let apiResponse = try JSONDecoder().decode(ReviewCompleteAPIResponse.self, from: data)
                    if apiResponse.code == 0 {
                        completion(apiResponse.data)
                        // 刷新列表
                        self?.loadReviewList()
                    } else {
                        self?.errorMessage = apiResponse.message
                        completion(nil)
                    }
                } catch {
                    self?.errorMessage = "数据解析失败: \(error.localizedDescription)"
                    completion(nil)
                }
            }
        }.resume()
    }
    
    /// 加载复习统计
    func loadReviewStats() {
        // 开发时使用 Mock 数据
        if useMockData {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.reviewStats = ReviewStats.mockData
            }
            return
        }

        // 实际 API 调用
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            print("⚠️ 复习统计：用户未登录")
            errorMessage = "用户未登录"
            return
        }

        let urlString = "\(baseURL)/review/statistics?userId=\(userId)"

        print("📊 复习统计：开始加载统计数据")
        print("📊 请求 URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ 复习统计：无效的 URL")
            errorMessage = "无效的 URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // 添加认证 Token
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("📊 复习统计：已添加认证 Token")
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 复习统计：网络错误 - \(error.localizedDescription)")
                    self?.errorMessage = "网络错误：\(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    print("❌ 复习统计：无数据返回")
                    self?.errorMessage = "无数据返回"
                    return
                }

                // 打印原始响应（用于调试）
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📊 复习统计 API 响应: \(jsonString)")
                }

                do {
                    let response = try JSONDecoder().decode(ReviewStatisticsResponse.self, from: data)

                    if response.code == 0 {
                        // 将新的 ReviewStatistics 转换为旧的 ReviewStats 格式
                        self?.reviewStats = ReviewStats.from(response.data)
                        print("✅ 复习统计：成功获取统计数据")
                        print("   - 总复习次数: \(response.data.data.totalReviews)")
                        print("   - 平均质量: \(response.data.data.avgQuality)")
                        print("   - 连续天数: \(response.data.data.consecutiveDays)")
                    } else {
                        print("❌ 复习统计：API 返回错误 - \(response.message)")
                        self?.errorMessage = response.message
                    }
                } catch {
                    print("❌ 复习统计：数据解析失败 - \(error.localizedDescription)")
                    self?.errorMessage = "数据解析失败"
                }
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    
    /// 将复习项目按日期分组
    private func groupReviewItems() {
        var groups: [String: [ReviewItem]] = [:]
        
        for item in reviewItems {
            let groupTitle = item.dateGroupTitle
            if groups[groupTitle] == nil {
                groups[groupTitle] = []
            }
            groups[groupTitle]?.append(item)
        }
        
        // 转换为 ReviewDateGroup 数组并排序
        dateGroups = groups.map { title, items in
            let isDueToday = items.first?.isDueToday ?? false
            let date = items.first?.nextReviewDate
            return ReviewDateGroup(
                title: title,
                date: date,
                items: items.sorted { ($0.nextReviewDate ?? Date()) < ($1.nextReviewDate ?? Date()) },
                isDueToday: isDueToday
            )
        }.sorted { group1, group2 in
            // 今日待复习排在最前面
            if group1.isDueToday && !group2.isDueToday {
                return true
            } else if !group1.isDueToday && group2.isDueToday {
                return false
            }
            // 其他按日期排序
            guard let date1 = group1.date, let date2 = group2.date else {
                return false
            }
            return date1 < date2
        }
    }
    
    /// 刷新数据
    func refresh() {
        loadReviewList()
        loadReviewStats()
    }
}

