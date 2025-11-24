import SwiftUI

// MARK: - 折角效果修饰器
struct FoldedCornerShape: Shape {
    var cornerSize: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // 从左上角开始，顺时针绘制
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerSize, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerSize))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

struct FoldedCorner: ViewModifier {
    var cornerSize: CGFloat = 20
    var foldColor: Color = Color.white.opacity(0.3)

    func body(content: Content) -> some View {
        content
            .clipShape(FoldedCornerShape(cornerSize: cornerSize))
            .overlay(
                // 折角三角形
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cornerSize, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: cornerSize))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [foldColor, foldColor.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: cornerSize, height: cornerSize)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 1, y: 1)
                , alignment: .topTrailing
            )
    }
}

extension View {
    func foldedCorner(size: CGFloat = 20, color: Color = Color.white.opacity(0.3)) -> some View {
        self.modifier(FoldedCorner(cornerSize: size, foldColor: color))
    }
}

// MARK: - 书架主页面（只显示已读书籍）
struct ClassicsLibraryView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var readBooks: [ReadBookInfo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    // 已读书籍信息
    struct ReadBookInfo: Identifiable {
        let id: String
        let bookId: String
        let title: String
        let author: String?
        let category: String
        let coverUrl: String?
        let lastReadAt: String
        let readProgress: Double // 阅读进度百分比
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                Color(red: 0.98, green: 0.96, blue: 0.94)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("加载中...")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.6))
                        Text(error)
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                        Button("重试") {
                            Task {
                                await loadReadBooks()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppConstants.Colors.primaryGreen)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else if readBooks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 64))
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.3))
                        Text("暂无已读书籍")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                        Text("开始阅读国学经典吧")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(readBooks) { book in
                                NavigationLink(destination: ClassicsReadingView(bookId: book.bookId, bookTitle: book.title).asSubView()) {
                                    ReadBookCard(book: book)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("书架")
            .navigationBarTitleDisplayMode(.large)
        }
        .asRootView()
        .task {
            await loadReadBooks()
        }
    }

    // MARK: - 加载已读书籍
    private func loadReadBooks() async {
        guard let userId = AuthManager.shared.getCurrentUserId() else {
            await MainActor.run {
                self.errorMessage = "请先登录"
            }
            return
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            // 获取用户的学习进度
            let progressList = try await ClassicsAPIService.shared.getProgress(userId: userId)

            // 按书籍分组，获取每本书的最后阅读时间
            var bookProgressMap: [String: ClassicsProgress] = [:]
            for progress in progressList {
                if let existing = bookProgressMap[progress.bookId] {
                    // 保留最新的阅读记录
                    if let existingDate = existing.lastReadAt,
                       let newDate = progress.lastReadAt,
                       newDate > existingDate {
                        bookProgressMap[progress.bookId] = progress
                    }
                } else {
                    bookProgressMap[progress.bookId] = progress
                }
            }

            // 获取所有书籍信息
            let allBooks = try await ClassicsAPIService.shared.getBooks(limit: 1000)

            // 构建已读书籍列表
            var readBooksList: [ReadBookInfo] = []
            for (bookId, progress) in bookProgressMap {
                if let book = allBooks.first(where: { $0.bookId == bookId }) {
                    // 计算阅读进度（简化版，基于阅读次数）
                    let readProgress = min(Double(progress.readCount ?? 0) / 100.0, 1.0)

                    let readBook = ReadBookInfo(
                        id: book.id,
                        bookId: book.bookId,
                        title: book.title,
                        author: book.author,
                        category: book.category,
                        coverUrl: book.coverUrl,
                        lastReadAt: progress.lastReadAt ?? "",
                        readProgress: readProgress
                    )
                    readBooksList.append(readBook)
                }
            }

            // 按最后阅读时间排序
            readBooksList.sort { $0.lastReadAt > $1.lastReadAt }

            await MainActor.run {
                self.readBooks = readBooksList
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载失败: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// MARK: - 已读书籍卡片
struct ReadBookCard: View {
    let book: ClassicsLibraryView.ReadBookInfo

    var body: some View {
        HStack(spacing: 16) {
            // 左侧封面
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: coverColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 80, height: 110)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                // 书名（竖排）
                VStack(spacing: 4) {
                    let chars = Array(book.title.prefix(5))
                    ForEach(0..<chars.count, id: \.self) { index in
                        Text(String(chars[index]))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }

            // 右侧信息
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineLimit(1)

                Text(book.author ?? "未知作者")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(book.category)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0.9, green: 0.88, blue: 0.85))
                        )

                    Spacer()
                }

                // 阅读进度
                if book.readProgress > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("阅读进度")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(red: 0.9, green: 0.88, blue: 0.85))
                                    .frame(height: 4)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(AppConstants.Colors.primaryGreen)
                                    .frame(width: geometry.size.width * book.readProgress, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private var coverColors: [Color] {
        let hash = abs(book.bookId.hashValue)
        let colorSets: [[Color]] = [
            [Color(red: 0.8, green: 0.6, blue: 0.4), Color(red: 0.7, green: 0.5, blue: 0.3)],
            [Color(red: 0.6, green: 0.7, blue: 0.8), Color(red: 0.5, green: 0.6, blue: 0.7)],
            [Color(red: 0.7, green: 0.5, blue: 0.6), Color(red: 0.6, green: 0.4, blue: 0.5)],
            [Color(red: 0.5, green: 0.7, blue: 0.6), Color(red: 0.4, green: 0.6, blue: 0.5)],
            [Color(red: 0.8, green: 0.7, blue: 0.5), Color(red: 0.7, green: 0.6, blue: 0.4)]
        ]
        return colorSets[hash % colorSets.count]
    }
}

// MARK: - 旧组件保留（其他页面可能使用）
// MARK: - 分类标签组件（纯文字样式）
struct CategoryChip: View {
    let category: ClassicsCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(LocalizationManager.shared.localizedString(key: category.titleKey))
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(red: 0.6, green: 0.4, blue: 0.2) : Color(red: 0.5, green: 0.4, blue: 0.3))

                // 选中时显示下划线
                if isSelected {
                    Rectangle()
                        .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                        .frame(height: 2)
                        .cornerRadius(1)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
            .padding(.horizontal, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 书籍卡片组件（古籍风格）
struct BookCard: View {
    let book: ClassicsBook
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 书籍封面 - 古籍风格
            ZStack(alignment: .topLeading) {
                // 古籍纹理背景 - 使用书籍分类颜色
                LinearGradient(
                    gradient: Gradient(colors: book.coverColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // 外边框
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.black.opacity(0.2), lineWidth: 2)

                // 内边框
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.8)
                    .padding(6)

                // 书名区域 - 放在左上角
                VStack(spacing: 0) {
                    // 书名竖排文字
                    VStack(spacing: 6) {
                        let chars = Array(book.title.prefix(6))
                        ForEach(0..<chars.count, id: \.self) { index in
                            Text(String(chars[index]))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)

                    // 书名下方的装饰方框
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 34, height: 4)
                        .cornerRadius(1.5)
                }
                .padding(.top, 14)
                .padding(.leading, 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(height: 200)
            .cornerRadius(4)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            // 书籍信息
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineLimit(2)

                if let author = book.author {
                    Text(author)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                        .lineLimit(1)
                }

                // 分类标签
                Text(localizationManager.localizedString(key: book.category.titleKey))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.1))
                    )
            }
            .padding(.top, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 书籍列表行组件
struct BookListRow: View {
    let book: ClassicsBook

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧书籍封面 - 古籍风格
            verticalTitleView
                .frame(width: 90, height: 130)
                .cornerRadius(4)

            // 右侧书籍信息
            VStack(alignment: .leading, spacing: 8) {
                // 书名和标签
                HStack(alignment: .top, spacing: 8) {
                    Text(book.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        .lineLimit(1)

                    // 标签组
                    tagsView
                }

                // 作者信息
                if let author = book.author {
                    Text(author)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                        .lineLimit(1)
                }

                // 简介
                if let description = book.description {
                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    // 竖排标题视图 - 古籍风格
    private var verticalTitleView: some View {
        ZStack(alignment: .topLeading) {
            // 古籍纹理背景 - 使用书籍分类颜色
            LinearGradient(
                gradient: Gradient(colors: book.coverColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 边框装饰
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.black.opacity(0.2), lineWidth: 1.5)

            // 内边框
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                .padding(3)

            // 书名区域 - 放在左上角
            VStack(spacing: 0) {
                // 书名竖排文字
                VStack(spacing: 4) {
                    let chars = Array(book.title.prefix(5))
                    ForEach(0..<chars.count, id: \.self) { index in
                        Text(String(chars[index]))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 8)

                // 书名下方的装饰方框
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 26, height: 3)
                    .cornerRadius(1)
            }
            .padding(.top, 10)
            .padding(.leading, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    // 标签视图（优化性能）
    @ViewBuilder
    private var tagsView: some View {
        if book.hasVernacular {
            tagLabel(text: "白话文")
        }
        if book.isProofread {
            tagLabel(text: "精校")
        }
    }

    // 单个标签
    private func tagLabel(text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange.opacity(0.1))
            )
    }
}

// MARK: - 国学经典分类枚举
enum ClassicsCategory: String, CaseIterable {
    case all = "all"
    case myBooks = "myBooks"  // 我的书籍
    case confucian = "confucian"
    case taoist = "taoist"
    case buddhist = "buddhist"
    case historical = "historical"
    case poetry = "poetry"
    case medical = "medical"

    var titleKey: String {
        switch self {
        case .all: return "all_categories"
        case .myBooks: return "my_books"
        case .confucian: return "confucian_classics"
        case .taoist: return "taoist_classics"
        case .buddhist: return "buddhist_classics"
        case .historical: return "historical_classics"
        case .poetry: return "poetry_classics"
        case .medical: return "medical_classics"
        }
    }
}

// MARK: - 国学经典书籍模型
struct ClassicsBook: Identifiable {
    let id = UUID()
    let title: String
    let author: String?
    let category: ClassicsCategory
    let coverColors: [Color]
    let introduction: String?
    let description: String?  // 详细描述
    let hasVernacular: Bool   // 是否有白话文
    let isProofread: Bool     // 是否精校
    let chapters: [ClassicsChapter] = []  // 章节列表

    // 示例数据
    static let sampleBooks: [ClassicsBook] = [
        // 示例书籍
        ClassicsBook(
            title: "古文观止",
            author: "[清] 吴楚材 辑 · 光绪二十八年善成堂刊本",
            category: .poetry,
            coverColors: [Color(red: 0.35, green: 0.45, blue: 0.55), Color(red: 0.25, green: 0.35, blue: 0.45)],
            introduction: nil,
            description: nil,
            hasVernacular: true,
            isProofread: false
        ),
        ClassicsBook(
            title: "妙法莲华经（法华经）",
            author: "[东晋] 鸠摩罗什 著 · 嘉兴藏本",
            category: .buddhist,
            coverColors: [Color(red: 0.65, green: 0.55, blue: 0.35), Color(red: 0.55, green: 0.45, blue: 0.25)],
            introduction: nil,
            description: "共七卷二十八品，简称《法华经》，后秦三藏法师鸠摩罗什译。是天台宗依据的主要经典。本...",
            hasVernacular: true,
            isProofread: false
        ),
        ClassicsBook(
            title: "国语",
            author: "[吴] 韦昭 注 · 四部丛刊景明嘉靖翻宋本",
            category: .historical,
            coverColors: [Color(red: 0.35, green: 0.45, blue: 0.45), Color(red: 0.25, green: 0.35, blue: 0.35)],
            introduction: nil,
            description: "共21卷，韦昭注，通过注解的形式疏通《国语》语言。韦氏注《国语》的目的，是因前代诸家...",
            hasVernacular: true,
            isProofread: true
        ),
        ClassicsBook(
            title: "墨子",
            author: "[战国] 墨翟 撰 · 四部丛刊景明嘉靖突丑唐尧臣...",
            category: .confucian,
            coverColors: [Color(red: 0.55, green: 0.50, blue: 0.40), Color(red: 0.45, green: 0.40, blue: 0.30)],
            introduction: nil,
            description: "共15卷，墨翟著，由墨翟自著和弟子记述墨子言论两部分组成。现存《墨子》一书，宋朝多...",
            hasVernacular: true,
            isProofread: true
        ),

        // 儒家经典
        ClassicsBook(
            title: "论语",
            author: "孔子",
            category: .confucian,
            coverColors: [Color(red: 0.8, green: 0.3, blue: 0.2), Color(red: 0.6, green: 0.2, blue: 0.1)],
            introduction: "儒家经典之一，记录孔子及其弟子言行",
            description: "儒家经典之一，记录孔子及其弟子的言行，是中国古代思想文化的重要典籍。",
            hasVernacular: true,
            isProofread: true
        ),
        ClassicsBook(
            title: "孟子",
            author: "孟子",
            category: .confucian,
            coverColors: [Color(red: 0.7, green: 0.2, blue: 0.3), Color(red: 0.5, green: 0.1, blue: 0.2)],
            introduction: "儒家经典著作，阐述仁政思想",
            description: "儒家经典著作，阐述仁政思想，主张性善论，是儒家思想的重要组成部分。",
            hasVernacular: true,
            isProofread: false
        ),
        ClassicsBook(
            title: "大学",
            author: "曾子",
            category: .confucian,
            coverColors: [Color(red: 0.6, green: 0.3, blue: 0.4), Color(red: 0.4, green: 0.2, blue: 0.3)],
            introduction: "四书之一，论述修身治国之道",
            description: "四书之一，论述修身治国之道，强调格物致知、诚意正心。",
            hasVernacular: false,
            isProofread: true
        ),
        ClassicsBook(
            title: "中庸",
            author: "子思",
            category: .confucian,
            coverColors: [Color(red: 0.7, green: 0.4, blue: 0.2), Color(red: 0.5, green: 0.3, blue: 0.1)],
            introduction: "儒家经典，讲述中庸之道",
            description: "儒家经典，讲述中庸之道，强调不偏不倚、和谐平衡的处世哲学。",
            hasVernacular: false,
            isProofread: false
        ),

        // 道家经典
        ClassicsBook(
            title: "道德经",
            author: "老子",
            category: .taoist,
            coverColors: [Color(red: 0.2, green: 0.4, blue: 0.6), Color(red: 0.1, green: 0.3, blue: 0.5)],
            introduction: "道家哲学思想的重要源头",
            description: "道家哲学思想的重要源头，阐述道法自然、无为而治的思想。",
            hasVernacular: true,
            isProofread: true
        ),
        ClassicsBook(
            title: "庄子",
            author: "庄子",
            category: .taoist,
            coverColors: [Color(red: 0.3, green: 0.5, blue: 0.7), Color(red: 0.2, green: 0.4, blue: 0.6)],
            introduction: "道家重要典籍，文辞优美深邃",
            description: "道家重要典籍，文辞优美深邃，充满浪漫主义色彩和哲学思辨。",
            hasVernacular: false,
            isProofread: false
        ),

        // 佛家经典
        ClassicsBook(
            title: "金刚经",
            author: "鸠摩罗什译",
            category: .buddhist,
            coverColors: [Color(red: 0.9, green: 0.7, blue: 0.2), Color(red: 0.8, green: 0.6, blue: 0.1)],
            introduction: "大乘佛教般若部重要经典",
            description: "大乘佛教般若部重要经典，阐述空性智慧，影响深远。",
            hasVernacular: true,
            isProofread: false
        ),
        ClassicsBook(
            title: "心经",
            author: "玄奘译",
            category: .buddhist,
            coverColors: [Color(red: 0.8, green: 0.6, blue: 0.3), Color(red: 0.7, green: 0.5, blue: 0.2)],
            introduction: "般若经系列中最短的经典",
            description: "般若经系列中最短的经典，言简意赅，阐述般若空性思想。",
            hasVernacular: false,
            isProofread: true
        ),

        // 史学经典
        ClassicsBook(
            title: "史记",
            author: "司马迁",
            category: .historical,
            coverColors: [Color(red: 0.4, green: 0.3, blue: 0.5), Color(red: 0.3, green: 0.2, blue: 0.4)],
            introduction: "中国第一部纪传体通史",
            description: "中国第一部纪传体通史，记载从黄帝到汉武帝时期的历史。",
            hasVernacular: true,
            isProofread: true
        ),
        ClassicsBook(
            title: "资治通鉴",
            author: "司马光",
            category: .historical,
            coverColors: [Color(red: 0.5, green: 0.4, blue: 0.6), Color(red: 0.4, green: 0.3, blue: 0.5)],
            introduction: "编年体史书，记载1362年历史",
            description: "编年体史书，记载1362年历史，是中国史学的重要著作。",
            hasVernacular: false,
            isProofread: false
        ),

        // 诗词歌赋
        ClassicsBook(
            title: "诗经",
            author: "佚名",
            category: .poetry,
            coverColors: [Color(red: 0.3, green: 0.6, blue: 0.4), Color(red: 0.2, green: 0.5, blue: 0.3)],
            introduction: "中国最早的诗歌总集",
            description: "中国最早的诗歌总集，收录西周至春秋时期的诗歌作品。",
            hasVernacular: true,
            isProofread: true
        ),
        ClassicsBook(
            title: "唐诗三百首",
            author: "蘅塘退士编",
            category: .poetry,
            coverColors: [Color(red: 0.4, green: 0.7, blue: 0.5), Color(red: 0.3, green: 0.6, blue: 0.4)],
            introduction: "唐代诗歌精选集",
            description: "唐代诗歌精选集，收录唐代著名诗人的代表作品。",
            hasVernacular: false,
            isProofread: false
        ),

        // 医学经典
        ClassicsBook(
            title: "黄帝内经",
            author: "佚名",
            category: .medical,
            coverColors: [Color(red: 0.5, green: 0.6, blue: 0.3), Color(red: 0.4, green: 0.5, blue: 0.2)],
            introduction: "中医理论奠基之作",
            description: "中医理论奠基之作，阐述中医基础理论和诊疗方法。",
            hasVernacular: true,
            isProofread: false
        ),
        ClassicsBook(
            title: "本草纲目",
            author: "李时珍",
            category: .medical,
            coverColors: [Color(red: 0.6, green: 0.7, blue: 0.4), Color(red: 0.5, green: 0.6, blue: 0.3)],
            introduction: "中药学巨著，集历代本草之大成",
            description: "中药学巨著，集历代本草之大成，记载药物1892种。",
            hasVernacular: false,
            isProofread: true
        ),
    ]
}

// MARK: - 功能入口按钮组件
struct FeatureEntryButton: View {
    let icon: String
    let title: String
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // 图标容器 - 圆形设计，更符合东方美学
                ZStack {
                    // 外圈装饰 - 金色边框
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.9, green: 0.7, blue: 0.4).opacity(0.6),
                                    Color(red: 0.8, green: 0.6, blue: 0.3).opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 64, height: 64)

                    // 渐变背景
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .shadow(color: gradientColors.first?.opacity(0.4) ?? Color.clear, radius: 8, x: 0, y: 4)

                    // 图标
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                }

                // 标题 - 使用康熙字体
                Text(title)
                    .font(AppFont.kangxi(size: 14))
                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 功能入口卡片组件（用于 NavigationLink）
struct FeatureEntryCard: View {
    let icon: String
    let title: String
    let gradientColors: [Color]

    var body: some View {
        VStack(spacing: 10) {
            // 图标容器 - 圆形设计，更符合东方美学
            ZStack {
                // 外圈装饰 - 金色边框
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.9, green: 0.7, blue: 0.4).opacity(0.6),
                                Color(red: 0.8, green: 0.6, blue: 0.3).opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 64, height: 64)

                // 渐变背景
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: gradientColors.first?.opacity(0.4) ?? Color.clear, radius: 8, x: 0, y: 4)

                // 图标
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            }

            // 标题 - 使用康熙字体
            Text(title)
                .font(AppFont.kangxi(size: 14))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 章节模型
struct ClassicsChapter: Identifiable {
    let id = UUID()
    let title: String
    let summary: String?
}

// MARK: - API 书籍列表行组件
struct BookListRowAPI: View {
    let book: ClassicsBookAPI

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧书籍封面 - 古籍风格
            verticalTitleView
                .frame(width: 90, height: 130)
                .cornerRadius(4)

            // 右侧书籍信息
            VStack(alignment: .leading, spacing: 8) {
                // 书名和标签
                HStack(alignment: .top, spacing: 8) {
                    Text(book.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        .lineLimit(1)

                    // 标签组 - 固定显示"精校"
                    tagsView
                }

                // 作者信息
                if let author = book.author {
                    Text(author)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                        .lineLimit(1)
                }

                // 简介
                if let description = book.description {
                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    // 竖排标题视图 - 古籍风格
    private var verticalTitleView: some View {
        ZStack(alignment: .topLeading) {
            // 古籍纹理背景 - 使用分类颜色
            LinearGradient(
                gradient: Gradient(colors: coverColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 边框装饰
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.black.opacity(0.2), lineWidth: 1.5)

            // 内边框
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                .padding(3)

            // 书名区域 - 放在左上角
            VStack(spacing: 0) {
                // 书名竖排文字
                VStack(spacing: 4) {
                    let chars = Array(book.title.prefix(5))
                    ForEach(0..<chars.count, id: \.self) { index in
                        Text(String(chars[index]))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 8)

                // 书名下方的装饰方框
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 26, height: 3)
                    .cornerRadius(1)
            }
            .padding(.top, 10)
            .padding(.leading, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    // 标签视图 - 固定显示"精校"
    @ViewBuilder
    private var tagsView: some View {
        tagLabel(text: "精校")
    }

    // 标签样式
    private func tagLabel(text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.15))
            )
    }

    // 根据分类生成封面颜色
    private var coverColors: [Color] {
        switch book.category {
        case "儒家", "儒家经典":
            return [Color(red: 0.8, green: 0.3, blue: 0.2), Color(red: 0.6, green: 0.2, blue: 0.1)]
        case "道家", "道家经典":
            return [Color(red: 0.2, green: 0.4, blue: 0.6), Color(red: 0.1, green: 0.3, blue: 0.5)]
        case "佛家", "佛家经典":
            return [Color(red: 0.9, green: 0.7, blue: 0.2), Color(red: 0.8, green: 0.6, blue: 0.1)]
        case "史学", "史学经典":
            return [Color(red: 0.4, green: 0.3, blue: 0.5), Color(red: 0.3, green: 0.2, blue: 0.4)]
        case "诗词", "诗词歌赋", "诗歌经典":
            return [Color(red: 0.3, green: 0.6, blue: 0.4), Color(red: 0.2, green: 0.5, blue: 0.3)]
        case "医学", "医学经典":
            return [Color(red: 0.5, green: 0.6, blue: 0.3), Color(red: 0.4, green: 0.5, blue: 0.2)]
        default:
            return [Color(red: 0.6, green: 0.5, blue: 0.4), Color(red: 0.5, green: 0.4, blue: 0.3)]
        }
    }
}

// MARK: - 书单卡片组件
struct BookCollectionCard: View {
    let book: ClassicsBookAPI

    var body: some View {
        VStack(spacing: 8) {
            // 书籍封面
            if let coverUrl = book.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderCover
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        placeholderCover
                    @unknown default:
                        placeholderCover
                    }
                }
            } else {
                placeholderCover
            }

            // 书名
            Text(book.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                .lineLimit(1)
                .frame(width: 120)
        }
    }

    // 占位封面
    private var placeholderCover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: getCategoryColors(book.category),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 160)

            VStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))

                Text(book.title)
                    .font(AppFont.kangxi(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
            }
        }
        .frame(width: 120, height: 160)
    }

    // 根据分类获取颜色
    private func getCategoryColors(_ category: String) -> [Color] {
        switch category {
        case "儒家", "儒家经典":
            return [Color(red: 0.82, green: 0.62, blue: 0.42), Color(red: 0.72, green: 0.52, blue: 0.32)]
        case "道家", "道家经典":
            return [Color(red: 0.68, green: 0.48, blue: 0.28), Color(red: 0.58, green: 0.38, blue: 0.18)]
        case "佛家", "佛家经典":
            return [Color(red: 0.75, green: 0.55, blue: 0.35), Color(red: 0.65, green: 0.45, blue: 0.25)]
        case "史学", "史学经典":
            return [Color(red: 0.4, green: 0.3, blue: 0.5), Color(red: 0.3, green: 0.2, blue: 0.4)]
        case "诗词", "诗词歌赋":
            return [Color(red: 0.3, green: 0.6, blue: 0.4), Color(red: 0.2, green: 0.5, blue: 0.3)]
        case "医学", "医学经典":
            return [Color(red: 0.5, green: 0.6, blue: 0.3), Color(red: 0.4, green: 0.5, blue: 0.2)]
        default:
            return [Color(red: 0.6, green: 0.5, blue: 0.4), Color(red: 0.5, green: 0.4, blue: 0.3)]
        }
    }
}