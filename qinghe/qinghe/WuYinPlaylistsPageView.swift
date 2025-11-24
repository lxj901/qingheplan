import SwiftUI

struct WuYinPlaylistItem: Identifiable {
    let id = UUID()
    let index: Int
    let title: String
    let artist: String
    let isVIP: Bool
    let tag: String?
}

struct WuYinPlaylistsPageView: View {
    let theme: WuYinPlaylistTheme

    @State private var tracks: [WuYinPlaylistItem] = []
    @State private var currentTrack: WuYinPlaylistItem? = nil
    @State private var showingMiniPlayer = true

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "F8F5EE"), Color(hex: "F5EFE6")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    bannerHeader
                    playlistIntroCard
                    sectionHeader
                    VStack(spacing: 18) {
                        ForEach(tracks) { item in
                            trackRow(item)
                                .onTapGesture { currentTrack = item; showingMiniPlayer = true }
                        }
                    }
                    .padding(.horizontal, 16)
                    Color.clear.frame(height: 80)
                }
            }

            if showingMiniPlayer, let playing = currentTrack {
                miniPlayerBar(playing)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear(perform: buildMockData)
        .navigationTitle("五音播单 · \(theme.element)")
        .navigationBarTitleDisplayMode(.inline)
        .asSubView()
    }
}

// MARK: Header
private extension WuYinPlaylistsPageView {
    var bannerHeader: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(LinearGradient(colors: [theme.accent.opacity(0.25), theme.accent.opacity(0.55)], startPoint: .top, endPoint: .bottom))
            .frame(height: 200)
    }

    var playlistIntroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Capsule().fill(theme.accent).frame(width: 3, height: 22)
                Text("时令养生歌单")
                    .font(AppFont.kangxi(size: 26))
                    .foregroundColor(Color(hex: "4A3A1F"))
                Spacer(minLength: 4)
                Text("调理脾胃")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "6B4E2E"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color(hex: "EBDAC6")))
            }

            Text("本歌单乐音适用于气滞血郁型、气的运行、精肝气的舒畅、血的运行、安心气的强健。治序止宜疏肝行气，助心行血。音乐整体风格……")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "6B5C47").opacity(0.95))
                .lineLimit(3)

            HStack(spacing: 12) {
                label(icon: "music.note", text: "宫音—养胃")
                label(icon: "clock", text: "辰时: 7-9点")
                label(icon: "play.circle", text: "27W+人播放")
                Spacer()
                HStack(spacing: -10) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(Color.white).frame(width: 22, height: 22)
                            .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 0.5))
                    }
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "6B5C47"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
        .offset(y: -30)
    }

    func label(icon: String, text: String) -> some View {
        HStack(spacing: 6) { Image(systemName: icon); Text(text) }
    }
}

// MARK: List
private extension WuYinPlaylistsPageView {
    var sectionHeader: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                ZStack { Circle().fill(theme.accent).frame(width: 26, height: 26); Image(systemName: "play.fill").foregroundColor(.white).font(.system(size: 12, weight: .bold)) }
                Text("全部播放 (\(tracks.count))")
                    .font(AppFont.kangxi(size: 20))
                    .foregroundColor(Color(hex: "4A3A1F"))
            }
            Spacer()
            HStack(spacing: 16) {
                Image(systemName: "square.and.arrow.down").foregroundColor(Color(hex: "6B5C47"))
                Image(systemName: "text.badge.checkmark").foregroundColor(Color(hex: "6B5C47"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, -10)
        .padding(.bottom, 4)
    }

    func trackRow(_ item: WuYinPlaylistItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(item.index)")
                .font(AppFont.kangxi(size: 18))
                .foregroundColor(theme.accent)
                .frame(width: 18, alignment: .trailing)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "3E3A34"))
                        .lineLimit(1)

                    if item.isVIP {
                        Text("VIP")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "A55F2A"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "F2E3D2")))
                    }

                    if let tag = item.tag {
                        Text(tag)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: "B04A4A"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "F7E1E1")))
                    }
                }

                Text(item.artist)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A806F"))
            }
            Spacer()
            Image(systemName: "heart").foregroundColor(Color(hex: "C9C0AE"))
        }
    }
}

// MARK: Mini Player
private extension WuYinPlaylistsPageView {
    func miniPlayerBar(_ track: WuYinPlaylistItem) -> some View {
        NavigationLink(destination: WuYinPlayerDetailView(theme: theme, track: track)) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(theme.accent.opacity(0.25))
                    .frame(width: 42, height: 42)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.7), lineWidth: 0.6))

                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "3E3A34"))
                        .lineLimit(1)
                    Text(track.artist)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8A806F"))
                        .lineLimit(1)
                }
                Spacer()
                HStack(spacing: 16) {
                    Image(systemName: "play.circle.fill").font(.system(size: 26)).foregroundColor(theme.accent)
                    Image(systemName: "list.bullet").font(.system(size: 18)).foregroundColor(Color(hex: "6B5C47"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: "F1E8D9").opacity(0.96))
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: -2)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .buttonStyle(.plain)
    }
}

// MARK: Data
private extension WuYinPlaylistsPageView {
    func buildMockData() {
        tracks = (1...20).map { i in
            WuYinPlaylistItem(
                index: i,
                title: i == 4 ? "第一段·肝气犯胃型（情志郁结）适用" : ["阑踏清凉月", "枫桥夜泊", "凝声", "赤壁怀古", "清净甘露"].randomElement() ?? "阑踏清凉月",
                artist: ["上海华夏乐团", "兰琼-当弥空灵鼓演奏曲集", "上海华夏乐团·茂海云森"].randomElement() ?? "上海华夏乐团",
                isVIP: Bool.random(),
                tag: i == 1 ? "悠扬舒缓旋律" : nil
            )
        }
        currentTrack = tracks.first
    }
}

#Preview {
    WuYinPlaylistsPageView(theme: .wood)
}
