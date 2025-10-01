import SwiftUI

struct WuYinPlayerDetailView: View {
    let theme: WuYinPlaylistTheme
    let track: WuYinPlaylistItem

    @State private var isPlaying: Bool = true

    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景：上半部分图像/渐变，下半深绿
            VStack(spacing: 0) {
                headerCover
                Spacer(minLength: 0)
            }
            .background(Color(hex: "2F4A2F"))
            .ignoresSafeArea()

            // 内容
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // 顶部标题与简介
                    titleAndIntro

                    // 轻分割线 + 在听/头像
                    HStack {
                        Rectangle().fill(Color.white.opacity(0.35)).frame(height: 0.5)
                        HStack(spacing: 8) {
                            Text("2321人在听")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                            Image(systemName: "waveform.path.ecg")
                                .foregroundColor(.white.opacity(0.9))
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .padding(.top, 4)

                    // 段落文案
                    VStack(alignment: .leading, spacing: 10) {
                        Text("新竹高于旧竹枝，全凭老干为扶持。")
                        Text("明年再有新生者，十丈龙孙绕凤池。")
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.92))

                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 260)
            }

            // 底部 CTA
            bottomCTA
        }
        .navigationBarBackButtonHidden(false)
        .navigationBarTitleDisplayMode(.inline)
        .asSubView()
    }
}

private extension WuYinPlayerDetailView {
    var headerCover: some View {
        ZStack(alignment: .bottomLeading) {
            // 封面占位：使用主题色渐变，可替换为真实封面
            LinearGradient(
                colors: [theme.accent.opacity(0.45), theme.accent.opacity(0.9)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 300)
            .overlay(
                LinearGradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.35)], startPoint: .center, endPoint: .bottom)
            )

            // 返回按钮（左上悬浮）
            HStack {
                Button(action: { /* 交由系统返回 */ }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.25)))
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
    }

    var titleAndIntro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(track.title)
                .font(AppFont.kangxi(size: 28))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)

            Text("竹林清脆，落子闻音。琴声悠扬，娉娉袅袅来。")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.92))

            HStack(spacing: 8) {
                tagChip("助眠")
                tagChip("冥想")
                tagChip("凝神")
            }
        }
    }

    func tagChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.2)))
    }

    var bottomCTA: some View {
        HStack {
            Spacer()
            Button(action: { isPlaying.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(isPlaying ? "暂停播放" : "立即播放")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(hex: "2F4A2F"))
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule().fill(Color.white.opacity(0.9))
                )
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .background(Color(hex: "2F4A2F").opacity(0.001))
    }
}

#Preview {
    WuYinPlayerDetailView(theme: .wood, track: .init(index: 1, title: "竹林手谈", artist: "郑蔓", isVIP: false, tag: nil))
}

