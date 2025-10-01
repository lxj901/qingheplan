import SwiftUI

/// 现代化设计系统
struct ModernDesignSystem {
    
    // MARK: - 字体系统
    struct Typography {
        // 使用动态字体管理器
        static var largeTitle: Font { FontManager.shared.font(for: .largeTitle) }
        static var title1: Font { FontManager.shared.font(for: .title1) }
        static var title2: Font { FontManager.shared.font(for: .title2) }
        static var title3: Font { FontManager.shared.font(for: .title3) }
        static var headline: Font { FontManager.shared.font(for: .headline) }
        static var body: Font { FontManager.shared.font(for: .body) }
        static var callout: Font { FontManager.shared.font(for: .callout) }
        static var subheadline: Font { FontManager.shared.font(for: .subheadline) }
        static var footnote: Font { FontManager.shared.font(for: .footnote) }
        static var caption1: Font { FontManager.shared.font(for: .caption1) }
        static var caption2: Font { FontManager.shared.font(for: .caption2) }

        // 数字字体
        static var numberLarge: Font { FontManager.shared.font(for: .numberLarge) }
        static var numberMedium: Font { FontManager.shared.font(for: .numberMedium) }
        static var numberSmall: Font { FontManager.shared.font(for: .numberSmall) }

        // 睡眠相关字体（映射到现有样式）
        static var subtitle: Font { FontManager.shared.font(for: .title3) }
        static var bodyMedium: Font { FontManager.shared.font(for: .bodyMedium) }
        static var caption: Font { FontManager.shared.font(for: .footnote) }

        // 兼容性：保留原有的静态字体定义作为后备
        struct Static {
            static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
            static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
            static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
            static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
            static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
            static let body = Font.system(size: 17, weight: .regular, design: .default)
            static let callout = Font.system(size: 16, weight: .regular, design: .default)
            static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
            static let footnote = Font.system(size: 13, weight: .regular, design: .default)
            static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
            static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        }
    }
    
    // MARK: - 间距系统
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        
        // 页面间距
        static let pageHorizontal: CGFloat = 20
        static let pageVertical: CGFloat = 16
        
        // 卡片间距
        static let cardPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 12
    }
    
    // MARK: - 阴影系统
    struct Shadow {
        static let light = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let heavy = (color: Color.black.opacity(0.15), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
    
    // MARK: - 阴影系统（新版）
    struct Shadows {
        struct ShadowStyle {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
        
        static let card = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let button = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    // MARK: - 颜色扩展
    struct Colors {
        // 主色调 - 使用开屏页面的自然绿色系
        static let primaryGreen = Color(red: 76/255, green: 175/255, blue: 80/255)        // #4CAF50 - 开屏页面主色
        static let primaryGreenLight = Color(red: 139/255, green: 195/255, blue: 74/255)  // #8BC34A - 开屏页面渐变色
        static let primaryGreenDark = Color(red: 56/255, green: 142/255, blue: 60/255)    // #388E3C - 深色版本

        // 分段选择器专用色
        static let segmentedBackground = Color(.systemGray6)
        static let segmentedSelected = Color(red: 76/255, green: 175/255, blue: 80/255)  // #4CAF50 - 使用侧边菜单首页的青禾绿色
        static let segmentedUnselected = Color(.systemGray)
        
        // 强调色
        static let accentBlue = Color(red: 33/255, green: 150/255, blue: 243/255)
        static let accentOrange = Color(red: 255/255, green: 152/255, blue: 0/255)
        static let accentPurple = Color(red: 156/255, green: 39/255, blue: 176/255)
        
        // 功能色
        static let successGreen = Color(red: 76/255, green: 175/255, blue: 80/255)
        static let warningOrange = Color(red: 255/255, green: 193/255, blue: 7/255)
        static let errorRed = Color(red: 244/255, green: 67/255, blue: 54/255)
        static let infoBlue = Color(red: 33/255, green: 150/255, blue: 243/255)
        
        // 文本颜色 - 使用系统动态颜色
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        static let textDisabled = Color(.quaternaryLabel)

        // 背景色 - 使用系统动态颜色
        static let backgroundPrimary = Color(.systemBackground)
        static let backgroundSecondary = Color(.secondarySystemBackground)
        static let backgroundCard = Color(.systemBackground)
        static let backgroundOverlay = Color(.systemBackground).opacity(0.8)

        // 聊天专用背景色 - 使用系统动态颜色
        static let chatBackground = Color(.secondarySystemBackground)
        static let chatBubbleReceived = Color(.systemBackground)
        static let chatBubbleSent = Color(red: 76/255, green: 175/255, blue: 80/255)

        // 边框色 - 使用系统动态颜色
        static let borderLight = Color(.separator)
        static let borderMedium = Color(.opaqueSeparator)
        static let borderDark = Color(.systemGray3)

        // 热力图颜色
        static let heatmapLevel0 = Color(red: 235/255, green: 237/255, blue: 240/255)
        static let heatmapLevel1 = Color(red: 155/255, green: 233/255, blue: 168/255)
        static let heatmapLevel2 = Color(red: 64/255, green: 196/255, blue: 99/255)
        static let heatmapLevel3 = Color(red: 48/255, green: 161/255, blue: 78/255)
        static let heatmapLevel4 = Color(red: 33/255, green: 110/255, blue: 57/255)
        
        // 阴影颜色 - 使用系统动态颜色
        static let shadowColor = Color(.systemGray4).opacity(0.3)

        // 中式扩展色（纸感与金色点缀）
        static let paperIvory = Color(red: 247/255, green: 244/255, blue: 237/255)
        static let accentGold = Color(red: 201/255, green: 169/255, blue: 106/255)
    }
    
    // MARK: - 圆角扩展
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let round: CGFloat = 50

        // 卡片圆角
        static let card: CGFloat = 16
        
        // 按钮圆角
        static let button: CGFloat = 12
    }
    
    // MARK: - 动画系统
    struct Animation {
        static let springQuick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)
        static let springStandard = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
        static let springSlow = SwiftUI.Animation.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.3)
    }
}

// MARK: - 扩展方法
extension View {
    /// 现代化卡片样式
    func modernCardStyle() -> some View {
        self
            .background(ModernDesignSystem.Colors.backgroundCard)
            .cornerRadius(ModernDesignSystem.CornerRadius.lg)
            .shadow(
                color: ModernDesignSystem.Shadow.light.color,
                radius: ModernDesignSystem.Shadow.light.radius,
                x: ModernDesignSystem.Shadow.light.x,
                y: ModernDesignSystem.Shadow.light.y
            )
    }

    /// 现代化按钮样式
    func modernButtonStyle(color: Color = ModernDesignSystem.Colors.primaryGreen) -> some View {
        self
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            .padding(.vertical, ModernDesignSystem.Spacing.md)
            .background(color)
            .cornerRadius(ModernDesignSystem.CornerRadius.md)
            .shadow(
                color: color.opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
    }

    /// 热力图单元格样式
    func heatmapCell(level: Int) -> some View {
        let color: Color
        switch level {
        case 0: color = ModernDesignSystem.Colors.heatmapLevel0
        case 1: color = ModernDesignSystem.Colors.heatmapLevel1
        case 2: color = ModernDesignSystem.Colors.heatmapLevel2
        case 3: color = ModernDesignSystem.Colors.heatmapLevel3
        default: color = ModernDesignSystem.Colors.heatmapLevel4
        }

        return self
            .background(color)
            .cornerRadius(2)
    }
}

struct ScrollOffsetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                }
            )
    }
}
