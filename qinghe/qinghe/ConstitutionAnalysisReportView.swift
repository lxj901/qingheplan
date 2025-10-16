import SwiftUI

struct ConstitutionAnalysisReportView: View {
    @Environment(\.dismiss) private var dismiss
    var data: ConstitutionAnalysisData

    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            // 全屏柔和渐变背景（覆盖到底部）
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "C3E88D"), location: 0.0),
                    .init(color: Color(hex: "B2F0E1"), location: 0.55),
                    .init(color: Color(hex: "FFE485"), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.28)
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ConstitutionAnalysisCard(
                        data: data, 
                        showRecommendations: false, 
                        showSyndrome: true,
                        showDiagnosisSwitch: false
                    )

                    if !data.hasAnalysis {
                        Text("暂未生成体质分析数据，请完成一次舌诊或面诊后查看完整报告。")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white.opacity(0.96))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 0.6)
                            )
                    } else {
                        // 基础评估
                        BasicAssessmentCard(
                            score: data.score,
                            physiqueName: data.physiqueName,
                            analysis: data.physiqueAnalysis,
                            typicalSymptom: data.typicalSymptom,
                            riskWarning: data.riskWarning
                        )

                        // 特征分析
                        if !data.features.isEmpty {
                            DiagnosisFeaturesCard(features: data.features)
                        }

                        // 体质分布（取前四项展示）
                        if !data.nineConstitutionScores.isEmpty {
                            DistributionCard(distribution: data.nineConstitutionScores)
                        }

                        // 舌象检测坐标卡片已根据需求移除

                        // 多维度调理建议
                        if !data.adviceSections.isEmpty {
                            AdviceSectionsCard(sections: data.adviceSections)
                        }

                        // 推荐产品卡片按需求移除
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("体质分析报告")
                    .font(.system(size: 17, weight: .semibold))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light) // 体质分析报告页面不适配深色模式
        .asSubView()
        .tint(.black)
    }
}

// 已移除：体质分析报告中的“五运六气”卡片

// MARK: - 基础评估卡片
private struct BasicAssessmentCard: View {
    var score: Int
    var physiqueName: String
    var analysis: String
    var typicalSymptom: String
    var riskWarning: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(physiqueName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black.opacity(0.9))
                Spacer(minLength: 0)
                Tag(text: "评分 \(score)")
            }

            LabeledTextRow(title: "体质说明", text: analysis)
            LabeledTextRow(title: "典型症候", text: typicalSymptom)
            LabeledTextRow(title: "风险提示", text: riskWarning)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.96)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 0.6))
    }
}

// MARK: - 特征分析列表
private struct DiagnosisFeaturesCard: View {
    var features: [DiagnosisFeature]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("特征分析")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "1F2A60").opacity(0.9))

            ForEach(features) { feature in
                DiagnosisFeatureRow(feature: feature)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.96)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.6), lineWidth: 0.6))
    }
}

private struct DiagnosisFeatureRow: View {
    var feature: DiagnosisFeature
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                // 状态点
                Circle()
                    .fill(feature.status == .normal ? Color.black.opacity(0.25) : Color.black.opacity(0.55))
                    .frame(width: 6, height: 6)
                Text(feature.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black.opacity(0.9))
                Spacer()
                Text(feature.value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
            }
            Text(feature.description)
                .font(.system(size: 13))
                .foregroundColor(.black.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.95)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 0.6))
    }
}

// MARK: - 体质分布
private struct DistributionCard: View {
    var distribution: [String: Double]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("体质分布")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "1F2A60").opacity(0.9))

            let sorted = Array(distribution.sorted { $0.value > $1.value }.prefix(6))
            let palette: [Color] = [
                Color(hex: "8FBF9F"), // 山岚绿
                Color(hex: "A3B0FF"), // 雨过天青
                Color(hex: "F4B2A5"), // 晨曦粉
                Color(hex: "EEC7A5"), // 杏仁米
                Color(hex: "C3E88D"), // 豆青
                Color(hex: "B2F0E1")  // 海天青
            ]

            ForEach(sorted.indices, id: \.self) { idx in
                let item = sorted[idx]
                HStack(spacing: 10) {
                    Text(item.key)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black.opacity(0.75))
                        .frame(width: 56, alignment: .leading)

                    GeometryReader { geo in
                        let pct = max(0, min(1, item.value))
                        let base = palette[idx % palette.count]
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.06))
                            Capsule().fill(
                                LinearGradient(
                                    colors: [base.opacity(0.95), base.opacity(0.55)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                                .frame(width: geo.size.width * CGFloat(pct))
                        }
                    }
                    .frame(height: 10)

                    Text(String(format: "%.0f%%", item.value * 100))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "1F2A60").opacity(0.8))
                        .frame(width: 48, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.96)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.6))
    }
}

// 舌象检测坐标卡片已删除

// MARK: - 多维度调理建议
private struct AdviceSectionsCard: View {
    var sections: [AdviceSection]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("多维度调理建议")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "1F2A60").opacity(0.9))

            ForEach(sections) { section in
                AdviceSectionView(section: section)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.96)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.6), lineWidth: 0.6))
    }
}

private struct AdviceSectionView: View {
    var section: AdviceSection
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.black.opacity(0.85))
            ForEach(section.entries) { entry in
                AdviceEntryRow(entry: entry)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.55), lineWidth: 0.5))
    }
}

private struct AdviceEntryRow: View {
    var entry: AdviceEntry
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Color.black.opacity(0.25)).frame(width: 6, height: 6).padding(.top, 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black.opacity(0.55))
                Text(entry.value)
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - 复用小组件
private struct LabeledTextRow: View {
    var title: String
    var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "8D6E63").opacity(0.95))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct Chip: View {
    var text: String
    var fill: Color = Color.white
    var stroke: Color = Color.white.opacity(0.6)
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "1F2A60").opacity(0.9))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(stroke.opacity(0.9), lineWidth: 1.0))
    }
}

// 极简标签
private struct Tag: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.black.opacity(0.7))
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.black.opacity(0.05)))
    }
}

// FlexibleWrap 及“推荐产品”卡片按需求移除
