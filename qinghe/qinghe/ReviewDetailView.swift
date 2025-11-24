//
//  ReviewDetailView.swift
//  qinghe
//
//  Created by Augment Agent on 2025-10-20.
//  复习详情页面（全屏复习 + 质量评分）

import SwiftUI

struct ReviewDetailView: View {
    let item: ReviewItem
    @ObservedObject var viewModel: ReviewViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var showRatingSheet = false
    @State private var selectedQuality: ReviewQuality?
    @State private var reviewCompleted = false
    @State private var nextReviewInfo: ReviewCompleteResponse?
    
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
                ScrollView {
                    VStack(spacing: 24) {
                        // 章节信息
                        chapterInfoView

                        // 原文内容
                        originalTextView

                        // 复习信息
                        reviewInfoView

                        // 完成按钮
                        completeButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        // 隐藏系统导航栏，避免出现大标题造成的顶部额外高度
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showRatingSheet) {
            RatingSheetView(
                selectedQuality: $selectedQuality,
                nextReviewInfo: nextReviewInfo,
                onConfirm: handleRatingConfirm
            )
            .presentationDetents([.height(480)])
        }
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
            Text("复习内容")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))

            Spacer()

            // 占位
            Color.clear
                .frame(width: 70)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 44)
        .background(Color.white.opacity(0.3))
    }
    
    // MARK: - Chapter Info
    private var chapterInfoView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 139/255, green: 97/255, blue: 57/255))

                Text(getBookTitle(bookId: item.bookId))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            }

            Text(item.chapterId)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.6))
        )
    }
    
    // MARK: - Original Text
    private var originalTextView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "scroll.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 51/255, green: 140/255, blue: 115/255))
                
                Text("原文")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 80/255, green: 80/255, blue: 80/255))
            }
            
            Text(item.original)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(red: 40/255, green: 40/255, blue: 40/255))
                .lineSpacing(8)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 255/255, green: 252/255, blue: 245/255),
                                    Color(red: 252/255, green: 248/255, blue: 238/255)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
        }
    }
    
    // MARK: - Review Info
    private var reviewInfoView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                // 复习次数
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                        Text("复习次数")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
                    
                    Text("\(item.reviewCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 51/255, green: 140/255, blue: 115/255))
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color(red: 200/255, green: 200/255, blue: 200/255))
                    .frame(width: 1, height: 40)
                
                // 复习间隔
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                        Text("复习间隔")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
                    
                    Text("\(item.reviewInterval) 天")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 139/255, green: 97/255, blue: 57/255))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.6))
            )
        }
    }
    
    // MARK: - Complete Button
    private var completeButton: some View {
        Button(action: {
            showRatingSheet = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                
                Text("完成复习")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
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
            .cornerRadius(12)
            .shadow(color: Color(red: 51/255, green: 140/255, blue: 115/255).opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Handle Rating Confirm
    private func handleRatingConfirm() {
        guard let quality = selectedQuality else { return }

        viewModel.completeReview(item: item, quality: quality) { response in
            if let response = response {
                nextReviewInfo = response
                reviewCompleted = true

                // 延迟关闭页面并刷新列表
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    // 刷新复习列表
                    viewModel.refresh()
                    dismiss()
                }
            }
        }
    }

    // MARK: - 辅助方法

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

// MARK: - Rating Sheet View
struct RatingSheetView: View {
    @Binding var selectedQuality: ReviewQuality?
    let nextReviewInfo: ReviewCompleteResponse?
    let onConfirm: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // 标题
            VStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 255/255, green: 200/255, blue: 50/255))
                
                Text("复习完成！请评价记忆质量")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
            }
            .padding(.top, 20)
            
            // 星级评分
            VStack(spacing: 16) {
                ForEach(ReviewQuality.allCases.reversed(), id: \.self) { quality in
                    QualityButton(
                        quality: quality,
                        isSelected: selectedQuality == quality,
                        onTap: { selectedQuality = quality }
                    )
                }
            }
            
            // 下次复习时间提示
            if let info = nextReviewInfo {
                Text("下次复习时间：\(info.nextReviewDescription)")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 100/255, green: 100/255, blue: 100/255))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 51/255, green: 140/255, blue: 115/255).opacity(0.1))
                    )
            }
            
            // 确认按钮
            Button(action: {
                onConfirm()
                dismiss()
            }) {
                Text("确认")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
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
                    .cornerRadius(10)
            }
            .disabled(selectedQuality == nil)
            .opacity(selectedQuality == nil ? 0.5 : 1.0)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 245/255, green: 242/255, blue: 237/255),
                    Color(red: 239/255, green: 235/255, blue: 224/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Quality Button
struct QualityButton: View {
    let quality: ReviewQuality
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 星级图标
                HStack(spacing: 2) {
                    ForEach(0..<quality.rawValue, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                    }
                }
                .foregroundColor(Color(red: quality.color.red, green: quality.color.green, blue: quality.color.blue))
                
                // 质量描述
                Text(quality.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 60/255, green: 60/255, blue: 60/255))
                
                Spacer()
                
                // 选中标记
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 51/255, green: 140/255, blue: 115/255))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(red: 51/255, green: 140/255, blue: 115/255).opacity(0.1) : Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? Color(red: 51/255, green: 140/255, blue: 115/255) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
}

#Preview {
    ReviewDetailView(item: ReviewItem.mockData[0], viewModel: ReviewViewModel())
}
