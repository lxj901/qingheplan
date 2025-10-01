import SwiftUI

// 体质圆形图（外圈五脏，内圈九体质趋势）
struct ConstitutionCircleView: View {
    var organs: [String: Double] // 心、肝、脾、肺、肾 -> 0~1
    var nineScores: [String: Double] // 九种体质 -> 0~1

    private let organOrder = ["心","肝","脾","肺","肾"]
    private let organColors: [String: Color] = [
        "心": Color(hex: "FF8A80"),
        "肝": Color(hex: "81C784"),
        "脾": Color(hex: "FFD180"),
        "肺": Color(hex: "A5D6A7"),
        "肾": Color(hex: "80D8FF")
    ]

    private let nineOrder = ["平和","气虚","阳虚","阴虚","痰湿","湿热","血瘀","气郁","特禀"]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            let outerRadius = size/2
            let ringThickness: CGFloat = 20
            let innerRadius = outerRadius - ringThickness - 14

            ZStack {
                // 外圈：五脏圆环 + 标签
                ForEach(Array(organOrder.enumerated()), id: \.offset) { (idx, name) in
                    let value = min(max(organs[name] ?? 0, 0), 1)
                    let start = CGFloat(idx) / CGFloat(organOrder.count)
                    let end = CGFloat(idx + 1) / CGFloat(organOrder.count)
                    let midA = (start + end) / 2 * 2 * .pi - .pi/2

                    Circle()
                        .trim(from: start, to: start + (end - start) * max(0.2, value))
                        .stroke(
                            AngularGradient(
                                colors: [organColors[name] ?? .blue, (organColors[name] ?? .blue).opacity(0.7)],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: ringThickness, lineCap: .round)
                        )
                        .frame(width: outerRadius * 2, height: outerRadius * 2)
                        .rotationEffect(.degrees(-90))

                    // 标签
                    let pos = CGPoint(
                        x: center.x + (outerRadius - ringThickness/2) * cos(midA),
                        y: center.y + (outerRadius - ringThickness/2) * sin(midA)
                    )
                    VStack(spacing: 2) {
                        Text(name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor((organColors[name] ?? .blue).opacity(0.95))
                        Text(String(format: "%.0f%%", value * 100))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .position(pos)
                }

                // 内圈：九种体质趋势（雷达状折线）
                Path { p in
                    for (i, key) in nineOrder.enumerated() {
                        let angle = -CGFloat.pi/2 + CGFloat(i) * (2 * .pi / CGFloat(nineOrder.count))
                        let ratio = min(max(nineScores[key] ?? 0, 0), 1)
                        let r = innerRadius * (0.3 + 0.7 * ratio)
                        let pt = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                    p.closeSubpath()
                }
                .fill(Color(hex: "A67C52").opacity(0.18))

                Path { p in
                    for (i, key) in nineOrder.enumerated() {
                        let angle = -CGFloat.pi/2 + CGFloat(i) * (2 * .pi / CGFloat(nineOrder.count))
                        let ratio = min(max(nineScores[key] ?? 0, 0), 1)
                        let r = innerRadius * (0.3 + 0.7 * ratio)
                        let pt = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                    p.closeSubpath()
                }
                .stroke(Color(hex: "8D6E63").opacity(0.9), lineWidth: 2)

                // 内圈坐标与标签
                ForEach(Array(nineOrder.enumerated()), id: \.offset) { (i, key) in
                    let angle = -CGFloat.pi/2 + CGFloat(i) * (2 * .pi / CGFloat(nineOrder.count))
                    let baseR = innerRadius + 10
                    let pt = CGPoint(x: center.x + baseR * cos(angle), y: center.y + baseR * sin(angle))
                    Text(key)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .position(pt)
                }

                // 中心标题
                VStack(spacing: 2) {
                    Text("体质趋势")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "1F2A60").opacity(0.9))
                    Text("九种体质")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

