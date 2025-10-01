import SwiftUI

/// 健康助手/健康页 设计主题
/// 统一定义背景渐变与常用颜色，便于复用与一致性
struct HealthDesignTheme {
    // MARK: - 颜色基准
    struct Colors {
        // 主色系（参考设计稿）
        static let healthGreen = Color(hex: "C3E88D")   // 清新绿
        static let healthMint  = Color(hex: "B2F0E1")   // 薄荷青
        static let healthWarm  = Color(hex: "FFE485")   // 温暖黄
        static let softShadow  = Color(hex: "B3ACA5")   // 右上角柔和阴影基色
    }

    // MARK: - 背景层
    struct Background {
        /// 基础线性渐变（与设计稿一致，带位置停靠）
        static let base = LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Colors.healthGreen, location: 0.0),
                .init(color: Colors.healthMint,  location: 0.55),
                .init(color: Colors.healthWarm,  location: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// 轻透明覆盖层（叠加柔和感）
        static let overlay = LinearGradient(
            colors: [Colors.healthGreen, Colors.healthMint, Colors.healthWarm],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// 顶部右侧径向柔光
        static func topRightGlow(opacity: Double = 0.22, endRadius: CGFloat = 520) -> RadialGradient {
            RadialGradient(
                colors: [
                    Colors.softShadow.opacity(opacity),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: endRadius
            )
        }
    }
}

// MARK: - 快捷修饰符
extension View {
    /// 健康助手页面的统一背景（三层叠加）
    func healthAssistantBackground() -> some View {
        self.background(
            ZStack {
                HealthDesignTheme.Background.base
                HealthDesignTheme.Background.overlay.opacity(0.28)
                HealthDesignTheme.Background.topRightGlow()
            }
            .ignoresSafeArea()
        )
    }
}

