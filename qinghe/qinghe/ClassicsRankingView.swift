import SwiftUI

// MARK: - 排行榜 ViewModel
@MainActor
class BookRankingViewModel: ObservableObject {
    @Published var rankings: [BookRanking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadRankings() async {
        isLoading = true
        errorMessage = nil

        do {
            rankings = try await ClassicsAPIService.shared.fetchBookRankings(
                category: nil,
                limit: 50
            )
        } catch {
            errorMessage = error.localizedDescription
            print("❌ 加载排行榜失败: \(error)")
        }

        isLoading = false
    }

    func loadMore() async {
        guard !isLoading else { return }

        isLoading = true

        do {
            let newRankings = try await ClassicsAPIService.shared.fetchBookRankings(
                category: nil,
                limit: 20,
                offset: rankings.count
            )
            rankings.append(contentsOf: newRankings)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

/// 国学书斋 - 排行榜页面（阅读数排行）
struct ClassicsRankingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BookRankingViewModel()

    var body: some View {
        ZStack {
            // 背景渐变色
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.94),
                    Color(red: 0.95, green: 0.92, blue: 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.rankings.isEmpty {
                    // 加载中
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.rankings.isEmpty {
                    // 空状态
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 50))
                            .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                        Text("暂无排行榜数据")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // 前三名特殊展示
                            if viewModel.rankings.count >= 3 {
                                topThreeSection
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                    .padding(.bottom, 20)
                            }

                            // 其他排名列表
                            VStack(spacing: 12) {
                                ForEach(Array(viewModel.rankings.enumerated()), id: \.element.id) { index, ranking in
                                    if index >= 3 {
                                        NavigationLink(destination: ClassicsReadingView(bookId: ranking.bookId, bookTitle: ranking.title).asSubView()) {
                                            RankingBookRow(ranking: ranking)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    .refreshable {
                        await viewModel.loadRankings()
                    }
                }
            }
        }
        .navigationTitle("阅读排行榜")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
        }
        .task {
            await viewModel.loadRankings()
        }
    }

    // MARK: - 前三名特殊展示
    private var topThreeSection: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 第二名
            if viewModel.rankings.count > 1 {
                NavigationLink(destination: ClassicsReadingView(bookId: viewModel.rankings[1].bookId, bookTitle: viewModel.rankings[1].title).asSubView()) {
                    TopRankCard(ranking: viewModel.rankings[1], height: 140)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // 第一名（最高）
            if viewModel.rankings.count > 0 {
                NavigationLink(destination: ClassicsReadingView(bookId: viewModel.rankings[0].bookId, bookTitle: viewModel.rankings[0].title).asSubView()) {
                    TopRankCard(ranking: viewModel.rankings[0], height: 170)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // 第三名
            if viewModel.rankings.count > 2 {
                NavigationLink(destination: ClassicsReadingView(bookId: viewModel.rankings[2].bookId, bookTitle: viewModel.rankings[2].title).asSubView()) {
                    TopRankCard(ranking: viewModel.rankings[2], height: 120)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - 前三名卡片组件
struct TopRankCard: View {
    let ranking: BookRanking
    let height: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            // 奖牌图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: rankColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: rankColors[0].opacity(0.4), radius: 8, x: 0, y: 4)

                if ranking.rank == 1 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                } else {
                    Text("\(ranking.rank)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -25)

            VStack(spacing: 6) {
                Text(ranking.title)
                    .font(AppFont.kangxi(size: ranking.rank == 1 ? 18 : 16))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineLimit(1)

                Text(ranking.category)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))

                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                    Text(formatReadCount(ranking.readCount))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                }

                // 排名变化指示器
                if ranking.rankTrend != .stable {
                    RankChangeIndicator(ranking: ranking)
                        .font(.system(size: 11))
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [rankColors[0].opacity(0.3), rankColors[1].opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }

    // 前三名的颜色
    private var rankColors: [Color] {
        switch ranking.rank {
        case 1:
            return [
                Color(red: 1.0, green: 0.84, blue: 0.0),  // 金色
                Color(red: 0.85, green: 0.65, blue: 0.13)
            ]
        case 2:
            return [
                Color(red: 0.75, green: 0.75, blue: 0.75), // 银色
                Color(red: 0.60, green: 0.60, blue: 0.60)
            ]
        case 3:
            return [
                Color(red: 0.80, green: 0.50, blue: 0.20), // 铜色
                Color(red: 0.65, green: 0.40, blue: 0.15)
            ]
        default:
            return [Color.gray]
        }
    }

    // 格式化阅读数
    private func formatReadCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1f万", Double(count) / 10000.0)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - 排行榜书籍行组件
struct RankingBookRow: View {
    let ranking: BookRanking

    var body: some View {
        HStack(spacing: 16) {
            // 排名
            Text("\(ranking.rank)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                .frame(width: 40)

            // 书籍信息
            VStack(alignment: .leading, spacing: 4) {
                Text(ranking.title)
                    .font(AppFont.kangxi(size: 16))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))

                HStack(spacing: 8) {
                    Text(ranking.category)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))

                    Text("·")
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))

                    Text(ranking.author)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                }
            }

            Spacer()

            // 阅读数和排名变化
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))

                    Text(formatReadCount(ranking.readCount))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                }

                // 排名变化指示器
                RankChangeIndicator(ranking: ranking)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    // 格式化阅读数
    private func formatReadCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1f万", Double(count) / 10000.0)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - 排名变化指示器
struct RankChangeIndicator: View {
    let ranking: BookRanking

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: iconName)
                .font(.caption)
            Text(changeText)
                .font(.caption)
        }
        .foregroundColor(trendColor)
    }

    private var iconName: String {
        switch ranking.rankTrend {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "minus"
        case .new: return "star.fill"
        }
    }

    private var changeText: String {
        if ranking.rankTrend == .new {
            return "NEW"
        } else if ranking.rankChange == 0 {
            return "-"
        } else {
            return "\(abs(ranking.rankChange))"
        }
    }

    private var trendColor: Color {
        switch ranking.rankTrend {
        case .up: return .red
        case .down: return .green
        case .stable: return .gray
        case .new: return .orange
        }
    }
}

#Preview {
    ClassicsRankingView()
}

