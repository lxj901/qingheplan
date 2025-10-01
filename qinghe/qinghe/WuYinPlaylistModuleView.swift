import SwiftUI

/// 五音播单模块（还原设计图：外层渐变面板 + 内层折角卡片）
struct WuYinPlaylistModuleView: View {
    // 可选：在模块内部显示标题/箭头（当前新首页已单独有标题行，这里默认不显示）
    var title: String? = nil
    var subtitle: String? = nil
    var showChevron: Bool = false
    var onChevronTap: (() -> Void)? = nil

    // 主题与尺寸（支持五行配色 + 可选固定宽度，便于横向滚动）
    var theme: WuYinPlaylistTheme = .wood
    var fixedWidth: CGFloat? = nil

    private let outerCorner: CGFloat = 28
    private let innerCorner: CGFloat = 20
    private let coverCorner: CGFloat = 16

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 外层柔和渐变面板 + 细描边 + 轻发光
            RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                .fill(outerGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                        .blendMode(.overlay)
                )

            VStack(alignment: .leading, spacing: 12) {
                if let t = title ?? nil {
                    // 顶部标题行（可选）
                    HStack(alignment: .center, spacing: 6) {
                        Text(t)
                            .font(AppFont.kangxi(size: 20))
                            .foregroundColor(Color(hex: "0A3B34").opacity(0.92))

                        if showChevron {
                            Button(action: { onChevronTap?() }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "0A3B34").opacity(0.92))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }

                // 内层“折角纸片”卡片
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: innerCorner, style: .continuous)
                        .fill(innerCardFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: innerCorner, style: .continuous)
                                .stroke(Color.white.opacity(0.85), lineWidth: 0.6)
                        )

                    // 顶部装饰已移除（无折角/高光带）

                    // 内容
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("释放学习压力 高能传导深静频率")
                                .font(AppFont.kangxi(size: 16))
                                .foregroundColor(Color(hex: "0A3B34").opacity(0.92))
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("来自：青禾计划团队")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "7F9C95").opacity(0.9))

                            Text("7.9万名藥友来过")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "C0C7C2"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ZStack {
                            // 左侧露出的“黑胶唱片”效果（带凹槽与中心标）
                            VinylDiscView(diameter: 58, accent: theme.accent)
                                .offset(x: -20)

                            // 封面图
                            coverPlaceholder
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: coverCorner, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: coverCorner, style: .continuous)
                                        .stroke(Color.white.opacity(0.75), lineWidth: 0.8)
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .padding(.top, 10)
        }
        .frame(width: fixedWidth, alignment: .leading)
        .frame(height: 160)
    }

    // MARK: - Subviews & Styles
    // 顶部装饰（无）

    private var outerGradient: LinearGradient {
        let a = theme.accent
        return LinearGradient(
            colors: [
                Color.white.opacity(0.96),
                a.opacity(0.28),
                a.opacity(0.50)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var innerCardFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.96),
                Color(hex: "F3FFFC").opacity(0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var coverPlaceholder: some View {
        Group {
            if let ui = UIImage(named: "health_bird") ?? UIImage(named: "test") {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: [theme.accent.opacity(0.75), theme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }
}

// MARK: - 五行主题
struct WuYinPlaylistTheme: Equatable {
    let element: String
    let accent: Color

    static let wood = WuYinPlaylistTheme(element: "木", accent: Color(hex: "37B26C"))
    static let fire = WuYinPlaylistTheme(element: "火", accent: Color(hex: "E85C4A"))
    static let earth = WuYinPlaylistTheme(element: "土", accent: Color(hex: "D6A23E"))
    static let metal = WuYinPlaylistTheme(element: "金", accent: Color(hex: "B7BEC7"))
    static let water = WuYinPlaylistTheme(element: "水", accent: Color(hex: "3E7BEB"))

    static let all: [WuYinPlaylistTheme] = [.wood, .fire, .earth, .metal, .water]
}

// MARK: - Vinyl Disc
private struct VinylDiscView: View {
    let diameter: CGFloat
    let accent: Color

    var body: some View {
        ZStack {
            // 基底：深色径向渐变
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.95),
                            Color.black.opacity(0.85),
                            Color.black.opacity(0.98)
                        ],
                        center: .center,
                        startRadius: diameter * 0.05,
                        endRadius: diameter * 0.52
                    )
                )

            // 凹槽：多条同心细线
            ForEach(0..<14, id: \.self) { i in
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 0.6)
                    .scaleEffect(1 - CGFloat(i) * 0.055)
                    .blendMode(.overlay)
            }

            // 高光：轻微环形高光提升质感
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1
                )
                .scaleEffect(0.98)

            // 中心彩贴
            Circle()
                .fill(accent)
                .frame(width: diameter * 0.26, height: diameter * 0.26)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.7), lineWidth: 0.8)
                )

            // 中心孔
            Circle()
                .fill(Color.black)
                .frame(width: diameter * 0.08, height: diameter * 0.08)
        }
        .frame(width: diameter, height: diameter)
    }
}

// MARK: - Shapes (unused)

#Preview {
    ZStack {
        Color.black.opacity(0.7).ignoresSafeArea()
        VStack(alignment: .leading, spacing: 16) {
            Text("预览：五音播单模块")
                .foregroundColor(.white)
            WuYinPlaylistModuleView(title: "音药｜唤醒大脑，清除大脑噪音", subtitle: nil, showChevron: true)
                .padding(.horizontal, 16)
        }
    }
}
