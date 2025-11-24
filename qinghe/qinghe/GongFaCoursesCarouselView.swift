import SwiftUI
import UIKit

struct GongFaCourse: Identifiable {
    let id = UUID()
    let title: String
    let tags: [String]
    let level: String // 入门 / 中阶 / 进阶
    let duration: String // e.g., 15分钟
    let cover: String? // asset name
    let tint: Color
}

struct GongFaCoursesCarouselView: View {
    private let courses: [GongFaCourse] = [
        .init(title: "八段锦", tags: ["科学健体"], level: "入门", duration: "15分钟", cover: nil, tint: ModernDesignSystem.Colors.primaryGreen),
        .init(title: "静坐冥想", tags: ["疗愈静心"], level: "中阶", duration: "18分钟", cover: nil, tint: ModernDesignSystem.Colors.accentBlue),
        .init(title: "术后康养", tags: ["科学健体"], level: "入门", duration: "15分钟", cover: nil, tint: ModernDesignSystem.Colors.primaryGreenDark)
    ]

    private let cardWidth: CGFloat = 240
    @State private var navigateToAll: Bool = false

    var body: some View {
        ZStack(alignment: .leading) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(Array(courses.enumerated()), id: \.element.id) { idx, course in
                        NavigationLink(destination: GongFaCourseDetailView(course: course)) {
                            GongFaCourseCard(course: course)
                                .frame(width: cardWidth)
                                .onAppear {
                                    // 当最后一个卡片真正出现（滑动到最右）时，自动跳转到“全部”页
                                    if idx == courses.count - 1 { navigateToAll = true }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            // 隐藏导航触发器，跳转到两列纵向的“功法跟练”页面
            NavigationLink(destination: GongFaCoursesPageView(), isActive: $navigateToAll) {
                EmptyView()
            }
            .hidden()
        }
    }
}

struct GongFaCourseCard: View {
    let course: GongFaCourse
    var body: some View {
        ZStack(alignment: .bottom) {
            // 封面（若无封面则使用渐变占位）
            Group {
                if let name = course.cover, let ui = UIImage(named: name) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(colors: [course.tint.opacity(0.65), course.tint.opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 0.6)
            )

            // 顶部右上：视频带练
            VStack { HStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill").font(.system(size: 12, weight: .bold))
                    Text("视频带练").font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.black.opacity(0.28)))
            }
            .padding(10)
            Spacer() }

            // 底部信息板
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(course.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    ForEach(course.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(Color.white.opacity(0.22))
                            )
                    }
                }

                Text("\(course.level)·\(course.duration)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.92))
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                // 渐变底栏（使用 app 配色加深）
                LinearGradient(
                    colors: [course.tint.opacity(0.85), Color.black.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(GFRoundedCorner(radius: 18, corners: [.bottomLeft, .bottomRight]))
                .overlay(
                    GFRoundedCorner(radius: 18, corners: [.bottomLeft, .bottomRight])
                        .stroke(Color.white.opacity(0.6), lineWidth: 0.6)
                )
            )
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// 辅助：仅对指定角应用圆角（避免与项目内同名类型冲突）
private struct GFRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    GongFaCoursesCarouselView()
        .padding()
}
