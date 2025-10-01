import SwiftUI

/// 可复用的星空背景（源自睡眠管理页面的动态背景）
/// - 特性：
///   - 深色径向渐变基底
///   - 可选的月光/光晕呼吸动画
///   - 闪烁的星空粒子
struct StarfieldBackgroundView: View {
    // 配置
    var starCount: Int = 40
    var includePulsingGlow: Bool = true

    // 动画状态
    @State private var pulseAnimation: Bool = false
    @State private var starAnimation: Bool = false
    @State private var starDrift: Bool = false

    // 预计算的星星属性，避免每次刷新随机重算导致闪烁跳变
    private let stars: [Star]

    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
        let duration: Double   // 闪烁周期
        let delay: Double      // 相位错开
        let driftX: CGFloat    // 位移幅度X
        let driftY: CGFloat    // 位移幅度Y
        let driftDuration: Double // 漂移周期
    }

    init(starCount: Int = 40, includePulsingGlow: Bool = true) {
        self.starCount = starCount
        self.includePulsingGlow = includePulsingGlow

        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height
        var temp: [Star] = []
        for i in 0..<max(0, starCount) {
            let driftAmp: CGFloat = CGFloat.random(in: 4...16)
            let driftX = driftAmp * (Bool.random() ? 1 : -1)
            let driftY = driftAmp * (Bool.random() ? 1 : -1) * CGFloat.random(in: 0.3...1.0)
            temp.append(
                Star(
                    x: CGFloat.random(in: 0...screenW),
                    y: CGFloat.random(in: 0...(screenH * 0.9)),
                    size: CGFloat.random(in: 1...3.5),
                    opacity: Double.random(in: 0.25...0.85),
                    duration: Double.random(in: 1.8...3.6),
                    delay: Double(i) * 0.08,
                    driftX: driftX,
                    driftY: driftY,
                    driftDuration: Double.random(in: 6.0...12.0)
                )
            )
        }
        self.stars = temp
    }

    var body: some View {
        ZStack {
            // 深度渐变背景
            RadialGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.25),
                    Color(red: 0.05, green: 0.08, blue: 0.18),
                    Color(red: 0.02, green: 0.05, blue: 0.12)
                ],
                center: .topTrailing,
                startRadius: 100,
                endRadius: 800
            )
            .ignoresSafeArea()

            if includePulsingGlow {
                // 动态光晕 / 月光效果
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 220
                        )
                    )
                    .frame(width: 420, height: 420)
                    .position(x: UIScreen.main.bounds.width * 0.78, y: 120)
                    .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                    .opacity(pulseAnimation ? 0.6 : 0.3)
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: pulseAnimation)
            }

            // 星空粒子（闪烁 + 缓慢漂移）
            ForEach(stars) { star in
                // 闪烁
                let dot = Circle()
                    .fill(Color.white.opacity(star.opacity))
                    .frame(width: star.size, height: star.size)
                    .scaleEffect(starAnimation ? 1.0 : 0.5)
                    .opacity(starAnimation ? 1.0 : 0.35)
                    .animation(
                        Animation.easeInOut(duration: star.duration)
                            .repeatForever(autoreverses: true)
                            .delay(star.delay),
                        value: starAnimation
                    )

                // 外层容器用于位移漂移
                dot
                    .position(x: star.x, y: star.y)
                    .offset(x: starDrift ? star.driftX : -star.driftX,
                            y: starDrift ? star.driftY : -star.driftY)
                    .animation(
                        Animation.easeInOut(duration: star.driftDuration)
                            .repeatForever(autoreverses: true)
                            .delay(star.delay * 0.3),
                        value: starDrift
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
                starAnimation = true
            }
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                starDrift = true
            }
        }
    }
}

#Preview("StarfieldBackgroundView") {
    ZStack {
        StarfieldBackgroundView(starCount: 60, includePulsingGlow: true)
        VStack(spacing: 8) {
            Text("五运六气")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text("背景预览")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
