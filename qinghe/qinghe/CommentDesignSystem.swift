import SwiftUI

/// 评论组件设计系统
/// 定义评论相关组件的统一设计规范、样式和交互标准
struct CommentDesignSystem {
    
    // MARK: - 布局规范
    struct Layout {
        /// 头像尺寸
        static let avatarSize: CGFloat = 40
        static let avatarCornerRadius: CGFloat = 20
        
        /// 嵌套层级 - 移除最大层级限制，支持无限层级
        static let indentationWidth: CGFloat = ModernDesignSystem.Spacing.lg // 16pt
        
        /// 连接线
        static let connectionLineWidth: CGFloat = 1
        static let connectionLineOffset: CGFloat = avatarSize / 2 // 20pt
        
        /// 内容区域
        static let contentMinHeight: CGFloat = 44
        static let actionButtonSize: CGFloat = 32
        static let actionButtonIconSize: CGFloat = 16
    }
    
    // MARK: - 间距规范
    struct Spacing {
        /// 评论行内部间距 - 增加更舒适的间距
        static let commentRowPadding = EdgeInsets(
            top: ModernDesignSystem.Spacing.xl,    // 20pt (进一步增加)
            leading: ModernDesignSystem.Spacing.lg, // 16pt
            bottom: ModernDesignSystem.Spacing.xl,  // 20pt (进一步增加)
            trailing: ModernDesignSystem.Spacing.lg // 16pt
        )

        /// 头像与内容间距 - 增加间距
        static let avatarToContent: CGFloat = ModernDesignSystem.Spacing.lg // 16pt (增加)

        /// 用户信息与评论内容间距 - 增加间距
        static let userInfoToContent: CGFloat = ModernDesignSystem.Spacing.md // 12pt (增加)

        /// 评论内容与操作按钮间距 - 增加间距
        static let contentToActions: CGFloat = ModernDesignSystem.Spacing.lg // 16pt (增加)

        /// 操作按钮间距
        static let actionButtonSpacing: CGFloat = ModernDesignSystem.Spacing.xl // 20pt (增加)

        /// 嵌套评论额外间距 - 增加间距
        static let nestedCommentSpacing: CGFloat = ModernDesignSystem.Spacing.md // 12pt (增加)
    }
    
    // MARK: - 字体规范
    struct Typography {
        /// 用户昵称
        static let nickname = Font.system(size: 15, weight: .medium)
        
        /// 用户等级/认证标识
        static let userBadge = Font.system(size: 11, weight: .medium)
        
        /// 评论内容
        static let content = Font.system(size: 15, weight: .regular)
        
        /// 时间戳
        static let timestamp = Font.system(size: 13, weight: .regular)
        
        /// 操作按钮文字
        static let actionButton = Font.system(size: 13, weight: .medium)
        
        /// 回复提示
        static let replyHint = Font.system(size: 13, weight: .regular)
        
        /// 展开/收起提示
        static let expandHint = Font.system(size: 13, weight: .medium)
    }
    
    // MARK: - 颜色规范
    struct Colors {
        /// 用户昵称颜色
        static let nickname = ModernDesignSystem.Colors.textPrimary
        
        /// 评论内容颜色
        static let content = ModernDesignSystem.Colors.textPrimary
        
        /// 时间戳颜色
        static let timestamp = ModernDesignSystem.Colors.textSecondary
        
        /// 操作按钮默认颜色
        static let actionDefault = ModernDesignSystem.Colors.textSecondary
        
        /// 操作按钮激活颜色
        static let actionActive = ModernDesignSystem.Colors.primaryGreen
        
        /// 点赞按钮激活颜色
        static let likeActive = ModernDesignSystem.Colors.errorRed
        
        /// 连接线颜色
        static let connectionLine = ModernDesignSystem.Colors.borderLight
        
        /// 嵌套背景颜色（按层级）
        static func nestedBackground(for level: Int) -> Color {
            switch level {
            case 0:
                return Color.clear
            case 1:
                return ModernDesignSystem.Colors.backgroundSecondary.opacity(0.3)
            case 2:
                return ModernDesignSystem.Colors.backgroundSecondary.opacity(0.5)
            default:
                return ModernDesignSystem.Colors.backgroundSecondary.opacity(0.7)
            }
        }
        
        /// 连接线颜色（按层级）
        static func connectionLineColor(for level: Int) -> Color {
            switch level {
            case 0:
                return connectionLine
            case 1:
                return ModernDesignSystem.Colors.accentBlue.opacity(0.3)
            case 2:
                return ModernDesignSystem.Colors.accentBlue.opacity(0.5)
            default:
                return ModernDesignSystem.Colors.accentBlue.opacity(0.7)
            }
        }
        
        /// 用户等级颜色
        static func userLevelColor(for level: Int) -> Color {
            switch level {
            case 1...3:
                return ModernDesignSystem.Colors.textTertiary
            case 4...6:
                return ModernDesignSystem.Colors.accentBlue
            case 7...9:
                return ModernDesignSystem.Colors.primaryGreen
            default:
                return ModernDesignSystem.Colors.accentOrange
            }
        }
    }
    
    // MARK: - 动画规范
    struct Animations {
        /// 点赞动画
        static let likeAnimation = Animation.spring(response: 0.3, dampingFraction: 0.6)
        
        /// 展开/收起动画
        static let expandAnimation = Animation.easeInOut(duration: 0.25)
        
        /// 回复按钮动画
        static let replyAnimation = Animation.easeOut(duration: 0.2)
        
        /// 加载动画
        static let loadingAnimation = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        
        /// 出现动画
        static let appearAnimation = Animation.easeOut(duration: 0.3)
    }
    
    // MARK: - 交互规范
    struct Interactions {
        /// 长文本展开阈值（字符数）
        static let longTextThreshold: Int = 100
        
        /// 长文本展开后显示的行数
        static let expandedLineLimit: Int = 10
        
        /// 折叠时显示的行数
        static let collapsedLineLimit: Int = 3
        
        /// 双击点赞的时间间隔（秒）
        static let doubleTapInterval: TimeInterval = 0.3
        
        /// 按钮最小点击区域
        static let minimumTapArea: CGFloat = 44
        
        /// 滑动手势阈值
        static let swipeThreshold: CGFloat = 50
    }
    
    // MARK: - 状态规范
    struct States {
        /// 加载状态
        enum LoadingState {
            case idle
            case loading
            case loaded
            case error(String)
        }
        
        /// 展开状态
        enum ExpandState {
            case collapsed
            case expanded
        }
        
        /// 点赞状态
        enum LikeState {
            case unliked
            case liked
            case animating
        }
    }
}

// MARK: - 样式扩展
extension View {
    /// 应用评论行样式
    func commentRowStyle(level: Int = 0) -> some View {
        self
            .padding(CommentDesignSystem.Spacing.commentRowPadding)
            .background(CommentDesignSystem.Colors.nestedBackground(for: level))
            .overlay(
                // 左侧连接线（仅嵌套评论显示）
                level > 0 ? 
                Rectangle()
                    .fill(CommentDesignSystem.Colors.connectionLineColor(for: level))
                    .frame(width: CommentDesignSystem.Layout.connectionLineWidth)
                    .offset(x: -CommentDesignSystem.Layout.connectionLineOffset)
                : nil,
                alignment: .leading
            )
    }
    
    /// 应用用户头像样式
    func commentAvatarStyle() -> some View {
        self
            .frame(
                width: CommentDesignSystem.Layout.avatarSize,
                height: CommentDesignSystem.Layout.avatarSize
            )
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(CommentDesignSystem.Colors.connectionLine, lineWidth: 0.5)
            )
    }
    
    /// 应用操作按钮样式
    func commentActionButtonStyle(isActive: Bool = false) -> some View {
        self
            .frame(
                width: CommentDesignSystem.Layout.actionButtonSize,
                height: CommentDesignSystem.Layout.actionButtonSize
            )
            .foregroundColor(
                isActive ? 
                CommentDesignSystem.Colors.actionActive : 
                CommentDesignSystem.Colors.actionDefault
            )
            .background(
                Circle()
                    .fill(Color.clear)
                    .frame(
                        width: CommentDesignSystem.Interactions.minimumTapArea,
                        height: CommentDesignSystem.Interactions.minimumTapArea
                    )
            )
    }
    
    /// 应用用户等级标识样式
    func userLevelBadgeStyle(level: Int) -> some View {
        self
            .font(CommentDesignSystem.Typography.userBadge)
            .foregroundColor(CommentDesignSystem.Colors.userLevelColor(for: level))
            .padding(.horizontal, ModernDesignSystem.Spacing.xs)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.xs)
                    .fill(CommentDesignSystem.Colors.userLevelColor(for: level).opacity(0.1))
            )
    }
}

// MARK: - 使用指南和最佳实践
/*
## 评论组件设计系统使用指南

### 1. 基本原则
- 保持视觉层次清晰，避免过度嵌套
- 确保交互区域足够大（最小44pt）
- 使用一致的间距和字体规范
- 提供清晰的视觉反馈

### 2. 嵌套规范
- 最大嵌套层级：3层
- 每层缩进：16pt
- 连接线颜色随层级变化
- 背景色透明度递增

### 3. 交互规范
- 点赞：支持双击和按钮点击
- 回复：显示回复对象信息
- 展开：长文本自动折叠，提供展开选项
- 加载：提供明确的加载状态

### 4. 无障碍支持
- 所有交互元素支持VoiceOver
- 提供语义化的标签
- 确保颜色对比度符合标准
- 支持动态字体大小

### 5. 性能优化
- 使用LazyVStack进行列表渲染
- 图片异步加载和缓存
- 避免不必要的重绘
- 合理使用动画效果
*/