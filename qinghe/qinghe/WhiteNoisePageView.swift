import SwiftUI

struct WhiteNoiseItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let minutes: Int
    let category: String
    let locked: Bool
    let cover: String? // asset name (optional)
}

struct WhiteNoisePageView: View {
    @State private var selectedCategory: String = "雨声"
    @State private var allItems: [WhiteNoiseItem] = []
    @State private var isPlayingFloating: Bool = true
    @State private var floatingItem: WhiteNoiseItem? = nil

    private let categories: [String] = ["雨声", "水声", "自然", "海浪", "鸟鸣", "风声"]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    categoryChips
                        .padding(.top, 6)

                    grid
                }
            }

            if let item = floatingItem, isPlayingFloating {
                floatingMiniPlayer(for: item)
                    .padding(.trailing, 16)
                    .padding(.top, 80)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .navigationTitle("白噪音")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: buildMockData)
        .asSubView()
    }
}

// MARK: - Components
private extension WhiteNoisePageView {
    var filteredItems: [WhiteNoiseItem] {
        allItems.filter { $0.category == selectedCategory }
    }

    var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { cat in
                    Button(action: { withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) { selectedCategory = cat } }) {
                        Text(cat)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(selectedCategory == cat ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(
                                    selectedCategory == cat ? Color.black : Color(.systemGray5)
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 22) {
            ForEach(filteredItems) { item in
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        // 封面占位（可替换为真实图片资源）
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.08), Color.black.opacity(0.18)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 172)
                            .overlay(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .stroke(Color.white.opacity(0.65), lineWidth: 0.6)
                            )

                        if item.locked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.9))
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .onTapGesture {
                        // 预览播放：显示右上角浮窗
                        floatingItem = item
                        isPlayingFloating = true
                    }

                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(item.minutes)分钟 · \(item.category)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    func floatingMiniPlayer(for item: WhiteNoiseItem) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 120, height: 140)
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)

                HStack(spacing: 10) {
                    Button(action: { isPlayingFloating.toggle() }) {
                        Image(systemName: isPlayingFloating ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Circle().fill(Color.white))
                    }
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isPlayingFloating = false } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Circle().fill(Color.white))
                    }
                }
                .padding(8)
            }

            Text(item.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - Mock
private extension WhiteNoisePageView {
    func buildMockData() {
        allItems = [
            .init(title: "雨落窗沿", minutes: 35, category: "雨声", locked: true, cover: nil),
            .init(title: "昨夜微雨如酥", minutes: 16, category: "雨声", locked: true, cover: nil),
            .init(title: "烟雨灵隐寺", minutes: 10, category: "雨声", locked: true, cover: nil),
            .init(title: "雨中梦之旅", minutes: 23, category: "雨声", locked: true, cover: nil),
            .init(title: "初春小雨", minutes: 12, category: "雨声", locked: true, cover: nil),
            .init(title: "细雨琴斋", minutes: 29, category: "雨声", locked: true, cover: nil),
        ]
    }
}

#Preview {
    NavigationStack { WhiteNoisePageView() }
}

