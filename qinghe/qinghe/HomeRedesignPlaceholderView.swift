import SwiftUI
import UIKit

struct HomeRedesignPlaceholderView: View {
    @State private var scrollOffset: CGFloat = 0
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "早上好！"
        case 12..<14: return "中午好！"
        case 14..<18: return "下午好！"
        default: return "晚上好！"
        }
    }
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Base background
                ModernDesignSystem.Colors.backgroundPrimary
                    .ignoresSafeArea()

                // Underlay bridge: softly lift the base near the top so
                // the fade from the header group blends without a step.
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.06),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 360)
                .allowsHitTesting(false)

                // Soft multi-color header gradient (top-left green, top-right blue, bottom-right purple)
                ZStack(alignment: .bottom) {
                    // Add mid stops to avoid edge rings
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: ModernDesignSystem.Colors.primaryGreen.opacity(0.6), location: 0.0),
                            .init(color: ModernDesignSystem.Colors.primaryGreen.opacity(0.28), location: 0.55),
                            .init(color: .clear, location: 1.0)
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 320
                    )
                    .offset(x: -40, y: -40)

                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: ModernDesignSystem.Colors.accentBlue.opacity(0.38), location: 0.0),
                            .init(color: ModernDesignSystem.Colors.accentBlue.opacity(0.18), location: 0.55),
                            .init(color: .clear, location: 1.0)
                        ]),
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 260
                    )
                    .offset(x: 60, y: -50)

                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: ModernDesignSystem.Colors.accentPurple.opacity(0.22), location: 0.0),
                            .init(color: ModernDesignSystem.Colors.accentPurple.opacity(0.10), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ]),
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: 300
                    )
                    .offset(x: 48, y: 60)

                    // Gentle bottom haze (inside the same compositing group)
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 160)
                }
                .frame(height: 242) // avoid half-pixel seams on some screens
                .frame(maxWidth: .infinity)
                .compositingGroup()
                .drawingGroup(opaque: false, colorMode: .linear)
                // Soft vertical fade-out to avoid a hard edge at the bottom
                .mask(
                    LinearGradient(
                        colors: [
                            Color.black,
                            Color.black.opacity(0.88),
                            Color.black.opacity(0.6),
                            Color.black.opacity(0.28),
                            Color.black.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blur(radius: 0.8)
                )
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)

                // Greeting bar on the new home (vertical scroll)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 监听滚动偏移
                        ScrollOffsetReader(coordinateSpace: "newHomeScroll")

                        GreetingHeaderBar()
                            .padding(.leading, 8)
                            .padding(.trailing, 16)
                            .padding(.top, 2)

                        // 随心漫听面板（应用色系的还原 UI）
                        CasualListeningBoardView(height: 226)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        // 移除金刚区与五音播单标题区，仅保留列表

                        // 五音播单 模块主体（横向滑动：木/火/土/金/水）
                        WuYinPlaylistsCarouselView()
                            .padding(.top, 8)

                        // 功法跟练 标题（复用五音播单样式：标题/副标题/竖痕）
                        gongFaHeaderRow
                            .padding(.horizontal, 16)
                            .padding(.top, 14)

                        // 功法跟练 课程横滑列表
                        GongFaCoursesCarouselView()
                            .padding(.top, 6)

                        Color.clear.frame(height: 24) // bottom spacing for scroll padding
                    }
                }
                .coordinateSpace(name: "newHomeScroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    // 避免对每次滚动偏移做动画，降低大量重绘导致的卡顿
                    scrollOffset = value
                }

                // 顶部导航栏（上滑后显示）
                topNavigationBar(opacity: navOpacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .asRootView()
    }
}

// MARK: - Components
private extension HomeRedesignPlaceholderView {
    // 动态计算副标题行高，使左侧竖痕自适应字体高度
    var subtitleLineHeight: CGFloat {
        let base: CGFloat = 13
        let scaled = UIFontMetrics(forTextStyle: .footnote).scaledValue(for: base)
        let font = UIFont.systemFont(ofSize: scaled, weight: .medium)
        return font.lineHeight
    }
    // 动态计算主标题行高
    var titleLineHeight: CGFloat {
        let base: CGFloat = 18
        let scaled = UIFontMetrics(forTextStyle: .headline).scaledValue(for: base)
        let font = UIFont.systemFont(ofSize: scaled, weight: .bold)
        return font.lineHeight
    }
    // 竖痕总高度 = 主标题 + 行间距(2) + 副标题
    var headerBarHeight: CGFloat { titleLineHeight + 2 + subtitleLineHeight }
    var wuYinHeaderRow: some View {
        HStack(spacing: 8) {
            // 竖痕：高度随主标题+副标题合计自适应
            Capsule()
                .fill(ModernDesignSystem.Colors.primaryGreen)
                .frame(width: 3, height: headerBarHeight)

            VStack(alignment: .leading, spacing: 2) {
                Text("五音播单")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))

                Text("中医五音疗法 · 调和身心")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // 功法跟练 标题行（复用竖痕 + 标题 + 副标题样式）
    var gongFaHeaderRow: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(ModernDesignSystem.Colors.primaryGreen)
                .frame(width: 3, height: headerBarHeight)

            VStack(alignment: .leading, spacing: 2) {
                Text("功法跟练")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))

                // 副标题沿用五音播单的文案
                Text("中医五音疗法 · 调和身心")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 顶部导航栏
private extension HomeRedesignPlaceholderView {
    var navOpacity: Double {
        // 当向上滚动时（offset 为负），逐步显示；阈值约 40pt
        let shown = max(0, min(1, Double((-scrollOffset - 20) / 40)))
        return shown
    }

    func topNavigationBar(opacity: Double) -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("青禾")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial.opacity(opacity))
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 0.5)
                    .opacity(opacity)
                , alignment: .bottom
            )
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    HomeRedesignPlaceholderView()
}
