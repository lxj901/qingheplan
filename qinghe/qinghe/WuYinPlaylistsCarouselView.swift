import SwiftUI

/// 五音播单横向滑动列表（木/火/土/金/水）
struct WuYinPlaylistsCarouselView: View {
    let themes: [WuYinPlaylistTheme] = WuYinPlaylistTheme.all
    let cardWidth: CGFloat = 300

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(themes, id: \.element) { theme in
                    NavigationLink(destination: WuYinPlaylistsPageView(theme: theme)) {
                        WuYinPlaylistModuleView(
                            title: "音药·清除大脑噪音",
                            subtitle: nil,
                            showChevron: true,
                            onChevronTap: nil,
                            theme: theme,
                            fixedWidth: cardWidth
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    WuYinPlaylistsCarouselView()
}
