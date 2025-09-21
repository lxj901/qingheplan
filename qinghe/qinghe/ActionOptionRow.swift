import SwiftUI

/// 通用的操作选项行组件
struct ActionOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isDestructive ? ModernDesignSystem.Colors.errorRed : ModernDesignSystem.Colors.primaryGreen)
                    .frame(width: 24, height: 24)
                
                // 文本信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDestructive ? ModernDesignSystem.Colors.errorRed : ModernDesignSystem.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            .padding(.vertical, ModernDesignSystem.Spacing.md)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
