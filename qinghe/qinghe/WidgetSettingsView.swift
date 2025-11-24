//
//  WidgetSettingsView.swift
//  qinghe
//
//  桌面组件设置页面
//

import SwiftUI

struct WidgetSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var enableHealthWidget = true
    @State private var enableQuoteWidget = true
    @State private var enableCheckinWidget = true
    @State private var enableSleepWidget = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            customNavigationBar
            
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部说明
                    VStack(spacing: 12) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color(red: 0.25, green: 0.85, blue: 0.65))
                            .padding(.top, 20)
                        
                        Text("桌面组件")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        
                        Text("在主屏幕添加小组件，快速查看重要信息")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 20)
                    
                    // 可用组件列表
                    VStack(spacing: 16) {
                        widgetCard(
                            icon: "heart.fill",
                            iconColor: Color(red: 1.0, green: 0.3, blue: 0.3),
                            title: "健康数据",
                            description: "显示今日步数、心率等健康数据",
                            isEnabled: $enableHealthWidget
                        )
                        
                        widgetCard(
                            icon: "quote.bubble.fill",
                            iconColor: Color(red: 0.6, green: 0.4, blue: 0.2),
                            title: "每日经典",
                            description: "每天推送一句经典名言",
                            isEnabled: $enableQuoteWidget
                        )
                        
                        widgetCard(
                            icon: "checkmark.circle.fill",
                            iconColor: Color(red: 0.2, green: 0.6, blue: 1.0),
                            title: "打卡提醒",
                            description: "显示今日打卡进度和提醒",
                            isEnabled: $enableCheckinWidget
                        )
                        
                        widgetCard(
                            icon: "moon.fill",
                            iconColor: Color(red: 0.4, green: 0.3, blue: 0.8),
                            title: "睡眠记录",
                            description: "显示昨晚睡眠质量和时长",
                            isEnabled: $enableSleepWidget
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // 使用说明
                    VStack(alignment: .leading, spacing: 12) {
                        Text("如何添加组件")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        
                        instructionStep(number: 1, text: "长按主屏幕空白处进入编辑模式")
                        instructionStep(number: 2, text: "点击左上角的 + 号")
                        instructionStep(number: 3, text: "搜索并选择\"青禾计划\"")
                        instructionStep(number: 4, text: "选择组件样式并添加到主屏幕")
                    }
                    .padding(20)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
    }
    
    // MARK: - 自定义导航栏
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("桌面组件")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 组件卡片
    private func widgetCard(icon: String, iconColor: Color, title: String, description: String, isEnabled: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }
            
            // 文字信息
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 使用说明步骤
    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color(red: 0.25, green: 0.85, blue: 0.65))
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

