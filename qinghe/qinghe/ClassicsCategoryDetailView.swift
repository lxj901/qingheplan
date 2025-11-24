import SwiftUI

/// 国学书斋 - 分类详情页面
struct ClassicsCategoryDetailView: View {
    @Environment(\.dismiss) private var dismiss

    // 所有分类（在儒家前面添加"我的书籍"）
    private let categories = ["我的书籍", "儒家", "道家", "佛家", "史学", "诗词", "医学"]

    @State private var selectedCategory: String = "我的书籍"
    @State private var books: [ClassicsBookAPI] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showImportView = false  // 控制导入书籍视图显示

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
                // 分类选择器
                categorySelector
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // 书籍列表
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if books.isEmpty {
                    emptyView
                } else {
                    booksGridView
                }
            }
        }
        .navigationTitle("书籍")
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

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showImportView = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("导入书籍")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                }
            }
        }
        .enableSwipeBack() // 启用系统原生滑动返回手势
        .sheet(isPresented: $showImportView) {
            ClassicsImportView()
        }
        .onAppear {
            Task {
                await loadBooks()
            }
        }
    }

    // MARK: - 分类选择器
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        Task {
                            await loadBooks()
                        }
                    }) {
                        Text(category)
                            .font(.system(size: 15, weight: selectedCategory == category ? .semibold : .regular))
                            .foregroundColor(selectedCategory == category ? .white : Color(red: 0.4, green: 0.3, blue: 0.2))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        selectedCategory == category ?
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.70, green: 0.50, blue: 0.30),
                                                Color(red: 0.60, green: 0.40, blue: 0.20)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - 书籍网格视图
    private var booksGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(books, id: \.id) { book in
                    NavigationLink(destination: ClassicsReadingView(bookId: book.bookId, bookTitle: book.title).asSubView()) {
                        CategoryBookCard(book: book)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(red: 0.6, green: 0.4, blue: 0.2))

            Text("加载中...")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 错误视图
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.8, green: 0.4, blue: 0.2))

            Text(message)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 空状态视图
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.5))

            Text("该分类暂无书籍")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 加载书籍数据
    private func loadBooks() async {
        isLoading = true
        errorMessage = nil

        do {
            let allBooks = try await ClassicsAPIService.shared.getBooks(limit: 100)

            await MainActor.run {
                // 根据选中的分类过滤书籍
                if selectedCategory == "我的书籍" {
                    // 我的书籍：只显示当前用户导入的书籍
                    if let currentUserId = AuthManager.shared.getCurrentUserId() {
                        self.books = allBooks.filter { book in
                            book.userId == currentUserId
                        }
                        print("✅ 加载我的书籍: \(self.books.count) 本 (用户ID: \(currentUserId))")
                    } else {
                        self.books = []
                        print("⚠️ 用户未登录，我的书籍为空")
                    }
                } else {
                    // 其他分类：按分类名称过滤
                    self.books = allBooks.filter { book in
                        book.category == selectedCategory ||
                        book.category == "\(selectedCategory)经典" ||
                        book.category.contains(selectedCategory)
                    }
                    print("✅ 加载分类 \(selectedCategory) 的书籍: \(self.books.count) 本")
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载失败: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ 加载书籍失败: \(error)")
            }
        }
    }
}

// MARK: - 分类书籍卡片组件
struct CategoryBookCard: View {
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
                            .frame(width: 100, height: 140)
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
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 36)

            // 作者
            if let author = book.author {
                Text(author)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var placeholderCover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.75, blue: 0.65),
                            Color(red: 0.75, green: 0.65, blue: 0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 140)

            VStack(spacing: 4) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))

                Text(book.title)
                    .font(AppFont.kangxi(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }
}

#Preview {
    ClassicsCategoryDetailView()
}

