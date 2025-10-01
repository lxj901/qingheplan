import SwiftUI

/// 五运主运图（五圈版）
/// 说明：
/// - 可配置多圈等分、沿弧文字、径向分隔线；
/// - 本实现按照“木火土金水 / 十天干 / 五运阶段 / 五音太少 / 节气交节提示”五圈渲染；
/// - 保持暗色 + 国风黄作为主视觉。
struct WuYunZhuYunDiagramView: View {
    // 配置：整体尺寸
    var size: CGFloat = 320

    // 配置：色彩
    private let accentYellow = Color(red: 1.0, green: 0.78, blue: 0.20) // 国风黄
    private let thinLine = Color.white.opacity(0.12)
    private let textDim = Color.white.opacity(0.85)
    private let ringSpacing: CGFloat = 6

    // 圈配置（内到外）——五运主运图（五圈）
    // 1) 第一圈：五行（从12点顺时针）
    // 2) 第二圈：天干（甲乙丙丁戊己庚辛壬癸）
    // 3) 第三圈：五运阶段（初運、二運、三運、四運、終運）
    // 4) 第四圈：五音“太/少”（少角、太角、少徵、太徵、少宫、太宫、少商、太商、少羽、太羽）
    // 5) 最外圈：节气交节提示（示例）
    private let ringSpecs: [RingSpec] = [
        // 第一圈：火 → 土 → 金 → 水 → 木（以“火”居上，与图一致）
        .init(names: ["火","土","金","水","木"], thickness: 22),
        // 第二圈：十天干（甲起上方，顺时针）
        .init(names: ["甲","乙","丙","丁","戊","己","庚","辛","壬","癸"], thickness: 22),
        // 第三圈：五运阶段
        .init(names: ["初運","二運","三運","四運","終運"], thickness: 22),
        // 第四圈：五音太少（10等分）
        .init(names: ["少角","太角","少徵","太徵","少宫","太宫","少商","太商","少羽","太羽"], thickness: 24),
        // 第五圈：交节提示（以“春分后十三日交”居上，顺时针）
        .init(names: ["春分后十三日交","芒种后十日交","处暑后七日交","立冬后四日交","大寒日交"], thickness: 22)
    ]

    struct RingSpec {
        let names: [String]
        let thickness: CGFloat
    }

    var body: some View {
        ZStack {
            // 背板（轻微晕光）
            Circle()
                .fill(Color.white.opacity(0.02))
                .overlay(Circle().stroke(Color.white.opacity(0.06), lineWidth: 1))
                .frame(width: size, height: size)

            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                let maxRadius = size/2 - 8
                let baseInner = maxRadius - totalRingsThickness()

                ZStack {
                    ForEach(ringSpecs.indices, id: \.self) { idx in
                        let ring = ringSpecs[idx]
                        let innerR = baseInner + cumulativeThickness(upto: idx) + CGFloat(idx) * ringSpacing
                        RingLayerView(center: center,
                                      innerRadius: innerR,
                                      thickness: ring.thickness,
                                      names: ring.names,
                                      clockwise: true,
                                      centerStartsAtTop: true,
                                      accentYellow: accentYellow,
                                      thinLine: thinLine,
                                      textDim: textDim)
                    }

                    // 中心：标题（占位）
                    VStack(spacing: 6) {
                        Text("五运主运图")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(accentYellow)
                        Text("示意版 · 待替换正式文案")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 1))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: size, height: size)
    }

    private func polar(center: CGPoint, r: CGFloat, a: CGFloat) -> CGPoint {
        CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
    }

    private func totalRingsThickness() -> CGFloat {
        ringSpecs.reduce(0) { $0 + $1.thickness } + CGFloat(max(0, ringSpecs.count - 1)) * ringSpacing
    }

    private func cumulativeThickness(upto index: Int) -> CGFloat {
        guard index > 0 else { return 0 }
        return ringSpecs.prefix(index).reduce(0) { $0 + $1.thickness }
    }

    // 单圈图层视图，拆分以降低编译器复杂度
    private struct RingLayerView: View {
        let center: CGPoint
        let innerRadius: CGFloat
        let thickness: CGFloat
        let names: [String]
        let clockwise: Bool
        let centerStartsAtTop: Bool
        let accentYellow: Color
        let thinLine: Color
        let textDim: Color

        var body: some View {
            let outerR = innerRadius + thickness
            let count = names.count
            let step = 2 * .pi / CGFloat(max(1, count))
            let dir: CGFloat = clockwise ? -1 : 1
            let centerStart: CGFloat = centerStartsAtTop ? (-.pi/2) : 0
            let labelR = innerRadius + thickness/2
            let maxChars = max(1, names.map { $0.count }.max() ?? 1)
            // 估算可用弧长，并把字体大小限制在可用空间内，避免重叠
            let availableArc = labelR * step
            let baseFont = ringLabelFontSize(for: count)
            // 中文等宽近似：字符宽 ~ 字号，留出余量 10pt
            let fittedFont = max(8, min(baseFont, (availableArc - 10) / CGFloat(maxChars)))
            return ZStack {
                // 圈框
                Circle()
                    .stroke(thinLine, lineWidth: 1)
                    .frame(width: outerR * 2, height: outerR * 2)

                // 分隔线（径向）
                ForEach(0..<count, id: \.self) { i in
                    let angle = centerStart + dir * (CGFloat(i) * step - step/2)
                    Path { p in
                        p.move(to: polar(center: center, r: innerRadius, a: angle))
                        p.addLine(to: polar(center: center, r: outerR, a: angle))
                    }
                    .stroke(thinLine, lineWidth: 1)
                }

                // 标签
                ForEach(0..<count, id: \.self) { i in
                    let midA = centerStart + dir * (CGFloat(i) * step)
                    let pos = polar(center: center, r: labelR, a: midA)
                    Text(names[i])
                        .font(.system(size: fittedFont, weight: .semibold))
                        .foregroundColor(i % 2 == 0 ? accentYellow : textDim)
                        .position(x: pos.x, y: pos.y)
                        // 与弧线切向对齐更节省左右空间
                        .rotationEffect(.radians(midA - .pi/2))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .allowsTightening(true)
                }
            }
        }

        private func polar(center: CGPoint, r: CGFloat, a: CGFloat) -> CGPoint {
            CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
        }

        private func ringLabelFontSize(for count: Int) -> CGFloat {
            switch count {
            case 4...6: return 13
            case 7...12: return 11
            default: return 10
            }
        }
    }


    private func ringLabelFontSize(for count: Int) -> CGFloat {
        switch count {
        case 4...6: return 13
        case 7...12: return 11
        default: return 10
        }
    }
}

// 为避免命名冲突与编译压力，另起一个 preview 结构
struct WuYunZhuYunDiagramView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            StarfieldBackgroundView(starCount: 60)
            WuYunZhuYunDiagramView(size: 320)
        }
        .previewDisplayName("WuYunZhuYunDiagramView")
    }
}
