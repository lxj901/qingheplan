import SwiftUI

// MARK: - ModernDesignSystem扩展方法
extension View {
    /// 现代化卡片样式
    func modernCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.card)
                    .fill(ModernDesignSystem.Colors.backgroundCard)
                    .shadow(
                        color: ModernDesignSystem.Colors.shadowColor,
                        radius: ModernDesignSystem.Shadows.card.radius,
                        x: ModernDesignSystem.Shadows.card.x,
                        y: ModernDesignSystem.Shadows.card.y
                    )
            )
    }
    
    /// 现代化卡片内边距
    func modernCardPadding() -> some View {
        self.padding(ModernDesignSystem.Spacing.cardPadding)
    }
    
    /// 现代化页面内边距
    func modernPagePadding() -> some View {
        self.padding(.horizontal, ModernDesignSystem.Spacing.pageHorizontal)
    }
    
    /// 现代化按钮样式
    func modernButton(style: ModernButtonStyle) -> some View {
        ModernButton(style: style) {
            self
        }
    }

    /// 添加用户反馈支持（Toast提示）
    func withUserFeedback() -> some View {
        self.modifier(UserFeedbackModifier())
    }
}

// MARK: - 现代化按钮
struct ModernButton<Content: View>: View {
    let style: ModernButtonStyle
    let content: Content
    
    init(style: ModernButtonStyle, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        Button(action: {}) {
            content
                .foregroundColor(style.textColor)
                .padding(.horizontal, style.horizontalPadding)
                .padding(.vertical, style.verticalPadding)
                .background(
                    RoundedRectangle(cornerRadius: style.cornerRadius)
                        .fill(style.backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: style.cornerRadius)
                                .stroke(style.borderColor, lineWidth: style.borderWidth)
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

enum ModernButtonStyle {
    case primary
    case secondary
    case tertiary
    
    var backgroundColor: Color {
        switch self {
        case .primary: return ModernDesignSystem.Colors.primaryGreen
        case .secondary: return ModernDesignSystem.Colors.backgroundSecondary
        case .tertiary: return Color.clear
        }
    }
    
    var textColor: Color {
        switch self {
        case .primary: return .white
        case .secondary: return ModernDesignSystem.Colors.textPrimary
        case .tertiary: return ModernDesignSystem.Colors.primaryGreen
        }
    }
    
    var borderColor: Color {
        switch self {
        case .primary: return Color.clear
        case .secondary: return ModernDesignSystem.Colors.borderLight
        case .tertiary: return ModernDesignSystem.Colors.primaryGreen
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .primary: return 0
        case .secondary: return 1
        case .tertiary: return 1
        }
    }
    
    var horizontalPadding: CGFloat {
        return ModernDesignSystem.Spacing.lg
    }
    
    var verticalPadding: CGFloat {
        return ModernDesignSystem.Spacing.md
    }
    
    var cornerRadius: CGFloat {
        return ModernDesignSystem.CornerRadius.button
    }
}

// MARK: - 按钮样式
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(ModernDesignSystem.Animation.springQuick, value: configuration.isPressed)
    }
}

// MARK: - 主要按钮样式
struct PrimaryButtonStyle: ButtonStyle {
    let color: Color

    init(color: Color = AppConstants.Colors.primaryGreen) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 滚动偏移监听
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollOffsetReader: View {
    let coordinateSpace: String
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named(coordinateSpace)).minY
                )
        }
        .frame(height: 0)
    }
}

// MARK: - 扩展方法
extension Data {
    func toDictionary() throws -> [String: Any] {
        let dictionary = try JSONSerialization.jsonObject(with: self, options: .allowFragments) as? [String: Any]
        return dictionary ?? [:]
    }
}

// MARK: - 用户反馈修饰符
struct UserFeedbackModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            // 这里可以添加Toast提示的实现
            // 目前只是一个占位符
    }
}