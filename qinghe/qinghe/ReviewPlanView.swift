//
//  ReviewPlanView.swift
//  qinghe
//
//  Created by Augment Agent on 2025-10-20.
//  复习计划主页面

import SwiftUI

struct ReviewPlanView: View {
    @StateObject private var viewModel = ReviewViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showStats = false
    @State private var selectedItem: ReviewItem?
    @State private var showReviewDetail = false
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(red: 245/255, green: 242/255, blue: 237/255),
                    Color(red: 239/255, green: 235/255, blue: 224/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 导航栏
                navigationBar
                
                // 内容区域
                if viewModel.isLoading && viewModel.reviewItems.isEmpty {
                    loadingView
                } else if viewModel.reviewItems.isEmpty {
                    emptyView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 今日待复习区域
                            if !viewModel.todayItems.isEmpty {
                                todayReviewSection
                            }
                            
                            // 未来复习计划
                            if !viewModel.futureItems.isEmpty {
                                futureReviewSection
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showStats) {
            ReviewStatsView(stats: viewModel.reviewStats ?? ReviewStats.mockData)
        }
        .fullScreenCover(item: $selectedItem) { item in
            ReviewDetailView(item: item, viewModel: viewModel)
        }
        .enableSwipeBack() // 启用系统原生滑动返回手势
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack(spacing: 12) {
            // 返回按钮
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("返回")
                        .font(.system(size: 15))
                }
                .foregroundColor(Color(red: 51/255, green: 140/255, blue: 115/255))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.6))
                )
            }
            
            Spacer()
            
            // 标题
            Text("复习计划")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            
            Spacer()
            
            // 统计按钮
            Button(action: { showStats = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14))
                    Text("统计")
                        .font(.system(size: 15))
                }
                .foregroundColor(Color(red: 51/255, green: 140/255, blue: 115/255))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.6))
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.3))
    }
    
    // MARK: - Today Review Section
    private var todayReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 220/255, green: 100/255, blue: 80/255))
                
                Text("今日待复习")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                
                Text("(\(viewModel.todayItems.count))")
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 120/255, green: 120/255, blue: 120/255))
            }
            .padding(.horizontal, 4)
            
            // 今日复习卡片列表
            ForEach(viewModel.todayItems) { item in
                ReviewCardView(item: item, isDueToday: true) {
                    selectedItem = item
                    showReviewDetail = true
                }
            }
        }
    }
    
    // MARK: - Future Review Section
    private var futureReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 100/255, green: 120/255, blue: 140/255))
                
                Text("未来复习计划")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            }
            .padding(.horizontal, 4)
            
            // 按日期分组显示
            ForEach(viewModel.dateGroups.filter { !$0.isDueToday }) { group in
                VStack(alignment: .leading, spacing: 8) {
                    // 日期分组标题
                    HStack(spacing: 6) {
                        Text(group.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
                        
                        Text("(\(group.count))")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 140/255, green: 140/255, blue: 140/255))
                        
                        Rectangle()
                            .fill(Color(red: 200/255, green: 200/255, blue: 200/255))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    
                    // 该日期的复习卡片
                    ForEach(group.items) { item in
                        ReviewCardView(item: item, isDueToday: false) {
                            selectedItem = item
                            showReviewDetail = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("加载中...")
                .font(.system(size: 15))
                .foregroundColor(Color(red: 120/255, green: 120/255, blue: 120/255))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 180/255, green: 180/255, blue: 180/255))
            
            Text("暂无复习计划")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
            
            Text("开始阅读国学经典，系统会自动为你创建复习计划")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 140/255, green: 140/255, blue: 140/255))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Review Card View
struct ReviewCardView: View {
    let item: ReviewItem
    let isDueToday: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // 章节信息
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 139/255, green: 97/255, blue: 57/255))

                    Text("\(getBookTitle(bookId: item.bookId)) · \(item.chapterId)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
                }
                
                // 原文内容
                Text(item.original)
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                    .lineLimit(3)
                    .lineSpacing(4)
                
                // 底部信息
                HStack(spacing: 12) {
                    // 复习次数
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                        Text("第 \(item.reviewCount) 次复习")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Color(red: 100/255, green: 120/255, blue: 140/255))
                    
                    // 复习时间
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(timeDescription)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(isDueToday ? Color(red: 220/255, green: 100/255, blue: 80/255) : Color(red: 100/255, green: 120/255, blue: 140/255))
                    
                    Spacer()
                    
                    // 开始复习按钮
                    if isDueToday {
                        HStack(spacing: 4) {
                            Text("开始复习")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 51/255, green: 140/255, blue: 115/255),
                                    Color(red: 41/255, green: 120/255, blue: 95/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(6)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isDueToday ? Color(red: 220/255, green: 100/255, blue: 80/255).opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var timeDescription: String {
        if isDueToday {
            if let date = item.nextReviewDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return "今天 \(formatter.string(from: date))"
            }
            return "今天"
        } else {
            return item.dateGroupTitle
        }
    }

    /// 根据 bookId 获取书名
    private func getBookTitle(bookId: String) -> String {
        switch bookId {
        case "lunyu": return "论语"
        case "daxue": return "大学"
        case "zhongyong": return "中庸"
        case "mengzi": return "孟子"
        case "daodejing": return "道德经"
        case "zhuangzi": return "庄子"
        case "yijing": return "易经"
        case "shijing": return "诗经"
        case "shangshu": return "尚书"
        case "liji": return "礼记"
        case "chunqiu": return "春秋"
        case "zuozhuan": return "左传"
        default: return bookId
        }
    }
}

#Preview {
    ReviewPlanView()
}

