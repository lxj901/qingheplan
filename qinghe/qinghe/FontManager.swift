import SwiftUI
import Combine

/// 字体管理器 - 统一管理应用内的字体大小设置
class FontManager: ObservableObject {
    static let shared = FontManager()
    
    @Published var currentFontSize: FontSizeOption = .standard
    @AppStorage("selectedFontSize") private var selectedFontSize: String = "standard"
    
    private init() {
        // 从存储中加载字体设置
        loadFontSettings()
        
        // 监听字体设置变化
        $currentFontSize
            .sink { [weak self] newSize in
                self?.selectedFontSize = newSize.rawValue
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func loadFontSettings() {
        currentFontSize = FontSizeOption(rawValue: selectedFontSize) ?? .standard
    }
    
    /// 设置字体大小
    func setFontSize(_ size: FontSizeOption) {
        currentFontSize = size
    }
    
    /// 获取动态字体大小
    func fontSize(for style: FontStyle) -> CGFloat {
        return style.size(for: currentFontSize)
    }
    
    /// 获取动态字体
    func font(for style: FontStyle) -> Font {
        return style.font(for: currentFontSize)
    }
}

/// 字体大小选项
enum FontSizeOption: String, CaseIterable {
    case small = "small"
    case standard = "standard"
    case large = "large"
    case extraLarge = "extraLarge"
    case system = "system"
    
    var title: String {
        switch self {
        case .small: return "小号"
        case .standard: return "标准"
        case .large: return "大号"
        case .extraLarge: return "超大号"
        case .system: return "跟随系统"
        }
    }
    
    var subtitle: String {
        switch self {
        case .small: return "紧凑的字体，节省空间"
        case .standard: return "适合大多数用户"
        case .large: return "更大的字体，便于阅读"
        case .extraLarge: return "最大字体，适合视力不佳用户"
        case .system: return "根据系统字体大小设置"
        }
    }
    
    /// 字体缩放比例
    var scale: CGFloat {
        switch self {
        case .small: return 0.85
        case .standard: return 1.0
        case .large: return 1.15
        case .extraLarge: return 1.3
        case .system: return 1.0 // 系统字体会通过 @ScaledMetric 自动处理
        }
    }
}

/// 字体样式定义
enum FontStyle {
    // 标题类
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    
    // 正文类
    case body
    case bodyMedium
    case callout
    case subheadline
    
    // 辅助类
    case footnote
    case caption1
    case caption2
    
    // 数字类
    case numberLarge
    case numberMedium
    case numberSmall
    
    // 基础字体大小（标准模式下）
    private var baseSize: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title1: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .bodyMedium: return 16
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption1: return 12
        case .caption2: return 11
        case .numberLarge: return 32
        case .numberMedium: return 24
        case .numberSmall: return 18
        }
    }
    
    /// 字体权重
    var weight: Font.Weight {
        switch self {
        case .largeTitle, .title1, .title2: return .bold
        case .title3, .headline: return .semibold
        case .bodyMedium: return .medium
        case .numberLarge, .numberMedium: return .bold
        case .numberSmall: return .semibold
        default: return .regular
        }
    }
    
    /// 字体设计
    var design: Font.Design {
        switch self {
        case .largeTitle, .title1, .title2, .title3, .headline, .numberLarge, .numberMedium, .numberSmall:
            return .rounded
        default:
            return .default
        }
    }
    
    /// 根据字体大小选项获取实际大小
    func size(for option: FontSizeOption) -> CGFloat {
        if option == .system {
            return baseSize // 系统字体通过 @ScaledMetric 处理
        }
        return baseSize * option.scale
    }
    
    /// 根据字体大小选项获取字体
    func font(for option: FontSizeOption) -> Font {
        if option == .system {
            // 使用系统动态字体
            switch self {
            case .largeTitle: return .largeTitle.weight(weight)
            case .title1: return .title.weight(weight)
            case .title2: return .title2.weight(weight)
            case .title3: return .title3.weight(weight)
            case .headline: return .headline.weight(weight)
            case .body, .bodyMedium: return .body.weight(weight)
            case .callout: return .callout.weight(weight)
            case .subheadline: return .subheadline.weight(weight)
            case .footnote: return .footnote.weight(weight)
            case .caption1, .caption2: return .caption.weight(weight)
            default: return .system(size: size(for: option), weight: weight, design: design)
            }
        } else {
            return .system(size: size(for: option), weight: weight, design: design)
        }
    }
}

/// View 扩展 - 提供便捷的字体设置方法
extension View {
    /// 应用动态字体
    func dynamicFont(_ style: FontStyle) -> some View {
        self.font(FontManager.shared.font(for: style))
    }
    
    /// 应用动态字体大小
    func dynamicFontSize(_ style: FontStyle) -> some View {
        self.font(.system(size: FontManager.shared.fontSize(for: style)))
    }
}

/// 支持系统动态字体的 ScaledFont 修饰符
struct ScaledFont: ViewModifier {
    let style: FontStyle
    @StateObject private var fontManager = FontManager.shared
    @ScaledMetric private var scaledSize: CGFloat
    
    init(style: FontStyle) {
        self.style = style
        self._scaledSize = ScaledMetric(wrappedValue: style.size(for: .standard))
    }
    
    func body(content: Content) -> some View {
        content.font(
            fontManager.currentFontSize == .system ?
                .system(size: scaledSize, weight: style.weight, design: style.design) :
                fontManager.font(for: style)
        )
    }
}

extension View {
    /// 应用支持系统缩放的动态字体
    func scaledDynamicFont(_ style: FontStyle) -> some View {
        self.modifier(ScaledFont(style: style))
    }
}
