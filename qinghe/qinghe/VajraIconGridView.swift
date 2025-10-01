import SwiftUI

/// 金刚区图标（扁平 + 柔和渐变 + 玻璃质感）
struct VajraIconGridView: View {
    struct Item: Identifiable {
        let id = UUID()
        let title: String
        let symbol: String
        let gradient: LinearGradient
        let tint: Color
    }

    private let items: [Item] = [
        .init(
            title: "日记",
            symbol: "square.and.pencil",
            gradient: LinearGradient(colors: [ModernDesignSystem.Colors.accentOrange.opacity(0.9), ModernDesignSystem.Colors.accentOrange.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing),
            tint: ModernDesignSystem.Colors.accentOrange
        ),
        .init(
            title: "听音",
            symbol: "headphones",
            gradient: LinearGradient(colors: [ModernDesignSystem.Colors.accentBlue.opacity(0.9), ModernDesignSystem.Colors.accentBlue.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing),
            tint: ModernDesignSystem.Colors.accentBlue
        ),
        .init(
            title: "睡眠",
            symbol: "moon.fill",
            gradient: LinearGradient(colors: [ModernDesignSystem.Colors.accentPurple.opacity(0.9), ModernDesignSystem.Colors.accentPurple.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing),
            tint: ModernDesignSystem.Colors.accentPurple
        ),
        .init(
            title: "跟练",
            symbol: "figure.walk",
            gradient: LinearGradient(colors: [ModernDesignSystem.Colors.primaryGreen.opacity(0.9), ModernDesignSystem.Colors.primaryGreenLight.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing),
            tint: ModernDesignSystem.Colors.primaryGreen
        ),
        .init(
            title: "健康",
            symbol: "heart.fill",
            gradient: LinearGradient(colors: [ModernDesignSystem.Colors.primaryGreenDark.opacity(0.9), ModernDesignSystem.Colors.primaryGreen.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing),
            tint: ModernDesignSystem.Colors.primaryGreenDark
        )
    ]

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(minimum: 44), spacing: 12), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items) { item in
                if item.title == "日记" {
                    NavigationLink(destination: GongGuoGeView()) {
                        VStack(spacing: 8) {
                            CandyIcon(symbol: item.symbol, gradient: item.gradient, tint: item.tint)
                                .frame(width: 56, height: 56)

                            Text(item.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(.label))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else if item.title == "听音" {
                    NavigationLink(destination: WhiteNoisePageView()) {
                        VStack(spacing: 8) {
                            CandyIcon(symbol: item.symbol, gradient: item.gradient, tint: item.tint)
                                .frame(width: 56, height: 56)

                            Text(item.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(.label))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else if item.title == "跟练" {
                    NavigationLink(destination: GongFaCoursesPageView()) {
                        VStack(spacing: 8) {
                            CandyIcon(symbol: item.symbol, gradient: item.gradient, tint: item.tint)
                                .frame(width: 56, height: 56)

                            Text(item.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(.label))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else if item.title == "睡眠" {
                    NavigationLink(destination: SleepDashboardView()) {
                        VStack(spacing: 8) {
                            CandyIcon(symbol: item.symbol, gradient: item.gradient, tint: item.tint)
                                .frame(width: 56, height: 56)

                            Text(item.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(.label))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else if item.title == "健康" {
                    NavigationLink(destination: HealthManagerView()) {
                        VStack(spacing: 8) {
                            CandyIcon(symbol: item.symbol, gradient: item.gradient, tint: item.tint)
                                .frame(width: 56, height: 56)

                            Text(item.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(.label))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(spacing: 8) {
                        CandyIcon(symbol: item.symbol, gradient: item.gradient, tint: item.tint)
                            .frame(width: 56, height: 56)

                        Text(item.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(.label))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 其他入口可在此接入各自页面
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

/// 单个毛玻璃风格图标：材料玻璃 + 柔和渐变 + 高光 + 轻阴影
private struct CandyIcon: View {
    let symbol: String
    let gradient: LinearGradient
    let tint: Color

    var body: some View {
        ZStack {
            // 背后柔和彩色投影，增强俏皮感
            Ellipse()
                .fill(tint.opacity(0.25))
                .frame(width: 42, height: 12)
                .blur(radius: 6)
                .offset(y: 20)

            // 糖果质感：饱和渐变 + 顶部高光 + 细描边 + 轻内阴影
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(gradient)
                .overlay(
                    // 顶部高光
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom))
                        .mask(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .padding(.bottom, 18)
                        )
                )
                .overlay(
                    // 细白描边
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.7)
                )
                .overlay(
                    // 内阴影（底部AO）
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.16), lineWidth: 10)
                        .blur(radius: 8)
                        .mask(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top))
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .shadow(color: tint.opacity(0.22), radius: 12, x: 0, y: 4)

            // 白色图标，轻阴影
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.12), radius: 1.5, x: 0, y: 1)
        }
    }
}

#Preview {
    VajraIconGridView()
        .padding()
        .background(Color.white)
}
