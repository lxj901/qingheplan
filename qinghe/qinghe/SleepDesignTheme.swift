import SwiftUI

/// 睡眠功能设计主题
/// 为睡眠相关功能提供统一的设计规范和样式
struct SleepDesignTheme {
    
    // MARK: - 颜色系统
    struct Colors {
        // 主色调 - 睡眠主题色
        static let primarySleep = Color(red: 102/255, green: 126/255, blue: 234/255)  // 深蓝紫色
        static let accentSleep = Color(red: 138/255, green: 43/255, blue: 226/255)   // 紫色强调色
        
        // 夜间渐变色
        static let nightGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 25/255, green: 25/255, blue: 112/255),  // 深蓝
                Color(red: 72/255, green: 61/255, blue: 139/255)   // 深紫
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // 背景色
        static let backgroundPrimary = Color(red: 15/255, green: 15/255, blue: 35/255)
        static let backgroundSecondary = Color(red: 25/255, green: 25/255, blue: 45/255)
        static let backgroundCard = Color(red: 35/255, green: 35/255, blue: 55/255)
        
        // 文本色
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 200/255, green: 200/255, blue: 220/255)
        static let textTertiary = Color(red: 150/255, green: 150/255, blue: 180/255)
    }
    
    // MARK: - 字体系统
    struct Fonts {
        static let title = Font.system(size: 24, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let bodyLarge = Font.system(size: 18, weight: .medium, design: .rounded)
        static let bodyMedium = Font.system(size: 16, weight: .regular, design: .rounded)
        static let bodySmall = Font.system(size: 14, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
        static let footnote = Font.system(size: 10, weight: .regular, design: .rounded)
    }
    
    // MARK: - 尺寸系统
    struct Sizes {
        // 内边距
        static let paddingSmall: CGFloat = 8
        static let paddingMedium: CGFloat = 12
        static let paddingLarge: CGFloat = 16
        static let paddingXLarge: CGFloat = 24
        
        // 圆角
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16
        static let cornerRadiusXLarge: CGFloat = 24
        
        // 图标尺寸
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 32
        static let iconXLarge: CGFloat = 48
        
        // 按钮尺寸
        static let buttonHeight: CGFloat = 48
        static let buttonHeightSmall: CGFloat = 36
        static let buttonHeightLarge: CGFloat = 56
    }
    
    // MARK: - 阴影系统
    struct Shadows {
        struct ShadowStyle {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
        
        static let light = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let medium = ShadowStyle(
            color: Color.black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let heavy = ShadowStyle(
            color: Color.black.opacity(0.3),
            radius: 16,
            x: 0,
            y: 8
        )
    }
    
    // MARK: - 动画系统
    struct Animations {
        static let quick = Animation.easeInOut(duration: 0.2)
        static let standard = Animation.easeInOut(duration: 0.3)
        static let slow = Animation.easeInOut(duration: 0.5)
        static let spring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    }
}

// MARK: - 扩展方法
extension View {
    /// 睡眠主题卡片样式
    func sleepCardStyle() -> some View {
        self
            .background(SleepDesignTheme.Colors.backgroundCard)
            .cornerRadius(SleepDesignTheme.Sizes.cornerRadiusLarge)
            .shadow(
                color: SleepDesignTheme.Shadows.medium.color,
                radius: SleepDesignTheme.Shadows.medium.radius,
                x: SleepDesignTheme.Shadows.medium.x,
                y: SleepDesignTheme.Shadows.medium.y
            )
    }
    
    /// 睡眠主题按钮样式
    func sleepButtonStyle(color: Color = SleepDesignTheme.Colors.primarySleep) -> some View {
        self
            .foregroundColor(SleepDesignTheme.Colors.textPrimary)
            .padding(.horizontal, SleepDesignTheme.Sizes.paddingLarge)
            .padding(.vertical, SleepDesignTheme.Sizes.paddingMedium)
            .background(color)
            .cornerRadius(SleepDesignTheme.Sizes.cornerRadiusMedium)
            .shadow(
                color: color.opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
    }
    
    /// 现代化阴影效果
    func modernShadow(_ shadow: SleepDesignTheme.Shadows.ShadowStyle) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}
