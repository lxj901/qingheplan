import SwiftUI
import UIKit

// 诊断历史页面（与“健康档案”不同页面）
// 先提供基础框架与导航，后续可接入真实诊断数据列表
struct DiagnosisHistoryView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            // 页面主体背景（不使用整页渐变）
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            // 主要内容区域（占位）
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // TODO: 接入真实诊断记录列表
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("暂无诊断记录")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                }
            }
            ToolbarItem(placement: .principal) {
                Text("诊断历史")
                    .font(.system(size: 17, weight: .semibold))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .asSubView() // 隐藏底部 Tab 栏
    }
}

