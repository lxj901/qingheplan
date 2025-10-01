import SwiftUI

// MARK: - 数据模型
struct WYAdviceItem: Identifiable { let id = UUID(); let text: String; let reason: String }

struct WYCardData {
    var dateText: String // e.g. 2025-09-24 或 节气名 + 日期
    var mainYun: String  // 金/木/水/火/土（或 金运/木运...）
    var mainQi: String   // 风/暑/湿/燥/寒/火（或 阴阳+经络名）
    var excessType: String // 太过/不及/正常
    var siTian: String // 司天
    var zaiQuan: String // 在泉
    // 强弱分布（0~1）
    var yunStrength: [String: Double] // keys: 木 火 土 金 水
    var qiStrength: [String: Double]  // keys: 风 暑 湿 燥 寒 火
    // 建议（最多展示3条）
    var advice: [WYAdviceItem]
}

// MARK: - 双环玫瑰图视图
struct DoubleRingRoseChartView: View {
    let yunStrength: [String: Double]
    let qiStrength: [String: Double]

    // 交互
    @Binding var highlighted: (ring: Ring, index: Int)?

    enum Ring { case yun, qi }

    private let yunOrder = ["木","火","土","金","水"]
    private let qiOrder  = ["风","暑","湿","燥","寒","火"]

    // 色彩
    private let yunColors: [String: Color] = [
        "木": Color(hex: "37B26C"),
        "火": Color(hex: "E85C4A"),
        "土": Color(hex: "D6A23E"),
        "金": Color(hex: "B7BEC7"),
        "水": Color(hex: "3E7BEB")
    ]
    private let qiColors: [String: Color] = [
        "风": Color(hex: "3AC6B1"),
        "暑": Color(hex: "FF9C42"),
        "湿": Color(hex: "36B0C9"),
        "燥": Color(hex: "E9CBA7"),
        "寒": Color(hex: "6AA8FF"),
        "火": Color(hex: "E85C4A")
    ]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            let innerR: CGFloat = size * 0.26
            let gap: CGFloat = 8
            let ringThick: CGFloat = 22

            ZStack {
                // 背板
                Circle().fill(Color.white.opacity(0.06)).overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.6))

                // 内圈：五运
                ringRose(center: center,
                         innerRadius: innerR,
                         thickness: ringThick,
                         names: yunOrder,
                         values: yunOrder.map { max(0, min(1, yunStrength[$0] ?? 0)) },
                         colors: yunColors,
                         ring: .yun)

                // 外圈：六气
                ringRose(center: center,
                         innerRadius: innerR + ringThick + gap,
                         thickness: ringThick,
                         names: qiOrder,
                         values: qiOrder.map { max(0, min(1, qiStrength[$0] ?? 0)) },
                         colors: qiColors,
                         ring: .qi)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeOut(duration: 0.35), value: highlighted?.index)
    }

    @ViewBuilder
    private func ringRose(center: CGPoint,
                          innerRadius: CGFloat,
                          thickness: CGFloat,
                          names: [String],
                          values: [Double],
                          colors: [String: Color],
                          ring: Ring) -> some View {
        let count = names.count
        let baseAngle = 2 * Double.pi / Double(count)
        let maxGrow: CGFloat = thickness // 最多增长到再加1倍厚度

        ForEach(0..<count, id: \.self) { i in
            let start = Double(i) * baseAngle - Double.pi/2
            let end = start + baseAngle
            let v = values[i]
            let grow = CGFloat(v) * maxGrow
            let color = colors[names[i]] ?? .blue
            let isHL = highlighted?.ring == ring && highlighted?.index == i
            let dim = (highlighted == nil || isHL) ? 1.0 : 0.6 // 相邻降低40%

            RoseWedge(center: center,
                      innerRadius: innerRadius,
                      thickness: thickness + grow,
                      startAngle: start,
                      endAngle: end)
                .fill(
                    LinearGradient(colors: [color.opacity(0.78), color.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoseWedge(center: center,
                              innerRadius: innerRadius,
                              thickness: thickness + grow,
                              startAngle: start,
                              endAngle: end)
                        .stroke(color.opacity(0.7), lineWidth: 0.8)
                )
                .opacity(dim)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isHL { highlighted = nil } else { highlighted = (ring, i) }
                    }
                }
                .overlay(alignment: .center) {
                    // 标签
                    let mid = (start + end) / 2
                    let labelR = innerRadius + (thickness + grow) + 10
                    let p = CGPoint(x: center.x + labelR * CGFloat(cos(mid)), y: center.y + labelR * CGFloat(sin(mid)))
                    Text(names[i])
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.9))
                        .position(p)
                        .opacity(dim)
                }

                // tooltip
                .overlay(alignment: .center) {
                    if isHL {
                        let mid = (start + end) / 2
                        let tipR = innerRadius + (thickness + grow) + 36
                        let tipP = CGPoint(x: center.x + tipR * CGFloat(cos(mid)), y: center.y + tipR * CGFloat(sin(mid)))
                        VStack(spacing: 4) {
                            Text(names[i]).font(.system(size: 11, weight: .semibold))
                            Text(String(format: "强度 %.0f%%", values[i] * 100)).font(.system(size: 10))
                        }
                        .padding(.vertical, 6).padding(.horizontal, 8)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 0.6))
                        .position(tipP)
                        .transition(.scale(scale: 0.9))
                    }
                }
        }
    }
}

// MARK: - 玫瑰图楔形
private struct RoseWedge: Shape {
    let center: CGPoint
    let innerRadius: CGFloat
    let thickness: CGFloat
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let outerR = innerRadius + thickness
        p.addArc(center: center, radius: outerR, startAngle: .radians(startAngle), endAngle: .radians(endAngle), clockwise: false)
        p.addArc(center: center, radius: innerRadius, startAngle: .radians(endAngle), endAngle: .radians(startAngle), clockwise: true)
        p.closeSubpath()
        return p
    }
}

// MARK: - Tag 样式
private struct TagCapsule: View {
    var text: String
    var color: Color = Color(hex: "C97D5D")
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(hex: "FFF3F0"))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(color.opacity(0.6), lineWidth: 0.8))
    }
}

// MARK: - 建议 Chip
private struct AdviceChip: View {
    var item: WYAdviceItem
    @State private var expanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(item.text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "1F2A60").opacity(0.95))
                Spacer()
                Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "C97D5D")).opacity(0.9)
            }
            if expanded {
                HStack(alignment: .top, spacing: 6) {
                    Text("理由")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "C97D5D"))
                        .padding(.vertical, 2).padding(.horizontal, 6)
                        .background(Color(hex: "FFF3F0")).clipShape(RoundedRectangle(cornerRadius: 6))
                    Text(item.reason).font(.system(size: 12)).foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(hex: "F4B2A5").opacity(0.6), lineWidth: 0.8))
        .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } }
    }
}

// MARK: - 总结卡片
struct WuYunLiuQiSummaryCard: View {
    var data: WYCardData

    @State private var scope: Scope = .today
    @State private var appeared: Bool = false

    @State private var highlighted: (ring: DoubleRingRoseChartView.Ring, index: Int)? = nil

    enum Scope: String, CaseIterable { case today = "今日", month = "本月", year = "全年" }

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            headerSection
            tagsRow
            scopeSelector
            ringChart
            adviceSection
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 0.5)
        )
    }

    // 子视图拆分，降低类型检查复杂度
    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("五运六气 · 今日概览")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1F2A60").opacity(0.95))
            Spacer()
            Text(data.dateText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var tagsRow: some View {
        HStack(spacing: 6) {
            TagCapsule(text: "主运 \(data.mainYun)")
            TagCapsule(text: "主气 \(data.mainQi)")
            TagCapsule(text: data.excessType)
            TagCapsule(text: "司天 \(data.siTian)")
            TagCapsule(text: "在泉 \(data.zaiQuan)")
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    private var scopeSelector: some View {
        HStack(spacing: 6) {
            ForEach(Scope.allCases, id: \.self) { s in
                ScopeChip(
                    title: s.rawValue,
                    selected: scope == s,
                    onTap: { withAnimation(.easeInOut(duration: 0.2)) { scope = s } }
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private struct ScopeChip: View {
        let title: String
        let selected: Bool
        let onTap: () -> Void
        var body: some View {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(selected ? .white : Color(hex: "C97D5D"))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    Capsule().fill(selected ? Color(hex: "C97D5D") : Color(hex: "FFF3F0"))
                )
                .overlay(
                    Capsule().stroke(Color(hex: "F4B2A5").opacity(selected ? 0 : 0.7), lineWidth: 0.8)
                )
                .onTapGesture(perform: onTap)
        }
    }

    private var ringChart: some View {
        ZStack {
            DoubleRingRoseChartView(yunStrength: data.yunStrength, qiStrength: data.qiStrength, highlighted: $highlighted)
                .frame(height: 220)
                .frame(maxWidth: .infinity)
            VStack(spacing: 6) {
                Text("主运 · \(data.mainYun)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text("主气 · \(data.mainQi)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(8)
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.25), lineWidth: 0.6))
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(appeared ? 1.0 : 0.86)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.85, blendDuration: 0.1), value: appeared)
        .onAppear { appeared = true }
    }

    @ViewBuilder
    private var adviceSection: some View {
        if !data.advice.isEmpty {
            Text("今日重点建议")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "1F2A60").opacity(0.9))
            VStack(alignment: .leading, spacing: 8) {
                ForEach(data.advice.prefix(3)) { it in
                    AdviceChip(item: it)
                }
            }
        }
    }
}
