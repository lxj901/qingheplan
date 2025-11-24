import SwiftUI

struct GongFaCourseDetailView: View {
    let course: GongFaCourse

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerCover

                    introCard

                    keyPointsRow
                        .padding(.horizontal, 16)

                    stepsSection
                        .padding(.horizontal, 16)

                    Color.clear.frame(height: 100)
                }
            }

            bottomCTA
        }
        .navigationBarTitleDisplayMode(.inline)
        .asSubView()
    }
}

// MARK: - Sections
private extension GongFaCourseDetailView {
    var headerCover: some View {
        ZStack(alignment: .bottomTrailing) {
            // 封面：有图则显示图片，否则渐变
            Group {
                if let name = course.cover, let ui = UIImage(named: name) {
                    Image(uiImage: ui).resizable().scaledToFill()
                } else {
                    LinearGradient(colors: [course.tint.opacity(0.65), course.tint.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .frame(height: 240)
            .clipped()

            HStack(spacing: 8) {
                Text("2W+人学过")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: -10) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(Color.white).frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 0.5))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.25)))
            .padding(16)
        }
    }

    var introCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("课程介绍")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "6B5C47"))

            HStack(alignment: .firstTextBaseline) {
                Text(course.title)
                    .font(AppFont.kangxi(size: 26))
                    .foregroundColor(Color(hex: "4A3A1F"))
                Spacer()
                Text("用时：15分钟")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "6B5C47"))
            }

            Text("当我们做为个动作时，通过摇头，促使了心经脉气开通，而摆尾，由于坎卦（肾）二阴之中的一阴促使脾脏温升，此时，由于离卦（心）两阳之中……")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "6B5C47").opacity(0.95))
                .lineLimit(3)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 0.6)
        )
        .padding(.horizontal, 16)
        .padding(.top, -20)
    }

    var keyPointsRow: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: WhiteNoisePageView()) {
                keyPoint(icon: "music.note", title: "听音曲目", value: "羽调·安神")
            }
            .buttonStyle(.plain)
            keyPoint(icon: "waveform.path.ecg", title: "练习频次", value: "每天一次")
            keyPoint(icon: "figure.stand", title: "练习姿势", value: "站姿 半蹲")
        }
    }

    func keyPoint(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "6B5C47"))

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "3E3A34"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 0.6)
        )
    }

    var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("步骤说明")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "6B5C47"))
                Spacer()
                Text("共八个动作 >")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "8A806F"))
            }

            ForEach(0..<4, id: \.self) { i in
                HStack(alignment: .top, spacing: 12) {
                    stepThumb(index: i)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(i == 0 ? "准备式" : (i == 1 ? "调身" : (i == 2 ? "调息" : "收势")))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "3E3A34"))
                        Text("通过音乐刺激大脑皮层，调节身心状态；上动不停，身体重心下降……")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8A806F"))
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
            }
        }
    }

    func stepThumb(index: Int) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(LinearGradient(colors: [course.tint.opacity(0.4), course.tint], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 82, height: 50)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.7), lineWidth: 0.6)
            )
    }

    var bottomCTA: some View {
        HStack { Spacer()
            NavigationLink(destination: GongFaVideoPlayerView(course: course, videoURL: URL(string: "https://www.bilibili.com/video/BV1kWaGzTEcx"))) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill").font(.system(size: 16, weight: .bold))
                    Text("开始练习").font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [Color(hex: "9B4536"), Color(hex: "C26759")], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            Spacer() }
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }
}

#Preview {
    GongFaCourseDetailView(course: .init(title: "八段锦", tags: ["科学健体"], level: "入门", duration: "15分钟", cover: nil, tint: ModernDesignSystem.Colors.primaryGreen))
}
