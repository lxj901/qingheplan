import SwiftUI

/// 五运六气页面（现代化UI草案）
/// - 背景：复用星空动画 StarfieldBackgroundView
/// - 结构：
///   1) 顶部导航与日期地点（可接入定位/城市）
///   2) 双层环形图：外圈五运（5分段），内圈六气（6分段）
///   3) 当前节气/时间轴卡片 + 推荐动作
///   4) 知识卡片（科普/来源）
struct WuYunLiuQiView: View {
    @Environment(\.dismiss) private var dismiss

    // 示例数据（后续可由算法/服务注入）
    @State private var selectedWuYunIndex: Int = 0 // 0-4
    @State private var selectedLiuQiIndex: Int = 0 // 0-5
    @State private var selectedRange: RangeScope = .day
    @State private var highlightedSegment: (ring: RingType, index: Int)? = nil
    @State private var showTooltip: Bool = false

    private let wuYunNames = ["木运","火运","土运","金运","水运"]
    private let liuQiNames = ["厥阴风木","少阴君火","少阳相火","太阴湿土","阳明燥金","太阳寒水"]

    enum RangeScope: String, CaseIterable { case day = "当天", week = "本周", year = "本年" }
    enum RingType { case wuyun, liuqi }
    // 分段控制：当天/本周/本年
    private var scopeSegmentedControl: some View {
        HStack(spacing: 8) {
            ForEach(RangeScope.allCases, id: \.self) { s in
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedRange = s } }) {
                    Text(s.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedRange == s ? .black : .white.opacity(0.8))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            ZStack {
                                if selectedRange == s {
                                    RoundedRectangle(cornerRadius: 12).fill(Color.white)
                                } else {
                                    RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08))
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // 中心简卡：节气/干支 + 时间轴占位
    private var currentCenterCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                SolarTermImageView()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentMainLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(currentSubLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.75))
                }
                Spacer()
            }

            // 时间轴（占位）：后续接实数据
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12)).frame(height: 6)
                Capsule().fill(LinearGradient(colors: [.white, .white.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: progressWidth, height: 6)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var progressWidth: CGFloat {
        let total: CGFloat = 1.0
        let p: CGFloat = selectedRange == .day ? 0.45 : (selectedRange == .week ? 0.32 : 0.18)
        return UIScreen.main.bounds.width * 0.6 * min(max(p/total, 0), 1)
    }

    private var currentMainLabel: String {
        "\(wuYunNames[selectedWuYunIndex % wuYunNames.count]) • \(liuQiNames[selectedLiuQiIndex % liuQiNames.count])"
    }

    private var currentSubLabel: String { "节气：\(SolarTermCalculator.currentTerm(for: Date()).chineseAssetName)" }

    private var currentAdvice: String {
        switch selectedRange {
        case .day: return "适度疏风，早睡早起，清淡饮食，适合温和拉伸与慢跑。"
        case .week: return "保持作息稳定，循序渐进训练，每周3-4次有氧+力量。"
        case .year: return "顺应年运调整节律，春夏重生发，秋冬注收敛与养藏。"
        }
    }

    // 扇区标签：沿圆弧排版（简化为极坐标点位 + 轻度旋转）
    private func ringLabels(count: Int, radius: CGFloat, names: [String], fontSize: CGFloat = 11) -> some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let startA = 2 * .pi * (CGFloat(i) / CGFloat(count))
                    let midA = startA + (.pi * 2 / CGFloat(count)) / 2
                    let x = center.x + radius * cos(midA - .pi/2)
                    let y = center.y + radius * sin(midA - .pi/2)
                    Text(names[i % names.count])
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .position(x: x, y: y)
                        .rotationEffect(.radians(midA - .pi/2))
                }
            }
        }
    }

    // Tooltip（简化）：显示当前高亮段解释
    private var tooltipView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("当令解读")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            Text("\(currentMainLabel)：有助于…（示例文案，后续接真实规则）")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(12)
        .background(Color.black.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.top, 8)
        .padding(.horizontal, 24)
    }

    var body: some View {
        ZStack {
            StarfieldBackgroundView(starCount: 50, includePulsingGlow: true)

            VStack(spacing: 16) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        scopeSegmentedControl

                        // 主运图（新骨架组件）
                        WuYunZhuYunDiagramView(size: 320)
                            .padding(.top, 4)

                        currentCenterCard

                        currentCard

                        knowledgeCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - 顶部栏
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("五运六气")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("现代中医 • 天人合一")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
    }




    // MARK: - 当前节气/建议卡片（列表卡）
    private var currentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                SolarTermImageView()
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 0.5))

                VStack(alignment: .leading, spacing: 2) {
                    Text("当令：")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(currentMainLabel)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.8))
                        .padding(8)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }

            Text("建议：\(currentAdvice)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .background(.ultraThinMaterial.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 知识卡片
    private var knowledgeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .foregroundColor(.white)
                Text("五运六气科普")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Link("参考资料", destination: URL(string: "https://zh.wikipedia.org/wiki/%E4%BA%8C%E5%8D%81%E5%9B%9B%E8%8A%82%E6%B0%94")!)
                    .font(.system(size: 12, weight: .medium))
            }

            Text("以干支纪年与六气推演气候对人体影响。页面采用‘星空 + 纹理暗面 + 玻璃拟态’的现代中式风格，你可在上方切换 当天/本周/本年 查看不同粒度。").font(.system(size: 13)).foregroundColor(.white.opacity(0.8))
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .background(.ultraThinMaterial.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - 配色
    private var wuYunColors: [Color] {
        [
            Color(red: 0.38, green: 0.76, blue: 0.50), // 木
            Color(red: 0.98, green: 0.41, blue: 0.41), // 火
            Color(red: 0.88, green: 0.79, blue: 0.48), // 土
            Color(red: 0.85, green: 0.85, blue: 0.88), // 金（淡金属色）
            Color(red: 0.44, green: 0.66, blue: 0.98)  // 水
        ]
    }

    private var liuQiColors: [Color] {
        [
            Color(red: 0.38, green: 0.76, blue: 0.50),
            Color(red: 0.95, green: 0.55, blue: 0.40),
            Color(red: 0.98, green: 0.41, blue: 0.58),
            Color(red: 0.64, green: 0.82, blue: 0.70),
            Color(red: 0.90, green: 0.86, blue: 0.72),
            Color(red: 0.40, green: 0.65, blue: 0.95)
        ]
    }
}

#Preview("WuYunLiuQiView") {
    WuYunLiuQiView()
}
