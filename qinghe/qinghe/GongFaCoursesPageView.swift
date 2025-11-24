import SwiftUI

/// 功法跟练 页面（从金刚区“跟练”入口进入）
struct GongFaCoursesPageView: View {
    private let courses: [GongFaCourse] = [
        .init(title: "八段锦", tags: ["科学健体"], level: "入门", duration: "15分钟", cover: nil, tint: ModernDesignSystem.Colors.primaryGreen),
        .init(title: "静坐冥想", tags: ["疗愈静心"], level: "中阶", duration: "18分钟", cover: nil, tint: ModernDesignSystem.Colors.accentBlue),
        .init(title: "术后康养", tags: ["科学健体"], level: "入门", duration: "15分钟", cover: nil, tint: ModernDesignSystem.Colors.primaryGreenDark),
        .init(title: "呼吸调息", tags: ["调气"], level: "入门", duration: "12分钟", cover: nil, tint: ModernDesignSystem.Colors.primaryGreenLight),
        .init(title: "太极入门", tags: ["身心协调"], level: "中阶", duration: "20分钟", cover: nil, tint: ModernDesignSystem.Colors.accentBlue),
        .init(title: "筋骨松解", tags: ["舒缓"], level: "入门", duration: "10分钟", cover: nil, tint: ModernDesignSystem.Colors.primaryGreen)
    ]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 标题区（与首页样式一致的标题+副标题+竖痕）
                HStack(spacing: 8) {
                    Capsule().fill(ModernDesignSystem.Colors.primaryGreen)
                        .frame(width: 3, height: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("功法跟练")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255))
                        Text("中医五音疗法 · 调和身心")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 102/255, green: 102/255, blue: 102/255))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // 课程两列竖向网格
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                    ForEach(courses, id: \.id) { course in
                        NavigationLink(destination: GongFaCourseDetailView(course: course)) {
                            GongFaCourseCard(course: course)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                Color.clear.frame(height: 12)
            }
        }
        .navigationTitle("功法跟练")
        .navigationBarTitleDisplayMode(.inline)
        .asSubView()
    }
}

#Preview {
    NavigationStack { GongFaCoursesPageView() }
}
