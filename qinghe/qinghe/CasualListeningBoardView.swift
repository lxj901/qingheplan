import SwiftUI

/// 随心漫听 面板（还原设计风格，配色使用应用色系）
struct CasualListeningBoardView: View {
    var height: CGFloat = 226
    var corner: CGFloat = 26

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 外层柔和面板
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            ModernDesignSystem.Colors.primaryGreen.opacity(0.12),
                            Color.white.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // 右上柔光
                    RadialGradient(
                        colors: [Color.white.opacity(0.6), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 360
                    )
                    .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                )
                .overlay(
                    // 细白描边
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)

            // 顶部条纹装饰（从标题右侧开始延伸的一行细条纹）
            // 之前未裁剪到面板形状，右侧会溢出。这里加 mask 保证不超出圆角面板。
            topStripes
                .padding(.horizontal, 8)
                .mask(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                )

            // 标题
            Text("随心漫听")
                .font(AppFont.kangxi(size: 24))
                .foregroundColor(Color(.label))
                .padding(.top, 14)
                .padding(.leading, 18)

            // 主内容卡
            mainContentCard
                .padding(.top, 58)
                .padding(.horizontal, 18)

            // 底部刻度尺/分类条（恢复）
            bottomDial
                .frame(height: 64)
                .padding(.horizontal, 0)
                .padding(.bottom, 0)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: height)
    }

    // MARK: - 主内容卡片
    private var mainContentCard: some View {
        HStack(spacing: 14) {
            // 封面占位
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            ModernDesignSystem.Colors.primaryGreen.opacity(0.6),
                            ModernDesignSystem.Colors.primaryGreenDark.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 86, height: 86)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 8) {
                // 标题：一行显示且字号更小
                Text("晨起养生 畅通筋络")
                    .font(AppFont.kangxi(size: 18))
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                    .truncationMode(.tail)

                // 曲目描述（替代昵称与头像）
                Text("曲目描述 · 纯音乐")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("127万次播放")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 播放按钮
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.92), Color(.systemGray6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 0.6))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ModernDesignSystem.Colors.primaryGreenDark)
            }
            .frame(width: 54, height: 54)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
        )
    }

    // MARK: - 底部刻度尺（全宽覆盖，不留左右空白）
    private var bottomDial: some View {
        ZStack(alignment: .top) {
            // 背景应为白色系
            LinearGradient(
                colors: [Color.white.opacity(0.94), Color.white.opacity(0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: -2)

            VStack(spacing: 6) {
                HStack {
                    Text("晚安电台").font(.system(size: 12)).foregroundColor(.secondary)
                    Spacer()
                    Text("专业助眠").font(.system(size: 12)).foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)

                GeometryReader { geo in
                    let width = geo.size.width
                    let height = geo.size.height
                    let count = 60
                    ZStack(alignment: .bottom) {
                        Path { path in
                            for i in 0...count {
                                let x = CGFloat(i) * (width / CGFloat(count))
                                let h: CGFloat = (i % 10 == 0) ? 18 : 10
                                path.addRect(CGRect(x: x, y: height - h, width: 1, height: h))
                            }
                        }
                        .fill(Color.black.opacity(0.12))

                        RoundedRectangle(cornerRadius: 2)
                            .fill(ModernDesignSystem.Colors.primaryGreen)
                            .frame(width: 3, height: 22)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Text("纯音旋律")
                    .font(AppFont.kangxi(size: 14))
                    .foregroundColor(Color(.label))
                    .padding(.top, -6)
            }
            .padding(.vertical, 8)
        }
    }
    
}

// MARK: - 顶部条纹装饰
extension CasualListeningBoardView {
    private var topStripes: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let columns = max(Int(width / 12), 10)
            HStack(spacing: 6) {
                ForEach(0..<columns, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(ModernDesignSystem.Colors.primaryGreen.opacity(0.12))
                        .frame(width: 3, height: 10)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 22)
            .padding(.leading, 118)
        }
        .allowsHitTesting(false)
    }
}

private enum MicrosoftPlaceholderStyle {
    static let gradient = LinearGradient(
        colors: [Color(.systemGray4), Color(.systemGray3)],
        startPoint: .top, endPoint: .bottom
    )
    static let stroke = Color.white.opacity(0.55)
}

#Preview {
    CasualListeningBoardView()
        .padding()
}
