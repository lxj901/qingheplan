import SwiftUI

// 独立文件：口腔矢量形状（近似示意图轮廓）
public struct MouthShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        let leftMid = CGPoint(x: rect.minX, y: rect.midY)
        let rightMid = CGPoint(x: rect.maxX, y: rect.midY)
        // 控制点参数：可微调以贴近示意图
        let insetX = rect.width * 0.18
        let topY = rect.minY + rect.height * 0.08
        let bottomY = rect.maxY - rect.height * 0.08
        // 上唇曲线：左中 -> 右中（控制点靠近上方）
        let cp1 = CGPoint(x: rect.minX + insetX, y: topY)
        let cp2 = CGPoint(x: rect.maxX - insetX, y: topY)
        p.move(to: leftMid)
        p.addCurve(to: rightMid, control1: cp1, control2: cp2)
        // 下唇曲线：右中 -> 左中（控制点靠近下方）
        let cp3 = CGPoint(x: rect.maxX - insetX, y: bottomY)
        let cp4 = CGPoint(x: rect.minX + insetX, y: bottomY)
        p.addCurve(to: leftMid, control1: cp3, control2: cp4)
        p.closeSubpath()
        return p
    }
}

