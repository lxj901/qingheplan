import SwiftUI

// MARK: - 数据模型
struct RadarMetric: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let value: Double // 0...maxValue
}

// MARK: - 雷达图视图
struct RadarChartView: View {
    let metrics: [RadarMetric]
    var maxValue: Double = 100

    // 外观
    var gridCount: Int = 4
    var showVertices: Bool = true
    var showLabels: Bool = true

    // 颜色
    var fillColor: Color = Color(hex: "A67C52").opacity(0.35)
    var strokeColor: Color = Color(hex: "8D6E63").opacity(0.9)
    var gridColor: Color = .gray.opacity(0.18)
    var axisColor: Color = .gray.opacity(0.22)

    var body: some View {
        GeometryReader { geo in
            // 基础几何参数
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2.0 - 10
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            let count = max(3, metrics.count)
            let angles: [Double] = (0..<count).map { i in
                // 顶部为第一个点，顺时针分布
                let step = (2 * Double.pi) / Double(count)
                return -Double.pi/2 + Double(i) * step
            }

            ZStack {
                gridLayer(center: center, radius: radius, angles: angles)
                axesLayer(center: center, radius: radius, angles: angles)
                polygonLayer(center: center, radius: radius, angles: angles)
                if showVertices { verticesLayer(center: center, radius: radius, angles: angles) }
                if showLabels { labelsLayer(center: center, radius: radius, angles: angles) }
            }
        }
    }
}

// MARK: - 子图层拆分，降低类型检查复杂度
private extension RadarChartView {
    func point(center: CGPoint, angle: Double, radius: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + CGFloat(cos(angle)) * radius,
            y: center.y + CGFloat(sin(angle)) * radius
        )
    }

    func valueRatio(_ value: Double) -> CGFloat {
        CGFloat(max(0, min(value / maxValue, 1)))
    }

    @ViewBuilder
    func gridLayer(center: CGPoint, radius: CGFloat, angles: [Double]) -> some View {
        ForEach(1...gridCount, id: \.self) { level in
            let progress = Double(level) / Double(gridCount)
            Path { p in
                for (idx, angle) in angles.enumerated() {
                    let pt = point(center: center, angle: angle, radius: radius * progress)
                    if idx == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
            }
            .stroke(gridColor, style: StrokeStyle(lineWidth: 1, dash: [4,4]))
        }
    }

    @ViewBuilder
    func axesLayer(center: CGPoint, radius: CGFloat, angles: [Double]) -> some View {
        ForEach(0..<angles.count, id: \.self) { i in
            Path { p in
                p.move(to: center)
                p.addLine(to: point(center: center, angle: angles[i], radius: radius))
            }
            .stroke(axisColor, lineWidth: 0.8)
        }
    }

    @ViewBuilder
    func polygonLayer(center: CGPoint, radius: CGFloat, angles: [Double]) -> some View {
        Group {
            Path { p in
                for (idx, metric) in metrics.enumerated() {
                    let r = radius * valueRatio(metric.value)
                    let pt = point(center: center, angle: angles[idx], radius: r)
                    if idx == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
            }
            .fill(fillColor)

            Path { p in
                for (idx, metric) in metrics.enumerated() {
                    let r = radius * valueRatio(metric.value)
                    let pt = point(center: center, angle: angles[idx], radius: r)
                    if idx == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
            }
            .stroke(strokeColor, lineWidth: 2)
        }
    }

    @ViewBuilder
    func verticesLayer(center: CGPoint, radius: CGFloat, angles: [Double]) -> some View {
        ForEach(Array(metrics.enumerated()), id: \.offset) { (idx, metric) in
            let r = radius * valueRatio(metric.value)
            let pt = point(center: center, angle: angles[idx], radius: r)
            Circle()
                .fill(strokeColor)
                .frame(width: 6, height: 6)
                .position(pt)
                .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 1))
        }
    }

    @ViewBuilder
    func labelsLayer(center: CGPoint, radius: CGFloat, angles: [Double]) -> some View {
        ForEach(Array(metrics.enumerated()), id: \.offset) { (idx, metric) in
            let labelR = radius + 18
            let pt = point(center: center, angle: angles[idx], radius: labelR)
            Text(metric.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "6B4E3D").opacity(0.9))
                .position(pt)
        }
    }
}

// MARK: - 预览
struct RadarChartView_Previews: PreviewProvider {
    static var previews: some View {
        RadarChartView(
            metrics: [
                RadarMetric(name: "综合", value: 75),
                RadarMetric(name: "体质", value: 80),
                RadarMetric(name: "运动", value: 60),
                RadarMetric(name: "睡眠", value: 70),
                RadarMetric(name: "BMI", value: 85)
            ]
        )
        .frame(width: 260, height: 260)
        .padding()
        .background(Color.white)
    }
}

